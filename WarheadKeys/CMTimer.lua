WarheadKeysCMTimer = {}

local function SendWHMessageToChat(message)
    local sendChannelType = "PARTY"

    if not IsInGroup() then
        sendChannelType = "SAY"
    end

    SendChatMessage(("WH: %s"):format(message), sendChannelType)
end

local surrenderedSoul
function WarheadKeysCMTimer:Init()
    if not WarheadKeysDB.pos then
        WarheadKeysDB.pos = {}
    end

    if WarheadKeysDB.pos.left == nil then
        WarheadKeysDB.pos.left = -260;
    end

    if WarheadKeysDB.pos.top == nil then
        WarheadKeysDB.pos.top = 190;
    end

    if WarheadKeysDB.pos.relativePoint == nil then
        WarheadKeysDB.pos.relativePoint = "RIGHT";
    end

    if not WarheadKeysDB.bestTimes then
        WarheadKeysDB.bestTimes = {}
    end

    WarheadKeysCMTimer.isCompleted = false;
    WarheadKeysCMTimer.started = false;
    WarheadKeysCMTimer.reset = false;
    WarheadKeysCMTimer.frames = {};
    WarheadKeysCMTimer.timerStarted = false;
    WarheadKeysCMTimer.lastKill = {};

    WarheadKeysCMTimer.frame = CreateFrame("Frame", "CmTimer", UIParent);
    WarheadKeysCMTimer.frame:SetPoint(WarheadKeysDB.pos.relativePoint, WarheadKeysDB.pos.left, WarheadKeysDB.pos.top)
    WarheadKeysCMTimer.frame:EnableMouse(true)
    WarheadKeysCMTimer.frame:RegisterForDrag("LeftButton")
    WarheadKeysCMTimer.frame:SetScript("OnDragStart", WarheadKeysCMTimer.frame.StartMoving)
    WarheadKeysCMTimer.frame:SetScript("OnDragStop", WarheadKeysCMTimer.frame.StopMovingOrSizing)
    WarheadKeysCMTimer.frame:SetScript("OnMouseDown", WarheadKeysCMTimer.OnFrameMouseDown)
    WarheadKeysCMTimer.frame:SetWidth(100);
    WarheadKeysCMTimer.frame:SetHeight(100);
    WarheadKeysCMTimer.frameToggle = false

    WarheadKeysCMTimer.eventFrame = CreateFrame("Frame")
    WarheadKeysCMTimer.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    WarheadKeysCMTimer.eventFrame:RegisterEvent("SCENARIO_CRITERIA_UPDATE")
    WarheadKeysCMTimer.eventFrame:SetScript("OnEvent", function(self, event, timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags)
        if subEvent == "PARTY_KILL" then
            WarheadKeysCMTimer:OnPartyKill(destGUID)
            return
        end

        if event == "SCENARIO_CRITERIA_UPDATE" then
            WarheadKeysCMTimer:OnCriteriaUpdate()
            return
        end


        if subEvent ~= "UNIT_DIED" then
            return
        end

        local isPlayer = strfind(destGUID, "Player")
        if not isPlayer then
            return
        end

        local isFeign = UnitIsFeignDeath(destName);
        if isFeign then
            return
        end

        if not surrenderedSoul then
            surrenderedSoul = GetSpellInfo(212570)
        end

        if UnitDebuff(destName, surrenderedSoul) == surrenderedSoul then
            return
        end

        WarheadKeysCMTimer:OnPlayerDeath()
    end)

    GameTooltip:HookScript("OnTooltipSetUnit", function(self)
        WarheadKeysCMTimer:OnTooltipSetUnit(self)
    end)

    self:ReStart()
end

