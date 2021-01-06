local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

SharedMedia:Register("statusbar", "Blizzard Raid PowerBar", "Interface\\RaidFrame\\Raid-Bar-Resource-Fill")

local _G, tostring, CreateFrame, IsInRaid, InCombatLockdown = _G, tostring, CreateFrame, IsInRaid, InCombatLockdown

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

local englishClasses = {
    "WARRIOR",
    "PALADIN",
    "HUNTER",
    "ROGUE",
    "PRIEST",
    "DEATHKNIGHT",
    "SHAMAN",
    "MAGE",
    "WARLOCK",
    "MONK",
    "DRUID",
    "DEMONHUNTER",
}

KHMRaidFrames.NATIVE_UNIT_FRAME_HEIGHT = 36
KHMRaidFrames.NATIVE_UNIT_FRAME_WIDTH = 72
KHMRaidFrames.CUF_AURA_BOTTOM_OFFSET = 2

KHMRaidFrames.defuffsColors = {
    magic = {0.2, 0.6, 1.0, 1},
    curse = {0.6, 0.0, 1.0, 1},
    disease = {0.6, 0.4, 0.0, 1},
    poison = {0.0, 0.6, 0.0, 1},
    physical = {1, 1, 1, 1}
}

KHMRaidFrames.textMirrors = {
    ["TOPLEFT"] = {"TOPRIGHT", "LEFT"},
    ["LEFT"] = {"RIGHT", "LEFT"},
    ["BOTTOMLEFT"] = {"BOTTOMRIGHT", "LEFT"},
    ["BOTTOMRIGHT"] = {"BOTTOMLEFT", "RIGHT"},
    ["RIGHT"] = {"LEFT", "RIGHT"},
    ["TOPRIGHT"] = {"BOTTOMLEFT", "RIGHT"},
}

KHMRaidFrames.mirrorPositions = {
    ["LEFT"] = {"BOTTOMRIGHT", "BOTTOMLEFT"},
    ["BOTTOM"] = {"TOPLEFT", "BOTTOMLEFT"},
    ["RIGHT"] = {"BOTTOMLEFT", "BOTTOMRIGHT"},
    ["TOP"] = {"BOTTOMLEFT", "TOPLEFT"},
}

KHMRaidFrames.smartAnchoring = {
    ["BOTTOM"] = {"LEFT", "RIGHT"},
    ["TOP"] = {"LEFT", "RIGHT"},
    ["RIGHT"] = {"BOTTOM", "TOP"},
    ["LEFT"] = {"BOTTOM", "TOP"},
}

KHMRaidFrames.smartAnchoringRowsPositions = {
    ["LEFT"] = {
        ["BOTTOM"] = {"TOPRIGHT", "TOPLEFT"},
        ["TOP"] = {"BOTTOMRIGHT", "BOTTOMLEFT"},
    },
    ["BOTTOM"] = {
        ["LEFT"] = {"TOPRIGHT", "BOTTOMRIGHT"},
        ["RIGHT"] = {"TOPLEFT", "BOTTOMLEFT"},
    },
    ["RIGHT"] = {
        ["BOTTOM"] = {"TOPLEFT", "TOPRIGHT"},
        ["TOP"] = {"BOTTOMLEFT", "BOTTOMRIGHT"},
    },
    ["TOP"] ={
        ["LEFT"] = {"BOTTOMRIGHT", "TOPRIGHT"},
        ["RIGHT"] = {"BOTTOMLEFT", "TOPLEFT"},
    },
}

KHMRaidFrames.rowsPositions = {
    ["LEFT"] = {"TOPRIGHT", "TOPLEFT"},
    ["BOTTOM"] = {"TOPRIGHT", "BOTTOMRIGHT"},
    ["RIGHT"] = {"BOTTOMLEFT", "BOTTOMRIGHT"},
    ["TOP"] = {"BOTTOMLEFT", "TOPLEFT"},
}

