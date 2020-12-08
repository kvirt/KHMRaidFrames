local addonName, addonTable = ...
addonTable.KHMRaidFrames = LibStub("AceAddon-3.0"):NewAddon("KHMRaidFrames", "AceHook-3.0", "AceEvent-3.0", "AceConsole-3.0")

local KHMRaidFrames = addonTable.KHMRaidFrames

local _G = _G
local GetReadyCheckStatus = GetReadyCheckStatus
local UnitInRaid = UnitInRaid
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitInVehicle = UnitInVehicle
local GetRaidRosterInfo = GetRaidRosterInfo
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitPhaseReason = UnitPhaseReason
local Enum = Enum
local C_IncomingSummon = C_IncomingSummon
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitInOtherParty = UnitInOtherParty
local RAID_CLASS_COLORS = RAID_CLASS_COLORS
local UnitClass = UnitClass
local UnitPopupButtons = UnitPopupButtons
local GetRaidTargetIndex = GetRaidTargetIndex
local IsInRaid = IsInRaid
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local C_Timer = C_Timer
local GetUnitName = GetUnitName

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

function KHMRaidFrames:UpdateRaidMark()
    for frame in self:IterateCompactFrames("raid") do
        self:SetUpRaidIcon(frame, "raid")
    end

    for frame in self:IterateCompactFrames("party") do
        self:SetUpRaidIcon(frame, "party")
    end
end

function KHMRaidFrames:SetUpSubFramesPositionsAndSize(frame, typedframes, db, groupType, subFrameType)
    local frameNum = 1
    local typedframe, anchor1, anchor2, relativeFrame, xOffset, yOffset
    local size = db.size * (subFrameType ~= "dispelDebuffFrames" and self.componentScale or 1)

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
            xOffset, yOffset = self:Offsets(anchor1)
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

        if self.db.profile[groupType].frames.clickThrough then
            typedframe:EnableMouse(false)
        else
            typedframe:EnableMouse(true)
        end

        if self.Masque and self.Masque[subFrameType] and typedframe:GetName() then
            self.Masque[subFrameType]:AddButton(typedframe)
        end

        frameNum = frameNum + 1
    end
end

function KHMRaidFrames:SetUpRaidIcon(frame, groupType)
    if not frame.unit then return end

    local db = self.db.profile[groupType]

    if not frame.raidIcon then
        frame.raidIcon = frame:CreateTexture(nil, "OVERLAY")
    end

    if not db.raidIcon.enabled then
        frame.raidIcon:Hide()
        return
    end

    local index = GetRaidTargetIndex(frame.unit)

    if index == "NONE" then
        index = 0
    else
        index = tonumber(index)
    end

    if index and index >= 1 and index <= 8 then
        local options = UnitPopupButtons["RAID_TARGET_"..index]
        local texture, tCoordLeft, tCoordRight, tCoordTop, tCoordBottom = options.icon, options.tCoordLeft, options.tCoordRight, options.tCoordTop, options.tCoordBottom

        frame.raidIcon:ClearAllPoints()

        frame.raidIcon:SetPoint(db.raidIcon.anchorPoint, frame, db.raidIcon.anchorPoint, db.raidIcon.xOffset, db.raidIcon.yOffset)
        frame.raidIcon:SetSize(db.raidIcon.size * self.componentScale, db.raidIcon.size * self.componentScale)

        frame.raidIcon:SetTexture(texture)

        frame.raidIcon:SetTexCoord(tCoordLeft, tCoordRight, tCoordTop, tCoordBottom)

        frame.raidIcon:Show()
    else
        frame.raidIcon:Hide()
    end
end

