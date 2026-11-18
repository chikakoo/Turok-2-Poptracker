-- Level 1
function map_1_1_access()
     return map_access(1)
end

function map_1_2a_access()
    return map_access(1, 1)
end

function map_1_3_access()
    return has("endtrail_soul") and map_access(1, 2, "start")
end

function map_1_2b_access()
    return has("endtrail_soul") and map_access(1, 3, "start")
end

function map_1_4_access()
    return has("endtrail_soul") and map_access(1, 4, "start")
end

function map_1_5_access()
    return has("endtrail_soul") and map_access(1, 5, "mid")
end

function map_1_6_access()
    return has("endtrail_soul") and map_access(1, 6, "mid")
end

function map_1_7_access()
    return has("endtrail_soul") and map_access(1, 7, "mid")
end

function map_1_8_access()
    return has("endtrail_soul") and map_access(1, 8, "mid")
end

function map_1_9_access()
    return has("endtrail_soul") and map_access(1, 9, "mid")
end

function map_1_O_access()
    return has("endtrail_soul") and map_access(1, 9, "mid")
end

-- Level 2
function can_open_level_2_gate()
    return has_mission_items("gate_key", 2)
end

function can_exit_gy1()
    return has("deadman_soul") and has("lord_of_the_dead_soul") and has("sister_of_despair_soul")
end

function map_2_1_access()
    return map_access(2)
end

function map_2_2_access()
    return map_access(2, 1)
end

function map_2_3_access()
    return map_access(2, 2, "start")
end

function map_2_4_access()
    return has("endtrail_soul") and map_access(2, 3, "start")
end

function map_2_O_access()
    return has("endtrail_soul") and can_open_level_2_gate() and map_access(2, 3, "start")
end

function map_2_5_access()
    return has("endtrail_soul") and can_open_level_2_gate() and map_access(2, 4, "mid")
end

function map_2_6a_access()
    return has("endtrail_soul") and can_open_level_2_gate() and map_access(2, 5, "mid")
end

function map_2_6b_access()
    return has("endtrail_soul") and can_open_level_2_gate() and map_access(2, 6, "mid")
end

function map_2_gy1_access()
    return has("endtrail_soul") and can_open_level_2_gate() and map_access(2, 7, "mid")
end

function map_2_6c_access()
    return has("endtrail_soul") and can_open_level_2_gate() and can_exit_gy1() and map_access(2, 8, "mid")
end

function map_2_7_access()
    return has("endtrail_soul") and can_open_level_2_gate() and can_exit_gy1() and map_access(2, 9, "mid")
end

function map_2_gy2_access()
    return has("endtrail_soul") and can_open_level_2_gate() and can_exit_gy1() and map_access(2, 10, "mid")
end

function map_2_8_access()
    return has("endtrail_soul") and can_open_level_2_gate() and can_exit_gy1() and map_access(2, 10, "mid")
end

function map_2_gy3_access()
    return has("endtrail_soul") and can_open_level_2_gate() and can_exit_gy1() and map_access(2, 11, "mid")
end

-- Level 3
function map_3_1_access()
    return map_access(3)
end

function map_3_a1_access()
    return map_access(3, 1)
end

function map_3_2_access()
    return map_access(3, 1)
end

function map_3_3_access()
    return map_access(3, 2, "start")
end

function map_3_4a_access()
    return map_access(3, 3, "mid")
end

function map_3_a2_access()
    return map_access(3, 4, "mid")
end

function map_3_4b_access()
    if not map_3_4a_access() then
        return AccessibilityLevel.None
    end

    if map_access(3, 4, "mid") or has("level_3_bridge_jump") then
        return AccessibilityLevel.Normal
    end

    return AccessibilityLevel.SequenceBreak
end

function map_3_5_access()
    return map_access(3, 5, "mid")
end

function map_3_6_access()
    return has("juggernaut_soul") and map_access(3, 6, "mid")
end