KHMRaidFrames.rowsGrows = {
    ["TOPLEFT"] = {
        ["LEFT"] = "BOTTOM",
        ["BOTTOM"] = "RIGHT",
        ["RIGHT"] = "BOTTOM",
        ["TOP"] = "RIGHT",
    },
    ["LEFT"] = {
        ["LEFT"] = "BOTTOM",
        ["BOTTOM"] = "RIGHT",
        ["RIGHT"] = "BOTTOM",
        ["TOP"] = "RIGHT",
    },
    ["BOTTOMLEFT"] = {
        ["LEFT"] = "TOP",
        ["BOTTOM"] = "RIGHT",
        ["RIGHT"] = "TOP",
        ["TOP"] = "RIGHT",
    },
    ["BOTTOM"] = {
        ["LEFT"] = "TOP",
        ["BOTTOM"] = "RIGHT",
        ["RIGHT"] = "TOP",
        ["TOP"] = "RIGHT",
    },
    ["BOTTOMRIGHT"] = {
        ["LEFT"] = "TOP",
        ["BOTTOM"] = "LEFT",
        ["RIGHT"] = "TOP",
        ["TOP"] = "LEFT",
    },
    ["RIGHT"] = {
        ["LEFT"] = "TOP",
        ["BOTTOM"] = "LEFT",
        ["RIGHT"] = "TOP",
        ["TOP"] = "LEFT",
    },
    ["TOPRIGHT"] = {
        ["LEFT"] = "BOTTOM",
        ["BOTTOM"] = "LEFT",
        ["RIGHT"] = "BOTTOM",
        ["TOP"] = "LEFT",
    },
    ["TOP"] = {
        ["LEFT"] = "BOTTOM",
        ["BOTTOM"] = "LEFT",
        ["RIGHT"] = "BOTTOM",
        ["TOP"] = "LEFT",
    },
    ["CENTER"] = {
        ["LEFT"] = "TOP",
        ["BOTTOM"] = "RIGHT",
        ["RIGHT"] = "TOP",
        ["TOP"] =  "RIGHT",
    }
}

function KHMRaidFrames.GetRole(frame)
    local raidID = UnitInRaid(frame.unit)
    local role

    if UnitInVehicle(frame.unit) and UnitHasVehicleUI(frame.unit) then
        role = "VEHICLE"
    elseif frame.optionTable.displayRaidRoleIcon and raidID and select(10, GetRaidRosterInfo(raidID)) then
        role = select(10, GetRaidRosterInfo(raidID))
    else
        role = UnitGroupRolesAssigned(frame.unit)
    end

    return role
end

function KHMRaidFrames:SetUpSubFramesPositionsAndSize(frame, subFrameType, groupType, virtual)
    local frameNum = 1
    local typedframe, anchor1, anchor2, relativeFrame, xOffset, yOffset
    local db = self.db.profile[groupType][subFrameType]
    local size = db.size * (subFrameType ~= "dispelDebuffFrames" and (self.db.profile[groupType].frames.autoScaling and self.componentScale or 1) or 1)
    local typedframes = virtual and self.virtual.frames[subFrameType] or frame[subFrameType]

    while frameNum <= #typedframes do
        typedframe = typedframes[frameNum]
        typedframe:ClearAllPoints()

        if frameNum == 1 then
            anchor1, relativeFrame, anchor2 = db.anchorPoint, frame, db.anchorPoint
        elseif frameNum % (db.numInRow) == 1 then
            anchor1, relativeFrame, anchor2 = self.rowsPositions[db.rowsGrowDirection][1], typedframes[frameNum - db.numInRow], self.rowsPositions[db.rowsGrowDirection][2]
        else
            anchor1, relativeFrame, anchor2 = self.mirrorPositions[db.growDirection][1], typedframes[frameNum - 1], self.mirrorPositions[db.growDirection][2]
        end

        if frameNum == 1 then
            xOffset, yOffset = self:Offsets(anchor1, frame, groupType)
            xOffset = xOffset + db.xOffset
            yOffset = yOffset + db.yOffset
        else
            xOffset, yOffset = 0, 0
        end

        typedframe:SetPoint(
            anchor1,
            relativeFrame,
            anchor2,
            xOffset,
            yOffset
        )

        typedframe:SetSize(size, size)
        typedframe:SetAlpha(db.alpha)

        if self.db.profile[groupType].frames.clickThrough then
            typedframe:EnableMouse(false)
        else
            typedframe:EnableMouse(true)
        end

        frameNum = frameNum + 1
    end
end

function KHMRaidFrames.MasqueSupport(frame)
    if not KHMRaidFrames.db.profile.Masque then return end

    for _, typedframe in ipairs(frame.buffFrames) do
        KHMRaidFrames.Masque.buffFrames:RemoveButton(typedframe)
        KHMRaidFrames.Masque.buffFrames:AddButton(typedframe)
    end

    for _, typedframe in ipairs(frame.debuffFrames) do
        KHMRaidFrames.Masque.debuffFrames:RemoveButton(typedframe)
        KHMRaidFrames.Masque.debuffFrames:AddButton(typedframe)
    end
end

function KHMRaidFrames:SetUpMainSubFramePosition(frame, subFrameType, groupType)
    local db = self.db.profile[groupType][subFrameType]

    local anchor1, relativeFrame, anchor2 = db.anchorPoint, frame, db.anchorPoint

    xOffset, yOffset = self:Offsets(anchor1, frame, groupType)
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset

    if not frame[subFrameType] or not frame[subFrameType][1] then return end

    frame[subFrameType][1]:ClearAllPoints()
    frame[subFrameType][1]:SetPoint(anchor1, relativeFrame, anchor2, xOffset, yOffset)
