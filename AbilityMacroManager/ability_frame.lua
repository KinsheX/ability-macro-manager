AbilityFrameFactory = {}
AbilityFrame = {}

local TankIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-Tank", 16, 16)
local HealerIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-Healer", 16, 16)
local DPSIcon = CreateAtlasMarkup("UI-LFG-RoleIcon-DPS", 16, 16)

local AbilityFrameCounter = 0
local abilityFrameTableBySpellId = {}
local abilityFrameTableByFrameIndex = {}

local AbilityFrameGroup = _G["AMM_AbilityAnchor"] or CreateFrame("Button", "AMM_AbilityAnchor", UIParent)
AbilityFrameGroup:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
AbilityFrameGroup:SetMovable(true)
AbilityFrameGroup:EnableMouse(true)
AbilityFrameGroup:RegisterForDrag("LeftButton")
AbilityFrameGroup:SetScript("OnMouseDown", AbilityFrameGroup.StartMoving)
AbilityFrameGroup:SetScript("OnMouseUp", AbilityFrameGroup.StopMovingOrSizing)
AbilityFrameGroup:SetUserPlaced(true); 
AbilityFrameGroup:SetWidth(42); 
AbilityFrameGroup:SetHeight(42);
AbilityFrameGroup:SetPoint("CENTER")

local SimpleTooltipFrame = _G["AMM_SimpleTooltip"] or CreateFrame("Frame", "AMM_SimpleTooltip", AbilityFrameGroup, BackdropTemplateMixin and "BackdropTemplate")
SimpleTooltipFrame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
SimpleTooltipFrame:SetBackdropColor(0, 0, 0, .6)
SimpleTooltipFrame:SetFrameStrata("TOOLTIP")
SimpleTooltipFrame:SetWidth(106); 
SimpleTooltipFrame:SetHeight(25);

SimpleTooltipFrame.text = SimpleTooltipFrame.text or SimpleTooltipFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
SimpleTooltipFrame.text:SetText("-")
SimpleTooltipFrame.text:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
SimpleTooltipFrame.text:SetPoint("CENTER", SimpleTooltipFrame, "CENTER", 0, 0)

SimpleTooltipFrame:Hide()



local function SpellInRange(spellName, unitId)
	local inRange = 0
	if UnitExists(unitId) and UnitIsVisible(unitId) then
		inRange = IsSpellInRange(spellName, unitId)
	end
	return inRange == 1
end

local function CheckRangeAndSetColors(spellID, unitId)
    local abilityFrame = _G["AMM_AbilityFrame" .. spellID]
	if unitId ~= "-" and unitId ~= nil and unitId ~= "" then
        local spellName = GetSpellInfo(AMM_AbilityIDMapping[spellID] or spellID)
		if SpellInRange(spellName, unitId) then
			abilityFrame:SetBackdropBorderColor(0, 1, 0)
			abilityFrame.text:SetTextColor(0, 1, 0)
		else
			abilityFrame:SetBackdropBorderColor(1, .347, 0)
			abilityFrame.text:SetTextColor(1, .447, 0)
		end
	else
		abilityFrame:SetBackdropBorderColor(1, .347, 0)
		abilityFrame.text:SetTextColor(1, .447, 0)
	end
end

function AbilityFrameFactory.remove(spellID)
    if not _G["AMM_AbilityFrame" .. spellID] then
        return
    end

    _G["AMM_AbilityFrame" .. spellID]:Hide()

    local startIdx = abilityFrameTableBySpellId[spellID] + 1

    for i=startIdx,AbilityFrameCounter do
        local abilitySpellId = abilityFrameTableByFrameIndex[i]
        local newIndex = i - 1
        _G["AMM_AbilityFrame" .. abilitySpellId]:SetPoint("CENTER", 0, -32 * newIndex)
        abilityFrameTableBySpellId[abilitySpellId] = newIndex
        abilityFrameTableByFrameIndex[newIndex] = abilitySpellId
    end
    AbilityFrameCounter = math.max(0, AbilityFrameCounter - 1)
end

function createPrioritizedList(firstPrioArr, secondPrioArr, thirdPrioArr)
    local prioritizedList = {}
    for _, value in ipairs(firstPrioArr) do
        table.insert(prioritizedList, value)
    end
    for _, value in ipairs(secondPrioArr) do
        table.insert(prioritizedList, value)
    end
    for _, value in ipairs(thirdPrioArr) do
        table.insert(prioritizedList, value)
    end

    return prioritizedList
end

