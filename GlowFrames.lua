local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")
local LCG = LibStub("LibCustomGlow-1.0")
local tinsert = tinsert

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
            width = "full",
            type = "toggle",
            order = 1,          
            set = function(info,val)
                db.enabled = val
                self:StopGlows(groupType, frameType)
                self:RefreshConfig()
            end,
            get = function(info) return db.enabled end
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
                return not db.enabled
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
            max = 50,
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
    }
    return options
end

function KHMRaidFrames:CompactUnitFrame_UtilSetBuff(buffFrame, index, ...)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = ...

    self:FilterGlowAuras(buffFrame, name, debuffType, spellId, "buffFrames")
end

function KHMRaidFrames:CompactUnitFrame_UtilSetDispelDebuff(dispellDebuffFrame, debuffType, index)
    self:FilterGlowAuras(dispellDebuffFrame, nil, debuffType, nil, "dispelDebuffFrames")
end

function KHMRaidFrames:CompactUnitFrame_HideAllBuffs(frame, startingIndex)
    if IsInRaid() then
        db = self.db.profile.raid.buffFrames.glow
    else
        db = self.db.profile.party.buffFrames.glow
    end

    if frame.buffFrames then
        for i=startingIndex or 1, #frame.buffFrames do
            self:StopGlowFrame(frame.buffFrames[i], db, "buffFrames")
        end
    end
end

function KHMRaidFrames:CompactUnitFrame_HideAllDebuffs(frame, startingIndex)
    if IsInRaid() then
        db = self.db.profile.raid.debuffFrames.glow
    else
        db = self.db.profile.party.debuffFrames.glow
    end

    if frame.debuffFrames then
        for i=startingIndex or 1, #frame.debuffFrames do
            self:StopGlowFrame(frame.debuffFrames[i], db, "debuffFrames")
        end
    end
end

function KHMRaidFrames:CompactUnitFrame_HideAllDispelDebuffs(frame, startingIndex)
    if IsInRaid() then
        db = self.db.profile.raid.dispelDebuffFrames.glow
    else
        db = self.db.profile.party.dispelDebuffFrames.glow
    end
    
    if frame.dispelDebuffFrames then
        for i=startingIndex or 1, #frame.dispelDebuffFrames do
            self:StopGlowFrame(frame.dispelDebuffFrames[i], db, "dispelDebuffFrames")
        end
    end
end

function KHMRaidFrames:StartGlowFrameInternal(frame, options, glowType, start, frameType)
    if glowType == "button" then
        start(frame, options.color, options.frequency)
    elseif glowType == "pixel" then
        start(frame, options.color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border, options.key or "")
    elseif glowType == "auto" then
        start(frame, options.color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset, options.key or "")
    end

    self.glowingFrames[frame:GetName()..frameType] = true
end

function KHMRaidFrames:StartGlowFrame(frame, db, frameType)
    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options
    local start = glowOptions.start

    self:StartGlowFrameInternal(frame, options, glowType, start, frameType)
end

function KHMRaidFrames:StopGlows(groupType, frameType)
    local len = 0

    for k, v in pairs(self.glowingFrames) do
        len = len + 1
    end

    if len == 0 then return end

    local db = self.db.profile[groupType][frameType].glow

    for frame, _ in pairs(self.glowingFrames) do
        if frame and frame:GetName() and frame:GetParent() then 
            self:StopGlowFrame(frame, db, frameType) 
        end
    end
end

function KHMRaidFrames:StopGlowFrame(frame, db, frameType)
    db.options[db.type].stop(frame)

    self.glowingFrames[frame:GetName()..frameType] = nil
end

function KHMRaidFrames:FilterGlowAuras(frame, name, debuffType, spellId, frameType)
    if not frame or not frame:GetName() or not frame:GetParent() then return end

    local db, tracked

    if IsInRaid() then
        db = self.db.profile.raid[frameType]
    else
        db = self.db.profile.party[frameType]
    end

    self:FilterGlowSubFrameAuras(frame, db.glow, name, debuffType, spellId, frameType)
    self:FilterGlowFrameAuras(frame:GetParent(), db.frameGlow, frameType)
end

function KHMRaidFrames:FilterGlowSubFrameAuras(frame, db, name, debuffType, spellId, frameType)
    if db.enabled then
        tracked = self:FilterGlowAurasInternal(name, debuffType, spellId, db.tracking)

        if tracked then
            self:StartGlowFrame(frame, db, frameType)
        else
            self:StopGlowFrame(frame, db, frameType)
        end
    end
end

function KHMRaidFrames:FilterGlowFrameAuras(frame, db, frameType)
    if db.enabled then
        tracked = self:FilterGlowAurasInternalThrottle(frame.unit, db.tracking, frameType)

        if tracked then
            self:StartGlowFrame(frame, db, frameType)
        else
            self:StopGlowFrame(frame, db, frameType)
        end
    end
end

function KHMRaidFrames:FilterGlowAurasInternal(name, debuffType, spellId, db)
    if #db == 0 then return false end 

    name = name and name:lower()
    debuffType = debuffType and debuffType:lower()

    for _, aura in ipairs(db) do
        print(aura)
        if aura ~= nil and (aura == name or aura == debuffType or (spellId ~= nil and tonumber(aura) == spellId)) then
            return true
        end
    end
    
    return false
end

function KHMRaidFrames:FilterGlowAurasInternalThrottle(unit, db, frameType)
    if #db == 0 then return false end

    local name, debuffType, spellId, found

    for i=1, 40 do
        if frameType == "buffFrames" then
            name, _, _, debuffType, _, _, _, _, _, spellId = UnitBuff(unit, i)
        else
            name, _, _, debuffType, _, _, _, _, _, spellId = UnitDebuff(unit, i)
        end

        name = name and name:lower()
        debuffType = debuffType and debuffType:lower()

        for _, aura in ipairs(db) do
            print(aura)
            if aura ~= nil and (aura == name or aura == debuffType or (spellId ~= nil and tonumber(aura) == spellId)) then
                found = true
                break
            end
        end

        if found then break end
    end

    return found
end