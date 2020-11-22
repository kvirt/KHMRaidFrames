local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")

local _G, tinsert, CompactRaidFrameContainer = _G, tinsert, CompactRaidFrameContainer
local NATIVE_UNIT_FRAME_HEIGHT = 36
local NATIVE_UNIT_FRAME_WIDTH = 72   

KHMRaidFrames.defuffsColors = {
    magic = {0.2, 0.6, 1.0, 1},
    curse = {0.6, 0.0, 1.0, 1},
    disease = {0.6, 0.4, 0.0, 1},
    poison = {0.0, 0.6, 0.0, 1},
    physical = {1, 1, 1, 1}
}

function KHMRaidFrames:Defaults()
    local componentScale = min(self.frameHeight / NATIVE_UNIT_FRAME_HEIGHT, self.frameWidth / NATIVE_UNIT_FRAME_WIDTH)

    local buffSize = 11 * componentScale
    local defaults_settings = {profile = {party = {}, raid = {}, glows = {}}}

    local commons = {
            frames = {
                hideGroupTitles = false,
                texture = "Blizzard Raid Bar",
                clickThrough = false,            
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
            defaultColors = self.defuffsColors,
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
            defaultColors = self.defuffsColors,                                                       
        },
        glowBlockList = {
            tracking = {},
            trackingStr = "",              
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

    if db.frames.hideGroupTitles then
        frame.title:Hide()    
    else
        frame.title:Show()
    end             
        
end

function KHMRaidFrames:DefaultFrameSetUp(frame, groupType, isInCombatLockDown)
    local db = self.db.profile[groupType]
    local deferred = false

    if not isInCombatLockDown then
        self:AddSubFrames(frame, groupType)
    else
        deferred = true   
    end 

    self:SetUpSubFramesPositionsAndSize(frame, frame.buffFrames, db.buffFrames, groupType)
    self:SetUpSubFramesPositionsAndSize(frame, frame.debuffFrames, db.debuffFrames, groupType)
    self:SetUpSubFramesPositionsAndSize(frame, frame.dispelDebuffFrames, db.dispelDebuffFrames, groupType)

    self:SetUpRaidIcon(frame, groupType)

    frame.healthBar:SetStatusBarTexture(self.textures[db.frames.texture], "BORDER")

    return deferred
end