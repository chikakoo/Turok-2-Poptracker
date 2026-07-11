require("scripts.autotracking.item_mapping")
require("scripts.autotracking.location_mapping")

CUR_INDEX = -1

ALL_LOCATIONS = {}
ALL_LOCATIONS_MAP = {}
SLOT_DATA = {}

MANUAL_CHECKED = true
ROOM_SEED = "default"
TROLL_PLAYER = false

if Highlight then
    HIGHLIGHT_LEVEL = {
        [0] = Highlight.Unspecified,
        [10] = Highlight.NoPriority,
        [20] = Highlight.Avoid,
        [30] = Highlight.Priority,
        [40] = Highlight.None,
        [100] = Highlight.Unspecified, --Filler
        [101] = Highlight.Priority, --Progression
        [102] = Highlight.NoPriority, --Useful
        [103] = Highlight.Priority, -- Prog + Useful
        [104] = Highlight.Avoid, --Trap
        [105] = Highlight.Priority, -- Prog + Trap
        [106] = Highlight.NoPriority, -- Useful + Trap
        [107] = Highlight.Priority, -- Prog + Useful + Trap
    }
end

Troll_Lookup = {
    ["solarcell"] = true,
    ["earthor"] = true,
}

---function to build a pretty-printable representation of a provided table
---@param o table
---@param depth? integer
---@return string
function DumpTable(o, depth)
    if depth == nil then
        depth = 0
    end
    if type(o) == 'table' then
        local tabs = ('\t'):rep(depth)
        local tabs2 = ('\t'):rep(depth + 1)
        local s = '{\n'
        for k, v in pairs(o) do
            if type(k) ~= 'number' then
                k = '"' .. k .. '"'
            end
            s = s .. tabs2 .. '[' .. k .. '] = ' .. DumpTable(v, depth + 1) .. ',\n'
        end
        return s .. tabs .. '}'
    else
        return tostring(o)
    end
end

---helper function that gets called when a LocationSection has changed state.
---checks if the interaction was from the server or manual.
---if manual, puts it into a cache for keeping that LocationSection toggled when reconnecting
---@param location LocationSection
function LocationHandler(location)
    if MANUAL_CHECKED then
        local custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
        if not custom_storage_item then
            return
        end
        if Archipelago.PlayerNumber == -1 then -- not connected
            if ROOM_SEED ~= "default" then -- seed is from previous connection
                ROOM_SEED = "default"
                custom_storage_item.MANUAL_LOCATIONS["default"] = {}
            else -- seed is default
            end
        end
        local full_path = location.FullID
        if not custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] then
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] = {}
        end
        if location.AvailableChestCount < location.ChestCount then --add to list
            -- print("add to list")
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][full_path] = location.AvailableChestCount
        else --remove from list of set back to max chestcount
            -- print("remove from list")
            custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][full_path] = nil
        end
    end
    -- local custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
    -- print(DumpTable(storage_item.ItemState.MANUAL_LOCATIONS))
    ForceUpdate() --
end

--function to force an update even if the interaction within poptracker noramlly would not call for a state update
function ForceUpdate()
    local update = Tracker:FindObjectForCode("update")
    if update == nil then
        return
    end
    update.Active = not update.Active
end

---resets a given item back to default or what's saved for the given seed in the pseuso-cache LuaItems
---@param item_type string table of the ItemCode and extra parameters from the Item_Mapping.lau
---@param item_obj JsonItem Tracker:FindObjectForCode(item) return object
---@param item_code string Reference for the custom LuaItem CachesItems
local function ItemReset(item_type, item_obj, item_code)
    if item_obj.Type == "toggle" then
        item_obj.Active = false
    elseif item_obj.Type == "progressive" then
        item_obj.CurrentStage = 0
    elseif item_obj.Type == "consumable" then
        if item_obj.MinCount then
            item_obj.AcquiredCount = item_obj.MinCount
        else
            item_obj.AcquiredCount = 0
        end
    elseif item_obj.Type == "progressive_toggle" then
        item_obj.CurrentStage = 0
        item_obj.Active = false
    end
