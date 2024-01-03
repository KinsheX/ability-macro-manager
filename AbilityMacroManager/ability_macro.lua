AMM_Macro = {}

local spellPlaceholder = "{spellName}"
local targetPlaceholder = "{target}"

local macroTemplate = "/cast [@mouseover,nodead,help]{spellName}\n" ..
                      "%s\n" ..
                      "/cast [@focus,nodead,help]{spellName}\n" ..
                      "/cast {spellName}"
local macroTargetTemplate = "/cast [target={target},nodead,help]{spellName}\n"

local macroTemplateResurrection = "/cast [@mouseover,dead,help]{spellName}\n" ..
                                  "%s\n" ..
                                  "/cast [@focus,dead,help]{spellName}\n" ..
                                  "/cast {spellName}"
local macroTargetTemplateResurrection = "/cast [target={target},dead,help]{spellName}\n"

function AMM_Macro.GetMacroName(spellID)
	return "AMM_" .. spellID
end

local function GetCurrentMacroTarget(spellID)
	body = GetMacroBody(AMM_Macro.GetMacroName(spellID))
	match = body:match(".*target=(%a+)%.*][^\r\n].*")
	if match then
		return match
	end

	return nil
end

local function CreateMacroWithText(macroName, icon, text)
    if GetMacroIndexByName(macroName) == 0 then
        CreateMacro(macroName, icon, text)
    else
        EditMacro(macroName, nil, nil, text)
    end
end

local function formatMacroText(macroText, spellName, target)
    local formattedMacroText = string.gsub(macroText, spellPlaceholder, spellName)
    if target then
        formattedMacroText = string.gsub(formattedMacroText, targetPlaceholder, target)
    end
    return formattedMacroText
end

local function CreateTargetStringsForSpellID(spellID, spellName, template)
    local temporarySelection = AMM_Abilities[spellID].temporarySelection
    local permanentTargets = AMM_Abilities[spellID].permanentTargets
    local partyOverrideTargets = AMM_Abilities[spellID].partyOverrideTargets

	local targetStrings = ""
    if partyOverrideTargets then
        for idx, value in ipairs(partyOverrideTargets) do
            if value ~= nil and value ~= "" then
                targetStrings = targetStrings .. formatMacroText(template, spellName, value)
            end
        end
    end
	if temporarySelection ~= "" then
		targetStrings = targetStrings .. formatMacroText(template, spellName, temporarySelection)
	end
	if permanentTargets then
		for key, value in pairs(permanentTargets) do
			if value ~= temporarySelection and not (value == nil or value == '') then
				targetStrings = targetStrings .. formatMacroText(template, spellName, value)
			end
		end
	end

    return targetStrings
end

local function CreateLinkText(btnTarget)
    return "/click "..btnTarget.." LeftButton t"
end

function AMM_Macro.UpdateIcon(self)
    local name = self:GetName()
    local spellId = self.spellID

    local spellName, _, _, _, _, _, _ = GetSpellInfo(spellId)
    SetMacroSpell(name, spellName)
end

local function splitByChunk(text, chunkSize)
    local s = {}
    for i=1, #text, chunkSize do
        s[#s+1] = text:sub(i,i+chunkSize - 1)
    end
    return s
end

local function createMacroButton(btnName, spellID)
    local macroFrame = _G[btnName] or CreateFrame("Button", btnName, nil, "SecureActionButtonTemplate,SecureHandlerBaseTemplate");
    macroFrame:SetAttribute("type", "macro")
    macroFrame:RegisterForClicks("AnyUp", "AnyDown")
    macroFrame.UpdateIcon = AMM_Macro.UpdateIcon
    macroFrame.spellID = spellID
    macroFrame:WrapScript(macroFrame, "OnClick", [=[
        self:CallMethod('UpdateIcon')
      ]=])

    return macroFrame
end

function AMM_Macro.Create(macroName, macroText, spellID)
    local idx = 1
    local macroFrame = createMacroButton(macroName, spellID)
    local macroTextBuilder = ""
    for line in macroText:gmatch("([^\n]*)\n?") do
        if string.len(macroTextBuilder) + string.len(line) > 1023 - 70 then
            idx = idx + 1
            macroFrame:SetAttribute("macrotext", macroTextBuilder .. "\n" .. CreateLinkText(macroName .. "_" .. idx))
            macroTextBuilder = ""
            macroFrame = createMacroButton(macroName .. "_" .. idx, spellID)
        else
            macroTextBuilder = macroTextBuilder .. "\n" .. line
        end
    end

    if macroTextBuilder ~= "" then
        macroFrame:SetAttribute("macrotext", macroTextBuilder)
    end
    
    CreateMacroWithText(macroName, "INV_MISC_QUESTIONMARK", "#showtooltip\n" .. CreateLinkText(macroName))
    AMM_Macro.UpdateIcon(_G[macroName])
end

function AMM_Macro.createOrUpdate(spellID)
    if UnitAffectingCombat("player") then
        return
    end
    local mappedSpellID = AMM_AbilityIDMapping[spellID] or spellID
    local macroName = AMM_Macro.GetMacroName(mappedSpellID)
    local spellName = GetSpellInfo(mappedSpellID)


    local template = macroTemplate
    local targetTemplate = macroTargetTemplate
    if AMM_ResurrectionSpells[mappedSpellID] then
        template = macroTemplateResurrection
        targetTemplate = macroTargetTemplateResurrection
    end

    if AMM_RotatingAbilities[spellName] then
        local macroText = ""
        for key, val in pairs(AMM_RotatingAbilities[spellName]) do
            macroText = macroText .. format(formatMacroText(template, key), CreateTargetStringsForSpellID(val, key, targetTemplate)) .. "\n"
        end

        macroText = macroText .. format(formatMacroText(template, spellName), CreateTargetStringsForSpellID(mappedSpellID, spellName, targetTemplate)) .. "\n"

        AMM_Macro.Create(macroName, macroText, mappedSpellID)
    else
        local targetStrings = CreateTargetStringsForSpellID(spellID, spellName, targetTemplate)
        local macroText = "#showtooltip\n" .. format(formatMacroText(template, spellName), targetStrings)
        local icon = GetSpellTexture(spellID)

        AMM_Macro.Create(macroName, macroText, mappedSpellID)
    end
end

function AMM_Macro.remove(spellID)
    DeleteMacro(AMM_Macro.GetMacroName(spellID))
end