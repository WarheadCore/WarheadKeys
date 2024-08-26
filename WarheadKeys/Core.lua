WarheadKeys = LibStub("AceAddon-3.0"):NewAddon("WarheadKeys", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");

local SelfName = GetUnitName("player", false)
local WH_ITEM_ID_KEYSTONE = 138019

function WarheadKeys:OnInitialize()
    if WarheadKeysDB == nil then
        WarheadKeysDB = {}
    end

    if not WarheadKeysDB.config then
        WarheadKeysDB.config =
        {
            objectiveTime = true,
            deathCounter = false,
            objectiveTimeInChat = true,
            progressTooltip = true,
            EnableChatLink = true,
            EnableChatLinkInstance = true,
            LinkSlottedKey = true,
        }
    end

    if WarheadKeysDB.config.objectiveTimeInChat == nil then
        WarheadKeysDB.config.objectiveTimeInChat = true
    end

    if WarheadKeysDB.config.progressTooltip == nil then
        WarheadKeysDB.config.progressTooltip = true
    end

    if not WarheadKeysDB.currentRun then
        WarheadKeysDB.currentRun = {}
    end

    if not WarheadKeysDB.npcProgressVersion then
        WarheadKeysDB.npcProgressVersion = 1
    end

    if not WarheadKeysDB.npcProgress or not WarheadKeysDB.npcProgressVersion or WarheadKeysDB.npcProgressVersion == 0 then
        WarheadKeysDB.npcProgress = {[104277]={[4]=1},[102253]={[4]=1},[98954]={[4]=1},[97185]={[10]=1},[114541]={[1]=1},[113537]={[10]=1},[114334]={[4]=1},[118717]={[4]=1},[120550]={[4]=1},[104246]={[4]=1},[104278]={[10]=1},[116550]={[4]=1},[98732]={[1]=1},[119977]={[4]=1},[97043]={[4]=1},[102430]={[1]=1},[98366]={[4]=1},[95832]={[2]=1},[104295]={[1]=1},[97171]={[10]=1},[102287]={[10]=1},[98733]={[4]=1},[119930]={[4]=1},[102351]={[1]=1},[96247]={[1]=1},[118703]={[4]=1},[118719]={[4]=1},[113699]={[8]=1},[91785]={[2]=1},[100216]={[4]=1},[97172]={[1]=1},[114783]={[4]=1},[114544]={[4]=1},[105651]={[10]=1},[118704]={[10]=1},[105715]={[4]=1},[98368]={[4]=1},[95834]={[2]=1},[98926]={[4]=1},[98177]={[12]=1},[97173]={[4]=1},[105636]={[4]=1},[114338]={[10]=1},[118705]={[10]=1},[95771]={[4]=1},[96584]={[4]=1},[97365]={[4]=1},[91006]={[4]=1},[115757]={[8]=1},[96664]={[2]=1},[100250]={[4]=1},[105876]={[1]=1},[95947]={[4]=1},[118690]={[4]=1},[118706]={[2]=1},[95772]={[4]=1},[99358]={[4]=1},[101414]={[2]=1},[98370]={[4]=1},[104251]={[4]=1},[114802]={[4]=1},[98243]={[4]=1},[98275]={[4]=1},[114627]={[4]=1},[118723]={[10]=1},[99359]={[3]=1},[120556]={[4]=1},[115488]={[4]=1},[104300]={[4]=1},[98706]={[6]=1},[114803]={[4]=1},[98770]={[4]=1},[100248]={[4]=1},[96611]={[2]=1},[105703]={[1]=1},[100364]={[4]=1},[99360]={[9]=1},[97081]={[5]=1},[96587]={[4]=1},[106786]={[1]=1},[121569]={[4]=1},[91790]={[4]=1},[98691]={[4]=1},[102094]={[4]=1},[91782]={[10]=1},[114804]={[4]=1},[95766]={[4]=1},[118700]={[2]=1},[119952]={[4]=1},[115486]={[8]=1},[106787]={[1]=1},[105720]={[4]=1},[114628]={[4]=1},[115831]={[4]=1},[97200]={[4]=1},[97097]={[4]=1},[104270]={[8]=1},[101991]={[4]=1},[114625]={[1]=1},[102788]={[4]=1},[114626]={[4]=1},[95861]={[4]=1},[98756]={[4]=1},[120366]={[4]=1},[98533]={[10]=1},[119978]={[1]=1},[105705]={[4]=1},[105952]={[6]=1},[98677]={[1]=1},[97083]={[5]=1},[99649]={[12]=1},[98900]={[4]=1},[98406]={[4]=1},[91792]={[10]=1},[91787]={[1]=1},[114801]={[4]=1},[92350]={[4]=1},[100526]={[4]=1},[114637]={[4]=1},[120405]={[4]=1},[102104]={[4]=1},[102375]={[3]=1},[105706]={[10]=1},[105699]={[3]=1},[97068]={[5]=1},[96574]={[5]=1},[118716]={[4]=1},[99188]={[4]=1},[102232]={[4]=1},[91793]={[1]=1},[95769]={[4]=1},[119923]={[4]=1},[97677]={[1]=1},[100527]={[3]=1},[102583]={[4]=1},[114584]={[1]=1},[98280]={[4]=1},[91796]={[10]=1},[118712]={[4]=1},[105617]={[4]=1},[120374]={[4]=1},[114792]={[4]=1},[97197]={[2]=1},[95842]={[2]=1},[102584]={[4]=1},[91794]={[1]=1},[96608]={[2]=1},[118714]={[4]=1},[91332]={[4]=1},[100529]={[1]=1},[98759]={[4]=1},[105915]={[4]=1},[90998]={[4]=1},[98919]={[4]=1},[114633]={[4]=1},[95779]={[10]=1},[99365]={[4]=1},[96640]={[2]=1},[101549]={[1]=1},[95843]={[5]=1},[106059]={[4]=1},[115765]={[4]=1},[105629]={[1]=1},[97182]={[6]=1},[98728]={[7]=1},[95939]={[10]=1},[98425]={[4]=1},[98776]={[8]=1},[98792]={[4]=1},[118713]={[4]=1},[114634]={[4]=1},[96480]={[1]=1},[99366]={[4]=1},[97087]={[2]=1},[90997]={[4]=1},[97119]={[1]=1},[114252]={[4]=1},[98681]={[6]=1},[96657]={[12]=1},[101839]={[4]=1},[102404]={[4]=1},[98963]={[1]=1},[121711]={[4]=1},[105921]={[4]=1},[98538]={[10]=1},[114364]={[1]=1},[102566]={[12]=1},[118724]={[4]=1},[98813]={[4]=1},[114542]={[4]=1},[105682]={[8]=1},[91000]={[8]=1},[91781]={[4]=1},[91783]={[4]=1},[97678]={[8]=1},[91008]={[4]=1},[92610]={[4]=1},[100531]={[8]=1},[116549]={[4]=1},[99033]={[4]=1},[114624]={[8]=1},[98810]={[6]=1},[114636]={[4]=1},[91786]={[4]=1},[121553]={[4]=1},[101679]={[4]=1},[114796]={[4]=1},[91001]={[4]=1},[106785]={[1]=1},}
    end

    if WarheadKeysDB.KeystoneCache == nil then
        WarheadKeysDB.KeystoneCache = { }
    end

    WarheadKeys.L = LibStub("AceLocale-3.0"):GetLocale("WarheadKeys")

    local options = {
        name = "WarheadKeys",
        handler = WarheadKeysDB,
        type = "group",
        args =
        {
            objectivetimeschat = {
                type = "toggle",
                name = WarheadKeys.L["ObjectiveTimesInChat"],
                desc = WarheadKeys.L["ObjectiveTimesInChatDesc"],
                get = function(info,val) return WarheadKeysDB.config.objectiveTimeInChat end,
                set = function(info,val) WarheadKeysDB.config.objectiveTimeInChat = val end,
                width = "full"
            },
            objectivetimes = {
                type = "toggle",
                name = WarheadKeys.L["ObjectiveTimes"],
                desc = WarheadKeys.L["ObjectiveTimesDesc"],
                get = function(info,val) return WarheadKeysDB.config.objectiveTime end,
                set = function(info,val) WarheadKeysDB.config.objectiveTime = val end,
                width = "full"
            },
            deathcounter = {
                type = "toggle",
                name = WarheadKeys.L["DeathCounter"],
                desc = WarheadKeys.L["DeathCounterDesc"],
                get = function(info,val) return WarheadKeysDB.config.deathCounter end,
                set = function(info,val) WarheadKeysDB.config.deathCounter = val end,
                width = "full"
            },
            progresstooltip = {
                type = "toggle",
                name = WarheadKeys.L["ProgressTooltip"],
                desc = WarheadKeys.L["ProgressTooltipDesc"],
                get = function(info,val) return WarheadKeysDB.config.progressTooltip end,
                set = function(info,val) WarheadKeysDB.config.progressTooltip = val end,
                width = "full"
            },
            -- resetbesttimes = {
            --     type = "execute",
            --     name = WarheadKeys.L["DeleteBestTimes"],
            --     desc = WarheadKeys.L["DeleteBestTimesRecords"],
            --     func = function(info) WarheadKeysDB.bestTimes = {} end,
            --     width = "full"
            -- },
            -- resetnpcprogress = {
            --     type = "execute",
            --     name = WarheadKeys.L["DeleteNPCProgress"],
            --     desc = WarheadKeys.L["DeleteNPCProgressDesc"],
            --     func = function(info) WarheadKeysDB.npcProgress = {} end,
            --     width = "full"
            -- },
--            exportdata = {
--                type = "execute",
--                name = "export",
--                desc = "export",
--                func = function(info) WarheadKeys:ExportData() end,
--                width = "full"
--            },
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("WarheadKeys", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("WarheadKeys", "|cFFFF0000Warhead:|r Ключи")

    WarheadKeysCMTimer:Init()
end

function WarheadKeys:OnEnable()
    self:RegisterEvent("CHALLENGE_MODE_START")
    self:RegisterEvent("CHALLENGE_MODE_COMPLETED")
    self:RegisterEvent("CHALLENGE_MODE_RESET")

    self:RegisterChatCommand("mpt", "CMTimerChatCommand")
end

function WarheadKeys:CHALLENGE_MODE_START()
    WarheadKeysCMTimer:OnStart();
end

function WarheadKeys:StartCMTimer()
    WarheadKeys:CancelCMTimer()
    WarheadKeys.cmTimer = self:ScheduleRepeatingTimer("OnCMTimerTick", 1)
end

function WarheadKeys:CHALLENGE_MODE_COMPLETED()
    WarheadKeysCMTimer:OnComplete();
end

function WarheadKeys:CHALLENGE_MODE_RESET()
    WarheadKeysCMTimer:OnReset();
end

function WarheadKeys:OnCMTimerTick()
    WarheadKeysCMTimer:Draw();
end

function WarheadKeys:PLAYER_ENTERING_WORLD()
    WarheadKeysCMTimer:ReStart()
end

function WarheadKeys:CancelCMTimer()
    if WarheadKeys.cmTimer then
        self:CancelTimer(WarheadKeys.cmTimer)
        WarheadKeys.cmTimer = nil
    end
end

function WarheadKeys:CMTimerChatCommand(input)
    if input == "toggle" then
        WarheadKeysCMTimer:ToggleFrame()
    else
        self:Print("/mpt toggle: " .. WarheadKeys.L["ToggleCommandText"])
    end
end
