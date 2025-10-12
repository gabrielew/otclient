huntingTasksController = Controller:new()
huntingTasks = nil

local SLOT_IDS = {
    'hunting_tasks_slot_1',
    'hunting_tasks_slot_2',
    'hunting_tasks_slot_3'
}

local huntingTaskSlotStates = {}
local huntingTasksBasicInfo = {
    preys = {},
    options = {},
    optionsByDifficulty = {},
    difficultyByRaceId = {}
}

local ensureHuntingTasksPanel
local getSlotWidget
local getSlotState
local setSlotTitle
local formatDifficulty
local getDifficultyForRace
local buildRaceDisplay
local updateSelectionPreview
local updateSelectionDetails
local selectSelectionWidget
local createSelectionItem
local showEmpty
local showLocked
local showActive
local showSelection
local refreshSlotFromBasicData
local resetAllSlots

local function getSlotIndex(slotId)
    return math.max(1, math.floor((slotId or 0) + 1))
end

ensureHuntingTasksPanel = function()
    if huntingTasks and not huntingTasks:isDestroyed() then
        return huntingTasks
    end

    if preyWindow and not preyWindow:isDestroyed() then
        local panel = preyWindow.huntingTasksTabPanel or preyWindow:getChildById('huntingTasksTabPanel')
        if panel and not panel:isDestroyed() then
            huntingTasks = panel
            return huntingTasks
        end
    end

    return nil
end

getSlotWidget = function(slotIndex)
    local panel = ensureHuntingTasksPanel()
    if not panel then
        return nil
    end

    local slotName = SLOT_IDS[slotIndex]
    local slotWidget = nil

    if slotName and panel.getChildById then
        slotWidget = panel:getChildById(slotName)
    end

    if (not slotWidget or slotWidget:isDestroyed()) and preyWindow and not preyWindow:isDestroyed() then
        slotWidget = preyWindow[slotName] or (preyWindow.getChildById and preyWindow:getChildById(slotName))
    end

    if slotWidget and slotWidget:isDestroyed() then
        slotWidget = nil
    end

    return slotWidget
end

getSlotState = function(slotIndex)
    huntingTaskSlotStates[slotIndex] = huntingTaskSlotStates[slotIndex] or {}
    return huntingTaskSlotStates[slotIndex]
end

setSlotTitle = function(slotWidget, slotIndex)
    if slotWidget and slotWidget.title then
        slotWidget.title:setText(tr('Hunting Task %d', slotIndex))
    end
end

formatDifficulty = function(difficulty)
    if difficulty == nil then
        return tr('Difficulty: Unknown')
    end

    return tr('Difficulty: %d', difficulty)
end

getDifficultyForRace = function(raceId)
    if not raceId then
        return nil
    end

    return huntingTasksBasicInfo.difficultyByRaceId and huntingTasksBasicInfo.difficultyByRaceId[raceId] or nil
end

buildRaceDisplay = function(raceId)
    local raceData = g_things and g_things.getRaceData and g_things.getRaceData(raceId) or nil
    local name = raceData and raceData.name or ''

    if name ~= '' and capitalFormatStr then
        name = capitalFormatStr(name)
    elseif name == '' then
        name = tr('Unknown Creature (%d)', raceId)
    end

    local outfit = raceData and raceData.outfit or nil

    return {
        raceId = raceId,
        name = name,
        outfit = outfit
    }
end

updateSelectionPreview = function(slotIndex, entry)
    local slotWidget = getSlotWidget(slotIndex)
    if not slotWidget or not slotWidget.selection then
        return
    end

    local preview = slotWidget.selection.preview
    if not preview then
        return
    end

    if not entry then
        if preview.placeholder then
            preview.placeholder:setVisible(true)
        end
        if preview.creature then
            preview.creature:setVisible(false)
        end
        if preview.name then
            preview.name:setVisible(false)
        end
        if preview.difficulty then
            preview.difficulty:setVisible(false)
        end
        if preview.status then
            preview.status:setVisible(false)
        end
        return
    end

    local display = buildRaceDisplay(entry.raceId)
    local difficulty = getDifficultyForRace(entry.raceId)

    if preview.placeholder then
        preview.placeholder:setVisible(false)
    end

    if preview.creature then
        preview.creature:setVisible(true)
        preview.creature:setOutfit(display.outfit or {})
        preview.creature:setTooltip(display.name)
    end

    if preview.name then
        preview.name:setVisible(true)
        preview.name:setText(display.name)
    end

    if preview.difficulty then
        preview.difficulty:setVisible(true)
        preview.difficulty:setText(formatDifficulty(difficulty))
    end

    if preview.status then
        preview.status:setVisible(true)
        if entry.unlocked then
            preview.status:setText(tr('Status: Unlocked'))
            preview.status:setColor('#5ac85a')
        else
            preview.status:setText(tr('Status: Locked'))
            preview.status:setColor('#d46a6a')
        end
    end
