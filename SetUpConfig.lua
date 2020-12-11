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

local abbreviateNumbers = {
    ["Abbreviate Large Numbers"] = L["Abbreviate Large Numbers"],
    ["Abbreviate Numbers"] = L["Abbreviate Numbers"],
    ["None"] = L["None"],
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

    options.args.profileName = {
        type = "header",
        name = L["Profile: |cFFC80000<text>|r"],
        hidden = function() return not KHMRaidFrames_SyncProfiles end,
        order = 5,
    }

    return options
end

function KHMRaidFrames:SetupOptionsByType(groupType)
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
        args = self:SetupFrameOptions(groupType),
    }
    options.buffFrames = {
        type = "group",
        order = 3,
        name = L["Buffs"],
        desc = "",
        childGroups = "tab",
        args = self:SetupBuffFrames(groupType),
    }
    options.debuffFrames = {
        type = "group",
        order = 4,
        name = L["Debuffs"],
        desc = "",
        childGroups = "tab",
        args = self:SetupDebuffFrames(groupType),
    }
    options.raidIcon = {
        type = "group",
        order = 5,
        name = L["Raid Icon"],
        desc = L["Raid Icon options"],
        childGroups = "tab",
        args = self:SetupRaidIconOptions(groupType),
    }
    options.dispelDebuffFrames = {
        type = "group",
        order = 6,
        name = L["Dispell Debuffs"],
        desc = L["Dispell Debuffs options"],
        childGroups = "tab",
        args = self:SetupDispelldebuffFrames(groupType),
    }
    options.nameAndIcons = {
        type = "group",
        order = 7,
        name = L["Name and Icons"],
        desc = L["Name and Icons options"],
        childGroups = "tree",
        args = self:SetupNameAndIconsOptions(groupType),
    }

    return options
end

