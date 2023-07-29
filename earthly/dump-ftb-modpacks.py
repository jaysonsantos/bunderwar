from io import StringIO
import json
import pathlib
import requests
import xml.etree.ElementTree

HERE = pathlib.Path(__file__).parent
TEMPLATE = """VERSION --shell-out-anywhere 0.6

ARG MOD_ID={mod_id}
ARG MOD_VERSION={mod_version}
ARG NAME={image_name}
ARG TARGETARCH
ARG IS_BETA=1

IMPORT ../ftb

all:
    BUILD ftb+all --MOD_ID=$MOD_ID --MOD_VERSION=$MOD_VERSION --NAME=$NAME --IS_BETA=$IS_BETA
"""


def get_packs(maybe_packs):
    if "packs" in maybe_packs:
        return maybe_packs["packs"]
    for value in maybe_packs.values():
        if packs := get_packs(value):
            return packs

    return None


def render_pack(pack):
    print(f'Rendering {pack["name"]}')
    image_name = pack["slug"].replace("presents-", "")
    mod_id = pack["id"]
    version, *previous = pack["versions"]
    mod_version = version["id"]
    previous_versions = ", ".join([str(p["id"]) for p in previous])

    print(f"Current {mod_version} previous {previous_versions}")
    output_file = HERE / image_name / "Earthfile"
    output_file.parent.mkdir(parents=True, exist_ok=True)

    with output_file.open("w") as output:
        output.write(
            TEMPLATE.format(
                mod_id=mod_id, mod_version=mod_version, image_name=image_name
            )
        )
    print(f"Written to {output_file}")
    print("\n\n")


t = xml.etree.ElementTree.parse(
    StringIO(requests.get("https://www.feed-the-beast.com/modpacks").text)
)
rv = json.loads(t.find('.//script[@id="__NEXT_DATA__"]').text)
packs = get_packs(rv)
for pack in packs:
    render_pack(pack)
