local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

local _G, IsInRaid, InCombatLockdown = _G, IsInRaid, InCombatLockdown

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

function KHMRaidFrames.IterateCompactFrames(groupType)
    local index = 0
    local groupIndex = 1
    local frame, doneRaid, doneParty, doneOldStyle

    if groupType then
        if groupType == "raid" then
            doneParty = true
        else
            doneRaid = true
        end
    end

    return function()
        while not doneRaid do
            index = index + 1

            if index > 5 then
                index = 1
                groupIndex = groupIndex + 1
            end

            frame = _G["CompactRaidGroup"..groupIndex.."Member"..index]

            if frame then
                return frame
            else
                if groupIndex >= 8 then
                    doneRaid = true
                    index = 0
                    break
                end
            end
        end

        while not doneParty do
            index = index + 1

            frame = _G["CompactPartyFrameMember"..index]

            if frame then
                return frame
            else
                index = 0
                doneParty = true
                break
            end
        end

        while not doneOldStyle do
            index = index + 1

            frame = _G["CompactRaidFrame"..index]

            if frame then
                return frame
            else
                doneOldStyle = true
                break
            end
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

local function split(str, sep)
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   str:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

function KHMRaidFrames.SanitizeStringsByUnit(str)
    local t = {}
    local index = 1

    for value in str:gmatch("[^\n]+") do
        local key = KHMRaidFrames.SanitazeString(value)

        if key then
            t[index] = split(key, "::")
            index = index + 1
        end
    end

    return t
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

function KHMRaidFrames.AdditionalTrackingHelpText()

    local s = KHMRaidFrames:TrackingHelpText()

    s = s.."\n".."\n".."\n"..L["AdditionalTrackingHelpText"]

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
    if not self.isOpen then return end

    local virtualFramesButton = self.dialog.general.obj.children and self.dialog.general.obj.children[1]

    if virtualFramesButton then
        virtualFramesButton:ClearAllPoints()
        virtualFramesButton:SetPoint("TOPRIGHT", self.dialog.general.obj.label:GetParent(), "TOPRIGHT", -10, -15)
    end

    local index = KHMRaidFrames_SyncProfiles and 3 or 2
    local groupTypelabel = self.dialog.general.obj.children
    and self.dialog.general.obj.children[index]
    and self.dialog.general.obj.children[index].children
    and self.dialog.general.obj.children[index].children[1]
    and self.dialog.general.obj.children[index].children[1].label

    if groupTypelabel then
        local label = L["You are in |cFFC80000<text>|r"]:gsub("<text>", IsInRaid() and L["Raid"] or L["Party"])
        groupTypelabel:SetText(label)
    end

    if KHMRaidFrames_SyncProfiles then
        local label = L["Profile: |cFFC80000<text>|r"]:gsub("<text>", self.db:GetCurrentProfile())
        local profileLabel = self.dialog.general.obj.children
        and self.dialog.general.obj.children[2]
        and self.dialog.general.obj.children[2].label

        if profileLabel then
            profileLabel:SetText(label)
        end
    end
end

function KHMRaidFrames:ConfigOptionsOpen()
    local index = KHMRaidFrames_SyncProfiles and 3 or 2
    local tabsP = self.dialog.general.obj.children
    and self.dialog.general.obj.children[index]

    tabsP:SelectTab(IsInRaid() and "raid" or "party")

    C_Timer.NewTicker(5, function() self:CustomizeOptions() end)
end

function KHMRaidFrames.PrintV(obj, name)
    if ViragDevTool_AddData then
        ViragDevTool_AddData(obj, name)
    else
        print(obj)
    end
end

function KHMRaidFrames.CompressData(data)
    local LibDeflate = LibStub:GetLibrary("LibDeflate")
    local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

    if LibDeflate and LibAceSerializer then
        local dataSerialized = LibAceSerializer:Serialize(data)
        if dataSerialized then
            local dataCompressed = LibDeflate:CompressDeflate(dataSerialized, {level = 9})
            if dataCompressed then
                local dataEncoded = LibDeflate:EncodeForPrint(dataCompressed)
                return dataEncoded
            end
        end
    end
end

function KHMRaidFrames.DecompressData(data)
    local LibDeflate = LibStub:GetLibrary("LibDeflate")
    local LibAceSerializer = LibStub:GetLibrary("AceSerializer-3.0")

    if LibDeflate and LibAceSerializer then
        local dataCompressed = LibDeflate:DecodeForPrint(data)
        if not dataCompressed then
            KHMRaidFrames:Print("couldn't decode the data.")
            return false
        end

        local dataSerialized = LibDeflate:DecompressDeflate(dataCompressed)
        if not dataSerialized then
            KHMRaidFrames:Print("couldn't uncompress the data.")
            return false
        end

        local okay, data = LibAceSerializer:Deserialize(dataSerialized)
        if not okay then
            KHMRaidFrames:Print("couldn't unserialize the data.")
            return false
        end

        return data
    end
end

function KHMRaidFrames.ExportProfileToString()
    local profile = KHMRaidFrames.db.profile

    local data = KHMRaidFrames.CompressData(profile)
    if not data then
        KHMRaidFrames:Print("failed to compress the profile")
    end

    return data
end

function KHMRaidFrames.ExportCurrentProfile(text)
    if not KHMRaidFrames.ProfileFrame then
        local f = CreateFrame("Frame", "KHMRaidFramesProfileFrame", UIParent, "UIPanelDialogTemplate")
        f:ClearAllPoints()
        f:SetPoint("CENTER")
        f:SetSize(700, 300)
        f:SetClampedToScreen(true)

        local sf = CreateFrame("ScrollFrame", "KHMRaidFramesScrollFrame", f, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -32)

        local eb = CreateFrame("EditBox", "KHMRaidFramesEditBox", KHMRaidFramesScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(true)
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)

        KHMRaidFrames.ProfileFrame = f
    end

    KHMRaidFramesEditBox:SetText(text)
    KHMRaidFramesEditBox:HighlightText()
    KHMRaidFrames.ProfileFrame:Show()
end

function KHMRaidFrames.ImportCurrentProfile(text)
    local db = KHMRaidFrames.DecompressData(text)

    local dbTo = KHMRaidFrames.db.profile

    for k, v in pairs(db) do
        dbTo[k] = v
    end
end

function KHMRaidFrames.SkipFrame(frame)
    return not frame or frame:IsForbidden() or not frame:GetName() or frame:GetName():find("^NamePlate%d")
end