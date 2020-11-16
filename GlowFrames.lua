local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local tonumber, tostring = tonumber, tostring
local defuffsColors = {
    magic = {0.2, 0.6, 1.0, 1},
    curse = {0.6, 0.0, 1.0, 1},
    disease = {0.6, 0.4, 0.0, 1},
    poison = {0.0, 0.6, 0.0, 1},
    physical = {1, 1, 1, 1}
}


function KHMRaidFrames:StartGlow(frame, db, color)
    if frame.glowing and not self.isOpen then return end

    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options
    local color = color or options.color

    if glowType == "button" then
        glowOptions.start(frame, colorr, options.frequency)
    elseif glowType == "pixel" then
        glowOptions.start(frame, color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border)
    elseif glowType == "auto" then
        glowOptions.start(frame, color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset)
    end

    frame.glowing = true
end

function KHMRaidFrames:StopGlow(frame, db)
    if not frame.glowing and not self.isOpen then return end

    db.options[db.type].stop(frame)

    frame.glowing = false
end

function KHMRaidFrames:FilterGlowAuras(frame, name, debuffType, spellId, frameType)
    local db = self.db.profile.glows.auraGlow[frameType]

    local found = false
    local frameName = frame:GetParent():GetName()

    if self.db.profile.glows.auraGlow[frameType].enabled or self.db.profile.glows.frameGlow[frameType].enabled then
        name = name and name:lower()
        debuffType = debuffType and debuffType:lower() or "physical"

        for _, aura in ipairs(db.tracking) do
            if (
                aura ~= nil and 
                (aura == name or (aura == debuffType) or 
                (spellId ~= nil and tonumber(aura) == spellId))
            ) then                
                found = true
                break
            end
        end

        local color = db.useDefaultsColors and defuffsColors[debuffType]

        if found and db.enabled then
            self:StartGlow(frame, db, color)
        elseif not found and db.enabled then
            self:StopGlow(frame, db)
        end

        local cache = self.aurasCache[frameType][frameName]

        self:CheckNil(cache, name, debuffType)
        self:CheckNil(cache, debuffType, debuffType)
        self:CheckNil(cache, tostring(spellId), debuffType)        
    end
end

function KHMRaidFrames:FinishGlows(frame, indexes)
    for subFrame in self:IterateSubFrameTypes("dispelDebuffFrames") do
        local db = self.db.profile.glows.auraGlow[subFrame]

        if db.enabled then
            for i=indexes[subFrame], #frame[subFrame] do
                self:StopGlow(frame[subFrame][i], db)
            end
        end
    end

    self:SetFrameGlow(frame)
end

function KHMRaidFrames:SetFrameGlow(frame)
    local frameName = frame:GetName()

    for frameType in self:IterateSubFrameTypes("dispelDebuffFrames") do
        local db = self.db.profile.glows.frameGlow[frameType]

        if db.enabled then
            for _, aura in ipairs(db.tracking) do
                if self.aurasCache[frameType][frameName][aura] then
                    local color = db.useDefaultsColors and defuffsColors[self.aurasCache[frameType][frameName][aura]]
                    return self:StartGlow(frame, db, color)
                end
            end

            self:StopGlow(frame, db)
        end
    end
end