local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")

local defuffsColors = {
    magic = {0.2, 0.6, 1.0, 1},
    curse = {0.6, 0.0, 1.0, 1},
    disease = {0.6, 0.4, 0.0, 1},
    poison = {0.0, 0.6, 0.0, 1},
    physical = {1, 1, 1, 1}
}


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

    debuffFrame:SetSize(size, size)

    debuffFrame:Show()

    name = name and name:lower()
    debuffType = debuffType and debuffType:lower() or "physical"
    spellId = tostring(spellId)

    local db = self.db.profile.glows

    if db.auraGlow.debuffFrames.enabled then
        for _, aura in ipairs(db.auraGlow.debuffFrames.tracking) do
            if (
                aura ~= nil and 
                (aura == name or aura == debuffType or aura == spellId)
            ) then
                local color = db.auraGlow.buffFrames.useDefaultsColors and defuffsColors[debuffType]                
                self:StartGlow(debuffFrame, db.auraGlow.debuffFrames, color, "debuffFrames", "auraGlow")
                debuffFrame.debuffFramesGlowing = debuffType
                break
            end
        end
    end        

    if not debuffFrame.debuffFramesGlowing then
        self:StopGlow(debuffFrame, db.auraGlow.debuffFrames, "debuffFrames", "auraGlow")
    end

    local parent = debuffFrame:GetParent() 
    parent.debuffFramesGlowing[debuffType] = debuffType
    parent.debuffFramesGlowing[name] = debuffType
    parent.debuffFramesGlowing[spellId] = debuffType
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
        for _, aura in ipairs(db.auraGlow.buffFrames.tracking) do
            if (
                aura ~= nil and 
                (aura == name or aura == debuffType or aura == spellId)
            ) then
                local color = db.auraGlow.buffFrames.useDefaultsColors and defuffsColors[debuffType]                
                self:StartGlow(buffFrame, db.auraGlow.buffFrames, color, "buffFrames", "auraGlow")
                buffFrame.buffFramesGlowing = debuffType
                break
            end
        end        
    end

    if not buffFrame.buffFramesGlowing then
        self:StopGlow(buffFrame, db.auraGlow.buffFrames, "buffFrames", "auraGlow")
    end

    local parent = buffFrame:GetParent()  
    parent.buffFramesGlowing[debuffType] = debuffType
    parent.buffFramesGlowing[name] = debuffType
    parent.buffFramesGlowing[spellId] = debuffType
end

local function CompactUnitFrame_Util_IsBossAura(...)
    return select(12, ...)
end

