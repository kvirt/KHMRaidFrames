local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")

local _G = _G
local frameStyle = "useCompactPartyFrames"


function KHMRaidFrames:Setup()
    self.maxFrames = 10 
    self.extraFrames = {}
    self.glowingFrames = {}
    self.virtual = {
        shown = false,
        frames = {},
    } 

    self:GetVirtualFrames()

    local defaults_settings = self:Defaults()
    self.db = LibStub("AceDB-3.0"):New("KHMRaidFramesDB", defaults_settings)

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    local LibDualSpec = LibStub("LibDualSpec-1.0")
    LibDualSpec:EnhanceDatabase(self.db, "KHMRaidFrames")
    LibDualSpec:EnhanceOptions(profiles, self.db)

    self.config = LibStub("AceConfigRegistry-3.0")
    self.config:RegisterOptionsTable("KHMRaidFrames", self:SetupOptions())
    self.config:RegisterOptionsTable("KHM Profiles", profiles)

    self.dialog = LibStub("AceConfigDialog-3.0")
    self.dialog.general = self.dialog:AddToBlizOptions("KHMRaidFrames", L["KHMRaidFrames"])
    self.dialog.profiles = self.dialog:AddToBlizOptions("KHM Profiles", L["Profiles"], "KHMRaidFrames")

    self:SecureHookScript(self.dialog.general, "OnShow", "OnOptionShow")
    self:SecureHookScript(self.dialog.general, "OnHide", "OnOptionHide")

    self:RegisterChatCommand("khm", function() 
        InterfaceOptionsFrame_OpenToCategory("KHMRaidFrames")
        InterfaceOptionsFrame_OpenToCategory("KHMRaidFrames")
    end)

    self:RegisterChatCommand("лрь", function() 
        InterfaceOptionsFrame_OpenToCategory("KHMRaidFrames")
        InterfaceOptionsFrame_OpenToCategory("KHMRaidFrames")
    end)      
end

function KHMRaidFrames:OnEnable()
    self:Setup()

    self.db.RegisterCallback(self, "OnProfileChanged", "SafeRefresh")
    self.db.RegisterCallback(self, "OnProfileCopied", "ProfileReload")
    self.db.RegisterCallback(self, "OnProfileReset", "ProfileReload") 

    local deferrFrame = CreateFrame("Frame")
    deferrFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    deferrFrame:RegisterEvent("RAID_TARGET_UPDATE")  -- raid target icon        
    deferrFrame:SetScript(
        "OnEvent", 
        function(frame, event)
            self:UpdateLayout()
        end
    ) 

    self:SecureHook(
        "CompactRaidFrameContainer_LayoutFrames", 
        function(container)
            self:UpdateLayout() 
        end
    )

    self:SecureHook(
        "CompactUnitFrame_UpdateAuras", 
        function(frame)
            if not UnitIsPlayer(frame.displayedUnit) or not frame:GetName() then
                return
            else
                self:UpdateAuras(frame)
            end
        end
    )

    self:SecureHook("CompactUnitFrame_UtilSetBuff")
    self:SecureHook("CompactUnitFrame_UtilSetDebuff")
    self:SecureHook("CompactUnitFrame_UtilSetDispelDebuff")        

    self:SecureHook("CompactUnitFrame_HideAllBuffs")
    self:SecureHook("CompactUnitFrame_HideAllDebuffs")
    self:SecureHook("CompactUnitFrame_HideAllDispelDebuffs")

    self:SafeRefresh()   
end

function KHMRaidFrames:ProfileReload()
    self.config:NotifyChange("KHMRaidFrames")
end

function KHMRaidFrames:OnOptionShow()
    if InCombatLockdown() then
        self:Print("Can not refresh settings while in combat")        
        self:HideAll() 
        return
    end

    self:ShowRaidFrame()
end

function KHMRaidFrames:OnOptionHide()
    self:HideRaidFrame()
end

function KHMRaidFrames:ShowRaidFrame()
    if not InCombatLockdown() and not IsInGroup() and GetCVar(frameStyle) == "1" then
        CompactRaidFrameContainer:Show()
        CompactRaidFrameManager:Show()
    end
end

function KHMRaidFrames:HideRaidFrame()
    if not InCombatLockdown() and not IsInGroup() and GetCVar(frameStyle) == "1" then
        CompactRaidFrameContainer:Hide()
        CompactRaidFrameManager:Hide()
    end

    self:HideVirtual()
end

function KHMRaidFrames:HideAll()
    _G["InterfaceOptionsFrame"]:Hide()  
end