function AbilityFrame.setPriorityMode(spellID, mode)
    local tankList = {}
    local healerList = {}
    local dpsList = {}
    local playerName = UnitName("player")
    local playerRole = UnitGroupRolesAssigned("player")
    if playerRole == "DAMAGER" then
        table.insert(dpsList, playerName)
    elseif playerRole == "TANK" then
        table.insert(tankList, playerName)
    elseif playerRole == "HEALER" then
        table.insert(healerList, playerName)
    end

    for groupIndex = 1, MAX_PARTY_MEMBERS do
        local partyUnit = format("%s%i", "party", groupIndex)
        local name = UnitName(partyUnit)
        if UnitExists(partyUnit) then
            local unitRole = UnitGroupRolesAssigned(partyUnit)
            if unitRole == "DAMAGER" then
                table.insert(dpsList, name)
            elseif unitRole == "TANK" then
                table.insert(tankList, name)
            elseif unitRole == "HEALER" then
                table.insert(healerList, name)
            end
        end
    end

    if mode == "Tank-Healer-DPS" then
        AMM_Abilities[spellID].partyOverrideTargets = createPrioritizedList(tankList, healerList, dpsList)
    elseif mode == "Healer-Tank-DPS" then
        AMM_Abilities[spellID].partyOverrideTargets = createPrioritizedList(healerList, tankList, dpsList)
    elseif mode == "DPS-Healer-Tank" then
        AMM_Abilities[spellID].partyOverrideTargets = createPrioritizedList(dpsList, healerList, tankList)
    elseif mode == "Clear" then
        AMM_Abilities[spellID].partyOverrideTargets = nil
    end

    AMM_Macro.createOrUpdate(spellID)
    AbilityFrame.updateIndicator(spellID)
end

function AbilityFrame.setTemporaryTarget(spellID, name)
    AMM_Abilities[spellID].temporarySelection = name
    AMM_Macro.createOrUpdate(spellID)
    AbilityFrame.updateIndicator(spellID)
end

function AbilityFrame.resetTemporarySelection(spellID)
    AMM_Abilities[spellID].temporarySelection = ""
    AMM_Abilities[spellID].partyOverrideTargets = {}
    AMM_Macro.createOrUpdate(spellID)
    AbilityFrame.updateIndicator(spellID)
end

function AbilityFrame.hideAll()
    for key, val in pairs(abilityFrameTableBySpellId) do
        if _G["AMM_AbilityFrame" .. key] and AMM_Abilities[key] then
            _G["AMM_AbilityFrame" .. key]:Hide()
        end
    end

    AbilityFrameGroup:Hide()
end

function AbilityFrame.resetGroupPosition()
    AbilityFrameGroup:ClearAllPoints()
    AbilityFrameGroup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
end

function AbilityFrame.showAll()
    for key, val in pairs(abilityFrameTableBySpellId) do
        if _G["AMM_AbilityFrame" .. key] and AMM_Abilities[key] then
            _G["AMM_AbilityFrame" .. key]:Show()
        end
    end

    AbilityFrameGroup:Show()
end

function AbilityFrame.toggle()
    if AMM_UIEnabled then
        AbilityFrame.hideAll()
        AMM_UIEnabled = false
    else
        AbilityFrame.showAll()
        AMM_UIEnabled = true
    end
end