function KHMRaidFrames:SetUpAbsorb(frame)
    if not frame then return end

    if not self.db.profile[IsInRaid() and "raid" or "party"].frames.enhancedAbsorbs then return end

    local absorbBar = frame.totalAbsorb
    if not absorbBar or absorbBar:IsForbidden()then return end

    local absorbOverlay = frame.totalAbsorbOverlay
    if not absorbOverlay or absorbOverlay:IsForbidden() or not absorbOverlay.tileSize then return end

    local healthBar = frame.healthBar
    if not healthBar or healthBar:IsForbidden() then return end

    local _, maxHealth = healthBar:GetMinMaxValues()
    if maxHealth <= 0 then return end

    if not frame.displayedUnit then return end

    local totalAbsorb = UnitGetTotalAbsorbs(frame.displayedUnit) or 0
    if totalAbsorb > maxHealth then
        totalAbsorb = maxHealth
    end

    local overAbsorbGlow = frame.overAbsorbGlow
    if overAbsorbGlow and not overAbsorbGlow:IsForbidden() then overAbsorbGlow:Hide() end

    if totalAbsorb > 0 then
        absorbOverlay:ClearAllPoints()

        if absorbBar:IsShown() then
            absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
            absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
        else
            absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
            absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)
        end

        local totalWidth, totalHeight = healthBar:GetSize()
        local barSize = totalAbsorb / maxHealth * totalWidth

        absorbOverlay:SetWidth(barSize)
        absorbOverlay:SetTexCoord(0, barSize / absorbOverlay.tileSize, 0, totalHeight / absorbOverlay.tileSize)
        absorbBar:SetAlpha(0.5)
        absorbOverlay:Show()
    end
end

function KHMRaidFrames:SetUpSoloFrame()
    if self.db.profile.party.frames.showPartySolo then
        if not self.ticker or self.ticker:IsCancelled() then
            self.ticker = C_Timer.NewTicker(1, function() self:ShowRaidFrame() end)
        end
    elseif not self.db.profile.party.frames.showPartySolo and self.ticker then
        self.ticker:Cancel()
    end
end

function KHMRaidFrames:SetUpName(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.name then return end
    if not frame.unit then return end

    local db = self.db.profile[groupType].nameAndIcons.name
    local name = frame.name
    local size = db.size * self.componentScale

    local flags = ""

    for k, v in pairs(db.flags) do
        if v then flags = flags..k..", " end
    end

    name:SetFont(
        self.fonts[db.font],
        size,
        flags
    )

    name:ClearAllPoints()

    local _name

    if db.showServer and frame.unit then
        _name = GetUnitName(frame.unit, true)
    else
        _name = GetUnitName(frame.unit, false)
        _name = _name and _name:gsub("%p", "")
    end

    if db.classColoredNames then
        local _, _, id = UnitClass(frame.unit)

        if id then
            local englishClass = englishClasses[id]
            local classColor = RAID_CLASS_COLORS[englishClass]
            name:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    end

    if _name then name:SetText(_name) end

    local xOffset, yOffset = self:Offsets("TOPLEFT")
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset

    name:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        xOffset,
        yOffset
    )

    name:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    name:SetJustifyH(db.hJustify)
end

