local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local _G, tonumber, tinsert, math = _G, tonumber, tinsert, math

local mirror_positions = {
    ["LEFT"] = {"BOTTOMRIGHT", "BOTTOMLEFT"},
    ["BOTTOM"] = {"TOPLEFT", "BOTTOMLEFT"},
    ["RIGHT"] = {"BOTTOMLEFT", "BOTTOMRIGHT"},
    ["TOP"] = {"BOTTOMLEFT", "TOPLEFT"},         
}

local rows_positions = {
    ["LEFT"] = {"TOPRIGHT", "TOPLEFT"},
    ["BOTTOM"] = {"TOPRIGHT", "BOTTOMRIGHT"},
    ["RIGHT"] = {"BOTTOMLEFT", "BOTTOMRIGHT"},
    ["TOP"] = {"BOTTOMRIGHT", "TOPRIGHT"},         
}


function KHMRaidFrames:AddSubFrames(frame, db, frameType)
    if not frame then return end
    local frameName = frame:GetName()..frameType
    local template 

    if frameType == "buffFrames" then
        template = "CompactBuffTemplate"
    elseif frameType == "debuffFrames" then
        template = "CompactDebuffTemplate"
    elseif frameType == "dispelDebuffFrames" then
        template = "CompactDispelDebuffTemplate"
    end  

    if db.num > 3 then
        for i=4, db.num do
            if not self.extraFrames[frameName..i] then 
                local typedFrame = CreateFrame("Button", frameName..i, frame, template)
                typedFrame:ClearAllPoints()
                typedFrame:Hide()
                self.extraFrames[frameName..i] = true
            end
        end
    end
end

function KHMRaidFrames:GetFrameProperties(frame)
    local matches = frame:GetName():gmatch("%u+%l+%d*")
    local _, groupType = matches(), matches()
    return groupType:lower()
end

function KHMRaidFrames:CompactUnitFrame_Util_IsBossAura(...)
    return select(12, ...);
end

function KHMRaidFrames:CompactUnitFrame_Util_ShouldDisplayDebuff(...)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura, isBossAura = ...;

    if not self:FilterAuras(name, debuffType, spellId, "debuffFrames") then
        return false
    end

    local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT");
    if ( hasCustom ) then
        return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") );   --Would only be "mine" in the case of something like forbearance.
    else
        return true;
    end
end

