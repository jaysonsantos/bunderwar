#!/usr/bin/env python3
import json
import os
import sys
import glob
import dataclasses
from typing import Iterator, Optional
from pathlib import Path
from subprocess import check_call
import shlex
import re

EARTHFILE = "Earthfile"

PLATFORMS = {"linux/amd64", "linux/arm64"}
HERE = Path(__file__).parent
REPOSITORY = "ghcr.io/jaysonsantos/bunderwar"
PUSH_IMAGE = "PUSH_IMAGE"


def platform_suffix(platform: str) -> str:
    return platform.replace("/", "-")


@dataclasses.dataclass(frozen=True)
class Image:
    name: str
    version: Optional[str]
    dockerfile: Path

    _version_re = re.compile(r"(?:ENV|ARG) .+?_VERSION[= ](.*)")
    _platforms_re = re.compile(r"ARG.+?PLATFORMS=(.*)")

    @classmethod
    def load(cls, name) -> "Image":
        """
        >>> Image.load("otel-collector")
        Image(name='otel-collector', version='0.60.0', dockerfile=...)
        >>> Image.load("otel-collector.Dockerfile")
        Image(name='otel-collector', version='0.60.0', dockerfile=...)
        """
        maybe_dockerfile = HERE / name
        if maybe_dockerfile.exists():
            return cls.load_from_dockerfile(
                Image.get_image_name_from_file(maybe_dockerfile), maybe_dockerfile
            )
        return cls.load_from_name(name)

    @classmethod
    def get_image_name_from_file(cls, maybe_dockerfile):
        if maybe_dockerfile.stem == EARTHFILE:
            return maybe_dockerfile.parent.name
        return maybe_dockerfile.stem

    @classmethod
    def load_from_name(cls, name: str) -> "Image":
        return cls.load_from_dockerfile(name, HERE / f"{name}.Dockerfile")

    @classmethod
    def load_from_dockerfile(cls, image_name, path: Path) -> "Image":
        if not (path.suffix == ".Dockerfile" or path.name == EARTHFILE):
            raise ValueError(f"{path} is not a Dockerfile")
        version = cls.parse_version(path.read_text())
        return cls(image_name, version, path)

    @classmethod
    def parse_version(cls, contents) -> Optional[str]:
        """
        >>> Image.parse_version("ENV OTEL_VERSION 0.60.0")
        '0.60.0'
        >>> Image.parse_version("ENV OTEL_VERSION v0.60.0")
        '0.60.0'
        >>> Image.parse_version("ARG OTEL_VERSION=v0.60.0")
        '0.60.0'
        >>> Image.parse_version("ARG OTEL_VERSION v0.60.0")
        '0.60.0'
        """
        if match := cls._version_re.search(contents):
            return match.group(1).replace("v", "")
        return None

    def full_tag(self) -> str:
        return f"{REPOSITORY}:{self.name}-{self.version}"

    def get_build_commands(self, push: bool, split_platforms: bool):
        full_tag = self.full_tag()
        platforms = self.get_platforms()
        push_arg = "--push" if push else ""

        if self._is_earthfile():
            return [self._build_earthfile(push_arg)]
        if split_platforms and not push:
            return [
                self._build_dockerfile(
                    full_tag,
                    [platform],
                    push_arg,
                    output_tag=f"{full_tag}-{platform_suffix(platform)}",
                )
                for platform in platforms
            ]
        return [self._build_dockerfile(full_tag, platforms, push_arg)]

    def get_manifest_entry(self):
        if self._is_earthfile():
            return None
        full_tag = self.full_tag()
        platforms = self.get_platforms()
        return dict(
            image=full_tag,
            sources=[f"{full_tag}-{platform_suffix(platform)}" for platform in platforms],
        )

    def _is_earthfile(self):
        return self.dockerfile.name == EARTHFILE

    def _build_earthfile(self, push_arg):
        working_directory = str(self.dockerfile.parent)
        build_command = f"earthly {push_arg} --ci +all"
        print(f"Building with {build_command!r} in {working_directory!r}")

        return dict(args=shlex.split(build_command), cwd=working_directory)

    def _build_dockerfile(self, full_tag, platforms, push_arg, output_tag=None):
        platforms = ','.join(platforms)
        output_tag = output_tag or full_tag
        build_command = f"docker buildx build {push_arg} --tag {output_tag} -f {self.dockerfile} --platform {platforms} ."
        print(f"Building with {build_command!r}")

        return dict(
            args=shlex.split(build_command),
            image=full_tag,
            platform=platforms,
            publish_tag=output_tag,
        )

    def get_platforms(self):
        contents = self.dockerfile.read_text()
        matches = self._platforms_re.search(contents)
        if matches:
            return [platform.strip() for platform in matches.group(1).split(",")]
        return PLATFORMS


def build(images, push: bool, output_matrix: bool):
    commands = []
    manifests = []
    split_platform_builds = output_matrix and not push
    for image in get_images(images):
        if not image.version:
            print(
                f"Skipping {image.name} {image.dockerfile} because no version was found"
            )
            continue
        print(f"Building {image}")
        commands.extend(
            image.get_build_commands(push, split_platforms=split_platform_builds)
        )
        if split_platform_builds:
            manifest = image.get_manifest_entry()
            if manifest:
                manifests.append(manifest)
    run_build_commands(commands, manifests, output_matrix)


def get_images(names) -> Iterator[Image]:
    for name in names or all_images():
        try:
            yield Image.load(name)
        except Exception as e:
            print(f"Skipping {name} because {e}")


def all_images():
    return glob.glob("**/*.Dockerfile", recursive=True)


def run_build_commands(calls, manifests, output_matrix):
    if not output_matrix:
        return run_serial_commands(calls)

    if not calls:
        calls.append(dict(args=["true"]))
    matrix = dict(include=calls)
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"matrix={json.dumps(matrix, separators=(',',':'))}\n")
        output.write(
            f"merge_matrix={json.dumps(dict(include=manifests), separators=(',',':'))}\n"
        )


def run_serial_commands(calls):
    for call in calls:
        check_call(**call)


if __name__ == "__main__":
    args = sys.argv[1:]
    try:
        args.remove("--output-matrix")
    except ValueError:
        output_matrix = False
    else:
        output_matrix = True

    build(args, push=PUSH_IMAGE in os.environ, output_matrix=output_matrix)
