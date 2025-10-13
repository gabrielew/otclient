HuntingTasks = HuntingTasks or {}

local Tasks = HuntingTasks
Tasks.BasicData = Tasks.BasicData or {}

local SLOT_COUNT = 3

local tasksTab
local contentWidget
local slotsContainer
local placeholderWidget
local slotWidgets = {}

local CANCEL_BUTTON_STYLE = 'HuntingTaskCancelButton'
local CANCEL_BUTTON_ID = 'HuntingTaskCancelButton'

local cancelButtonStylesLoaded = false
local cancelButtonStylesAttempted = false

local function formatFreeRerollText(seconds)
    local remainingSeconds = math.max(0, math.floor(tonumber(seconds) or 0))
    if remainingSeconds <= 0 then
        return 'Free'
    end

    local hours = math.floor(remainingSeconds / 3600)
    local minutes = math.floor((remainingSeconds % 3600) / 60)

    return string.format('%02d:%02d', hours, minutes)
end

local function handleFormatPrice(price)
    local priceText = "Free"
    if price > 0 then
        if price >= 1000000 then
            local millions = math.floor(price / 1000000)
            local remainder = price % 1000000
            if remainder >= 500000 then
                priceText = string.format('%d.5M', millions)
            elseif remainder >= 100000 then
                priceText = string.format('%dM', millions)
            else
                priceText = string.format('%dM', math.max(1, millions))
            end
        elseif price >= 100000 then
            local thousands = math.floor(price / 1000)
            local remainder = price % 1000
            if remainder >= 500 then
                priceText = string.format('%d.5k', thousands)
            elseif remainder >= 100 then
                priceText = string.format('%dk', thousands)
            else
                priceText = string.format('%dk', math.max(1, thousands))
            end
        else
            priceText = tostring(price)
        end
    end

    return priceText
end

local function applyPriceToCancel(slotWidget, data)
    if not slotWidget or slotWidget:isDestroyed() then
        return
    end

    local activePanel = slotWidget:recursiveGetChildById('active')
    if not activePanel or activePanel:isDestroyed() then
        return
    end

    local rerollPanel = activePanel:recursiveGetChildById('reroll')
    if not rerollPanel or rerollPanel:isDestroyed() then
        return
    end

    local timerWidget
    local buttonPanel = rerollPanel:recursiveGetChildById('button')
    if buttonPanel and not buttonPanel:isDestroyed() then
        timerWidget = buttonPanel:recursiveGetChildById('price')
    end
    timerWidget = timerWidget or rerollPanel:recursiveGetChildById('price')
    if not timerWidget or timerWidget:isDestroyed() or not timerWidget.setText then
        return
    end

    local cancelText = handleFormatPrice(data.cancelProgress or 0)
    timerWidget:setText(cancelText)
end

local function ensureCancelButtonStyle()
    if cancelButtonStylesLoaded then
        return true
    end

    if cancelButtonStylesAttempted then
        return false
    end

    cancelButtonStylesAttempted = true

    if not g_ui or not g_ui.importStyle then
        return false
    end

    cancelButtonStylesLoaded = g_ui.importStyle('hunting_tasks') or false

    return cancelButtonStylesLoaded
end

local function getActivePanel(slotWidget)
    if not slotWidget or slotWidget.isDestroyed and slotWidget:isDestroyed() then
        return nil
    end

    local activePanel = slotWidget:recursiveGetChildById('active')
    if activePanel and activePanel.isDestroyed and activePanel:isDestroyed() then
        return nil
    end

    return activePanel
end

local function getCancelButton(slotWidget)
    local activePanel = getActivePanel(slotWidget)
    if not activePanel then
        return nil, activePanel
    end

    local cancelButton = activePanel:recursiveGetChildById(CANCEL_BUTTON_ID)
    if cancelButton and cancelButton.isDestroyed and cancelButton:isDestroyed() then
        return nil, activePanel
    end

    return cancelButton, activePanel
end