end

function KHMRaidFrames:RefreshConfig(virtualGroupType)
    local groupType = IsInRaid() and "raid" or "party"

    local isInCombatLockDown = InCombatLockdown()

    self:SetUpVirtual("buffFrames", virtualGroupType, self.componentScale)
    self:SetUpVirtual("debuffFrames", virtualGroupType, self.componentScale, true)
    self:SetUpVirtual("dispelDebuffFrames", virtualGroupType, 1)

    for group in self.IterateCompactGroups(groupType) do
        self:LayoutGroup(group, groupType, isInCombatLockDown)
    end

    for frame in self.IterateCompactFrames(groupType) do
        self:LayoutFrame(frame, groupType, isInCombatLockDown)
        self.MasqueSupport(frame)
    end

    self:SetUpSoloFrame()
end

function KHMRaidFrames:Offsets(anchor, frame, groupType, force)
    local displayPowerBar, powerBarUsedHeight

    if not force then
        if self.db.profile[groupType].frames.showResourceOnlyForHealers and self.displayPowerBar then
            displayPowerBar = frame.unit and UnitGroupRolesAssigned(frame.unit) == "HEALER"
        else
            displayPowerBar = self.displayPowerBar
        end

        powerBarUsedHeight = (displayPowerBar and self.db.profile[groupType].frames.powerBarHeight or 0) + self.CUF_AURA_BOTTOM_OFFSET
    else
        powerBarUsedHeight = (self.displayPowerBar and self.db.profile[groupType].frames.powerBarHeight or 0) + self.CUF_AURA_BOTTOM_OFFSET
    end

    local xOffset, yOffset = 0, 0

    if anchor == "LEFT" then
        xOffset, yOffset = 3, 0
    elseif anchor == "RIGHT" then
        xOffset, yOffset = -3, 0
    elseif anchor == "TOP" then
        xOffset, yOffset = 0, -3
    elseif anchor == "BOTTOM" then
        xOffset, yOffset = 0, powerBarUsedHeight
    elseif anchor == "BOTTOMLEFT" then
        xOffset, yOffset = 3, powerBarUsedHeight
    elseif anchor == "BOTTOMRIGHT" then
        xOffset, yOffset = -3, powerBarUsedHeight
    elseif anchor == "TOPLEFT" then
        xOffset, yOffset = 3, -3
    elseif anchor == "TOPRIGHT" then
        xOffset, yOffset = -3, -3
    end

    return xOffset, yOffset
end

function KHMRaidFrames:AddSubFrames(frame, groupType)
    for subFrameType in self.IterateSubFrameTypes() do
        local frameName, template
        local db = self.db.profile[groupType][subFrameType]

        if subFrameType == "buffFrames" then
            template = "CompactBuffTemplate"
            frameName = frame:GetName().."Buff"
        elseif subFrameType == "debuffFrames" then
            template = "CompactDebuffTemplate"
            frameName = frame:GetName().."Debuff"
        elseif subFrameType == "dispelDebuffFrames" then
            template = "CompactDispelDebuffTemplate"
            frameName = frame:GetName().."DispelDebuff"
        end

        for i=#frame[subFrameType] + 1, db.num do
            local typedFrame = _G[frameName..i] or CreateFrame("Button", frameName..i, frame, template)

            typedFrame:ClearAllPoints()
            typedFrame:Hide()
        end
    end
end

function KHMRaidFrames:FilterAuras(name, debuffType, spellId, frameType)
    local db, excluded

    if IsInRaid() then
        db = self.db.profile.raid[frameType]
    else
        db = self.db.profile.party[frameType]
    end

    excluded = self:FilterAurasInternal(name, debuffType, spellId, db.exclude)

    if excluded then return false else return true end
end

function KHMRaidFrames:FilterAurasInternal(name, debuffType, spellId, db)
    if #db == 0 then return false end

    name = name and self.SanitazeString(name)
    debuffType = debuffType and self.SanitazeString(debuffType)
    spellId = tostring(spellId)

    for _, aura in ipairs(db) do
        if aura ~= nil and (aura == name or aura == debuffType or (spellId ~= nil and aura == spellId)) then
            return true
        end
    end

    return false
end

function KHMRaidFrames:AdditionalAura(name, debuffType, spellId, unitCaster)
    local db

    if IsInRaid() then
        db = self.db.profile.raid.frames.tracking
    else
        db = self.db.profile.party.frames.tracking
    end

    if #db == 0 then return false end

    name = name and self.SanitazeString(name)
    debuffType = debuffType and self.SanitazeString(debuffType)
    spellId = tostring(spellId)

    for _, aura in ipairs(db) do
        local _aura, unit = aura[1], aura[2]
        if _aura == name or _aura == debuffType or (spellId ~= nil and _aura == spellId) then
            if not unit then
                return true
            elseif unit == unitCaster then
                return true
            end
        end
    end

    return false
