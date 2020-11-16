local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local tonumber, tostring = tonumber, tostring


function KHMRaidFrames:StartGlow(frame, db, color)
    if frame.__glowing then return end

    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options
    local color = color or options.color

    if glowType == "button" then
        glowOptions.start(frame, color, options.frequency)
    elseif glowType == "pixel" then
        glowOptions.start(frame, color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border)    
    elseif glowType == "auto" then
        glowOptions.start(frame, color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset)
    end

    frame.__glowing = true
end

function KHMRaidFrames:StopGlow(frame, db)  
    if not frame.__glowing then return end
 
    db.options[db.type].stop(frame)

    frame.__glowing = nil
end