local function ensureCancelButton(slotWidget)
    local cancelButton, activePanel = getCancelButton(slotWidget)
    if cancelButton then
        return cancelButton, activePanel
    end

    activePanel = activePanel or getActivePanel(slotWidget)
    if not activePanel then
        return nil, nil
    end

    if not ensureCancelButtonStyle() then
        return nil, activePanel
    end

    local rerollPanel = activePanel:recursiveGetChildById('reroll')
    if not rerollPanel or rerollPanel.isDestroyed and rerollPanel:isDestroyed() then
        return nil, activePanel
    end

    local buttonContainer = rerollPanel:recursiveGetChildById('button') or rerollPanel
    if not buttonContainer or buttonContainer.isDestroyed and buttonContainer:isDestroyed() then
        return nil, activePanel
    end

    if not g_ui or not g_ui.createWidget then
        return nil, activePanel
    end

    cancelButton = buttonContainer:recursiveGetChildById(CANCEL_BUTTON_ID)
    if cancelButton and cancelButton.isDestroyed and cancelButton:isDestroyed() then
        cancelButton = nil
    end

    if cancelButton then
        return cancelButton, activePanel
    end

    cancelButton = g_ui.createWidget(CANCEL_BUTTON_STYLE, buttonContainer)
    if not cancelButton then
        return nil, activePanel
    end

    cancelButton:setId(CANCEL_BUTTON_ID)
    cancelButton:setVisible(false)
    cancelButton:setFocusable(false)

    if cancelButton.fill then
        cancelButton:fill('parent')
    elseif cancelButton.breakAnchors then
        cancelButton:breakAnchors()
        cancelButton:addAnchor(AnchorTop, 'parent', AnchorTop)
        cancelButton:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        cancelButton:addAnchor(AnchorRight, 'parent', AnchorRight)
        cancelButton:addAnchor(AnchorBottom, 'parent', AnchorBottom)
    end

    return cancelButton, activePanel
end

local function setCancelButtonVisible(slotWidget, visible)
    local cancelButton, activePanel = getCancelButton(slotWidget)
    if visible and not cancelButton then
        cancelButton, activePanel = ensureCancelButton(slotWidget)
    end

    if not cancelButton then
        visible = false
    end

    if cancelButton then
        cancelButton:setVisible(visible)
        if cancelButton.setEnabled then
            cancelButton:setEnabled(visible)
        end
    end

    activePanel = activePanel or getActivePanel(slotWidget)
    if not activePanel then
        return
    end

    local rerollPanel = activePanel:recursiveGetChildById('reroll')
    if not rerollPanel or rerollPanel.isDestroyed and rerollPanel:isDestroyed() then
        return
    end

    local rerollButton = rerollPanel:recursiveGetChildById('rerollButton')
    local rerollVisible = not visible or not cancelButton
    if rerollButton and not rerollButton:isDestroyed() then
        rerollButton:setVisible(rerollVisible)
        if rerollButton.setEnabled then
            rerollButton:setEnabled(rerollVisible)
        end
    end
end

local function updateClaimRewardButton(activePanel)
    if not activePanel or activePanel:isDestroyed() then
        return
    end

    local styleLoaded = ensureCancelButtonStyle()

    local choosePanel = activePanel:recursiveGetChildById('choose')
    if not choosePanel or choosePanel:isDestroyed() then
        return
    end

    local button = choosePanel:recursiveGetChildById('selectPrey')
    if not button or button:isDestroyed() then
        return
    end

    if choosePanel.setSize then
        choosePanel:setSize('70 95')
    end

    if styleLoaded and button.setStyle then
        button:setStyle('HuntingTaskClaimRewardButton')
    elseif button.setImageSource then
        button:setImageSource('/images/game/prey/prey_hunting_task_claim_reward')
        if button.setImageClip then
            button:setImageClip('0 0 65 91')
        end
    end

    if button.setSize then
        button:setSize('65 91')
    end

    if button.disable then
        button:disable()
    elseif button.setEnabled then
        button:setEnabled(false)
    end

    local priceLabel = choosePanel:recursiveGetChildById('price')
    if priceLabel and priceLabel.setVisible then
        priceLabel:setVisible(false)
    end
end

local function clearSlotWidgets()
    for index = #slotWidgets, 1, -1 do
        local widget = slotWidgets[index]
        if widget then
            destroyWidget(widget)
        end
        slotWidgets[index] = nil
    end
end

local function destroyWidget(widget)
    if widget and not widget:isDestroyed() then
        widget:destroy()
    end
end

local function resolveTasksTab(preyWindow, tabWidget)
    if tabWidget and not tabWidget:isDestroyed() then
        return tabWidget
    end

    if not preyWindow then
        return nil
    end

    local widget = preyWindow:recursiveGetChildById('huntingTasksTab')
    if widget and widget.isDestroyed and widget:isDestroyed() then
        return nil
    end

    return widget
