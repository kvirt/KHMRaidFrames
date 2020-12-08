local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")

local positions = {
    ["TOPLEFT"] = L["TOPLEFT"],
    ["LEFT"] = L["LEFT"],
    ["BOTTOMLEFT"] = L["BOTTOMLEFT"],
    ["BOTTOM"] = L["BOTTOM"],
    ["BOTTOMRIGHT"] = L["BOTTOMRIGHT"],
    ["RIGHT"] = L["RIGHT"],
    ["TOPRIGHT"] = L["TOPRIGHT"],
    ["TOP"] = L["TOP"],
    ["CENTER"] = L["CENTER"],
}

local positionsText = {
    ["LEFT"] = L["LEFT"],
    ["RIGHT"] = L["RIGHT"],
    ["CENTER"] = L["CENTER"],
}

local grow_positions = {
    ["LEFT"] = L["LEFT"],
    ["BOTTOM"] = L["BOTTOM"],
    ["RIGHT"] = L["RIGHT"],
    ["TOP"] = L["TOP"],
}

local flags = {
    ["None"] = L["None"],
    ["OUTLINE"] = L["OUTLINE"],
    ["THICKOUTLINE"] = L["THICKOUTLINE"],
    ["MONOCHROME"] = L["MONOCHROME"],
}

function KHMRaidFrames:SetupOptions()
    local options = {
        name = L["KHMRaidFrames"],
        type = "group",
        childGroups = "tab",
        order = 1,
    }

    options.args = {}

    options.args.raid = {
        type = "group",
        order = 1,
        name = L["Raid"],
        desc = L["Raid settings"],
        childGroups = "tab",
        args = self:SetupOptionsByType("raid"),
    }
    options.args.party = {
        type = "group",
        order = 2,
        name = L["Party"],
        desc = L["Party settings"],
        childGroups = "tab",
        args = self:SetupOptionsByType("party"),
    }
    options.args.glows = {
        type = "group",
        order = 3,
        name = L["Glows"],
        desc = L["Glows settings"],
        childGroups = "tab",
        args = {
            ["aura glow"] = {
                type = "group",
                order = 1,
                name = L["Aura Glow"],
                desc = L["Glow effect options for your Buffs and Debuffs"],
                childGroups = "tree",
                args = self:GlowSubTypes("auraGlow"),
            },
            ["frame glow"] = {
                type = "group",
                order = 2,
                name = L["Frame Glow"],
                desc = L["Glow effect options for your Frames"],
                childGroups = "tree",
                args = self:GlowSubTypes("frameGlow"),
            },
            ["glow block list"] = {
                type = "group",
                order = 3,
                name = L["Block List"],
                desc = L["Exclude auras from Glows"],
                childGroups = "tab",
                args = {
                    ["glowBlockList"] = {
                        name = L["Block List"],
                        desc = L["Exclude auras from Glows"],
                        usage = self.ExcludeHelpText(),
                        width = "full",
                        type = "input",
                        multiline = 10,
                        order = 1,
                        set = function(info,val)
                            self.db.profile.glows.glowBlockList.tracking = self:SanitizeStrings(val)
                            self.db.profile.glows.glowBlockList.excludeStr = val

                            self:SafeRefresh(groupType)
                        end,
                        get = function(info)
                            return self.db.profile.glows.glowBlockList.excludeStr
                        end
                    },
                    ["glow block list Skip"] = {
                        type = "header",
                        name = "",
                        order = 2,
                    },
                    ["glow block list Reset"] = {
                        name = L["Reset to Default"],
                        desc = "",
                        width = "full",
                        type = "execute",
                        confirm = true,
                        order = 3,
                        func = function(info,val)
                            self.db.profile.glows.glowBlockList.excludeStr = ""
                            self.db.profile.glows.glowBlockList.tracking = {}
                        end,
                    },
                },
            }
        },
    }

    options.args.virtualFrames = {
        name = L["Show\\Hide Test Frames"],
        desc = L["Show\\Hide Test Frames desc"],
        width = "double",
        type = "execute",
        order = 4,
        func = function(info,val)
            if self.virtual.shown == true then
                self:HideVirtual()
            else
                self:ShowVirtual()
            end
        end,
    }

    return options
