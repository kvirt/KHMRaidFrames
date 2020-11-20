local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")

local _G, CompactRaidFrameContainer = _G, CompactRaidFrameContainer
local reloadConfirmation = "KHMRaidFrames_PROFILE_RELOAD"
StaticPopupDialogs[reloadConfirmation] = {
    text = "Reload needed to apply profile",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        ReloadUI()
    end, 
    OnCancel = function(self)
       KHMRaidFrames:Print("The user interface is not reloaded. To fix it, enter \"\/reload\" in chat.")
        end,
    timeout = 0,
    hideOnEscape = 1,
}


function KHMRaidFrames:OnInitialize()
     self:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
end

function KHMRaidFrames:Setup()
    self:GetRaidProfileSettings()

    self.isOpen = false

    self.maxFrames = 10 
    self.virtual = {
        shown = false,
        frames = {},
    } 
    self.aurasCache = {}
    self.processedFrames = {}
    self.glowingFrames = {
        auraGlow = {
            buffFrames = {},
            debuffFrames = {},
        },
        frameGlow = {
            buffFrames = {},
            debuffFrames = {},            
        },
    }

    self:GetVirtualFrames()

    self.textures, self.sortedTextures = self:GetTextures()

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

    self:RegisterChatCommand("кд", function() ReloadUI() end)         
end

function KHMRaidFrames:COMPACT_UNIT_FRAME_PROFILES_LOADED()
    self:Setup()

    self.db.RegisterCallback(
        self, "OnProfileChanged", 
        function(...) StaticPopup_Show(reloadConfirmation)                    
    end)
    self.db.RegisterCallback(
        self, "OnProfileCopied", 
        function(...) StaticPopup_Show(reloadConfirmation)                             
    end)
    self.db.RegisterCallback(
        self, "OnProfileReset", 
        function(...) StaticPopup_Show(reloadConfirmation)               
    end)

    local deferrFrame = CreateFrame("Frame")
    deferrFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    deferrFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
    deferrFrame:RegisterEvent("PLAYER_ROLES_ASSIGNED")
    deferrFrame:RegisterEvent("RAID_TARGET_UPDATE")  -- raid target icon    
    deferrFrame:SetScript(
        "OnEvent", 
        function(frame, event)
            local groupType = IsInRaid() and "raid" or "party"

            if event == "PLAYER_REGEN_ENABLED" then
                self:SafeRefresh(groupType)

                if self.deffered then                
                    InterfaceOptionsFrame_OpenToCategory("KHMRaidFrames")
                    InterfaceOptionsFrame_OpenToCategory("KHMRaidFrames")

                    self.deffered = false
                end
            elseif event == "PLAYER_REGEN_DISABLED" and self.isOpen then
                self:HideAll()
                self.deffered = true
            elseif event == "RAID_TARGET_UPDATE" or event == "PLAYER_ROLES_ASSIGNED" then
                self:UpdateRaidMark(groupType)
            end
        end
    ) 

    self:SecureHook(
        "CompactRaidFrameContainer_LayoutFrames", 
        function()
            local groupType = IsInRaid() and "raid" or "party"
            self:CUFDefaults(groupType)
        end
    )

    self:SecureHook(
        "CompactUnitFrame_UpdateAuras", 
        function(frame)
            if not UnitIsPlayer(frame.displayedUnit) or not frame:GetName() then
                return
            elseif frame:GetName() and frame:GetName():find("^NamePlate%d") then
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
            local groupType = IsInRaid() and "raid" or "party"

            if cvar == "useCompactPartyFrames" then
                self.useCompactPartyFrames = value
                
                if self.db then
                    self:SafeRefresh(groupType)
                end
            end        
        end
    )

    self:SafeRefresh()
end

function KHMRaidFrames:RefreshConfig(groupType)
    local isInCombatLockDown = InCombatLockdown()

    for frameType in self:IterateSubFrameTypes() do
        self:SetUpVirtual(frameType, groupType)
    end

    for group in self:IterateCompactGroups(groupType) do
        self:DefaultGroupSetUp(group, groupType, isInCombatLockDown)
    end

    for frame in self:IterateCompactFrames(groupType) do
        self:DefaultFrameSetUp(frame, groupType, isInCombatLockDown)
    end
end    

function KHMRaidFrames:GetRaidProfileSettings(profile)
    if InCombatLockdown() then return end

    local settings = GetRaidProfileFlattenedOptions(profile or GetActiveRaidProfile())

    if not settings then return end

    self.horizontalGroups = settings.horizontalGroups
    self.displayMainTankAndAssist =  settings.displayMainTankAndAssist
    self.keepGroupsTogether = settings.keepGroupsTogether
    self.displayBorder = settings.displayBorder
    self.frameWidth = settings.frameWidth
    self.frameHeight = settings.frameHeight
    self.displayPowerBar = settings.displayPowerBar
    self.displayPets = settings.displayPets
    self.useCompactPartyFrames = GetCVar("useCompactPartyFrames") == "1"

    if self.db then
        self:SafeRefresh()
    end
end

function KHMRaidFrames:OnOptionShow()
    if InCombatLockdown() then        
        self:HideAll()
        self.deffered = true
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