end

local function ensureContentWidget()
    if not tasksTab or (tasksTab.isDestroyed and tasksTab:isDestroyed()) then
        contentWidget = nil
        return nil
    end

    if contentWidget and not contentWidget:isDestroyed() then
        return contentWidget
    end

    contentWidget = tasksTab:getChildById('huntingTasksContent')
    if contentWidget and contentWidget.isDestroyed and contentWidget:isDestroyed() then
        contentWidget = nil
    end

    if not contentWidget and g_ui then
        contentWidget = g_ui.createWidget('UIWidget', tasksTab)
        contentWidget:setId('huntingTasksContent')
        if contentWidget.fill then
            contentWidget:fill('parent')
        else
            contentWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
            contentWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            contentWidget:addAnchor(AnchorRight, 'parent', AnchorRight)
            contentWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        end
    end

    return contentWidget
end

local function ensureSlotsContainer()
    local content = ensureContentWidget()
    if not content then
        return nil
    end

    if slotsContainer and slotsContainer.isDestroyed and slotsContainer:isDestroyed() then
        slotsContainer = nil
    end

    if slotsContainer then
        return slotsContainer
    end

    slotsContainer = g_ui and g_ui.createWidget('UIWidget', content) or nil
    if not slotsContainer then
        return nil
    end

    slotsContainer:setId('huntingTasksSlots')
    slotsContainer:setFocusable(false)
    slotsContainer:setPhantom(false)
    slotsContainer:fill('parent')

    return slotsContainer
end

local function removeTaskExclusiveOptions(slotWidget)
    if not slotWidget or slotWidget.isDestroyed and slotWidget:isDestroyed() then
        return
    end

    local autoReroll = slotWidget:recursiveGetChildById('autoReroll')
    if autoReroll then
        destroyWidget(autoReroll)
    end

    local autoRerollPrice = slotWidget:recursiveGetChildById('autoRerollPrice')
    if autoRerollPrice then
        destroyWidget(autoRerollPrice)
    end

    local lockPrey = slotWidget:recursiveGetChildById('lockPrey')
    if lockPrey then
        destroyWidget(lockPrey)
    end

    local lockPreyPrice = slotWidget:recursiveGetChildById('lockPreyPrice')
    if lockPreyPrice then
        destroyWidget(lockPreyPrice)
    end
end

local function configureSlotWidget(slotWidget, index)
    if not slotWidget then
        return nil
    end

    slotWidget:setId(string.format('huntingTaskSlot%d', index))
    if slotWidget.breakAnchors then
        slotWidget:breakAnchors()
    end

    slotWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
    slotWidget:setMarginTop(10)

    if index == 1 then
        slotWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
    else
        local previousSlot = slotWidgets[index - 1]
        if previousSlot then
            slotWidget:addAnchor(AnchorLeft, previousSlot:getId(), AnchorRight)
            slotWidget:setMarginLeft(10)
        else
            slotWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        end
    end

    removeTaskExclusiveOptions(slotWidget)

    local titleWidget = slotWidget:recursiveGetChildById('title')
    if titleWidget then
        titleWidget:setText(tr('Hunting Task Slot %d', index))
    end

    local activePanel = slotWidget:recursiveGetChildById('active')
    if activePanel then
        local creatureAndBonus = activePanel:recursiveGetChildById('creatureAndBonus')
        if creatureAndBonus and not creatureAndBonus.__huntingTaskAdjusted then
            creatureAndBonus.__huntingTaskAdjusted = true

            local creatureHeight = 160
            local creatureWidget = creatureAndBonus:recursiveGetChildById('creature')
            local originalCreatureHeight = creatureWidget and creatureWidget:getHeight() or 0
            if creatureWidget then
                creatureWidget:setHeight(creatureHeight)
            end

            local originalContainerHeight = creatureAndBonus:getHeight() or 0
            if originalCreatureHeight > 0 and originalContainerHeight > 0 then
                local heightDelta = creatureHeight - originalCreatureHeight
                if heightDelta ~= 0 then
                    local newContainerHeight = math.max(originalContainerHeight + heightDelta, creatureHeight)
                    creatureAndBonus:setHeight(newContainerHeight)
                end
            end

            local progressBar = creatureAndBonus:recursiveGetChildById('timeLeft')
            if progressBar and progressBar.breakAnchors then
                progressBar:breakAnchors()
                progressBar:addAnchor(AnchorLeft, 'parent', AnchorLeft)
                progressBar:addAnchor(AnchorRight, 'parent', AnchorRight)
                progressBar:addAnchor(AnchorBottom, 'parent', AnchorBottom)
                progressBar:setMarginBottom(0)
                progressBar:setMarginTop(0)
            end

            local bonusPanel = creatureAndBonus:recursiveGetChildById('bonus')
            if bonusPanel then
                local gradePanel = bonusPanel:recursiveGetChildById('grade')
                if gradePanel and gradePanel.setMarginBottom then
                    local progressHeight = progressBar and progressBar:getHeight() or 0
                    local spacing = 5
                    gradePanel:setMarginBottom(progressHeight + spacing)
                end
            end
        end
    end

    return slotWidget
