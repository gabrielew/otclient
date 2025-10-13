GameHuntingTask = {}

local tabButton
local tabContent
local tabBar
local descriptionWidget

local function reset()
    tabButton = nil
    tabContent = nil
    tabBar = nil
    descriptionWidget = nil
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
    end
    return tabContent
end

function GameHuntingTask.addTab(preyWindow, preyTabBar)
    if not preyWindow or not preyTabBar then
        return nil
    end

    local content = ensureTabContent()
    detachWidget(content)

    tabBar = preyTabBar
    tabButton = preyTabBar:addTab(tr('Hunting Tasks'), content)

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

function clear()
    GameHuntingTask.clear()
end