function KHMRaidFrames:CompactUnitFrame_UtilShouldDisplayBuff(...)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = ...;

    if not self:FilterAuras(name, debuffType, spellId, "buffFrames") then
        return false
    end

    local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(spellId, UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT");

    if ( hasCustom ) then
        return showForMySpec or (alwaysShowMine and (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle"));
    else
        return (unitCaster == "player" or unitCaster == "pet" or unitCaster == "vehicle") and canApplyAura and not SpellIsSelfBuff(spellId);
    end
end

function KHMRaidFrames:SetDebuffsHelper(debuffFrames, frameNum, maxDebuffs, filter, isBossAura, isBossBuff, auras)
    if auras then
        for i = 1,#auras do
            local aura = auras[i];
            if frameNum > maxDebuffs then
                break;
            end
            local debuffFrame = debuffFrames[frameNum];
            local index, name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId = aura[1], aura[2], aura[3], aura[4], aura[5], aura[6], aura[7], aura[8], aura[9], aura[10], aura[11];
            local unit = nil;
            CompactUnitFrame_UtilSetDebuff(debuffFrame, unit, index, "HARMFUL", isBossAura, isBossBuff, name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, nameplateShowPersonal, spellId);
            frameNum = frameNum + 1;

            if isBossAura then
                --Boss auras are about twice as big as normal debuffs, so we may need to display fewer buffs
                local bossDebuffScale = (debuffFrame.baseSize + BOSS_DEBUFF_SIZE_INCREASE)/debuffFrame.baseSize;
                maxDebuffs = maxDebuffs - (bossDebuffScale - 1);
            end
        end
    end
    return frameNum, maxDebuffs;
end

function KHMRaidFrames:NumElements(arr)
    return arr and #arr or 0;
end

local dispellableDebuffTypes = { Magic = true, Curse = true, Disease = true, Poison = true};

function KHMRaidFrames:UpdateAuras(frame)
    local db = self.db.profile[self:GetFrameProperties(frame)]
    local maxBuffs = db.buffFrames.num
    local maxDebuffs = db.debuffFrames.num
    local maxDispelDebuffs = db.dispelDebuffFrames.num

    local doneWithBuffs = not frame.buffFrames or not frame.optionTable.displayBuffs or maxBuffs == 0;
    local doneWithDebuffs = not frame.debuffFrames or not frame.optionTable.displayDebuffs or maxDebuffs == 0;
    local doneWithDispelDebuffs = not frame.dispelDebuffFrames or not frame.optionTable.displayDispelDebuffs or maxDispelDebuffs == 0;

    local numUsedBuffs = 0;
    local numUsedDebuffs = 0;
    local numUsedDispelDebuffs = 0;

    local displayOnlyDispellableDebuffs = frame.optionTable.displayOnlyDispellableDebuffs;

    -- The following is the priority order for debuffs
    local bossDebuffs, bossBuffs, priorityDebuffs, nonBossDebuffs;
    local index = 1;
    local batchCount = maxDebuffs

    if not doneWithDebuffs then
        AuraUtil.ForEachAura(frame.displayedUnit, "HARMFUL", batchCount, function(...)
            if self:CompactUnitFrame_Util_IsBossAura(...) then
                if not bossDebuffs then
                    bossDebuffs = {};
                end
                tinsert(bossDebuffs, {index, ...});
                numUsedDebuffs = numUsedDebuffs + 1;
                if numUsedDebuffs == maxDebuffs then
                    doneWithDebuffs = true;
                    return true;
                end
            elseif CompactUnitFrame_Util_IsPriorityDebuff(...) then
                if not priorityDebuffs then
                    priorityDebuffs = {};
                end
                tinsert(priorityDebuffs, {index, ...});
            elseif not displayOnlyDispellableDebuffs and self:CompactUnitFrame_Util_ShouldDisplayDebuff(...) then
                if not nonBossDebuffs then
                    nonBossDebuffs = {};
                end
                tinsert(nonBossDebuffs, {index, ...});
            end

            index = index + 1;
            return false;
        end);
    end

    if not doneWithBuffs or not doneWithDebuffs then
        index = 1;
        batchCount = math.max(maxBuffs, maxDebuffs);
        AuraUtil.ForEachAura(frame.displayedUnit, "HELPFUL", batchCount, function(...)
            if self:CompactUnitFrame_Util_IsBossAura(...) then
                -- Boss Auras are considered Debuffs for our purposes.
                if not doneWithDebuffs then
                    if not bossBuffs then
                        bossBuffs = {};
                    end
                    tinsert(bossBuffs, {index, ...});
                    numUsedDebuffs = numUsedDebuffs + 1;
                    if numUsedDebuffs == maxDebuffs then
                        doneWithDebuffs = true;
                    end
                end
            elseif self:CompactUnitFrame_UtilShouldDisplayBuff(...) then
                if not doneWithBuffs then
                    numUsedBuffs = numUsedBuffs + 1;
                    local buffFrame = frame.buffFrames[numUsedBuffs];
                    CompactUnitFrame_UtilSetBuff(buffFrame, index, ...);
                    if numUsedBuffs == maxBuffs then
                        doneWithBuffs = true;
                    end
                end
            end

            index = index + 1;
            return doneWithBuffs and doneWithDebuffs;
        end);
    end

    numUsedDebuffs = math.min(maxDebuffs, numUsedDebuffs + self:NumElements(priorityDebuffs));
    if numUsedDebuffs == maxDebuffs then
        doneWithDebuffs = true;
    end

    if not doneWithDispelDebuffs then
        --Clear what we currently have for dispellable debuffs
        for debuffType, display in pairs(dispellableDebuffTypes) do
            if ( display ) then
                frame["hasDispel"..debuffType] = false;
            end
        end
    end

    if not doneWithDispelDebuffs or not doneWithDebuffs then
        batchCount = math.max(maxDebuffs, maxDispelDebuffs);
        index = 1;
        AuraUtil.ForEachAura(frame.displayedUnit, "HARMFUL|RAID", batchCount, function(...)
            if not doneWithDebuffs and displayOnlyDispellableDebuffs then
                if self:CompactUnitFrame_Util_ShouldDisplayDebuff(...) and not self:CompactUnitFrame_Util_IsBossAura(...) and not CompactUnitFrame_Util_IsPriorityDebuff(...) then
                    if not nonBossDebuffs then
                        nonBossDebuffs = {};
                    end
                    tinsert(nonBossDebuffs, {index, ...});
                    numUsedDebuffs = numUsedDebuffs + 1;
                    if numUsedDebuffs == maxDebuffs then
                        doneWithDebuffs = true;
                    end
                end
            end
            if not doneWithDispelDebuffs then
                local debuffType = select(4, ...);
                if ( dispellableDebuffTypes[debuffType] and not frame["hasDispel"..debuffType] ) then
                    frame["hasDispel"..debuffType] = true;
                    numUsedDispelDebuffs = numUsedDispelDebuffs + 1;
                    local dispellDebuffFrame = frame.dispelDebuffFrames[numUsedDispelDebuffs];
                    CompactUnitFrame_UtilSetDispelDebuff(dispellDebuffFrame, debuffType, index)
                    if numUsedDispelDebuffs == maxDispelDebuffs then
                        doneWithDispelDebuffs = true;
                    end
                end
            end
            index = index + 1;
            return (doneWithDebuffs or not displayOnlyDispellableDebuffs) and doneWithDispelDebuffs;
        end);
    end

    local frameNum = 1;
    local maxDebuffs = maxDebuffs

    do
        local isBossAura = true;
        local isBossBuff = false;
        frameNum, maxDebuffs = self:SetDebuffsHelper(frame.debuffFrames, frameNum, maxDebuffs, "HARMFUL", isBossAura, isBossBuff, bossDebuffs);
    end
    do
        local isBossAura = true;
        local isBossBuff = true;
        frameNum, maxDebuffs = self:SetDebuffsHelper(frame.debuffFrames, frameNum, maxDebuffs, "HELPFUL", isBossAura, isBossBuff, bossBuffs);
    end
    do
        local isBossAura = false;
        local isBossBuff = false;
        frameNum, maxDebuffs = self:SetDebuffsHelper(frame.debuffFrames, frameNum, maxDebuffs, "HARMFUL", isBossAura, isBossBuff, priorityDebuffs);
    end
    do
        local isBossAura = false;
        local isBossBuff = false;
        frameNum, maxDebuffs = self:SetDebuffsHelper(frame.debuffFrames, frameNum, maxDebuffs, "HARMFUL|RAID", isBossAura, isBossBuff, nonBossDebuffs);
    end
    numUsedDebuffs = frameNum - 1;

    CompactUnitFrame_HideAllBuffs(frame, numUsedBuffs + 1);
    CompactUnitFrame_HideAllDebuffs(frame, numUsedDebuffs + 1);
    CompactUnitFrame_HideAllDispelDebuffs(frame, numUsedDispelDebuffs + 1);
end

function KHMRaidFrames:GetFramePosition(frame, typedframes, db, frameNum)
    local anchor1, relativeFrame, anchor2

    if frameNum == 1 then
        anchor1, relativeFrame, anchor2 = db.anchorPoint, frame, db.anchorPoint
    elseif frameNum % (db.numInRow) == 1 then
        anchor1, relativeFrame, anchor2 = rows_positions[db.rowsGrowDirection][1], typedframes[frameNum - db.numInRow], rows_positions[db.rowsGrowDirection][2]
    else
        anchor1, relativeFrame, anchor2 = mirror_positions[db.growDirection][1], typedframes[frameNum - 1], mirror_positions[db.growDirection][2]           
    end

    return anchor1, relativeFrame, anchor2
end

function KHMRaidFrames:FilterAuras(name, debuffType, spellId, frameType)
    local db, excluded

    if IsInRaid() then
        db = self.db.profile.raid[frameType]
    else
        db = self.db.profile.party[frameType]
    end

    excluded = self:FilterAurasInternal(name, debuffType, spellId, db.exclude, true)

    if excluded then return false end

    return self:FilterAurasInternal(name, debuffType, spellId, db.tracking, false)
end

function KHMRaidFrames:FilterAurasInternal(name, debuffType, spellId, db, exclude)
    if #db == 0 then return not exclude end

    for _, aura in pairs(db) do
        if aura == name or aura == debuffType or tonumber(aura) == spellId then
            return true
        end
    end

    return false
end