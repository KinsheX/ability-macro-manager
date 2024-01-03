AMM_Utils = AMM_Utils or {}

AMM_RotatingAbilities = {
    ["Blessing of Summer"] = {
        ["Blessing of Spring"]=328282,
        ["Blessing of Autumn"]=328622,
        ["Blessing of Winter"]=328281
    }
}

AMM_AbilityMapping = {
    ["Blessing of Spring"] = "Blessing of Summer",
    ["Blessing of Autumn"] = "Blessing of Summer",
    ["Blessing of Winter"] = "Blessing of Summer"
}

AMM_AbilityIDMapping = {
    [328282] = 328620,
    [328622] = 328620,
    [328281] = 328620
}

AMM_SpellIconIDOverride = {
    [388007]=328620,
    [388010]=328620
}

AMM_SpellExistanceIDMapping = {
    [328620] = 388007
}

AMM_ResurrectionSpells = {
    [20484]=true, --Rebirth
    [20707]=true, --Soulstone
    [391054]=true, --Intercession
    [61999]=true --Raise Ally
}

local addonTechnicalName = "AbilityMacroManager"
local GetAddonMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata

function AMM_Utils.GetAddonVersion()
    return GetAddonMetadata(addonTechnicalName, "Version")
end

function AMM_Utils.GetAddonTitle()
    return GetAddonMetadata(addonTechnicalName, "Title")
end