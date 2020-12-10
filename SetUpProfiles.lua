local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")


function KHMRaidFrames:SetupProfiles()
    local options = {
        name = L["KHM Profile Stuff"],
        type = "group",
        childGroups = "tab",
        order = 1,
    }

    options.args = {}

    options.args.sync = {
        name = L["Sync Profiles"],
        desc = L["Sync Profiles Desc"],
        descStyle = "inline",
        width = "full",
        type = "toggle",
        order = 1,
        set = function(info,val)
            KHMRaidFrames_SyncProfiles = val
        end,
        get = function(info,val)
            return KHMRaidFrames_SyncProfiles
        end,
    }

    options.args.export = {
        name = L["Export Profile"],
        desc = "",
        width = "full",
        type = "execute",
        order = 2,
        func = function(info,val)
            self.ExportCurrentProfile(self.ExportProfileToString())
            self:HideAll()
        end,
    }

    options.args.import = {
        name = L["Import Profile"],
        desc = "",
        width = "full",
        type = "input",
        multiline = 10,
        confirm = true,
        confirmText = L["Are You sure?"],
        order = 3,
        set = function(info,val)
            self.ImportCurrentProfile(val)
            ReloadUI()
        end,
    }
    return options
end
