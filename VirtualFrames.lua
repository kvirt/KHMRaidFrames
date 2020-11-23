local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")

local _G = _G


function KHMRaidFrames:GetVirtualFrames()
    local frame

    for frameType in self:IterateSubFrameTypes() do
        for i=1, self.maxFrames do
            frame = CreateFrame("Frame", nil, UIParent)
            self.virtual.frames[frameType..i] = frame

            local texture = frame:CreateTexture(nil, "BACKGROUND")
            texture:SetAllPoints(frame)

            frame.texture = texture

            if frameType == "buffFrames" then
                texture:SetTexture("Interface\\Icons\\ability_rogue_sprint")
            elseif frameType == "debuffFrames" then
                texture:SetTexture("Interface\\Icons\\ability_rogue_kidneyshot")
            else
                texture:SetTexture("Interface\\RaidFrame\\Raid-Icon-DebuffMagic")
            end

            frame:Hide()
        end
    end
end

function KHMRaidFrames:ShowVirtual(groupType)
    local frame 

    for _frame in self:IterateCompactFrames("raid") do
        frame = _frame
        break
    end

    if frame == nil then
        for _frame in self:IterateCompactFrames("party") do
            frame = _frame
            break
        end
    end

    if frame == nil then
        return
    end

    self.virtual.shown = true 
    self.virtual.frame = frame

    for subFrameType in self:IterateSubFrameTypes() do
        self:SetUpVirtual(subFrameType, groupType)
    end
end

function KHMRaidFrames:SetUpVirtual(subFrameType, groupType)
    if self.virtual.shown == false then return end

    local db = self.db.profile[groupType][subFrameType]

    local typedframes = {}

    for i=1, self.maxFrames do
        typedframes[i] = self.virtual.frames[subFrameType..i]
    end

    for frameNum=1, #typedframes do
        if frameNum > db.num then
            typedframes[frameNum]:Hide()
        elseif frameNum <= db.num then
            typedframes[frameNum]:Show()
        end
    end 

    local resize = subFrameType ~= "dispelDebuffFrames" and self.componentScale or 1
    self:SetUpSubFramesPositionsAndSize(self.virtual.frame, typedframes, db, groupType, resize)
end

function KHMRaidFrames:HideVirtual()
    for _, frame in pairs(self.virtual.frames) do
        frame:Hide()
    end

    self.virtual.shown = false        
end