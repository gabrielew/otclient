GameHuntingTask = {}

local tabButton
local tabContent
local tabBar
local descriptionWidget
local slots = {}

local function reset()
    tabButton = nil
    tabContent = nil
    tabBar = nil
    descriptionWidget = nil
    slots = {}
end

local function detachWidget(widget)
    if not widget then
        return nil
    end

    local parent = widget:getParent()
    if parent then
        parent:removeChild(widget)
    end

    return widget
end

function init()
    g_ui.importStyle('hunting_task')
    reset()
end

function terminate()
    if tabContent then
        tabContent:destroy()
    end
    reset()
end

local function ensureTabContent()
    if not tabContent or tabContent:isDestroyed() then
        tabContent = g_ui.createWidget('HuntingTaskTab')
        descriptionWidget = tabContent:recursiveGetChildById('description')
        slots = {}
        for index = 1, 3 do
            local slotId = 'slot' .. index
            local slotWidget = tabContent:getChildById(slotId)
            if not slotWidget and tabContent.recursiveGetChildById then
                slotWidget = tabContent:recursiveGetChildById(slotId)
            end

            if slotWidget then
                tabContent[slotId] = slotWidget
                slots[index] = slotWidget
            end
        end
    end
    return tabContent
end

local function setPriceValue(container, value)
    if not container then
        return
    end

    local textWidget = container.text
    if not textWidget and container.getChildById then
        textWidget = container:getChildById('text')
        if textWidget and not container.text then
            container.text = textWidget
        end
    end

    if textWidget and textWidget.setText then
        if value == nil then
            textWidget:setText('')
        else
            textWidget:setText(tostring(value))
        end
    end
end

function GameHuntingTask.setUnsupportedSettings()
    ensureTabContent()

    if not slots or #slots == 0 then
        return
    end

    for _, slot in ipairs(slots) do
        if slot then
            for _, state in ipairs({ slot.active, slot.inactive }) do
                local selectWidget = state and state.select
                local priceWidget = selectWidget and selectWidget.price
                setPriceValue(priceWidget, 5)

                local rerollWidget = state and state.reroll and state.reroll.price
                setPriceValue(rerollWidget, 5)

                local chooseWidget = state and state.choose and state.choose.price
                setPriceValue(chooseWidget, 1)
            end
        end
    end
end

function GameHuntingTask.addTab(preyWindow, preyTabBar)
    if not preyWindow or not preyTabBar then
        return nil
    end

    local content = ensureTabContent()
    detachWidget(content)

    tabBar = preyTabBar
    tabButton = preyTabBar:addTab(tr('Hunting Tasks'), content)

    GameHuntingTask.setUnsupportedSettings()

    return tabButton
end

function GameHuntingTask.isTabSelected(selectedTab)
    if selectedTab then
        return tabButton and selectedTab == tabButton or false
    end

    if not tabBar or not tabButton then
        return false
    end

    return tabBar:getCurrentTab() == tabButton
end

function GameHuntingTask.setDescription(text)
    if descriptionWidget and not descriptionWidget:isDestroyed() then
        descriptionWidget:setText(text or '')
    end
end

function GameHuntingTask.getDescriptionWidget()
    if descriptionWidget and descriptionWidget:isDestroyed() then
        descriptionWidget = nil
    end
    return descriptionWidget
end

function GameHuntingTask.getTabContent()
    if tabContent and tabContent:isDestroyed() then
        tabContent = nil
    end
    return tabContent
end

function GameHuntingTask.getTabButton()
    if tabButton and tabButton:isDestroyed() then
        tabButton = nil
    end
    return tabButton
end

function GameHuntingTask.clear()
    if tabContent then
        tabContent:destroy()
    end
    reset()
end

function addTab(preyWindow, preyTabBar)
    return GameHuntingTask.addTab(preyWindow, preyTabBar)
end

function isTabSelected(selectedTab)
    return GameHuntingTask.isTabSelected(selectedTab)
end

function setDescription(text)
    GameHuntingTask.setDescription(text)
end

function setUnsupportedSettings()
    GameHuntingTask.setUnsupportedSettings()
end

function clear()
    GameHuntingTask.clear()
end
