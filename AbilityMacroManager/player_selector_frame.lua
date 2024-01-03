AMM_CharacterSelection = {}

local offsetX = 0
local offsetY = 0

local AMM_SelectionFrame = _G["AMM_SelectionFrame"] or CreateFrame("Frame", "AMM_SelectionFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate")
AMM_SelectionFrame:Hide()
AMM_SelectionFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
AMM_SelectionFrame:SetFrameStrata("TOOLTIP")
AMM_SelectionFrame:SetWidth(400); 
AMM_SelectionFrame:SetHeight(150);
AMM_SelectionFrame:SetPoint("TOPLEFT", 0, 0)
AMM_SelectionFrame:SetBackdropColor(0, 0, 0, .6)

AMM_SelectionFrame.scrollFrame = AMM_SelectionFrame.scrollFrame or CreateFrame("ScrollFrame", nil, AMM_SelectionFrame, "UIPanelScrollFrameTemplate")
AMM_SelectionFrame.scrollFrame:SetPoint("TOPLEFT", 3, -4)
AMM_SelectionFrame.scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
local scrollChild = CreateFrame("Frame")
AMM_SelectionFrame.scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(AMM_SelectionFrame:GetWidth()-18)
scrollChild:SetHeight(1)

AMM_SelectionFrame.priorityLabel = AMM_SelectionFrame.priorityLabel or AMM_SelectionFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
AMM_SelectionFrame.priorityLabel:SetText("Set By Priority:")
AMM_SelectionFrame.priorityLabel:SetPoint("TOPLEFT", 8, -9)

AMM_SelectionFrame.tankPriorityBtn = AMM_SelectionFrame.tankPriorityBtn or CreateFrame("Button", nil, AMM_SelectionFrame, "UIPanelButtonTemplate")
AMM_SelectionFrame.tankPriorityBtn:SetText(AMM_Utils.getTankHealerDPSPriority())
AMM_SelectionFrame.tankPriorityBtn:SetPoint("TOPLEFT", 100, -4)
AMM_SelectionFrame.tankPriorityBtn:SetWidth(60)
AMM_SelectionFrame.tankPriorityBtn:SetHeight(25)

AMM_SelectionFrame.healerPriorityBtn = AMM_SelectionFrame.healerPriorityBtn or CreateFrame("Button", nil, AMM_SelectionFrame, "UIPanelButtonTemplate")
AMM_SelectionFrame.healerPriorityBtn:SetText(AMM_Utils.getHealerTankDPSPriority())
AMM_SelectionFrame.healerPriorityBtn:SetPoint("TOPLEFT", 170, -4)
AMM_SelectionFrame.healerPriorityBtn:SetWidth(60)
AMM_SelectionFrame.healerPriorityBtn:SetHeight(25)

AMM_SelectionFrame.dpsPriorityBtn = AMM_SelectionFrame.dpsPriorityBtn or CreateFrame("Button", nil, AMM_SelectionFrame, "UIPanelButtonTemplate")
AMM_SelectionFrame.dpsPriorityBtn:SetText(AMM_Utils.getDPSHealerTankPriority())
AMM_SelectionFrame.dpsPriorityBtn:SetPoint("TOPLEFT", 240, -4)
AMM_SelectionFrame.dpsPriorityBtn:SetWidth(60)
AMM_SelectionFrame.dpsPriorityBtn:SetHeight(25)

AMM_SelectionFrame.clearPriorityBtn = AMM_SelectionFrame.clearPriorityBtn or CreateFrame("Button", nil, AMM_SelectionFrame, "UIPanelButtonTemplate")
AMM_SelectionFrame.clearPriorityBtn:SetText("Clear")
AMM_SelectionFrame.clearPriorityBtn:SetPoint("TOPLEFT", 310, -4)
AMM_SelectionFrame.clearPriorityBtn:SetWidth(60)
AMM_SelectionFrame.clearPriorityBtn:SetHeight(25)

local function setPartyPriority(mode)
    if AMM_SelectionFrame.priorityCallback then
        if UnitAffectingCombat("player") then
            AMM_Utils.warn("Failed to set macro. You are in combat.")
            AMM_SelectionFrame.priorityCallback = nil
            AMM_SelectionFrame:Hide()
            return
        end
        AMM_SelectionFrame.priorityCallback(mode)
        AMM_SelectionFrame.priorityCallback = nil
        AMM_SelectionFrame:Hide()
    end
end

AMM_SelectionFrame.tankPriorityBtn:SetScript("OnClick", function()
    setPartyPriority("Tank-Healer-DPS")
end)
AMM_SelectionFrame.healerPriorityBtn:SetScript("OnClick", function()
    setPartyPriority("Healer-Tank-DPS")
end)
AMM_SelectionFrame.dpsPriorityBtn:SetScript("OnClick", function()
    setPartyPriority("DPS-Healer-Tank")
end)
AMM_SelectionFrame.clearPriorityBtn:SetScript("OnClick", function()
    setPartyPriority("Clear")
end)

tinsert(UISpecialFrames, AMM_SelectionFrame:GetName())

