-- put logic functions here using the Lua API: https://github.com/black-sliver/PopTracker/blob/master/doc/PACKS.md#lua-interface
-- don't be afraid to use custom logic functions. it will make many things a lot easier to maintain, for example by adding logging.
-- to see how this function gets called, check: locations/locations.json
require("scripts.autotracking.archipelago")

---Checks whether the id of the given location exists as a location in the seed
---Accepts any number of args and returns the number of then that do exist
function id_exists(...)
    if Archipelago.PlayerNumber == -1 then
        return true
    end

    local args = {...}
    local count = #args

    for _, value in pairs(args) do
        if not ALL_LOCATIONS_MAP[tonumber(value)] then
            count = count - 1
        end
    end

    return count
end

--- Checks whether any location is unchecked, given the location table
function is_any_location_unchecked(location_table_name)
    local locations = _G[location_table_name]
    if locations == nil then
        print("Unknown location table: " .. location_table_name)
        return false
    end

    for _, location_array in pairs(locations) do
        for _, location in pairs(location_array) do
            local location_obj = Tracker:FindObjectForCode(location)

            if location_obj.AvailableChestCount > 0 then
                return true
            end
        end
    end

    return false
end