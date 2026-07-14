import json
import re
from pathlib import Path

"""
Generates the Hub.jsonc file so the hub locations can be references to the real locations
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
    }
    # {
    #     "level_name": "level_6",
    #     "initial_position": (733, 108),
    #     "maps": [
    #        "6-Hub",
    #        "6-1",
    #        "6-2a",
    #        "6-2b",
    #        "6-3a",
    #        "6-3b",
    #        "6-4a",
    #        "6-4b",
    #        "6-4c",
    #        "6-4d",
    #        "6-O"
    #     ]
    # }
]

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