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

---Returns whether the player has unused items, given the item and all locations it's used
---@param mission_item string code for the item
---@param mission_item_locations array of strings of the locations the item is used
function has_unused_mission_item(mission_item, mission_item_locations)
    local used_items = 0
    for _, location in pairs(mission_item_locations) do
        if Tracker:FindObjectForCode(location).AvailableChestCount == 0 then
            used_items = used_items + 1
        end
    end

    return Tracker:ProviderCountForCode(mission_item) - used_items > 0
end

---Returns whether the player has an unused power cell
function has_unused_power_cell()
    return has_unused_mission_item(
        "power_cell",
        {
            "@1-1/Beacon Room/Activate Beacon",
            "@1-3B/Ladder After Box Jumps/Activate Beacon",
            "@1-3B/Bottom Right Near Boxes/Activate Beacon"
        }
    )
end

---Returns whether the player has an level 3 satchel charge
---TODO: add the locations when they are real
function has_unused_l3_satchel_charge()
    return has_unused_mission_item(
        "l3_satchel_charge",
        {
            
        }
    )
end

---Accessibility for map 3-4b, as a glitch can be used to get here early
---Returns whether the player can do the level 3 brdige jump to get to 3-4b, skipping a warp
---Includes whether the map can be accessed at all
function level_3_4b_access()
    if map_access(3, 4, "mid") then
        return AccessibilityLevel.Normal
    end

    if map_access(3, 3, "mid") then
        if has("level_3_bridge_jump") then
            return AccessibilityLevel.Normal
        else
            return AccessibilityLevel.SequenceBreak
        end
    end

    return AccessibilityLevel.None
end

---Checks the torpedo launcher requirement
---If not randomizing weapons, a vanilla torpedo launcher is available
---Else, check for either the weapon or the trick to skip it
function has_torpedo_launcher()
    return not has("randomize_weapons") or has("torpedo_launcher") or has("level_4_skip_torpedo_launcher")
end