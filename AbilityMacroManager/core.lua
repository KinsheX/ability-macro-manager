local EventFrame = CreateFrame("Frame")
EventFrame:RegisterEvent("ADDON_LOADED")
EventFrame:RegisterEvent("SPELLS_CHANGED")
EventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

local addonTechnicalName = "AbilityMacroManager"

local GetAddonMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or _G.GetAddOnMetadata

local currentVersion = GetAddOnMetadata(addonTechnicalName, "Version")

AMM_Initialized = false

EventFrame:SetScript("OnEvent", function (self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonTechnicalName then
		AMM_Abilities = _G.AMM_Abilities or {}
        if _G.AMM_UIEnabled == nil then
            AMM_UIEnabled = true
        else
            AMM_UIEnabled = _G.AMM_UIEnabled
        end

        if not _G.AMM_Version or _G.AMM_Version ~= currentVersion then
            if not _G.AMM_Version then --Reset all abilities. Version field introduced in 1.2
                AMM_Utils.warn("Reset all abilities due to schema changes. Sorry for the inconvenience.")
                AMM_Abilities = {}
            end
        end
        AMM_Version = _G.AMM_Version or currentVersion

		self:UnregisterEvent("ADDON_LOADED")
	elseif event == "SPELLS_CHANGED" and not AMM_Initialized then
        AMM_Initialized = true
        AMM_Settings.initialize()

        C_Timer.NewTicker(5, function()
            for key, value in pairs(AMM_Abilities) do
                if AMM_Abilities[key] then
                    if IsSpellKnownOrOverridesKnown(value.spellExistanceID or key) then
                        AbilityFrame.updateIndicator(key)
                    else
                        AbilityFrameFactory.remove(key)
                    end
                end
            end
        end)
    elseif event == "GROUP_ROSTER_UPDATE" then
        if AMM_Abilities then
            for key, value in pairs(AMM_Abilities) do
                if AMM_Abilities[key] and AMM_Abilities[key].priorityMode then
                    AbilityFrame.setPriorityMode(key, AMM_Abilities[key].priorityMode)
                end
            end
        end
    end
end)
