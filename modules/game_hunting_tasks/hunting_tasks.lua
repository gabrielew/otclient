huntingTasksController = Controller:new()
huntingTasks = nil
huntingTasksWindow = nil

huntingTasksController.difficultyByRaceId = {}
huntingTasksController.optionsByDifficultyAndStars = {}
huntingTasksController.pendingSlotData = {}
huntingTasksController.uiInitialized = false

local PREY_TASK_STATE_LOCKED = 0
local PREY_TASK_STATE_INACTIVE = 1
local PREY_TASK_STATE_SELECTION = 2
local PREY_TASK_STATE_LIST_SELECTION = 3
local PREY_TASK_STATE_ACTIVE = 4
local PREY_TASK_STATE_COMPLETED = 5

local descriptionTable = {
    shopPermButton =
    'Go to the Store to purchase the Permanent Hunting Task Slot. Once you complete the purchase, the slot remains unlocked for any account status.',
    shopTempButton = 'Activate this hunting task slot while your account has Premium status.',
    noBonusIcon =
    'This hunting task slot is not available yet. Check the blue buttons below to learn how to unlock access to hunting tasks.',
    selectHuntingTask =
    'Spend hunting task points to reroll the active bonus. The chosen creature will remain active for the duration of the task.',
    chooseHuntingTaskButton =
    'Confirm the highlighted creatures to start a hunting task. Completing tasks grants hunting task points and potential rewards.',
    pickSpecificHuntingTask =
    'Browse the full creature list to select a specific hunting task target. This requires hunting task points.',
    rerollButton =
    'Request a new list of hunting task creatures. Rerolls consume hunting task points or gold depending on your configuration.',
    huntingTasksWindow = '',
}

local function setDescriptionText(text)
    local preyModule = modules and modules.game_prey
    local window = preyModule and preyModule.preyWindow
    local description = window and window.description

    if not description or description:isDestroyed() then
        return
    end

    description:setText(text or '')
end

local function toggleWidgetVisible(widget, visible)
    if not widget then
        return
    end

    if visible then
        widget:show()
    else
        widget:hide()
    end
end

local function ensureHuntingTasksWindow()
    if huntingTasksWindow and not huntingTasksWindow:isDestroyed() then
        return true
    end

    local preyModule = modules and modules.game_prey
    local preyWindow = preyModule and preyModule.preyWindow
    if not preyWindow or preyWindow:isDestroyed() then
        return false
    end

    local panel = preyWindow:recursiveGetChildById('huntingTasksWindow')
    if not panel then
        local tabPanel = preyWindow:recursiveGetChildById('huntingTasksTabPanel')
        if tabPanel then
            panel = tabPanel:recursiveGetChildById('huntingTasksWindow') or tabPanel
        end
    end

    if not panel then
        return false
    end

    huntingTasksWindow = panel
    huntingTasks = panel
    return true
end

local function getPreySlotWidget(slot)
    if not ensureHuntingTasksWindow() then
        return nil
    end

    return huntingTasksWindow['hunting_tasks_slot_' .. (slot + 1)]
end

function onPreyRaceListItemClicked(widget)

end

function onPreyRaceListItemHoverChange(widget)

end

function onHover(widget)
    if type(widget) == 'string' then
        local description = descriptionTable[widget]
        if description then
            setDescriptionText(description)
        end
        return
    end

    if not widget or widget:isDestroyed() or not widget:isVisible() then
        return
    end

    local id = widget:getId()
    if not id then
        return
    end

    local description = descriptionTable[id]
    if description then
        setDescriptionText(description)
    end
end

local function resolveRaceData(raceId)
    if not raceId or raceId == 0 then
        return nil
    end

    if not modules or not modules.game_things or not modules.game_things.isLoaded or not modules.game_things.isLoaded() then
        return nil
    end

    local raceData = g_things.getRaceData(raceId)
    if not raceData or raceData.raceId == 0 then
        return nil
    end

    return raceData
end

local function resolveRaceName(raceId, raceData)
    if raceData and raceData.name and raceData.name ~= '' then
        return raceData.name
    end

    return tr('Unknown Creature (%d)', raceId)
