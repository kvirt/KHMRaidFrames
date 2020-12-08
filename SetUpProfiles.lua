local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")


function KHMRaidFrames:SetupProfiles(options)
    options.args.line = {
        type = "header",
        name = "",
        order = 97,
    }

    options.args.export = {
        name = L["Export Profile"],
        desc = "",
        width = "full",
        type = "execute",
        order = 98,
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
        confirmText = L["Are You sure?"],
        order = 99,
        set = function(info,val)
            self.ImportCurrentProfile(val)
            ReloadUI()
        end,
    }
    return options
end
