local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")

local _G = _G

local subFrameTypes = {"debuffFrames", "buffFrames", "dispelDebuffFrames"}

local systemYellowCode = "|cFFffd100<text>|r"
local yellowCode = "|cFFFFF569<text>|r"
local redCode = "|cFFC80000<text>|r"
local greenCode = "|cFF009600<text>|r"
local purpleCode = "|cFF9600FF<text>|r"
local blueCode = "|cFF3296FF<text>|r"
local brownCode = "|cFF966400<text>|r"
local greyCode = "|cFFb8b6b0<text>|r"


function KHMRaidFrames:SafeRefresh()
    if InCombatLockdown() then
        self:Print("Can not refresh settings while in combat")        
        self:HideAll() 
        return
    else
        self:RefreshConfig()
    end
end

function KHMRaidFrames:IterateRaidGroups()
    local groupIndex = 0

    return function()
        groupIndex = groupIndex + 1

        local groupFrame = _G["CompactRaidGroup"..groupIndex]
        if groupIndex <= 8 and groupFrame then return groupFrame end 
    end
end

function KHMRaidFrames:IterateRaidMembers()    
    local groupIndex = 0
    local index = 0

    return function()
        while groupIndex <= 8 do
            index = index + 1

            if index > 5 then
                index = 1
                groupIndex = groupIndex + 1
            end

            local frame = _G["CompactRaidGroup"..groupIndex.."Member"..index]
            if frame then return frame end
        end
    end
end

function KHMRaidFrames:IterateGroupMembers()
    local index = 0
    local groupFrame = _G["CompactPartyFrame"]

    return function()
       index = index + 1
       if index <= 5 then return groupFrame and _G[groupFrame:GetName().."Member"..index] end 
    end
end

function KHMRaidFrames:IterateSubFrameTypes()
    local index = 0
    local len = #subFrameTypes

    return function()
       index = index + 1
       if index <= len then return subFrameTypes[index] end 
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

function KHMRaidFrames:TrackingHelpText()

    local s = "\n".."\n".."\n"..
        L["Rejuvenation"].."\n"..
        "Curse".."\n"..
        "155777".."\n"..
        "Magic".."\n"..
        "\n"..
        L["Wildcards"]..":\n"..
        greenCode:gsub("<text>", "Poison").."\n"..
        purpleCode:gsub("<text>", "Curse").."\n"..
        brownCode:gsub("<text>", "Disease").."\n"..
        blueCode:gsub("<text>", "Magic").."\n"..
        redCode:gsub("<text>", "Physical").."\n"..        
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

function KHMRaidFrames:CheckNil(table, key, value)
    if key ~= nil then
        table[key] = value
    end
end

-- function KHMRaidFrames:SubFramesIndexMT()
--     local t = {}

--     t.__newindex  = function(_table, key, value)
--         if key == nil then
--             return
--         else
--             rawset(_table, key, value)
--         end
--     end

--     return t
-- end