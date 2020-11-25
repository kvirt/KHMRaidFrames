local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")


function KHMRaidFrames:CompactUnitFrame_UtilSetDebuff(debuffFrame, unit, index, filter, isBossAura, isBossBuff, ...)
    debuffFrame.debuffFramesGlowing = nil  

    -- make sure you are using the correct index here!
    --isBossAura says make this look large.
    --isBossBuff looks in HELPFULL auras otherwise it looks in HARMFULL ones
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = ...
    if name == nil then
        -- for backwards compatibility - this functionality will be removed in a future update
        if unit then
            if (isBossBuff) then
                name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitBuff(unit, index, filter)
            else
                name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(unit, index, filter)
            end
        else
            return
        end
    end
    debuffFrame.filter = filter
    debuffFrame.icon:SetTexture(icon)
    if ( count > 1 ) then
        local countText = count
        if ( count >= 100 ) then
            countText = BUFF_STACKS_OVERFLOW
        end
        debuffFrame.count:Show()
        debuffFrame.count:SetText(countText)
    else
        debuffFrame.count:Hide()
    end
    debuffFrame:SetID(index)
    local enabled = expirationTime and expirationTime ~= 0
    if enabled then
        local startTime = expirationTime - duration
        CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true)
    else
        CooldownFrame_Clear(debuffFrame.cooldown)
    end

    local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
    debuffFrame.border:SetVertexColor(color.r, color.g, color.b)

    debuffFrame.isBossBuff = isBossBuff

    local size

    if IsInRaid() then
        size = self.db.profile.raid.debuffFrames.size
    else
        size = self.db.profile.party.debuffFrames.size
    end

    if isBossAura then
        size = size + BOSS_DEBUFF_SIZE_INCREASE
    end

    size = size * self.componentScale
    
    debuffFrame:SetSize(size, size)

    debuffFrame:Show()

    name = name and name:lower()
    debuffType = debuffType and debuffType:lower() or "physical"
    spellId = tostring(spellId)

    local db = self.db.profile.glows

    if db.auraGlow.debuffFrames.enabled then
        if self:TrackAuras(name, debuffType, spellId, db.auraGlow.debuffFrames.tracking) then
            local color = db.auraGlow.debuffFrames.useDefaultsColors and db.auraGlow.defaultColors[debuffType]                
            self:StartGlow(debuffFrame, db.auraGlow.debuffFrames, color, "debuffFrames", "auraGlow")
            debuffFrame.debuffFramesGlowing = debuffType
        end     
    end       

    if not debuffFrame.debuffFramesGlowing then
        self:StopGlow(debuffFrame, db.auraGlow.debuffFrames, "debuffFrames", "auraGlow")
    end

    local parent = debuffFrame:GetParent()

    parent.debuffFramesGlowing[debuffType] = {name, debuffType, spellId}
    parent.debuffFramesGlowing[name] = {name, debuffType, spellId}
    parent.debuffFramesGlowing[spellId] = {name, debuffType, spellId}
end

function KHMRaidFrames:CompactUnitFrame_UtilSetBuff(buffFrame, index, ...)
    buffFrame.buffFramesGlowing = nil

    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = ...
    buffFrame.icon:SetTexture(icon)
    if ( count > 1 ) then
        local countText = count
        if ( count >= 100 ) then
            countText = BUFF_STACKS_OVERFLOW
        end
        buffFrame.count:Show()
        buffFrame.count:SetText(countText)
    else
        buffFrame.count:Hide()
    end
    buffFrame:SetID(index)
    local enabled = expirationTime and expirationTime ~= 0
    if enabled then
        local startTime = expirationTime - duration
        CooldownFrame_Set(buffFrame.cooldown, startTime, duration, true)
    else
        CooldownFrame_Clear(buffFrame.cooldown)
    end
    buffFrame:Show()

    name = name and name:lower()
    debuffType = debuffType and debuffType:lower() or "physical"
    spellId = tostring(spellId)

    local db = self.db.profile.glows

    if db.auraGlow.buffFrames.enabled then
        if self:TrackAuras(name, debuffType, spellId, db.auraGlow.buffFrames.tracking) then
            local color = db.auraGlow.buffFrames.useDefaultsColors and db.auraGlow.defaultColors[debuffType]                
            self:StartGlow(buffFrame, db.auraGlow.buffFrames, color, "buffFrames", "auraGlow")
            buffFrame.buffFramesGlowing = debuffType
        end     
    end

    if not buffFrame.buffFramesGlowing then
        self:StopGlow(buffFrame, db.auraGlow.buffFrames, "buffFrames", "auraGlow")
    end

    local parent = buffFrame:GetParent()  
    
    parent.buffFramesGlowing[debuffType] = {name, debuffType, spellId}
    parent.buffFramesGlowing[name] = {name, debuffType, spellId}
    parent.buffFramesGlowing[spellId] = {name, debuffType, spellId}
