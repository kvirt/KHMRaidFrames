local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

local _G = _G

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

function KHMRaidFrames:IterateCompactGroups(isInRaid)
    local groupIndex = 0

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

function KHMRaidFrames:IterateSubFrameTypes(exclude)
    local index = 0
    local len = #subFrameTypes

    return function()
        index = index + 1
        if index <= len and subFrameTypes[index] ~= exclude then 
            return subFrameTypes[index] 
        end 
    end
end

function KHMRaidFrames:SanitazeString(str)
    key = str:match("[^--]+")
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
        local key = self:SanitazeString(value)
        t[index] = key

        index = index + 1
    end

    return t
end

function KHMRaidFrames:DebuffColorsText()
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
        L["Wildcards"]..":\n"..self:DebuffColorsText()..        
        "155777"..greyCode:gsub("<text>", L["-- Comments"])

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

function KHMRaidFrames:GetTextures()
    local textures = SharedMedia:HashTable("statusbar")

    local s = {}
    for k, v in pairs(textures) do
        table.insert(s, k)
    end


    table.sort(s, function(a, b)
        return a:sub(1, 1):lower() < b:sub(1, 1):lower() 
    end) 

    return textures, s
end