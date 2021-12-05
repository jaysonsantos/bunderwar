#!/usr/bin/env python3
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

PLATFORMS = {"linux/amd64", "linux/arm64"}
HERE = Path(__file__).parent
REPOSITORY = "ghcr.io/jaysonsantos/bunderwar"
PUSH_IMAGE = "PUSH_IMAGE"


@dataclasses.dataclass(frozen=True)
class Image:
    name: str
    version: Optional[str]
    dockerfile: Path

    _version_re = re.compile(r"ENV .+?_VERSION (.*)")

    @classmethod
    def load(cls, name) -> "Image":
        """
        >>> Image.load("otel-collector")
        Image(name='otel-collector', version='0.39.0', dockerfile=...)
        >>> Image.load("otel-collector.Dockerfile")
        Image(name='otel-collector', version='0.39.0', dockerfile=...)
        """
        maybe_dockerfile = HERE / name
        if maybe_dockerfile.exists():
            return cls.load_from_dockerfile(maybe_dockerfile.stem, maybe_dockerfile)
        return cls.load_from_name(name)

    @classmethod
    def load_from_name(cls, name: str) -> "Image":
        return cls.load_from_dockerfile(name, HERE / f"{name}.Dockerfile")

    @classmethod
    def load_from_dockerfile(cls, name, path: Path) -> "Image":
        if path.suffix != ".Dockerfile":
            raise ValueError(f"{path} is not a Dockerfile")
        version = cls.parse_version(path.read_text())
        return cls(name, version, path)

    @classmethod
    def parse_version(cls, contents) -> Optional[str]:
        if match := cls._version_re.search(contents):
            return match.group(1)
        return None

    def build(cls, push):
        full_tag = f"{REPOSITORY}:{cls.name}-{cls.version}"
        platforms = ",".join(PLATFORMS)
        push_arg = "--push" if push else ""
        build_command = f"docker buildx build {push_arg} --tag {full_tag} -f {cls.dockerfile} --platform {platforms} ."
        print(f"Building with {build_command!r}")

        check_call(args=shlex.split(build_command))


def build(images, push: bool):
    for image in get_images(images):
        if not image.version:
            print(
                f"Skipping {image.name} {image.dockerfile} because no version was found"
            )
            continue
        print(f"Building {image}")
        image.build(push)


def get_images(names) -> Iterator[Image]:
    for name in names or all_images():
        try:
            yield Image.load(name)
        except Exception as e:
            print(f"Skipping {name} because {e}")


def all_images():
    return glob.glob("**/*.Dockerfile", recursive=True)


if __name__ == "__main__":
    build(sys.argv[1:], push=PUSH_IMAGE in os.environ)