end

updateSelectionDetails = function(slotIndex)
    local slotState = huntingTaskSlotStates[slotIndex]
    if not slotState then
        return
    end

    for _, widget in ipairs(slotState.selectionWidgets or {}) do
        if widget and not widget:isDestroyed() and widget.entry then
            local entry = widget.entry
            local difficulty = getDifficultyForRace(entry.raceId)

            if widget.difficulty then
                widget.difficulty:setVisible(true)
                widget.difficulty:setText(formatDifficulty(difficulty))
            end

            if widget.status then
                widget.status:setVisible(true)
                if entry.unlocked then
                    widget.status:setText(tr('Unlocked'))
                    widget.status:setColor('#5ac85a')
                else
                    widget.status:setText(tr('Locked'))
                    widget.status:setColor('#d46a6a')
                end
            end
        end
    end

    updateSelectionPreview(slotIndex, slotState.selectedEntry)
end

selectSelectionWidget = function(slotIndex, widget)
    if not widget or widget:isDestroyed() then
        return
    end

    local slotState = getSlotState(slotIndex)

    if slotState.selectedWidget and slotState.selectedWidget ~= widget and not slotState.selectedWidget:isDestroyed() then
        if slotState.selectedWidget.setChecked then
            slotState.selectedWidget:setChecked(false)
        end
    end

    slotState.selectedWidget = widget
    slotState.selectedEntry = widget.entry

    if widget.setChecked then
        widget:setChecked(true)
    end

    updateSelectionPreview(slotIndex, widget.entry)
end

createSelectionItem = function(parent, slotIndex, entry)
    local widget = g_ui.createWidget('HuntingTaskSelectionItem', parent)
    local display = buildRaceDisplay(entry.raceId)

    widget.entry = entry

    if widget.creature then
        widget.creature:setOutfit(display.outfit or {})
        widget.creature:setTooltip(display.name)
    end

    if widget.name then
        widget.name:setText(display.name)
        widget.name:setTooltip(display.name)
    end

    if widget.difficulty then
        widget.difficulty:setVisible(false)
    end

    if widget.status then
        widget.status:setVisible(false)
    end

    widget.onClick = function(self)
        selectSelectionWidget(slotIndex, self)
        return true
    end

    widget.onDoubleClick = widget.onClick

    return widget
end

showEmpty = function(slotIndex, slotWidget, subtitle)
    local slotState = getSlotState(slotIndex)
    slotState.mode = 'empty'
    slotState.selectionWidgets = {}
    slotState.selectedWidget = nil
    slotState.selectedEntry = nil
    slotState.activeData = nil

    setSlotTitle(slotWidget, slotIndex)

    if slotWidget.subtitle then
        slotWidget.subtitle:setText(subtitle or tr('Awaiting hunting task data'))
    end

    if slotWidget.empty then
        slotWidget.empty:setVisible(true)
    end

    if slotWidget.selection then
        slotWidget.selection:setVisible(false)
    end

    if slotWidget.active then
        slotWidget.active:setVisible(false)
    end

    if slotWidget.locked then
        slotWidget.locked:setVisible(false)
    end
end

showLocked = function(slotIndex, slotWidget, data)
    local slotState = getSlotState(slotIndex)
    slotState.mode = 'locked'
    slotState.selectionWidgets = {}
    slotState.selectedWidget = nil
    slotState.selectedEntry = nil
    slotState.activeData = nil

    setSlotTitle(slotWidget, slotIndex)

    if slotWidget.empty then
        slotWidget.empty:setVisible(false)
    end

    if slotWidget.selection then
        slotWidget.selection:setVisible(false)
    end

    if slotWidget.active then
        slotWidget.active:setVisible(false)
    end

    if slotWidget.locked then
        slotWidget.locked:setVisible(true)
        if slotWidget.locked.message then
            if data and data.isPremium == false then
                slotWidget.locked.message:setText(tr('Requires Premium status to unlock this hunting task slot.'))
            else
                slotWidget.locked.message:setText(tr('This hunting task slot is locked.'))
            end
        end
    end

    if slotWidget.subtitle then
        slotWidget.subtitle:setText(tr('Locked'))
    end