end

local function ensureSlots()
    local container = ensureSlotsContainer()
    if not container then
        return nil
    end

    for index = 1, SLOT_COUNT do
        local slotWidget = slotWidgets[index]
        if not slotWidget or (slotWidget.isDestroyed and slotWidget:isDestroyed()) then
            slotWidget = g_ui and g_ui.createWidget('SlotPanel', container)
            slotWidgets[index] = slotWidget
            configureSlotWidget(slotWidget, index)
        end
    end

    return slotWidgets
end

local function setSlotsVisible(visible)
    if slotsContainer and not slotsContainer:isDestroyed() then
        slotsContainer:setVisible(visible)
    end
end

local function getSlotWidgetBySlotId(slotId)
    if slotId == nil then
        return nil, nil
    end

    local index = slotId + 1
    if index < 1 or index > SLOT_COUNT then
        return nil, nil
    end

    local slots = ensureSlots()
    return slots and slots[index] or nil, index
end

local function hideSlotPanels(slotWidget)
    if not slotWidget or slotWidget:isDestroyed() then
        return
    end

    setCancelButtonVisible(slotWidget, false)

    local inactive = slotWidget:recursiveGetChildById('inactive')
    if inactive then
        inactive:setVisible(false)
    end

    local active = slotWidget:recursiveGetChildById('active')
    if active then
        active:setVisible(false)
    end

    local locked = slotWidget:recursiveGetChildById('locked')
    if locked then
        locked:setVisible(false)
    end
end

local function updateTaskRarity(gradePanel, rarity)
    if not gradePanel or gradePanel:isDestroyed() then
        return
    end

    gradePanel:destroyChildren()

    local effectiveRarity = math.max(0, math.floor(rarity or 0))
    local maxStars = 5

    if not g_ui or not g_ui.createWidget then
        return
    end

    for index = 1, maxStars do
        local widgetName = index <= effectiveRarity and 'Star' or 'NoStar'
        g_ui.createWidget(widgetName, gradePanel)
    end

    gradePanel:setTooltip(tr('Rarity: %d', effectiveRarity))
end

local function updateTaskProgress(progressBar, currentKills, requiredKills)
    if not progressBar or progressBar:isDestroyed() then
        return
    end

    local kills = math.max(0, math.floor(currentKills or 0))
    local total = math.max(0, math.floor(requiredKills or 0))
    local percent = 0

    if total > 0 then
        percent = math.min(100, (kills / total) * 100)
    end

    local text = string.format('%d / %d', kills, total)

    progressBar:setPercent(percent)
    progressBar:setText(text)
    progressBar:setTooltip(tr('Hunting task progress: %s', text))
end

local function resolveRaceData(raceId)
    if not raceId or not g_things or not g_things.getRaceData then
        return nil
    end

    local data = g_things.getRaceData(raceId)
    if not data or data.raceId == 0 then
        return nil
    end

    return data
end

