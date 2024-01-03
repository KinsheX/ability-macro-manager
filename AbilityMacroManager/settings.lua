AMM_Settings = {}

local abilityFrameTableBySpellId = {}
local abilityFrameTableByFrameIndex = {}

local maximumPermanentTargetsPerAbility = 3
local abilitySettingsLoaded = 0
local settingsPanel = CreateFrame("Frame", "AbilityMacroManagerSettingsPanel")
settingsPanel.name = "Ability Macro Manager"
InterfaceOptions_AddCategory(settingsPanel)

local commandTable = {
	["reset"] = AbilityFrame.resetGroupPosition,
    ["toggle"] = AbilityFrame.toggle
}

local function Usage()
	print("/amm <action>")
	print()
	print("Actions:")
	print(" reset | Resets UI anchor position")
	print(" toggle | Toggles UI on/off")
end

SLASH_ABILITY_MACRO_MANAGER1 = "/amm"
SlashCmdList["ABILITY_MACRO_MANAGER"] = function (msg)
	local cmd, arguments = msg:match("(%a*)%s*([%a%s]*)")
	if cmd ~= nil and cmd ~= "" then
		if commandTable[cmd] then
			commandTable[cmd](arguments)
		else
			AMM_Utils.warn("Unknown action: " .. cmd .. ". Type /amm to get a list of available commands.")
		end
	else
        Usage()
		InterfaceOptionsFrame_OpenToCategory(settingsPanel)
	end
end

local scrollFrame = CreateFrame("ScrollFrame", nil, settingsPanel, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 3, -4)
scrollFrame:SetPoint("BOTTOMRIGHT", -27, 4)

-- Create the scrolling child frame, set its width to fit, and give it an arbitrary minimum height (such as 1)
local scrollChild = CreateFrame("Frame")
scrollFrame:SetScrollChild(scrollChild)
scrollChild:SetWidth(SettingsPanel.Container:GetWidth()-18)
scrollChild:SetHeight(1)

-- Add widgets to the scrolling child frame as desired
local title = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormalLarge")
title:SetPoint("TOP")
title:SetText(AMM_Utils.GetAddonTitle())

local version = scrollChild:CreateFontString("ARTWORK", nil, "GameFontNormal")
version:SetPoint("TOP", 0, -15)
version:SetTextColor(1, 1, 1)
version:SetText("Version " .. AMM_Utils.GetAddonVersion())

local addAbilityBtn = CreateFrame("Button", "AddAbilityButton", scrollChild, "UIPanelButtonTemplate")
addAbilityBtn:SetSize(120, 32) -- width, height
addAbilityBtn:SetText("Add Ability")
addAbilityBtn:SetPoint("TOPLEFT", 0, -30)
addAbilityBtn:SetScript("OnClick", function()
    local numglobalmacros = GetNumMacros()
    if numglobalmacros == 120 then
        StaticPopup_Show("AMM_GENERIC_ERROR", "No more macro slots available in the global space.")
        return
    end
    StaticPopup_Show("AMM_ADD_ABILITY")
end)

local toggleUIDisplay = CreateFrame("CheckButton", "ToggleUIDisplayBtn", scrollChild, "ChatConfigCheckButtonTemplate")
toggleUIDisplay:SetSize(32, 32)
toggleUIDisplay:SetPoint("TOPRIGHT", -90, -30)
toggleUIDisplay:SetText("Enable UI")
toggleUIDisplay:SetScript("OnClick", function()
    if toggleUIDisplay:GetChecked() then
        AbilityFrame.showAll()
        AMM_UIEnabled = true
    else
        AbilityFrame.hideAll()
        AMM_UIEnabled = false
    end
end)
ToggleUIDisplayBtnText:SetText("Enable UI")

local addAbilityBtn = CreateFrame("Button", "ResetUIButton", scrollChild, "UIPanelButtonTemplate")
addAbilityBtn:SetSize(120, 32) -- width, height
addAbilityBtn:SetText("Reset UI Position")
addAbilityBtn:SetPoint("TOPRIGHT", -130, -30)
addAbilityBtn:SetScript("OnClick", function()
    AbilityFrame.resetGroupPosition()
end)

