HuntingTasks = HuntingTasks or {}

local Tasks = HuntingTasks

local SLOT_COUNT = 3

local tasksTab
local contentWidget
local slotsContainer
local placeholderWidget
local slotWidgets = {}

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

function Tasks.init(preyWindow, tabWidget)
    Tasks.terminate()

    tasksTab = resolveTasksTab(preyWindow, tabWidget)
    if not tasksTab then
        return
    end

    ensureContentWidget()
    ensureSlots()
    Tasks.showSlots()
end

function Tasks.terminate()
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
