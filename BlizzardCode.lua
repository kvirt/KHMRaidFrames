local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")

local SharedMedia = LibStub("LibSharedMedia-3.0")

local UnitIsTapDenied = UnitIsTapDenied
local UnitPlayerControlled = UnitPlayerControlled
local UnitInRaid = UnitInRaid
local UnitHasVehicleUI = UnitHasVehicleUI
local UnitInVehicle = UnitInVehicle
local GetRaidRosterInfo = GetRaidRosterInfo
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local GetTexCoordsForRoleSmallCircle = GetTexCoordsForRoleSmallCircle
local GetReadyCheckTimeLeft = GetReadyCheckTimeLeft
local GetReadyCheckStatus = GetReadyCheckStatus
local READY_CHECK_WAITING_TEXTURE, READY_CHECK_NOT_READY_TEXTURE, READY_CHECK_NOT_READY_TEXTURE = READY_CHECK_WAITING_TEXTURE, READY_CHECK_NOT_READY_TEXTURE, READY_CHECK_NOT_READY_TEXTURE
local UnitPhaseReason = UnitPhaseReason
local Enum = Enum
local C_IncomingSummon = C_IncomingSummon
local UnitHasIncomingResurrection = UnitHasIncomingResurrection
local UnitInOtherParty = UnitInOtherParty
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax


function KHMRaidFrames:CompactUnitFrame_UtilSetDebuff(debuffFrame, unit, index, filter, isBossAura, isBossBuff, aura)
    debuffFrame.debuffFramesGlowing = nil
    
    -- make sure you are using the correct index here!
    --isBossAura says make this look large.
    --isBossBuff looks in HELPFULL auras otherwise it looks in HARMFULL ones
    
    debuffFrame.filter = filter
    debuffFrame.icon:SetTexture(aura.icon)
    if ( aura.applications > 1 ) then
        local countText = aura.applications
        if ( aura.applications >= 100 ) then
            countText = BUFF_STACKS_OVERFLOW
        end
        debuffFrame.count:Show()
        debuffFrame.count:SetText(countText)
    else
        debuffFrame.count:Hide()
    end
    debuffFrame:SetID(index)
    debuffFrame.auraInstanceID = aura.auraInstanceID;
    local enabled = aura.expirationTime and aura.expirationTime ~= 0
    if enabled then
        local startTime = aura.expirationTime - aura.duration
        CooldownFrame_Set(debuffFrame.cooldown, startTime, aura.duration, true)
    else
        CooldownFrame_Clear(debuffFrame.cooldown)
    end
    
    local color = DebuffTypeColor[aura.dispelName] or DebuffTypeColor["none"]
    debuffFrame.border:SetVertexColor(color.r, color.g, color.b)
    
    debuffFrame.isBossBuff = isBossBuff
    debuffFrame.isBossAura = isBossAura
    
    local size
    
    if IsInRaid() then
        size = self.db.profile.raid.debuffFrames
    else
        size = self.db.profile.party.debuffFrames
    end
    
    if isBossAura then
        size = size.bigDebuffSize
    else
        size = size.size
    end
    
    local parent = debuffFrame:GetParent()
    
    size = size * self.componentScale(IsInRaid() and "raid" or "party")
    
    debuffFrame:SetSize(size, size)
    
    debuffFrame:Show()
    
    name = aura.name and aura.name:lower()
    debuffType = aura.dispelName and aura.dispelName:lower() or "physical"
    spellId = tostring(aura.spellId)
    
    local db = self.db.profile.glows
    
    if db.auraGlow.debuffFrames.enabled then
        if self:TrackAuras(name, debuffType, spellId, db.auraGlow.debuffFrames.tracking) then
            local color = db.auraGlow.debuffFrames.useDefaultsColors and db.auraGlow.defaultColors[debuffType]
            self.StartGlow(debuffFrame, db.auraGlow.debuffFrames, color, "debuffFrames", "auraGlow")
            debuffFrame.debuffFramesGlowing = debuffType
        end
    end
    
    if not debuffFrame.debuffFramesGlowing then
        self.StopGlow(debuffFrame, db.auraGlow.debuffFrames, "debuffFrames", "auraGlow")
    end
    
    parent.debuffFramesGlowing[debuffType] = {name, debuffType, spellId}
    parent.debuffFramesGlowing[name] = {name, debuffType, spellId}
    parent.debuffFramesGlowing[spellId] = {name, debuffType, spellId}
    
    if self.Masque then
        debuffFrame.border:Hide()
    end
