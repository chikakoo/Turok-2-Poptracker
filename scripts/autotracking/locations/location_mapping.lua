require("scripts.autotracking.locations.level_1")
require("scripts.autotracking.locations.level_2")
--require("scripts.autotracking.locations.level_3")
--require("scripts.autotracking.locations.level_4")
--require("scripts.autotracking.locations.level_5")
--require("scripts.autotracking.locations.level_6")

LOCATION_MAPPING = concat_tables(
	-- Level 1
	LOCATIONS_1_1,
	LOCATIONS_1_2a,
	LOCATIONS_1_3,
	LOCATIONS_1_2b,
	LOCATIONS_1_4,
	LOCATIONS_1_5,
	LOCATIONS_1_6,
	LOCATIONS_1_7,
	LOCATIONS_1_8,
	LOCATIONS_1_9,
	LOCATIONS_1_O,

	-- Level 2
	LOCATIONS_2_1,
	LOCATIONS_2_2,
	LOCATIONS_2_3,
	LOCATIONS_2_4,
	LOCATIONS_2_O,
	LOCATIONS_2_5,
	LOCATIONS_2_6a,
	LOCATIONS_2_6b,
	LOCATIONS_2_GY1,
	LOCATIONS_2_6c,
	LOCATIONS_2_7,
	LOCATIONS_2_GY2,
	LOCATIONS_2_8,
	LOCATIONS_2_GY3
)