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


function KHMRaidFrames:UpdateRaidMark()
    for frame in self:IterateCompactFrames("raid") do
        self:SetUpRaidIcon(frame, "raid") 
    end

    for frame in self:IterateCompactFrames("party") do
        self:SetUpRaidIcon(frame, "party") 
    end      
end

function KHMRaidFrames:SetUpSubFramesPositionsAndSize(frame, typedframes, db, groupType, resize)
    local frameNum = 1
    local typedframe, anchor1, anchor2, relativeFrame, xOffset, yOffset

    while frameNum <= #typedframes do
        typedframe = typedframes[frameNum]
        typedframe:ClearAllPoints()

        if frameNum == 1 then
            anchor1, relativeFrame, anchor2 = db.anchorPoint, frame, db.anchorPoint
        elseif frameNum % (db.numInRow) == 1 then
            anchor1, relativeFrame, anchor2 = self.rowsPositions[db.rowsGrowDirection][1], typedframes[frameNum - db.numInRow], self.rowsPositions[db.rowsGrowDirection][2]
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
        
        typedframe:SetSize(db.size * resize, db.size * resize)
        
        if self.db.profile[groupType].frames.clickThrough then
            typedframe:EnableMouse(false)
        else
            typedframe:EnableMouse(true)
        end

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

    if index == "NONE" then
        index = 0
    else
        index = tonumber(index)
    end    

    if index and index >= 1 and index <= 8 then
        local options = UnitPopupButtons["RAID_TARGET_"..index]
        local texture, tCoordLeft, tCoordRight, tCoordTop, tCoordBottom = options.icon, options.tCoordLeft, options.tCoordRight, options.tCoordTop, options.tCoordBottom

        frame.raidIcon:ClearAllPoints()

        frame.raidIcon:SetPoint(db.raidIcon.anchorPoint, frame, db.raidIcon.anchorPoint, db.raidIcon.xOffset, db.raidIcon.yOffset)
        frame.raidIcon:SetSize(db.raidIcon.size * self.componentScale, db.raidIcon.size * self.componentScale)

        frame.raidIcon:SetTexture(texture)

        frame.raidIcon:SetTexCoord(tCoordLeft, tCoordRight, tCoordTop, tCoordBottom)

        frame.raidIcon:Show()
    else
        frame.raidIcon:Hide()
    end  
end                  

function KHMRaidFrames:ResizeGroups(frame, yOffset)
    local totalHeight, totalWidth = 0, 0

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

function KHMRaidFrames:SetUpAbsorb(frame)
    if not frame then return end

    if not self.db.profile[IsInRaid() and "raid" or "party"].frames.enhancedAbsorbs then return end   
     
    local absorbBar = frame.totalAbsorb
    if not absorbBar or absorbBar:IsForbidden()then return end
    
    local absorbOverlay = frame.totalAbsorbOverlay
    if not absorbOverlay or absorbOverlay:IsForbidden() or not absorbOverlay.tileSize then return end
    
    local healthBar = frame.healthBar
    if not healthBar or healthBar:IsForbidden() then return end
    
    local _, maxHealth = healthBar:GetMinMaxValues()
    if maxHealth <= 0 then return end

    if not frame.displayedUnit then return end

    local totalAbsorb = UnitGetTotalAbsorbs(frame.displayedUnit) or 0
    if totalAbsorb > maxHealth then
        totalAbsorb = maxHealth
    end
    
    local overAbsorbGlow = frame.overAbsorbGlow
    if overAbsorbGlow and not overAbsorbGlow:IsForbidden() then overAbsorbGlow:Hide() end

    if totalAbsorb > 0 then
        absorbOverlay:ClearAllPoints()

        if absorbBar:IsShown() then
            absorbOverlay:SetPoint("TOPRIGHT", absorbBar, "TOPRIGHT", 0, 0)
            absorbOverlay:SetPoint("BOTTOMRIGHT", absorbBar, "BOTTOMRIGHT", 0, 0)
        else
            absorbOverlay:SetPoint("TOPRIGHT", healthBar, "TOPRIGHT", 0, 0)
            absorbOverlay:SetPoint("BOTTOMRIGHT", healthBar, "BOTTOMRIGHT", 0, 0)             
        end

        local totalWidth, totalHeight = healthBar:GetSize()           
        local barSize = totalAbsorb / maxHealth * totalWidth

        absorbOverlay:SetWidth(barSize)
        absorbOverlay:SetTexCoord(0, barSize / absorbOverlay.tileSize, 0, totalHeight / absorbOverlay.tileSize)
        absorbBar:SetAlpha(0.5)
        absorbOverlay:Show()
    end  
end

function KHMRaidFrames:SetUpSoloFrame()
    if self.db.profile.party.frames.showPartySolo then
        if not self.ticker or self.ticker:IsCancelled() then
            self.ticker = C_Timer.NewTicker(1, function() self:ShowRaidFrame() end)
        end
    elseif not self.db.profile.party.frames.showPartySolo and self.ticker then
        self.ticker:Cancel()
    end
end

function KHMRaidFrames:SetUpName(frame, groupType)
    if not frame.unit then return end

    local db = self.db.profile[groupType].nameAndIcons.name
    local name = frame.name
    local size = db.size * self.componentScale

    local flags = ""

    for k, v in pairs(db.flags) do
        if v then flags = flags..k..", " end
    end

    name:ClearAllPoints()

    local _name

    if db.showServer and frame.unit then
        _name = GetUnitName(frame.unit, true)
    else
        _name = GetUnitName(frame.unit, false)
        _name = _name and _name:gsub("%p", "")
    end

    name:SetText(_name)

    name:SetFont(
        self.fonts[db.font], 
        size,
        flags
    )

    xOffset, yOffset = self:Offsets(db.anchorPoint)
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset

    name:SetPoint(
        "TOPLEFT", 
        frame, 
        "TOPLEFT", 
        xOffset, 
        yOffset
    )

    name:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    name:SetJustifyH(db.hJustify)
end

function KHMRaidFrames:SetUpStatusText(frame, groupType)
    local db = self.db.profile[groupType].nameAndIcons.statusText
    local statusText = frame.statusText
    local size = db.size * self.componentScale

    local flags = ""

    for k, v in pairs(db.flags) do
        if v then flags = flags..k..", " end
    end

    statusText:ClearAllPoints()

    statusText:SetFont(
        self.fonts[db.font], 
        size,
        flags
    )

    xOffset, yOffset = self:Offsets(db.anchorPoint)
    xOffset = xOffset + db.xOffset
    yOffset = yOffset + db.yOffset + ((self.frameHeight / 3) - 2)

    statusText:SetPoint(
        "BOTTOMLEFT", 
        frame, 
        "BOTTOMLEFT", 
        xOffset, 
        yOffset
    )

    statusText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", xOffset, yOffset)
    statusText:SetJustifyH(db.hJustify)   
end