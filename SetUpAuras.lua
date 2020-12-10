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

local grow_positions = {
    ["LEFT"] = L["LEFT"],
    ["BOTTOM"] = L["BOTTOM"],
    ["RIGHT"] = L["RIGHT"],
    ["TOP"] = L["TOP"],
}

function KHMRaidFrames:SetupBuffFrames(groupType)
    local options = {
        ["num"] = {
            name = L["Num"],
            desc = "",
            width = "normal",
            type = "range",
            min = 0,
            max = 10,
            step = 1,
            order = 1,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.num = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].buffFrames.num end
        },
        ["size"] = {
            name = L["Size"],
            desc = "",
            width = "double",
            type = "range",
            min = 1,
            max = 100,
            step = 1,
            order = 1,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.size = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].buffFrames.size end
        },
        ["numInRow"] = {
            name = L["Num In Row"],
            desc = "",
            width = "normal",
            type = "range",
            min = 1,
            max = 10,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.numInRow = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].buffFrames.numInRow end
        },
        ["xOffset"] = {
            name = L["X Offset"],
            desc = "",
            width = "normal",
            type = "range",
            min = -200,
            max = 200,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.xOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].buffFrames.xOffset end
        },
        ["yOffset"] = {
            name = L["Y Offset"],
            desc = "",
            width = "normal",
            type = "range",
            min = -200,
            max = 200,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.yOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].buffFrames.yOffset end
        },
        ["AnchorPoint"] = {
            name = L["Anchor Point"],
            desc = "",
            width = "normal",
            type = "select",
            values = positions,
            order = 3,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.anchorPoint = val
                self.db.profile[groupType].buffFrames.rowsGrowDirection = self.rowsGrows[val][self.db.profile[groupType].buffFrames.growDirection]
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].buffFrames.anchorPoint end
        },
        ["GrowDirection"] = {
            name = L["Grow Direction"],
            desc = "",
            width = "normal",
            type = "select",
            values = grow_positions,
            order = 3,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.growDirection = val
                self.db.profile[groupType].buffFrames.rowsGrowDirection = self.rowsGrows[self.db.profile[groupType].buffFrames.anchorPoint][val]
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].buffFrames.growDirection end
        },
        ["alpha"] = {
            name = L["Transparency"],
            desc = "",
            width = "normal",
            type = "range",
            min = 0.1,
            max = 1.0,
            step = 0.1,
            order = 4,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.alpha = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].buffFrames.alpha end
        },
        ["Skip3"] = {
            type = "header",
            name = L["Block List"],
            order = 6,
        },
        ["exclude"] = {
            name = L["Exclude"],
            desc = L["Exclude auras"],
            usage = self:TrackingHelpText(),
            width = "full",
            type = "input",
            multiline = 5,
            order = 7,
            set = function(info,val)
                self.db.profile[groupType].buffFrames.exclude = self:SanitizeStrings(val)
                self.db.profile[groupType].buffFrames.excludeStr = val

                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].buffFrames.excludeStr
            end
        },
        ["Copy"] = {
            name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            width = "normal",
            type = "execute",
            order = 8,
            confirm = true,
            func = function(info,val)
                self:CopySettings(self.db.profile[groupType].buffFrames, self.db.profile[self.ReverseGroupType(groupType)].buffFrames)
            end,
        },
        ["Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            width = "double",
            type = "execute",
            order = 8,
            confirm = true,
            func = function(info,val)
                self:RestoreDefaults(groupType, "buffFrames")
            end,
        },
    }
    return options
end

function KHMRaidFrames:SetupDebuffFrames(groupType)

    local options = {
        ["num"] = {
            name = L["Num"],
            desc = "",
            width = "normal",
            type = "range",
            min = 0,
            max = 10,
            step = 1,
            order = 1,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.num = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.num end
        },
        ["size"] = {
            name = L["Size"],
            desc = "",
            width = "double",
            type = "range",
            min = 1,
            max = 100,
            step = 1,
            order = 1,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.size = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.size end
        },
        ["numInRow"] = {
            name = L["Num In Row"],
            desc = "",
            width = "normal",
            type = "range",
            min = 1,
            max = 10,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.numInRow = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.numInRow end
        },
        ["xOffset"] = {
            name = L["X Offset"],
            desc = "",
            width = "normal",
            type = "range",
            min = -200,
            max = 200,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.xOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.xOffset end
        },
        ["yOffset"] = {
            name = L["Y Offset"],
            desc = "",
            width = "normal",
            type = "range",
            min = -200,
            max = 200,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.yOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.yOffset end
        },
        ["AnchorPoint"] = {
            name = L["Anchor Point"],
            desc = "",
            width = "normal",
            type = "select",
            values = positions,
            order = 3,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.anchorPoint = val
                self.db.profile[groupType].debuffFrames.rowsGrowDirection = self.rowsGrows[val][self.db.profile[groupType].debuffFrames.growDirection]
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.anchorPoint end
        },
        ["GrowDirection"] = {
            name = L["Grow Direction"],
            desc = "",
            width = "normal",
            type = "select",
            values = grow_positions,
            order = 3,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.growDirection = val
                self.db.profile[groupType].debuffFrames.rowsGrowDirection = self.rowsGrows[self.db.profile[groupType].debuffFrames.anchorPoint][val]
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.growDirection end
        },
        ["alpha"] = {
            name = L["Transparency"],
            desc = "",
            width = "normal",
            type = "range",
            min = 0.1,
            max = 1.0,
            step = 0.1,
            order = 4,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.alpha = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.alpha end
        },
        ["Skip2"] = {
            type = "header",
            name = L["Big Debuffs"],
            order = 6,
        },
        ["Show Big Debuffs"] = {
            name = L["Show Big Debuffs"],
            desc = "",
            width = "normal",
            type = "toggle",
            order = 7,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.showBigDebuffs = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].debuffFrames.showBigDebuffs
            end
        },
        ["Smart Anchoring"] = {
            name = L["Align Big Debuffs"],
            desc = L["Align Big Debuffs Desc"],
            width = "normal",
            type = "toggle",
            order = 8,
            disabled = function(info)
                return not self.db.profile[groupType].debuffFrames.showBigDebuffs
            end,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.smartAnchoring = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].debuffFrames.smartAnchoring
            end
        },
        ["bigDebuffSize"] = {
            name = L["Size"],
            desc = "",
            width = "normal",
            type = "range",
            min = 1,
            max = 100,
            step = 1,
            order = 9,
            disabled = function(info)
                return not self.db.profile[groupType].debuffFrames.showBigDebuffs or self.db.profile[groupType].debuffFrames.smartAnchoring
            end,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.bigDebuffSize = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].debuffFrames.bigDebuffSize end
        },
        ["Skip3"] = {
            type = "header",
            name = L["Block List"],
            order = 10,
        },
        ["exclude"] = {
            name = L["Exclude"],
            desc = L["Exclude auras"],
            usage = self:TrackingHelpText(),
            width = "full",
            type = "input",
            multiline = 5,
            order = 11,
            set = function(info,val)
                self.db.profile[groupType].debuffFrames.exclude = self:SanitizeStrings(val)
                self.db.profile[groupType].debuffFrames.excludeStr = val

                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].debuffFrames.excludeStr
            end
        },
        ["Copy"] = {
            name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            width = "normal",
            type = "execute",
            order = 12,
            confirm = true,
            func = function(info,val)
                self:CopySettings(self.db.profile[groupType].debuffFrames, self.db.profile[self.ReverseGroupType(groupType)].debuffFrames)
            end,
        },
        ["Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            width = "double",
            type = "execute",
            order = 13,
            confirm = true,
            func = function(info,val)
                self:RestoreDefaults(groupType, "debuffFrames")
            end,
        },
    }
    return options
