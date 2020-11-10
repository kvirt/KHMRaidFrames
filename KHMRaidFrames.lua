local addonName, addonTable = ...
addonTable.KHMRaidFrames = LibStub("AceAddon-3.0"):NewAddon("KHMRaidFrames", "AceHook-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("KHMRaidFrames")

local KHMRaidFrames = addonTable.KHMRaidFrames
local _G, tonumber = _G, tonumber
local MAX_RAID_GROUPS, BOSS_DEBUFF_SIZE_INCREASE = MAX_RAID_GROUPS, BOSS_DEBUFF_SIZE_INCREASE
local frameStyle = "useCompactPartyFrames"


function KHMRaidFrames:Setup()
    self.maxFrames = 10 
    self.extraFrames = {}
    self.glowingFrames = {
        buffFrames = {},
        debuffFrames = {},
        dispelDebuffFrames = {},        
    }

    self.virtualFrames = self:GetVirtualFrames()
    self.virtual = {        
        buffFrames = false,
        debuffFrames = false,
        dispelDebuffFrames = false,
    }

    local defaults_settings = self:Defaults()
    self.db = LibStub("AceDB-3.0"):New("KHMRaidFramesDB", defaults_settings)

    local profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    local LibDualSpec = LibStub('LibDualSpec-1.0')
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
end

function KHMRaidFrames:OnEnable()
    self:Setup()

    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
    self.db.RegisterCallback(self, "OnProfileCopied", "ProfileReload")
    self.db.RegisterCallback(self, "OnProfileReset", "ProfileReload") 

    local deferrFrame = CreateFrame("Frame")
    deferrFrame:RegisterEvent("PLAYER_REGEN_ENABLED")  
    deferrFrame:SetScript(
        "OnEvent", 
        function(frame, event)
            self:UpdateLayout(_G["CompactRaidFrameContainer"])
        end
    ) 

    self:SecureHook(
        "CompactRaidFrameContainer_LayoutFrames", 
        function(container) 
            self:UpdateLayout(container) 
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
    -- hooked in resize\setposition function for blizzard's big debuff reason
    -- self:SecureHook("CompactUnitFrame_UtilSetDebuff")
    self:SecureHook("CompactUnitFrame_UtilSetDispelDebuff")        

    self:SecureHook("CompactUnitFrame_HideAllBuffs")
    self:SecureHook("CompactUnitFrame_HideAllDebuffs")
    self:SecureHook("CompactUnitFrame_HideAllDispelDebuffs") 

    self:RefreshConfig()   
end

function KHMRaidFrames:ProfileReload()
    self.config:NotifyChange("KHMRaidFrames")
end

function KHMRaidFrames:OnOptionShow()
    self:ShowRaidFrame()
    self:RefreshConfig()
end

function KHMRaidFrames:OnOptionHide()
    self:HideRaidFrame()
    self:RefreshConfig()
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

    self:HideAllVirtual()
end

function KHMRaidFrames:RefreshConfig()
    if InCombatLockdown() then
        print("Can not refresh settings while in combat")   
        return
    end

    self.refresh = true

    local crfc = _G["CompactRaidFrameContainer"]
    if crfc and crfc:IsShown() then
        for i=1, 8 do
            local groupFrame = _G["CompactRaidGroup"..i]
            if groupFrame then
                self:SetUpFrames(i, groupFrame)
                self:SetUpSubFrames(i, groupFrame)
                self:SetUpVirtualSubFrames(i) 
            end
        end

        local groupFrame = _G["CompactPartyFrame"]
        if groupFrame then
            self:SetUpFrames("PARTY", groupFrame)
            self:SetUpSubFrames("PARTY", groupFrame)
            self:SetUpVirtualSubFrames("PARTY") 
        end
    end   
 
    self.refresh = false    
end

function KHMRaidFrames:UpdateLayout(container)
    local usedGroups = {}

    for i=1, MAX_RAID_GROUPS do
        usedGroups[i] = false
    end

    if IsInRaid() then
        for i=1, GetNumGroupMembers() do
            local name, rank, subgroup = GetRaidRosterInfo(i)
            usedGroups[subgroup] = true
        end

        for groupIndex, isUsed in ipairs(usedGroups) do
            if isUsed and container.groupFilterFunc(groupIndex) then
                self:SetUpAll(groupIndex)
            end
        end
    else
        self:SetUpAll("PARTY")
    end
end

function KHMRaidFrames:SetUpAll(groupIndex)
    local groupFrame

    if type(groupIndex) == "number" then
        groupFrame = _G["CompactRaidGroup"..groupIndex]
    elseif groupIndex == "PARTY" then    
        groupFrame = _G["CompactPartyFrame"]
    end

    if not groupFrame then return end

    self:SetUpFrames(groupIndex, groupFrame)
    self:SetUpSubFrames(groupIndex, groupFrame)     
end

function KHMRaidFrames:SetUpSubFrames(groupIndex, groupFrame)
    local typedframes, frame

    local db = self:FrameType(groupIndex)

    for index=1, 5 do
        frame = _G[groupFrame:GetName().."Member"..index]

        if frame and frame:IsShown() and frame.unit then
            for _, frameType in ipairs({"buffFrames", "debuffFrames", "dispelDebuffFrames"}) do
                self:AddSubFrames(frame, db[frameType], frameType)
                typedframes = frame[frameType]
                self:ResizeHideHooks(typedframes, db[frameType], frameType == "debuffFrames")                
                self:SetUpFramesInternal(frame, typedframes, db[frameType])
            end
            if not InCombatLockdown() then
                if self.refresh then
                    CompactUnitFrame_UpdateAll(frame)
                end
            end                
        end                   
    end  
end

function KHMRaidFrames:ResizeHideHooks(typedframes, db, needHook)
    local hooked, _

    for frameNum=1, #typedframes do
        if frameNum > db.num then
            hooked, _ = self:IsHooked(typedframes[frameNum], "OnShow")

            if not hooked then 
                self:SecureHookScript(typedframes[frameNum], "OnShow", 
                    function(typedframe)
                        self:OnShow(typedframe, db, frameNum)
                    end
                )
            end

            self:OnShow(typedframes[frameNum], db, frameNum)
        end

        if needHook then
            hooked, _ = self:IsHooked("CompactUnitFrame_UtilSetDebuff")

            if not hooked then        
                self:SecureHook(
                    "CompactUnitFrame_UtilSetDebuff", 
                    function(debuffFrame, unit, index, filter, isBossAura, isBossBuff, ...) 
                        self:SetDebuff(db, debuffFrame, unit, index, filter, isBossAura, isBossBuff, ...) 
                    end
                )
            end        
        end
    end                                 
end

function KHMRaidFrames:OnShow(frame, db, frameNum)
    if frameNum > db.num then
        frame:Hide()
    end
end

function KHMRaidFrames:SetDebuff(db, debuffFrame, unit, index, filter, isBossAura, isBossBuff, ...)
    local size = db.size

    if isBossAura then
        size = size + BOSS_DEBUFF_SIZE_INCREASE
    end

    debuffFrame:SetSize(size, size)

    self:CompactUnitFrame_UtilSetDebuff(debuffFrame, unit, index, filter, isBossAura, isBossBuff, ...)  
end

function KHMRaidFrames:SetUpFramesInternal(frame, typedframes, db)
    local frameNum = 1
    local typedframe, anchor1, anchor2, relativeFrame, xOffset, yOffset

    while frameNum <= #typedframes do
        typedframe = typedframes[frameNum]

        typedframe:ClearAllPoints()
        anchor1, relativeFrame, anchor2 = self:GetFramePosition(frame, typedframes, db, frameNum)

        if frameNum == 1 then
            xOffset, yOffset = db.xOffset, db.yOffset
        else
            xOffset, yOffset = 0, 0
        end

        typedframe:SetPoint(
            anchor1, 
            relativeFrame, 
            anchor2, 
            xOffset, 
            yOffset
        )

        typedframe:SetSize(db.size, db.size)      

        frameNum = frameNum + 1
    end     
end

function KHMRaidFrames:SetUpFrames(groupIndex, groupFrame)
    local db = self:FrameType(groupIndex)

    if db.frames.hideGroupTitles then
        groupFrame.title:Hide()
    else
        groupFrame.title:Show()
    end  

    for i=1, 5 do
        local frame = _G[groupFrame:GetName().."Member"..i]
        if frame then
            frame.healthBar:SetStatusBarTexture(db.frames.texture, "BORDER")
        end
    end
end

function KHMRaidFrames:FrameType(groupIndex)
    local db

    if type(groupIndex) == "number" then
        db = self.db.profile.raid
    elseif groupIndex == "PARTY" then    
        db = self.db.profile.party
    end

    return db
end