end

showActive = function(slotIndex, slotWidget, activeData, isCompleted)
    local slotState = getSlotState(slotIndex)
    slotState.mode = isCompleted and 'completed' or 'active'
    slotState.selectionWidgets = {}
    slotState.selectedWidget = nil
    slotState.selectedEntry = nil
    slotState.activeData = activeData

    setSlotTitle(slotWidget, slotIndex)

    if slotWidget.empty then
        slotWidget.empty:setVisible(false)
    end

    if slotWidget.selection then
        slotWidget.selection:setVisible(false)
    end

    if slotWidget.locked then
        slotWidget.locked:setVisible(false)
    end

    if not slotWidget.active then
        return
    end

    slotWidget.active:setVisible(true)

    local display = buildRaceDisplay(activeData and activeData.selectedRaceId)
    local difficulty = getDifficultyForRace(activeData and activeData.selectedRaceId)
    local requiredKills = activeData and activeData.requiredKills or 0
    local currentKills = 0

    if isCompleted then
        currentKills = activeData and activeData.achievedKills or requiredKills
    else
        currentKills = activeData and activeData.currentKills or 0
    end

    if slotWidget.subtitle then
        slotWidget.subtitle:setText(isCompleted and tr('Completed') or tr('Active task'))
    end

    if slotWidget.active.creature then
        slotWidget.active.creature:setOutfit(display.outfit or {})
        slotWidget.active.creature:setTooltip(display.name)
    end

    if slotWidget.active.name then
        slotWidget.active.name:setText(display.name)
    end

    if slotWidget.active.difficulty then
        slotWidget.active.difficulty:setText(formatDifficulty(difficulty))
    end

    if slotWidget.active.rarity then
        slotWidget.active.rarity:setText(tr('Stars: %d', activeData and activeData.rarity or 0))
    end

    if slotWidget.active.upgrade then
        local upgradeText = (activeData and activeData.upgrade) and tr('Upgrade active') or tr('Upgrade inactive')
        slotWidget.active.upgrade:setText(upgradeText)
    end

    if slotWidget.active.progress then
        local percent = 0
        if requiredKills > 0 then
            percent = math.min(100, (currentKills / requiredKills) * 100)
        elseif currentKills > 0 then
            percent = 100
        end
        slotWidget.active.progress:setPercent(percent)
    end

    if slotWidget.active.progressText then
        slotWidget.active.progressText:setText(string.format('%d / %d', currentKills, requiredKills))
    end

    if slotWidget.active.status then
        if isCompleted then
            slotWidget.active.status:setText(tr('Completed'))
            slotWidget.active.status:setColor('#ffcc66')
        else
            slotWidget.active.status:setText(tr('In progress'))
            slotWidget.active.status:setColor('#5ac85a')
        end
    end
end