end

function KHMRaidFrames:SetupDispelldebuffFrames(groupType)

    local options = {
        ["num"] = {
            name = L["Num"],
            desc = "",
            width = "normal",
            type = "range",
            min = 0,
            max = 4,
            step = 1,
            order = 1,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.num = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].dispelDebuffFrames.num end
        },
        ["size"] = {
            name = L["Size"],
            desc = "",
            width = "double",
            type = "range",
            min = 1,
            max = 100,
            step = 1,
            order = 1,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.size = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].dispelDebuffFrames.size end
        },
        ["numInRow"] = {
            name = L["Num In Row"],
            desc = "",
            width = "normal",
            type = "range",
            min = 1,
            max = 4,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.numInRow = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].dispelDebuffFrames.numInRow end
        },
        ["xOffset"] = {
            name = L["X Offset"],
            desc = "",
            width = "normal",
            type = "range",
            min = -200,
            max = 200,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.xOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].dispelDebuffFrames.xOffset end
        },
        ["yOffset"] = {
            name = L["Y Offset"],
            desc = "",
            width = "normal",
            type = "range",
            min = -200,
            max = 200,
            step = 1,
            order = 2,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.yOffset = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].dispelDebuffFrames.yOffset end
        },
        ["AnchorPoint"] = {
            name = L["Anchor Point"],
            desc = "",
            width = "normal",
            type = "select",
            values = positions,
            order = 3,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.anchorPoint = val
                self.db.profile[groupType].dispelDebuffFrames.rowsGrowDirection = self.rowsGrows[val][self.db.profile[groupType].dispelDebuffFrames.growDirection]
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].dispelDebuffFrames.anchorPoint end
        },
        ["GrowDirection"] = {
            name = L["Grow Direction"],
            desc = "",
            width = "normal",
            type = "select",
            values = grow_positions,
            order = 3,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.growDirection = val
                self.db.profile[groupType].dispelDebuffFrames.rowsGrowDirection = self.rowsGrows[self.db.profile[groupType].dispelDebuffFrames.anchorPoint][val]
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].dispelDebuffFrames.growDirection end
        },
        ["alpha"] = {
            name = L["Transparency"],
            desc = "",
            width = "normal",
            type = "range",
            min = 0.1,
            max = 1.0,
            step = 0.1,
            order = 4,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.alpha = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return self.db.profile[groupType].dispelDebuffFrames.alpha end
        },
        ["Skip3"] = {
            type = "header",
            name = L["Block List"],
            order = 5,
        },
        ["exclude"] = {
            name = L["Exclude"],
            desc = L["Exclude auras"],
            usage = self:TrackingHelpText(),
            width = "full",
            type = "input",
            multiline = 5,
            order = 6,
            set = function(info,val)
                self.db.profile[groupType].dispelDebuffFrames.exclude = self:SanitizeStrings(val)
                self.db.profile[groupType].dispelDebuffFrames.excludeStr = val

                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return self.db.profile[groupType].dispelDebuffFrames.excludeStr
            end
        },
        ["Copy"] = {
            name = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            desc = L["Copy settings to |cFFffd100<text>|r"]:gsub("<text>", groupType == "party" and L["Raid"] or L["Party"]),
            width = "normal",
            type = "execute",
            order = 7,
            confirm = true,
            func = function(info,val)
                self:CopySettings(self.db.profile[groupType].dispelDebuffFrames, self.db.profile[self.ReverseGroupType(groupType)].dispelDebuffFrames)
            end,
        },
        ["Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            width = "double",
            type = "execute",
            order = 8,
            confirm = true,
            func = function(info,val)
                self:RestoreDefaults(groupType, "dispelDebuffFrames")
            end,
        },
    }
    return options
end