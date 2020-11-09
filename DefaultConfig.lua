local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")

local _G = _G
local options = DefaultCompactUnitFrameSetupOptions
local powerBarHeight = 8
local powerBarUsedHeight = options.displayPowerBar and powerBarHeight or 0
local CUF_AURA_BOTTOM_OFFSET = 2
local yOffset = CUF_AURA_BOTTOM_OFFSET + powerBarUsedHeight

function KHMRaidFrames:GetFrameScale()
    local width, height = 72, 36

    return min(options.height / height, options.width / width)
end

function KHMRaidFrames:Defaults()
    local buffSize = 11 * self:GetFrameScale()
    local defaults_settings = {profile = {party = {}, raid = {}}}

    local commons = {
            frames = {
                hideGroupTitles = false,
                texture = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",                
            },        
            dispelDebuffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",
                anchorPoint = "TOPRIGHT",
                growDirection = "LEFT",
                size = 12,
                xOffset = -3,
                yOffset = -2,
                exclude = {},
                tracking = {},               
                glow = {
                    type = "pixel",
                    options = self:GetGlowOptions(),
                    exclude = {},
                    tracking = {
                        "magic",
                        "poison",
                        "curse",
                        "disease",
                    },
                    enabledFor = "None",
                },
            },
            debuffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",                
                anchorPoint = "BOTTOMLEFT",
                growDirection = "RIGHT",
                size = buffSize,
                xOffset = 3,
                yOffset = yOffset,
                exclude = {},
                tracking = {},                  
                glow = {
                    type = "pixel",
                    options = self:GetGlowOptions(),
                    exclude = {},
                    tracking = {},
                    enabledFor = "None",                                          
                },             
            },
            buffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",                  
                anchorPoint = "BOTTOMRIGHT",
                growDirection = "LEFT",
                size = buffSize,
                xOffset = -3,
                yOffset = yOffset,
                exclude = {},
                tracking = {},                  
                glow = {
                    type = "pixel",
                    options = self:GetGlowOptions(),
                    exclude = {},
                    tracking = {},
                    enabledFor = "None",                                          
                },              
            },      
    }
    defaults_settings.profile.party = commons
    defaults_settings.profile.raid = commons

    return defaults_settings
end

function KHMRaidFrames:RestoreDefaults(partyType, frameType)
    if InCombatLockdown() then
        print("Can not refresh settings while in combat")      
        return
    end

    local defaults_settings = self:Defaults()["profile"][partyType][frameType]

    for k, v in pairs(defaults_settings) do
        self.db.profile[partyType][frameType][k] = v
    end

    self:RefreshConfig()
end
