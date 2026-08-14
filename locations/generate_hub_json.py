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
        "maps": {
            "1-1": { "starting_id": 51000 },
            "1-2a": { "starting_id": 52000 },
            "1-3": { "starting_id": 53000 },
            "1-2b": { "starting_id": 52000 },
            "1-4": { "starting_id": 55000 },
            "1-5": { "starting_id": 54000 },
            "1-6": { "starting_id": 56000 },
            "1-7": { "starting_id": 57000 },
            "1-8": { "starting_id": 58000 },
            "1-9": { "starting_id": 59000 },
            "1-O": { "starting_id": 78000 },
        }
    },
    {
        "level_name": "level_2",
        "initial_position": (837, 606),
        "maps": {
            "2-1": { "starting_id": 125000 },
            "2-2": { "starting_id": 126000 },
            "2-3": { "starting_id": 127000 },
            "2-4": { "starting_id": 128000 },
            "2-O": { "starting_id": 79000 },
            "2-5": { "starting_id": 129000 },
            "2-6a": { "starting_id": 130000 },
            "2-6b": { "starting_id": 130000 },
            "2-GY1": { "starting_id": 133000 },
            "2-6c": { "starting_id": 130000 },
            "2-7": { "starting_id": 131000 },
            "2-GY2": { "starting_id": 134000 },
            "2-8": { "starting_id": 132000, "extra_ids": [73000] },
            "2-GY3": { "starting_id": 135000 }
        }
    },
    {
        "level_name": "level_3",
        "initial_position": (109, 608),
        "maps": {
           "3-1": { "starting_id": 61000 },
           "3-A1": { "starting_id": 69000 },
           "3-2": { "starting_id": 62000 },
           "3-3": { "starting_id": 63000 },
           "3-O": { "starting_id": 80000 },
           "3-4a": { "starting_id": 64000 },
           "3-A2": { "starting_id": 70000 },
           "3-4b": { "starting_id": 64000 },
           "3-5": { "starting_id": 65000 },
           "3-6": { "starting_id": 66000, "extra_ids": [74000] },
           "3-7": { "starting_id": 67000 },
           "3-A3": { "starting_id": 71000 },
           "3-8": { "starting_id": 68000 }
        }
    },
    {
        "level_name": "level_4",
        "initial_position": (900, 382),
        "maps": {
           "4-1": { "starting_id": 98000 },
           "4-2": { "starting_id": 99000, "extra_ids": [75000] },
           "4-3": { "starting_id": 100000 },
           "4-4": { "starting_id": 101000 },
           "4-V1": { "starting_id": 106000 },
           "4-5": { "starting_id": 102000 },
           "4-V2": { "starting_id": 107000 },
           "4-6a": { "starting_id": 103000 },
           "4-O": { "starting_id": 81000 },
           "4-7": { "starting_id": 104000 },
           "4-8a": { "starting_id": 105000 },
           "4-V3": { "starting_id": 108000 },
           "4-8b": { "starting_id": 105000 },
           "4-6b": { "starting_id": 103000, "extra_ids": [1000] }
        }
    },
    {
        "level_name": "level_5",
        "initial_position": (114, 351),
        "maps": {
           "5-1": { "starting_id": 124000 },
           "5-2": { "starting_id": 84000 },
           "5-3": { "starting_id": 85000 },
           "5-4": { "starting_id": 86000 },
           "5-5": { "starting_id": 87000 },
           "5-O": { "starting_id": 82000 },
           "5-6": { "starting_id": 88000, "extra_ids": [76000] },
           "5-7": { "starting_id": 89000 },
           "5-8": { "starting_id": 90000 },
           "5-E1": { "starting_id": 94000 },
           "5-9": { "starting_id": 91000 },
           "5-E2": { "starting_id": 95000 },
           "5-E3": { "starting_id": 96000 },
           "5-MC": { "starting_id": 93000 },
           "5-10": { "starting_id": 92000 }
        }
    },
    {
        "level_name": "level_6",
        "initial_position": (733, 108),
        "maps": {
           "6-Hub": { "starting_id": 114000 },
           "6-1": { "starting_id": 115000 },
           "6-2a": { "starting_id": 116000 },
           "6-2b": { "starting_id": 117000 },
           "6-3a": { "starting_id": 118000 },
           "6-3b": { "starting_id": 119000 },
           "6-4a": { "starting_id": 120000 },
           "6-4b": { "starting_id": 121000, "extra_ids": [77000] },
           "6-4c": { "starting_id": 122000 },
           "6-4d": { "starting_id": 123000 },
           "6-O": { "starting_id": 83000 }
        }
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

def add_locations(hub_child, map_name, starting_id, node, path):
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
            validate_section(map_name, starting_id, current_path, section)
            hub_child["sections"].append({
                "ref": f"{ref_path}/{section['name']}",
                "name": f"[{section['name']}] {display_name}"
            })

    for child in node.get("children", []):
        add_locations(hub_child, map_name, starting_id, child, current_path)

def validate_section(map_name, starting_id, path, section):
    """
    Validates a single section.

    path is a list of parent names, e.g.
    ["Land", "On Box"]
    """
    full_location = f"{map_name}/{'/'.join(path)}/{section['name']}"

    expected_count = section["item_count"]

    ranges = [(starting_id, starting_id + 999)]
    for extra_id in map_info.get("extra_ids", []):
        ranges.append((extra_id, extra_id))

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

        for id_string in ids:
            # Valid id check
            try:
                location_id = int(id_string)
            except ValueError:
                validation_errors.append(
                    f"{full_location}: invalid location ID '{id_string}' "
                    f"(expected an integer)"
                )
                continue

            # Duplicate check
            if location_id in id_locations:
                validation_errors.append(
                    f"Duplicate ID {location_id}\n"
                    f"  First: {id_locations[location_id]}\n"
                    f"  Again: {full_location}"
                )
            else:
                id_locations[location_id] = full_location

            # Range check
            if not any(start <= location_id <= end for start, end in ranges):
                validation_errors.append(
                    f"{full_location}: ID {location_id} is outside the valid range "
                    f"({starting_id}-{starting_id + 999})"
                )

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
    for index, (map_string, map_info) in enumerate(map_data["maps"].items()):
        starting_id = map_info["starting_id"]
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
                add_locations(child, map_name, starting_id, location, [])

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