local addonName, addonTable = ...
addonTable.KHMRaidFrames = LibStub("AceAddon-3.0"):NewAddon("KHMRaidFrames", "AceHook-3.0", "AceEvent-3.0", "AceConsole-3.0")

local KHMRaidFrames = addonTable.KHMRaidFrames

local LCG = LibStub("LibCustomGlow-1.0")

local unpack, select, tonumber = unpack, select, tonumber
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
local AbbreviateLargeNumbers = AbbreviateLargeNumbers
local AbbreviateNumbers = AbbreviateNumbers
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax


-- MAIN FUNCTIONS FOR LAYOUT
function KHMRaidFrames:CompactRaidFrameContainer_LayoutFrames()
    local deferred
    local groupType = IsInRaid() and "raid" or "party"
    local isInCombatLockDown = InCombatLockdown()

    for group in self.IterateCompactGroups(groupType) do
        if self.processedFrames[group] == nil then
            deferred = self:LayoutGroup(group, groupType)

            if deferred == false then
                self.processedFrames[group] = true
            end
        end
    end

    for frame in self.IterateCompactFrames(groupType) do
        if self.processedFrames[frame] == nil then
            deferred = self:LayoutFrame(frame, groupType, isInCombatLockDown)

            if deferred == false then
                self.processedFrames[frame] = true
            end
        end
    end

    self:SetUpSoloFrame()
end

function KHMRaidFrames:LayoutGroup(frame, groupType)
    local db = self.db.profile[groupType]

    if db.frames.hideGroupTitles then
        frame.title:Hide()
    else
        frame.title:Show()
    end

end