function WarheadKeysCMTimer:OnTooltipSetUnit(el)
    if not WarheadKeysDB.config.progressTooltip then
        return
    end

    local unit = select(2, el:GetUnit())
    if not unit then
        return
    end

    local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();
    if difficulty ~= 8 or WarheadKeysCMTimer.started == false or WarheadKeysCMTimer.isCompleted then
        return
    end

    if UnitCanAttack("player", unit) and not UnitIsDead(unit) then
        local guid = UnitGUID(unit)
        local npcID = WarheadKeysCMTimer:resolveNpcID(guid)
        if not npcID then
            return
        end

        local value = WarheadKeysCMTimer:GetProgressValue(npcID)
        if not value then
            return
        end

        local _, _, steps = C_Scenario.GetStepInfo();
        if not steps or steps <= 0 then
            return
        end

        local _, _, _, _, finalValue = C_Scenario.GetCriteriaInfo(steps);
        local quantityPercent = (value / finalValue) * 100

        local mult = 10^2
        quantityPercent = math.floor(quantityPercent * mult + 0.5) / mult
        if(quantityPercent > 100) then
            quantityPercent = 100
        end

        local name = C_Scenario.GetCriteriaInfo(steps)

        GameTooltip:AddDoubleLine(name..": +"..quantityPercent.."%")
        GameTooltip:Show()
    end
end

function WarheadKeysCMTimer:OnPartyKill(destGUID)
    local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();
    if difficulty ~= 8 or WarheadKeysCMTimer.started == false or WarheadKeysCMTimer.isCompleted then
        return
    end

    if not WarheadKeysCMTimer.lastKill then
        WarheadKeysCMTimer.lastKill = {}
    end

    if not WarheadKeysCMTimer.lastKill[1] or WarheadKeysCMTimer.lastKill[1]  == nil then
        WarheadKeysCMTimer.lastKill[1] = GetTime() * 1000
    end

    local npcID = WarheadKeysCMTimer:resolveNpcID(destGUID)
    if npcID then
        local valid = ((GetTime() * 1000) - WarheadKeysCMTimer.lastKill[1]) > 100
        WarheadKeysCMTimer.lastKill = {GetTime() * 1000, npcID, valid}
    end
end

function WarheadKeysCMTimer:OnCriteriaUpdate()
    local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();
    if difficulty ~= 8 or WarheadKeysCMTimer.started == false or WarheadKeysCMTimer.isCompleted then
        return
    end

    if not WarheadKeysDB.currentRun.currentQuantity then
        WarheadKeysDB.currentRun.currentQuantity = 0
    end

    local _, _, steps = C_Scenario.GetStepInfo();
    if not steps or steps <= 0 then
        return
    end

    local _, _, _, _, finalValue, _, _, quantity = C_Scenario.GetCriteriaInfo(steps);
    if WarheadKeysDB.currentRun.currentQuantity >= finalValue then
        return
    end

    local quantityNumber = string.sub(quantity, 1, string.len(quantity) - 1)
    quantityNumber = tonumber(quantityNumber)

    local delta = quantityNumber - WarheadKeysDB.currentRun.currentQuantity

    if delta > 0 then
        WarheadKeysDB.currentRun.currentQuantity = quantityNumber
        if WarheadKeysDB.currentRun.currentQuantity >= finalValue then
            return
        end

        local timestamp, npcID, valid  = unpack(WarheadKeysCMTimer.lastKill)
        if timestamp and npcID and delta and valid then
            if (GetTime() * 1000) - timestamp <= 600 then
                WarheadKeysCMTimer:UpdateProgressValue(npcID, delta);
            end
        end
    end
end

function WarheadKeysCMTimer:UpdateProgressValue(npcID, value)
    if not WarheadKeysDB.npcProgress then
        WarheadKeysDB.npcProgress = {}
    end

    if not WarheadKeysDB.npcProgress[npcID] then
        WarheadKeysDB.npcProgress[npcID] = {}
    end

    if WarheadKeysDB.npcProgress[npcID][value] == nil then
        WarheadKeysDB.npcProgress[npcID][value] = 1
    else
        WarheadKeysDB.npcProgress[npcID][value] = WarheadKeysDB.npcProgress[npcID][value] + 1
    end

    for val, occurrences in pairs(WarheadKeysDB.npcProgress[npcID]) do
        if val ~= value then
            WarheadKeysDB.npcProgress[npcID][val] = occurrences * 0.80
        end
    end