end

function KHMRaidFrames:SmartAnchoring(frame, groupType, virtual)
    local db = self.db.profile[groupType].debuffFrames
    local typedframes = virtual and self.virtual.frames.debuffFrames or frame.debuffFrames
    local frameNum = 1
    local typedframe, anchor1, anchor2, relativeFrame, xOffset, yOffset

    local size = db.size * self.componentScale
    local bigSize = size * 2
    local rowStart = 1
    local groupType = IsInRaid() and "raid" or "party"

    while frameNum <= #typedframes do
        local rowLen = db.numInRow
        local index = 1
        local bigs = 0

        if typedframe and not typedframe:IsShown() then
            break
        end

        while true do
            if frameNum > #typedframes then break end

            typedframe = typedframes[frameNum]

            if typedframe and not typedframe:IsShown() then
                break
            end

            typedframe:ClearAllPoints()

            if frameNum == 1 then
                anchor1, relativeFrame, anchor2 = db.anchorPoint, frame, db.anchorPoint
            elseif index == 1 then
                anchor1, relativeFrame, anchor2 = self.smartAnchoringRowsPositions[db.rowsGrowDirection][db.growDirection][1], typedframes[rowStart], self.smartAnchoringRowsPositions[db.rowsGrowDirection][db.growDirection][2]
                rowStart = frameNum
            elseif index % rowLen == 1 then
                if bigs > 0 and rowLen > bigs then
                    for j=1, rowLen - (bigs * 2) do
                        if frameNum > #typedframes then break end

                        typedframe = typedframes[frameNum]
                        typedframe:ClearAllPoints()

                        anchor1, relativeFrame, anchor2 = self.smartAnchoring[db.growDirection][1], typedframes[frameNum - (rowLen - (bigs * 2))], self.smartAnchoring[db.growDirection][2]

                        typedframe:SetPoint(
                            anchor1,
                            relativeFrame,
                            anchor2,
                            xOffset,
                            yOffset
                        )

                        typedframe:SetSize(typedframe.isBossAura and bigSize or size, typedframe.isBossAura and bigSize or size)

                        frameNum = frameNum + 1
                    end
                end
                break
            else
                anchor1, relativeFrame, anchor2 = self.mirrorPositions[db.growDirection][1], typedframes[frameNum - 1], self.mirrorPositions[db.growDirection][2]
            end

            if frameNum == 1 then
                xOffset, yOffset = self:Offsets(anchor1, frame, groupType)
                xOffset = xOffset + db.xOffset
                yOffset = yOffset + db.yOffset
            else
                xOffset, yOffset = 0, 0
            end

            typedframe:SetPoint(
                anchor1,
                relativeFrame,
                anchor2,
                xOffset,
                yOffset
            )

            typedframe:SetSize(typedframe.isBossAura and bigSize or size, typedframe.isBossAura and bigSize or size)

            frameNum = frameNum + 1

            if typedframe.isBossAura then
                index = index + 2
                bigs = bigs + 1

                if index > rowLen then break end
            else
                index = index + 1
            end
        end
    end
end

function KHMRaidFrames.ColorByClass(unit)
    local _, _, id = UnitClass(unit)

    if id then
        local englishClass = englishClasses[id]
        local classColor = RAID_CLASS_COLORS[englishClass]
        return classColor
    end
end

function KHMRaidFrames:SafeRefresh(virtualGroupType)
    if not self.refreshingSettings then
        self.refreshingSettings = true
        C_Timer.After(self.refreshThrottleSecs, function()
            self:SafeRefreshInternal(virtualGroupType)
        end)
    end
end

function KHMRaidFrames:SafeRefreshInternal(virtualGroupType)
    self:RefreshConfig(virtualGroupType)

    self.refreshingSettings = false
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

function KHMRaidFrames.IsFrameOk(frame)
    return not KHMRaidFrames.SkipFrame(frame) and (UnitExists(frame.displayedUnit)) and not (frame.unit and string.find(frame.unit, "pet"))
end

local function Round(num, numDecimalPlaces, litera)
  return string.format("%." .. (numDecimalPlaces or 0) .. "f"..litera, num)
end

function KHMRaidFrames.Abbreviate(num, groupType)
    local precision = KHMRaidFrames.db.profile[groupType].nameAndIcons.statusText.precision

    if num < 1000 then
        return num
    elseif num < 1000000 then
        return Round(num / 1000, precision, "K")
    else
        return Round(num / 1000000, precision, "M")
    end
end