function KHMRaidFrames:LayoutFrame(frame, groupType, isInCombatLockDown)
    local db = self.db.profile[groupType]
    local deferred = false

    if not isInCombatLockDown then
        self:AddSubFrames(frame, groupType)
    else
        deferred = true
    end

    self:SetUpSubFramesPositionsAndSize(frame, frame.buffFrames, db.buffFrames, groupType, "buffFrames")
    self:SetUpSubFramesPositionsAndSize(frame, frame.debuffFrames, db.debuffFrames, groupType, "debuffFrames")

    if db.showBigDebuffs and db.smartAnchoring then
        self:SmartAnchoring(frame, frame.debuffFrames, db.debuffFrames)
    end

    self:SetUpSubFramesPositionsAndSize(frame, frame.dispelDebuffFrames, db.dispelDebuffFrames, groupType, "dispelDebuffFrames")

    self:SetUpRaidIcon(frame, groupType)

    if self.db.profile[groupType].nameAndIcons.name.enabled then
        self:SetUpName(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.statusText.enabled then
        self:SetUpStatusText(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.roleIcon.enabled then
        self:SetUpRoleIcon(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled then
        self:SetUpReadyCheckIcon(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled then
        self:SetUpCenterStatusIcon(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.leaderIcon.enabled then
        self.SetUpLeaderIcon(frame, groupType)
    end

    self:CompactUnitFrame_UpdateHealPrediction(frame)

    local texture = self.textures[db.frames.texture] or self.textures[self:Defaults().profile[groupType].frames.texture]
    frame.healthBar:SetStatusBarTexture(texture, "BORDER")

    return deferred
end
--

-- ABSORB PREDICTION
function KHMRaidFrames:CompactUnitFrame_UpdateHealPrediction(frame)
    if not frame or frame:IsForbidden() or not frame:GetName() or frame:GetName():find("^NamePlate%d") or not UnitIsPlayer(frame.displayedUnit) then return end

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
--

-- SOLO FRAME WITHOUT PARTY
function KHMRaidFrames:SetUpSoloFrame()
    if self.db.profile.party.frames.showPartySolo then
        if not self.ticker or self.ticker:IsCancelled() then
            self.ticker = C_Timer.NewTicker(1, function() self:ShowRaidFrame() end)
        end
    elseif not self.db.profile.party.frames.showPartySolo and self.ticker then
        self.ticker:Cancel()
    end
end
--


-- NAME STATUS AND ICONS RELATED FUNCTIONS --

-- NAME
function KHMRaidFrames:SetUpName(frame, groupType)
    if not frame.name then return end

    local db = self.db.profile[groupType].nameAndIcons.name

    if not db.enabled then
        return
    end

    local size = db.size * (self.db.profile[groupType].frames.autoScaling and self.componentScale or 1)

    if not frame.unit then return end

    local name = frame.name

    local flags = db.flag ~= "None" and db.flag or ""

    local font = self.fonts[db.font] or self.fonts[self:Defaults().profile[groupType].nameAndIcons.name.font]

    if not ShouldShowName(frame) or db.hide then
        name:Hide()
        return
    end

    name:SetFont(
        font,
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
        local classColor = KHMRaidFrames.ColorByClass(frame.unit)

        if classColor then
            name:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    else
        if KHMRaidFrames.CompactUnitFrame_IsTapDenied(frame) then
            frame.name:SetVertexColor(0.5, 0.5, 0.5)
        else
            frame.name:SetVertexColor(1.0, 1.0, 1.0)
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

    name:Show()
end

-- STATUS TEXT
function KHMRaidFrames:SetUpStatusText(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.statusText.enabled then return end
    if not frame.statusText then return end
    if not frame.optionTable.displayStatusText then return end

    local db = self.db.profile[groupType].nameAndIcons.statusText
    local statusText = frame.statusText
    local size = db.size * (self.db.profile[groupType].frames.autoScaling and self.componentScale or 1)

    local flags = db.flag ~= "None" and db.flag or ""

    local font = self.fonts[db.font] or self.fonts[self:Defaults().profile[groupType].nameAndIcons.statusText.font]

    statusText:SetFont(
        font,
        size,
        flags
    )

    statusText:ClearAllPoints()

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

    self.SetUpStatusTextInternal(frame, groupType)
end

function KHMRaidFrames.SetUpStatusTextInternal(frame, groupType)
    if not frame.unit then return end
    if not frame.statusText then return end
    if not frame.optionTable.displayStatusText then return end

    local db = KHMRaidFrames.db.profile[groupType].nameAndIcons.statusText

    if not db.enabled then return end

    local statusText = frame.statusText
    local text

    if db.notShowStatuses or db.abbreviateNumbers or db.showPercents then
        if not db.notShowStatuses then
            if not UnitIsConnected(frame.unit) and not db.notShowStatuses then
                text = PLAYER_OFFLINE
            elseif UnitIsDeadOrGhost(frame.displayedUnit) and not db.notShowStatuses then
                text = DEAD
            end
        end

        if text then
            statusText:SetText(health)
        else
            local health = UnitHealth(frame.displayedUnit)

            if db.abbreviateNumbers then
                health = KHMRaidFrames.Abbreviate(health, groupType)
            end

            if db.showPercents then
                health = health.." - "..math.ceil(100 * (UnitHealth(frame.displayedUnit) / UnitHealthMax(frame.displayedUnit))).."%"
            end

            statusText:SetText(health)
        end
    end

    if db.classColoredText then
        local classColor = KHMRaidFrames.ColorByClass(frame.unit)

        if classColor then
            statusText:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    else
        if KHMRaidFrames.CompactUnitFrame_IsTapDenied(frame) then
            statusText:SetVertexColor(0.5, 0.5, 0.5)
        else
            statusText:SetVertexColor(unpack(db.color))
        end
    end
end

-- RAID TARGET ICON (STAR, SQUARE, etc)
function KHMRaidFrames:UpdateRaidMark()
    for frame in self.IterateCompactFrames() do
        self:SetUpRaidIcon(frame)
    end
end

function KHMRaidFrames:SetUpRaidIcon(frame)
    if not frame.unit then return end

    local db = self.db.profile[IsInRaid() and "raid" or "party"]

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
        local size = db.raidIcon.size * (db.frames.autoScaling and self.componentScale or 1)

        frame.raidIcon:ClearAllPoints()

        frame.raidIcon:SetPoint(db.raidIcon.anchorPoint, frame, db.raidIcon.anchorPoint, db.raidIcon.xOffset, db.raidIcon.yOffset)
        frame.raidIcon:SetSize(size, size)

        frame.raidIcon:SetTexture(texture)

        frame.raidIcon:SetTexCoord(tCoordLeft, tCoordRight, tCoordTop, tCoordBottom)

        frame.raidIcon:SetAlpha(db.raidIcon.alpha)

        frame.raidIcon:Show()
    else
        frame.raidIcon:Hide()
    end
end

-- ROLE ICON
function KHMRaidFrames:SetUpRoleIcon(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.roleIcon.enabled then return end
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

    if db.hide then
        roleIcon:Hide()
        return
    end

    local raidID = UnitInRaid(frame.unit)
    local _role

    if UnitInVehicle(frame.unit) and UnitHasVehicleUI(frame.unit) then
        _role = "vehicle"
    elseif frame.optionTable.displayRaidRoleIcon and raidID and select(10, GetRaidRosterInfo(raidID)) then
        local role = select(10, GetRaidRosterInfo(raidID))
        _role = role:lower()
    else
        local role = UnitGroupRolesAssigned(frame.unit)
        if frame.optionTable.displayRoleIcon and (role == "TANK" or role == "HEALER" or role == "DAMAGER") then
            _role = role:lower()
        end
    end

    if _role and db[_role:lower()] ~= "" then
        roleIcon:SetTexture(db[_role])
        roleIcon:SetTexCoord(0, 1, 0, 1)
        roleIcon:SetVertexColor(unpack(db.colors[_role]))
        roleIcon:Show()
    end
end

-- READY CHECK ICON
function KHMRaidFrames:SetUpReadyCheckIcon(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled then return end
    if not frame.readyCheckIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.readyCheckIcon
    local readyCheckIcon = frame.readyCheckIcon
    local size = db.size * (self.db.profile[groupType].frames.autoScaling and self.componentScale or 1)

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
    if not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled then return end
    if not frame.unit then return end
    if not frame.readyCheckIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.readyCheckIcon
    local readyCheckIcon = frame.readyCheckIcon

    if db.hide then
        readyCheckIcon:Hide()
    end

    local readyCheckStatus = GetReadyCheckStatus(frame.unit)

    if readyCheckStatus and db[readyCheckStatus] ~= "" then
        readyCheckIcon:SetTexture(db[readyCheckStatus])
        readyCheckIcon:SetVertexColor(unpack(db.colors[readyCheckStatus]))
        readyCheckIcon:Show()
    end
end

-- CENTER STATUS ICON
function KHMRaidFrames:SetUpCenterStatusIcon(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled then return end
    if not frame.centerStatusIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.centerStatusIcon
    local centerStatusIcon = frame.centerStatusIcon
    local size = db.size * (self.db.profile[groupType].frames.autoScaling and self.componentScale or 1)

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
    if not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled then return end
    if not frame.unit then return end
    if not frame.centerStatusIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.centerStatusIcon
    local centerStatusIcon = frame.centerStatusIcon

    if db.hide then
        centerStatusIcon:Hide()
        return
    end

    if frame.optionTable.displayInOtherGroup and UnitInOtherParty(frame.unit) and db.inOtherGroup ~= "" then
        centerStatusIcon.texture:SetTexture(db.inOtherGroup)
        centerStatusIcon.texture:SetTexCoord(0.125, 0.25, 0.25, 0.5)
        centerStatusIcon.texture:SetVertexColor(unpack(db.colors.inOtherGroup))
        centerStatusIcon:Show()
    elseif frame.optionTable.displayIncomingResurrect and UnitHasIncomingResurrection(frame.unit) and db.hasIncomingResurrection ~= "" then
        centerStatusIcon.texture:SetTexture(db.hasIncomingResurrection)
        centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
        centerStatusIcon.texture:SetVertexColor(unpack(db.colors.hasIncomingResurrection))
        centerStatusIcon:Show()
    elseif frame.optionTable.displayIncomingSummon and C_IncomingSummon.HasIncomingSummon(frame.unit) then
        local status = C_IncomingSummon.IncomingSummonStatus(frame.unit)
        if status == Enum.SummonStatus.Pending and db.hasIncomingSummonPending ~= "" then
            centerStatusIcon.texture:SetTexture(db.hasIncomingSummonPending)
            centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
            centerStatusIcon.texture:SetVertexColor(unpack(db.colors.hasIncomingSummonPending))
            centerStatusIcon:Show()
        elseif status == Enum.SummonStatus.Accepted and db.hasIncomingSummonAccepted ~= "" then
            centerStatusIcon.texture:SetTexture(db.hasIncomingSummonAccepted)
            centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
            centerStatusIcon.texture:SetVertexColor(unpack(db.colors.hasIncomingSummonAccepted))
            centerStatusIcon:Show()
        elseif status == Enum.SummonStatus.Declined and db.hasIncomingSummonDeclined ~= "" then
            centerStatusIcon.texture:SetTexture(db.hasIncomingSummonDeclined)
            centerStatusIcon.texture:SetTexCoord(0, 1, 0, 1)
            centerStatusIcon.texture:SetVertexColor(unpack(db.colors.hasIncomingSummonDeclined))
            centerStatusIcon:Show()
        end
    else
        if frame.inDistance and frame.optionTable.displayInOtherPhase and db.inOtherPhase ~= "" then
            local phaseReason = UnitPhaseReason(frame.unit)
            if phaseReason then
                centerStatusIcon.texture:SetTexture(db.inOtherPhase)
                centerStatusIcon.texture:SetTexCoord(0.15625, 0.84375, 0.15625, 0.84375)
                centerStatusIcon.texture:SetVertexColor(unpack(db.colors.inOtherPhase))
                centerStatusIcon:Show()
            end
        end
    end
end

-- LEADER ICON
function KHMRaidFrames.UpdateLeaderIcon()
    local groupType = IsInRaid() and "raid" or "party"

    for frame in KHMRaidFrames.IterateCompactFrames() do
        KHMRaidFrames.SetUpLeaderIcon(frame, groupType)
    end
end

function KHMRaidFrames.SetUpLeaderIcon(frame, groupType)
    if not frame or not frame.unit then return end

    if not frame.leaderIcon then
        frame.leaderIcon = frame:CreateTexture(nil, "OVERLAY")
    end

    if not KHMRaidFrames.db.profile[groupType].nameAndIcons.leaderIcon.enabled then
        frame.leaderIcon:Hide()
        return
    end

    local db = KHMRaidFrames.db.profile[groupType].nameAndIcons.leaderIcon
    local size = db.size * (KHMRaidFrames.db.profile[groupType].frames.autoScaling and KHMRaidFrames.componentScale or 1)

    local isLeader = UnitIsGroupLeader(frame.unit)

    if not isLeader then
        frame.leaderIcon:Hide()
        return
    end

    frame.leaderIcon:ClearAllPoints()

    local xOffset, yOffset = KHMRaidFrames:Offsets(db.anchorPoint)
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset

    frame.leaderIcon:SetPoint(
        db.anchorPoint,
        frame,
        db.anchorPoint,
        xOffset,
        yOffset
    )

    frame.leaderIcon:SetSize(size, size)
    frame.leaderIcon:SetAlpha(db.alpha)

    if db.icon ~= "" then
        frame.leaderIcon:SetTexture(db.icon)
        frame.leaderIcon:SetVertexColor(unpack(db.colors.icon))
    else
        frame.leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon")
        frame.leaderIcon:SetVertexColor(1, 1, 1)
    end

    frame.leaderIcon:Show()
end
--

-- GLOWS START/STOP
function KHMRaidFrames.StartGlow(frame, db, color, key, gType)
    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options
    local color = color or options.color

    if glowType == "button" then
        LCG.ButtonGlow_Start(frame, color, options.frequency)
    elseif glowType == "pixel" then
        LCG.PixelGlow_Start(frame, color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border, key or "")
    elseif glowType == "auto" then
        LCG.AutoCastGlow_Start(frame, color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset, key or "")
    end

    KHMRaidFrames.glowingFrames[gType][key][frame] = color
end

function KHMRaidFrames.StopGlow(frame, db, key, gType)
    if db.type == "button" then
        LCG.ButtonGlow_Stop(frame, key or "")
    elseif db.type == "pixel" then
        LCG.PixelGlow_Stop(frame, key or "")
    elseif db.type == "auto" then
        LCG.AutoCastGlow_Stop(frame, key or "")
    end

    KHMRaidFrames.glowingFrames[gType][key][frame] = nil
end
--