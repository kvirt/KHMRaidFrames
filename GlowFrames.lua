local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")


function KHMRaidFrames:FilterGlowAurasInternal(trackingAuras, name, debuffType, spellId)
    if #trackingAuras == 0 then return false end 

    local found = false

    name = name and name:lower()
    debuffType = debuffType and debuffType:lower()

    for _, aura in ipairs(trackingAuras) do
        if aura ~= nil and (aura == name or aura == debuffType or (spellId ~= nil and tonumber(aura) == spellId)) then
            found = true
        end
    end
    
    return found
end

function KHMRaidFrames:StartGlow(frame, db)
    if frame.glowing and not self.isOpen then return end

    local glowType = db.type
    local glowOptions = db.options[glowType]
    local options = glowOptions.options

    if glowType == "button" then
        glowOptions.start(frame, options.color, options.frequency)
    elseif glowType == "pixel" then
        glowOptions.start(frame, options.color, options.N, options.frequency, options.length, options.th, options.xOffset, options.yOffset, options.border)
    elseif glowType == "auto" then
        glowOptions.start(frame, options.color, options.N, options.frequency, options.scale, options.xOffset, options.yOffset)
    end

    frame.glowing = true
end

function KHMRaidFrames:StopGlow(frame, db)
    if not frame.glowing and not self.isOpen then return end

    db.options[db.type].stop(frame)

    frame.glowing = false
end

function KHMRaidFrames:FilterDispelDebuffFrameGlowAuras(frame, debuffType)
    local db = self:GroupTypeDB().dispelDebuffFrames.glow

    local found = false
    local frameName = frame:GetParent():GetName()

    if db.enabled then
        if #db.tracking ~= 0 then 
            debuffType = debuffType and debuffType:lower()

            for _, aura in ipairs(db.tracking) do
                if aura ~= nil and aura == debuffType then
                    found = true
                    break
                end
            end
        end

        self.aurasCache.dispelDebuffFrames[frameName][debuffType] = true

        if found then
            self:StartGlow(frame, db)
        else
            self:StopGlow(frame, db)
        end
    end
end

function KHMRaidFrames:FilterDebuffFrameGlowAuras(frame, name, debuffType, spellId)
    local db = self:GroupTypeDB().debuffFrames

    local found = false
    local frameName = frame:GetParent():GetName()

    if db.glow.enabled or db.frameGlow.enabled then
        db = db.glow
        if #db.tracking > 0 then 
            name = name and name:lower()
            debuffType = debuffType and debuffType:lower()

            for _, aura in ipairs(db.tracking) do
                if aura ~= nil and (aura == name or aura == debuffType or (spellId ~= nil and tonumber(aura) == spellId)) then                
                    found = true
                    break
                end
            end

            self:CheckNil(self.aurasCache.debuffFrames[frameName], name, true)
            self:CheckNil(self.aurasCache.debuffFrames[frameName], debuffType, true)
            self:CheckNil(self.aurasCache.debuffFrames[frameName], spellId, true)

            if found and db.enabled then
                self:StartGlow(frame, db)
            elseif not found and db.enabled then
                self:StopGlow(frame, db)
            end
        end
    end
end

function KHMRaidFrames:FilterBuffFrameGlowAuras(frame, name, debuffType, spellId)
    local db = self:GroupTypeDB().buffFrames

    local found = false
    local frameName = frame:GetParent():GetName()

    if db.glow.enabled or db.frameGlow.enabled then
        db = db.glow
        if #db.tracking > 0 then 
            name = name and name:lower()
            debuffType = debuffType and debuffType:lower()

            for _, aura in ipairs(db.tracking) do
                if aura ~= nil and (aura == name or aura == debuffType or (spellId ~= nil and tonumber(aura) == spellId)) then                
                    found = true
                    break
                end
            end

            self:CheckNil(self.aurasCache.buffFrames[frameName], name, true)
            self:CheckNil(self.aurasCache.buffFrames[frameName], debuffType, true)
            self:CheckNil(self.aurasCache.buffFrames[frameName], spellId, true)

            if found and db.enabled then
                self:StartGlow(frame, db)
            elseif not found and db.enabled then
                self:StopGlow(frame, db)
            end
        end
    end
end

function KHMRaidFrames:StopBuffFramesGlow(frame, index)
    local db = self:GroupTypeDB().buffFrames.glow

    if db.enabled then
        for i=index, #frame.buffFrames do
            self:StopGlow(frame.buffFrames[i], db)
        end
    end    
end

function KHMRaidFrames:StopDebuffFramesGlow(frame, index)
    local db = self:GroupTypeDB().debuffFrames.glow

    if db.enabled then
        for i=index, #frame.debuffFrames do
            self:StopGlow(frame.debuffFrames[i], db)
        end
    end    
end

function KHMRaidFrames:StopDispelDebuffFramesGlow(frame, index)
    local db = self:GroupTypeDB().dispelDebuffFrames.glow

    if db.enabled then
        for i=index, #frame.dispelDebuffFrames do
            self:StopGlow(frame.dispelDebuffFrames[i], db)
        end
    end    
end

function KHMRaidFrames:CheckFrameGlow(frame)
    local db = self:GroupTypeDB()
    local frameName = frame:GetName()

    for subFrame in self:IterateSubFrameTypes() do
        local _db = db[subFrame].frameGlow

        if _db.enabled then
            if #_db.tracking > 0 then
                for _, aura in ipairs(_db.tracking) do
                    if (self.aurasCache[subFrame][frameName][aura] or 
                        (tonumber(aura) and self.aurasCache[subFrame][frameName][tonumber(aura)]))
                    then
                        return self:StartGlow(frame, _db)
                    end
                end
            end

            self:StopGlow(frame, _db)
        end
    end
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
    if not frame.glowing and not self.isOpen then return end

    for _, glowType in pairs{"pixel", "auto", "button"} do
        db.options[glowType].stop(frame)
    end

    frame.glowing = false
end