local function applyActiveTask(slotWidget, activeData)
    if not slotWidget or slotWidget:isDestroyed() or not activeData then
        return
    end

    hideSlotPanels(slotWidget)

    local activePanel = slotWidget:recursiveGetChildById('active')
    if activePanel then
        activePanel:setVisible(true)
    end

    local cancelButton = ensureCancelButton(slotWidget)
    setCancelButtonVisible(slotWidget, true)
    cancelButton = select(1, getCancelButton(slotWidget))

    local raceData = resolveRaceData(activeData.selectedRaceId)
    local titleWidget = slotWidget:recursiveGetChildById('title')
    local raceName = raceData and raceData.name or ''

    if not raceName or raceName:len() == 0 then
        raceName = activeData.selectedRaceId and tr('Unknown Creature (%d)', activeData.selectedRaceId) or
            tr('Hunting Task')
    end

    if titleWidget then
        titleWidget:setText(raceName)
    end

    if not activePanel then
        return
    end

    updateClaimRewardButton(activePanel)

    local creatureAndBonus = activePanel:recursiveGetChildById('creatureAndBonus')
    if creatureAndBonus and not creatureAndBonus:isDestroyed() then
        local creatureWidget = creatureAndBonus:recursiveGetChildById('creature')
        if creatureWidget then
            if raceData and raceData.outfit then
                creatureWidget:setOutfit(raceData.outfit)
                creatureWidget:setVisible(true)
            else
                creatureWidget:setVisible(false)
            end
            creatureWidget:setTooltip(raceName)
        end

        local bonusPanel = creatureAndBonus:recursiveGetChildById('bonus')
        if bonusPanel then
            local iconWidget = bonusPanel:recursiveGetChildById('icon')
            if iconWidget then
                iconWidget:setImageSource('/images/game/prey/prey_hunting_task_prey_token')
            end

            local gradePanel = bonusPanel:recursiveGetChildById('grade')
            updateTaskRarity(gradePanel, activeData.rarity)
        end

        local progressBar = creatureAndBonus:recursiveGetChildById('timeLeft')
        updateTaskProgress(progressBar, activeData.currentKills, activeData.requiredKills)
    end

    applyPriceToCancel(slotWidget, Tasks.prices)

    local activeCardsHeight = 0
    local cardSpacing = 4

    local function accumulateCardBounds(widget)
        if not widget or widget:isDestroyed() then
            return
        end

        if widget.getMarginTop and widget.setMarginTop and widget:getId() == 'choose' then
            widget:setMarginTop(cardSpacing)
        end

        local marginTop = widget.getMarginTop and widget:getMarginTop() or 0
        local marginBottom = widget.getMarginBottom and widget:getMarginBottom() or 0
        local height = widget.getHeight and widget:getHeight() or 0

        activeCardsHeight = math.max(activeCardsHeight, marginTop + height + marginBottom)
    end

    accumulateCardBounds(activePanel:recursiveGetChildById('choose'))
    accumulateCardBounds(activePanel:recursiveGetChildById('select'))
    if cancelButton and cancelButton:isVisible() then
        accumulateCardBounds(cancelButton)
    else
        accumulateCardBounds(activePanel:recursiveGetChildById('reroll'))
    end

    local creatureMarginTop = 0
    local creatureMarginBottom = 0
    local creatureHeight = 0
    if creatureAndBonus and not creatureAndBonus:isDestroyed() then
        creatureMarginTop = creatureAndBonus.getMarginTop and creatureAndBonus:getMarginTop() or 0
        creatureMarginBottom = creatureAndBonus.getMarginBottom and creatureAndBonus:getMarginBottom() or 0
        creatureHeight = creatureAndBonus.getHeight and creatureAndBonus:getHeight() or 0
    end

    local panelPaddingTop = activePanel.getPaddingTop and activePanel:getPaddingTop() or 0
    local panelPaddingBottom = activePanel.getPaddingBottom and activePanel:getPaddingBottom() or 0

    local desiredActiveHeight = creatureMarginTop + creatureHeight + creatureMarginBottom + activeCardsHeight +
        panelPaddingTop + panelPaddingBottom

    if desiredActiveHeight > 0 and activePanel.setHeight then
        local currentHeight = activePanel:getHeight() or 0
        if desiredActiveHeight > currentHeight then
            activePanel:setHeight(desiredActiveHeight)
        end
    end

    local titleWidget = slotWidget:recursiveGetChildById('title')
    local titleHeight = 0
    if titleWidget and not titleWidget:isDestroyed() then
        local titleMarginTop = titleWidget.getMarginTop and titleWidget:getMarginTop() or 0
        local titleMarginBottom = titleWidget.getMarginBottom and titleWidget:getMarginBottom() or 0
        titleHeight = titleMarginTop + (titleWidget.getHeight and titleWidget:getHeight() or 0) + titleMarginBottom
    end

    local slotPaddingTop = slotWidget.getPaddingTop and slotWidget:getPaddingTop() or 0
    local slotPaddingBottom = slotWidget.getPaddingBottom and slotWidget:getPaddingBottom() or 0
    local desiredSlotHeight = desiredActiveHeight + titleHeight + slotPaddingTop + slotPaddingBottom

    if desiredSlotHeight > 0 and slotWidget.setHeight then
        local currentSlotHeight = slotWidget:getHeight() or 0
        if desiredSlotHeight > currentSlotHeight then
            slotWidget:setHeight(desiredSlotHeight)
        end
    end
