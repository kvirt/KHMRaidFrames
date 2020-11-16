local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")

local _G, tinsert, CompactRaidFrameContainer = _G, tinsert, CompactRaidFrameContainer
local NATIVE_UNIT_FRAME_HEIGHT = 36
local NATIVE_UNIT_FRAME_WIDTH = 72   


function KHMRaidFrames:Defaults()
    local componentScale = min(self.frameHeight / NATIVE_UNIT_FRAME_HEIGHT, self.frameWidth / NATIVE_UNIT_FRAME_WIDTH)

    local buffSize = 11 * componentScale
    local defaults_settings = {profile = {party = {}, raid = {}, glows = {}}}

    local commons = {
            frames = {
                hideGroupTitles = false,
                texture = "Blizzard Raid Bar",                
            },        
            dispelDebuffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",
                anchorPoint = "TOPRIGHT",
                growDirection = "LEFT",
                size = 12,
                xOffset = 0,
                yOffset = 0,
                exclude = {},
                excludeStr = "",                            
            },
            debuffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",                
                anchorPoint = "BOTTOMLEFT",
                growDirection = "RIGHT",
                size = buffSize,
                xOffset = 0,
                yOffset = 0,
                exclude = {},
                excludeStr = "",                                               
            },
            buffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",                  
                anchorPoint = "BOTTOMRIGHT",
                growDirection = "LEFT",
                size = buffSize,
                xOffset = 0,
                yOffset = 0,
                exclude = {},
                excludeStr = "",                                               
            },
            raidIcon = {
                enabled = true,
                size = 30,
                xOffset = 0,
                yOffset = 0,
                anchorPoint = "TOP",
            },      
    }
    defaults_settings.profile.party = commons
    defaults_settings.profile.raid = commons

    defaults_settings.profile.glows = {
        auraGlow = {
            buffFrames = {
                type = "pixel",
                options = self.GetGlowOptions(),
                tracking = {},
                trackingStr = "",    
                enabled = false,
                useDefaultsColors = true,                
            },
            debuffFrames = {
                type = "pixel",
                options = self.GetGlowOptions(),
                tracking = {},
                trackingStr = "",    
                enabled = false,
                useDefaultsColors = true,                
            },
        },
        frameGlow = {
            buffFrames = {
                type = "pixel",
                options = self.GetGlowOptions(),
                tracking = {},
                trackingStr = "",    
                enabled = false,
                useDefaultsColors = true,                
            },
            debuffFrames = {
                type = "pixel",
                options = self.GetGlowOptions(),
                tracking = {},
                trackingStr = "",    
                enabled = false,
                useDefaultsColors = true,                
            },                                                         
        },
    }

    return defaults_settings
end

function KHMRaidFrames:RestoreDefaults(groupType, frameType)
    if InCombatLockdown() then
        print("Can not refresh settings while in combat")      
        return
    end

    local defaults_settings = self:Defaults()["profile"][groupType][frameType]

    for k, v in pairs(defaults_settings) do
        self.db.profile[groupType][frameType][k] = v
    end

    self:SafeRefresh(groupType)
end

function KHMRaidFrames:CUFDefaults(groupType)
    local deferred
    local isInCombatLockDown = InCombatLockdown()

    for group in self:IterateCompactGroups(groupType) do
        if self.processedFrames[group] == nil then
            deferred = self:DefaultGroupSetUp(group, groupType, isInCombatLockDown)

            if deferred == false then 
                self.processedFrames[group] = true
            end
        end
    end

    for frame in self:IterateCompactFrames(groupType) do
        if self.processedFrames[frame] == nil then
            deferred = self:DefaultFrameSetUp(frame, groupType, isInCombatLockDown)

            if deferred == false then 
                self.processedFrames[frame] = true
            end
        end
    end
end

function KHMRaidFrames:DefaultGroupSetUp(frame, groupType, isInCombatLockDown)
    local db = self.db.profile[groupType]

    local deferred = false

    if not isInCombatLockDown then
        local totalHeight, totalWidth = 0, 0

        if db.frames.hideGroupTitles then
            frame.title:Hide()    
            totalHeight, totalWidth = self:ResizeGroups(frame, 0)
        else
            frame.title:Show()               
            totalHeight, totalWidth = self:ResizeGroups(frame, -frame.title:GetHeight())
            totalHeight = totalHeight + frame.title:GetHeight() 
        end
        
        if frame.borderFrame:IsShown() then
            totalWidth = totalWidth + 12
            totalHeight = totalHeight + 4
        end

        frame:SetSize(totalWidth, totalHeight)
    else
        deferred = true
    end  

    return deferred
end

function KHMRaidFrames:DefaultFrameSetUp(frame, groupType, isInCombatLockDown)
    local db = self.db.profile[groupType]
    local deferred = false

    if not isInCombatLockDown then
        self:AddSubFrames(frame, groupType)
    else
        deferred = true   
    end 

    self:SetUpSubFramesPositionsAndSize(frame, frame.buffFrames, db.buffFrames)
    self:SetUpSubFramesPositionsAndSize(frame, frame.debuffFrames, db.debuffFrames)
    self:SetUpSubFramesPositionsAndSize(frame, frame.dispelDebuffFrames, db.dispelDebuffFrames)

    self:SetUpRaidIcon(frame, groupType)

    frame.healthBar:SetStatusBarTexture(self.textures[db.frames.texture], "BORDER")

    return deferred
end