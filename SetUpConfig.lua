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
        order = 2,
        name = L["Raid"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByType("raid"),
    }
    options.args.party = {
        type = "group",
        order = 3,
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
                order = 2,
                name = L["Aura Glow"],
                desc = "",
                childGroups = "tab",  
                args = self:GlowSubTypes("auraGlow"),     
            },
            ["frame glow"] = {
                type = "group",
                order = 3,
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

    return options
end

function KHMRaidFrames:SetupOptionsByType(groupType)
    local db = self.db.profile[groupType]

    self.groupType = groupType
    local options = {} 
    
    options.virtualFrames = {
        name = L["Show\\Hide Test Frames"],
        desc = "",
        descStyle = "inline",
        width = "full",
        type = "execute",
        order = 6,
        func = function(info,val)
            if self.virtual.shown == true then            
                self:HideVirtual()
            else                
                self:ShowVirtual(groupType)      
            end
        end,
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
        args = self:SetupOptionsByFrameType("buffFrames", db, groupType),        
    }
    options.debuffFrames = {
        type = "group",
        order = 4,
        name = L["Debuffs"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByFrameType("debuffFrames", db, groupType),        
    }
    options.dispelDebuffFrames = {
        type = "group",
        order = 5,
        name = L["Dispell Debuffs"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByFrameType("dispelDebuffFrames", db, groupType),  
    }
    options.raidIcon = {
        type = "group",
        order = 6,
        name = L["Raid Target Icon"],
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
            name = L["Enabled"],
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
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "execute",
            confirm = true,
            order = 7,
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
            width = "double",
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
        [frameType.."Show Big Debuffs"] = {
            name = L["Show Big Debuffs"],
            desc = "",
            descStyle = "inline",
            width = "double",
            type = "toggle",
            order = 5,        
            set = function(info,val)
                db.showBigDebuffs = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) 
                return db.showBigDebuffs 
            end
        },                   
        [frameType.."Skip"] = {
            type = "header",
            name = "",
            order = 6,
        },                         
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "execute",
            confirm = true,
            order = 7,
            func = function(info,val)
                self:RestoreDefaults(groupType, frameType)
            end,
        },                               
    }
    return options    
end

function KHMRaidFrames:SetupOptionsByFrameType(frameType, db, groupType)
    db = db[frameType]
    local num, frameName

    if frameType == "dispelDebuffFrames" then
        frameName = L["Dispell Debuffs"]
    elseif frameType == "debuffFrames" then
        frameName = L["Debuffs"]
    else
        frameName = L["Buffs"]
    end

    if frameType ~= "dispelDebuffFrames" then num = self.maxFrames else num = 4 end

    local options = {                
        ["num"..frameType] = {
            name = L["Num"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = 0,
            max = num,
            step = 1,
            order = 1,          
            set = function(info,val)
                db.num = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.num end
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
            order = 1,           
            set = function(info,val)
                db.size = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.size end
        },
        ["numInRow"..frameType] = {
            name = L["Num In Row"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = 1,
            max = num,
            step = 1,
            order = 2,          
            set = function(info,val)
                db.numInRow = val
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.numInRow end
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
            order = 2,          
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
            order = 2,          
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
            order = 3,           
            set = function(info,val)
                db.anchorPoint = val
                db.rowsGrowDirection = self.rowsGrows[val][db.growDirection]              
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.anchorPoint end
        },
        [frameType.."GrowDirection"] = {
            name = L["Grow Direction"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "select",
            values = grow_positions,
            order = 3,
            set = function(info,val)
                db.growDirection = val
                db.rowsGrowDirection = self.rowsGrows[db.anchorPoint][val]
                self:SafeRefresh(groupType)
            end,
            get = function(info) return db.growDirection end
        },                              
        [frameType.."Skip2"] = {
            type = "header",
            name = L["Block List"],
            order = 4,
        },
        ["exclude"..frameType] = {
            name = L["Exclude"],
            desc = L["Exclude auras"],
            usage = self:TrackingHelpText(),
            width = "full",
            type = "input",
            multiline = 5, 
            order = 6,                   
            set = function(info,val)
                db.exclude = self:SanitizeStrings(val)
                db.excludeStr = val

                self:SafeRefresh(groupType)
            end,
            get = function(info)
                return db.excludeStr
            end              
        },                      
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "execute",
            order = 7,
            confirm = true,
            func = function(info,val)
                self:RestoreDefaults(groupType, frameType)
            end,
        },                       
    }
    return options   
end