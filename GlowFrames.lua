local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local tonumber, tostring = tonumber, tostring
local defuffsColors = {
    magic = {0.2, 0.6, 1.0, 1},
    curse = {0.6, 0.0, 1.0, 1},
    disease = {0.6, 0.4, 0.0, 1},
    poison = {0.0, 0.6, 0.0, 1},
    physical = {0.8, 0, 0, 1}
}


function KHMRaidFrames:StartGlow(frame, db, color)
    if self.isOpen then
        self:StopOptionsGlow(frame, db)
    end

    if frame.glowing then return end

    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options

    if glowType == "button" then
        glowOptions.start(frame, color or options.color, options.frequency)
    elseif glowType == "pixel" then
        glowOptions.start(frame, color or options.color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border)
    elseif glowType == "auto" then
        glowOptions.start(frame, color or options.color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset)
    end

    frame.glowing = true
end

function KHMRaidFrames:StopGlow(frame, db)
    if not frame.glowing and not self.isOpen then return end

    db.options[db.type].stop(frame)

    frame.glowing = false
end

function KHMRaidFrames:FilterGlowAuras(frame, name, debuffType, spellId, frameType)
    local db = self:GroupTypeDB()[frameType]

    local found = false
    local frameName = frame:GetParent():GetName()

    if db.glow.enabled or db.frameGlow.enabled then
        db = db.glow
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
    local db = self:GroupTypeDB()

    for subFrame in self:IterateSubFrameTypes() do
        local _db = db[subFrame].glow

        if db.enabled then
            for i=indexes[subFrame], #frame[subFrame] do
                self:StopGlow(frame[subFrame][i], db)
            end
        end
    end

    self:SetFrameGlow(frame)
end

function KHMRaidFrames:SetFrameGlow(frame)
    local db = self:GroupTypeDB()
    local frameName = frame:GetName()

    for subFrame in self:IterateSubFrameTypes() do
        local _db = db[subFrame].frameGlow

        if _db.enabled then
            for _, aura in ipairs(_db.tracking) do
                if self.aurasCache[subFrame][frameName][aura] then
                    local color = _db.useDefaultsColors and defuffsColors[self.aurasCache[subFrame][frameName][aura]]
                    return self:StartGlow(frame, _db, color)
                end
            end

            self:StopGlow(frame, _db)
        end
    end
end