function map_3_7_access()
    return has("juggernaut_soul") and map_access(3, 7, "mid")
end

function map_3_8_access()
    return has("juggernaut_soul") and map_access(3, 8, "mid")
end

function map_3_a3_access()
    return has("juggernaut_soul") and map_access(3, 8, "mid")
end

-- Level 4
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
    if has_mission_items("cave_door_key", max_keys) then
        return AccessibilityLevel.Normal
    end

    -- If you have the min keys, then you can potentially use them elsewhere
    if has_mission_items("cave_door_key", min_keys) then
        return AccessibilityLevel.SequenceBreak
    end

    -- Else, you can't enter (fallback)
    return AccessibilityLevel.None
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
            CAVE_DOOR_4_8,
            CAVE_DOOR_4_V3_LEFT,
            CAVE_DOOR_4_V3_RIGHT
        },
        count
    ) ~= AccessibilityLevel.None
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

---Returns whether the 4-8 cave door can be entered or opened.
---Min 3: Must open the 4-3/4-6a doors to get here
---Max 5: Could open the 4-1/4-V1 doors, but can't progress without this one
function can_enter_cave_door_on_4_8()
    min_keys = 3 + number_of_cave_door_keys_used({CAVE_DOOR_4_1, CAVE_DOOR_4_V1})
    return can_enter_cave_door(min_keys, 5, CAVE_DOOR_4_8)
end

---Returns whether the 4-V3 cave door can be entered.
---This one assumes that you can get to 4-V3 already, so it just checks whether both keys can be placed.
function can_enter_cave_door_on_4_v3()
    -- If you have the max keys, then you can definitely go in
    if has_mission_items("cave_door_key", 7) then
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

---Returns the accessibility given the cave door accessibility value.
---These are for checks beyond the torpedo launcher room.
---None: Can't pass the cave door
---SequenceBreak: Cave door or torpedo launcher can be passed out of logic
---Normal: Cave door and torpedo launcher is in logic
function cave_door_and_torpedo_launcher_accessibility(cave_door_accessibility)
    if cave_door_accessibility == AccessibilityLevel.None then
        return AccessibilityLevel.None
    end

    if cave_door_accessibility == AccessibilityLevel.SequenceBreak then
        return AccessibilityLevel.SequenceBreak
    end

    if has_torpedo_launcher() then
        return AccessibilityLevel.Normal
    end

    return AccessibilityLevel.SequenceBreak
end

function can_exit_4_3()
    return has("cave_spider_soul") and has("nala_soul")
end

function can_exit_4_4()
    return can_exit_4_3() and has("blind_sentinel_soul")
end

function can_exit_4_8a()
    return can_exit_4_4() and has("cave_worm_soul") and has("guardian_soul") and has("endtrail_soul")
end

function map_4_1_access()
    return map_access(4)
end

function map_4_2_access()
    return map_access(4, 1)
end

function map_4_3_access()
    return map_access(4, 2, "start")
end

function map_4_4_access()
    if not can_exit_4_3() or not map_access(4, 3, "mid") then
        return AccessibilityLevel.None
    end

    return can_enter_cave_door_on_4_3()
end

function map_4_v1_access()
    if not can_exit_4_4() or not map_access(4, 4, "mid") then
        return AccessibilityLevel.None
    end

    return can_enter_cave_door_on_4_3()
end

function map_4_5_access()
    if not can_exit_4_4() or not map_access(4, 4, "mid") then
        return AccessibilityLevel.None
    end

    return can_enter_cave_door_on_4_3()
end

function map_4_v2_access()
    if not can_exit_4_4() or not map_access(4, 5, "mid") then
        return AccessibilityLevel.None
    end

    return cave_door_and_torpedo_launcher_accessibility(can_enter_cave_door_on_4_3())
end

function map_4_6a_access()
    if not can_exit_4_4() or not map_access(4, 5, "mid") then
        return AccessibilityLevel.None
    end

    return cave_door_and_torpedo_launcher_accessibility(can_enter_cave_door_on_4_3())