end

local function updateActiveSlot(slotWidget, activeData)
    if not slotWidget or not activeData then
        return
    end

    toggleWidgetVisible(slotWidget.inactive, false)
    toggleWidgetVisible(slotWidget.locked, false)
    toggleWidgetVisible(slotWidget.active, true)

    local raceData = resolveRaceData(activeData.selectedRaceId)
    local creatureName = resolveRaceName(activeData.selectedRaceId, raceData)
    if slotWidget.title then
        slotWidget.title:setText(creatureName)
        slotWidget.title:setTooltip(creatureName)
    end

    local creatureWidget = slotWidget.active and slotWidget.active.taskCreatureAndBonus and
        slotWidget.active.taskCreatureAndBonus.creature
    if creatureWidget and raceData and raceData.outfit then
        creatureWidget:setOutfit(raceData.outfit)
        creatureWidget:show()
        local creature = creatureWidget.getCreature and creatureWidget:getCreature()
        if creature then
            creature:setStaticWalking(1000)
        end
        creatureWidget:setTooltip(creatureName)
    elseif creatureWidget then
        creatureWidget:hide()
        creatureWidget:setTooltip('')
    end

    local progressBar = slotWidget.active and slotWidget.active.taskCreatureAndBonus and
        slotWidget.active.taskCreatureAndBonus.timeLeft
    if progressBar then
        local targetKills = activeData.requiredKills or 0
        local requiredKills = math.max(targetKills, 1)
        local currentKills = math.max(activeData.currentKills or 0, 0)
        local percent = math.min(100, (currentKills / requiredKills) * 100)
        progressBar:setPercent(percent)
        progressBar:setText(string.format('%d / %d', currentKills, targetKills))
        progressBar:setTooltip(tr('Kills: %d / %d', currentKills, targetKills))
    end
end

local function updateGenericSlotState(slotWidget, state)
    if not slotWidget then
        return
    end

    if state == PREY_TASK_STATE_LOCKED then
        toggleWidgetVisible(slotWidget.locked, true)
        toggleWidgetVisible(slotWidget.active, false)
        toggleWidgetVisible(slotWidget.inactive, false)
        if slotWidget.title then
            slotWidget.title:setText(tr('Locked'))
            slotWidget.title:setTooltip(tr('Locked'))
        end
    else
        toggleWidgetVisible(slotWidget.locked, false)
        toggleWidgetVisible(slotWidget.active, false)
        toggleWidgetVisible(slotWidget.inactive, true)
        if slotWidget.title then
            slotWidget.title:setText(tr('Inactive'))
            slotWidget.title:setTooltip(tr('Inactive'))
        end
    end

    local creatureWidget = slotWidget.active and slotWidget.active.taskCreatureAndBonus and
        slotWidget.active.taskCreatureAndBonus.creature
    if creatureWidget then
        creatureWidget:hide()
        creatureWidget:setTooltip('')
    end

    local progressBar = slotWidget.active and slotWidget.active.taskCreatureAndBonus and
        slotWidget.active.taskCreatureAndBonus.timeLeft
    if progressBar then
        progressBar:setPercent(0)
        progressBar:setText('')
        progressBar:setTooltip('')
    end
end

local function refreshSlot(data)
    if not ensureHuntingTasksWindow() then
        return false
    end

    local slotWidget = getPreySlotWidget(data.slotId)
    if not slotWidget then
        return false
    end

    if data.state == PREY_TASK_STATE_ACTIVE and data.active then
        updateActiveSlot(slotWidget, data.active)
    else
        updateGenericSlotState(slotWidget, data.state)
    end

    return true
end

local function applyPendingSlotData()
    if not huntingTasksController.pendingSlotData then
        return
    end

    for _, slotData in pairs(huntingTasksController.pendingSlotData) do
        refreshSlot(slotData)
    end
end

