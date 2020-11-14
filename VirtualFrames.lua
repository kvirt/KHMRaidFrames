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
    if self.virtual.shown then
        self:HideVirtual()
        return
    end

    for frame in self:IterateCompactFrames(groupType) do
        self.virtual.shown = true
        self:SetUpVirtualSubFrames(frame, groupType)
        break
    end
end

function KHMRaidFrames:HideVirtual()
    for _, frame in pairs(self.virtual.frames) do
        frame:Hide()
    end

    self.virtual.shown = false
end

function KHMRaidFrames:SetUpVirtualFrameCount(typedframes, num)
    for frameNum=1, #typedframes do
        if frameNum > num then
            typedframes[frameNum]:Hide()
        elseif frameNum <= num then
            typedframes[frameNum]:Show()
        end
    end     
end

function KHMRaidFrames:SetUpVirtualSubFrames(frame, groupType)
    if not frame or not self.virtual.shown then
        self:HideVirtual()
        return
    end
    print(frame:GetName())
    local db = self.db.profile[groupType]

    for subFrameType in self:IterateSubFrameTypes() do
        local _db = db[subFrameType]

        local typedframes = {}
        for i=1, self.maxFrames do
            typedframes[i] = self.virtual.frames[subFrameType..i]
        end

        self:SetUpVirtualFrameCount(typedframes, _db.num)
        self:SetUpSubFramesPositionsAndSize(frame, typedframes, _db)
    end
end