end

function map_4_O_access()
    if not can_exit_4_4() or not map_access(4, 5, "mid") then
        return AccessibilityLevel.None
    end

    return cave_door_and_torpedo_launcher_accessibility(can_enter_cave_door_on_4_6a())
end

function map_4_7_access()
    if not can_exit_4_4() or not map_access(4, 6, "mid") then
        return AccessibilityLevel.None
    end

    return cave_door_and_torpedo_launcher_accessibility(can_enter_cave_door_on_4_6a())
end

function map_4_8a_access()
    if not can_exit_4_4() or not map_access(4, 7, "mid") then
        return AccessibilityLevel.None
    end

    return cave_door_and_torpedo_launcher_accessibility(can_enter_cave_door_on_4_6a())
end

function map_4_v3_access()
    if not can_exit_4_8a() or not map_access(4, 8, "mid") then
        return AccessibilityLevel.None
    end

    return cave_door_and_torpedo_launcher_accessibility(can_enter_cave_door_on_4_8())
end

function map_4_8b_access()
    if not can_exit_4_8a() or not map_access(4, 9, "mid") then
        return AccessibilityLevel.None
    end

    return cave_door_and_torpedo_launcher_accessibility(can_enter_cave_door_on_4_8())
end

function map_4_6b_access()
    if not can_exit_4_8a() or not map_access(4, 10, "mid") then
        return AccessibilityLevel.None
    end

    return cave_door_and_torpedo_launcher_accessibility(can_enter_cave_door_on_4_8())
end

---Returns whether the boss room can be entered on level 4.
---This assumes that the boss portal can already be reached and does not include that key/torpedo logic.
function can_enter_4_boss()
    -- Ending weapon requirements and all 3 satchel charges are required
    if not has_weapon_requirement(4, "end") or not has_mission_items("l4_satchel_charge", 3) then
        return AccessibilityLevel.None
    end

    -- All cave door keys means all objectives can be completed
    if has_mission_items("cave_door_key", 7) then
        return AccessibilityLevel.Normal
    end

    -- If missing one key, it's out of logic unless the one optional door has been opened
    if has_mission_items("cave_door_key", 6) and not (number_of_cave_door_keys_used({CAVE_DOOR_4_1}) > 0) then
        return AccessibilityLevel.SequenceBreak
    end

    -- Not enough keys (or the one optional one was used)
    return AccessibilityLevel.None
end

-- Level 5
function map_5_1_access()
    return map_access(5)
end

function map_5_2_access()
    return map_access(5, 1)
end

function map_5_3_access()
    return has("drone_soul") and map_access(5, 2, "start")
end

function map_5_4_access()
    return has("drone_soul") and map_access(5, 3, "start")
end

function map_5_5_access()
    return has("drone_soul") and map_access(5, 4, "start")
end

function map_5_O_access()
    return has("drone_soul") and map_access(5, 4, "start")
end

function map_5_6_access()
    return has("drone_soul") and map_access(5, 5, "start")
end

function map_5_7_access()
    return has("drone_soul") and map_access(5, 6, "start")
end

function map_5_8_access()
    return has("drone_soul") and map_access(5, 7, "mid")
end

function map_5_e1_access()
    return has("drone_soul") and map_access(5, 8, "mid")
end

function map_5_9_access()
    return has("drone_soul") and map_access(5, 9, "mid")
end

function map_5_e2_access()
    return has("drone_soul") and map_access(5, 10, "mid")
end

function map_5_e3_access()
    return has("drone_soul") and map_access(5, 10, "mid")
end

function map_5_10_access()
    if not has("drone_soul") or not map_access(5, 10, "mid") then
        return AccessibilityLevel.None
    end

    return can_do_l5_jump_to_primagen_key_path()
end

function map_5_mc_access()
    return has("drone_soul") and map_access(5, 10, "mid")
end

-- Level 6
