local addonName, addonTable = ...
addonTable.KHMRaidFrames = LibStub("AceAddon-3.0"):NewAddon("KHMRaidFrames", "AceHook-3.0", "AceEvent-3.0", "AceConsole-3.0")

local KHMRaidFrames = addonTable.KHMRaidFrames
local _G = _G
local UnitPopupButtons = {
    ["RAID_TARGET_1"] = UnitPopupButtons["RAID_TARGET_1"],
    ["RAID_TARGET_2"] = UnitPopupButtons["RAID_TARGET_2"],
    ["RAID_TARGET_3"] = UnitPopupButtons["RAID_TARGET_3"],
    ["RAID_TARGET_4"] = UnitPopupButtons["RAID_TARGET_4"],
    ["RAID_TARGET_5"] = UnitPopupButtons["RAID_TARGET_5"],
    ["RAID_TARGET_6"] = UnitPopupButtons["RAID_TARGET_6"],
    ["RAID_TARGET_7"] = UnitPopupButtons["RAID_TARGET_7"],
    ["RAID_TARGET_8"] = UnitPopupButtons["RAID_TARGET_8"],             
}


function KHMRaidFrames:UpdateLayout()
    if not InCombatLockdown() then
        self:AddSubFrames()
    end  

    local isInRaid = IsInRaid() and "raid" or "party"

    for frame in self:IterateCompactFrames(isInRaid) do
        if frame then
            self:SetUpFrame(frame, isInRaid)
            self:SetUpRaidIcon(frame, isInRaid)            
            self:SetUpSubFrames(frame, isInRaid)
        end       
    end

    for group in self:IterateCompactGroups(isInRaid) do
        self:SetUpGroup(group, isInRaid)
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

function KHMRaidFrames:SetUpRaidIcon(frame, groupType)
    if not frame.unit then return end

    local db = self.db.profile[groupType]

    if not frame.raidIcon then
        frame.raidIcon = frame:CreateTexture(nil, "OVERLAY")
    end

    if not db.raidIcon.enabled then
        frame.raidIcon:Hide()
        return
    end

    local index = GetRaidTargetIndex(frame.unit)

    if index and index >= 1 and index <= 8 then
        local options = UnitPopupButtons["RAID_TARGET_"..index]
        local texture, tCoordLeft, tCoordRight, tCoordTop, tCoordBottom = options.icon, options.tCoordLeft, options.tCoordRight, options.tCoordTop, options.tCoordBottom

        frame.raidIcon:ClearAllPoints()

        frame.raidIcon:SetPoint(db.raidIcon.anchorPoint, frame, db.raidIcon.anchorPoint, db.raidIcon.xOffset, db.raidIcon.yOffset)
        frame.raidIcon:SetSize(db.raidIcon.size, db.raidIcon.size)

        frame.raidIcon:SetTexture(texture)

        frame.raidIcon:SetTexCoord(tCoordLeft, tCoordRight, tCoordTop, tCoordBottom)

        frame.raidIcon:Show()
    else
        frame.raidIcon:Hide()
    end  
end

function KHMRaidFrames:SetUpFrame(frame, groupType)
    local db = self.db.profile[groupType]

    if frame then
        frame.healthBar:SetStatusBarTexture(db.frames.texture, "BORDER")
    end
end

function KHMRaidFrames:SetUpGroup(frame, groupType)
    if InCombatLockdown() then return end
    if not frame then return end

    local db = self.db.profile[groupType]

    local totalHeight, totalWidth 

    if db.frames.hideGroupTitles then
        frame.title:Hide()

        totalHeight, totalWidth = self:ResizeGroups(frame, 0)          
    else
        totalHeight, totalWidth = self:ResizeGroups(frame, -frame.title:GetHeight()) 

        frame.title:Show()
    end
    
    if frame.borderFrame:IsShown() then
        totalWidth = totalWidth + 12
        totalHeight = totalHeight + 4
    end

    frame:SetSize(totalWidth, totalHeight)
end                    

function KHMRaidFrames:ResizeGroups(frame, yOffset)
    local totalHeight = frame.title:GetHeight()
    local totalWidth = 0

    if self.horizontalGroups then
        frame.title:ClearAllPoints()
        frame.title:SetPoint("TOPLEFT")

        local frame1 = _G[frame:GetName().."Member1"];
        frame1:ClearAllPoints()
        frame1:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, yOffset)
        
        for i=2, 5 do
            local unitFrame = _G[frame:GetName().."Member"..i]
            unitFrame:ClearAllPoints()
            unitFrame:SetPoint("LEFT", _G[frame:GetName().."Member"..(i-1)], "RIGHT", 0, 0)
        end

        totalHeight = totalHeight + _G[frame:GetName().."Member1"]:GetHeight()
        totalWidth = totalWidth + _G[frame:GetName().."Member1"]:GetWidth() * 5
    else
        frame.title:ClearAllPoints()
        frame.title:SetPoint("TOP")

        local frame1 = _G[frame:GetName().."Member1"];
        frame1:ClearAllPoints()
        frame1:SetPoint("TOP", frame, "TOP", 0, yOffset)
        
        for i=2, 5 do
            local unitFrame = _G[frame:GetName().."Member"..i]
            unitFrame:ClearAllPoints()
            unitFrame:SetPoint("TOP", _G[frame:GetName().."Member"..(i-1)], "BOTTOM", 0, 0)
        end

        totalHeight = totalHeight + _G[frame:GetName().."Member1"]:GetHeight() * 5
        totalWidth = totalWidth + _G[frame:GetName().."Member1"]:GetWidth()
    end

    return totalHeight, totalWidth           
end