end

local function applyInactiveTask(slotWidget, title)
    if not slotWidget or slotWidget:isDestroyed() then
        return
    end

    hideSlotPanels(slotWidget)

    local inactivePanel = slotWidget:recursiveGetChildById('inactive')
    if inactivePanel then
        inactivePanel:setVisible(true)
    end

    local titleWidget = slotWidget:recursiveGetChildById('title')
    if titleWidget then
        titleWidget:setText(title or tr('No hunting task'))
    end
end

function Tasks.init(preyWindow, tabWidget)
    Tasks.terminate()

    tasksTab = resolveTasksTab(preyWindow, tabWidget)
    if not tasksTab then
        return
    end

    ensureContentWidget()
    ensureSlots()
    Tasks.showSlots()

    connect(g_game,
        {
            taskHuntingBasicData = taskHuntingBasicData,
            onTaskHuntingData = onTaskHuntingData,
            onPreyRerollPrice = onHuntingTaskPrices
        })
end

function onHuntingTaskPrices(data)
    Tasks.prices = Tasks.prices or {}
    Tasks.prices.cancelProgress = data.taskHuntingCancelProgressPriceInGold or 0
    Tasks.prices.rerollSelectionList = data.taskHuntingSelectionListPriceInGold or 0
    local bonusRerollCards = data.taskHuntingBonusRerollPriceInCards
    if bonusRerollCards == nil then
        bonusRerollCards = 1
    end
    Tasks.prices.bonusRerollInCards = bonusRerollCards
    Tasks.prices.taskHuntingBonusRerollPriceInCards = bonusRerollCards
    Tasks.prices.rerollSelectionListInCards = data.taskHuntingSelectionListPriceInCards or 5

    for _, slotWidget in ipairs(slotWidgets) do
        if slotWidget and not slotWidget:isDestroyed() then
            local activePanel = slotWidget:recursiveGetChildById('active')
            if activePanel and not activePanel:isDestroyed() and activePanel:isVisible() then
                updateClaimRewardButton(activePanel)
            end
        end
    end
end

