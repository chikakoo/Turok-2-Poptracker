-- put logic functions here using the Lua API: https://github.com/black-sliver/PopTracker/blob/master/doc/PACKS.md#lua-interface
-- don't be afraid to use custom logic functions. it will make many things a lot easier to maintain, for example by adding logging.
-- to see how this function gets called, check: locations/locations.json
require("scripts.autotracking.archipelago")

CAVE_DOOR_4_1 = "@4-1/Whispers/Whispers Drop/Unlock Cave Door"
CAVE_DOOR_4_3 = "@4-3/Cave Door Room/Unlock Cave Door"
CAVE_DOOR_4_V1 = "@4-V1/Cave Door Room/Unlock Cave Door"
CAVE_DOOR_4_6a = "@4-6a/Cave Door Room/Unlock Cave Door"
CAVE_DOOR_4_8a = "@4-8a/Path Bottom/Unlock Cave Door"
CAVE_DOOR_4_V3_LEFT = "@4-V3/Cave Door Right/Place Left Key"
CAVE_DOOR_4_V3_RIGHT = "@4-V3/Cave Door Right/Place Right Key"

PROGRESSIVE_WEAPONS = {
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

---One of the ion capacitors. Used to see if ion capacitors are shuffled, as either one or all will be.
ION_CAPACITOR_ID = "115011"

---Checks whether the id of the given location exists as a location in the seed
---Accepts any number of args and returns the number that do exist
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
        if tonumber(level) == 6 then
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

    local unique_weapons_owned = 0
    for _, weapon_name in pairs(PROGRESSIVE_WEAPONS) do
        if has(weapon_name) then
            unique_weapons_owned = unique_weapons_owned + 1
        end
    end
    
    return unique_weapons_owned >= weapon_setting.AcquiredCount
end

---Returns whether the player has fully cleared the given location
---@param checked_location string of the location to check
function has_check(checked_location)
    return Tracker:FindObjectForCode(checked_location).AvailableChestCount == 0
end

---Returns whether the player has unused items, given the item and all locations it's used
---@param mission_item string code for the item
---@param mission_item_locations array of strings of the locations the item is used
---@param count_to_check number indicating the number of mission items to check (defaults to 1)
function has_unused_mission_item(mission_item, mission_item_locations, count_to_check)
    if count_to_check == nil then
        count_to_check = 1
    end

    local used_items = 0
    for _, location in pairs(mission_item_locations) do
        if Tracker:FindObjectForCode(location).AvailableChestCount == 0 then
            used_items = used_items + 1
        end
    end

    return Tracker:ProviderCountForCode(mission_item) - used_items >= count_to_check
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

---Returns whether the player has an unused level 3 satchel charge
function has_unused_l3_satchel_charge()
    return has_unused_mission_item(
        "l3_satchel_charge",
        {
            "@3-A1/Back Room/Destroy Facility",
            "@3-A2/Back Room/Destroy Facility",
            "@3-A3/Back Room/Destroy Facility"
        }
    )
end

---Returns whether the player has an unused level 4 satchel charge
function has_unused_l4_satchel_charge()
    return has_unused_mission_item(
        "l4_satchel_charge",
        {
            "@4-V1/Cave Door/On Top Platform/Seal Vent",
            "@4-V2/On Top Platform/Seal Vent",
            "@4-V3/Cave Door/On Top Platform/Seal Vent"
        }
    )
end

---Returns whether the player has the given number of unused cave door keys
---@param count number of cave door keys to check for (defaults to 1)
function has_unused_cave_door_keys(count)
    if count == nil then
        count = 1
    end

    return has_unused_mission_item(
        "cave_door_key",
        {
            CAVE_DOOR_4_1,
            CAVE_DOOR_4_3,
            CAVE_DOOR_4_V1,
            CAVE_DOOR_4_6a,
            CAVE_DOOR_4_8a,
            CAVE_DOOR_4_V3_LEFT,
            CAVE_DOOR_4_V3_RIGHT
        },
        count
    )
end

---Returns whether the 4-1 cave door can be entered or opened.
---Min 1: Can get here from the start
---Max 7: All keys; completely optional door
function can_enter_cave_door_on_4_1()
    return can_enter_cave_door(1, 7, CAVE_DOOR_4_1)
end

---Returns whether the 4-3 cave door can be entered or opened.
---Min 1: Can get here from the start
---Max 2: Could open the 4-1 door, but can't progress without this one
function can_enter_cave_door_on_4_3()
    return can_enter_cave_door(1, 2, CAVE_DOOR_4_3)
end

---Returns whether the 4-V1 cave door can be entered or opened.
---Min 2: Must open the 4-3 door to get here
---Max 7: All keys; completely optional door
function can_enter_cave_door_on_4_V1()
    return can_enter_cave_door(2, 7, CAVE_DOOR_4_V1)
end

---Returns whether the 4-6a cave door can be entered or opened.
---Min 2: Must open the 4-3 door to get here
---Max 4: Could open the 4-1/4-V1 doors, but can't progress without this one
function can_enter_cave_door_on_4_6a()
    min_keys = 2 + number_of_cave_door_keys_used({CAVE_DOOR_4_1, CAVE_DOOR_4_V1})
    return can_enter_cave_door(min_keys, 4, CAVE_DOOR_4_6a)
end

---Returns whether the 4-8a cave door can be entered or opened.
---Min 3: Must open the 4-3/4-6a doors to get here
---Max 5: Could open the 4-1/4-V1 doors, but can't progress without this one
function can_enter_cave_door_on_4_8a()
    min_keys = 3 + number_of_cave_door_keys_used({CAVE_DOOR_4_1, CAVE_DOOR_4_V1})
    return can_enter_cave_door(min_keys, 5, CAVE_DOOR_4_8a)
end

---Returns whether the 4-V3 cave door can be entered.
---This one assumes that you can get to 4-V3 already, so it just checks whether both keys can be placed.
function can_enter_cave_door_on_4_v3()
    -- If you have the max keys, then you can definitely go in
    if has("cave_door_key", 7) then
        return AccessibilityLevel.Normal
    end

    needed_cave_door_keys = 2 - number_of_cave_door_keys_used({CAVE_DOOR_4_V3_LEFT, CAVE_DOOR_4_V3_RIGHT})

    -- No needed keys means both doors are open already
    if needed_cave_door_keys == 0 then
        return AccessibilityLevel.Normal
    end

    -- If the player doesn't have enough keys, then they cannot get here
    if not has_unused_cave_door_keys(needed_cave_door_keys) then
        return AccessibilityLevel.None
    end

    -- Else it means the player has enough, but isn't guaranteed to be able to enter
    return AccessibilityLevel.SequenceBreak
end

---Returns whether the boss room can be entered on level 4.
---This assumes that the boss portal can already be reached and does not include that key/torpedo logic.
function can_enter_4_boss()
    -- Ending weapon requirements and all 3 satchel charges are required
    if not has_weapon_requirement(4, "end") or not has("l4_satchel_charge", 3) then
        return AccessibilityLevel.None
    end

    -- All cave door keys means all objectives can be completed
    if has("cave_door_key", 7) then
        return AccessibilityLevel.Normal
    end

    -- If missing one key, it's out of logic unless the one optional door has been opened
    if has("cave_door_key", 6) and not (number_of_cave_door_keys_used({CAVE_DOOR_4_1}) > 0) then
        return AccessibilityLevel.SequenceBreak
    end

    -- Not enough keys (or the one optional one was used)
    return AccessibilityLevel.None
end

---Returns the number of the early cave door keys used for the given locations.
---This helps not show too many out of logic location when we know how deep it's possible to go.
function number_of_cave_door_keys_used(cave_door_locations)
    local used_keys = 0

    for _, location in pairs(cave_door_locations) do
        if Tracker:FindObjectForCode(location).AvailableChestCount == 0 then
            used_keys = used_keys + 1
        end
    end

    return used_keys
end

---Returns whether the cave door can be entered or opened.
---Also handles whether door has been opened already.
---@param max_keys number of keys to consider the door always able to be opened
---@param min_keys number of keys to consider the door to be openable, but not in logic
---@param cave_door_name string indicating the location name of the cave door being checked
function can_enter_cave_door(min_keys, max_keys, cave_door_name)
    -- If the door is open, you can go in it no matter what
    if cave_door_name ~= nil and Tracker:FindObjectForCode(cave_door_name).AvailableChestCount == 0 then
        return AccessibilityLevel.Normal
    end

    -- If you have no more keys left, you can't open another one
    if not has_unused_cave_door_keys() then
        return AccessibilityLevel.None
    end

    -- If you have the max keys, then you can definitely go in
    if has("cave_door_key", max_keys) then
        return AccessibilityLevel.Normal
    end

    -- If you have the min keys, then you can potentially use them elsewhere
    if has("cave_door_key", min_keys) then
        return AccessibilityLevel.SequenceBreak
    end

    -- Else, you can't enter (fallback)
    return AccessibilityLevel.None
end

---Checks the torpedo launcher requirement
---If not randomizing weapons, a vanilla torpedo launcher is available
---Else, check for either the weapon or the trick to skip it
function has_torpedo_launcher()
    return not has("randomize_weapons") or has("torpedo_launcher") or has("level_4_skip_torpedo_launcher")
end

---Returns whether the player can do the river of souls death jumps
---Normal: Has Breath of Life, or death jumps are in logic
---SequenceBreak: Out of logic (it's possible to get them still)
---None: Collection is impossible as the mod prevents it
function can_do_river_of_souls_death_jumps()
    if has("breath_of_life") or has("river_of_souls_death_jumps_in_logic") then
        return AccessibilityLevel.Normal
    end

    if has("river_of_souls_death_jumps_out_of_logic") then
        return AccessibilityLevel.SequenceBreak
    end

    -- Covers prevent collection
    return AccessibilityLevel.None
end

---Returns whether the player can do the jump through lava trick
---Normal: Has Heart of Fire, or can do the trick
---SequenceBreak: Out of logic (it's possible to get them still)
---None: Collection is impossible as the mod prevents it
function can_jump_through_lava()
    if has("heart_of_fire") or has("jump_through_lava_in_logic") then
        return AccessibilityLevel.Normal
    end

    if has("jump_through_lava_out_of_logic") then
        return AccessibilityLevel.SequenceBreak
    end

    -- Covers prevent collection
    return AccessibilityLevel.None
end

---Returns whether the player can do the level 5 jump to primagen key path trick
---Normal: Has Breath of Life (gets there normally), or can do the trick
---SequenceBreak: Out of logic (you can always do the trick, even if the setting is off)
function can_do_l5_jump_to_primagen_key_path()
    if has("breath_of_life") or has("level_5_jump_to_primagen_key_path") then
        return AccessibilityLevel.Normal
    end

    return AccessibilityLevel.SequenceBreak
end

---Returns the number of unused ion capacitors (returns 0 if it would return negative)
---We can only know this from generators that are completed recalibrated,
---so it is possible that there are more than what this reports back
function get_unused_ion_capacitors()
    local generator_locations = {
        "@6-1/Generator/Recalibrate Generator",
        "@6-2b/Generator/Recalibrate Generator",
        "@6-3b/Generator/Recalibrate Generator",
        "@6-4d/Generator/Generator/Recalibrate Generator"
    }

    local used_items = 0
    for _, location in pairs(generator_locations) do
        if Tracker:FindObjectForCode(location).AvailableChestCount == 0 then
            used_items = used_items + 4 -- Each generator uses 4 capacitors
        end
    end

    return math.max(0, Tracker:ProviderCountForCode("ion_capacitor") - used_items)
end

---Whether one of the generators can be purified
---Normal: 
---  Has all ion capacitors (16)
---  If not shuffling ion capacitors, it's always possible to get them all per map
---SequenceBreak: 
---  If not connected to AP (it's hard to know whether ion capacitors are shuffled)
---  Otherwise, if you have could have enough to place on this generator
---None: Not enough capacitors
function can_place_all_ion_capacitors()
    if has("ion_capacitor", 16) then
        return AccessibilityLevel.Normal
    end

    if Archipelago.PlayerNumber == -1 then
        return AccessibilityLevel.SequenceBreak
    end

    if not id_exists(ION_CAPACITOR_ID) then
        return AccessibilityLevel.Normal
    end

    if get_unused_ion_capacitors() >= 4 then
        return AccessibilityLevel.SequenceBreak
    end

    return AccessibilityLevel.None
end

---Whether a single ion capacitor can be placed (used for 6-2b)
---Normal: 
---  Has enough ion capacitors (13) such that you couldn't run out
---  If not shuffling ion capacitors, it's always possible to get them all per map
---  The capacitors were already placed (6-2b's generator was already recalibrated)
---SequenceBreak:
---  Has any unused ion capacitor, as it could potentially be placed elsewhere
---None: Not enough capacitors
function can_place_one_ion_capacitor()
    if has("ion_capacitor", 13) or 
        not id_exists(ION_CAPACITOR_ID) or
        Tracker:FindObjectForCode("@6-2b/Generator/Recalibrate Generator").AvailableChestCount == 0 then
        return AccessibilityLevel.Normal
    end

    if get_unused_ion_capacitors() > 0 then
        return AccessibilityLevel.SequenceBreak
    end

    return AccessibilityLevel.None
end