end

function WarheadKeysCMTimer:GetProgressValue(npcID)
    if not WarheadKeysDB.npcProgress then
        return
    end

    if not WarheadKeysDB.npcProgress[npcID] then
        return
    end

    local value, occurrences = nil, -1
    for val, valOccurrences in pairs(WarheadKeysDB.npcProgress[npcID]) do
        if valOccurrences > occurrences then
            value, occurrences = val, valOccurrences
        end
    end

    return value
end

function WarheadKeysCMTimer:ToggleFrame()
    if WarheadKeysCMTimer.frameToggle then
        WarheadKeysCMTimer.frame:SetMovable(false)
        WarheadKeysCMTimer.frame:SetBackdrop(nil)
        WarheadKeysCMTimer.frameToggle = false

        local _, _, relativePoint, xOfs, yOfs = WarheadKeysCMTimer.frame:GetPoint()
        WarheadKeysDB.pos.relativePoint = relativePoint;
        WarheadKeysDB.pos.top = yOfs;
        WarheadKeysDB.pos.left = xOfs;

        local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();
        if difficulty ~= 8 then
            WarheadKeysCMTimer.frame:Hide();
        end
    else
        WarheadKeysCMTimer.frame:SetMovable(true)
        local backdrop = {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 1,
            insets = {
                left = 0,
                right = 0,
                top = 0,
                bottom = 0
            }
        }

        WarheadKeysCMTimer.frame:SetBackdrop(backdrop)
        WarheadKeysCMTimer.frameToggle = true
        WarheadKeysCMTimer.frame:Show();
    end
end

function WarheadKeysCMTimer:OnComplete()
    if not WarheadKeysDB.bestTimes[WarheadKeysDB.currentRun.currentZoneID]["_complete"] or WarheadKeysDB.currentRun.time < WarheadKeysDB.bestTimes[WarheadKeysDB.currentRun.currentZoneID]["_complete"] then
        WarheadKeysDB.bestTimes[WarheadKeysDB.currentRun.currentZoneID]["_complete"] = WarheadKeysDB.currentRun.time
    end

    if not WarheadKeysDB.bestTimes[WarheadKeysDB.currentRun.currentZoneID]["l"..WarheadKeysDB.currentRun.cmLevel]["_complete"] or WarheadKeysDB.currentRun.time < WarheadKeysDB.bestTimes[WarheadKeysDB.currentRun.currentZoneID]["l"..WarheadKeysDB.currentRun.cmLevel]["_complete"] then
        WarheadKeysDB.bestTimes[WarheadKeysDB.currentRun.currentZoneID]["l"..WarheadKeysDB.currentRun.cmLevel]["_complete"] = WarheadKeysDB.currentRun.time
    end

    if WarheadKeysDB.config.objectiveTimeInChat then
        -- local text = WarheadKeysDB.currentRun.zoneName.." +"..WarheadKeysDB.currentRun.cmLevel.." "..WarheadKeys.L["Completed"].."! "..WarheadKeys.L["Time"]..": "..WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.currentRun.time)..". "..WarheadKeys.L["BestTime"]..": "
        -- text = text..WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.bestTimes[WarheadKeysDB.currentRun.currentZoneID]["l"..WarheadKeysDB.currentRun.cmLevel]["_complete"])

        local _, _, _, _, keystoneUpgradeLevel = C_ChallengeMode.GetCompletionInfo()
        keystoneUpgradeLevel = keystoneUpgradeLevel or 0

        local text = WarheadKeysDB.currentRun.zoneName.." ("..WarheadKeysDB.currentRun.cmLevel..") закрыт. Изменение уровня: "..keystoneUpgradeLevel..". Потраченное время: "..WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.currentRun.time)

        SendWHMessageToChat(text)
    end

    ObjectiveTrackerFrame:Show()
    WarheadKeysCMTimer.isCompleted = true
    WarheadKeysCMTimer.frame:Hide()
    ObjectiveTrackerFrame:Show()
    WarheadKeysCMTimer:HideObjectivesFrames()

    WarheadKeysDB.currentRun = {}
