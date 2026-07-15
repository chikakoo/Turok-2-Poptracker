import json
import re
from pathlib import Path

"""
Generates the Hub.jsonc file so the hub locations can be references to the real locations
It also validates the files to ensure that ids are unique/correct
"""

# Items are placed vertically for this many rows before starting a new column
ROWS = 4
X_OFFSET = 60
Y_OFFSET = 30

MAP_DATA = [
    {
        "level_name": "level_1",
        "initial_position": (674, 812),
        "maps": [
            "1-1",
            "1-2a",
            "1-3",
            "1-2b",
            "1-4",
            "1-5",
            "1-6",
            "1-7",
            "1-8",
            "1-9",
            "1-O"
        ]
    },
    {
        "level_name": "level_2",
        "initial_position": (837, 606),
        "maps": [
            "2-1",
            "2-2",
            "2-3",
            "2-4",
            "2-O",
            "2-5",
            "2-6a",
            "2-6b",
            "2-GY1",
            "2-6c",
            "2-7",
            "2-GY2",
            "2-8",
            "2-GY3"
        ]
    },
    {
        "level_name": "level_3",
        "initial_position": (109, 608),
        "maps": [
           "3-1",
           "3-A1",
           "3-2",
           "3-3",
           "3-O",
           "3-4a",
           "3-A2",
           "3-4b",
           "3-5",
           "3-6",
           "3-7",
           "3-A3",
           "3-8"
        ]
    },
    {
        "level_name": "level_4",
        "initial_position": (900, 382),
        "maps": [
           "4-1",
           "4-2",
           "4-3",
           "4-4",
           "4-V1",
           "4-5",
           "4-V2",
           "4-6a",
           "4-O",
           "4-7",
           "4-8a",
           "4-V3",
           "4-8b",
           "4-6b"
        ]
    },
    {
        "level_name": "level_5",
        "initial_position": (114, 351),
        "maps": [
           "5-1",
           "5-2",
           "5-3",
           "5-4",
           "5-5",
           "5-O",
           "5-6",
           "5-7",
           "5-8",
           "5-E1",
           "5-9",
           "5-E2",
           "5-E3",
           "5-MC",
           "5-10"
        ]
    },
    {
        "level_name": "level_6",
        "initial_position": (733, 108),
        "maps": [
           "6-Hub",
           "6-1",
           "6-2a",
           "6-2b",
           "6-3a",
           "6-3b",
           "6-4a",
           "6-4b",
           "6-4c",
           "6-4d",
           "6-O"
        ]
    }
]

# The output file name
OUTPUT_FILE = "Hub.jsonc"

# Validation state
id_locations = {} # id -> first location where it appeared
validation_errors = []
ID_EXISTS_RE = re.compile(r"^\$id_exists\|(.+)$")

def load_jsonc(path: Path):
    """
    Loads the jsonc file, removing the comments so that the library can parse it.
    """
    text = path.read_text(encoding="utf-8")
    text = re.sub(r"//.*?$", "", text, flags=re.MULTILINE)
    return json.loads(text)

def add_locations(hub_child, map_name, node, path):
    """
    Recursively walks the tree to create all hub references.

    Names are in the format:
    - [section_name] Path/To/Location/location_name
    """
    location_name = node["name"]
    current_path = path + [location_name]

    if "sections" in node:
        ref_path = "/".join([map_name] + current_path)

        if path:
            display_name = f"{'/'.join(path)}/{location_name}"
        else:
            display_name = f"{location_name}"

        for section in node["sections"]:
            validate_section(map_name, current_path, section)
            hub_child["sections"].append({
                "ref": f"{ref_path}/{section['name']}",
                "name": f"[{section['name']}] {display_name}"
            })

    for child in node.get("children", []):
        add_locations(hub_child, map_name, child, current_path)

def validate_section(map_name, path, section):
    """
    Validates a single section.

    path is a list of parent names, e.g.
    ["Land", "On Box"]
    """
    full_location = f"{map_name}/{'/'.join(path)}/{section['name']}"

    expected_count = section["item_count"]

    for rule in section.get("visibility_rules", []):
        match = ID_EXISTS_RE.match(rule)
        if not match:
            continue

        ids = match.group(1).split("|")

        # Count validation
        if len(ids) != expected_count:
            validation_errors.append(
                f"{full_location}: item_count={expected_count}, "
                f"but $id_exists has {len(ids)} ids ({', '.join(ids)})"
            )

        # Duplicate validation
        for id_string in ids:
            if id_string in id_locations:
                validation_errors.append(
                    f"Duplicate id {id_string}\n"
                    f"  First: {id_locations[id_string]}\n"
                    f"  Again: {full_location}"
                )
            else:
                id_locations[id_string] = full_location

# Skeleton of the hub object
hub = [
    {
        "name": "Hub",
        "chest_unopened_img": "images/items/life_forces/lf1.png",
        "chest_opened_img": "images/items/life_forces/lf1_bw.png",
        "children": []
    }
]

# Loop through the json and format it so that each tab has all the references
# These are named as: [Section Name] Location Name are in the same map, and should be in the same location
hub_children = {}
for map_data in MAP_DATA:
    level_name = map_data["level_name"]
    initial_position = map_data["initial_position"]
    for index, map_string in enumerate(map_data["maps"]):
        file_name = f"{level_name}/{map_string}.jsonc"
        x = initial_position[0] + ((index // ROWS) * X_OFFSET)
        y = initial_position[1] + ((index % ROWS) * Y_OFFSET)

        data = load_jsonc(Path(file_name))
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
                            "x": x,
                            "y": y
                        }
                    ],
                }

            child = hub_children[hub_name]

            for location in source["children"]:
                add_locations(child, map_name, location, [])

hub[0]["children"] = list(hub_children.values())

# Write any validation errrs
if validation_errors:
    print()
    print("=================")
    print("VALIDATION ERRORS")
    print("=================")

    for error in validation_errors:
        print(error)

    print()
    print(f"{len(validation_errors)} error(s) found.")

    raise SystemExit(1)
else:
    print("Validation passed.")

# Write the file
with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
    json.dump(hub, f, indent=2)

print(f"Wrote {OUTPUT_FILE}")