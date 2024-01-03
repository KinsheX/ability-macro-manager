AMM_Utils = AMM_Utils or {}

local AMM_Title = WrapTextInColorCode("AbilityMacroManager", "ff1ac3d6")
local AMM_Title_Warn = WrapTextInColorCode(" [INFO]", "ffeb8109")
local AMM_Title_Spacer = ": "

local TankIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-Tank", 16, 16)
local HealerIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-Healer", 16, 16)
local DPSIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-DPS", 16, 16)


function AMM_Utils.print(text)
    print(AMM_Title .. AMM_Title_Spacer .. text)
end

function AMM_Utils.warn(text)
    print(AMM_Title .. AMM_Title_Warn .. AMM_Title_Spacer .. text)
end

function AMM_Utils.getTankHealerDPSPriority()
    return TankIcon .. HealerIcon .. DPSIcon
end

function AMM_Utils.getHealerTankDPSPriority()
    return HealerIcon .. TankIcon .. DPSIcon
end

function AMM_Utils.getDPSHealerTankPriority()
    return DPSIcon .. HealerIcon .. TankIcon
end