local function GetAbilityVerticalPosition(index)
    local nonFirstExtraSpacing = 0
    if index > 1 then
        nonFirstExtraSpacing = 120 * (index - 1)
    end
    return (-70 * index) - nonFirstExtraSpacing
end

local function addTargetInputBox(frameParent, spellID, index)
    local targetEditBoxName = "AMM_Target" .. spellID .. "Target" .. index

    frameParent[targetEditBoxName] = _G[targetEditBoxName] or CreateFrame("EditBox", targetEditBoxName, frameParent, "InputBoxTemplate")
    frameParent[targetEditBoxName]:SetWidth("200")
    frameParent[targetEditBoxName]:SetHeight("32")
    frameParent[targetEditBoxName]:SetFrameStrata("DIALOG")
    frameParent[targetEditBoxName]:SetAutoFocus(false);
    frameParent[targetEditBoxName]:SetScript("OnTextChanged", function(self, userInput)
        AMM_Abilities[spellID].permanentTargets[index] = self:GetText()
        AMM_Macro.createOrUpdate(spellID)
    end)
    local position = -40 - ((index - 1) * 25)
    frameParent[targetEditBoxName]:SetPoint("TOPLEFT", 150, position)

    if AMM_Abilities[spellID].permanentTargets[index] then
        frameParent[targetEditBoxName]:SetText(AMM_Abilities[spellID].permanentTargets[index])
    end

    frameParent[targetEditBoxName].label = _G[targetEditBoxName .. "_label"] or frameParent[targetEditBoxName]:CreateFontString("ARTWORK", nil, "GameFontNormal")
    frameParent[targetEditBoxName].label:SetPoint("CENTER", frameParent[targetEditBoxName], "CENTER", -(frameParent[targetEditBoxName]:GetWidth() / 2) - 12, 0)
    frameParent[targetEditBoxName].label:SetText(index .. ".")

    frameParent[targetEditBoxName]:SetCursorPosition(0)
end