function setUnsupportedSettings()
    if not ensureHuntingTasksWindow() then
        return false
    end

    for slot = 0, 2 do
        local panel = getPreySlotWidget(slot)
        if panel then
            for _, state in pairs({ panel.active, panel.inactive }) do
                if state and state.select and state.select.price and state.select.price.text then
                    state.select.price.text:setText('5')
                end
            end

            local active = panel.active
            if active and active.choose and active.choose.price and active.choose.price.text then
                active.choose.price.text:setText('1')
            end
        end
    end

    applyPendingSlotData()
    return true
end

local function tryInitializeUI()
    if huntingTasksController.uiInitialized then
        return
    end

    if setUnsupportedSettings() then
        huntingTasksController.uiInitialized = true
        return
    end

    huntingTasksController:scheduleEvent(tryInitializeUI, 250, 'huntingTasksAwaitUI')
end

function huntingTasksController:onInit()
    self:registerEvents(g_game, {
        onTaskHuntingData = onTaskHuntingData,
        taskHuntingBasicData = taskHuntingBasicData,
    })

    tryInitializeUI()
end

function taskHuntingBasicData(data)
    g_logger.info(("taskHuntingBasicData: preys=%d, options=%d")
        :format(#(data.preys or {}), #(data.options or {})))

    -- Log compacto
    for i, p in ipairs(data.preys or {}) do
        huntingTasksController.difficultyByRaceId[p.raceId] = p.difficulty
        -- g_logger.info(("  Prey[%d] raceId=%d difficulty=%d"):format(i, p.raceId, p.difficulty))
    end

    huntingTasksController.optionsByDifficultyAndStars = data.options or {}

    -- for i, o in ipairs(data.options or {}) do
    --     g_logger.info(("  Option[%d] diff=%d stars=%d firstKill=%d firstReward=%d secondKill=%d secondReward=%d")
    --         :format(i, o.difficulty, o.stars, o.firstKill, o.firstReward, o.secondKill, o.secondReward))
    -- end

    -- Acesso fácil por dificuldade/estrela:
    -- ex.: pegar os dados de difficulty=2, stars=4:
    local d2 = data.optionsByDifficulty and data.optionsByDifficulty[2]
    local star4 = d2 and d2[4]
    if star4 then
        g_logger.info(("  D2*4 = firstKill=%d secondKill=%d"):format(star4.firstKill, star4.secondKill))
    end
end

function onTaskHuntingData(data)
    g_logger.info(("TaskHuntingData received: slotId=%d, state=%d, freeRerollRemainingSeconds=%d")
        :format(data.slotId, data.state, data.freeRerollRemainingSeconds or 0))

    huntingTasksController.pendingSlotData = huntingTasksController.pendingSlotData or {}
    huntingTasksController.pendingSlotData[data.slotId] = data

    if not refreshSlot(data) then
        tryInitializeUI()
    end

    -- Locked
    if data.isPremium ~= nil then
        g_logger.info(("  [Locked] isPremium=%s"):format(tostring(data.isPremium)))
    end

    -- Selection
    if data.selection then
        g_logger.info(("  [Selection] %d entries"):format(#data.selection))
        for i, entry in ipairs(data.selection) do
            g_logger.info(("    [%d] raceId=%d, unlocked=%s")
                :format(i, entry.raceId, tostring(entry.unlocked)))
        end
    end

    -- ListSelection
    if data.listSelection then
        g_logger.info(("  [ListSelection] %d entries"):format(#data.listSelection))
        for i, entry in ipairs(data.listSelection) do
            g_logger.info(("    [%d] raceId=%d, unlocked=%s")
                :format(i, entry.raceId, tostring(entry.unlocked)))
        end
    end

    -- Active
    if data.active then
        local a = data.active
        g_logger.info(("  [Active] selectedRaceId=%d, upgrade=%s, requiredKills=%d, currentKills=%d, rarity=%d")
            :format(a.selectedRaceId, tostring(a.upgrade), a.requiredKills, a.currentKills, a.rarity))
    end

    -- Completed
    if data.completed then
        local c = data.completed
        g_logger.info(("  [Completed] selectedRaceId=%d, upgrade=%s, requiredKills=%d, achievedKills=%d, rarity=%d")
            :format(c.selectedRaceId, tostring(c.upgrade), c.requiredKills, c.achievedKills, c.rarity))
    end
end
