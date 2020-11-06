local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")
local SharedMedia = LibStub:GetLibrary("LibSharedMedia-3.0")

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

function KHMRaidFrames:SetupOptionsByType(frameType)
    local db = self.db.profile[frameType]
    local options = {}

    options.frames = {
        type = "group",
        order = 2,
        name = L["Frames"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupFrameOptions("frames", db, frameType),     
    }
    options.buffFrames = {
        type = "group",
        order = 3,
        name = L["Buffs"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByFrameType("buffFrames", db, frameType),        
    }
    options.debuffFrames = {
        type = "group",
        order = 4,
        name = L["Debuffs"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByFrameType("debuffFrames", db, frameType),        
    }
    options.dispelDebuffFrames = {
        type = "group",
        order = 5,
        name = L["Dispell Debuffs"],
        desc = "",
        childGroups = "tab",  
        args = self:SetupOptionsByFrameType("dispelDebuffFrames", db, frameType),  
    }

    return options
end        

function KHMRaidFrames:SetupFrameOptions(frameType, db, partyType)
    local halfWidth = 1.6

    db = db[frameType]

    local options = {            
        [frameType.."HideGroupTitles"] = {
            name = L["Hide Group Title"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "toggle",
            order = 2,
            set = function(info,val)
                db.hideGroupTitles = val
                self:RefreshConfig()
            end,
            get = function(info) 
                return db.hideGroupTitles 
            end
        },                   
        [frameType.."Texture"] = {
            name = L["Texture"],
            desc = "",
            descStyle = "inline",
            width = "full",
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
                self:RefreshConfig()
            end,
            get = function(info) return db.texture end
        },
        [frameType.."Skip"] = {
            type = "header",
            name = "",
            order = 4,
        },                  
        [frameType.."Skip2"] = {
            type = "header",
            name = "",
            order = 5,
        },         
        [frameType.."Reset"] = {
            name = L["Reset to Default"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "execute",
            order = 6,
            func = function(info,val)
                self:RestoreDefaults(partyType, frameType)
            end,
        },                       
    }
    return options    
end

function KHMRaidFrames:SetupOptionsByFrameType(frameType, db, partyType)
    local halfWidth = 1.6

    db = db[frameType]

    local options = {                
        ["num"..frameType] = {
            name = L["Num"],
            desc = "",
            descStyle = "inline",
            width = halfWidth,
            type = "range",
            min = 0,
            max = 3,
            step = 1,
            order = 1,          
            set = function(info,val)
                db.num = val
                self:RefreshConfig()
            end,
            get = function(info) return db.num end
        },
        ["size"..frameType] = {
            name = L["Size"],
            desc = "",
            descStyle = "inline",
            width = halfWidth,
            type = "range",
            min = 1,
            max = 100,
            step = 1,
            order = 1,           
            set = function(info,val)
                db.size = val
                self:RefreshConfig()
            end,
            get = function(info) return db.size end
        },
        ["xOffset"..frameType] = {
            name = L["X Offset"],
            desc = "",
            descStyle = "inline",
            width = halfWidth,
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 2,          
            set = function(info,val)
                db.xOffset = val
                self:RefreshConfig()
            end,
            get = function(info) return db.xOffset end
        },
        ["yOffset"..frameType] = {
            name = L["Y Offset"],
            desc = "",
            descStyle = "inline",
            width = halfWidth,
            type = "range",
            min = -100,
            max = 100,
            step = 1,
            order = 2,          
            set = function(info,val)
                db.yOffset = val
                self:RefreshConfig()
            end,
            get = function(info) return db.yOffset end
        },                                      
        [frameType.."AnchorPoint"] = {
            name = L["Anchor Point"],
            desc = "",
            descStyle = "inline",
            width = halfWidth,
            type = "select",
            values = positions,
            order = 3,           
            set = function(info,val)
                db.anchorPoint = val
                self:RefreshConfig()
            end,
            get = function(info) return db.anchorPoint end
        },
        [frameType.."GrowDirection"] = {
            name = L["Grow Direction"],
            desc = "",
            descStyle = "inline",
            width = halfWidth,
            type = "select",
            values = grow_positions,
            order = 3,
            set = function(info,val)
                db.growDirection = val
                self:RefreshConfig()
            end,
            get = function(info) return db.growDirection end
        },
        [frameType.."Skip"] = {
            type = "header",
            name = "",
            order = 4,
        },        
        [frameType.."Virtual"] = {
            name = L["Show\\Hide Test Frames"],
            desc = "",
            descStyle = "inline",
            width = "full",
            type = "execute",
            order = 5,
            func = function(info,val)
                self:ShowVirtual(info)
            end,
        },         
        [frameType.."Skip2"] = {
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
            order = 7,
            func = function(info,val)
                self:RestoreDefaults(partyType, frameType)
            end,
        },                       
    }
    return options   
end