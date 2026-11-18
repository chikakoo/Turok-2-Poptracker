---Logic used for map access

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


-- Level 5


-- Level 6

