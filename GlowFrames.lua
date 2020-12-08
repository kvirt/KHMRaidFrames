local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local LCG = LibStub("LibCustomGlow-1.0")

local tonumber, tostring = tonumber, tostring


function KHMRaidFrames:StartGlow(frame, db, color, key, gType)
    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options
    local color = color or options.color

    if glowType == "button" then
        LCG.ButtonGlow_Start(frame, color, options.frequency)
    elseif glowType == "pixel" then
        LCG.PixelGlow_Start(frame, color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border, key or "")
    elseif glowType == "auto" then
        LCG.AutoCastGlow_Start(frame, color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset, key or "")
    end

    self.glowingFrames[gType][key][frame] = color
end

function KHMRaidFrames:StopGlow(frame, db, key, gType)
    if db.type == "button" then
        LCG.ButtonGlow_Stop(frame, key or "")
    elseif db.type == "pixel" then
        LCG.PixelGlow_Stop(frame, key or "")
    elseif db.type == "auto" then
        LCG.AutoCastGlow_Stop(frame, key or "")
    end

    self.glowingFrames[gType][key][frame] = nil
end