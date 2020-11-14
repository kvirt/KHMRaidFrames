local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local _G, tonumber, tinsert, math, BOSS_DEBUFF_SIZE_INCREASE = _G, tonumber, tinsert, math, BOSS_DEBUFF_SIZE_INCREASE

local mirrorPositions = {
    ["LEFT"] = {"BOTTOMRIGHT", "BOTTOMLEFT"},
    ["BOTTOM"] = {"TOPLEFT", "BOTTOMLEFT"},
    ["RIGHT"] = {"BOTTOMLEFT", "BOTTOMRIGHT"},
    ["TOP"] = {"BOTTOMLEFT", "TOPLEFT"},         
}

local rowsPositions = {
    ["LEFT"] = {"TOPRIGHT", "TOPLEFT"},
    ["BOTTOM"] = {"TOPRIGHT", "BOTTOMRIGHT"},
    ["RIGHT"] = {"BOTTOMLEFT", "BOTTOMRIGHT"},
    ["TOP"] = {"BOTTOMRIGHT", "TOPRIGHT"},         
}

function KHMRaidFrames:AddSubFramesInternal(frame, groupType)
    for subFrameType in self:IterateSubFrameTypes() do
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

        for i=4, db.num do
            if not self.extraFrames[frameName..i] then 
                local typedFrame = CreateFrame("Button", frameName..i, frame, template)
                typedFrame:ClearAllPoints()
                typedFrame:Hide()
                self.extraFrames[frameName..i] = true
            end
        end
        
        frame[subFrameType.."_Num"] = db.num
    end
end

function KHMRaidFrames:AddSubFrames()
    local isInRaid = IsInRaid() and "raid" or "party"

    for frame in self:IterateCompactFrames(isInRaid) do
        if frame then
            self:AddSubFramesInternal(frame, isInRaid)
        end
    end
end

function KHMRaidFrames:GetFramePosition(frame, typedframes, db, frameNum)
    local anchor1, relativeFrame, anchor2

    if frameNum == 1 then
        anchor1, relativeFrame, anchor2 = db.anchorPoint, frame, db.anchorPoint
    elseif frameNum % (db.numInRow) == 1 then
        anchor1, relativeFrame, anchor2 = rowsPositions[db.rowsGrowDirection][1], typedframes[frameNum - db.numInRow], rowsPositions[db.rowsGrowDirection][2]
    else
        anchor1, relativeFrame, anchor2 = mirrorPositions[db.growDirection][1], typedframes[frameNum - 1], mirrorPositions[db.growDirection][2]           
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

    excluded = self:FilterAurasInternal(name, debuffType, spellId, db.exclude)

    if excluded then return false else return true end
end

function KHMRaidFrames:FilterAurasInternal(name, debuffType, spellId, db)
    if #db == 0 then return false end    

    name = name and self:SanitazeString(name)
    debuffType = debuffType and self:SanitazeString(debuffType)

    for _, aura in ipairs(db) do
        if aura ~= nil and (aura == name or aura == debuffType or (spellId ~= nil and tonumber(aura) == spellId)) then
            return true
        end
    end

    return false
end