Archipelago:AddClearHandler("clear handler", OnClear)
Archipelago:AddItemHandler("item handler", OnItem)
Archipelago:AddLocationHandler("location handler", OnLocation)

Archipelago:AddSetReplyHandler("notify handler", OnNotify)
Archipelago:AddRetrievedHandler("notify launch handler", OnNotifyLaunch)

Archipelago:AddBouncedHandler("bounce handler", OnBounce)

ScriptHost:AddWatchForCode("setting progressive_warps", "progressive_warps", OnProgressiveWarps)
ScriptHost:AddWatchForCode("setting level_unlock_method", "level_unlock_method", OnLevelUnlockMethod)
ScriptHost:AddWatchForCode(
    "setting progressive_weapon_ammo_upgrades",
    "progressive_weapon_ammo_upgrades",
    OnProgressiveWeaponAmmoUpgrades)