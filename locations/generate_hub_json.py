import json
import re
from pathlib import Path

"""
Generates the Hub.jsonc file so the hub locations can be references to the real locations
"""

# Input files - add to this list when a new map is added
INPUT_FILES = [
    "1-1.jsonc",
    "1-2.jsonc",
    "1-3.jsonc",
    "1-4.jsonc",
    "1-5.jsonc",
    "1-6.jsonc",
    "1-7.jsonc",
    "1-8.jsonc",
    "1-9.jsonc",
    "1-O.jsonc",
]

# Where each map should go on the hub
HUB_MAP_POSITIONS = {
    "1-1": (30, 30),
    "1-2a": (40, 30),
    "1-3": (200, 30),
    "1-2b": (40, 40),
    "1-4": (60, 30),
    "1-5": (70, 30),
    "1-6": (80, 30),
    "1-7": (90, 30),
    "1-8": (100, 30),
    "1-9": (110, 30),
    "1-O": (150, 60),
}

# The output file name
OUTPUT_FILE = "Hub.jsonc"

def load_jsonc(path: Path):
    """
    Loads the jsonc file, removing the comments so that the library can parse it.
    """
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"//.*?$", "", text, flags=re.MULTILINE)
    return json.loads(text)

# Skeleton of the hub object
hub = [
    {
        "name": "Hub",
        "children": []
    }
]

# Loop through the json and format it so that each tab has all the references
# Maps with lowercase letters (a, b, etc.) go in a separate location
# Maps with uppercase Letters (B, F, etc.)
# These are named as: [Section Name] Location Name are in the same map, and should be in the same location
hub_children = {}
for filename in INPUT_FILES:
    data = load_jsonc(Path(filename))

    for source in data:
        map_name = source["name"]

        # Strip one uppercase suffix for hub grouping
        hub_name = re.sub(r"^(\d+-\d+)[A-Z]$", r"\1", map_name)

        if hub_name not in hub_children:
            hub_children[hub_name] = {
                "name": hub_name,
                "sections": [],
                "map_locations": [
                    {
                        "map": "Hub",
                        "x": HUB_MAP_POSITIONS[hub_name][0],
                        "y": HUB_MAP_POSITIONS[hub_name][1],
                    }
                ],
            }

        child = hub_children[hub_name]

        if "chest_unopened_img" in source:
            child["chest_unopened_img"] = source["chest_unopened_img"]

        if "chest_opened_img" in source:
            child["chest_opened_img"] = source["chest_opened_img"]

        for location in source["children"]:
            location_name = location["name"]

            for section in location["sections"]:
                section_name = section["name"]

                child["sections"].append({
                    "ref": f"{map_name}/{location_name}/{section_name}",
                    "name": f"[{section_name}] {location_name}",
                })

hub[0]["children"] = list(hub_children.values())

# Write the file
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    json.dump(hub, f, indent=2)

print(f"Wrote {OUTPUT_FILE}")