showSelection = function(slotIndex, slotWidget, data)
    local slotState = getSlotState(slotIndex)
    slotState.mode = 'selection'
    slotState.selectionWidgets = {}
    slotState.selectedWidget = nil
    slotState.selectedEntry = nil
    slotState.activeData = nil
    slotState.freeReroll = data and data.freeRerollRemainingSeconds or nil

    setSlotTitle(slotWidget, slotIndex)

    if slotWidget.empty then
        slotWidget.empty:setVisible(false)
    end

    if slotWidget.active then
        slotWidget.active:setVisible(false)
    end

    if slotWidget.locked then
        slotWidget.locked:setVisible(false)
    end

    if not slotWidget.selection then
        return
    end

    slotWidget.selection:setVisible(true)

    if slotWidget.subtitle then
        slotWidget.subtitle:setText(tr('Select a creature'))
    end

    local list = slotWidget.selection.list
    if list then
        list:destroyChildren()
    end

    local parentWidget = list or slotWidget.selection
    local widgets = {}

    local function appendSection(title)
        if not parentWidget then
            return
        end
        local header = g_ui.createWidget('HuntingTaskSectionLabel', parentWidget)
        header:setText(title)
        header:setFocusable(false)
        header:setEnabled(false)
    end

    if data and data.selection and #data.selection > 0 then
        appendSection(tr('Available creatures'))
        for _, entry in ipairs(data.selection) do
            local widget = createSelectionItem(parentWidget, slotIndex, entry)
            table.insert(widgets, widget)
        end
    end

    if data and data.listSelection and #data.listSelection > 0 then
        appendSection(tr('All creatures'))
        for _, entry in ipairs(data.listSelection) do
            local widget = createSelectionItem(parentWidget, slotIndex, entry)
            table.insert(widgets, widget)
        end
    end

    slotState.selectionWidgets = widgets

    if slotWidget.selection.emptyMessage then
        slotWidget.selection.emptyMessage:setVisible(#widgets == 0)
    end

    if list then
        list:setVisible(#widgets > 0)
    end

    if slotWidget.selection.preview then
        slotWidget.selection.preview:setVisible(#widgets > 0)
    end

    if #widgets == 0 then
        updateSelectionPreview(slotIndex, nil)
        return
    end

    local defaultWidget
    for _, widget in ipairs(widgets) do
        if widget.entry and widget.entry.unlocked then
            defaultWidget = widget
            break
        end
    end

    if not defaultWidget then
        defaultWidget = widgets[1]
    end

    if defaultWidget then
        selectSelectionWidget(slotIndex, defaultWidget)
    else
        updateSelectionPreview(slotIndex, nil)
    end

    updateSelectionDetails(slotIndex)
end

refreshSlotFromBasicData = function(slotIndex)
    local slotState = huntingTaskSlotStates[slotIndex]
    if not slotState then
        return
    end

    local slotWidget = getSlotWidget(slotIndex)
    if not slotWidget then
        return
    end

    if slotState.mode == 'selection' then
        updateSelectionDetails(slotIndex)
    elseif slotState.mode == 'active' then
        showActive(slotIndex, slotWidget, slotState.activeData or {}, false)
    elseif slotState.mode == 'completed' then
        showActive(slotIndex, slotWidget, slotState.activeData or {}, true)
    end
end

resetAllSlots = function()
    local panel = ensureHuntingTasksPanel()
    if not panel then
        return
    end

    for index = 1, #SLOT_IDS do
        local slotWidget = getSlotWidget(index)
        if slotWidget then
            showEmpty(index, slotWidget, tr('Waiting for hunting task data'))
        end
    end
end

function setUnsupportedSettings()
    resetAllSlots()
end

function huntingTasksController:onInit()
    self:registerEvents(g_game, {
        onTaskHuntingData = onTaskHuntingData,
        taskHuntingBasicData = taskHuntingBasicData,
    })

    setUnsupportedSettings()
end

function huntingTasksController:onGameEnd()
    huntingTasks = nil
    huntingTaskSlotStates = {}
end

function taskHuntingBasicData(data)
    huntingTasksBasicInfo.preys = data.preys or {}
    huntingTasksBasicInfo.options = data.options or {}
    huntingTasksBasicInfo.optionsByDifficulty = data.optionsByDifficulty or {}
    huntingTasksBasicInfo.difficultyByRaceId = {}

    for _, prey in ipairs(huntingTasksBasicInfo.preys) do
        if prey.raceId then
            huntingTasksBasicInfo.difficultyByRaceId[prey.raceId] = prey.difficulty
        end
    end

    for index = 1, #SLOT_IDS do
        refreshSlotFromBasicData(index)
    end
end

function onTaskHuntingData(data)
    local slotIndex = getSlotIndex(data.slotId)
    local panel = ensureHuntingTasksPanel()
    if not panel then
        return
    end

    local slotWidget = getSlotWidget(slotIndex)
    if not slotWidget then
        g_logger.warning(string.format('[HuntingTasks] Missing slot widget for slot %d', slotIndex))
        return
    end

    if data.isPremium ~= nil and not data.isPremium then
        showLocked(slotIndex, slotWidget, data)
        return
    end

    if data.completed then
        showActive(slotIndex, slotWidget, data.completed, true)
        return
    end

    if data.active then
        showActive(slotIndex, slotWidget, data.active, false)
        return
    end

    if (data.selection and #data.selection > 0) or (data.listSelection and #data.listSelection > 0) then
        showSelection(slotIndex, slotWidget, data)
        return
    end

    showEmpty(slotIndex, slotWidget, tr('No hunting task available'))
end