end

function KHMRaidFrames:CompactUnitFrame_UtilSetBuff(buffFrame, index, aura)
    buffFrame.buffFramesGlowing = nil
    
    buffFrame.icon:SetTexture(aura.icon)
    if ( aura.applications > 1 ) then
        local countText = aura.applications;
        if ( aura.applications >= 100 ) then
            countText = BUFF_STACKS_OVERFLOW
        end
        buffFrame.count:Show()
        buffFrame.count:SetText(countText)
    else
        buffFrame.count:Hide()
    end
    buffFrame:SetID(index)
    buffFrame.auraInstanceID = aura.auraInstanceID;
    local enabled = aura.expirationTime and aura.expirationTime ~= 0
    if enabled then
        local startTime = aura.expirationTime - aura.duration
        CooldownFrame_Set(buffFrame.cooldown, startTime, aura.duration, true)
    else
        CooldownFrame_Clear(buffFrame.cooldown)
    end
    
    local size;
    if IsInRaid() then
        size = self.db.profile.raid.buffFrames.size
    else
        size = self.db.profile.party.buffFrames.size
    end
    
    size = size * self.componentScale(IsInRaid() and "raid" or "party")
    
    buffFrame:SetSize(size, size)
    
    buffFrame:Show()
    
    name = aura.name and aura.name:lower()
    debuffType = aura.dispelName and aura.dispelName:lower() or "physical"
    spellId = tostring(aura.spellId)
    
    local db = self.db.profile.glows
    
    if db.auraGlow.buffFrames.enabled then
        if self:TrackAuras(name, debuffType, spellId, db.auraGlow.buffFrames.tracking) then
            local color = db.auraGlow.buffFrames.useDefaultsColors and db.auraGlow.defaultColors[debuffType]
            self.StartGlow(buffFrame, db.auraGlow.buffFrames, color, "buffFrames", "auraGlow")
            buffFrame.buffFramesGlowing = debuffType
        end
    end
    
    if not buffFrame.buffFramesGlowing then
        self.StopGlow(buffFrame, db.auraGlow.buffFrames, "buffFrames", "auraGlow")
    end
    
    local parent = buffFrame:GetParent()
    
    parent.buffFramesGlowing[debuffType] = {name, debuffType, spellId}
    parent.buffFramesGlowing[name] = {name, debuffType, spellId}
    parent.buffFramesGlowing[spellId] = {name, debuffType, spellId}
end

local function CompactUnitFrame_Util_IsBossAura(aura)
    return aura.isBossAura
end

