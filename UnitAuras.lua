local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")

local _G, tostring, tinsert, math, BOSS_DEBUFF_SIZE_INCREASE = _G, tostring, tinsert, math, BOSS_DEBUFF_SIZE_INCREASE
local CUF_AURA_BOTTOM_OFFSET = 2
local powerBarHeight = 8

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


function KHMRaidFrames:Offsets(anchor)
    local powerBarUsedHeight = (self.displayPowerBar and powerBarHeight or 0) + CUF_AURA_BOTTOM_OFFSET 
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

    name = name and self:SanitazeString(name)
    debuffType = debuffType and self:SanitazeString(debuffType)
    spellId = tostring(spellId)

    for _, aura in ipairs(db) do
        if aura ~= nil and (aura == name or aura == debuffType or (spellId ~= nil and aura == spellId)) then
            return true
        end
    end

    return false
end

function KHMRaidFrames:AdditionalAura(name, debuffType, spellId)
    local db

    if IsInRaid() then
        db = self.db.profile.raid.frames.tracking
    else
        db = self.db.profile.party.frames.tracking
    end

    if #db == 0 then return false end

    name = name and self:SanitazeString(name)
    debuffType = debuffType and self:SanitazeString(debuffType)
    spellId = tostring(spellId)

    for _, aura in ipairs(db) do
        if aura == name or aura == debuffType or (spellId ~= nil and aura == spellId) then
            return true
        end
    end

    return false
end

function KHMRaidFrames:SmartAnchoring(frame, typedframes, db)
    local frameNum = 1
    local typedframe, anchor1, anchor2, relativeFrame, xOffset, yOffset

    local size = db.size * self.componentScale
    local bigSize = size * 2
    local rowCounter = 1
    local rowStart = 1

    while frameNum <= #typedframes do
        local rowLen = db.numInRow
        local index = 1
        local bigs = 0

        while true do
            if frameNum > #typedframes then break end

            typedframe = typedframes[frameNum]
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