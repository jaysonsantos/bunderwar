#!/usr/bin/env python3
import json
from os import stat
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

    def get_build_command(self, push):
        full_tag = f"{REPOSITORY}:{self.name}-{self.version}"
        platforms = self.get_platforms()
        push_arg = "--push" if push else ""

        if self._is_earthfile():
            return self._build_earthfile(push_arg)
        return self._build_dockerfile(full_tag, platforms, push_arg)

    def _is_earthfile(self):
        return self.dockerfile.name == EARTHFILE

    def _build_earthfile(self, push_arg):
        working_directory = str(self.dockerfile.parent)
        build_command = f"earthly {push_arg} --ci +all"
        print(f"Building with {build_command!r} in {working_directory!r}")

        return dict(args=shlex.split(build_command), cwd=working_directory)

    def _build_dockerfile(self, full_tag, platforms, push_arg):
        platforms = ','.join(platforms)
        build_command = f"docker buildx build {push_arg} --tag {full_tag} -f {self.dockerfile} --platform {platforms} ."
        print(f"Building with {build_command!r}")

        return dict(args=shlex.split(build_command))

    def get_platforms(self):
        contents = self.dockerfile.read_text()
        matches = self._platforms_re.search(contents)
        if matches:
            return [platform.strip() for platform in matches.group(1).split(",")]
        return PLATFORMS


def build(images, push: bool, output_matrix: bool):
    commands = []
    for image in get_images(images):
        if not image.version:
            print(
                f"Skipping {image.name} {image.dockerfile} because no version was found"
            )
            continue
        print(f"Building {image}")
        commands.append(image.get_build_command(push))
    run_build_commands(commands, output_matrix)


def get_images(names) -> Iterator[Image]:
    for name in names or all_images():
        try:
            yield Image.load(name)
        except Exception as e:
            print(f"Skipping {name} because {e}")


def all_images():
    return glob.glob("**/*.Dockerfile", recursive=True)


def run_build_commands(calls, output_matrix):
    if not output_matrix:
        return run_serial_commands(calls)

    if not calls:
        calls.append(dict(args=["true"]))
    matrix = dict(include=calls)
    with open(os.environ["GITHUB_OUTPUT"], "a") as output:
        output.write(f"matrix={json.dumps(matrix, separators=(',',':'))}\n")


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