end

function KHMRaidFrames:SetupOptionsByType(groupType)
    local db = self.db.profile[groupType]

    local options = {}

    options.currentGroupType = {
        name = function()
            self.virtual.groupType = groupType

            self:SetUpVirtual("buffFrames", groupType, self.componentScale)
            self:SetUpVirtual("debuffFrames", groupType, self.componentScale, true)
            self:SetUpVirtual("dispelDebuffFrames", groupType, 1)

            return L["You are in |cFFC80000<text>|r"]
        end,
        type = "header",
        order = 1,
    }

    options.frames = {
        type = "group",
        order = 2,
        name = L["General"],
        desc = L["General options"],
        childGroups = "tab",
        args = self:SetupFrameOptions("frames", db, groupType),
    }
    options.buffFrames = {
        type = "group",
        order = 3,
        name = L["Buffs"],
        desc = "",
        childGroups = "tab",
        args = self:SetupBuffFrames(db.buffFrames, groupType),
    }
    options.debuffFrames = {
        type = "group",
        order = 4,
        name = L["Debuffs"],
        desc = "",
        childGroups = "tab",
        args = self:SetupDebuffFrames(db.debuffFrames, groupType),
    }
    options.raidIcon = {
        type = "group",
        order = 5,
        name = L["Raid Icon"],
        desc = L["Raid Icon options"],
        childGroups = "tab",
        args = self:SetupRaidIconOptions("raidIcon", db, groupType),
    }
    options.dispelDebuffFrames = {
        type = "group",
        order = 6,
        name = L["Dispell Debuffs"],
        desc = L["Dispell Debuffs options"],
        childGroups = "tab",
        args = self:SetupDispelldebuffFrames(db.dispelDebuffFrames, groupType),
    }
    options.nameAndIcons = {
        type = "group",
        order = 7,
        name = L["Name and Icons"],
        desc = L["Name and Icons options"],
        childGroups = "tree",
        args = self:SetupNameAndIconsOptions("nameAndIcons", db, groupType),
    }

    return options
end

