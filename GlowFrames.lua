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

local glowEnabledFor = {
    None = L["None"],
    All = L["All"],
    SubFrame = L["SubFrame"],
    MainFrame = L["MainFrame"],
}

function KHMRaidFrames:SetupGlowOptions(frameType, db, partyType)
    local fullWidth = 2.6
    local thirdWidth = fullWidth / 3    

    db = db[frameType]
    local frameName = "glow"..frameType

    local options = {
        ["enabledFor"..frameName] = {
            name = L["Enabled For"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "select",
            values = glowEnabledFor,
            order = 1,          
            set = function(info,val)
                db.glow.enabledFor = val
                self:RefreshConfig()
            end,
            get = function(info) return db.glow.enabledFor end
        },          
        ["glowType"..frameName] = {
            name = L["Glow Type"],
            desc = "",
            descStyle = "inline",
            width = thirdWidth,
            type = "select",
            order = 2,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,
            values = function(info, val)
                return {
                    pixel = "pixel", 
                    auto = "auto", 
                    button = "button",
                }
            end,      
            set = function(info,val)
                db.glow.type = val
                self:RefreshConfig()
            end,
            get = function(info) return db.glow.type end
        },
        ["color"..frameName] = {
            name = L["Color"],
            desc = "",
            descStyle = "inline",
            width = thirdWidth,
            type = "color",
            order = 2,
            hasAlpha = true,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,                     
            set = function(info, r, g, b, a)
                db.glow.options[db.glow.type].options.color = {r, g, b, a}
                self:RefreshConfig()
            end,
            get = function(info)
                local color = db.glow.options[db.glow.type].options.color
                return color[1], color[2], color[3], color[4]
            end
        },        
        ["frequency"..frameName] = {
            name = L["Frequency"],
            desc = "",
            descStyle = "inline",
            width = thirdWidth,
            type = "range",
            min = -1,
            max = 1,
            step = 0.01,
            order = 2,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,                    
            set = function(info,val)
                db.glow.options[db.glow.type].options.frequency = val
                self:RefreshConfig()
            end,
            get = function(info) return db.glow.options[db.glow.type].options.frequency end
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
            width = "full",
            type = "range",
            min = 1,
            max = 50,
            step = 1,
            order = 4,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.glow.type)
                if options.options["N"] ~= nil then return false else return true end
            end,                  
            set = function(info,val)
                db.glow.options[db.glow.type].options.N = val
                self:RefreshConfig()
            end,
            get = function(info) return db.glow.options[db.glow.type].options.N end
        },
        ["th"..frameName] = {
            name = L["Thickness"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "range",
            min = 0.1,
            max = 10,
            step = 0.1,
            order = 5,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.glow.type)
                if options.options["th"] ~= nil then return false else return true end
            end,                       
            set = function(info,val)
                db.glow.options[db.glow.type].options.th = val
                self:RefreshConfig()
            end,
            get = function(info) return db.glow.options[db.glow.type].options.th end
        },
        ["xOffset"..frameName] = {
            name = L["X Offset"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 6,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.glow.type)
                if options.options["xOffset"] ~= nil then return false else return true end
            end,                     
            set = function(info,val)
                db.glow.options[db.glow.type].options.xOffset = val
                self:RefreshConfig()
            end,
            get = function(info) return db.glow.options[db.glow.type].options.xOffset end
        },
       ["yOffset"..frameName] = {
            name = L["Y Offset"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 7,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.glow.type)
                if options.options["yOffset"] ~= nil then return false else return true end
            end,                     
            set = function(info,val)
                db.glow.options[db.glow.type].options.yOffset = val
                self:RefreshConfig()
            end,
            get = function(info) return db.glow.options[db.glow.type].options.yOffset end
        },        
        ["border"..frameName] = {
            name = L["Border"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "toggle",
            order = 8,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,            
            hidden = function(info)
                local options = self:GetGlowOptions(db.glow.type)
                if options.options["border"] ~= nil then return false else return true end
            end,                       
            set = function(info,val)
                db.glow.options[db.glow.type].options.border = val
                self:RefreshConfig()
            end,
            get = function(info) return db.glow.options[db.glow.type].options.border end
        },
        [frameName.."Skip2"] = {
            type = "header",
            name = "",
            order = 9,
            hidden = function(info)
                local options = self:GetGlowOptions(db.glow.type)
                if options.options["N"] ~= nil then return false else return true end
            end,             
        },                                        
        ["tracking"..frameName] = {
            name = L["Tracking"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "input",
            multiline = true,
            order = 10,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,                 
            set = function(info,val)
                db.glow.tracking = {}
                local index = 1
                for value in string.gmatch(val, "[^\n]+") do
                    db.glow.tracking[index] = value
                    index = index + 1
                end
                self:RefreshConfig()
            end,
            get = function(info)
                local str = ""
                for _, value in ipairs(db.glow.tracking) do
                    str = str..value.."\n"
                end
                return str
            end            
        },
        ["exclude"..frameName] = {
            name = L["Exclude"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "input",
            multiline = true,
            order = 11,
            disabled = function(info)
                if db.glow.enabledFor == "None" then return true else return false end
            end,                   
            set = function(info,val)
                db.glow.exclude = {}
                local index = 1
                for value in string.gmatch(val, "[^\n]+") do
                    db.glow.exclude[index] = value
                    index = index + 1
                end
                self:RefreshConfig()
            end,
            get = function(info)
                local str = ""
                for _, value in ipairs(db.glow.exclude) do
                    str = str..value.."\n"
                end
                return str
            end
        },                          
    }
    return options
end

function KHMRaidFrames:CompactUnitFrame_UtilSetBuff(buffFrame, index, ...)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = ...

    self:FilterGlowAuras(buffFrame, name, debuffType, spellId, "buffFrames")
end

function KHMRaidFrames:CompactUnitFrame_UtilSetDebuff(debuffFrame, unit, index, filter, isBossAura, isBossBuff, ...)
    local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = ...

    self:FilterGlowAuras(debuffFrame, name, debuffType, spellId, "debuffFrames")
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
            self:StopGlowFrame(frame.buffFrames[i], frame, db)
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
            self:StopGlowFrame(frame.debuffFrames[i], frame, db)
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
            self:StopGlowFrame(frame.dispelDebuffFrames[i], frame, db)
        end
    end
end

function KHMRaidFrames:StartGlowFrameInternal(frame, options, glowType, start)
    if glowType == "button" then
        start(frame, options.color, options.frequency)
    elseif glowType == "pixel" then
        start(frame, options.color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border, options.key or "")
    elseif glowType == "auto" then
        start(frame, options.color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset, options.key or "")
    end
end

function KHMRaidFrames:StartGlowFrame(frame, parentframe, db)
    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options
    local start = glowOptions.start
    local parentGlow = false

    for k, v in pairs(self.framesAuras) do
        if v then 
            parentGlow = true 
            break 
        end
    end

    if db.enabledFor == "SubFrame" then
        self:StartGlowFrameInternal(frame, options, glowType, start)
    elseif db.enabledFor == "MainFrame" then
        if parentGlow then
            self:StartGlowFrameInternal(parentframe, options, glowType, start)
        end
    else
        self:StartGlowFrameInternal(frame, options, glowType, start)

        if parentGlow then
            self:StartGlowFrameInternal(parentframe, options, glowType, start)
        end
    end 
end

function KHMRaidFrames:StopGlowFrame(frame, parentFrame, db)
    local parentGlow = false

    for k, v in pairs(self.framesAuras) do
        if v then 
            parentGlow = true 
            break 
        end
    end

    if db.enabledFor == "SubFrame" then
        db.options[db.type].stop(frame)
    elseif db.enabledFor == "MainFrame" then
        if not parentGlow then
            db.options[db.type].stop(parentFrame)
        end
    else
        db.options[db.type].stop(frame)

        if not parentGlow then
            db.options[db.type].stop(parentFrame)
        end
    end    
end

function KHMRaidFrames:FilterGlowAuras(frame, name, debuffType, spellId, frameType)
    local db, excluded, tracked

    if IsInRaid() then
        db = self.db.profile.raid[frameType].glow
    else
        db = self.db.profile.party[frameType].glow
    end

    if db.enabledFor == "None" then
        return
    end

    local parentFrame = frame:GetParent()

    excluded = self:FilterGlowAurasInternal(name, debuffType, spellId, db.exclude, true)

    if exclude then
        self:StopGlowFrame(frame, parentFrame, db)
        return
    end

    tracked = self:FilterGlowAurasInternal(name, debuffType, spellId, db.tracking, false)

    if tracked then
        self:StartGlowFrame(frame, parentFrame, db)
    else
        self:StopGlowFrame(frame, parentFrame, db)
    end
end

function KHMRaidFrames:FilterGlowAurasInternal(name, debuffType, spellId, db, exclude)
    if #db == 0 then return not exclude end

    local found = false

    for _, aura in pairs(db) do
        if aura == name or aura == debuffType or tonumber(aura) == spellId then
            found = true
            self.framesAuras[aura] = not exclude
        else
            self.framesAuras[aura] = exclude
        end
    end
    
    return found
end