local function addAbilityInternal(spellNameOrId, isInitialization, spellIDToCheck)
    local spellName, _, spellIcon, _, _, _, spellID = GetSpellInfo(spellNameOrId)
    if AMM_SpellIconIDOverride[spellNameOrId] then
        local _, _, spellIconOverride = GetSpellInfo(AMM_SpellIconIDOverride[spellNameOrId])
        spellIcon = spellIconOverride or spellIcon
    end
    if not isInitialization then
        if not spellName then
            StaticPopup_Show("AMM_GENERIC_ERROR", spellNameOrId .. " is not a spell.")
            return
        end
        if AMM_Abilities[spellID] then
            StaticPopup_Show("AMM_GENERIC_ERROR", spellNameOrId .. " already exists: " .. spellName)
            return
        end
    end

    abilitySettingsLoaded = abilitySettingsLoaded + 1
    local spellFrameIndex = abilitySettingsLoaded

    AMM_Abilities[spellID] = AMM_Abilities[spellID] or {}
    AMM_Abilities[spellID].permanentTargets = AMM_Abilities[spellID].permanentTargets or {}
    AMM_Abilities[spellID].temporarySelection = AMM_Abilities[spellID].temporarySelection or ""
    AMM_Abilities[spellID].partyOverrideTargets = AMM_Abilities[spellID].partyOverrideTargets or {}

    if not AMM_Abilities[spellID].spellName then
        AMM_Abilities[spellID].spellName = spellName
    end

    AMM_Abilities[spellID].parentSpellID = spellIDToCheck
    AMM_Abilities[spellID].spellExistanceID = AMM_SpellExistanceIDMapping[spellIDToCheck] or spellID

    local AbilitySettingsFrame = _G["AMM_AbilitySettingFrame" .. spellID] or CreateFrame("Frame", "AMM_AbilitySettingFrame" .. spellID, scrollChild, BackdropTemplateMixin and "BackdropTemplate")
    AbilitySettingsFrame:Show()
    AbilitySettingsFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    local verticalSpacing = GetAbilityVerticalPosition(spellFrameIndex)
    if spellID == spellIDToCheck then
        AbilitySettingsFrame:SetWidth(scrollChild:GetWidth()-25);
        AbilitySettingsFrame:SetPoint("TOPLEFT", 0, verticalSpacing)
    else
        AbilitySettingsFrame:SetWidth(scrollChild:GetWidth()-50);
        AbilitySettingsFrame:SetPoint("TOPLEFT", 25, verticalSpacing)
    end
    AbilitySettingsFrame:SetHeight(190);
    
    
    AbilitySettingsFrame:SetBackdropColor(0, 0, 0, .33)

    AbilitySettingsFrame.title = AbilitySettingsFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
    AbilitySettingsFrame.title:SetPoint("TOPLEFT", 35, -13)
    AbilitySettingsFrame.title:SetText(spellName)

    AbilitySettingsFrame.icon = AbilitySettingsFrame:CreateTexture(nil, "OVERLAY")
    AbilitySettingsFrame.icon:SetTexture(spellIcon)
    AbilitySettingsFrame.icon:SetSize(20,20)
    AbilitySettingsFrame.icon:SetPoint("TOPLEFT", 10, -10) -- horizontal, vertical

    AbilitySettingsFrame.permanentTargetsTitle = AbilitySettingsFrame:CreateFontString("ARTWORK", nil, "GameFontWhite")
    AbilitySettingsFrame.permanentTargetsTitle:SetPoint("TOPLEFT", 150, -30)
    AbilitySettingsFrame.permanentTargetsTitle:SetText("Permanent Targets")

    addTargetInputBox(AbilitySettingsFrame, spellID, 1)
    addTargetInputBox(AbilitySettingsFrame, spellID, 2)
    addTargetInputBox(AbilitySettingsFrame, spellID, 3)
    addTargetInputBox(AbilitySettingsFrame, spellID, 4)
    addTargetInputBox(AbilitySettingsFrame, spellID, 5)


    abilityFrameTableBySpellId[spellID] = spellFrameIndex
    abilityFrameTableByFrameIndex[spellFrameIndex] = spellID

    if IsSpellKnownOrOverridesKnown(AMM_Abilities[spellID].spellExistanceID) then
        AbilityFrameFactory.create(spellID, spellIcon)
    end

    if spellID == spellIDToCheck then
        AbilitySettingsFrame.deleteBtn = _G["AMM_DeleteAbilityBtn" .. spellID] or CreateFrame("Button", "AMM_DeleteAbilityBtn" .. spellID, AbilitySettingsFrame, "UIPanelButtonTemplate")
        AbilitySettingsFrame.deleteBtn:SetSize(70, 25) -- width, height
        AbilitySettingsFrame.deleteBtn:SetText("Delete")
        AbilitySettingsFrame.deleteBtn:SetPoint("TOPRIGHT", -5, -5)
        AbilitySettingsFrame.deleteBtn:SetScript("OnClick", function()
            local dialog = StaticPopup_Show("AMM_DELETE_ABILITY", spellName)
            if dialog then
                dialog.data = spellName
                dialog.data2 = spellID
            end
        end)
    

        AbilitySettingsFrame.macroBtn = CreateFrame("Button", "AMM_AbilityBtnMacro" .. spellID, AbilitySettingsFrame, "SecureActionButtonTemplate");
        AbilitySettingsFrame.macroBtn:SetAttribute("type", "macro")
        AbilitySettingsFrame.macroBtn:SetAttribute("macro", AMM_Macro.GetMacroName(spellID))
        AbilitySettingsFrame.macroBtn:SetPoint("TOPLEFT", 45, -50)
        AbilitySettingsFrame.macroBtn:SetSize(48,48)
        AbilitySettingsFrame.macroBtn:SetNormalTexture(spellIcon)
        AbilitySettingsFrame.macroBtn:EnableMouse(true)
        AbilitySettingsFrame.macroBtn:RegisterForDrag("LeftButton")
        AbilitySettingsFrame.macroBtn:SetMovable(true)
        AbilitySettingsFrame.macroBtn:SetScript("OnMouseDown", function(self)
            PickupMacro(AMM_Macro.GetMacroName(spellIDToCheck))
        end)

        AbilitySettingsFrame.macroBtnLabel = AbilitySettingsFrame:CreateFontString("ARTWORK", nil, "GameFontNormal")
        AbilitySettingsFrame.macroBtnLabel:SetPoint("TOPLEFT", 30, -100)
        AbilitySettingsFrame.macroBtnLabel:SetText("(Click to drag)")
    end