function KHMRaidFrames:SetupNameAndIconsOptions(frameType, db, groupType)
    db = db[frameType]

    local options = {}

    options.name = {
        type = "group",
        order = 1,
        name = L["Name"],
        desc = L["Name Options"],
        childGroups = "tab",
        args = {
            ["Enable"] = {
                name = L["Enable"],
                desc = "",
                width = "double",
                type = "toggle",
                order = 1,
                confirm = true,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    db.name.enabled = val
                    ReloadUI()
                end,
                get = function(info)
                    return db.name.enabled
                end,
            },
            ["Font"] = {
                name = L["Font"],
                desc = "",
                width = "normal",
                type = "select",
                values = function(info, val) return self.sortedFonts end,
                order = 2,
                disabled = function() return not db.name.enabled end,
                set = function(info,val)
                    db.name.font = self.sortedFonts[val]
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    for i, font in ipairs(self.sortedFonts) do
                        if db.name.font == font then return i end
                    end

                    db.name.font = "Friz Quadrata TT"
                    self:SafeRefresh(groupType)

                    return db.name.font
                end
            },
            ["Flags"] = {
                name = L["Flags"],
                desc = "",
                width = "normal",
                type = "select",
                values = flags,
                order = 3,
                disabled = function() return not db.name.enabled end,
                set = function(info,val)
                    db.name.flag = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info, value) return db.name.flag end
            },
            ["size"] = {
                name = L["Size"],
                desc = "",
                width = "normal",
                type = "range",
                min = 1,
                max = 100,
                step = 1,
                order = 4,
                disabled = function() return not db.name.enabled end,
                set = function(info,val)
                    db.name.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.name.size end
            },
             ["Horizontal Justify"] = {
                name = L["Horizontal Justify"],
                desc = "",
                width = "normal",
                type = "select",
                values = positionsText,
                order = 5,
                confirm = true,
                confirmText = L["UI will be reloaded to apply settings"],
                disabled = function() return not db.name.enabled end,
                set = function(info,val)
                    db.name.hJustify = val
                    self:SafeRefresh(groupType)
                    ReloadUI()
                end,
                get = function(info) return db.name.hJustify end
            },
            ["xOffset"] = {
                name = L["X Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 6,
                disabled = function() return not db.name.enabled end,
                set = function(info,val)
                    db.name.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.name.xOffset end
            },
            ["yOffset"] = {
                name = L["Y Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 7,
                disabled = function() return not db.name.enabled end,
                set = function(info,val)
                    db.name.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.name.yOffset end
            },
            ["Show Server"] = {
                name = L["Show Server"],
                desc = "",
                width = "normal",
                type = "toggle",
                order = 8,
                disabled = function() return not db.name.enabled end,
                set = function(info,val)
                    db.name.showServer = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    return db.name.showServer
                end
            },
            ["Class Colored Names"] = {
                name = L["Class Colored Names"],
                desc = L["Class Colored Names desc"],
                width = "normal",
                type = "toggle",
                order = 9,
                disabled = function() return not db.name.enabled end,
                set = function(info,val)
                    db.name.classColoredNames = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    return db.name.classColoredNames
                end
            },
            [frameType.."Skip"] = {
                type = "header",
                name = "",
                order = 10,
            },
            ["Copy"] = {
                name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                width = "normal",
                type = "execute",
                order = 11,
                disabled = function() return not db.name.enabled end,
                confirm = true,
                func = function(info,val)
                    self:CopySettings(db.name, self.db.profile[self.ReverseGroupType(groupType)][frameType].name)
                end,
            },
            [frameType.."Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 12,
                disabled = function() return not db.name.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, frameType)
                end,
            },
        },
    }

    options.statusText = {
        type = "group",
        order = 2,
        name = L["Status Text"],
        desc = L["Status Text Options"],
        childGroups = "tab",
        args = {
            ["Enable"] = {
                name = L["Enable"],
                desc = "",
                width = "double",
                type = "toggle",
                order = 1,
                confirm = true,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    db.statusText.enabled = val
                    ReloadUI()
                end,
                get = function(info)
                    return db.statusText.enabled
                end,
            },
            ["Font"] = {
                name = L["Font"],
                desc = "",
                width = "normal",
                type = "select",
                values = function(info, val) return self.sortedFonts end,
                order = 2,
                disabled = function() return not db.statusText.enabled end,
                set = function(info,val)
                    db.statusText.font = self.sortedFonts[val]
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    for i, font in ipairs(self.sortedFonts) do
                        if db.statusText.font == font then return i end
                    end

                    db.statusText.font = "Friz Quadrata TT"
                    self:SafeRefresh(groupType)

                    return db.statusText.font
                end
            },
            ["Flags"] = {
                name = L["Flags"],
                desc = "",
                width = "normal",
                type = "select",
                values = flags,
                order = 3,
                disabled = function() return not db.statusText.enabled end,
                set = function(info,val)
                    db.statusText.flag = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info, value) return db.statusText.flag end
            },
            ["size"] = {
                name = L["Size"],
                desc = "",
                width = "normal",
                type = "range",
                min = 1,
                max = 100,
                step = 1,
                order = 4,
                disabled = function() return not db.statusText.enabled end,
                set = function(info,val)
                    db.statusText.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.statusText.size end
            },
            ["Horizontal Justify"] = {
                name = L["Horizontal Justify"],
                desc = "",
                width = "normal",
                type = "select",
                values = positionsText,
                order = 5,
                disabled = function() return not db.statusText.enabled end,
                confirm = true,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    db.statusText.hJustify = val
                    self:SafeRefresh(groupType)
                    ReloadUI()
                end,
                get = function(info) return db.statusText.hJustify end
            },
            ["xOffset"] = {
                name = L["X Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 6,
                disabled = function() return not db.statusText.enabled end,
                set = function(info,val)
                    db.statusText.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.statusText.xOffset end
            },
            ["yOffset"] = {
                name = L["Y Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 7,
                disabled = function() return not db.statusText.enabled end,
                set = function(info,val)
                    db.statusText.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.statusText.yOffset end
            },
            [frameType.."Skip"] = {
                type = "header",
                name = "",
                order = 8,
            },
            ["Copy"] = {
                name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                width = "normal",
                type = "execute",
                order = 9,
                confirm = true,
                disabled = function() return not db.statusText.enabled end,
                func = function(info,val)
                    self:CopySettings(db.statusText, self.db.profile[self.ReverseGroupType(groupType)][frameType].statusText)
                end,
            },
            [frameType.."Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 10,
                disabled = function() return not db.statusText.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, frameType)
                end,
            },
        },
    }

    options.roleIcon = {
        type = "group",
        order = 3,
        name = L["Role Icon"],
        desc = L["Role Icon Options"],
        childGroups = "tab",
        args = {
            ["Enable"] = {
                name = L["Enable"],
                desc = "",
                width = "normal",
                type = "toggle",
                order = 1,
                confirm = true,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    db.roleIcon.enabled = val
                    ReloadUI()
                end,
                get = function(info)
                    return db.roleIcon.enabled
                end,
            },
            ["size"] = {
                name = L["Size"],
                desc = "",
                width = "full",
                type = "range",
                min = 1,
                max = 100,
                step = 1,
                order = 2,
                disabled = function() return not db.roleIcon.enabled end,
                set = function(info,val)
                    db.roleIcon.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.roleIcon.size end
            },
            ["xOffset"] = {
                name = L["X Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 3,
                disabled = function() return not db.roleIcon.enabled end,
                set = function(info,val)
                    db.roleIcon.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.roleIcon.xOffset end
            },
            ["yOffset"] = {
                name = L["Y Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 4,
                disabled = function() return not db.roleIcon.enabled end,
                set = function(info,val)
                    db.roleIcon.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.roleIcon.yOffset end
            },
            [frameType.."Skip1"] = {
                type = "execute",
                name = L["Custom Textures"],
                desc = L["Custom Textures desc"],
                order = 5,
                disabled = function() return not db.roleIcon.enabled end,
                width = "full",
                func = function(info,val)
                    db.roleIcon.toggle = not db.roleIcon.toggle
                end,
            },
            ["healer"] = {
                name = L["Healer"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 6,
                disabled = function() return not db.roleIcon.enabled end,
                hidden = function(info)
                    return not db.roleIcon.toggle
                end,
                set = function(info,val)
                    db.roleIcon.healer = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.roleIcon.healer end
            },
            ["damager"] = {
                name = L["Damager"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 7,
                disabled = function() return not db.roleIcon.enabled end,
                hidden = function(info)
                    return not db.roleIcon.toggle
                end,
                set = function(info,val)
                    db.roleIcon.damager = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.roleIcon.damager end
            },
            ["tank"] = {
                name = L["Tank"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 8,
                disabled = function() return not db.roleIcon.enabled end,
                hidden = function(info)
                    return not db.roleIcon.toggle
                end,
                set = function(info,val)
                    db.roleIcon.tank = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.roleIcon.tank end
            },
            ["vehicle"] = {
                name = L["Vehicle"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 9,
                disabled = function() return not db.roleIcon.enabled end,
                hidden = function(info)
                    return not db.roleIcon.toggle
                end,
                set = function(info,val)
                    db.roleIcon.vehicle = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.roleIcon.vehicle end
            },
            [frameType.."Skip2"] = {
                type = "header",
                name = "",
                order = 10,
            },
            ["Copy"] = {
                name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                width = "normal",
                type = "execute",
                order = 11,
                disabled = function() return not db.roleIcon.enabled end,
                confirm = true,
                func = function(info,val)
                    self:CopySettings(db.roleIcon, self.db.profile[self.ReverseGroupType(groupType)][frameType].roleIcon)
                end,
            },
            [frameType.."Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 12,
                disabled = function() return not db.roleIcon.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, frameType)
                end,
            },
        },
    }

    options.readyCheckIcon = {
        type = "group",
        order = 4,
        name = L["Ready Check Icon"],
        desc = L["Ready Check Icon Options"],
        childGroups = "tab",
        args = {
            ["Enable"] = {
                name = L["Enable"],
                desc = "",
                width = "normal",
                type = "toggle",
                order = 1,
                confirm = true,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    db.readyCheckIcon.enabled = val
                    ReloadUI()
                end,
                get = function(info)
                    return db.readyCheckIcon.enabled
                end,
            },
            ["size"] = {
                name = L["Size"],
                desc = "",
                width = "full",
                type = "range",
                min = 1,
                max = 100,
                step = 1,
                order = 2,
                disabled = function() return not db.readyCheckIcon.enabled end,
                set = function(info,val)
                    db.readyCheckIcon.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.readyCheckIcon.size end
            },
            ["xOffset"] = {
                name = L["X Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 3,
                disabled = function() return not db.readyCheckIcon.enabled end,
                set = function(info,val)
                    db.readyCheckIcon.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.readyCheckIcon.xOffset end
            },
            ["yOffset"] = {
                name = L["Y Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 4,
                disabled = function() return not db.readyCheckIcon.enabled end,
                set = function(info,val)
                    db.readyCheckIcon.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.readyCheckIcon.yOffset end
            },
            [frameType.."Skip1"] = {
                type = "execute",
                name = L["Custom Textures"],
                desc = L["Custom Textures desc"],
                order = 5,
                disabled = function() return not db.readyCheckIcon.enabled end,
                width = "full",
                func = function(info,val)
                    db.readyCheckIcon.toggle = not db.readyCheckIcon.toggle
                end,
            },
            ["ready"] = {
                name = L["Ready"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 6,
                disabled = function() return not db.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not db.readyCheckIcon.toggle
                end,
                set = function(info,val)
                    db.readyCheckIcon.ready = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.readyCheckIcon.ready end
            },
            ["notready"] = {
                name = L["Not Ready"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 7,
                disabled = function() return not db.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not db.readyCheckIcon.toggle
                end,
                set = function(info,val)
                    db.readyCheckIcon.notready = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.readyCheckIcon.notready end
            },
            ["waiting"] = {
                name = L["Waiting"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 8,
                disabled = function() return not db.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not db.readyCheckIcon.toggle
                end,
                set = function(info,val)
                    db.readyCheckIcon.waiting = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.readyCheckIcon.waiting end
            },
            [frameType.."Skip2"] = {
                type = "header",
                name = "",
                order = 9,
            },
            ["Copy"] = {
                name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                width = "normal",
                type = "execute",
                order = 10,
                disabled = function() return not db.readyCheckIcon.enabled end,
                confirm = true,
                func = function(info,val)
                    self:CopySettings(db.readyCheckIcon, self.db.profile[self.ReverseGroupType(groupType)][frameType].readyCheckIcon)
                end,
            },
            [frameType.."Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 11,
                disabled = function() return not db.readyCheckIcon.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, frameType)
                end,
            },
        },
    }

    options.centerStatusIcon = {
        type = "group",
        order = 5,
        name = L["Center Status Icon"],
        desc = L["Center Status Icon Options"],
        childGroups = "tab",
        args = {
            ["Enable"] = {
                name = L["Enable"],
                desc = "",
                width = "normal",
                type = "toggle",
                order = 1,
                confirm = true,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    db.centerStatusIcon.enabled = val
                    ReloadUI()
                end,
                get = function(info)
                    return db.centerStatusIcon.enabled
                end,
            },
            ["size"] = {
                name = L["Size"],
                desc = "",
                width = "full",
                type = "range",
                min = 1,
                max = 100,
                step = 1,
                order = 2,
                disabled = function() return not db.centerStatusIcon.enabled end,
                set = function(info,val)
                    db.centerStatusIcon.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.size end
            },
            ["xOffset"] = {
                name = L["X Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 3,
                disabled = function() return not db.centerStatusIcon.enabled end,
                set = function(info,val)
                    db.centerStatusIcon.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.xOffset end
            },
            ["yOffset"] = {
                name = L["Y Offset"],
                desc = "",
                width = "normal",
                type = "range",
                min = -200,
                max = 200,
                step = 1,
                order = 4,
                disabled = function() return not db.centerStatusIcon.enabled end,
                set = function(info,val)
                    db.centerStatusIcon.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.yOffset end
            },
            [frameType.."Skip1"] = {
                type = "execute",
                name = L["Custom Textures"],
                desc = L["Custom Textures desc"],
                order = 5,
                disabled = function() return not db.centerStatusIcon.enabled end,
                width = "full",
                func = function(info,val)
                    db.centerStatusIcon.toggle = not db.centerStatusIcon.toggle
                end,
            },
            ["inOtherGroup "] = {
                name = L["In Other Group"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 6,
                disabled = function() return not db.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not db.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    db.centerStatusIcon.inOtherGroup = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.inOtherGroup end
            },
            ["hasIncomingResurrection"] = {
                name = L["Has Icoming Ressurection"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 7,
                disabled = function() return not db.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not db.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    db.centerStatusIcon.hasIncomingResurrection = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.hasIncomingResurrection end
            },
            ["hasIncomingSummonPending"] = {
                name = L["Incoming Summon Pending"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 8,
                disabled = function() return not db.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not db.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    db.centerStatusIcon.hasIncomingSummonPending = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.hasIncomingSummonPending end
            },
            ["hasIncomingSummonAccepted"] = {
                name = L["Incoming Summon Accepted"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 9,
                disabled = function() return not db.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not db.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    db.centerStatusIcon.hasIncomingSummonAccepted = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.hasIncomingSummonAccepted end
            },
             ["hasIncomingSummonDeclined"] = {
                name = L["Incoming Summon Declined"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 10,
                disabled = function() return not db.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not db.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    db.centerStatusIcon.hasIncomingSummonDeclined = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.hasIncomingSummonDeclined end
            },
             ["inOtherPhase"] = {
                name = L["In Other Phase"],
                desc = L["Custom Texture Options"],
                width = "full",
                type = "input",
                order = 11,
                disabled = function() return not db.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not db.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    db.centerStatusIcon.inOtherPhase = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return db.centerStatusIcon.inOtherPhase end
            },
            [frameType.."Skip2"] = {
                type = "header",
                name = "",
                order = 12,
            },
            ["Copy"] = {
                name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                width = "normal",
                type = "execute",
                order = 13,
                disabled = function() return not db.centerStatusIcon.enabled end,
                confirm = true,
                func = function(info,val)
                    self:CopySettings(db.centerStatusIcon, self.db.profile[self.ReverseGroupType(groupType)][frameType].centerStatusIcon)
                end,
            },
            [frameType.."Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 14,
                disabled = function() return not db.centerStatusIcon.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, frameType)
                end,
            },
        },
    }

    return options
end

function KHMRaidFrames:SetupRaidIconOptions(frameType, db, groupType)
    db = db[frameType]

    local options = {
        [frameType.."enabled"] = {
            name = L["Enable"],
            desc = "",
            width = "normal",
            type = "toggle",
            order = 1,
            set = function(info,val)
                db.enabled = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return db.enabled
            end
        },
        ["size"..frameType] = {
            name = L["Size"],
            desc = "",
            width = "double",
            type = "range",
            min = 1,
            max = 100,
            step = 1,
            order = 2,
            disabled = function(info)
                return not db.enabled
            end,
            set = function(info,val)
                db.size = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.size end
        },
        ["xOffset"..frameType] = {
            name = L["X Offset"],
            desc = "",
            width = "normal",
            type = "range",
            min = -200,
            max = 200,
            step = 1,
            order = 3,
            disabled = function(info)
                return not db.enabled
            end,
            set = function(info,val)
                db.xOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.xOffset end
        },
        ["yOffset"..frameType] = {
            name = L["Y Offset"],
            desc = "",
            width = "normal",
            type = "range",
            min = -200,
            max = 200,
            step = 1,
            order = 4,
            disabled = function(info)
                return not db.enabled
            end,
            set = function(info,val)
                db.yOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.yOffset end
        },
        [frameType.."AnchorPoint"] = {
            name = L["Anchor Point"],
            desc = "",
            width = "normal",
            type = "select",
            values = positions,
            order = 5,
            disabled = function(info)
                return not db.enabled
            end,
            set = function(info,val)
                db.anchorPoint = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.anchorPoint end
        },
        [frameType.."Skip"] = {
            type = "header",
            name = "",
            order = 6,
        },
        ["Copy"] = {
            name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            width = "normal",
            type = "execute",
            order = 7,
            confirm = true,
            func = function(info,val)
                self:CopySettings(db, self.db.profile[self.ReverseGroupType(groupType)][frameType])
            end,
        },
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            width = "double",
            type = "execute",
            confirm = true,
            order = 8,
            func = function(info,val)
                self:RestoreDefaults(groupType, frameType)
            end,
        },
    }
    return options
end

function KHMRaidFrames:SetupFrameOptions(frameType, db, groupType)
    local halfWidth = "normal"

    db = db[frameType]

    local options = {
        [frameType.."Texture"] = {
            name = L["Texture"],
            desc = "",
            width = "normal",
            type = "select",
            values = function(info, val) return self.sortedTextures end,
            order = 1,
            set = function(info,val)
                db.texture = self.sortedTextures[val]
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                for i, texture in ipairs(self.sortedTextures) do
                    if db.texture == texture then return i end
                end

                db.texture = "Blizzard Raid Bar"
                self:SafeRefresh(groupType)

                return db.texture
            end
        },
        ["Masque Support"] = {
            name = L["Enable Masque Support"],
            desc = L["Enable Masque Support Desc"],
            width = "normal",
            type = "toggle",
            order = 2,
            confirm = true,
            confirmText = L["UI will be reloaded to apply settings"],
            set = function(info,val)
                self.db.profile.Masque = val
                ReloadUI()
            end,
            get = function(info)
                return  self.db.profile.Masque
            end
        },
        [frameType.."Show Party When Solo"] = {
            name = L["Always Show Party Frame"],
            desc = L["Always Show Party Frame Desc"],
            width = "normal",
            type = "toggle",
            order = 3,
            hidden = function(info)
                return groupType == "raid"
            end,
            set = function(info,val)
                db.showPartySolo = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return db.showPartySolo
            end
        },
        [frameType.."Skip1"] = {
                type = "header",
                name = "",
                order = 4,
            },
        [frameType.."HideGroupTitles"] = {
            name = L["Hide Group Title"],
            desc = "",
            width = "normal",
            type = "toggle",
            order = 5,
            set = function(info,val)
                db.hideGroupTitles = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return db.hideGroupTitles
            end
        },
        [frameType.."Click Through"] = {
            name = L["Click Through Auras"],
            desc = L["Click Through Auras Desc"],
            width = "normal",
            type = "toggle",
            order = 6,
            set = function(info,val)
                db.clickThrough = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return db.clickThrough
            end
        },
        [frameType.."Enhanced Absorbs"] = {
            name = L["Enhanced Absorbs"],
            desc = L["Enhanced Absorbs Desc"],
            width = "normal",
            type = "toggle",
            order = 7,
            confirm = true,
            confirmText = L["UI will be reloaded to apply settings"],
            set = function(info,val)
                db.enhancedAbsorbs = val
                self:SafeRefresh(groupType)
                ReloadUI()
            end,
            get = function(info)
                return db.enhancedAbsorbs
            end
        },
        ["additionalTracking"] = {
            name = L["Additional Auras Tracking"],
            desc = L["Track Auras that are not shown by default by Blizzard"],
            usage = self.AdditionalTrackingHelpText(),
            width = "full",
            type = "input",
            multiline = 10,
            order = 10,
            set = function(info,val)
                db.tracking = self.SanitizeStringsByUnit(val)
                db.trackingStr = val

                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return db.trackingStr
            end
        },
        [frameType.."Skip2"] = {
            type = "header",
            name = "",
            order = 11,
        },
        ["Copy"] = {
            name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            width = "normal",
            type = "execute",
            order = 12,
            confirm = true,
            func = function(info,val)
                self:CopySettings(db, self.db.profile[self.ReverseGroupType(groupType)][frameType])
            end,
        },
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            width = "double",
            type = "execute",
            confirm = true,
            order = 13,
            func = function(info,val)
                self:RestoreDefaults(groupType, frameType)
            end,
        },
    }
    return options
end