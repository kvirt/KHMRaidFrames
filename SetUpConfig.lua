local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")
-- useCompactPartyFrames, showPartyPets, raidOptionDisplayPets, raidFramesDisplayPowerBars, raidOptionDisplayMainTankAndAssist, raidOptionKeepGroupsTogether, https://wow.gamepedia.com/Console_variables
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
        name = L["Raid Frames"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByType("raid"),
    }
    options.args.party = {
        type = "group",
        order = 3,
        name = L["Party Frames"],
        desc = "",
        childGroups = "tab",          
        args = self:SetupOptionsByType("party"),                  
    }

    return options
end

function KHMRaidFrames:SetupOptionsByType(groupType)
    local db = self.db.profile[groupType]
    local options = {}

    options.virtualFrames = {
        name = L["Show\\Hide Test Frames"],
        desc = "",
        descStyle = "inline",
        width = "full",
        type = "execute",
        order = 6,
        func = function(info,val)
            self:ShowVirtual(groupType)
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
        args = self:SetupOptionsByFrameTypeProxy("buffFrames", db, groupType),        
    }
    options.debuffFrames = {
        type = "group",
        order = 4,
        name = L["Debuffs"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByFrameTypeProxy("debuffFrames", db, groupType),        
    }
    options.dispelDebuffFrames = {
        type = "group",
        order = 5,
        name = L["Dispell Debuffs"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByFrameTypeProxy("dispelDebuffFrames", db, groupType),  
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

function KHMRaidFrames:SetupOptionsByFrameTypeProxy(frameType, db, groupType)
    local options = {}

    options.properties = {
        type = "group",
        order = 1,
        name = L["Properties"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByFrameType(frameType, db, groupType),     
    }

    local glows = self:SetupGlowOptionsProxy(frameType, db, groupType)
    options.glow = glows.glow
    options.frameGlow = glows.frameGlow

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
                self:SafeRefresh()
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
                self:SafeRefresh()
            end,
            get = function(info) return db.size end
        },
        ["xOffset"..frameType] = {
            name = L["X Offset"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 3,          
            disabled = function(info)
                return not db.enabled
            end,              
            set = function(info,val)
                db.xOffset = val
                self:SafeRefresh()
            end,
            get = function(info) return db.xOffset end
        },
        ["yOffset"..frameType] = {
            name = L["Y Offset"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 4,
            disabled = function(info)
                return not db.enabled
            end,                        
            set = function(info,val)
                db.yOffset = val
                self:SafeRefresh()
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
                self:SafeRefresh()
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
                self:SafeRefresh()
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
            values = function(info, val)
                local textures = SharedMedia:HashTable("statusbar")
                local t = {}
                for k, v in pairs(textures) do
                    t[v] = k
                end
                table.sort(t, function(a, b) return a:upper() < b:upper() end)
                self.textures = t                    
                return t
            end, 
            order = 3,        
            set = function(info,val)
                db.texture = val
                self:SafeRefresh()
            end,
            get = function(info) return db.texture end
        },
        [frameType.."Skip"] = {
            type = "header",
            name = "",
            order = 4,
        },                         
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "execute",
            confirm = true,
            order = 5,
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
                self:SafeRefresh()
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
                self:SafeRefresh()
            end,
            get = function(info) return db.size end
        },
        ["numInRow"..frameType] = {
            name = L["Num In Row"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = 0,
            max = num,
            step = 1,
            order = 2,          
            set = function(info,val)
                db.numInRow = val
                self:SafeRefresh()
            end,
            get = function(info) return db.numInRow end
        },                
        ["xOffset"..frameType] = {
            name = L["X Offset"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 2,          
            set = function(info,val)
                db.xOffset = val
                self:SafeRefresh()
            end,
            get = function(info) return db.xOffset end
        },
        ["yOffset"..frameType] = {
            name = L["Y Offset"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 2,          
            set = function(info,val)
                db.yOffset = val
                self:SafeRefresh()
            end,
            get = function(info) return db.yOffset end
        },       
        [frameType.."rowsGrowDirection"] = {
            name = L["Rows Grow Direction"],
            desc = "",
            descStyle = "inline",
            width = "normal",
            type = "select",
            values = grow_positions,
            order = 3,
            set = function(info,val)
                db.rowsGrowDirection = val
                self:SafeRefresh()
            end,
            get = function(info) return db.rowsGrowDirection end
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
                self:SafeRefresh()
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
                self:SafeRefresh()
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
            desc = L["Use to block auras"],
            usage = self:TrackingHelpText(),
            width = "full",
            type = "input",
            multiline = 5, 
            order = 6,                   
            set = function(info,val)
                db.exclude = self:SanitizeStrings(val)
                db.excludeStr = val

                self:SafeRefresh()
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