end

local function addAbility(spellNameOrId, isInitialization)
    spellNameOrId = AMM_AbilityMapping[spellNameOrId] or spellNameOrId
    spellNameOrId = AMM_AbilityIDMapping[spellNameOrId] or spellNameOrId

    local spellName, _, spellIcon, _, _, _, spellID = GetSpellInfo(spellNameOrId)
    spellName = AMM_AbilityMapping[spellName] or spellName
    spellID = AMM_AbilityIDMapping[spellID] or spellID
    if AMM_RotatingAbilities[spellName] then
        addAbilityInternal(AMM_SpellIconIDOverride[spellID] or spellID, isInitialization, AMM_SpellIconIDOverride[spellID] or spellID)
        for key, value in pairs(AMM_RotatingAbilities[spellName]) do
            addAbilityInternal(value, isInitialization, AMM_SpellIconIDOverride[spellID] or spellID)
        end

        AMM_Macro.createOrUpdate(AMM_SpellIconIDOverride[spellID] or spellID)
    else
        addAbilityInternal(spellID, isInitialization, spellID)
        AMM_Macro.createOrUpdate(spellID)
    end
end

local function removeAbilityInternal(spellName, spellID)
    _G["AMM_AbilitySettingFrame" .. spellID]:Hide()
    AMM_Abilities[spellID] = nil
    AMM_Macro.remove(spellID)
    AbilityFrameFactory.remove(spellID)

    local startIdx = abilityFrameTableBySpellId[spellID] + 1

    for i=startIdx,abilitySettingsLoaded do
        local abilitySpellId = abilityFrameTableByFrameIndex[i]
        local newIndex = i - 1
        _G["AMM_AbilitySettingFrame" .. abilitySpellId]:SetPoint("TOPLEFT", 0, GetAbilityVerticalPosition(newIndex))
        abilityFrameTableBySpellId[abilitySpellId] = newIndex
        abilityFrameTableByFrameIndex[newIndex] = abilitySpellId
    end
    abilitySettingsLoaded = abilitySettingsLoaded - 1
end

local function removeAbility(spellName, spellID)
    if AMM_RotatingAbilities[spellName] then
        for key, value in pairs(AMM_RotatingAbilities[spellName]) do
            removeAbilityInternal(key, value)
        end

        removeAbilityInternal(spellName, spellID)
    else
        removeAbilityInternal(spellName, spellID)
    end
end

function AMM_Settings.initialize()
    toggleUIDisplay:SetChecked(AMM_UIEnabled)
    for key, value in pairs(AMM_Abilities) do
        if not value.parentSpellID or value.parentSpellID == key then
            addAbility(key, true)
        end
    end
end

StaticPopupDialogs["AMM_ADD_ABILITY"] = {
    text = "Enter the name of the ability, or its spell ID",
    button1 = "Add",
    button2 = "Cancel",
    OnAccept = function(self)
        addAbility(self.editBox:GetText())
    end,
    timeout = 0,
    whileDead = true,
    hasEditBox = true,
    hasWideEditBox = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
}

StaticPopupDialogs["AMM_DELETE_ABILITY"] = {
    text = "Are you sure you wish to delete %s?",
    button1 = "Yes, remove it",
    button2 = "Cancel",
    OnAccept = function(self, data, data2)
        removeAbility(data, data2)
    end,
    timeout = 0,
    whileDead = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
  }

  StaticPopupDialogs["AMM_GENERIC_ERROR"] = {
    text = "%s",
    button1 = "OK",
    button2 = "Cancel",
    timeout = 0,
    whileDead = true,
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
  }