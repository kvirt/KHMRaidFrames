local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local LGF = LibStub("LibGetFrame-1.0")
local _G, SecureButton_GetUnit, C_Timer, _ = _G, SecureButton_GetUnit, C_Timer, _

function KHMRaidFrames:GetVirtualFrames()
    local frames = {
        buffFrames = {},
        debuffFrames = {},
        dispelDebuffFrames = {},
    }
    local frame

    for frameType, _ in pairs(frames) do
        for i=1, self.maxFrames do
            if not frames[i] then
                frame = CreateFrame("Frame", nil, UIParent)
                table.insert(frames[frameType], frame)

                local texture = frame:CreateTexture(nil, "BACKGROUND")
                texture:SetAllPoints(frame)

                local cooldown = CreateFrame("Cooldown", "myCooldown"..i, frame, "CooldownFrameTemplate")
                cooldown:SetAllPoints(frame)


                frame.cooldown = cooldown
                frame.texture = texture

                if frameType == "buffFrames" then
                    texture:SetTexture("Interface\\Icons\\ability_rogue_sprint")
                    self:SecureHookScript(frame, "OnShow", "OnCooldownShow")
                    self:SecureHookScript(frame, "OnHide", "OnCooldownHide")
                elseif frameType == "debuffFrames" then
                    texture:SetTexture("Interface\\Icons\\ability_rogue_kidneyshot")
                    self:SecureHookScript(frame, "OnShow", "OnCooldownShow")
                    self:SecureHookScript(frame, "OnHide", "OnCooldownHide")
                else
                    texture:SetTexture("Interface\\RaidFrame\\Raid-Icon-DebuffMagic")
                end

                frame:Hide()
            end
        end
    end
    return frames
end

function KHMRaidFrames:OnCooldownShow(frame)
    local duration = 9

    local function SetCooldownTicker(duration)
        frame.cooldown:Clear()
        frame.cooldown:SetCooldown(GetTime(), duration)
    end

    SetCooldownTicker(duration)
    local handle = C_Timer.NewTicker(duration, function() SetCooldownTicker(duration) end)
    frame.handler = handle
end

function KHMRaidFrames:OnCooldownHide(frame)
    if frame.handler then
        frame.handler:Cancel()
    end

    frame.cooldown:Clear()
end

function KHMRaidFrames:ShowVirtual(info)
    local groupType, frameType = info[1], info[2]

    if self.virtual[frameType] then
        self.virtual[frameType] = false
        self:HideVirtual()
        return
    end

    local db = self.db.profile[groupType][frameType]

    local typedframes = self.virtualFrames[frameType]

    local frame = LGF.GetFrame("player", {framePriorities={"^CompactParty", "^CompactRaid"}})

    if not frame then
        self:HideAllVirtual()
        return
    end

    self.virtual[frameType] = true
    self:SetUpFramesInternal(frame, typedframes, db)
    self:SetUpVirtualFrameCount(typedframes, db) 
end

function KHMRaidFrames:HideAllVirtual()
    for k, v in pairs(self.virtual) do
        self.virtual[k] = false
    end

    self:HideVirtual()
end

function KHMRaidFrames:HideVirtual()
    for frameType, virtualStatus in pairs(self.virtual) do
        if not virtualStatus then
            local typedframes = self.virtualFrames[frameType]
            for i=1, #typedframes do
                typedframes[i].cooldown:Clear()
                typedframes[i]:Hide()
            end
        end
    end
end

function KHMRaidFrames:SetUpVirtualFrameCount(typedframes, db)
    for frameNum=1, #typedframes do
        if frameNum > db.num then
            typedframes[frameNum]:Hide()
        elseif frameNum <= db.num then
            typedframes[frameNum]:Show()
        end
    end     
end

function KHMRaidFrames:SetUpVirtualSubFrames(groupIndex)
    local frame = LGF.GetFrame("player", {framePriorities={"^CompactParty", "^CompactRaid"}})

    if not frame then
        self:HideAllVirtual()
        return
    end

    local db = self:FrameType(groupIndex)

    for _, frameType in ipairs({"buffFrames", "debuffFrames", "dispelDebuffFrames"}) do
        if self.virtual[frameType] then
            typedframes = self.virtualFrames[frameType]
            local _db = db[frameType]
            self:SetUpFramesInternal(frame, typedframes, _db)
            self:SetUpVirtualFrameCount(typedframes, _db)            
        end  
    end
end