function KHMRaidFrames:SetUpStatusText(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.statusText then return end

    local db = self.db.profile[groupType].nameAndIcons.statusText
    local statusText = frame.statusText
    local size = db.size * self.componentScale

    local flags = ""

    for k, v in pairs(db.flags) do
        if v then flags = flags..k..", " end
    end

    statusText:ClearAllPoints()

    statusText:SetFont(
        self.fonts[db.font],
        size,
        flags
    )

    local xOffset, yOffset = self:Offsets("BOTTOMLEFT")
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset + ((self.frameHeight / 3) - 2)

    statusText:SetPoint(
        "BOTTOMLEFT",
        frame,
        "BOTTOMLEFT",
        xOffset,
        yOffset
    )

    statusText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", xOffset, yOffset)
    statusText:SetJustifyH(db.hJustify)
end

function KHMRaidFrames:SetUpRoleIcon(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.roleIcon then return end
    if not frame.roleIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.roleIcon
    local roleIcon = frame.roleIcon
    local size = db.size

    roleIcon:ClearAllPoints()

    local xOffset, yOffset = self:Offsets("TOPLEFT")
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset

    roleIcon:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        xOffset,
        yOffset
    )

    roleIcon:SetSize(size, size)

    self:SetUpRoleIconInternal(frame, groupType)
end

function KHMRaidFrames:SetUpRoleIconInternal(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.roleIcon.enabled then return end
    if not frame.unit then return end
    if not frame.roleIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.roleIcon
    local roleIcon = frame.roleIcon

    local raidID = UnitInRaid(frame.unit)

    if UnitInVehicle(frame.unit) and UnitHasVehicleUI(frame.unit) then
        if db.vehicle ~= "" then
            roleIcon:SetTexture(db.vehicle)
            roleIcon:SetTexCoord(0, 1, 0, 1)
        end
    elseif frame.optionTable.displayRaidRoleIcon and raidID and select(10, GetRaidRosterInfo(raidID)) then
        local role = select(10, GetRaidRosterInfo(raidID))
        if db[role:lower()] ~= "" then
            roleIcon:SetTexture(db[role:lower()])
            roleIcon:SetTexCoord(0, 1, 0, 1)
        end
    else
        local role = UnitGroupRolesAssigned(frame.unit)
        if frame.optionTable.displayRoleIcon and (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
            if db[role:lower()] ~= "" then
                roleIcon:SetTexture(db[role:lower()])
                roleIcon:SetTexCoord(0, 1, 0, 1)
            end
        end
    end
end

function KHMRaidFrames:SetUpReadyCheckIcon(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.readyCheckIcon then return end
    if not frame.readyCheckIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.readyCheckIcon
    local readyCheckIcon = frame.readyCheckIcon
    local size = db.size * self.componentScale

    readyCheckIcon:ClearAllPoints()

    local xOffset, yOffset = self:Offsets("BOTTOM")
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset + ((self.frameHeight / 3) - 4)

    readyCheckIcon:SetPoint(
        "BOTTOM",
        frame,
        "BOTTOM",
        xOffset,
        yOffset
    )

    readyCheckIcon:SetSize(size, size)

    self:SetUpReadyCheckIconInternal(frame, groupType)
end

function KHMRaidFrames:SetUpReadyCheckIconInternal(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.readyCheckIcon then return end
    if not frame.unit then return end
    if not frame.readyCheckIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.readyCheckIcon
    local readyCheckIcon = frame.readyCheckIcon

    local readyCheckStatus = GetReadyCheckStatus(frame.unit)
    if db[readyCheckStatus] ~= "" then
        readyCheckIcon:SetTexture(db[readyCheckStatus])
    end
end

function KHMRaidFrames:SetUpCenterStatusIcon(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.centerStatusIcon then return end
    if not frame.centerStatusIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.centerStatusIcon
    local centerStatusIcon = frame.centerStatusIcon
    local size = db.size * self.componentScale

    centerStatusIcon:ClearAllPoints()

    local xOffset, yOffset = self:Offsets("BOTTOM")
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset + ((self.frameHeight / 3) - 4)

    centerStatusIcon:SetPoint(
        "BOTTOM",
        frame,
        "BOTTOM",
        xOffset,
        yOffset
    )

    centerStatusIcon:SetSize(size, size)

    self:SetUpCenterStatusIconInternal(frame, groupType)
end

function KHMRaidFrames:SetUpCenterStatusIconInternal(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.centerStatusIcon then return end
    if not frame.unit then return end
    if not frame.centerStatusIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.centerStatusIcon
    local centerStatusIcon = frame.centerStatusIcon

    if frame.optionTable.displayInOtherGroup and UnitInOtherParty(frame.unit) and db.inOtherGroup ~= "" then
        centerStatusIcon.texture:SetTexture(db.inOtherGroup)
        centerStatusIcon.texture:SetTexCoord(0.125, 0.25, 0.25, 0.5)
    elseif frame.optionTable.displayIncomingResurrect and UnitHasIncomingResurrection(frame.unit) and db.hasIncomingResurrection ~= "" then
        centerStatusIcon.texture:SetTexture(db.hasIncomingResurrection)
        centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
    elseif frame.optionTable.displayIncomingSummon and C_IncomingSummon.HasIncomingSummon(frame.unit) then
        local status = C_IncomingSummon.IncomingSummonStatus(frame.unit)
        if status == Enum.SummonStatus.Pending and db.hasIncomingSummonPending ~= "" then
            centerStatusIcon.texture:SetTexture(db.hasIncomingSummonPending)
            centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
        elseif status == Enum.SummonStatus.Accepted and db.hasIncomingSummonAccepted ~= "" then
            centerStatusIcon.texture:SetTexture(db.hasIncomingSummonAccepted)
            centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
        elseif status == Enum.SummonStatus.Declined and db.hasIncomingSummonDeclined ~= "" then
            centerStatusIcon.texture:SetTexture(db.hasIncomingSummonDeclined)
            centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
        end
    else
        if frame.inDistance and frame.optionTable.displayInOtherPhase and db.inOtherPhase ~= "" then
            local phaseReason = UnitPhaseReason(frame.unit)
            if phaseReason then
                centerStatusIcon.texture:SetTexture(db.inOtherPhase)
                centerStatusIcon.texture:SetTexCoord(0.15625, 0.84375, 0.15625, 0.84375)
            end
        end
    end
end