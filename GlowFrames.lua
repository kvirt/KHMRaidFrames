local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local tonumber, tostring = tonumber, tostring


function KHMRaidFrames:StartGlow(frame, db, color, key, gType)
    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options
    local color = color or options.color

    if glowType == "button" then
        glowOptions.start(frame, color, options.frequency)
    elseif glowType == "pixel" then
        glowOptions.start(frame, color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border, key or "")    
    elseif glowType == "auto" then
        glowOptions.start(frame, color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset, key or "")
    end

    self.glowingFrames[gType][key][frame] = color
end

function KHMRaidFrames:StopGlow(frame, db, key, gType)  
    db.options[db.type].stop(frame, key or "")

    self.glowingFrames[gType][key][frame] = nil

end