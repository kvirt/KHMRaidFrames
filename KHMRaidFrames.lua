local addonName, addonTable = ...
addonTable.KHMRaidFrames = LibStub("AceAddon-3.0"):NewAddon("KHMRaidFrames", "AceHook-3.0", "AceEvent-3.0", "AceConsole-3.0")

local KHMRaidFrames = addonTable.KHMRaidFrames

local LCG = LibStub("LibCustomGlow-1.0")
local SharedMedia = LibStub("LibSharedMedia-3.0")

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
local GetRaidTargetIndex = GetRaidTargetIndex
local IsInRaid = IsInRaid
local UnitGetTotalAbsorbs = UnitGetTotalAbsorbs
local C_Timer = C_Timer
local GetUnitName = GetUnitName
local AbbreviateLargeNumbers = AbbreviateLargeNumbers
local AbbreviateNumbers = AbbreviateNumbers
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitExists = UnitExists
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsConnected = UnitIsConnected
local UnitPopupButtons = {
	["RAID_TARGET_ICON"] = { text = RAID_TARGET_ICON, dist = 0, nested = 1 },
	["RAID_TARGET_1"] = { text = RAID_TARGET_1, dist = 0, checkable = 1, color = {r = 1.0, g = 0.92, b = 0}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", tCoordLeft = 0, tCoordRight = 0.25, tCoordTop = 0, tCoordBottom = 0.25 },
	["RAID_TARGET_2"] = { text = RAID_TARGET_2, dist = 0, checkable = 1, color = {r = 0.98, g = 0.57, b = 0}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", tCoordLeft = 0.25, tCoordRight = 0.5, tCoordTop = 0, tCoordBottom = 0.25 },
	["RAID_TARGET_3"] = { text = RAID_TARGET_3, dist = 0, checkable = 1, color = {r = 0.83, g = 0.22, b = 0.9}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", tCoordLeft = 0.5, tCoordRight = 0.75, tCoordTop = 0, tCoordBottom = 0.25 },
	["RAID_TARGET_4"] = { text = RAID_TARGET_4, dist = 0, checkable = 1, color = {r = 0.04, g = 0.95, b = 0}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", tCoordLeft = 0.75, tCoordRight = 1, tCoordTop = 0, tCoordBottom = 0.25 },
	["RAID_TARGET_5"] = { text = RAID_TARGET_5, dist = 0, checkable = 1, color = {r = 0.7, g = 0.82, b = 0.875}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", tCoordLeft = 0, tCoordRight = 0.25, tCoordTop = 0.25, tCoordBottom = 0.5 },
	["RAID_TARGET_6"] = { text = RAID_TARGET_6, dist = 0, checkable = 1, color = {r = 0, g = 0.71, b = 1}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", tCoordLeft = 0.25, tCoordRight = 0.5, tCoordTop = 0.25, tCoordBottom = 0.5 },
	["RAID_TARGET_7"] = { text = RAID_TARGET_7, dist = 0, checkable = 1, color = {r = 1.0, g = 0.24, b = 0.168}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", tCoordLeft = 0.5, tCoordRight = 0.75, tCoordTop = 0.25, tCoordBottom = 0.5 },
	["RAID_TARGET_8"] = { text = RAID_TARGET_8, dist = 0, checkable = 1, color = {r = 0.98, g = 0.98, b = 0.98}, icon = "Interface\\TargetingFrame\\UI-RaidTargetingIcons", tCoordLeft = 0.75, tCoordRight = 1, tCoordTop = 0.25, tCoordBottom = 0.5 },
	["RAID_TARGET_NONE"] = { text = RAID_TARGET_NONE, dist = 0, checkable = 1 }
}

-- MAIN FUNCTIONS FOR LAYOUT
function KHMRaidFrames:CompactUnitFrame_UpdateAll(frame)
    if self.SkipFrame(frame) then return end

    local groupType = IsInRaid() and "raid" or "party"

    local isInCombatLockDown = InCombatLockdown()

    if groupType ~= self.currentGroup then
        self:RefreshProfileSettings()
    end

    local name = frame and frame:GetName()
    if not name then return end

    if not UnitExists(frame.displayedUnit) then return end

    local lastGroupType = self.processedFrames[name]

    if groupType ~= lastGroupType or groupType == "party" then
        self:LayoutFrame(frame, groupType, isInCombatLockDown)
        self.processedFrames[name] = groupType
    end
end

function KHMRaidFrames:CompactRaidFrameContainer_LayoutFrames()
    local groupType = IsInRaid() and "raid" or "party"

    for group in self.IterateCompactGroups(groupType) do
        self:LayoutGroup(group, groupType)
    end

    self:SetUpSoloFrame()
end

function KHMRaidFrames:LayoutGroup(frame, groupType)
    if self.db.profile[groupType].frames.hideGroupTitles then
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

    local texture = SharedMedia:Fetch("statusbar", db.frames.texture) or SharedMedia:Fetch("statusbar", self:Defaults().profile[groupType].frames.texture)
    frame.healthBar:SetStatusBarTexture(texture, "BORDER")

    if not self.db.profile[groupType].frames.showResourceOnlyForHealers and KHMRaidFrames.displayPowerBar and (frame.unit and not string.find(frame.unit, "pet")) then
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, self.db.profile[groupType].frames.powerBarHeight + 1)
        frame.horizDivider:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1 + self.db.profile[groupType].frames.powerBarHeight)
        frame.horizDivider:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 1 + self.db.profile[groupType].frames.powerBarHeight)
    end

    local texture = SharedMedia:Fetch("statusbar", db.frames.powerBarTexture) or SharedMedia:Fetch("statusbar", self:Defaults().profile[groupType].frames.powerBarTexture)
    frame.powerBar:SetStatusBarTexture(texture, "BORDER")

    self.UpdateResourceBar(frame, groupType, nil, true)

    self:SetUpSubFramesPositionsAndSize(frame, "buffFrames", groupType)
    self:SetUpSubFramesPositionsAndSize(frame, "debuffFrames", groupType)
    self:SetUpSubFramesPositionsAndSize(frame, "dispelDebuffFrames", groupType)

    if self.db.profile[groupType].raidIcon.enabled then
        self.SetUpRaidIcon(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.name.enabled then
        self:SetUpName(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.statusText.enabled then
        self:SetUpStatusText(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.roleIcon.enabled then
        self:SetUpRoleIcon(frame, groupType, nil)
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

    if self.db.profile[groupType].frames.colorEnabled then
        self:CompactUnitFrame_UpdateHealthColor(frame, groupType)
    end

    if self.IsFrameOk(frame) then
        self:CompactUnitFrame_UpdateHealPrediction(frame)
    end

    local backgroundAlpha, alpha

    backgroundAlpha = db.frames.alphaBackgound
    alpha = db.frames.alpha
    alpha = db.frames.alpha

    frame.background:SetAlpha(backgroundAlpha)
    frame.healthBar:SetAlpha(alpha)
    frame.healthBar.background:SetAlpha(backgroundAlpha)
    frame.powerBar:SetAlpha(alpha)
	
    frame.roleIcon:SetDrawLayer("OVERLAY")
    frame.totalAbsorbOverlay:SetDrawLayer("ARTWORK", 1)
	
    return deferred
end
--

-- HEALTHBAR COLOR
function KHMRaidFrames:CompactUnitFrame_UpdateHealthColor(frame, groupType)
    local db = self.db.profile[groupType].frames

    local br, bg, bb = db.backGroundColor[1], db.backGroundColor[2], db.backGroundColor[3]

    frame.healthBar.background:SetColorTexture(br, bg, bb)

    frame.background:Hide()

    self:CompactUnitFrame_UpdateHealthColorInternal(frame, groupType)
end

function KHMRaidFrames:CompactUnitFrame_UpdateHealthColorInternal(frame, groupType)
    local db = self.db.profile[groupType].frames

    if not db.colorEnabled then return end

    local r, g, b
    local name = frame:GetName()

    if not self.coloredFrames[name] then
        self.coloredFrames[name] = {
            health = {},
        }
    end

    local cache = self.coloredFrames[name]

    if not self.useClassColors then
        if frame.healthBar.r ~= cache.health.r or frame.healthBar.g ~= cache.health.g or frame.healthBar.b ~= cache.health.b then
            if frame.unit and not UnitIsConnected(frame.unit) then
                r, g, b = 0.5, 0.5, 0.5
            elseif CompactUnitFrame_IsTapDenied(frame) then
                r, g, b = 0.9, 0.9, 0.9
            else
                r, g, b = db.color[1], db.color[2], db.color[3]
            end

            frame.healthBar:SetStatusBarColor(r, g, b)

            self.coloredFrames[name].health = {
                r=frame.healthBar.r,
                g=frame.healthBar.g,
                b=frame.healthBar.b,
            }
        end
    end
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

    local name = frame.name

    if db.hide then
        name:Hide()
        return
    end

    local flags = db.flag ~= "None" and db.flag or ""
    local font = SharedMedia:Fetch("font", db.font) or SharedMedia:Fetch("font", self.font)
    local size = db.size * self.componentScale(groupType)

    name:SetJustifyH(db.hJustify)

    name:ClearAllPoints()

    local xOffset, yOffset = self:Offsets("TOPLEFT", frame, groupType)
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset

    name:SetFont(font, size, flags)
    name:SetPoint("TOPLEFT", frame, "TOPLEFT", xOffset, yOffset)
    name:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, yOffset)

    self.SetUpNameInternal(frame, groupType)
end

function KHMRaidFrames.SetUpNameInternal(frame, groupType)
    if not frame.name then return end

    local db = KHMRaidFrames.db.profile[groupType].nameAndIcons.name

    if not db.enabled then
        return
    end

    if not frame.unit then return end
    if not UnitExists(frame.displayedUnit) then return end
    if not ShouldShowName(frame) then return end

    local name = frame.name

    local _name

    if db.showServer then
        _name = GetUnitName(frame.unit, true)
    else
        _name = GetUnitName(frame.unit, false)
        _name = _name and _name:gsub("%p", "") or _name
    end

    if _name ~= nil and _name:len() > 0 and _name ~= "" then
        name:SetText(_name)
    end

    if db.classColoredNames then
        local classColor = KHMRaidFrames.ColorByClass(frame.unit)

        if classColor then
            name:SetTextColor(classColor.r, classColor.g, classColor.b)
        end
    else
        if KHMRaidFrames.CompactUnitFrame_IsTapDenied(frame) then
            name:SetVertexColor(0.5, 0.5, 0.5)
        else
            name:SetVertexColor(1.0, 1.0, 1.0)
        end
    end
end

-- STATUS TEXT
function KHMRaidFrames:SetUpStatusText(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.statusText.enabled then return end
    if not frame.statusText then return end
    if not frame.optionTable.displayStatusText then return end

    local db = self.db.profile[groupType].nameAndIcons.statusText

    local size = db.size * self.componentScale(groupType)
    local flags = db.flag ~= "None" and db.flag or ""
    local font = SharedMedia:Fetch("font", db.font) or SharedMedia:Fetch("font", self.font)

    -- i dont know why blizzard frames mess with fonts
    frame.KHMStatusText = frame.KHMStatusText or frame:CreateFontString(nil, "ARTWORK")

    local statusText = frame.KHMStatusText

    statusText:SetJustifyH(db.hJustify)

    statusText:ClearAllPoints()

    local xOffset, yOffset = self:Offsets("BOTTOMLEFT", frame, groupType, true)
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset + (((DefaultCompactUnitFrameSetupOptions['height'] or self.NATIVE_UNIT_FRAME_HEIGHT) / 3) - 2)

    statusText:SetFont(font, size, flags)
    statusText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", xOffset, yOffset)
    statusText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", xOffset, yOffset)
    statusText:SetShadowColor(0, 0, 0, 1)
    statusText:SetShadowOffset(1, -1)

    statusText:SetText("text")

    self.SetUpStatusTextInternal(frame, groupType)
end

function KHMRaidFrames.HideStatusText(frame)
    local text, percents, hide

    if not UnitIsConnected(frame.unit) then
        hide = false
        text = PLAYER_OFFLINE or "blizzard bug"
    elseif UnitHealth(frame.displayedUnit) == 0 or (frame.displayedUnit and UnitIsDeadOrGhost(frame.displayedUnit)) then
        hide = false
        text = DEAD or "blizzard bug"
    elseif frame.optionTable.healthText == "health" then
        hide = false
        text = UnitHealth(frame.displayedUnit)
    elseif frame.optionTable.healthText == "losthealth" then
        local losthealth = UnitHealthMax(frame.displayedUnit) - UnitHealth(frame.displayedUnit)

        if losthealth > 0 then
            hide = false
            text = losthealth
        else
            hide = true
        end
    elseif (frame.optionTable.healthText == "perc") and (UnitHealthMax(frame.displayedUnit) > 0) then
        percents = math.ceil(100 * (UnitHealth(frame.displayedUnit) / UnitHealthMax(frame.displayedUnit)))
        text = percents
        hide = false
    else
        hide = true
    end

    return hide, text, percents
end

function KHMRaidFrames.SetUpStatusTextInternal(frame, groupType)
    if not KHMRaidFrames.IsFrameOk(frame) then return end
    if not frame.unit then return end
    if not UnitExists(frame.displayedUnit) then return end
    if not frame.statusText then return end
    if not frame.optionTable.displayStatusText then return end
    if not frame.KHMStatusText then return end

    local db = KHMRaidFrames.db.profile[groupType].nameAndIcons.statusText

    if not db.enabled then return end

    local hide, text, percents = KHMRaidFrames.HideStatusText(frame)
    local statusText = frame.KHMStatusText

    if hide then
        statusText:Hide()
        return
    else
        frame.statusText:Hide()
        statusText:Show()
    end

    local health

    if (db.notShowStatuses or db.abbreviateNumbers or db.showPercents) and not (frame.optionTable.healthText == "none") then
        health = tonumber(text)

        if not health and db.notShowStatuses then
            health = 0
        end

        if health then
            if db.abbreviateNumbers then
                health = KHMRaidFrames.Abbreviate(health, groupType)
            end

            if db.showPercents and not (frame.optionTable.healthText == "perc") then
                percents = percents or math.ceil(100 * (UnitHealth(frame.displayedUnit) / UnitHealthMax(frame.displayedUnit)))
                percents = (percents ~= math.huge and percents ~= -math.huge and percents) or 0

                if frame.optionTable.healthText == "losthealth" then
                    percents = 100 - percents
                end

                health = health.." - "..percents.."%"
            end
        end

        if frame.optionTable.healthText == "losthealth" and health then
            health = "-"..health
        end
    end

    health = health or text

    if frame.optionTable.healthText == "losthealth" then
        health = "-"..health
    elseif frame.optionTable.healthText == "perc" then
        health = percents.."%"
    end

    statusText:SetText(health)

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

    --LAST RESORT
    local size = db.size * KHMRaidFrames.componentScale(groupType)
    local flags = db.flag ~= "None" and db.flag or ""
    local font = SharedMedia:Fetch("font", db.font) or SharedMedia:Fetch("font", KHMRaidFrames.font)

    statusText:SetFont(font, size, flags)
end

-- RAID TARGET ICON (STAR, SQUARE, etc)
function KHMRaidFrames:UpdateRaidMark()
    local groupType = IsInRaid() and "raid" or "party"

    for frame in self.IterateCompactFrames() do
        self:SetUpRaidIconInternal(frame, groupType)
    end
end

function KHMRaidFrames.SetUpRaidIcon(frame, groupType)
    local db = KHMRaidFrames.db.profile[groupType]

    if not frame.raidIcon then
        frame.raidIcon = frame:CreateTexture(nil, "OVERLAY")
    end

    local size = db.raidIcon.size * KHMRaidFrames.componentScale(groupType)

    frame.raidIcon:ClearAllPoints()

    frame.raidIcon:SetPoint(db.raidIcon.anchorPoint, frame, db.raidIcon.anchorPoint, db.raidIcon.xOffset, db.raidIcon.yOffset)
    frame.raidIcon:SetSize(size, size)
    frame.raidIcon:SetAlpha(db.raidIcon.alpha)

    KHMRaidFrames:SetUpRaidIconInternal(frame, groupType)
end

function KHMRaidFrames:SetUpRaidIconInternal(frame, groupType)
    if not frame.raidIcon then return end
    if not frame.unit then return end
    if not UnitExists(frame.displayedUnit) then return end

    local db = self.db.profile[groupType]

    if not db.raidIcon.enabled then return end

    local index = GetRaidTargetIndex(frame.unit)

    if index == "NONE" then
        index = 0
    else
        index = tonumber(index)
    end

    if index and index >= 1 and index <= 8 then
        local options = UnitPopupButtons["RAID_TARGET_"..index]
        local texture, tCoordLeft, tCoordRight, tCoordTop, tCoordBottom = options.icon, options.tCoordLeft, options.tCoordRight, options.tCoordTop, options.tCoordBottom

        frame.raidIcon:SetTexture(texture)
        frame.raidIcon:SetTexCoord(tCoordLeft, tCoordRight, tCoordTop, tCoordBottom)

        frame.raidIcon:Show()
    else
        frame.raidIcon:Hide()
    end
end

-- ROLE ICON
function KHMRaidFrames:SetUpRoleIcon(frame, groupType, role)
    if not self.db.profile[groupType].nameAndIcons.roleIcon.enabled then return end
    if not frame.roleIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.roleIcon
    local roleIcon = frame.roleIcon
    local size = db.size

    roleIcon:ClearAllPoints()

    local xOffset, yOffset = self:Offsets("TOPLEFT", frame, groupType)
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

    self:SetUpRoleIconInternal(frame, groupType, role)
end

function KHMRaidFrames:SetUpRoleIconInternal(frame, groupType, role)
    if not self.db.profile[groupType].nameAndIcons.roleIcon.enabled then return end
    if not frame.unit then return end
    if not frame.roleIcon then return end
    if not UnitExists(frame.displayedUnit) then return end

    local db = self.db.profile[groupType].nameAndIcons.roleIcon
    local roleIcon = frame.roleIcon

    if db.hide or not roleIcon:IsVisible() then
        roleIcon:Hide()
        return
    end

    role = role or self.GetRole(frame)

    role = role:lower()

    if db[role] ~= "" and db[role] ~= nil then
        roleIcon:SetTexture(db[role])
        roleIcon:SetTexCoord(0, 1, 0, 1)
        roleIcon:SetVertexColor(unpack(db.colors[role]))
    else
        roleIcon:SetVertexColor(1, 1, 1)
    end

    roleIcon:Show()
end

-- READY CHECK ICON
function KHMRaidFrames:SetUpReadyCheckIcon(frame, groupType)
    if not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled then return end
    if not frame.readyCheckIcon then return end

    local db = self.db.profile[groupType].nameAndIcons.readyCheckIcon
    local readyCheckIcon = frame.readyCheckIcon
    local size = db.size * self.componentScale(groupType)

    readyCheckIcon:ClearAllPoints()

    local xOffset, yOffset = self:Offsets("BOTTOM", frame, groupType)
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset + (((DefaultCompactUnitFrameSetupOptions['height'] or KHMRaidFrames.NATIVE_UNIT_FRAME_HEIGHT) / 3) - 4)

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
    if not UnitExists(frame.displayedUnit) then return end

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
    local size = db.size * self.componentScale(groupType)

    centerStatusIcon:ClearAllPoints()

    local xOffset, yOffset = self:Offsets("BOTTOM", frame, groupType)
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset + (((DefaultCompactUnitFrameSetupOptions['height'] or KHMRaidFrames.NATIVE_UNIT_FRAME_HEIGHT) / 3) - 4)

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
    if not UnitExists(frame.displayedUnit) then return end

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
        KHMRaidFrames.SetUpLeaderIconInternal(frame, groupType)
    end
end

function KHMRaidFrames.SetUpLeaderIcon(frame, groupType)
    if not frame.leaderIcon then
        frame.leaderIcon = frame:CreateTexture(nil, "OVERLAY")
    end

    local db = KHMRaidFrames.db.profile[groupType].nameAndIcons.leaderIcon
    local size = db.size * KHMRaidFrames.componentScale(groupType)

    frame.leaderIcon:ClearAllPoints()

    local xOffset, yOffset = KHMRaidFrames:Offsets(db.anchorPoint, frame, groupType)
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

    KHMRaidFrames.SetUpLeaderIconInternal(frame, groupType)
end

function KHMRaidFrames.SetUpLeaderIconInternal(frame, groupType)
    if not frame.leaderIcon then return end
    if not KHMRaidFrames.db.profile[groupType].nameAndIcons.leaderIcon.enabled then return end
    if not frame or not frame.unit then return end
    if not UnitExists(frame.displayedUnit) then return end

    local isLeader = UnitIsGroupLeader(frame.unit)

    if not isLeader then
        frame.leaderIcon:Hide()
    else
        frame.leaderIcon:Show()
    end
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

--RESOURСE BAR
function KHMRaidFrames.UpdateResourceBar(frame, groupType, role, refresh)
    if not frame.unit then return end
    if not frame.powerBar then return end
    if not UnitExists(frame.displayedUnit) then return end
    if string.find(frame.unit, "pet") then return end

    if not KHMRaidFrames.db.profile[groupType].frames.showResourceOnlyForHealers or not KHMRaidFrames.displayPowerBar then
        return
    end

    role = role or KHMRaidFrames.GetRole(frame)

    if role == "HEALER" then
        frame.powerBar:Show()
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, KHMRaidFrames.db.profile[groupType].frames.powerBarHeight + 1)

        if KHMRaidFrames.displayBorder then
            frame.horizDivider:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1 + KHMRaidFrames.db.profile[groupType].frames.powerBarHeight)
            frame.horizDivider:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 1 + KHMRaidFrames.db.profile[groupType].frames.powerBarHeight)
            frame.horizDivider:Show()
        else
            frame.horizDivider:Hide()
        end
    else
        frame.powerBar:Hide()
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

        if KHMRaidFrames.displayBorder then
            frame.horizDivider:Hide()
        end
    end

    if not refresh then
        KHMRaidFrames:SetUpMainSubFramePosition(frame, "buffFrames", groupType)

        if KHMRaidFrames.db.profile[groupType].debuffFrames.smartAnchoring and KHMRaidFrames.db.profile[groupType].debuffFrames.showBigDebuffs then
            KHMRaidFrames:SmartAnchoring(frame, groupType)
        else
            KHMRaidFrames:SetUpMainSubFramePosition(frame, "debuffFrames", groupType)
        end

        KHMRaidFrames:SetUpMainSubFramePosition(frame, "dispelDebuffFrames", groupType)
    end
end

function KHMRaidFrames.RevertResourceBar()
    local groupType = IsInRaid() and "raid" or "party"

    if not KHMRaidFrames.db.profile[groupType].frames.showResourceOnlyForHealers or not KHMRaidFrames.displayPowerBar then
        for frame in KHMRaidFrames.IterateCompactFrames() do
            KHMRaidFrames.RevertResourceBarInternal(frame)
        end
    else
        for frame in KHMRaidFrames.IterateCompactFrames() do
            if frame.unit and UnitExists(frame.displayedUnit) then
                local role = KHMRaidFrames.GetRole(frame)

                KHMRaidFrames.UpdateResourceBar(frame, groupType, role, true)
            end
        end
    end

    for frame in KHMRaidFrames.IterateCompactFrames() do
        KHMRaidFrames:SetUpMainSubFramePosition(frame, "buffFrames", groupType)

        if KHMRaidFrames.db.profile[groupType].debuffFrames.smartAnchoring and KHMRaidFrames.db.profile[groupType].debuffFrames.showBigDebuffs then
            KHMRaidFrames:SmartAnchoring(frame, groupType)
        else
            KHMRaidFrames:SetUpMainSubFramePosition(frame, "debuffFrames", groupType)
        end

        KHMRaidFrames:SetUpMainSubFramePosition(frame, "dispelDebuffFrames", groupType)
    end
end

function KHMRaidFrames.RevertResourceBarInternal(frame)
    local groupType = IsInRaid() and "raid" or "party"
    local powerBarHeight = KHMRaidFrames.db.profile[groupType].frames.powerBarHeight

    if frame.unit and string.find(frame.unit, "pet") then return end

    if KHMRaidFrames.displayPowerBar and frame.unit and UnitExists(frame.displayedUnit) then
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, powerBarHeight + 1)
        frame.powerBar:Show()

        if KHMRaidFrames.displayBorder then
            frame.horizDivider:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1 + KHMRaidFrames.db.profile[groupType].frames.powerBarHeight)
            frame.horizDivider:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 1 + KHMRaidFrames.db.profile[groupType].frames.powerBarHeight)
            frame.horizDivider:Show()
        else
            frame.horizDivider:Hide()
        end
    else
        frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
        frame.powerBar:Hide()

        if KHMRaidFrames.displayBorder then
            frame.horizDivider:Hide()
        end
    end
end
--
