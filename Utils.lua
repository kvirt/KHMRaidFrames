local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

local _G, IsInRaid, InCombatLockdown, ViragDevTool_AddData = _G, IsInRaid, InCombatLockdown, ViragDevTool_AddData

local subFrameTypes = {"debuffFrames", "buffFrames", "dispelDebuffFrames"}

local systemYellowCode = "|cFFffd100<text>|r"
local yellowCode = "|cFFFFF569<text>|r"
local witeCode = "|cFFFFFFFF<text>|r"
local redCode = "|cFFC80000<text>|r"
local greenCode = "|cFF009600<text>|r"
local purpleCode = "|cFF9600FF<text>|r"
local blueCode = "|cFF3296FF<text>|r"
local brownCode = "|cFF966400<text>|r"
local greyCode = "|cFFb8b6b0<text>|r"


function KHMRaidFrames:SafeRefresh(groupType)
    groupType = groupType or (IsInRaid() and "raid" or "party")

    if InCombatLockdown() then
        self:Print("Can not refresh settings while in combat")
        self:HideAll()
        self.deffered = true
        return
    else
        self:RefreshConfig(groupType)
    end
end

function KHMRaidFrames.ReverseGroupType(groupType)
    return groupType == "party" and "raid" or "party"
end

function KHMRaidFrames:IterateCompactFrames(isInRaid)
    local index = 0
    local groupIndex = 0
    local doneOld = (not self.displayPets and not self.displayMainTankAndAssist) and self.keepGroupsTogether
    local doneNew = not self.keepGroupsTogether
    local frame

    return function()
        while not doneNew do
            index = index + 1

            if index > 5 then
                index = 1
                groupIndex = groupIndex + 1

                if groupIndex == 9 then
                    index = 0
                    doneNew = true
                end
            end

            if isInRaid == "raid" then
                frame = _G["CompactRaidGroup"..groupIndex.."Member"..index]
            else
                if groupIndex == 2 then
                    index = 0
                    doneNew = true
                    break
                end

                frame = _G["CompactPartyFrameMember"..index]
            end

            if frame then return frame end
        end

        while not doneOld do
            index = index + 1

            local oldStyleframe =_G["CompactRaidFrame"..index]

            if index == 40 then
                doneOld = true
                index = 0
            end

            if oldStyleframe then return oldStyleframe end
        end
    end
end

function KHMRaidFrames.IterateCompactGroups(isInRaid)
    local groupIndex = 0
    local groupFrame

    return function()
        while groupIndex <= 8 do
            groupIndex = groupIndex + 1

            if isInRaid == "raid" then
                groupFrame = _G["CompactRaidGroup"..groupIndex]
            else
                groupFrame = _G["CompactPartyFrame"]
                groupIndex = 9
            end

            if groupFrame then return groupFrame end
        end
    end
end

function KHMRaidFrames.IterateSubFrameTypes(exclude)
    local index = 0
    local len = #subFrameTypes

    return function()
        index = index + 1
        if index <= len and subFrameTypes[index] ~= exclude then
            return subFrameTypes[index]
        end
    end
end

function KHMRaidFrames.SanitazeString(str)
    local key = str:match("[^--]+")

    if not key then return end

    key = key:lower()
    key = key:gsub("^%s*(.-)%s*$", "%1")
    key = key:gsub("\"", "")
    key = key:gsub(",", "")

    return key
end

function KHMRaidFrames:SanitizeStrings(str)
    local t = {}
    local index = 1

    for value in str:gmatch("[^\n]+") do
        local key = self.SanitazeString(value)

        if key then
            t[index] = key

            index = index + 1
        end
    end

    return t
end

function KHMRaidFrames.DebuffColorsText()
    local s = "\n"..
        greenCode:gsub("<text>", "Poison").."\n"..
        purpleCode:gsub("<text>", "Curse").."\n"..
        brownCode:gsub("<text>", "Disease").."\n"..
        blueCode:gsub("<text>", "Magic").."\n"..
        witeCode:gsub("<text>", "Physical").."\n"

    return s
end

function KHMRaidFrames:TrackingHelpText()

    local s = "\n".."\n".."\n"..
        L["Rejuvenation"].."\n"..
        "Curse".."\n"..
        "155777".."\n"..
        "Magic".."\n"..
        "\n"..
        L["Wildcards"]..":\n"..self.DebuffColorsText()..
        "155777"..greyCode:gsub("<text>", L["-- Comments"])

    return s
end

function KHMRaidFrames.ExcludeHelpText()

    local s = "\n".."\n".."\n"..
        L["Rejuvenation"].."\n"..
        "155777".."\n"

    return s
end

function KHMRaidFrames:GroupTypeDB()
    local groupType

    if IsInRaid() then
        groupType = "raid"
    else
        groupType = "party"
    end

    return self.db.profile[groupType]
end

function KHMRaidFrames.GetTextures()
    local textures = SharedMedia:HashTable("statusbar")

    local s = {}
    for k, _ in pairs(textures) do
        table.insert(s, k)
    end


    table.sort(s, function(a, b)
        return a:sub(1, 1):lower() < b:sub(1, 1):lower()
    end)

    return textures, s
end

function KHMRaidFrames.GetFons()
    local fonts = SharedMedia:HashTable("font")

    local s = {}
    for k, _ in pairs(fonts) do
        table.insert(s, k)
    end


    table.sort(s, function(a, b)
        return a:sub(1, 1):lower() < b:sub(1, 1):lower()
    end)

    return fonts, s
end

function KHMRaidFrames:TrackAuras(name, debuffType, spellId, db)
    for _, aura in ipairs(db) do
        if (aura == name or aura == debuffType or aura == spellId) then
            if not self:ExcludeAuras(name, debuffType, spellId) then return true end
        end
    end

    return nil
end

function KHMRaidFrames:ExcludeAuras(name, debuffType, spellId)
    for _, exclude in ipairs(self.db.profile.glows.glowBlockList.tracking) do
        if (exclude == name or exclude == debuffType or exclude == spellId) then
            return true
        end
    end
end

function KHMRaidFrames:CustomizeOptions()
    local virtualFramesButton = self.dialog.general.obj.children and self.dialog.general.obj.children[1]

    if virtualFramesButton then
        virtualFramesButton:ClearAllPoints()
        virtualFramesButton:SetPoint("TOPRIGHT", self.dialog.general.obj.label:GetParent(), "TOPRIGHT", -10, -15)
    end

    local groupTypelabel = self.dialog.general.obj.children
    and self.dialog.general.obj.children[2]
    and self.dialog.general.obj.children[2].children
    and self.dialog.general.obj.children[2].children[1]
    and self.dialog.general.obj.children[2].children[1].label

    if groupTypelabel then
        local label = L["You are in |cFFC80000<text>|r"]:gsub("<text>", IsInRaid() and L["Raid"] or L["Party"])
        groupTypelabel:SetText(label)
    end
end

function KHMRaidFrames:ConfigOptionsOpen()
    local tabsP = self.dialog.general.obj.children
    and self.dialog.general.obj.children[2]
    and self.dialog.general.obj.children[2]
    tabsP:SelectTab(IsInRaid() and "raid" or "party")
end

function KHMRaidFrames.Print(obj, name)
    if ViragDevTool_AddData then
        ViragDevTool_AddData(obj, name)
    else
        print(obj)
    end
end