function taskHuntingBasicData(data)
    Tasks.BasicData.difficultyByRaceId = Tasks.BasicData.difficultyByRaceId or data.difficultyByRaceId or {}
    g_logger.info(("taskHuntingBasicData: preys=%d, options=%d")
        :format(#(data.preys or {}), #(data.options or {})))

    local d1 = Tasks.BasicData.difficultyByRaceId[1938]
    if d1 then
        g_logger.info(("  raceId=1938 has difficulty=%d"):format(d1))
    end
    Tasks.BasicData.optionsByDifficulty = Tasks.BasicData.optionsByDifficulty or data.optionsByDifficulty or {}
    -- Acesso fácil por dificuldade/estrela:
    -- ex.: pegar os dados de difficulty=2, stars=4:
    local d2 = Tasks.BasicData.optionsByDifficulty[d1]
    local star4 = d2 and d2[5]
    if star4 then
        g_logger.info(("  D2*5 = firstKill=%d secondKill=%d"):format(star4.firstKill, star4.secondKill))
    end
end

-- [[
-- TaskHuntingData received: slotId=0, state=4, freeRerollRemainingSeconds=-75743
--   [Active] selectedRaceId=2539, upgrade=false, requiredKills=400, currentKills=0, rarity=2
-- TaskHuntingData received: slotId=1, state=2, freeRerollRemainingSeconds=-2932635
--   [Selection] 9 entries
--     [1] raceId=570, unlocked=false
--     [2] raceId=1659, unlocked=true
--     [3] raceId=1938, unlocked=true
--     [4] raceId=880, unlocked=false
--     [5] raceId=2343, unlocked=false
--     [6] raceId=211, unlocked=false
--     [7] raceId=2447, unlocked=true
--     [8] raceId=961, unlocked=true
--     [9] raceId=63, unlocked=false
-- TaskHuntingData received: slotId=2, state=0, freeRerollRemainingSeconds=-9
-- ]]
function onTaskHuntingData(data)
    g_logger.info(("TaskHuntingData received: slotId=%d, state=%d, freeRerollRemainingSeconds=%d")
        :format(data.slotId, data.state, data.freeRerollRemainingSeconds or 0))

    local slotWidget = getSlotWidgetBySlotId(data.slotId)
    if not slotWidget then
        return
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
        applyActiveTask(slotWidget, a)
        return
    end

    -- Completed
    if data.completed then
        local c = data.completed
        g_logger.info(("  [Completed] selectedRaceId=%d, upgrade=%s, requiredKills=%d, achievedKills=%d, rarity=%d")
            :format(c.selectedRaceId, tostring(c.upgrade), c.requiredKills, c.achievedKills, c.rarity))
        applyInactiveTask(slotWidget, tr('Completed task'))
        return
    end

    applyInactiveTask(slotWidget)
end

function Tasks.terminate()
    disconnect(g_game, {
        taskHuntingBasicData = taskHuntingBasicData,
        onTaskHuntingData = onTaskHuntingData,
        onPreyRerollPrice = onHuntingTaskPrices
    })
    clearSlotWidgets()
    destroyWidget(slotsContainer)
    slotsContainer = nil

    destroyWidget(placeholderWidget)
    placeholderWidget = nil

    if contentWidget and not contentWidget:isDestroyed() then
        contentWidget:destroyChildren()
    end

    contentWidget = nil
    tasksTab = nil
end

function Tasks.getTab()
    if tasksTab and not tasksTab:isDestroyed() then
        return tasksTab
    end
    return nil
end

function Tasks.getContentWidget()
    return ensureContentWidget()
end

function Tasks.clear()
    local content = ensureContentWidget()
    if not content then
        return
    end

    for _, child in ipairs(content:getChildren()) do
        if slotsContainer and child == slotsContainer then
            -- Preserve the slots container when clearing other content
            setSlotsVisible(true)
        else
            child:destroy()
        end
    end

    destroyWidget(placeholderWidget)
    placeholderWidget = nil
end

function Tasks.setContent(widget, keepAnchors)
    if not widget then
        return nil
    end

    local content = ensureContentWidget()
    if not content then
        return nil
    end

    Tasks.clear()

    setSlotsVisible(false)

    if widget:getParent() ~= content then
        widget:setParent(content)
    end

    widget:setVisible(true)

    if keepAnchors ~= true then
        if widget.fill then
            widget:fill('parent')
        else
            widget:addAnchor(AnchorTop, 'parent', AnchorTop)
            widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            widget:addAnchor(AnchorRight, 'parent', AnchorRight)
            widget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        end
    end

    return widget
end

function Tasks.showPlaceholder(text)
    local content = ensureContentWidget()
    if not content then
        return nil
    end

    setSlotsVisible(false)
    destroyWidget(placeholderWidget)

    placeholderWidget = g_ui.createWidget('UILabel', content)
    placeholderWidget:setId('huntingTasksPlaceholder')
    placeholderWidget:fill('parent')
    placeholderWidget:setTextWrap(true)
    placeholderWidget:setTextAlign(AlignCenter)
    placeholderWidget:setFont('verdana-11px-rounded')
    placeholderWidget:setColor('#c6c6c6')
    placeholderWidget:setText(text or tr('No hunting tasks available.'))

    return placeholderWidget
end

function Tasks.setPlaceholderText(text)
    if not placeholderWidget or placeholderWidget:isDestroyed() then
        return Tasks.showPlaceholder(text)
    end

    placeholderWidget:setText(text or tr('No hunting tasks available.'))
    return placeholderWidget
end

function Tasks.showSlots()
    local slots = ensureSlots()
    if not slots then
        return nil
    end

    if placeholderWidget then
        destroyWidget(placeholderWidget)
        placeholderWidget = nil
    end

    setSlotsVisible(true)
    return slots
end

function Tasks.getSlotCount()
    return SLOT_COUNT
end

function Tasks.getSlot(index)
    if index < 1 or index > SLOT_COUNT then
        return nil
    end

    local slots = ensureSlots()
    return slots and slots[index] or nil
end

return Tasks