function KHMRaidFrames:CompactUnitFrame_Util_ShouldDisplayDebuff(aura)
    
    if not self:FilterAuras(aura.name, aura.dispelName, aura.spellId, "debuffFrames") then
        return false
    end
    
    if self:AdditionalAura(aura.name, aura.dispelName, aura.spellId, aura.unitCaster) then
        return true
    end
    
    local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(aura.spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT")
    if ( hasCustom ) then
        return showForMySpec or (alwaysShowMine and (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle") )   --Would only be "mine" in the case of something like forbearance.
    else
        return true
    end
end

function KHMRaidFrames:CompactUnitFrame_UtilShouldDisplayBuff(aura)
    
    if not self:FilterAuras(aura.name, aura.dispelName, aura.spellId, "buffFrames") then
        return false
    end
    
    if self:AdditionalAura(aura.name, aura.dispelName, aura.spellId, aura.sourceUnit) then
        return true
    end
    
    local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(aura.spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT")
    
    if ( hasCustom ) then
        return showForMySpec or (alwaysShowMine and (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle"))
    else
        return (aura.sourceUnit == "player" or aura.sourceUnit == "pet" or aura.sourceUnit == "vehicle") and aura.canApplyAura and not SpellIsSelfBuff(aura.spellId)
    end
end

function KHMRaidFrames:CompactUnitFrame_HideAllBuffs(frame, startingIndex, db)
    if frame.buffFrames then
        for i=startingIndex or 1, #frame.buffFrames do
            frame.buffFrames[i]:Hide()
            self.StopGlow(frame.buffFrames[i], db.buffFrames, "buffFrames", "auraGlow")
        end
    end
end

function KHMRaidFrames:CompactUnitFrame_HideAllDebuffs(frame, startingIndex, db)
    if frame.debuffFrames then
        for i=startingIndex or 1, #frame.debuffFrames do
            frame.debuffFrames[i]:Hide()
            self.StopGlow(frame.debuffFrames[i], db.debuffFrames, "debuffFrames", "auraGlow")
        end
    end
end

function KHMRaidFrames:SetDebuffsHelper(debuffFrames, frameNum, maxDebuffs, filter, isBossAura, isBossBuff, auras)
    if auras then
        for i = 1,#auras do
            local index = auras[i][1]
            local aura = auras[i][2]
            if frameNum > maxDebuffs then
                break
            end
            local debuffFrame = debuffFrames[frameNum]
            
            if self:FilterAuras(aura.name, aura.dispelName, aura.spellId, "debuffFrames") then
                local unit = nil
                self:CompactUnitFrame_UtilSetDebuff(debuffFrame, unit, index, "HARMFUL", isBossAura, isBossBuff, aura)
                frameNum = frameNum + 1
                
                if not self.db.profile[IsInRaid() and "raid" or "party"].debuffFrames.smartAnchoring then
                    if isBossAura then
                        --Boss auras are about twice as big as normal debuffs, so we may need to display fewer buffs
                        local bossDebuffScale = (debuffFrame.baseSize + BOSS_DEBUFF_SIZE_INCREASE)/debuffFrame.baseSize
                        maxDebuffs = maxDebuffs - (bossDebuffScale - 1)
                    end
                end
            end
        end
    end
    return frameNum, maxDebuffs
end

local function NumElements(arr)
    return arr and #arr or 0
end

local dispellableDebuffTypes = { Magic = true, Curse = true, Disease = true, Poison = true}

function KHMRaidFrames:CompactUnitFrame_UpdateAuras(frame)
    if self.SkipFrame(frame) then return end
    
    frame.buffFramesGlowing = {}
    frame.debuffFramesGlowing = {}
    
    local db = self:GroupTypeDB()
    
    local maxBuffs = min(db.buffFrames.num, #frame.buffFrames) or 3
    local maxDebuffs = min(db.debuffFrames.num, #frame.debuffFrames) or 3
    local maxDispelDebuffs = min(db.dispelDebuffFrames.num, #frame.dispelDebuffFrames) or 3
    
    local doneWithBuffs = not frame.buffFrames or not frame.optionTable.displayBuffs or maxBuffs == 0
    local doneWithDebuffs = not frame.debuffFrames or not frame.optionTable.displayDebuffs or maxDebuffs == 0
    local doneWithDispelDebuffs = not frame.dispelDebuffFrames or not frame.optionTable.displayDispelDebuffs or maxDispelDebuffs == 0
    
    local numUsedBuffs = 0
    local numUsedDebuffs = 0
    local numUsedDispelDebuffs = 0
    
    local displayOnlyDispellableDebuffs = frame.optionTable.displayOnlyDispellableDebuffs
    
    -- The following is the priority order for debuffs
    local bossDebuffs, bossBuffs, priorityDebuffs, nonBossDebuffs
    local index = 1
    local batchCount = maxDebuffs
    
    if not doneWithDebuffs then
        AuraUtil.ForEachAura(frame.displayedUnit, "HARMFUL", batchCount, function(...)
                local aura = ...
                
                if db.debuffFrames.showBigDebuffs and CompactUnitFrame_Util_IsBossAura(aura) then
                    if not bossDebuffs then
                        bossDebuffs = {}
                    end
                    tinsert(bossDebuffs, {index, aura})
                    numUsedDebuffs = numUsedDebuffs + 1
                    if numUsedDebuffs == maxDebuffs then
                        doneWithDebuffs = true
                        return true
                    end
                elseif db.frames.showBigDebuffs and CompactUnitFrame_Util_IsPriorityDebuff(aura.spellId) then
                    if not priorityDebuffs then
                        priorityDebuffs = {}
                    end
                    tinsert(priorityDebuffs, {index, aura})
                elseif not displayOnlyDispellableDebuffs and self:CompactUnitFrame_Util_ShouldDisplayDebuff(aura) then
                    if not nonBossDebuffs then
                        nonBossDebuffs = {}
                    end
                    tinsert(nonBossDebuffs, {index, aura})
                end
                
                index = index + 1
                return false
        end, true)
    end
    
    if not doneWithBuffs or not doneWithDebuffs then
        index = 1
        batchCount = math.max(maxBuffs, maxDebuffs)
        AuraUtil.ForEachAura(frame.displayedUnit, AuraUtil.CreateFilterString(AuraUtil.AuraFilters.Helpful), batchCount, function(...)
                local aura = ...
                
                if db.debuffFrames.showBigDebuffs and CompactUnitFrame_Util_IsBossAura(aura) then
                    -- Boss Auras are considered Debuffs for our purposes.
                    if not doneWithDebuffs then
                        if not bossBuffs then
                            bossBuffs = {}
                        end
                        tinsert(bossBuffs, {index, aura})
                        numUsedDebuffs = numUsedDebuffs + 1
                        if numUsedDebuffs == maxDebuffs then
                            doneWithDebuffs = true
                        end
                    end
                elseif self:CompactUnitFrame_UtilShouldDisplayBuff(aura) then
                    if not doneWithBuffs then
                        numUsedBuffs = numUsedBuffs + 1
                        local buffFrame = frame.buffFrames[numUsedBuffs]
                        self:CompactUnitFrame_UtilSetBuff(buffFrame, index, aura)
                        if numUsedBuffs == maxBuffs then
                            doneWithBuffs = true
                        end
                    end
                end
                index = index + 1
                return doneWithBuffs and doneWithDebuffs
        end, true)
    end
    
    numUsedDebuffs = math.min(maxDebuffs, numUsedDebuffs + NumElements(priorityDebuffs))
    if numUsedDebuffs == maxDebuffs then
        doneWithDebuffs = true
    end
    
    if not doneWithDispelDebuffs then
        --Clear what we currently have for dispellable debuffs
        for debuffType, display in pairs(dispellableDebuffTypes) do
            if ( display ) then
                frame["hasDispel"..debuffType] = false
            end
        end
    end
    
    if not doneWithDispelDebuffs or not doneWithDebuffs then
        batchCount = math.max(maxDebuffs, maxDispelDebuffs)
        index = 1
        AuraUtil.ForEachAura(frame.displayedUnit, "HARMFUL|RAID", batchCount, function(...)
                local aura = ...
                
                if not doneWithDebuffs and displayOnlyDispellableDebuffs then
                    if self:CompactUnitFrame_Util_ShouldDisplayDebuff(aura) and not CompactUnitFrame_Util_IsBossAura(aura) and not CompactUnitFrame_Util_IsPriorityDebuff(aura.spellId) then
                        if not nonBossDebuffs then
                            nonBossDebuffs = {}
                        end
                        tinsert(nonBossDebuffs, {index, aura})
                        numUsedDebuffs = numUsedDebuffs + 1
                        if numUsedDebuffs == maxDebuffs then
                            doneWithDebuffs = true
                        end
                    end
                end
                if not doneWithDispelDebuffs then
                    local debuffType = aura.dispelName
                    if (dispellableDebuffTypes[debuffType] and not frame["hasDispel"..debuffType] ) then
                        frame["hasDispel"..debuffType] = true
                        numUsedDispelDebuffs = numUsedDispelDebuffs + 1
                        local dispellDebuffFrame = frame.dispelDebuffFrames[numUsedDispelDebuffs]
                        CompactUnitFrame_UtilSetDispelDebuff(dispellDebuffFrame, {dispelName=debuffType, auraInstanceID=aura.auraInstanceID})
                        if numUsedDispelDebuffs == maxDispelDebuffs then
                            doneWithDispelDebuffs = true
                        end
                    end
                end
                index = index + 1
                return (doneWithDebuffs or not displayOnlyDispellableDebuffs) and doneWithDispelDebuffs
        end, true)
    end
    
    local frameNum = 1
    local maxDebuffs = maxDebuffs
    
    do
        local isBossAura = true
        local isBossBuff = false
        frameNum, maxDebuffs = self:SetDebuffsHelper(frame.debuffFrames, frameNum, maxDebuffs, "HARMFUL", isBossAura, isBossBuff, bossDebuffs)
    end
    do
        local isBossAura = true
        local isBossBuff = true
        frameNum, maxDebuffs = self:SetDebuffsHelper(frame.debuffFrames, frameNum, maxDebuffs, "HELPFUL", isBossAura, isBossBuff, bossBuffs)
    end
    do
        local isBossAura = false
        local isBossBuff = false
        frameNum, maxDebuffs = self:SetDebuffsHelper(frame.debuffFrames, frameNum, maxDebuffs, "HARMFUL", isBossAura, isBossBuff, priorityDebuffs)
    end
    do
        local isBossAura = false
        local isBossBuff = false
        frameNum, maxDebuffs = self:SetDebuffsHelper(frame.debuffFrames, frameNum, maxDebuffs, "HARMFUL|RAID", isBossAura, isBossBuff, nonBossDebuffs)
    end
    numUsedDebuffs = frameNum - 1
    
    self:CompactUnitFrame_HideAllBuffs(frame, numUsedBuffs + 1,  self.db.profile.glows.auraGlow)
    self:CompactUnitFrame_HideAllDebuffs(frame, numUsedDebuffs + 1, self.db.profile.glows.auraGlow)
    CompactUnitFrame_HideAllDispelDebuffs(frame, numUsedDispelDebuffs + 1)
    
    local groupType = IsInRaid() and "raid" or "party"
    
    if self.db.profile[groupType].debuffFrames.showBigDebuffs then
        if self.db.profile[groupType].debuffFrames.smartAnchoring then
            self:SmartAnchoring(frame, IsInRaid() and "raid" or "party")
        end
        
        if self.db.profile.Masque then
            for _, _frame in pairs(frame.debuffFrames) do
                if _frame:IsShown() then
                    self.Masque.debuffFrames:ReSkin(_frame)
                end
            end
        end
    end
    
    local db = self.db.profile.glows.frameGlow
    
    if db.buffFrames.enabled then
        for aura, auras in pairs(frame.buffFramesGlowing) do
            local name, debuffType, spellId = auras[1], auras[2], auras[3]
            
            if self:TrackAuras(name, debuffType, spellId, self.db.profile.glows.frameGlow.buffFrames.tracking) then
                local color = db.buffFrames.useDefaultsColors and db.defaultColors[debuffType]
                self.StartGlow(frame, db.buffFrames, color, "buffFrames", "frameGlow")
                self.StopGlow(frame, db.debuffFrames, "debuffFrames", "frameGlow")
                return
            end
        end
    end
    
    if db.debuffFrames.enabled then
        for aura, auras in pairs(frame.debuffFramesGlowing) do
            local name, debuffType, spellId = auras[1], auras[2], auras[3]
            
            if self:TrackAuras(name, debuffType, spellId, self.db.profile.glows.frameGlow.debuffFrames.tracking) then
                local color = db.debuffFrames.useDefaultsColors and db.defaultColors[debuffType]
                self.StartGlow(frame, db.debuffFrames, color, "debuffFrames", "frameGlow")
                self.StopGlow(frame, db.buffFrames, "buffFrames", "frameGlow")
                return
            end
        end
    end
    
    self.StopGlow(frame, db.debuffFrames, "debuffFrames", "frameGlow")
    self.StopGlow(frame, db.buffFrames, "buffFrames", "frameGlow")
end

function KHMRaidFrames.CompactUnitFrame_IsTapDenied(frame)
    return frame.optionTable.greyOutWhenTapDenied and not UnitPlayerControlled(frame.unit) and UnitIsTapDenied(frame.unit)
end

function KHMRaidFrames.CompactUnitFrame_UpdateRoleIcon(frame)
    if not frame.roleIcon or not frame.unit then
        return
    end
    
    frame.roleIcon:ClearAllPoints()
    frame.roleIcon:SetPoint("TOPLEFT", 3, -2)
    frame.roleIcon:SetSize(12, 12)
    
    if IsInGroup() then
        frame.roleIcon:Show()
    end
    
    KHMRaidFrames.CompactUnitFrame_UpdateRoleIconTexture(frame)
end

function KHMRaidFrames.CompactUnitFrame_UpdateRoleIconTexture(frame)
    CompactUnitFrame_UpdateRoleIcon(frame)
    
    frame.roleIcon:SetVertexColor(1, 1, 1, 1)
end

function KHMRaidFrames.RevertRoleIcon()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        
        if frame.unit then
            KHMRaidFrames.CompactUnitFrame_UpdateRoleIcon(frame)
        end
    end
end

function KHMRaidFrames.RevertRoleIconTexture()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.unit then
            KHMRaidFrames.CompactUnitFrame_UpdateRoleIconTexture(frame)
        end
    end
end

function KHMRaidFrames.CompactUnitFrame_UpdateReadyCheck(frame)
    if not frame.readyCheckIcon or frame.readyCheckDecay and GetReadyCheckTimeLeft() <= 0 or not frame.unit then
        return
    end
    
    local readyCheckSize = 15 * KHMRaidFrames.componentScale(IsInRaid() and "raid" or "party")
    frame.readyCheckIcon:ClearAllPoints();
    frame.readyCheckIcon:SetPoint("BOTTOM", frame, "BOTTOM", 0, frame:GetHeight() / 3 - 4)
    frame.readyCheckIcon:SetSize(readyCheckSize, readyCheckSize)
    
    KHMRaidFrames.CompactUnitFrame_UpdateReadyCheckTexture(frame)
end

function KHMRaidFrames.CompactUnitFrame_UpdateReadyCheckTexture(frame)
    CompactUnitFrame_UpdateReadyCheck(frame)
    
    frame.readyCheckIcon:SetVertexColor(1, 1, 1, 1)
end

function KHMRaidFrames.RevertReadyCheckIcon()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.unit then
            KHMRaidFrames.CompactUnitFrame_UpdateReadyCheck(frame)
        end
    end
end

function KHMRaidFrames.RevertReadyCheckIconTexture()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.unit then
            KHMRaidFrames.CompactUnitFrame_UpdateReadyCheckTexture(frame)
        end
    end
end

function KHMRaidFrames.CompactUnitFrame_UpdateCenterStatusIcon(frame)
    if not frame.unit or not frame.centerStatusIcon then return end
    
    local size = 11 * KHMRaidFrames.componentScale(IsInRaid() and "raid" or "party") * 2
    frame.centerStatusIcon:ClearAllPoints()
    frame.centerStatusIcon:SetPoint("CENTER", frame, "BOTTOM", 0, frame:GetHeight() / 3 + 2)
    frame.centerStatusIcon:SetSize(size, size)
    
    KHMRaidFrames.CompactUnitFrame_UpdateCenterStatusIconTexture(frame)
end

function KHMRaidFrames.CompactUnitFrame_UpdateCenterStatusIconTexture(frame)
    CompactUnitFrame_UpdateCenterStatusIcon(frame)
    
    frame.centerStatusIcon.texture:SetVertexColor(1, 1, 1, 1)
end

function KHMRaidFrames.RevertStatusIcon()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.unit then
            KHMRaidFrames.CompactUnitFrame_UpdateCenterStatusIcon(frame)
        end
    end
end

function KHMRaidFrames.RevertStatusIconTexture()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.unit then
            KHMRaidFrames.CompactUnitFrame_UpdateCenterStatusIconTexture(frame)
        end
    end
end

function KHMRaidFrames.RevertStatusText()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.KHMStatusText then
            frame.KHMStatusText:Hide()
        end
        local hide, text, percents = KHMRaidFrames.HideStatusText(frame)
        frame.statusText:SetShown(not hide)
    end
end

function KHMRaidFrames.CompactUnitFrame_UpdateName(frame)
    frame.name:SetFont(SharedMedia:Fetch("font", KHMRaidFrames.font), 11)
    
    frame.name:ClearAllPoints()
    
    if KHMRaidFrames.db.profile[IsInRaid() and "raid" or "party"].nameAndIcons.roleIcon.enabled then
        frame.name:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -1)
    else
        frame.name:SetPoint("TOPLEFT", frame.roleIcon, "TOPRIGHT", 0, -1)
    end
    
    frame.name:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    frame.name:SetJustifyH("LEFT")
    frame.name:SetVertexColor(1.0, 1.0, 1.0)
    
    CompactUnitFrame_UpdateName(frame)
end

function KHMRaidFrames.RevertName()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.unit then
            KHMRaidFrames.CompactUnitFrame_UpdateName(frame)
        end
    end
end

function KHMRaidFrames.RevertNameColors()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if KHMRaidFrames.CompactUnitFrame_IsTapDenied(frame) then
            frame.name:SetVertexColor(0.5, 0.5, 0.5)
        else
            frame.name:SetVertexColor(1.0, 1.0, 1.0)
        end
    end
end

function KHMRaidFrames.ReverseHealthBarColors()
    local br, bg, bb = unpack(KHMRaidFrames:Defaults().profile.party.frames.backGroundColor)
    
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.healthBar.r ~= nil then
            frame.healthBar:SetStatusBarColor(frame.healthBar.r, frame.healthBar.g, frame.healthBar.b)
            frame.healthBar.background:SetColorTexture(br, bg, bb)
            frame.background:Show()
        end
    end
end


function KHMRaidFrames.RevertRaidTargetIcon()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.raidIcon then
            frame.raidIcon:Hide()
        end
    end
end


function KHMRaidFrames.RevertLeaderIcon()
    for frame in KHMRaidFrames.IterateCompactFrames() do
        if frame.leaderIcon then
            frame.leaderIcon:Hide()
        end
    end
end