end

function WarheadKeysCMTimer:OnStart()
    WarheadKeysDB.currentRun = {}

    WarheadKeysCMTimer.isCompleted = false;
    WarheadKeysCMTimer.started = true;
    WarheadKeysCMTimer.reset = false;
    WarheadKeysCMTimer.lastKill = {};

    WarheadKeys:StartCMTimer()
end

function WarheadKeysCMTimer:OnReset()
    WarheadKeysCMTimer.frame:Hide();
    ObjectiveTrackerFrame:Show();
    WarheadKeysCMTimer.isCompleted = false;
    WarheadKeysCMTimer.started = false;
    WarheadKeysCMTimer.lastKill = {};
    WarheadKeysCMTimer.reset = true;
    WarheadKeysCMTimer:HideObjectivesFrames()

    WarheadKeysDB.currentRun = {}
end

function WarheadKeysCMTimer:HideObjectivesFrames()
    if WarheadKeysCMTimer.frames.objectives then
        for key, _ in pairs(WarheadKeysCMTimer.frames.objectives) do
            WarheadKeysCMTimer.frames.objectives[key]:Hide()
        end
    end
end

function WarheadKeysCMTimer:ReStart()
    local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();

    if difficulty ~= 8 then
        return
    end

    local _, timeCM = GetWorldElapsedTime(1);

    if timeCM > 0 then
        WarheadKeysCMTimer.started = true;
        WarheadKeysCMTimer.lastKill = {};

        local _, _, steps = C_Scenario.GetStepInfo();
        local _, _, _, _, _, _, _, quantity = C_Scenario.GetCriteriaInfo(steps);
        local quantityNumber = string.sub(quantity, 1, string.len(quantity) - 1)

        WarheadKeysDB.currentRun.currentQuantity = tonumber(quantityNumber)

        WarheadKeys:StartCMTimer()
        return
    end

    WarheadKeysCMTimer.frame:Hide();
    ObjectiveTrackerFrame:Show();
    WarheadKeysCMTimer.reset = false
    WarheadKeysCMTimer.timerStarted = false
    WarheadKeysCMTimer.started = false
    WarheadKeysCMTimer.lastKill = {};
    WarheadKeysCMTimer.isCompleted = false
    WarheadKeysDB.currentRun = {}
end

function WarheadKeysCMTimer:OnPlayerDeath()
    local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();
    local _, timeCM = GetWorldElapsedTime(1);

    if difficulty ~= 8 then
        return
    end

    if not WarheadKeysCMTimer.started then
        return
    end

    if WarheadKeysDB.currentRun.death == nil then
        return
    end

    WarheadKeysDB.currentRun.death = WarheadKeysDB.currentRun.death + 1
end