end

---resets a given location back to default or whats saved for the gives seed in the pseuso-cache LuaItems
---@param location string String of the Location or LocatioSection to reset
---@param location_obj JsonItem|LocationSection Tracker:FindObjectForCode(location) return object
---@param custom_storage_item table Reference for the custom LuaItem CachesItems
local function LocationReset(location, location_obj, custom_storage_item)
    if location:sub(1, 1) == "@" then
        ---@cast location_obj LocationSection
        if custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][location_obj.FullID] then
            location_obj.AvailableChestCount = custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED][location_obj.FullID]
        else
            location_obj.AvailableChestCount = location_obj.ChestCount
        end
        location_obj.Highlight = HIGHLIGHT_LEVEL[40]
    else
        ---@cast location_obj JsonItem
        location_obj.Active = false
    end
end


--- Function to prepare custom LuaItems for caching, check for mischieve/traps, subscribe to datastorage
local function PreOnClear()
    PLAYER_ID = Archipelago.PlayerNumber or -1
	TEAM_NUMBER = Archipelago.TeamNumber or 0
    if PLAYER_ID > -1 then
        for key, _ in pairs(Troll_Lookup) do
            if string.find(string.lower(Archipelago:GetPlayerAlias(PLAYER_ID)), key, 1, true) ~= nil then
                TROLL_PLAYER = true
                break
            end
        end

        if #ALL_LOCATIONS > 0 then
            ALL_LOCATIONS = {}
        end
        for _, value in pairs(Archipelago.MissingLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end

        for _, value in pairs(Archipelago.CheckedLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
        end
        ---add more of those for other datastorage keys
        HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
        Archipelago:SetNotify({HINTS_ID}) --{HINTS_ID, other vars, ...}
        Archipelago:Get({HINTS_ID}) --{HINTS_ID, other vars, ...}
    end


    -- print(Archipelago.Seed)
    local seed_base = (Archipelago.Seed or tostring(#ALL_LOCATIONS)).."_"..Archipelago.TeamNumber.."_"..Archipelago.PlayerNumber
    if ROOM_SEED == "default" or ROOM_SEED ~= seed_base then -- seed is default or from previous connection

        ROOM_SEED = seed_base --something like 2345_0_12
        for _, custom_item_code in pairs({"manual_location_storage"}) do -- add more to the table if you created more storage cache items
            local custom_storage_item = Tracker:FindObjectForCode(custom_item_code).ItemState
            if custom_storage_item then
                if #custom_storage_item.MANUAL_LOCATIONS > 10 then
                    custom_storage_item.MANUAL_LOCATIONS[custom_storage_item.MANUAL_LOCATIONS_ORDER[1]] = nil
                    table.remove(custom_storage_item.MANUAL_LOCATIONS_ORDER, 1)
                end
                if custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] == nil then
                    custom_storage_item.MANUAL_LOCATIONS[ROOM_SEED] = {}
                    table.insert(custom_storage_item.MANUAL_LOCATIONS_ORDER, ROOM_SEED)
                end
            end
        end
    else -- seed is from previous connection
        -- do nothing
    end
end

---Called when the pack connects to an AP server
---@param slot_data? table Slotdata send from AP server for the specific user/slot
function OnClear(slot_data)
    MANUAL_CHECKED = false
    local custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
    if custom_storage_item == nil then
        CreateLuaManualStorageItem("manual_location_storage")
        custom_storage_item = Tracker:FindObjectForCode("manual_location_storage").ItemState
    end
    -- repeat that here for every cache-storage item you create just to be safe

    PreOnClear()

    ScriptHost:RemoveWatchForCode("StateChanged")
    ScriptHost:RemoveOnLocationSectionHandler("location_section_change_handler")

    CUR_INDEX = -1
    -- reset locations
    for _, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
				---@type LocationSection
                local location_obj = Tracker:FindObjectForCode(location)
                if location_obj then
                    LocationReset(location, location_obj, custom_storage_item)
                end
            end
        end
    end

    -- reset items
    for _, item_array in pairs(ITEM_MAPPING) do
        for _, item_pair in pairs(item_array) do
            local item_code = item_pair[1]
            local item_type = item_pair[2]
            -- print("on clear", item_code, item_type)
			---@type JsonItem
            local item_obj = Tracker:FindObjectForCode(item_code)
            if item_obj then
                ItemReset(item_type, item_obj, item_code)
            end
        end
    end
    PLAYER_ID = Archipelago.PlayerNumber or -1
    TEAM_NUMBER = Archipelago.TeamNumber or 0
    SLOT_DATA = slot_data

    if Tracker:FindObjectForCode("autofill_settings").Active == true then
         AutoFill(slot_data)
    end

    -- print(PLAYER_ID, TEAM_NUMBER)
    if Archipelago.PlayerNumber > -1 then
        if #ALL_LOCATIONS > 0 then
            ALL_LOCATIONS = {}
        end
        for _, value in pairs(Archipelago.MissingLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
            ALL_LOCATIONS_MAP[value] = true
        end

        for _, value in pairs(Archipelago.CheckedLocations) do
            table.insert(ALL_LOCATIONS, #ALL_LOCATIONS + 1, value)
            ALL_LOCATIONS_MAP[value] = true
        end

        HINTS_ID = "_read_hints_"..TEAM_NUMBER.."_"..PLAYER_ID
        Archipelago:SetNotify({HINTS_ID})
        Archipelago:Get({HINTS_ID})
    end

    -- Mark off items that are % checks (if not in AP, it should be marked off)
    for location_id, location_array in pairs(LOCATION_MAPPING) do
        for _, location in pairs(location_array) do
            if location then
                if not ALL_LOCATIONS_MAP[tonumber(location_id)] then
                    ---@type LocationSection
                    local location_obj = Tracker:FindObjectForCode(location)
                    if location_obj and location:sub(1, 1) == "@" then
                        location_obj.AvailableChestCount = location_obj.AvailableChestCount - 1
                    end
                end
            end
        end
    end

    ScriptHost:AddOnFrameHandler("load handler", OnFrameHandler)
    MANUAL_CHECKED = true
end

---Run every time an Item gets sent to the connected slot
---@param index integer running index for the items the connected slot has received so far
---@param item_id integer ID of the received item, matching the game's datapackage ID
---@param item_name string name of the item from the datapackage for the given itemID
---@param player_number integer slotnumber of the player who picked up the item
function OnItem(index, item_id, item_name, player_number)
    if index <= CUR_INDEX then
        return
    end
    local is_local = player_number == Archipelago.PlayerNumber
    CUR_INDEX = index;
    local item = ITEM_MAPPING[item_id]
    if not item or not item[1] then
        --print(string.format("OnItem: could not find item mapping for id %s", item_id))
        return
    end
    for _, item_pair in pairs(item) do
        local item_code = item_pair[1]
        local item_type = item_pair[2]
        local consumable_multiplier = tonumber(item_pair[3]) or 1

        local item_obj = Tracker:FindObjectForCode(item_code)
        if item_obj then
            if item_obj.Type == "toggle" then
                -- print("toggle")
                item_obj.Active = true
            elseif item_obj.Type == "progressive" then
                -- print("progressive")
                if item_obj.Active == true then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            elseif item_obj.Type == "consumable" then
                -- print("consumable")
                item_obj.AcquiredCount = item_obj.AcquiredCount + item_obj.Increment * consumable_multiplier
            elseif item_obj.Type == "progressive_toggle" then
                -- print("progressive_toggle")
                if item_obj.Active then
                    item_obj.CurrentStage = item_obj.CurrentStage + 1
                else
                    item_obj.Active = true
                end
            end
        else
            print(string.format("OnItem: could not find object for code %s", item_code))
        end
    end
end

---called when a location gets cleared
---@param location_id integer ID of the location cleared from the datapackage
---@param location_name string name of the location cleared from the datapackage
function OnLocation(location_id, location_name)
    MANUAL_CHECKED = false
    local location_array = LOCATION_MAPPING[location_id]
    if not location_array or not location_array[1] then
        print(string.format("OnLocation: could not find location mapping for id %s", location_id))
        return
    end

    for _, location in pairs(location_array) do
        local location_obj = Tracker:FindObjectForCode(location)
        -- print(location, location_obj)
        if location_obj then
            if location:sub(1, 1) == "@" then
                (location_obj --[[@as LocationSection]]).AvailableChestCount = location_obj.AvailableChestCount - 1
            else
                (location_obj --[[@as JsonItem]]).Active = true
            end
        else
            print(string.format("OnLocation: could not find location_object for code %s", location))
        end
    end
    MANUAL_CHECKED = true
end

---Called from the client to update the current map
---Contains json containing the tab to switch to
---@param json json containing the map and section used to switch tabs
function OnBounce(json)
    local data = json["data"]
    if data then
        if data["type"] == "MapUpdate" then
            Tracker:UiHint("ActivateTab", data["map"])
            Tracker:UiHint("ActivateTab", data["section"])
        end
    end
end

---Populates the settings based on the slot data
---@param slot_data table containing the slot data
function AutoFill(slot_data)
    if not Tracker:FindObjectForCode("autofill_settings").Active then
        return
    end

    print(DumpTable(slot_data))

    slotCodes = {
        -- Goals
        level_goal = { code = "level_goal" },
        primagen_goal = { code = "primagen_goal", mapping = { [0]=false, [1]=true, [2]=true} },

        -- Included levels
        include_level_1 = { code=  "include_level_1" },
        include_level_2 = { code = "include_level_2" },
        include_level_3 = { code = "include_level_3" },
        include_level_4 = { code = "include_level_4" },
        include_level_5 = { code = "include_level_5" },
        include_level_6 = { code = "include_level_6" },

        -- Progressions
        progressive_warps = { code = "progressive_warps" },
        level_unlock_method = { code = "level_unlock_method" },
        progressive_weapon_ammo_upgrades = {  code = "level_unlock_method" },

        -- Weapon Barriers
        weapon_barrier_level_1_start = { code = "weapon_barrier_level_1_start" },
        weapon_barrier_level_1_mid = { code = "weapon_barrier_level_1_mid" },
        weapon_barrier_level_1_end = { code = "weapon_barrier_level_1_end" },
        weapon_barrier_level_2_start = { code = "weapon_barrier_level_2_start" },
        weapon_barrier_level_2_mid = { code = "weapon_barrier_level_2_mid" },
        weapon_barrier_level_2_end = { code = "weapon_barrier_level_2_end" },
        weapon_barrier_level_3_start = { code = "weapon_barrier_level_3_start" },
        weapon_barrier_level_3_mid = { code = "weapon_barrier_level_3_mid" },
        weapon_barrier_level_3_end = { code = "weapon_barrier_level_3_end" },
        weapon_barrier_level_4_start = { code = "weapon_barrier_level_4_start" },
        weapon_barrier_level_4_mid = { code = "weapon_barrier_level_4_mid" },
        weapon_barrier_level_4_end = { code = "weapon_barrier_level_4_end" },
        weapon_barrier_level_5_start = { code = "weapon_barrier_level_5_start" },
        weapon_barrier_level_5_mid = { code = "weapon_barrier_level_5_mid" },
        weapon_barrier_level_5_end = { code = "weapon_barrier_level_5_end" },
        weapon_barrier_level_6_start = { code = "weapon_barrier_level_6_start" },
        weapon_barrier_level_6_mid = { code = "weapon_barrier_level_6_mid" },
        weapon_barrier_level_6_end = { code = "weapon_barrier_level_6_end" },
        weapon_barrier_primagen = { code = "weapon_barrier_primagen" },
        
        -- Tricks
        level_3_river_ledge_jump = { code = "level_3_river_ledge_jump" },
        level_3_bridge_jump = { code = "level_3_bridge_jump" },
        level_3_eye_of_truth_skip = { code = "level_3_eye_of_truth_skip" },
        level_4_skip_torpedo_launcher = { code = "level_4_skip_torpedo_launcher" },
        level_6_eye_of_truth_skip = { code = "level_6_eye_of_truth_skip" },
        river_of_souls_death_jumps = { code = "river_of_souls_death_jumps" },
        jump_through_lava = { code = "jump_through_lava" }
    }

    for settings_name, settings_value in pairs(slot_data) do
        settingData = slotCodes[settings_name]
        if settingData then
            item = Tracker:FindObjectForCode(settingData.code)
            if item.Type == "toggle" then
                if settingData.mapping then
                    item.Active = settingData.mapping[settings_value]
                else
                    item.Active = settings_value
                end
            elseif item.Type == "consumable" then
                item.AcquiredCount = settings_value
            elseif item.Type == "progressive" then
                item.CurrentStage = settings_value
            else
                print("WARNING - Setting not mapped: " .. settings_name)
            end
        end
    end
end

---Sets the progressive warp max counts according to the value here
function OnProgressiveWarps()
    local default_max_values = { 9, 11, 8, 10, 10, 13 }
    local progressive_warp_strength = Tracker:FindObjectForCode("progressive_warps").AcquiredCount
    local progressive_warp_settings = {
        "progressive_warp_l1", "progressive_warp_l2", "progressive_warp_l3", 
        "progressive_warp_l4", "progressive_warp_l5", "progressive_warp_l6"
    }
    for i, value in ipairs(progressive_warp_settings) do
        if progressive_warp_strength == 0 then
            Tracker:FindObjectForCode(value).MaxCount = 0
        else
            local max_progressive_warps
            if progressive_warp_strength == 0 then
                max_progressive_warps = 0
            else
                max_progressive_warps = math.ceil(default_max_values[i] / progressive_warp_strength)
            end
            Tracker:FindObjectForCode(value).MaxCount = max_progressive_warps
        end
    end
end

---Sets the level key max counts according to the level unlock method setting
function OnLevelUnlockMethod()
    local level_key_settings = {
        "level_1_key", "level_2_key", "level_3_key", "level_4_key", "level_5_key", "level_6_key"
    }

    -- Set the vanilla counts
    if has("level_unlock_method_all_level_keys") then
        for _, value in pairs(level_key_settings) do
            Tracker:FindObjectForCode(value).MaxCount = 3
        end
        Tracker:FindObjectForCode("level_6_key").MaxCount = 6
        return
    end

    -- Keys should be 1 or 0, depending on if they're included
    local level_key_max_count = -1
    if has("level_unlock_method_one_level_key") then
        level_key_max_count = 1
    elseif has("level_unlock_method_one_progressive_warp") then
        level_key_max_count = 0
    end

    if level_key_max_count > -1 then
        for _, value in pairs(level_key_settings) do
            Tracker:FindObjectForCode(value).MaxCount = level_key_max_count
        end
    else
        print("ERROR - Unknown level_unlock_method value: " .. Tracker:FindObjectForCode("level_unlock_method").CurrentStage)
    end
end

---Sets the weapon max ammo counts according to the progressive weapon ammo upgrades setting
function OnProgressiveWeaponAmmoUpgrades()
    local progressive_weapon_ammo_upgrades = Tracker:FindObjectForCode("progressive_weapon_ammo_upgrades").AcquiredCount
    local weapons_with_ammo = {
        "tek_bow", "pistol", "mag_60", "tranquilizer_gun", "charge_dart_rifle",
        "shotgun", "shredder", "plasma_rifle", "firestorm_cannon", "sunfire_pod",
        "cerebral_bore", "pfm_layer", "grenade_launcher", "scorpion_launcher", "flame_thrower",
        "harpoon_gun", "torpedo_launcher"
    }
    for _, value in pairs(weapons_with_ammo) do
        Tracker:FindObjectForCode(value).MaxCount = progressive_weapon_ammo_upgrades
    end
end

---@class APHintMessage
---@field receiving_player integer
---@field finding_player integer
---@field location integer
---@field item integer
---@field found boolean
---@field entrance string
---@field item_flags 0|1|2|3|4|5|6|7
---@field status 0|10|20|30|40

---function to update the Highlight of a LocationSection to represent the status of the hint that is present
---for that LocationSection
---@param locationID integer ID of the locations the hint is being given for
---@param status 0|10|20|30|40|100|101|102|103|104|105|106|107 status to determine the color of the hint glow
local function UpdateHints(locationID, status) -->
    if Highlight then
        -- print(locationID, status)
        local location_table = LOCATION_MAPPING[locationID]
        for _, location in ipairs(location_table) do
            if location:sub(1, 1) == "@" then
				---@type LocationSection
                local obj = Tracker:FindObjectForCode(location)

                if obj then
                    if TROLL_PLAYER and HIGHLIGHT_LEVEL[status] == Highlight.Avoid then
                        obj.Highlight = HIGHLIGHT_LEVEL[30]
                    else
                        obj.Highlight = HIGHLIGHT_LEVEL[status]
                    end
                else
                    print(string.format("No object found for code: %s", location))
                end
            end
        end
    end
end

---triggers as AP sends live updates from the server using a given key we subscribed to in Archipelago:SetNotify
---@param key string Name of the key that was used to send the message
---@param value table<integer, APHintMessage>
---@param old_value table<integer, APHintMessage>
function OnNotify(key, value, old_value)
    print("OnNotify", key, value, old_value)
    if value ~= old_value and key == HINTS_ID then
        Tracker.BulkUpdate = true
        for _, hint in ipairs(value) do
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.status == 0 then
                    UpdateHints(hint.location, 100+hint.item_flags)
                else
                    UpdateHints(hint.location, hint.status)
                end
            end
        end
        Tracker.BulkUpdate = false
    end
end

---triggers on connecting to AP when we receive this message from the server after providing a given key to Archipelago:Get
---@param key string Name of the key that was used to send the message
---@param value table<integer, APHintMessage>
function OnNotifyLaunch(key, value)
    if key == HINTS_ID then
        Tracker.BulkUpdate = true
        for _, hint in ipairs(value) do
            if hint.finding_player == Archipelago.PlayerNumber then
                if hint.status == 0 then
                    UpdateHints(hint.location, 100+hint.item_flags)
                else
                    UpdateHints(hint.location, hint.status)
                end
            end
        end
        Tracker.BulkUpdate = false
    end
end

--doc
--hint layout
-- {
--     ["receiving_player"] = 1,
--     ["class"] = Hint,
--     ["finding_player"] = 1,
--     ["location"] = 67361,
--     ["found"] = false,
--     ["item_flags"] = 2, --bitflag --> 0=filler, 1=progression, 2=useful, 4=trap
--     ["status"] = 40, --bitflag --> 0=Unspecified, 10=NoPriority, 20=Avoid, 30=Priority, 40=None
--     ["entrance"] = ,
--     ["item"] = 66062,
-- }


----------
---remnant from when poptracker had issues loading some larger/heavy packs
--function OnClearHandler(slot_data)
--    local clear_timer = os.clock()
--
--    ScriptHost:RemoveWatchForCode("StateChange")
--    -- Disable tracker updates.
--    Tracker.BulkUpdate = true
--    -- Use a protected call so that tracker updates always get enabled again, even if an error occurred.
--    local ok, err = pcall(OnClear, slot_data)
--    -- Enable tracker updates again.
--    if ok then
--        -- Defer re-enabling tracker updates until the next frame, which doesn't happen until all received items/cleared
--        -- locations from AP have been processed.
--        local handlerName = "AP OnClearHandler"
--        local function frameCallback()
--            ScriptHost:AddWatchForCode("StateChange", "*", StateChanged)
--            ScriptHost:RemoveOnFrameHandler(handlerName)
--            Tracker.BulkUpdate = false
--            ForceUpdate()
--            print(string.format("Time taken total: %.2f", os.clock() - clear_timer))
--        end
--        ScriptHost:AddOnFrameHandler(handlerName, frameCallback)
--    else
--        Tracker.BulkUpdate = false
--        print("Error: OnClear failed:")
--        print(err)
--    end
--end