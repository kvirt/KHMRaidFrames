local KHMRaidFrames = LibStub("AceAddon-3.0"):GetAddon("KHMRaidFrames")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")

local _G, CompactRaidFrameContainer = _G, CompactRaidFrameContainer
KHMRaidFrames.reloadConfirmation = "KHMRaidFrames_PROFILE_RELOAD"
StaticPopupDialogs[KHMRaidFrames.reloadConfirmation] = {
    text = "Reload needed to apply settings",
    button1 = YES,
    button2 = NO,
    OnAccept = function(self)
        ReloadUI()
    end,
    OnCancel = function(self) end,
    timeout = 0,
    hideOnEscape = 1,
}


function KHMRaidFrames:OnInitialize()
     self:RegisterEvent("COMPACT_UNIT_FRAME_PROFILES_LOADED")
end

function KHMRaidFrames:SetInternalVariables()
    self.componentScale = 1

    self:GetRaidProfileSettings()

    self.isOpen = false

    self.maxFrames = 10
    self.virtual = {
        shown = false,
        frames = {},
        groupType = "raid",
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

    if self.db.profile.Masque then
        local Masque = LibStub("Masque", true)

        if Masque then
            self.Masque = {}
            self.Masque.buffFrames = Masque:Group("KHMRaidFrames", "Buff Auras")
            self.Masque.debuffFrames = Masque:Group("KHMRaidFrames", "Debuff Auras")
        end
    end

    self:GetVirtualFrames()

    self.textures, self.sortedTextures = self.GetTextures()
    self.fonts, self.sortedFonts = self.GetFons()
end

function KHMRaidFrames:Setup()
    local defaults_settings = self:Defaults()
    self.db = LibStub("AceDB-3.0"):New("KHMRaidFramesDB", defaults_settings)

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    local LibDualSpec = LibStub("LibDualSpec-1.0")
    LibDualSpec:EnhanceDatabase(self.db, "KHMRaidFrames")
    LibDualSpec:EnhanceOptions(profiles, self.db)

    self.config = LibStub("AceConfigRegistry-3.0")
    self.config:RegisterOptionsTable("KHMRaidFrames", self:SetupOptions())
    self.config:RegisterOptionsTable("KHM Profiles", self:SetupProfiles(profiles))

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

    self:RegisterChatCommand("rl", function() ReloadUI() end)

    self:SetInternalVariables()

end

function KHMRaidFrames:COMPACT_UNIT_FRAME_PROFILES_LOADED()
    self:Setup()

    self.db.RegisterCallback(
        self, "OnProfileChanged",
        function(...) StaticPopup_Show(self.reloadConfirmation)
    end)
    self.db.RegisterCallback(
        self, "OnProfileCopied",
        function(...) StaticPopup_Show(self.reloadConfirmation)
    end)
    self.db.RegisterCallback(
        self, "OnProfileReset",
        function(...) StaticPopup_Show(self.reloadConfirmation)
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
                self:GetRaidProfileSettings()
                self:SafeRefresh()

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
                self:CustomizeOptions()
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

    if self.db.profile.raid.frames.enhancedAbsorbs or self.db.profile.party.frames.enhancedAbsorbs then
        self:SecureHook(
            "CompactUnitFrame_UpdateHealPrediction",
            function(frame)
                if not frame:GetName() or frame:GetName():find("^NamePlate%d") or not UnitIsPlayer(frame.displayedUnit) then return end

                self:SetUpAbsorb(frame)
            end
        )
    end

     self:SecureHook(
        self.dialog,
        "FeedGroup",
        function() self:CustomizeOptions() end
    )

    self:SecureHook(
        "CompactUnitFrame_UpdateAuras",
        function(frame)
            if not frame:GetName() or frame:GetName():find("^NamePlate%d") then return end

            self:UpdateAuras(frame)
        end
    )

    self:HookNameAndIcons()

    self:SecureHook(
        "CompactUnitFrameProfiles_ApplyProfile",
        function(profile)
            self:GetRaidProfileSettings()
            self:SafeRefresh()
        end
    )

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

function KHMRaidFrames:HookNameAndIcons()
    local dbParty = self.db.profile.party.nameAndIcons
    local dbRaid = self.db.profile.raid.nameAndIcons

    if dbParty.name.enabled or dbRaid.name.enabled then

        self:SecureHook(
            "CompactUnitFrame_UpdateName",
            function(frame)
                if not frame:GetName() or frame:GetName():find("^NamePlate%d") then return end

                self:SetUpName(frame, IsInRaid() and "raid" or "party")
            end
        )
    end

    if dbParty.roleIcon.enabled or dbRaid.roleIcon.enabled then
        self:SecureHook(
            "CompactUnitFrame_UpdateRoleIcon",
            function(frame)
            if not frame:GetName() or frame:GetName():find("^NamePlate%d") then return end

            self:SetUpRoleIconInternal(frame, IsInRaid() and "raid" or "party")
         end
        )
    end

    if dbParty.readyCheckIcon.enabled or dbRaid.readyCheckIcon.enabled then
        self:SecureHook(
            "CompactUnitFrame_UpdateReadyCheck",
            function(frame)
                if not frame:GetName() or frame:GetName():find("^NamePlate%d") then return end

                self:SetUpReadyCheckIconInternal(frame, IsInRaid() and "raid" or "party")
            end
        )
    end

    if dbParty.centerStatusIcon.enabled or dbRaid.centerStatusIcon.enabled then
        self:SecureHook(
            "CompactUnitFrame_UpdateCenterStatusIcon",
            function(frame)
                if not frame:GetName() or frame:GetName():find("^NamePlate%d") then return end

                self:SetUpCenterStatusIconInternal(frame, IsInRaid() and "raid" or "party")
            end
        )
    end
end

function KHMRaidFrames:RefreshConfig(groupType)
    if groupType ~= (IsInRaid() and "raid" or "party") then return end

    local isInCombatLockDown = InCombatLockdown()

    self:SetUpVirtual("buffFrames", groupType, self.componentScale)
    self:SetUpVirtual("debuffFrames", groupType, self.componentScale, true)
    self:SetUpVirtual("dispelDebuffFrames", groupType, 1)

    for group in self.IterateCompactGroups(groupType) do
        self:DefaultGroupSetUp(group, groupType, isInCombatLockDown)
    end

    for frame in self:IterateCompactFrames(groupType) do
        self:DefaultFrameSetUp(frame, groupType, isInCombatLockDown)
        self:SetUpAbsorb(frame)
    end

    self:SetUpSoloFrame()
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

    self.componentScale = min(self.frameHeight / self.NATIVE_UNIT_FRAME_HEIGHT, self.frameWidth / self.NATIVE_UNIT_FRAME_WIDTH)
end

function KHMRaidFrames:OnOptionShow()
    if InCombatLockdown() then
        self:HideAll()
        self.deffered = true
        return
    end

    self.isOpen = true
    self:ShowRaidFrame()
    self:ConfigOptionsOpen()
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
    if not self.db.profile.party.frames.showPartySolo and not InCombatLockdown() and not IsInGroup() and self.useCompactPartyFrames then
        CompactRaidFrameContainer:Hide()
        CompactRaidFrameManager:Hide()
    end

    self:HideVirtual()
end

function KHMRaidFrames:HideAll()
    _G["InterfaceOptionsFrame"]:Hide()
end