function WarheadKeysCMTimer:Draw()
    local _, _, difficulty, _, _, _, _, currentZoneID = GetInstanceInfo();

    if difficulty ~= 8 then
        WarheadKeysCMTimer.frame:Hide()
        ObjectiveTrackerFrame:Show()
        return
    end

    if not WarheadKeysCMTimer.isCompleted then
        ObjectiveTrackerFrame:Hide()
    end

    if not WarheadKeysCMTimer.started and not WarheadKeysCMTimer.reset and WarheadKeysCMTimer.timerStarted then
        WarheadKeys:CancelCMTimer()
        WarheadKeysCMTimer.timerStarted = false
        WarheadKeysCMTimer.frame:Hide()
        ObjectiveTrackerFrame:Show()
        return
    end

    if WarheadKeysCMTimer.reset or WarheadKeysCMTimer.isCompleted then
        WarheadKeysCMTimer.reset = false
        WarheadKeysCMTimer.timerStarted = false
        WarheadKeysCMTimer.started = false
        WarheadKeysCMTimer.lastKill = {}
        WarheadKeys:CancelCMTimer()
        WarheadKeysCMTimer.frame:Hide()
        ObjectiveTrackerFrame:Show()
        return
    end

    WarheadKeysCMTimer.timerStarted = true

    local _, timeCM = GetWorldElapsedTime(1)

    if not timeCM or timeCM <= 0 then
        return
    end

    local cmLevel, affixes, empowered = C_ChallengeMode.GetActiveKeystoneInfo()

    if cmLevel == 0 then
        cmLevel = 2
    end

    if not WarheadKeysCMTimer.isCompleted then
        WarheadKeysCMTimer.frame:Show()
    end

    if not WarheadKeysDB.bestTimes[currentZoneID] then
        WarheadKeysDB.bestTimes[currentZoneID] = {}
    end

    if not WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel] then
        WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel] = {}
    end

    if not WarheadKeysDB.currentRun.times then
        WarheadKeysDB.currentRun.times = {}
    end

    if WarheadKeysDB.currentRun.death == nil then
        WarheadKeysDB.currentRun.death = 0
    end

    local currentMapId = C_ChallengeMode.GetActiveChallengeMapID()

    -- Fix for Uwow
    if not currentMapId then
        -- Око азшары
        if currentZoneID == 1456 then
            currentMapId = 197
        end

        -- Квартал звёзд
        if currentZoneID == 1571 then
            currentMapId = 210
        end
    end

    local zoneName, _, maxTime = C_ChallengeMode.GetMapInfo(currentMapId)
    local bonus = C_ChallengeMode.GetPowerLevelDamageHealthMod(cmLevel)

    -- Info
    WarheadKeysDB.currentRun.cmLevel = cmLevel
    WarheadKeysDB.currentRun.zoneName = zoneName
    WarheadKeysDB.currentRun.currentZoneID = currentZoneID
    WarheadKeysDB.currentRun.time = timeCM

    if not WarheadKeysCMTimer.frames.info then
        local f = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
        f:SetAllPoints()
        f.text = f:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge");
        f.text:SetPoint("TOPLEFT", 0, 0);
        WarheadKeysCMTimer.frames.info = f
    end

    WarheadKeysCMTimer.frames.info.text:SetText("+" .. cmLevel .. " - " .. zoneName);

    -- Main tooltip
    if not WarheadKeysCMTimer.frames.infos then
        local i = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
        i:SetAllPoints()
        i.text = i:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
        i.text:SetPoint("TOPLEFT", 0, -18);

        WarheadKeysCMTimer.frames.infos = i

        local debuffOnEnter = function(self, motion)
            if not WarheadKeysCMTimer.frames.infos.tooltip then
                return
            end

            GameTooltip:Hide()
            GameTooltip:ClearLines()
            GameTooltip:SetOwner(WarheadKeysCMTimer.frame, "ANCHOR_LEFT")

            for _, v in pairs(WarheadKeysCMTimer.frames.infos.tooltip) do
                GameTooltip:AddLine(v)
            end

            GameTooltip:Show()
        end

        local debuffOnLeave = function(self, motion)
            GameTooltip:Hide()
        end

        WarheadKeysCMTimer.frame:SetScript("OnEnter", debuffOnEnter)
        WarheadKeysCMTimer.frame:SetScript("OnLeave", debuffOnLeave)
    end

    local tooltip = {};
    table.insert(tooltip, "+" .. cmLevel .. " - " .. zoneName);
    table.insert(tooltip, "|cFFFFFFFF" .. "+"..bonus.."%");
    table.insert(tooltip, " ")

    if empowered and affixes then
        local txt = WarheadKeys.L["Empowered"]

        for _, affixID in ipairs(affixes) do
            local affixName, affixDesc, _ = C_ChallengeMode.GetAffixInfo(affixID);
            txt = txt .. " - "..affixName

            table.insert(tooltip, affixName)
            table.insert(tooltip, "|cFFFFFFFF" .. affixDesc)
            table.insert(tooltip, "  ")
        end
    end

    WarheadKeysCMTimer.frames.infos.tooltip = tooltip;
    WarheadKeysCMTimer.frames.infos.text:SetText(txt)

    -- Time
    local timeLeft = maxTime - timeCM;
    if timeLeft < 0 then
        timeLeft = 0
    end

    if not WarheadKeysCMTimer.frames.time then
        local font = "GameFontGreenLarge"

        if timeLeft == 0 then
            font = "GameFontRedLarge"
        end

        local t = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
        t:SetAllPoints()
        t.text = t:CreateFontString(nil, "BACKGROUND", font);
        t.text:SetPoint("TOPLEFT", 0, -40)

        local t2 = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
        t2:SetAllPoints()
        t2.text = t2:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
        t2.text:SetPoint("TOPLEFT", 45, -42)

        WarheadKeysCMTimer.frames.time =
        {
            timer = t;
            timer2 = t2;
        }
    end

    local font = "GameFontGreenLarge"

    if timeLeft == 0 then
        font = "GameFontRedLarge"
    end

    WarheadKeysCMTimer.frames.time.timer.text:SetFontObject(font);
    WarheadKeysCMTimer.frames.time.timer.text:SetText(WarheadKeysCMTimer:FormatSeconds(timeLeft));
    WarheadKeysCMTimer.frames.time.timer2.text:SetText("(".. WarheadKeysCMTimer:FormatSeconds(timeCM) .." / ".. WarheadKeysCMTimer:FormatSeconds(maxTime) ..")");

    WarheadKeysDB.currentRun.timeLeft = timeLeft

    -- Chest Timer
    local threeChestTime = maxTime * 0.6
    local twoChestTime = maxTime * 0.8

    local timeLeft3 = threeChestTime - timeCM;
    if timeLeft3 < 0 then
        timeLeft3 = 0
    end

    local timeLeft2 = twoChestTime - timeCM;
    if timeLeft2 < 0 then
        timeLeft2 = 0
    end

    WarheadKeysDB.currentRun.timeLeft3 = timeLeft3
    WarheadKeysDB.currentRun.timeLeft2 = timeLeft2

    if not WarheadKeysCMTimer.frames.chesttimer then
        local l2 = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
        l2:SetAllPoints()
        l2.text = l2:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
        l2.text:SetPoint("TOPLEFT", 0, -60);

        local t2 = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
        t2:SetAllPoints()
        t2.text = t2:CreateFontString(nil, "BACKGROUND", "GameFontGreen");
        t2.text:SetPoint("TOPLEFT", 60, -60);

        local l3 = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
        l3:SetAllPoints()
        l3.text = l3:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
        l3.text:SetPoint("TOPLEFT", 0, -75);

        local t3 = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
        t3:SetAllPoints()
        t3.text = t3:CreateFontString(nil, "BACKGROUND", "GameFontGreen");
        t3.text:SetPoint("TOPLEFT", 60, -75);

        WarheadKeysCMTimer.frames.chesttimer =
        {
            label2 = l2;
            time2 = t2;

            label3 = l3;
            time3 = t3;
        }
    end

    -- 2 Chest
    if timeLeft2 == 0 then
        WarheadKeysCMTimer.frames.chesttimer.label2.text:SetText("+2 ("..WarheadKeysCMTimer:FormatSeconds(twoChestTime)..")")
        WarheadKeysCMTimer.frames.chesttimer.label2.text:SetFontObject("GameFontDisable");

        if WarheadKeysDB.config.objectiveTimeInChat and WarheadKeysCMTimer.frames.chesttimer.time2:IsShown() then
            self:PrintLostTime(2)
        end

        WarheadKeysCMTimer.frames.chesttimer.time2:Hide()
    else
        WarheadKeysCMTimer.frames.chesttimer.label2.text:SetText("+2 ("..WarheadKeysCMTimer:FormatSeconds(twoChestTime).."):")
        WarheadKeysCMTimer.frames.chesttimer.label2.text:SetFontObject("GameFontHighlight");

        WarheadKeysCMTimer.frames.chesttimer.time2.text:SetText(WarheadKeysCMTimer:FormatSeconds(timeLeft2));
        WarheadKeysCMTimer.frames.chesttimer.time2:Show()
    end

    -- 3 Chest
    if timeLeft3 == 0 then
        WarheadKeysCMTimer.frames.chesttimer.label3.text:SetText("+3 ("..WarheadKeysCMTimer:FormatSeconds(threeChestTime)..")")
        WarheadKeysCMTimer.frames.chesttimer.label3.text:SetFontObject("GameFontDisable");

        if WarheadKeysDB.config.objectiveTimeInChat and WarheadKeysCMTimer.frames.chesttimer.time3:IsShown() then
            self:PrintLostTime(3)
        end

        WarheadKeysCMTimer.frames.chesttimer.time3:Hide()
    else
        WarheadKeysCMTimer.frames.chesttimer.label3.text:SetText("+3 ("..WarheadKeysCMTimer:FormatSeconds(threeChestTime).."):")
        WarheadKeysCMTimer.frames.chesttimer.label3.text:SetFontObject("GameFontHighlight");

        WarheadKeysCMTimer.frames.chesttimer.time3.text:SetText(WarheadKeysCMTimer:FormatSeconds(timeLeft3))
        WarheadKeysCMTimer.frames.chesttimer.time3:Show()
    end

    -- Objectives
    local _, _, steps = C_Scenario.GetStepInfo()

    if not WarheadKeysCMTimer.frames.objectives then
        WarheadKeysCMTimer.frames.objectives = {}
    end

    local stepsCount = 0

    for i = 1, steps do
        stepsCount = stepsCount + 1

        if not WarheadKeysCMTimer.frames.objectives[i] then
            local f = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
            f:SetAllPoints()
            f.text = f:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
            f.text:SetPoint("TOPLEFT", 0, -90 - (i * 17))

            WarheadKeysCMTimer.frames.objectives[i] = f
        end

        WarheadKeysCMTimer.frames.objectives[i]:Show()

        local name, _, status, curValue, finalValue, _, _, quantity = C_Scenario.GetCriteriaInfo(i);

        if status then
            WarheadKeysCMTimer.frames.objectives[i].text:SetFontObject("GameFontDisable")

            if WarheadKeysDB.currentRun.times[i] == nil then
                WarheadKeysDB.currentRun.times[i] = timeCM

                if not WarheadKeysDB.bestTimes[currentZoneID][i] or timeCM < WarheadKeysDB.bestTimes[currentZoneID][i] then
                    WarheadKeysDB.bestTimes[currentZoneID][i] = timeCM
                end

                if not WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel][i] or timeCM < WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel][i] then
                    WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel][i] = timeCM
                end

                if WarheadKeysDB.config.objectiveTimeInChat then
                    local text = name.." "..WarheadKeys.L["Completed"].." (+"..cmLevel.."). "..WarheadKeys.L["Time"]..": "..WarheadKeysCMTimer:FormatSeconds(timeCM)..". "..WarheadKeys.L["BestTime"]..": "
                    text = text..WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel][i])

                    SendWHMessageToChat(text)
                end
            end
        else
            WarheadKeysCMTimer.frames.objectives[i].text:SetFontObject("GameFontHighlight")

            if WarheadKeysDB.currentRun.times[i] then
                WarheadKeysDB.currentRun.times[i] = nil
            end
        end

        local bestTimeStr = ""

        if WarheadKeysDB.currentRun.times[i] and WarheadKeysDB.config.objectiveTime then
            bestTimeStr = " - " .. WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.currentRun.times[i])

            if WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel][i] then
                local diff =  WarheadKeysDB.currentRun.times[i] - WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel][i];
                local diffStr = ""

                if diff > 0 then
                    diffStr = ", +" ..WarheadKeysCMTimer:FormatSeconds(diff)
                end

                bestTimeStr = bestTimeStr .. " (".. WarheadKeys.L["Best"] ..": " .. WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.bestTimes[currentZoneID]["l"..cmLevel][i]) .. diffStr .. ")"
            end
        end

        if finalValue >= 100 then
            local quantityNumber = string.sub(quantity, 1, string.len(quantity) - 1)
            local quantityPercent = (quantityNumber / finalValue) * 100
            local mult = 10^2

            quantityPercent = math.floor(quantityPercent * mult + 0.5) / mult

            if (quantityPercent > 100) then
                quantityPercent = 100
            end

            WarheadKeysCMTimer.frames.objectives[i].text:SetText("- "..quantityPercent.."% "..name .. bestTimeStr);
        else
            if status then
                curValue = finalValue
            end

            WarheadKeysCMTimer.frames.objectives[i].text:SetText("- "..curValue.."/"..finalValue.." "..name .. bestTimeStr);
        end
    end

    -- Death Count
    if WarheadKeysDB.currentRun.death > 0 and WarheadKeysDB.config.deathCounter then
        local i = stepsCount + 1

        if not WarheadKeysCMTimer.frames.deathCounter then
            local f = CreateFrame("Frame", nil, WarheadKeysCMTimer.frame)
            f:SetAllPoints()
            f.text = f:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
            WarheadKeysCMTimer.frames.deathCounter = f
        end

        WarheadKeysCMTimer.frames.deathCounter.text:SetPoint("TOPLEFT", 0, -90 - (i * 17))
        WarheadKeysCMTimer.frames.deathCounter:Show()

        local seconds = WarheadKeysDB.currentRun.death * 5
        WarheadKeysCMTimer.frames.deathCounter.text:SetText(WarheadKeysDB.currentRun.death.." "..WarheadKeys.L["Deaths"]..":|cFFFF0000 -"..WarheadKeysCMTimer:FormatSeconds(seconds))
    else
        if WarheadKeysCMTimer.frames.deathCounter then
            WarheadKeysCMTimer.frames.deathCounter:Hide()
        end
    end
