local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")

local _G, tinsert, CompactRaidFrameContainer = _G, tinsert, CompactRaidFrameContainer
KHMRaidFrames.NATIVE_UNIT_FRAME_HEIGHT = 36
KHMRaidFrames.NATIVE_UNIT_FRAME_WIDTH = 72

KHMRaidFrames.defuffsColors = {
    magic = {0.2, 0.6, 1.0, 1},
    curse = {0.6, 0.0, 1.0, 1},
    disease = {0.6, 0.4, 0.0, 1},
    poison = {0.0, 0.6, 0.0, 1},
    physical = {1, 1, 1, 1}
}

function KHMRaidFrames:Defaults()
    local defaults_settings = {profile = {party = {}, raid = {}, glows = {}}}

    local commons = {
            frames = {
                hideGroupTitles = false,
                texture = "Blizzard Raid Bar",
                clickThrough = false,
                enhancedAbsorbs = false,
                showPartySolo = false,
                tracking = {},
                trackingStr = "",
            },
            dispelDebuffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",
                anchorPoint = "TOPRIGHT",
                growDirection = "LEFT",
                size = 12,
                xOffset = 0,
                yOffset = 0,
                exclude = {},
                excludeStr = "",
            },
            debuffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",
                anchorPoint = "BOTTOMLEFT",
                growDirection = "RIGHT",
                size = 11,
                xOffset = 0,
                yOffset = 0,
                exclude = {},
                excludeStr = "",
                bigDebuffSize = 11 + 9,
                showBigDebuffs = true,
                smartAnchoring = true,
            },
            buffFrames = {
                num = 3,
                numInRow = 3,
                rowsGrowDirection = "TOP",
                anchorPoint = "BOTTOMRIGHT",
                growDirection = "LEFT",
                size = 11,
                xOffset = 0,
                yOffset = 0,
                exclude = {},
                excludeStr = "",
            },
            raidIcon = {
                enabled = true,
                size = 15,
                xOffset = 0,
                yOffset = 0,
                anchorPoint = "TOP",
            },
            nameAndIcons = {
                name = {
                    font = "Friz Quadrata TT",
                    size = 6,
                    flags = {
                        ["OUTLINE"] = false,
                        ["THICKOUTLINE"] = false,
                        ["MONOCHROME"] = false,
                    },
                    hJustify = "LEFT",
                    xOffset = 0,
                    yOffset = -1,
                    showServer = true,
                    classColoredNames = false,
                    enabled = false,
                },
                statusText = {
                    font = "Friz Quadrata TT",
                    size = 12,
                    flags = {
                        ["OUTLINE"] = false,
                        ["THICKOUTLINE"] = false,
                        ["MONOCHROME"] = false,
                    },
                    hJustify = "CENTER",
                    xOffset = 0,
                    yOffset = 0,
                    enabled = false,
                },
                roleIcon = {
                    size = 12,
                    xOffset = 0,
                    yOffset = 0,
                    healer = "",
                    damager = "",
                    tank = "",
                    vehicle = "",
                    toggle = false,
                    enabled = false,
                },
                readyCheckIcon  = {
                    size = 15 ,
                    xOffset = 0,
                    yOffset = 0,
                    ready = "",
                    notready = "",
                    waiting = "",
                    toggle = false,
                    enabled = false,
                },
                centerStatusIcon = {
                    size = 22,
                    xOffset = 0,
                    yOffset = 0,
                    inOtherGroup = "",
                    hasIncomingResurrection = "",
                    hasIncomingSummonPending = "",
                    hasIncomingSummonAccepted = "",
                    hasIncomingSummonDeclined = "",
                    inOtherPhase = "",
                    toggle = false,
                    enabled = false,
                },
            },
    }
    defaults_settings.profile.party = commons
    defaults_settings.profile.raid = commons

    defaults_settings.profile.glows = {
        auraGlow = {
            buffFrames = {
                type = "pixel",
                options = self.GetGlowOptions(),
                tracking = {},
                trackingStr = "",
                enabled = false,
                useDefaultsColors = true,
            },
            debuffFrames = {
                type = "pixel",
                options = self.GetGlowOptions(),
                tracking = {},
                trackingStr = "",
                enabled = false,
                useDefaultsColors = true,
            },
            defaultColors = self.defuffsColors,
        },
        frameGlow = {
            buffFrames = {
                type = "pixel",
                options = self.GetGlowOptions(),
                tracking = {},
                trackingStr = "",
                enabled = false,
                useDefaultsColors = true,
            },
            debuffFrames = {
                type = "pixel",
                options = self.GetGlowOptions(),
                tracking = {},
                trackingStr = "",
                enabled = false,
                useDefaultsColors = true,
            },
            defaultColors = self.defuffsColors,
        },
        glowBlockList = {
            tracking = {},
            trackingStr = "",
        },
    }

    defaults_settings.profile.Masque = false

    return defaults_settings
