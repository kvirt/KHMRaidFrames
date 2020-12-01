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


function KHMRaidFrames:SetupOptions()
    local options = {
        name = L["KHMRaidFrames"],
        descStyle = "inline",
        type = "group",
        childGroups = "tab",  
        order = 1,            
    }

    options.args = {}

    options.args.raid = {
        type = "group",
        order = 1,
        name = L["Raid"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByType("raid"),
    }
    options.args.party = {
        type = "group",
        order = 2,
        name = L["Party"],
        desc = "",
        childGroups = "tab",          
        args = self:SetupOptionsByType("party"),                  
    }
    options.args.glows = {
        type = "group",
        order = 3,
        name = L["Glows"],
        desc = "",
        childGroups = "tab",          
        args = {
            ["aura glow"] = {
                type = "group",
                order = 1,
                name = L["Aura Glow"],
                desc = "",
                childGroups = "tab",  
                args = self:GlowSubTypes("auraGlow"),     
            },
            ["frame glow"] = {
                type = "group",
                order = 2,
                name = L["Frame Glow"],
                desc = "",
                childGroups = "tab",  
                args = self:GlowSubTypes("frameGlow"),        
            },
            ["glow block list"] = {
                type = "group",
                order = 3,
                name = L["Block List"],
                desc = "",
                childGroups = "tab",  
                args = {
                    ["glowBlockList"] = {
                        name = L["Block List"],
                        desc = L["Exclude auras from Glows"],
                        usage = self:ExcludeHelpText(),
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
                        descStyle = "inline",
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
        desc = "",
        descStyle = "inline",
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
        desc = "",
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
    options.dispelDebuffFrames = {
        type = "group",
        order = 5,
        name = L["Dispell Debuffs"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupDispelldebuffFrames(db.dispelDebuffFrames, groupType),  
    }
    options.raidIcon = {
        type = "group",
        order = 6,
        name = L["Raid Icon"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupRaidIconOptions("raidIcon", db, groupType),  
    }

    return options
end        

function KHMRaidFrames:SetupRaidIconOptions(frameType, db, groupType)
    db = db[frameType]

    local options = {            
        [frameType.."enabled"] = {
            name = L["Enable"],
            desc = "",
            descStyle = "inline",
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
            descStyle = "inline",
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
            descStyle = "inline",
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
            descStyle = "inline",
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
            descStyle = "inline",
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
            descStyle = "inline",
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
        [frameType.."HideGroupTitles"] = {
            name = L["Hide Group Title"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "toggle",
            order = 2,
            set = function(info,val)
                db.hideGroupTitles = val
                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return db.hideGroupTitles 
            end
        },                   
        [frameType.."Texture"] = {
            name = L["Texture"],
            desc = "",
            descStyle = "inline",
            width = "double",
            type = "select",
            values = function(info, val) return self.sortedTextures end, 
            order = 3,        
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
        [frameType.."Click Through"] = {
            name = L["Click Through Auras"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "toggle",
            order = 4,        
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
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "toggle",
            order = 5,
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
        [frameType.."Show Party When Solo"] = {
            name = L["Show Party When Solo"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "toggle",
            order = 6,
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
        ["additionalTracking"] = {
            name = L["Additional Auras Tracking"],
            desc = L["Track Auras that are not shown by default by Blizzard"],
            usage = self:TrackingHelpText(),
            width = "full",
            type = "input",
            multiline = 10, 
            order = 7,                   
            set = function(info,val)
                db.tracking = self:SanitizeStrings(val)
                db.trackingStr = val

                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return db.trackingStr
            end              
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
            func = function(info,val)
                self:CopySettings(db, self.db.profile[self.ReverseGroupType(groupType)][frameType])
            end,
        },                                  
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            descStyle = "inline",
            width = "double",
            type = "execute",
            confirm = true,
            order = 10,
            func = function(info,val)
                self:RestoreDefaults(groupType, frameType)
            end,
        },                               
    }
    return options    
end