end

local function CompactUnitFrame_Util_IsBossAura(...)
    return select(12, ...)
end

function KHMRaidFrames:CompactUnitFrame_Util_ShouldDisplayDebuff(...)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, isBossAura = ...

    if not self:FilterAuras(name, debuffType, spellId, "debuffFrames") then
        return false
    end

    if self:AdditionalAura(name, debuffType, spellId) then
        return true
    end

    local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT")
    if ( hasCustom ) then
        return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") )   --Would only be "mine" in the case of something like forbearance.
    else
        return true
    end
end

function KHMRaidFrames:CompactUnitFrame_UtilShouldDisplayBuff(...)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = ...

    if not self:FilterAuras(name, debuffType, spellId, "buffFrames") then
        return false
    end

    if self:AdditionalAura(name, debuffType, spellId) then
        return true
    end

    local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT")

    if ( hasCustom ) then
        return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle"))
    else
        return (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") and canApplyAura and not SpellIsSelfBuff(spellId)
    end
end

function KHMRaidFrames:CompactUnitFrame_HideAllBuffs(frame, startingIndex, db)
    if frame.buffFrames then
        for i=startingIndex or 1, #frame.buffFrames do
            frame.buffFrames[i]:Hide()
            self:StopGlow(frame.buffFrames[i], db.buffFrames, "buffFrames", "auraGlow")
        end
    end
end

function KHMRaidFrames:CompactUnitFrame_HideAllDebuffs(frame, startingIndex, db)
    if frame.debuffFrames then
        for i=startingIndex or 1, #frame.debuffFrames do
            frame.debuffFrames[i]:Hide()
            self:StopGlow(frame.debuffFrames[i], db.debuffFrames, "debuffFrames", "auraGlow")
        end
    end
end

function KHMRaidFrames:SetDebuffsHelper(debuffFrames, frameNum, maxDebuffs, filter, isBossAura, isBossBuff, auras)
    if auras then
        for i = 1,#auras do
            local aura = auras[i]
            if frameNum > maxDebuffs then
                break
            end
            local debuffFrame = debuffFrames[frameNum]
            local index, name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId = aura[1], aura[2], aura[3], aura[4], aura[5], aura[6], aura[7], aura[8], aura[9], aura[10], aura[11]

            if self:FilterAuras(name, debuffType, spellId, "debuffFrames") then
                local unit = nil
                self:CompactUnitFrame_UtilSetDebuff(debuffFrame, unit, index, "HARMFUL", isBossAura, isBossBuff, name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId)
                frameNum = frameNum + 1

                if isBossAura then
                    --Boss auras are about twice as big as normal debuffs, so we may need to display fewer buffs
                    local bossDebuffScale = (debuffFrame.baseSize + BOSS_DEBUFF_SIZE_INCREASE)/debuffFrame.baseSize
                    maxDebuffs = maxDebuffs - (bossDebuffScale - 1)
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

function KHMRaidFrames:UpdateAuras(frame)
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
            if db.frames.showBigDebuffs and CompactUnitFrame_Util_IsBossAura(...) then
                if not bossDebuffs then
                    bossDebuffs = {}
                end
                tinsert(bossDebuffs, {index, ...})
                numUsedDebuffs = numUsedDebuffs + 1
                if numUsedDebuffs == maxDebuffs then
                    doneWithDebuffs = true
                    return true
                end
            elseif db.frames.showBigDebuffs and CompactUnitFrame_Util_IsPriorityDebuff(...) then
                if not priorityDebuffs then
                    priorityDebuffs = {}
                end
                tinsert(priorityDebuffs, {index, ...})
            elseif not displayOnlyDispellableDebuffs and self:CompactUnitFrame_Util_ShouldDisplayDebuff(...) then
                if not nonBossDebuffs then
                    nonBossDebuffs = {}
                end
                tinsert(nonBossDebuffs, {index, ...})
            end

            index = index + 1
            return false
        end)
    end

    if not doneWithBuffs or not doneWithDebuffs then
        index = 1
        batchCount = math.max(maxBuffs, maxDebuffs)
        AuraUtil.ForEachAura(frame.displayedUnit, "HELPFUL", batchCount, function(...)
            if db.frames.showBigDebuffs and CompactUnitFrame_Util_IsBossAura(...) then
                -- Boss Auras are considered Debuffs for our purposes.
                if not doneWithDebuffs then
                    if not bossBuffs then
                        bossBuffs = {}
                    end
                    tinsert(bossBuffs, {index, ...})
                    numUsedDebuffs = numUsedDebuffs + 1
                    if numUsedDebuffs == maxDebuffs then
                        doneWithDebuffs = true
                    end
                end
            elseif self:CompactUnitFrame_UtilShouldDisplayBuff(...) then
                if not doneWithBuffs then
                    numUsedBuffs = numUsedBuffs + 1
                    local buffFrame = frame.buffFrames[numUsedBuffs]
                    self:CompactUnitFrame_UtilSetBuff(buffFrame, index, ...)
                    if numUsedBuffs == maxBuffs then
                        doneWithBuffs = true
                    end
                end
            end
            index = index + 1
            return doneWithBuffs and doneWithDebuffs
        end)
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
            if not doneWithDebuffs and displayOnlyDispellableDebuffs then
                if self:CompactUnitFrame_Util_ShouldDisplayDebuff(...) and not CompactUnitFrame_Util_IsBossAura(...) and not CompactUnitFrame_Util_IsPriorityDebuff(...) then
                    if not nonBossDebuffs then
                        nonBossDebuffs = {}
                    end
                    tinsert(nonBossDebuffs, {index, ...})
                    numUsedDebuffs = numUsedDebuffs + 1
                    if numUsedDebuffs == maxDebuffs then
                        doneWithDebuffs = true
                    end
                end
            end
            if not doneWithDispelDebuffs then
                local debuffType = select(4, ...)
                if ( dispellableDebuffTypes[debuffType] and not frame["hasDispel"..debuffType] ) then
                    frame["hasDispel"..debuffType] = true
                    numUsedDispelDebuffs = numUsedDispelDebuffs + 1
                    local dispellDebuffFrame = frame.dispelDebuffFrames[numUsedDispelDebuffs]
                    CompactUnitFrame_UtilSetDispelDebuff(dispellDebuffFrame, debuffType, index)
                    if numUsedDispelDebuffs == maxDispelDebuffs then
                        doneWithDispelDebuffs = true
                    end
                end
            end
            index = index + 1
            return (doneWithDebuffs or not displayOnlyDispellableDebuffs) and doneWithDispelDebuffs
        end)
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


    db = self.db.profile.glows.frameGlow

    if db.buffFrames.enabled then
        for aura, auras in pairs(frame.buffFramesGlowing) do
            local name, debuffType, spellId = auras[1], auras[2], auras[3]
            
            if self:TrackAuras(name, debuffType, spellId, self.db.profile.glows.frameGlow.buffFrames.tracking) then
                local color = db.buffFrames.useDefaultsColors and db.defaultColors[debuffType]
                self:StartGlow(frame, db.buffFrames, color, "buffFrames", "frameGlow")
                self:StopGlow(frame, db.debuffFrames, "debuffFrames", "frameGlow")
                return
            end
        end
    end

    if db.debuffFrames.enabled then
        for aura, auras in pairs(frame.debuffFramesGlowing) do
            local name, debuffType, spellId = auras[1], auras[2], auras[3]

            if self:TrackAuras(name, debuffType, spellId, self.db.profile.glows.frameGlow.debuffFrames.tracking) then
                local color = db.debuffFrames.useDefaultsColors and db.defaultColors[debuffType]
                self:StartGlow(frame, db.debuffFrames, color, "debuffFrames", "frameGlow")
                self:StopGlow(frame, db.buffFrames, "buffFrames", "frameGlow")
                return
            end
        end
    end

    self:StopGlow(frame, db.debuffFrames, "debuffFrames", "frameGlow")
    self:StopGlow(frame, db.buffFrames, "buffFrames", "frameGlow")
end