end

function KHMRaidFrames:RestoreDefaults(groupType, frameType)
    if InCombatLockdown() then
        print("Can not refresh settings while in combat")
        return
    end

    local defaults_settings = self:Defaults()["profile"][groupType][frameType]

    for k, v in pairs(defaults_settings) do
        self.db.profile[groupType][frameType][k] = v
    end

    self:SafeRefresh(groupType)
end

function KHMRaidFrames:CopySettings(dbFrom, dbTo)
    if InCombatLockdown() then
        print("Can not refresh settings while in combat")
        return
    end

    for k, v in pairs(dbFrom) do
        if dbTo[k] ~= nil then
            dbTo[k] = v
        end
    end

    self:SafeRefresh(groupType)
end

function KHMRaidFrames:CUFDefaults(groupType)
    local deferred
    local isInCombatLockDown = InCombatLockdown()

    for group in self.IterateCompactGroups(groupType) do
        if self.processedFrames[group] == nil then
            deferred = self:DefaultGroupSetUp(group, groupType, isInCombatLockDown)

            if deferred == false then
                self.processedFrames[group] = true
            end
        end
    end

    for frame in self:IterateCompactFrames(groupType) do
        if self.processedFrames[frame] == nil then
            deferred = self:DefaultFrameSetUp(frame, groupType, isInCombatLockDown)

            if deferred == false then
                self.processedFrames[frame] = true
            end
        end
    end

    self:SetUpSoloFrame()
end

function KHMRaidFrames:DefaultGroupSetUp(frame, groupType, isInCombatLockDown)
    local db = self.db.profile[groupType]

    if db.frames.hideGroupTitles then
        frame.title:Hide()
    else
        frame.title:Show()
    end

end

function KHMRaidFrames:DefaultFrameSetUp(frame, groupType, isInCombatLockDown)
    local db = self.db.profile[groupType]
    local deferred = false

    if not isInCombatLockDown then
        self:AddSubFrames(frame, groupType)
    else
        deferred = true
    end

    self:SetUpSubFramesPositionsAndSize(frame, frame.buffFrames, db.buffFrames, groupType, "buffFrames")
    self:SetUpSubFramesPositionsAndSize(frame, frame.debuffFrames, db.debuffFrames, groupType, "debuffFrames")

    if db.showBigDebuffs and db.smartAnchoring then
        self:SmartAnchoring(frame, frame.debuffFrames, db.debuffFrames)
    end

    self:SetUpSubFramesPositionsAndSize(frame, frame.dispelDebuffFrames, db.dispelDebuffFrames, groupType, "dispelDebuffFrames")

    self:SetUpRaidIcon(frame, groupType)

    if self.db.profile[groupType].nameAndIcons.name.enabled then
        self:SetUpName(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.statusText.enabled then
        self:SetUpStatusText(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.roleIcon.enabled then
        self:SetUpRoleIcon(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled then
        self:SetUpReadyCheckIcon(frame, groupType)
    end

    if self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled then
        self:SetUpCenterStatusIcon(frame, groupType)
    end

    frame.healthBar:SetStatusBarTexture(self.textures[db.frames.texture], "BORDER")

    return deferred
end