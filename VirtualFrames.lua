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

            local text = frame:CreateFontString(frame, "OVERLAY", "GameTooltipText")
            text:SetPoint("CENTER", 0, 0)
            text:SetText(i)

            frame.text = text

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

function KHMRaidFrames:ShowVirtual()
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

    self:SetUpVirtual("buffFrames", self.virtual.groupType, self.componentScale)
    self:SetUpVirtual("debuffFrames", self.virtual.groupType, self.componentScale, true)
    self:SetUpVirtual("dispelDebuffFrames", self.virtual.groupType, 1)
end

function KHMRaidFrames:SetUpVirtual(subFrameType, groupType, resize, bigSized)
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

    self:SetUpSubFramesPositionsAndSize(self.virtual.frame, typedframes, db, groupType, resize)

    if db.showBigDebuffs and bigSized then
        typedframes[1].isBossAura = true
        typedframes[2].isBossAura = true

        local size = db.bigDebuffSize * resize

        typedframes[1]:SetSize(size, size)
        typedframes[2]:SetSize(size, size)

        if db.smartAnchoring then      
            self:SmartAnchoring(self.virtual.frame, typedframes, db)
        end
    end    
end

function KHMRaidFrames:HideVirtual()
    for _, frame in pairs(self.virtual.frames) do
        frame:Hide()
    end

    self.virtual.shown = false        
end