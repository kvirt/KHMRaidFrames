local L = LibStub("AceLocale-3.0"):NewLocale("KHMRaidFrames", "enUS", true)

if not L then return end

L["TOPLEFT"] = true
L["LEFT"] = true
L["BOTTOMLEFT"] = true
L["BOTTOM"] = true
L["BOTTOMRIGHT"] = true
L["RIGHT"] = true
L["TOPRIGHT"] = true
L["TOP"] = true
L["CENTER"] = true
L["KHMRaidFrames"] = true
L["Raid"] = true
L["Buffs"] = true
L["Num"] = true
L["Size"] = true
L["X Offset"] = true
L["Y Offset"] = true
L["Grow Direction"] = true
L["Debuffs"] = true
L["Party"] = true
L["Dispell Debuffs"] = true
L["Anchor Point"] = true
L["Texture"] = true
L["Hide Group Title"] = true
L["Width"] = true
L["Height"] = true
L["General"] = true
L["Reset to Default"] = true
L["Profiles"] = true
L["Show\\Hide Test Frames"] = true
L["Glow Type"] = true
L["Color"] = true
L["Frequency"] = true
L["Glows"] = true
L["Enable"] = true
L["Thickness"] = true
L["Border"] = true
L["Tracking"] = true
L["Exclude"] = true
L["Num In Row"] = true
L["Rows Grow Direction"] = true
L["Rejuvenation"] = true
L["Wildcards"] = true
L["-- Comments"] = true
L["Track auras"] = "Track auras \nRefresh any buff\\debuff to apply settings or /reload"
L["Exclude auras"] = "Exclude auras \nRefresh any buff\\debuff to apply settings or /reload"
L["Block List"] = true
L["Raid Icon"] = true
L["Auras"] = true
L["Aura Glow"] = true
L["Frame Glow"] = true
L["Use Default Colors"] = true
L["Exclude auras from Glows"] = "Exclude auras from Glows \nRefresh any buff\\debuff to apply settings or /reload"
L["Default Colors"] = true
L["Poison"] = true
L["Magic"] = true
L["Disease"] = true
L["Curse"] = true
L["Physical"] = true
L["Click Through Auras"] = true
L["Show Big Debuffs"] = true
L["Additional Auras Tracking"] = true
L["Track Auras that are not shown by default by Blizzard"] = "Track Auras that are not shown by default \nRefresh any buff\\debuff to apply settings or /reload"
L["Big Debuffs"] = true
L["Enhanced Absorbs"] = true
L["UI will be reloaded to apply settings"] = true
L["Always Show Party Frame"] = true
L["Align Big Debuffs"] = true
L["You are in |cFFC80000<text>|r"] = true
L["Copy settings to |cFFffd100<text>|r"] = true
L["Raid settings"] = true
L["Party settings"] = true
L["Glows settings"] = true
L["Glow effect options for your Buffs and Debuffs"] = true
L["Glow effect options for your Frames"] = true
L["General options"] = true
L["Dispell Debuffs options"] = true
L["Raid Icon options"] = true
L["Click Through Auras Desc"] = "Removes Aura Tooltips"
L["Enhanced Absorbs Desc"] = "Permanent feedback on total shielding amounts regardless of whether the shielded person's HP is full or not"
L["Always Show Party Frame Desc"] = "Show Party Frame even outside group"
L["Align Big Debuffs Desc"] = "Align debuffs related to \"big\" ones"
L["Name and Icons"] = "Texts and Icons"
L["Name and Icons options"] = "Texts and Icons Options"
L["Name"] = true
L["Name Options"] = true
L["Font"] = true
L["Flags"] = "Font Outline"
L["Name Options"] = true
L["Font"] = true
L["Flags"] = true
L["None"] = true
L["OUTLINE"] = true
L["THICKOUTLINE"] = true
L["MONOCHROME"] = true
L["Status Text"] = "Health (status)"
L["Status Text Options"] = "Health and status text display(offline, dead, etc)"
L["Show Server"] = true
L["Horizontal Justify"] = true
L["Role Icon"] = true
L["Role Icon Options"] = true
L["Custom Textures"] = true
L["Custom Textures desc"] = "Reload needed to apply default settings"
L["Custom Texture Options"] = "Path to custom texture. Example: Interface\\AddOns\\KHMRaidFrames\\ Icons\\lyn-dps"
L["Healer"] = true
L["Damager"] = true
L["Tank"] = true
L["Vehicle"] = true
L["Ready"] = true
L["Not Ready"] = true
L["Waiting"] = true
L["Ready Check Icon"] = true
L["Ready Check Icon Options"] = true
L["Center Status Icon"] = true
L["Center Status Icon Options"] = "Center Status Icon options (phase, summon, ressurection, etc)"
L["In Other Group"] = true
L["Has Icoming Ressurection"] = true
L["Incoming Summon Pending"] = true
L["Incoming Summon Accepted"] = true
L["Incoming Summon Declined"] = true
L["In Other Phase"] = true
L["Class Colored Names"] = true
L["Class Colored Names desc"] = "Player names colored by their classes"
L["Enable Masque Support"] = true
L["Enable Masque Support Desc"] = "Experimental"
L["Show\\Hide Test Frames desc"] = "Test frames made for easy setup of you buffs\\debuffs. Does not support glow, masque, etc"
L["Masque Reskin"] = true
L["AdditionalTrackingHelpText"] = "You can filter auras by unit e.g.:"..
                                    "\n    Rejuvenation|cFFC80000::|r|cFFFFFFFFplayer|r"
L["Export Profile"] = true
L["Import Profile"] = true
L["Are You sure?"] = true
L["Transparency"] = true
L["Sync Profiles"] = "|cFFffd100Sync Profiles|r"
L["Sync Profiles Desc"] = "Автоматически переключать профиль на соответствующй в настройках \"Профили Рейда\""
L["KHM Profile Stuff"] = true
L["Profile: |cFFC80000<text>|r"] = true
L["Abbreviate Large Numbers"] = true
L["Abbreviate Numbers"] = true
L["Abbreviate"] = true
L["Abbreviate Desc"] = "100 -> 100"..
                        "\n1000 -> 1K"..
                        "\n1000000 -> 1M"
L["buffsAndDebuffs"] = "Buffs and Debuffs"
L["Don\'t Show Status Text"] = true
L["Don\'t Show Status Text Desc"] = ""
L["Leader Icon"] = true
L["Leader Icon Options"] = true
L["Leader Icon Texture"] = true
L["Precision"] = true
L["Show Percents"] = true
L["Formatting"] = true
L["Class Colored Text"] = true
L["Auto Scaling"] = true
L["Auto Scaling Desc"] = "Following elements are scaled by default: \n|cFFffd100Buffs|r, \n|cFFffd100Debuffs|r, \n|cFFffd100ReadyCheck Icon|r, \n|cFFffd100Status Text|r, \n|cFFffd100Center Status Icon|r.\n\n"..
                        "Some addon provided elements are also scaled: \n|cFFffd100Raid Icon|r, \n|cFFffd100Leader Icon|r, \n|cFFffd100Name|r"
L["Hide Element"] = true