end

function WarheadKeysCMTimer:ResolveTime(seconds)
    local min = math.floor(seconds/60)
    local sec = seconds - (min * 60)
    return min, sec
end

function WarheadKeysCMTimer:FormatSeconds(seconds)
    local min, sec = WarheadKeysCMTimer:ResolveTime(seconds)
    if min < 10 then
        min = "0" .. min
    end

    if sec < 10 then
        sec = "0" .. sec
    end

    return min .. ":" .. sec
end

function WarheadKeysCMTimer:OnFrameMouseDown()
    if IsModifiedClick("CHATLINK") then
        if not WarheadKeysDB.currentRun.time then
            return
        end

        local timeText = WarheadKeys.L["TimeLeft"]..": "..WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.currentRun.timeLeft).." || +2: "..WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.currentRun.timeLeft2).." || +3: "..WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.currentRun.timeLeft3)

        local channel = "PARTY"

        if GetNumGroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 0 then
            channel = "INSTANCE_CHAT"
        end

        SendChatMessage(timeText, channel)
    end
end

function WarheadKeysCMTimer:resolveNpcID(guid)
    local targetType, _,_,_,_, npcID = strsplit("-", guid)
    if targetType == "Vehicle" or targetType == "Creature" and npcID then
        return tonumber(npcID)
    end
end

function WarheadKeysCMTimer:DebugPrint()
end

function WarheadKeysCMTimer:PrintLostTime(lootLevel)
    SendWHMessageToChat("Время для лута +"..lootLevel.." закончилось. Прошло: "..WarheadKeysCMTimer:FormatSeconds(WarheadKeysDB.currentRun.time))
end
