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

---General map access, checking the level key, progressive warp, and weapon requirements
---@param level number
---@param warp number indicating the number of progressive warps required
---@param weapon_barrier_suffix string indicating which barrier (start/mid/end)
function map_access(level, warp, weapon_barrier_suffix)
    if not level_access(level) then
        return false
    end

    if not warp_requirement(level, warp) then
        return false
    end

    return has_weapon_requirement(level, weapon_barrier_suffix)
end

---Checks whether the warp requirements are met for the given level
---Returns true if no warp is passed
---@param warp number indicating the number of progressive warps required
---@param level number
function warp_requirement(level, warp)
    if warp == nil then
        return true
    end

    return has("progressive_warp_l" .. level, get_progressive_warps_needed(warp))
end

---Get how many progressive warps needed for the given warp number
---@param warp number indicating the number of progressive warps required
function get_progressive_warps_needed(warp)
    local progressive_warp_strength = Tracker:ProviderCountForCode("progressive_warps")
    if progressive_warp_strength == 0 then
        return true
    end

    return math.ceil(warp / progressive_warp_strength)
end

---Checks level access based on the key setting
---@param level number
function level_access(level)
    if has("level_unlock_method_all_level_keys") then
        -- Levels 1-5 need 3 keys, level 6 needs 6 keys
        local key_requirement = 3
        if level == 6 then
            key_requirement = 6
        end
        return has("level_" .. level .. "_key", key_requirement)
    end

    if has("level_unlock_method_one_level_key") then
        return has("level_" .. level .. "_key")
    end

    if has("level_unlock_method_one_progressive_warp") then
        return has("progressive_warp_l" .. level)
    end

    print("ERROR: Unknown level unlock setting")
    return false
end

---Checks level access based on the key setting
---Returns true if no barrier is passed in
---@param level number
---@param weapon_barrier_suffix string indicating which barrier (start/mid/end)
function has_weapon_requirement(level, weapon_barrier_suffix)
    if weapon_barrier_suffix == nil then
        return true
    end

    local weapon_setting_name = "weapon_barrier_level_" .. level .. "_" .. weapon_barrier_suffix
    local weapon_setting = Tracker:FindObjectForCode(weapon_setting_name)
    if weapon_setting == nil then
        print("ERROR - Weapon setting not found: " .. weapon_setting_name)
        return false
    end

    if weapon_setting.AcquiredCount == 0 then
        return true
    end

    local progressive_weapons = {
        "war_blade",
        "tek_bow",
        "pistol",
        "mag_60",
        "tranquilizer_gun",
        "charge_dart_rifle",
        "shotgun",
        "shredder",
        "plasma_rifle",
        "firestorm_cannon",
        "sunfire_pod",
        "cerebral_bore",
        "pfm_layer",
        "grenade_launcher",
        "scorpion_launcher",
        "flame_thrower",
        "razor_wind"
    }

    local unique_weapons_owned = 0
    for _, weapon_name in pairs(progressive_weapons) do
        if has(weapon_name) then
            unique_weapons_owned = unique_weapons_owned + 1
        end
    end
    
    return unique_weapons_owned >= weapon_setting.AcquiredCount
end

---Returns whether the player has an unused power cell
function has_unused_power_cell()
    local used_power_cells = 0
    if Tracker:FindObjectForCode("@1-1/Beacon Room/Activate Beacon").AvailableChestCount == 0 then
        used_power_cells = used_power_cells + 1
    end

    if Tracker:FindObjectForCode("@1-3B/Ladder After Box Jumps/Activate Beacon").AvailableChestCount == 0 then
        used_power_cells = used_power_cells + 1
    end

    if Tracker:FindObjectForCode("@1-3B/Bottom Right Near Boxes/Activate Beacon").AvailableChestCount == 0 then
        used_power_cells = used_power_cells + 1
    end

    return Tracker:ProviderCountForCode("power_cell") - used_power_cells > 0
end