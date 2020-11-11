local addonName, addonTable = ...
addonTable.KHMRaidFrames = LibStub("AceAddon-3.0"):NewAddon("KHMRaidFrames", "AceHook-3.0", "AceConsole-3.0")

local KHMRaidFrames = addonTable.KHMRaidFrames
local _G = _G


function KHMRaidFrames:RefreshConfig()
    self:AddSubFrames()

    local doneWithVirtual = false

    for frame in self:IterateRaidMembers() do
        self:SetUpFrame(frame, "raid")
        self:SetUpSubFrames(frame, "raid")

        if self.virtual.shown and not doneWithVirtual then
            self:SetUpVirtualSubFrames(frame, "raid")
            doneWithVirtual = true
        end

        if not InCombatLockdown() then
            CompactUnitFrame_UpdateAll(frame)
        end          
    end

    for frame in self:IterateGroupMembers() do
        self:SetUpFrame(frame, "party")
        self:SetUpSubFrames(frame, "party")

        if self.virtual.shown and not doneWithVirtual then
            self:SetUpVirtualSubFrames(frame, "party")
            doneWithVirtual = true
        end

        if not InCombatLockdown() then
            CompactUnitFrame_UpdateAll(frame)
        end         
    end    

    for group in self:IterateRaidGroups() do
        self:SetUpGroup(group, "raid")
    end

    self:SetUpGroup(_G["CompactPartyFrame"], "party")
end

function KHMRaidFrames:UpdateLayout()
    if IsInRaid() then
        for frame in self:IterateRaidMembers() do
            self:SetUpFrame(frame, "raid")
            self:SetUpSubFrames(frame, "raid")
        end
        
        for group in self:IterateRaidGroups() do
            self:SetUpGroup(group, "raid")
        end        
    else
        for frame in self:IterateGroupMembers() do
            self:SetUpFrame(frame, "party")
            self:SetUpSubFrames(frame, "party") 
        end

        self:SetUpGroup(_G["CompactPartyFrame"], "party")  
    end
end

function KHMRaidFrames:SetUpSubFrames(frame, groupType)
    local typedframes

    local db = self.db.profile[groupType]

    if frame and frame:IsShown() and frame.unit then
        for frameType in self:IterateSubFrameTypes() do
            typedframes = frame[frameType]

            self:ShowHideHooks(typedframes, db[frameType])         
            self:SetUpSubFramesPositionsAndSize(frame, typedframes, db[frameType])
        end              
    end                   
end  

function KHMRaidFrames:ShowHideHooks(typedframes, db)
    local hooked, _

    for frameNum=1, #typedframes do
        if frameNum > db.num then
            hooked, _ = self:IsHooked(typedframes[frameNum], "OnShow")

            if not hooked then 
                self:SecureHookScript(typedframes[frameNum], "OnShow", 
                    function(typedframe)
                        self:OnShow(typedframe, db, frameNum)
                    end
                )
            end

            self:OnShow(typedframes[frameNum], db, frameNum)
        end
    end
end                            

function KHMRaidFrames:OnShow(frame, db, frameNum)
    if frameNum > db.num then
        frame:Hide()
    end
end

function KHMRaidFrames:SetUpSubFramesPositionsAndSize(frame, typedframes, db)
    local frameNum = 1
    local typedframe, anchor1, anchor2, relativeFrame, xOffset, yOffset

    while frameNum <= #typedframes do
        typedframe = typedframes[frameNum]

        typedframe:ClearAllPoints()
        anchor1, relativeFrame, anchor2 = self:GetFramePosition(frame, typedframes, db, frameNum)

        if frameNum == 1 then
            xOffset, yOffset = db.xOffset, db.yOffset
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

        typedframe:SetSize(db.size, db.size)      

        frameNum = frameNum + 1
    end     
end

function KHMRaidFrames:SetUpFrame(frame, groupType)
    local db = self.db.profile[groupType]

    if frame then
        frame.healthBar:SetStatusBarTexture(db.frames.texture, "BORDER")
    end
end

function KHMRaidFrames:SetUpGroup(frame, groupType)
    local db = self.db.profile[groupType]

    if db.frames.hideGroupTitles then
        frame.title:Hide()
    else
        frame.title:Show()
    end
end                    