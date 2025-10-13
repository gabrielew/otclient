PreyWindowTabs = PreyWindowTabs or {}

local Tabs = PreyWindowTabs

local CREATURES_TAB_STYLE = 'PreyCreaturesTabButton'
local TASKS_TAB_STYLE = 'PreyTasksTabButton'
local pendingTaskHuntingBasicData

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

local function isHuntingTasksTabSelected(selectedTab)
    if selectedTab then
        return Tabs.huntingTasksTabButton and selectedTab == Tabs.huntingTasksTabButton or false
    end

    return Tabs.tabBar and Tabs.huntingTasksTabButton and
        Tabs.tabBar:getCurrentTab() == Tabs.huntingTasksTabButton or false
end

local function getHuntingTasksModule()
    return rawget(_G, 'HuntingTasks')
end

local function forwardTaskHuntingBasicData()
    if not pendingTaskHuntingBasicData then
        return
    end

    if not isHuntingTasksTabSelected() then
        return
    end

    local module = getHuntingTasksModule()
    if not module or type(module.setBasicData) ~= 'function' then
        return
    end

    module.setBasicData(pendingTaskHuntingBasicData)

    if type(module.onTabSelected) == 'function' then
        module.onTabSelected()
    end
end

local function updateHuntingTasksResourceVisibility(selectedTab)
    if not Tabs.huntingTasksResource then
        return
    end

    Tabs.huntingTasksResource:setVisible(isHuntingTasksTabSelected(selectedTab))
end

local function setupHuntingTasksResource(preyWindow)
    if not preyWindow then
        return
    end

    local huntingTasksResource = preyWindow:recursiveGetChildById('huntingTasksResource')
    if not huntingTasksResource then
        return
    end

    Tabs.huntingTasksResource = huntingTasksResource

    local huntingTaskIcon = huntingTasksResource:getChildById('huntingTaskPoints') or
        huntingTasksResource:recursiveGetChildById('huntingTaskPoints')
    if huntingTaskIcon then
        huntingTaskIcon:setTooltip(tr('Hunting Task Points'))
    end

    local textWidget = huntingTasksResource:getChildById('text') or
        huntingTasksResource:recursiveGetChildById('text')
    if textWidget then
        Tabs.huntingTasksResourceText = textWidget
    end

    huntingTasksResource:setVisible(false)
end

function Tabs.onTabChange(tabBar, tab)
    updateHuntingTasksResourceVisibility(tab)

    if isHuntingTasksTabSelected(tab) then
        Tabs.updateResourceLabelsFromPlayer()
        forwardTaskHuntingBasicData()
    end
end

function Tabs.setup(preyWindow, config)
    Tabs.window = preyWindow
    Tabs.tabBar = preyWindow and preyWindow:getChildById('preyTabBar') or nil
    Tabs.tabContent = config and config.tabContent or (preyWindow and preyWindow:getChildById('preyTabContent'))
    Tabs.creaturesTab = config and config.creaturesTab or
        (preyWindow and preyWindow:recursiveGetChildById('preyCreaturesTab'))
    Tabs.huntingTasksTab = config and config.huntingTasksTab or
        (preyWindow and preyWindow:recursiveGetChildById('huntingTasksTab'))
    Tabs.huntingTasksTabButton = nil

    setupHuntingTasksResource(preyWindow)

    if Tabs.tabBar and Tabs.tabContent then
        Tabs.tabBar:setContentWidget(Tabs.tabContent)

        local creaturesTabWidget = detachWidget(Tabs.creaturesTab)
        local huntingTasksWidget = detachWidget(Tabs.huntingTasksTab)

        local creaturesTab
        if creaturesTabWidget then
            creaturesTab = Tabs.tabBar:addTab('', creaturesTabWidget)
            creaturesTab:setStyle(CREATURES_TAB_STYLE)
            creaturesTab:setTooltip(tr('Prey Creatures'))
        end

        if huntingTasksWidget then
            Tabs.huntingTasksTabButton =
                Tabs.tabBar:addTab('', huntingTasksWidget)
            Tabs.huntingTasksTabButton:setStyle(TASKS_TAB_STYLE)
            Tabs.huntingTasksTabButton:setTooltip(tr('Hunting Tasks'))
        end

        connect(Tabs.tabBar, { onTabChange = Tabs.onTabChange })

        if creaturesTab then
            Tabs.tabBar:selectTab(creaturesTab)
        end
    end

    updateHuntingTasksResourceVisibility()
    forwardTaskHuntingBasicData()
end

function Tabs.updateResourceLabelsFromPlayer()
    local preyWindow = Tabs.window
    if not preyWindow then
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        if preyWindow.gold then
            preyWindow.gold:setText('0')
        end
        if preyWindow.wildCards then
            preyWindow.wildCards:setText('0')
        end
        if Tabs.huntingTasksResourceText then
            Tabs.huntingTasksResourceText:setText('0')
        end
        return
    end

    if preyWindow.gold then
        preyWindow.gold:setText(comma_value(player:getTotalMoney()))
    end

    if preyWindow.wildCards and ResourceTypes and ResourceTypes.PREY_WILDCARDS then
        local wildcardsBalance = player:getResourceBalance(ResourceTypes.PREY_WILDCARDS)
        preyWindow.wildCards:setText(tostring(wildcardsBalance))
    end

    if Tabs.huntingTasksResourceText and ResourceTypes and ResourceTypes.TASK_HUNTING then
        local huntingBalance = player:getResourceBalance(ResourceTypes.TASK_HUNTING)
        Tabs.huntingTasksResourceText:setText(tostring(huntingBalance))
    end
end

function Tabs.resetResourceDisplays()
    local preyWindow = Tabs.window
    if not preyWindow then
        return
    end

    if preyWindow.gold then
        preyWindow.gold:setText('0')
    end

    if preyWindow.wildCards then
        preyWindow.wildCards:setText('0')
    end

    if Tabs.huntingTasksResourceText then
        Tabs.huntingTasksResourceText:setText('0')
    end

    updateHuntingTasksResourceVisibility()
end

function Tabs.terminate()
    if Tabs.tabBar then
        disconnect(Tabs.tabBar, { onTabChange = Tabs.onTabChange })
    end

    Tabs.window = nil
    Tabs.tabBar = nil
    Tabs.tabContent = nil
    Tabs.creaturesTab = nil
    Tabs.huntingTasksTab = nil
    Tabs.huntingTasksTabButton = nil
    Tabs.huntingTasksResource = nil
    Tabs.huntingTasksResourceText = nil
    pendingTaskHuntingBasicData = nil
end

function Tabs.getTaskHuntingBasicData()
    return pendingTaskHuntingBasicData
end

function g_game.taskHuntingBasicData(data)
    pendingTaskHuntingBasicData = data
    local module = getHuntingTasksModule()
    if module and type(module.setBasicData) == 'function' then
        module.setBasicData(pendingTaskHuntingBasicData)
    end
    forwardTaskHuntingBasicData()
end

return Tabs
