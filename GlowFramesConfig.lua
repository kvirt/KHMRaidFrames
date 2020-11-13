local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")
local LCG = LibStub("LibCustomGlow-1.0")

function KHMRaidFrames:GetGlowOptions(key)
    local options = {
        pixel = {
            options = {
                color = {0.95, 0.95, 0.32, 1},
                N = 8,
                length = false,
                frequency = 0.25,
                th = 2,
                xOffset = 0,
                yOffset = 0,
                border = false,
            },
            start = LCG.PixelGlow_Start,
            stop = LCG.PixelGlow_Stop,   
        },
        auto = {
            options = {
                color = {0.95, 0.95, 0.32, 1},
                N = 4,
                frequency = 0.125,
                scale = 1,
                xOffset = 0,
                yOffset = 0,
            },            
            start = LCG.AutoCastGlow_Start,
            stop = LCG.AutoCastGlow_Stop,                       
        },
        button = {
            options = {
                color = {0.95, 0.95, 0.32, 1},
                frequency = 0.125,
            },          
            start = LCG.ButtonGlow_Start,
            stop = LCG.ButtonGlow_Stop,                   
        },      
    }
    if key and options[key] then return options[key] else return options end
end

function KHMRaidFrames:SetupGlowOptionsProxy(frameType, db, groupType)
    db = db[frameType]

    local options = {}

    options.glow = {
        type = "group",
        order = 2,
        name = L["Aura Glow"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupGlowOptions("glow", db, groupType, frameType),     
    }
    options.frameGlow = {
        type = "group",
        order = 3,
        name = L["Frame Glow"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupGlowOptions("frameGlow", db, groupType, frameType),        
    }

    return options
end

function KHMRaidFrames:SetupGlowOptions(glowType, db, groupType, frameType)
    db = db[glowType]

    local frameName = glowType..frameType

    local options = {
        ["enabled"..frameName] = {
            name = L["Enabled"],
            desc = "",
            descStyle = "inline",
            width = "double",
            type = "toggle",
            order = 1,          
            set = function(info,val)
                db.enabled = val
                if not val then
                    self:StopOptionsAuraGlows(frameType, groupType, db)
                    self:StopOptionsFramesGlows(frameType, groupType, db)
                end

                self:RefreshConfig()
            end,
            get = function(info) return db.enabled end
        },
        ["useDefaultsColors"..frameName] = {
            name = L["Use Default Colors"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "toggle",
            order = 2,
            disabled = function(info)
                return not db.enabled
            end,                       
            set = function(info,val)
                db.useDefaultsColors = val
                self:RefreshConfig()
            end,
            get = function(info) return db.useDefaultsColors end
        },              
        ["glowType"..frameName] = {
            name = L["Glow Type"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "select",
            order = 2,
            disabled = function(info)
                return not db.enabled
            end,
            values = function(info, val)
                return {
                    pixel = "pixel", 
                    auto = "auto", 
                    button = "button",
                }
            end,      
            set = function(info,val)
                db.type = val
                self:StopOptionsAuraGlows(frameType, groupType, db)
                self:StopOptionsFramesGlows(frameType, groupType, db)

                self:RefreshConfig()
            end,
            get = function(info) return db.type end
        },
        ["color"..frameName] = {
            name = L["Color"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "color",
            order = 2,
            hasAlpha = true,
            disabled = function(info)
                return not db.enabled or db.useDefaultsColors
            end,                     
            set = function(info, r, g, b, a)
                db.options[db.type].options.color = {r, g, b, a}
                self:RefreshConfig()
            end,
            get = function(info)
                local color = db.options[db.type].options.color
                return color[1], color[2], color[3], color[4]
            end
        },               
        ["frequency"..frameName] = {
            name = L["Frequency"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = -1,
            max = 1,
            step = 0.01,
            order = 2,
            disabled = function(info)
                return not db.enabled
            end,                    
            set = function(info,val)
                db.options[db.type].options.frequency = val
                self:RefreshConfig()
            end,
            get = function(info) return db.options[db.type].options.frequency end
        },
        [frameName.."Skip"] = {
            type = "header",
            name = "",
            order = 3,
        },         
        ["num"..frameName] = {
            name = L["Num"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = 1,
            max = 20,
            step = 1,
            order = 4,
            disabled = function(info)
                return not db.enabled
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.type)
                if options.options["N"] ~= nil then return false else return true end
            end,                  
            set = function(info,val)
                db.options[db.type].options.N = val
                self:RefreshConfig()
            end,
            get = function(info) return db.options[db.type].options.N end
        },
        ["xOffset"..frameName] = {
            name = L["X Offset"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 5,
            disabled = function(info)
                return not db.enabled
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.type)
                if options.options["xOffset"] ~= nil then return false else return true end
            end,                     
            set = function(info,val)
                db.options[db.type].options.xOffset = val
                self:RefreshConfig()
            end,
            get = function(info) return db.options[db.type].options.xOffset end
        },
       ["yOffset"..frameName] = {
            name = L["Y Offset"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 6,
            disabled = function(info)
                return not db.enabled
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.type)
                if options.options["yOffset"] ~= nil then return false else return true end
            end,                     
            set = function(info,val)
                db.options[db.type].options.yOffset = val
                self:RefreshConfig()
            end,
            get = function(info) return db.options[db.type].options.yOffset end
        },
        ["th"..frameName] = {
            name = L["Thickness"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = 0.1,
            max = 10,
            step = 0.1,
            order = 7,
            disabled = function(info)
                return not db.enabled
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.type)
                if options.options["th"] ~= nil then return false else return true end
            end,                       
            set = function(info,val)
                db.options[db.type].options.th = val
                self:RefreshConfig()
            end,
            get = function(info) return db.options[db.type].options.th end
        },      
        ["border"..frameName] = {
            name = L["Border"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "toggle",
            order = 8,
            disabled = function(info)
                return not db.enabled
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.type)
                if options.options["border"] ~= nil then return false else return true end
            end,                       
            set = function(info,val)
                db.options[db.type].options.border = val
                self:RefreshConfig()
            end,
            get = function(info) return db.options[db.type].options.border end
        },
        [frameName.."Skip2"] = {
            type = "header",
            name = "",
            order = 9,
            hidden = function(info)
                local options = self:GetGlowOptions(db.type)
                if options.options["N"] ~= nil then return false else return true end
            end,             
        },                                        
        ["tracking"..frameName] = {
            name = L["Tracking"],
            desc = L["Use to block auras"],
            width = "full",
            type = "input",
            usage = self:TrackingHelpText(),
            multiline = 5, 
            order = 10,
            disabled = function(info)
                return not db.enabled
            end,                 
            set = function(info,val)
                db.tracking = self:SanitizeStrings(val)
                db.trackingStr = val

                self:SafeRefresh()
            end,
            get = function(info)
                return db.trackingStr
            end             
        },
        [frameType.."Skip"] = {
            type = "header",
            name = "",
            order = 11,
        },                                       
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "execute",
            confirm = true,
            order = 12,
            func = function(info,val)
                self:RestoreGlowDefaults(groupType, frameType, glowType)
                self:StopOptionsAuraGlows(frameType, groupType, db)
                self:StopOptionsFramesGlows(frameType, groupType, db)                
            end,
        },                                 
    }
    return options
end

function KHMRaidFrames:RestoreGlowDefaults(groupType, frameType, glowType)
    if InCombatLockdown() then
        print("Can not refresh settings while in combat")      
        return
    end

    local defaults_settings = self:Defaults()["profile"][groupType][frameType][glowType]

    for k, v in pairs(defaults_settings) do
        self.db.profile[groupType][frameType][glowType][k] = v
    end

    self:SafeRefresh()
end

function KHMRaidFrames:StopOptionsAuraGlows(frameType, groupType, db)
    local db = self.db.profile[groupType][frameType].glow

    if groupType == "raid" then
        for frame in self:IterateRaidMembers() do
            for i=1, #frame[frameType] do
                self:StopOptionsGlow(frame[frameType][i], db)
            end        
        end
    else
        for frame in self:IterateGroupMembers() do
            for i=1, #frame[frameType] do
                self:StopOptionsGlow(frame[frameType][i], db)
            end          
        end
    end
end

function KHMRaidFrames:StopOptionsFramesGlows(frameType, groupType, db)
    local db = self.db.profile[groupType][frameType].frameGlow

    if groupType == "raid" then
        for frame in self:IterateRaidMembers() do
            self:StopOptionsGlow(frame, db)
        end
    else
        for frame in self:IterateGroupMembers() do
            self:StopOptionsGlow(frame, db)         
        end
    end
end

function KHMRaidFrames:StopOptionsGlow(frame, db)
    if not frame.glowing or not self.isOpen then return end

    for _, glowType in pairs{"pixel", "auto", "button"} do
        db.options[glowType].stop(frame)
    end

    frame.glowing = false
end