function AbilityFrameFactory.create(spellID, spellIcon)
    if not AMM_UIEnabled then
        return
    end
    AbilityFrameCounter = AbilityFrameCounter + 1

    local IndicatorFrame = _G["AMM_AbilityFrame" .. spellID] or CreateFrame("Frame", "AMM_AbilityFrame" .. spellID, AbilityFrameGroup, BackdropTemplateMixin and "BackdropTemplate")
    IndicatorFrame:SetBackdrop({
        bgFile = [[Interface\Buttons\WHITE8x8]],
        edgeFile = [[Interface\Buttons\WHITE8x8]],
        edgeSize = 1,
    })
    IndicatorFrame:SetBackdropBorderColor(1, .347, 0)
    IndicatorFrame:SetBackdropColor(0, 0, 0, 0.33)
    IndicatorFrame:SetWidth(106); 
    IndicatorFrame:SetHeight(28);
    IndicatorFrame:SetPoint("CENTER", 0, -35 * AbilityFrameCounter)
    IndicatorFrame:EnableMouse(true)
    IndicatorFrame:SetScript("OnMouseDown", function (self, button)
        if button == "RightButton" then
            AMM_CharacterSelection.select(spellID, function (name)
                AbilityFrame.setTemporaryTarget(spellID, name)
            end, function (priorityMode)
                AMM_Abilities[spellID].priorityMode = priorityMode
                AbilityFrame.setPriorityMode(spellID, priorityMode)
            end)
        end
    end)
    IndicatorFrame:SetScript("OnMouseUp", function(self, ...)
        if self.timer < time() then
            self.startTimer = false
        end
        if self.timer == time() and self.startTimer then
            self.startTimer = false
    
            AbilityFrame.resetTemporarySelection(spellID)
        else
            self.startTimer = true
            self.timer = time()
        end
    end)
    IndicatorFrame.texture = IndicatorFrame.texture or IndicatorFrame:CreateTexture(nil, "BACKGROUND")
    IndicatorFrame.texture:SetAllPoints(true)
    IndicatorFrame.texture:SetTexture(0, 0, 0, 0)
    
    IndicatorFrame.text = IndicatorFrame.text or IndicatorFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    IndicatorFrame.text:SetText("-")
    IndicatorFrame.text:SetFont("Fonts\\ARIALN.ttf", 14, "OUTLINE")
    IndicatorFrame.text:SetTextColor(1, .447, 0)
    IndicatorFrame.text:SetPoint("CENTER", IndicatorFrame, "CENTER", 0, 0)
    
    IndicatorFrame.icon = IndicatorFrame.icon or IndicatorFrame:CreateTexture(nil, "OVERLAY")
    IndicatorFrame.icon:SetTexture(spellIcon)
    IndicatorFrame.icon:SetSize(22,22)
    IndicatorFrame.icon:SetPoint("TOP", -53, -3) -- horizontal, vertical

    IndicatorFrame.updatePriorityIcon = function ()
        local priorityMode = AMM_Abilities[spellID].priorityMode
        IndicatorFrame.priorityLabel = IndicatorFrame.priorityLabel or IndicatorFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        IndicatorFrame.priorityLabel:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
        IndicatorFrame.priorityLabel:SetTextColor(1, .447, 0)
        IndicatorFrame.priorityLabel:SetPoint("TOP", 35, 5)

        if priorityMode == "Tank-Healer-DPS" then
            IndicatorFrame.priorityLabel:SetText(AMM_Utils.getTankHealerDPSPriority())
        elseif priorityMode == "Healer-Tank-DPS" then
            IndicatorFrame.priorityLabel:SetText(AMM_Utils.getHealerTankDPSPriority())
        elseif priorityMode == "DPS-Healer-Tank" then
            IndicatorFrame.priorityLabel:SetText(AMM_Utils.getDPSHealerTankPriority())
        else
            IndicatorFrame.priorityLabel:SetText("")
        end
    end
    IndicatorFrame:updatePriorityIcon()

    IndicatorFrame:SetScript('OnEnter', function(self)
        local AMMTooltip = _G["AMM_SimpleTooltip"]
        AMMTooltip:ClearAllPoints()

        local spellName = GetSpellInfo(spellID)
        AMMTooltip.text:SetText(spellName)
        AMMTooltip:SetWidth(AMMTooltip.text:GetStringWidth()+20)

        AMMTooltip:SetPoint("LEFT",self,"CENTER",-AMMTooltip:GetWidth() - (IndicatorFrame:GetWidth() / 2) - 17, 0)
        AMMTooltip:Show()
    end)
    IndicatorFrame:SetScript('OnLeave', function()
        _G["AMM_SimpleTooltip"]:Hide()
    end)
    IndicatorFrame.timer = 0

    IndicatorFrame:Show()

    abilityFrameTableBySpellId[spellID] = AbilityFrameCounter
    abilityFrameTableByFrameIndex[AbilityFrameCounter] = spellID
end

function AbilityFrame.updateIndicator(spellID)
    local spellName, _, spellIcon = GetSpellInfo(spellID)
    local selectedTarget = AMM_Abilities[spellID].temporarySelection
    local permanentTargets = AMM_Abilities[spellID].permanentTargets
    local partyOverrideTargets = AMM_Abilities[spellID].partyOverrideTargets
    local abilityFrame = _G["AMM_AbilityFrame" .. spellID]

    spellName = AMM_AbilityMapping[spellName] or spellName

    if not abilityFrame then
        return
    end

    if not abilityFrame:IsShown() then
        AbilityFrameFactory.create(spellID, spellIcon)
    end

	local uiSet = false
    if partyOverrideTargets then
        for idx, value in ipairs(partyOverrideTargets) do
            if SpellInRange(spellName, value) then
                abilityFrame.text:SetText(value)
                uiSet=true
                break
            end
        end
    end
	if selectedTarget ~= "" and not uiSet then
		if SpellInRange(spellName, selectedTarget) then
			abilityFrame.text:SetText(selectedTarget)
			uiSet = true
		end
	end
	if permanentTargets then
		for key, value in pairs(permanentTargets) do
			if value ~= selectedTarget then
				if not uiSet and SpellInRange(spellName, value) then
					abilityFrame.text:SetText(value)
					uiSet = true
                    break
				end
			end
		end
	end

	if not uiSet then
		if UnitIsPlayer("focus") and SpellInRange(spellName, "focus") then
			name, realm = UnitName("focus")
			abilityFrame.text:SetText(name)
		else
			abilityFrame.text:SetText("-")
		end
	end

    abilityFrame:updatePriorityIcon()

    CheckRangeAndSetColors(spellID, abilityFrame.text:GetText())
end