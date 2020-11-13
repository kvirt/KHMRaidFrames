local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")

local _G = _G


function KHMRaidFrames:OnInitialize()
     self:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
end

function KHMRaidFrames:Setup()
    self:GetRaidProfileSettings()

    self.isOpen = false

    self.maxFrames = 10 
    self.extraFrames = {}
    self.glowingFrames = {
        party = {
            frames = {},
        },
        raid = {
            frames = {},
        },
    }
    self.virtual = {
        shown = false,
        frames = {},
    } 
    self.aurasCache = {}

    for subFrame in self:IterateSubFrameTypes() do
        self.glowingFrames.party[subFrame] = {}
        self.glowingFrames.raid[subFrame] = {}
        self.aurasCache[subFrame] = {}
    end

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

function KHMRaidFrames:COMPACT_UNIT_FRAME_PROFILES_LOADED()
    self:Setup()

    self.db.RegisterCallback(self, "OnProfileChanged", "SafeRefresh")
    self.db.RegisterCallback(self, "OnProfileCopied", "ProfileReload")
    self.db.RegisterCallback(self, "OnProfileReset", "ProfileReload") 

    local deferrFrame = CreateFrame("Frame")
    deferrFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    deferrFrame:RegisterEvent("PLAYER_REGEN_DISABLED")    
    deferrFrame:RegisterEvent("RAID_TARGET_UPDATE")  -- raid target icon    
    deferrFrame:SetScript(
        "OnEvent", 
        function(frame, event)
            self:UpdateLayout()

            if event == "PLAYER_REGEN_ENABLED" and self.deffered then
                self:SafeRefresh()

                InterfaceOptionsFrame_OpenToCategory("KHMRaidFrames")
                InterfaceOptionsFrame_OpenToCategory("KHMRaidFrames")

                self.deffered = false
            elseif event == "PLAYER_REGEN_DISABLED" and self.isOpen then
                self:HideAll()
                self.deffered = true         
            end
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
    
    self:SecureHook("CompactUnitFrameProfiles_ApplyProfile", "GetRaidProfileSettings")

    self:SecureHook(
        "SetCVar",         
        function(cvar, value)
            if InCombatLockdown() then return end
            if cvar == "useCompactPartyFrames" then
                self.useCompactPartyFrames = value
                
                if self.db then
                    self:SafeRefresh()
                end
            end        
        end
    )

    self:SafeRefresh()   
end

function KHMRaidFrames:GetRaidProfileSettings(profile)
    if InCombatLockdown() then return end

    local settings = GetRaidProfileFlattenedOptions(profile or GetActiveRaidProfile())

    self.horizontalGroups = settings.horizontalGroups
    self.displayMainTankAndAssist =  settings.displayMainTankAndAssist
    self.keepGroupsTogether = settings.keepGroupsTogether
    self.displayBorder = settings.displayBorder
    self.frameWidth = settings.frameWidth
    self.frameHeight = settings.frameHeight
    self.displayPowerBar = settings.displayPowerBar
    self.displayPets = settings.displayPets
    self.useCompactPartyFrames = settings.shown
    self.useCompactPartyFrames = GetCVar("useCompactPartyFrames") == "1"

    if self.db then
        self:SafeRefresh()
    end
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

    self.isOpen = true
    self:ShowRaidFrame()
end

function KHMRaidFrames:OnOptionHide()
    self.isOpen = false
    self:HideRaidFrame()
end

function KHMRaidFrames:ShowRaidFrame()
    if not InCombatLockdown() and not IsInGroup() and self.useCompactPartyFrames then
        CompactRaidFrameContainer:Show()
        CompactRaidFrameManager:Show()
    end
end

function KHMRaidFrames:HideRaidFrame()
    if not InCombatLockdown() and not IsInGroup() and self.useCompactPartyFrames then
        CompactRaidFrameContainer:Hide()
        CompactRaidFrameManager:Hide()
    end

    self:HideVirtual()
end

function KHMRaidFrames:HideAll()
    _G["InterfaceOptionsFrame"]:Hide()  
end