function KHMRaidFrames:SetupNameAndIconsOptions(groupType)
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
                confirm = function() return self.db.profile[groupType].nameAndIcons.name.enabled end,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.enabled = val

                    if not val then
                        ReloadUI()
                    else
                        self:HookNameAndIcons()
                        self:SafeRefresh(groupType)
                    end
                end,
                get = function(info)
                    return self.db.profile[groupType].nameAndIcons.name.enabled
                end,
            },
            ["Font"] = {
                name = L["Font"],
                desc = "",
                width = "normal",
                type = "select",
                values = function(info, val) return self.sortedFonts end,
                order = 2,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.font = self.sortedFonts[val]
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    for i, font in ipairs(self.sortedFonts) do
                        if self.db.profile[groupType].nameAndIcons.name.font == font then return i end
                    end

                    for i, font in ipairs(self.sortedFonts) do
                        if self:Defaults().profile[groupType].nameAndIcons.name.font == font then return i end
                    end

                    --fallback hack
                    return 7
                end
            },
            ["Flags"] = {
                name = L["Flags"],
                desc = "",
                width = "normal",
                type = "select",
                values = flags,
                order = 3,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.flag = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info, value) return self.db.profile[groupType].nameAndIcons.name.flag end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.name.size end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.hJustify = val
                    self:SafeRefresh(groupType)
                    ReloadUI()
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.name.hJustify end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.name.xOffset end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.name.yOffset end
            },
            ["Show Server"] = {
                name = L["Show Server"],
                desc = "",
                width = "normal",
                type = "toggle",
                order = 8,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.showServer = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    return self.db.profile[groupType].nameAndIcons.name.showServer
                end
            },
            ["Class Colored Names"] = {
                name = L["Class Colored Names"],
                desc = L["Class Colored Names desc"],
                width = "normal",
                type = "toggle",
                order = 9,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.name.classColoredNames = val

                    if not val then
                        self.RevertNameColors()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    return self.db.profile[groupType].nameAndIcons.name.classColoredNames
                end
            },
            ["Skip"] = {
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                confirm = true,
                func = function(info,val)
                    self:CopySettings(self.db.profile[groupType].nameAndIcons.name, self.db.profile[self.ReverseGroupType(groupType)].nameAndIcons.name)
                end,
            },
            ["Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 12,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.name.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, "nameAndIcons", "name")
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
                confirm = function() return self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.statusText.enabled = val

                    if not val then
                        ReloadUI()
                    else
                        self:HookNameAndIcons()
                        self:SafeRefresh(groupType)
                    end
                end,
                get = function(info)
                    return self.db.profile[groupType].nameAndIcons.statusText.enabled
                end,
            },
            ["Font"] = {
                name = L["Font"],
                desc = "",
                width = "normal",
                type = "select",
                values = function(info, val) return self.sortedFonts end,
                order = 2,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.statusText.font = self.sortedFonts[val]
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    for i, font in ipairs(self.sortedFonts) do
                        if self.db.profile[groupType].nameAndIcons.statusText.font == font then return i end
                    end


                    for i, font in ipairs(self.sortedFonts) do
                        if self:Defaults().profile[groupType].nameAndIcons.statusText.font == font then return i end
                    end

                    --fallback hack
                    return 7
                end
            },
            ["Flags"] = {
                name = L["Flags"],
                desc = "",
                width = "normal",
                type = "select",
                values = flags,
                order = 3,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.statusText.flag = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info, value) return self.db.profile[groupType].nameAndIcons.statusText.flag end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.statusText.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.statusText.size end
            },
            ["Horizontal Justify"] = {
                name = L["Horizontal Justify"],
                desc = "",
                width = "normal",
                type = "select",
                values = positionsText,
                order = 5,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                confirm = true,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.statusText.hJustify = val
                    self:SafeRefresh(groupType)
                    ReloadUI()
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.statusText.hJustify end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.statusText.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.statusText.xOffset end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.statusText.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.statusText.yOffset end
            },
            ["Abbreviate"] = {
                name = L["Abbreviate"],
                desc = "",
                width = "normal",
                type = "select",
                values = abbreviateNumbers,
                order = 8,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.statusText.abbreviateNumbers = val

                    self.RevertStatusText()

                    self:SafeRefresh(groupType)
                end,
                get = function(info, value) return self.db.profile[groupType].nameAndIcons.statusText.abbreviateNumbers end
            },
            ["Skip"] = {
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
                confirm = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                func = function(info,val)
                    self:CopySettings(self.db.profile[groupType].nameAndIcons.statusText, self.db.profile[self.ReverseGroupType(groupType)].nameAndIcons.statusText)
                end,
            },
            ["Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 11,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.statusText.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, "nameAndIcons", "statusText")
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
                confirm = function() return self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.enabled = val

                    if not val then
                        ReloadUI()
                    else
                        self:HookNameAndIcons()
                        self:SafeRefresh(groupType)
                    end
                end,
                get = function(info)
                    return self.db.profile[groupType].nameAndIcons.roleIcon.enabled
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.roleIcon.size end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.roleIcon.xOffset end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.roleIcon.yOffset end
            },
            ["Skip1"] = {
                type = "execute",
                name = L["Custom Textures"],
                desc = L["Custom Textures desc"],
                order = 5,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                width = "full",
                func = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.toggle = not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
            },
            ["healer"] = {
                name = L["Healer"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 6,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.healer = val

                    if val == "" then
                        self.RevertRoleIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.roleIcon.healer end
            },
            ["color healer"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 7,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.roleIcon.colors.healer = {r, g, b, a}
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.roleIcon.colors.healer
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["damager"] = {
                name = L["Damager"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 8,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.damager = val

                    if val == "" then
                        self.RevertRoleIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.roleIcon.damager end
            },
            ["color damager"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 9,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.roleIcon.colors.damager = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.roleIcon.colors.damager
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["tank"] = {
                name = L["Tank"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 10,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.tank = val

                    if val == "" then
                        self.RevertRoleIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.roleIcon.tank end
            },
            ["color tank"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 11,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.roleIcon.colors.tank = {r, g, b, a}
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.roleIcon.colors.tank
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["vehicle"] = {
                name = L["Vehicle"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 12,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.roleIcon.vehicle = val

                    if val == "" then
                        self.RevertRoleIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.roleIcon.vehicle end
            },
            ["color vehicle"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 13,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.roleIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.roleIcon.colors.vehicle = {r, g, b, a}
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.roleIcon.colors.vehicle
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["Skip2"] = {
                type = "header",
                name = "",
                order = 14,
            },
            ["Copy"] = {
                name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                width = "normal",
                type = "execute",
                order = 15,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                confirm = true,
                func = function(info,val)
                    self:CopySettings(self.db.profile[groupType].nameAndIcons.roleIcon, self.db.profile[self.ReverseGroupType(groupType)].nameAndIcons.roleIcon)
                end,
            },
            ["Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 16,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.roleIcon.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType,"nameAndIcons", "roleIcon")
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
                confirm = function() return self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled = val

                    if not val then
                        ReloadUI()
                    else
                        self:HookNameAndIcons()
                        self:SafeRefresh(groupType)
                    end
                end,
                get = function(info)
                    return self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.readyCheckIcon.size end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.readyCheckIcon.xOffset end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.readyCheckIcon.yOffset end
            },
            ["Skip1"] = {
                type = "execute",
                name = L["Custom Textures"],
                desc = L["Custom Textures desc"],
                order = 5,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                width = "full",
                func = function(info,val)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.toggle = not self.db.profile[groupType].nameAndIcons.readyCheckIcon.toggle
                end,
            },
            ["ready"] = {
                name = L["Ready"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 6,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.ready = val

                    if val == "" then
                        self.RevertReadyCheckIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.readyCheckIcon.ready end
            },
            ["color ready"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 7,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.colors.ready = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.readyCheckIcon.colors.ready
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["notready"] = {
                name = L["Not Ready"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 8,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.notready = val

                    if val == "" then
                        self.RevertReadyCheckIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.readyCheckIcon.notready end
            },
            ["color notready"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 9,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.colors.notready = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.readyCheckIcon.colors.notready
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["waiting"] = {
                name = L["Waiting"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 10,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.waiting = val

                    if val == "" then
                        self.RevertReadyCheckIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.readyCheckIcon.waiting end
            },
            ["color waiting"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 11,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.readyCheckIcon.colors.waiting = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.readyCheckIcon.colors.waiting
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["Skip2"] = {
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                confirm = true,
                func = function(info,val)
                    self:CopySettings(self.db.profile[groupType].nameAndIcons.readyCheckIcon, self.db.profile[self.ReverseGroupType(groupType)].nameAndIcons.readyCheckIcon)
                end,
            },
            ["Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 14,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.readyCheckIcon.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, "nameAndIcons", "readyCheckIcon")
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
                confirm = function() return self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                confirmText = L["UI will be reloaded to apply settings"],
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled = val

                    if not val then
                        ReloadUI()
                    else
                        self:HookNameAndIcons()
                        self:SafeRefresh(groupType)
                    end
                end,
                get = function(info)
                    return self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.size = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.size end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.xOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.xOffset end
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
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.yOffset = val
                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.yOffset end
            },
            ["Skip1"] = {
                type = "execute",
                name = L["Custom Textures"],
                desc = L["Custom Textures desc"],
                order = 5,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                width = "full",
                func = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle = not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
            },
            ["inOtherGroup "] = {
                name = L["In Other Group"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 6,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.inOtherGroup = val

                    if val == "" then
                        self.RevertStatusIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.inOtherGroup end
            },
            ["color inOtherGroup"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 7,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.inOtherGroup = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.inOtherGroup
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["hasIncomingResurrection"] = {
                name = L["Has Icoming Ressurection"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 8,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.hasIncomingResurrection = val

                    if val == "" then
                        self.RevertStatusIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.hasIncomingResurrection end
            },
            ["color hasIncomingResurrection"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 9,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.hasIncomingResurrection = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.hasIncomingResurrection
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["hasIncomingSummonPending"] = {
                name = L["Incoming Summon Pending"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 10,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.hasIncomingSummonPending = val

                    if val == "" then
                        self.RevertStatusIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.hasIncomingSummonPending end
            },
            ["color hasIncomingSummonPending"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 11,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.hasIncomingSummonPending = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.hasIncomingSummonPending
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["hasIncomingSummonAccepted"] = {
                name = L["Incoming Summon Accepted"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 12,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.hasIncomingSummonAccepted = val

                    if val == "" then
                        self.RevertStatusIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.hasIncomingSummonAccepted end
            },
            ["color hasIncomingSummonAccepted"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 13,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.hasIncomingSummonAccepted = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.hasIncomingSummonAccepted
                    return color[1], color[2], color[3], color[4]
                end
            },
             ["hasIncomingSummonDeclined"] = {
                name = L["Incoming Summon Declined"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 14,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.hasIncomingSummonDeclined = val

                    if val == "" then
                        self.RevertStatusIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.hasIncomingSummonDeclined end
            },
            ["color hasIncomingSummonDeclined"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 15,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.hasIncomingSummonDeclined = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.hasIncomingSummonDeclined
                    return color[1], color[2], color[3], color[4]
                end
            },
             ["inOtherPhase"] = {
                name = L["In Other Phase"],
                desc = L["Custom Texture Options"],
                width = 1.5,
                type = "input",
                order = 16,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info,val)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.inOtherPhase = val

                    if val == "" then
                        self.RevertStatusIcon()
                    end

                    self:SafeRefresh(groupType)
                end,
                get = function(info) return self.db.profile[groupType].nameAndIcons.centerStatusIcon.inOtherPhase end
            },
            ["color inOtherPhase"] = {
                name = "",
                desc = "",
                width = "half",
                type = "color",
                order = 17,
                hasAlpha = true,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                hidden = function(info)
                    return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.toggle
                end,
                set = function(info, r, g, b, a)
                    self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.inOtherPhase = {r, g, b, a}
                    self:SafeRefresh(groupType)
                end,
                get = function(info)
                    local color = self.db.profile[groupType].nameAndIcons.centerStatusIcon.colors.inOtherPhase
                    return color[1], color[2], color[3], color[4]
                end
            },
            ["Skip2"] = {
                type = "header",
                name = "",
                order = 18,
            },
            ["Copy"] = {
                name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
                width = "normal",
                type = "execute",
                order = 19,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                confirm = true,
                func = function(info,val)
                    self:CopySettings(self.db.profile[groupType].nameAndIcons.centerStatusIcon, self.db.profile[self.ReverseGroupType(groupType)].nameAndIcons.centerStatusIcon)
                end,
            },
            ["Reset"] = {
                name = L["Reset to Default"],
                desc = "",
                width = "normal",
                type = "execute",
                confirm = true,
                order = 20,
                disabled = function() return not self.db.profile[groupType].nameAndIcons.centerStatusIcon.enabled end,
                func = function(info,val)
                    self:RestoreDefaults(groupType, "nameAndIcons", "centerStatusIcon")
                end,
            },
        },
    }

    return options
end

function KHMRaidFrames:SetupRaidIconOptions(groupType)
    local options = {
        ["enabled"] = {
            name = L["Enable"],
            desc = "",
            width = "normal",
            type = "toggle",
            order = 1,
            set = function(info,val)
                self.db.profile[groupType].raidIcon.enabled = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].raidIcon.enabled
            end
        },
        ["size"] = {
            name = L["Size"],
            desc = "",
            width = "double",
            type = "range",
            min = 1,
            max = 100,
            step = 1,
            order = 2,
            disabled = function(info)
                return not self.db.profile[groupType].raidIcon.enabled
            end,
            set = function(info,val)
                self.db.profile[groupType].raidIcon.size = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].raidIcon.size end
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
            disabled = function(info)
                return not self.db.profile[groupType].raidIcon.enabled
            end,
            set = function(info,val)
                self.db.profile[groupType].raidIcon.xOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].raidIcon.xOffset end
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
            disabled = function(info)
                return not self.db.profile[groupType].raidIcon.enabled
            end,
            set = function(info,val)
                self.db.profile[groupType].raidIcon.yOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].raidIcon.yOffset end
        },
        ["AnchorPoint"] = {
            name = L["Anchor Point"],
            desc = "",
            width = "normal",
            type = "select",
            values = positions,
            order = 5,
            disabled = function(info)
                return not self.db.profile[groupType].raidIcon.enabled
            end,
            set = function(info,val)
                self.db.profile[groupType].raidIcon.anchorPoint = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].raidIcon.anchorPoint end
        },
        ["Skip"] = {
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
                self:CopySettings(self.db.profile[groupType].raidIcon, self.db.profile[self.ReverseGroupType(groupType)].raidIcon)
            end,
        },
        ["Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            width = "double",
            type = "execute",
            confirm = true,
            order = 8,
            func = function(info,val)
                self:RestoreDefaults(groupType, "raidIcon")
            end,
        },
    }
    return options
end

function KHMRaidFrames:SetupFrameOptions(groupType)
    local options = {
        ["Texture"] = {
            name = L["Texture"],
            desc = "",
            width = "normal",
            type = "select",
            values = function(info, val) return self.sortedTextures end,
            order = 1,
            set = function(info,val)
                self.db.profile[groupType].frames.texture = self.sortedTextures[val]
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                for i, texture in ipairs(self.sortedTextures) do
                    if self.db.profile[groupType].frames.texture == texture then return i end
                end

                for i, texture in ipairs(self.sortedTextures) do
                    if self:Defaults().profile[groupType].frames.texture == texture then return i end
                end

                --fallback hack
                return 3
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
        ["Show Party When Solo"] = {
            name = L["Always Show Party Frame"],
            desc = L["Always Show Party Frame Desc"],
            width = "normal",
            type = "toggle",
            order = 3,
            hidden = function(info)
                return groupType == "raid"
            end,
            set = function(info,val)
                self.db.profile[groupType].frames.showPartySolo = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].frames.showPartySolo
            end
        },
        ["Skip1"] = {
                type = "header",
                name = "",
                order = 4,
            },
        ["HideGroupTitles"] = {
            name = L["Hide Group Title"],
            desc = "",
            width = "normal",
            type = "toggle",
            order = 5,
            set = function(info,val)
                self.db.profile[groupType].frames.hideGroupTitles = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].frames.hideGroupTitles
            end
        },
        ["Click Through"] = {
            name = L["Click Through Auras"],
            desc = L["Click Through Auras Desc"],
            width = "normal",
            type = "toggle",
            order = 6,
            set = function(info,val)
                self.db.profile[groupType].frames.clickThrough = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].frames.clickThrough
            end
        },
        ["Enhanced Absorbs"] = {
            name = L["Enhanced Absorbs"],
            desc = L["Enhanced Absorbs Desc"],
            width = "normal",
            type = "toggle",
            order = 7,
            confirm = true,
            confirmText = L["UI will be reloaded to apply settings"],
            set = function(info,val)
                self.db.profile[groupType].frames.enhancedAbsorbs = val
                self:SafeRefresh(groupType)
                ReloadUI()
            end,
            get = function(info)
                return self.db.profile[groupType].frames.enhancedAbsorbs
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
                self.db.profile[groupType].frames.tracking = self.SanitizeStringsByUnit(val)
                self.db.profile[groupType].frames.trackingStr = val

                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].frames.trackingStr
            end
        },
        ["Skip2"] = {
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
                self:CopySettings(self.db.profile[groupType].frames, self.db.profile[self.ReverseGroupType(groupType)].frames)
            end,
        },
        ["Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            width = "double",
            type = "execute",
            confirm = true,
            order = 13,
            func = function(info,val)
                self:RestoreDefaults(groupType, "frames")
            end,
        },
    }
    return options
end