function KHMRaidFrames:CompactUnitFrame_Util_ShouldDisplayDebuff(...)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, isBossAura = ...

    if not self:FilterAuras(name, debuffType, spellId, "debuffFrames") then
        return false
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
            if CompactUnitFrame_Util_IsBossAura(...) then
                if not bossDebuffs then
                    bossDebuffs = {}
                end
                tinsert(bossDebuffs, {index, ...})
                numUsedDebuffs = numUsedDebuffs + 1
                if numUsedDebuffs == maxDebuffs then
                    doneWithDebuffs = true
                    return true
                end
            elseif CompactUnitFrame_Util_IsPriorityDebuff(...) then
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
            if CompactUnitFrame_Util_IsBossAura(...) then
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
        for _, tracking in ipairs(db.buffFrames.tracking) do
            if frame.buffFramesGlowing[tracking] then
                local color = db.buffFrames.useDefaultsColors and defuffsColors[frame.buffFramesGlowing[tracking]]
                self:StartGlow(frame, db.buffFrames, color, "buffFrames", "frameGlow")
                self:StopGlow(frame, db.debuffFrames, "debuffFrames", "frameGlow")
                return
            end
        end
    end

    if db.debuffFrames.enabled then
        for _, tracking in ipairs(db.debuffFrames.tracking) do
            if frame.debuffFramesGlowing[tracking] then
                local color = db.debuffFrames.useDefaultsColors and defuffsColors[frame.debuffFramesGlowing[tracking]]
                self:StartGlow(frame, db.debuffFrames, color, "debuffFrames", "frameGlow")
                self:StopGlow(frame, db.buffFrames, "buffFrames", "frameGlow")
                return
            end
        end
    end

    self:StopGlow(frame, db.debuffFrames, "debuffFrames", "frameGlow")
    self:StopGlow(frame, db.buffFrames, "buffFrames", "frameGlow")

    --     for aura, debuffType in pairs(frame.useDefaultsColors) do
    --         if aura ~= nil and aura == parent.debuffFramesGlowing then break end

    --         if (
    --             aura ~= nil and 
    --             (aura == name or aura == debuffType or aura == spellId)
    --         ) then                     
    --             parent.debuffFramesGlowing = debuffType
    --             break
    --         end
    --     end
    -- end

    -- if frame.debuffFramesGlowing then
    --     local color = db.debuffFrames.useDefaultsColors and defuffsColors[frame.debuffFramesGlowing]
    --     self:StartGlow(frame, db.debuffFrames, color, "debuffFrames")

    --     if db.debuffFrames.type ~= db.buffFrames.type then
    --         self:StopGlow(frame, db.buffFrames, "buffFrames")
    --     end
    -- elseif frame.buffFramesGlowing then
    --     local color = db.buffFrames.useDefaultsColors and defuffsColors[frame.buffFramesGlowing]
    --     self:StartGlow(frame, db.buffFrames, color, "buffFrames")

    --     if db.debuffFrames.type ~= db.buffFrames.type then
    --         self:StopGlow(frame, db.debuffFrames, "debuffFrames")
    --     end        
    -- else
    --     self:StopGlow(frame, db.debuffFrames, "debuffFrames")
    --     self:StopGlow(frame, db.buffFrames, "buffFrames")
    -- end        
    -- if rame.debuffFramesGlowing then
    --     self:StopGlow(frame, db.debuffFrames)
    --     self:StopGlow(frame, db.buffFrames)

    --     local color = db.debuffFrames.useDefaultsColors and defuffsColors[n_d]
    --     self:StartGlow(frame, db.debuffFrames, color)
    --     return
    -- elseif (n_d and o_d) and n_d == o_d then
    --     return
    -- elseif not n_d then
    --     self:StopGlow(frame, db.debuffFrames)  
    -- end

    -- topPrio = 9999

    -- for k, v in pairs(frame.buffFramesGlowing or {}) do
    --     if tonumber(k) < topPrio then topPrio = k end
    -- end

    -- local n_b = frame.buffFramesGlowing[topPrio]
    -- local o_b = buffFramesGlowing

    -- frame.buffFramesGlowing = n_b

    -- if n_b and (n_b ~= o_b) then
    --     self:StopGlow(frame, db.debuffFrames)
    --     self:StopGlow(frame, db.buffFrames)

    --     local color = db.buffFrames.useDefaultsColors and defuffsColors[n_b]
    --     self:StartGlow(frame, db.buffFrames, color)
    --     return
    -- elseif (n_b and o_b) and n_b == o_b then
    --     return
    -- elseif not n_b then
    --     self:StopGlow(frame, db.buffFrames)  
    -- end











                   
    -- local d_old, d_new = debuffFramesGlowing, frame.debuffFramesGlowing

    -- if (d_old and d_new) and (d_old[1] ~= d_new[1]) then
    --     if d_new[2] ~= d_old[2] then
    --         self:StopGlow(frame, db.debuffFrames)
    --         self:StopGlow(frame, db.buffFrames)

    --         local color = db.debuffFrames.useDefaultsColors and defuffsColors[d_new[1]]
    --         self:StartGlow(frame, db.debuffFrames, color)
    --         return
    --     end
    -- elseif d_old and not d_new then
    --     self:StopGlow(frame, db.debuffFrames)
    -- elseif not d_old and d_new then
    --     local color = db.debuffFrames.useDefaultsColors and defuffsColors[d_new[1]]
    --     self:StartGlow(frame, db.debuffFrames, color)
    --     return
    -- elseif (d_old and d_new) and (d_old[1] == d_new[1]) then
    --     return
    -- end

    -- local b_old, b_new = buffFramesGlowing, frame.buffFramesGlowing

    -- if (b_old and b_new) and (b_old[1] ~= b_new[1]) then
    --     if b_new[2] ~= b_old[2] then
    --         self:StopGlow(frame, db.buffFrames)
    --         self:StopGlow(frame, db.debuffFrames) 
                           
    --         local color = db.buffFrames.useDefaultsColors and defuffsColors[b_new[1]]
    --         self:StartGlow(frame, db.buffFrames, color)
    --     end

    -- elseif b_old and not b_new then
    --     self:StopGlow(frame, db.buffFrames)
    -- elseif not b_old and b_new then
    --     local color = db.buffFrames.useDefaultsColors and defuffsColors[b_new[1]]
    --     self:StartGlow(frame, db.buffFrames, color)
    -- elseif (b_old and b_new) and (b_old[1] == b_new[1]) then
    --     local color = db.buffFrames.useDefaultsColors and defuffsColors[b_new[1]]
    --     self:StartGlow(frame, db.buffFrames, color) 
    -- end
end