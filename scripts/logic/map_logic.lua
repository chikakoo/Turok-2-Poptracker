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


-- Level 2