local function loadUnit(unitId)
    local name = UnitName(unitId)
    local class, classFileName = UnitClass(unitId)
    local classColor = RAID_CLASS_COLORS[classFileName]

    local IndicatorFrame = _G["AMM_SelectUnit_" .. unitId] or CreateFrame("Frame", "AMM_SelectUnit_" .. unitId, scrollChild, BackdropTemplateMixin and "BackdropTemplate")
    IndicatorFrame:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    IndicatorFrame:SetBackdropBorderColor(0, 0, 0, 0)
    IndicatorFrame:SetBackdropColor(0, 0, 0, 0)
    IndicatorFrame:SetScript('OnEnter', function()
        IndicatorFrame:SetBackdropBorderColor(classColor.r, classColor.g, classColor.b, 0.5)
        IndicatorFrame:SetBackdropColor(classColor.r, classColor.g, classColor.b, 0.33)
    end)
    IndicatorFrame:SetScript('OnLeave', function()
        IndicatorFrame:SetBackdropBorderColor(0, 0, 0, 0)
        IndicatorFrame:SetBackdropColor(0, 0, 0, 0, 0)
    end)
    IndicatorFrame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            if AMM_SelectionFrame.selectionCallback then
                if UnitAffectingCombat("player") then
                    AMM_Utils.warn("Failed to set macro. You are in combat.")
                    AMM_SelectionFrame.selectionCallback = nil
                    AMM_SelectionFrame:Hide()
                    return
                end
                AMM_SelectionFrame.selectionCallback(name)
                AMM_SelectionFrame.selectionCallback = nil
                AMM_SelectionFrame:Hide()
            end
        end
    end)
    IndicatorFrame:SetWidth(100); 
    IndicatorFrame:SetHeight(25);
    IndicatorFrame:ClearAllPoints()
    IndicatorFrame:SetPoint("TOPLEFT", 10 + offsetX, -10 - offsetY)
    IndicatorFrame:EnableMouse(true)
    IndicatorFrame.texture = IndicatorFrame.texture or IndicatorFrame:CreateTexture(nil, "BACKGROUND")
    IndicatorFrame.texture:SetAllPoints(true)
    IndicatorFrame.texture:SetTexture(0, 0, 0, 0)
    
    IndicatorFrame.roleText = IndicatorFrame.roleText or IndicatorFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    IndicatorFrame.roleText:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
    IndicatorFrame.roleText:SetPoint("CENTER", IndicatorFrame, "LEFT", 10, 0)

    if UnitGroupRolesAssigned(unitId) == "DAMAGER" then
        IndicatorFrame.roleText:SetText(DPSIcon)
    elseif UnitGroupRolesAssigned(unitId) == "TANK" then
        IndicatorFrame.roleText:SetText(TankIcon)
    elseif UnitGroupRolesAssigned(unitId) == "HEALER" then
        IndicatorFrame.roleText:SetText(HealerIcon)
    end

    IndicatorFrame.text = IndicatorFrame.text or IndicatorFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    IndicatorFrame.text:SetText(name)
    IndicatorFrame.text:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
    IndicatorFrame.text:SetTextColor(classColor.r, classColor.g, classColor.b)
    IndicatorFrame.text:SetPoint("CENTER", IndicatorFrame, "CENTER", 0, 0)

    IndicatorFrame:Show()

    if offsetX + 110 > 300 then
        offsetX = 0
        offsetY = offsetY + 35
    else
        offsetX = offsetX + 110
    end
end

function AMM_CharacterSelection.select(contextFrame, callback, priorityCallback)
    if UnitAffectingCombat("player") then
        return
    end

    if UnitInParty("player") or UnitInRaid("player") then
        contextFrame = _G["AMM_AbilityFrame" .. contextFrame]
        local x, y = GetCursorPosition()
        local scale = AMM_SelectionFrame:GetEffectiveScale()
        AMM_SelectionFrame:ClearAllPoints()
        AMM_SelectionFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", (x/scale), (y/scale))

        AMM_SelectionFrame.scrollFrame:SetPoint("TOPLEFT", 3, -4)

        AMM_SelectionFrame.priorityLabel:Hide()
        AMM_SelectionFrame.tankPriorityBtn:Hide()
        AMM_SelectionFrame.healerPriorityBtn:Hide()
        AMM_SelectionFrame.dpsPriorityBtn:Hide()
        AMM_SelectionFrame.clearPriorityBtn:Hide()

        AMM_SelectionFrame.selectionCallback = callback
        AMM_SelectionFrame.priorityCallback = priorityCallback

        offsetX = 0
        offsetY = 0
        loadUnit("player")

        for groupIndex = 1, MAX_RAID_MEMBERS do
            local raidUnit = format("%s%i", "raid", groupIndex)
            if _G["AMM_SelectUnit_" .. raidUnit] then 
                _G["AMM_SelectUnit_" .. raidUnit]:Hide()
            end
        end

        for groupIndex = 1, MAX_PARTY_MEMBERS do
            local partyUnit = format("%s%i", "party", groupIndex)
            if _G["AMM_SelectUnit_" .. partyUnit] then
                _G["AMM_SelectUnit_" .. partyUnit]:Hide()
            end
        end

        if UnitInRaid("player") then
            for groupIndex = 1, MAX_RAID_MEMBERS do
                local raidUnit = format("%s%i", "raid", groupIndex)
                if UnitExists(raidUnit) then
                    loadUnit(raidUnit)
                end
            end
        elseif UnitInParty("player") then
            AMM_SelectionFrame.scrollFrame:SetPoint("TOPLEFT", 3, -25)
            AMM_SelectionFrame.priorityLabel:Show()
            AMM_SelectionFrame.tankPriorityBtn:Show()
            AMM_SelectionFrame.healerPriorityBtn:Show()
            AMM_SelectionFrame.dpsPriorityBtn:Show()
            AMM_SelectionFrame.clearPriorityBtn:Show()

            for groupIndex = 1, MAX_PARTY_MEMBERS do
                local partyUnit = format("%s%i", "party", groupIndex)
                if UnitExists(partyUnit) then
                    loadUnit(partyUnit)
                end
            end
        end

        AMM_SelectionFrame:Show()
    end
end