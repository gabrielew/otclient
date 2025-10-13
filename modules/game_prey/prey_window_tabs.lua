local PreyWindowTabs = {}

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
        return PreyWindowTabs.huntingTasksTabButton and selectedTab == PreyWindowTabs.huntingTasksTabButton or false
    end

    return PreyWindowTabs.tabBar and PreyWindowTabs.huntingTasksTabButton and
        PreyWindowTabs.tabBar:getCurrentTab() == PreyWindowTabs.huntingTasksTabButton or false
end

local function updateHuntingTasksResourceVisibility(selectedTab)
    if not PreyWindowTabs.huntingTasksResource then
        return
    end

    PreyWindowTabs.huntingTasksResource:setVisible(isHuntingTasksTabSelected(selectedTab))
end

local function setupHuntingTasksResource(preyWindow)
    if not preyWindow then
        return
    end

    local huntingTasksResource = preyWindow:recursiveGetChildById('huntingTasksResource')
    if not huntingTasksResource then
        return
    end

    PreyWindowTabs.huntingTasksResource = huntingTasksResource

    local huntingTaskIcon = huntingTasksResource:getChildById('huntingTaskPoints') or
        huntingTasksResource:recursiveGetChildById('huntingTaskPoints')
    if huntingTaskIcon then
        huntingTaskIcon:setTooltip(tr('Hunting Task Points'))
    end

    local textWidget = huntingTasksResource:getChildById('text') or
        huntingTasksResource:recursiveGetChildById('text')
    if textWidget then
        PreyWindowTabs.huntingTasksResourceText = textWidget
    end

    huntingTasksResource:setVisible(false)
end

function PreyWindowTabs.onTabChange(tabBar, tab)
    updateHuntingTasksResourceVisibility(tab)

    if isHuntingTasksTabSelected(tab) then
        PreyWindowTabs.updateResourceLabelsFromPlayer()
    end
end

function PreyWindowTabs.setup(preyWindow, config)
    PreyWindowTabs.window = preyWindow
    PreyWindowTabs.tabBar = preyWindow and preyWindow:getChildById('preyTabBar') or nil
    PreyWindowTabs.tabContent = config and config.tabContent or (preyWindow and preyWindow:getChildById('preyTabContent'))
    PreyWindowTabs.creaturesTab = config and config.creaturesTab or
        (preyWindow and preyWindow:recursiveGetChildById('preyCreaturesTab'))
    PreyWindowTabs.huntingTasksTab = config and config.huntingTasksTab or
        (preyWindow and preyWindow:recursiveGetChildById('huntingTasksTab'))
    PreyWindowTabs.huntingTasksTabButton = nil

    setupHuntingTasksResource(preyWindow)

    if PreyWindowTabs.tabBar and PreyWindowTabs.tabContent then
        PreyWindowTabs.tabBar:setContentWidget(PreyWindowTabs.tabContent)

        local creaturesTabWidget = detachWidget(PreyWindowTabs.creaturesTab)
        local huntingTasksWidget = detachWidget(PreyWindowTabs.huntingTasksTab)

        local creaturesTab
        if creaturesTabWidget then
            creaturesTab = PreyWindowTabs.tabBar:addTab(tr('Prey Creatures'), creaturesTabWidget)
        end

        if huntingTasksWidget then
            PreyWindowTabs.huntingTasksTabButton =
                PreyWindowTabs.tabBar:addTab(tr('Hunting Tasks'), huntingTasksWidget)
        end

        connect(PreyWindowTabs.tabBar, { onTabChange = PreyWindowTabs.onTabChange })

        if creaturesTab then
            PreyWindowTabs.tabBar:selectTab(creaturesTab)
        end
    end

    updateHuntingTasksResourceVisibility()
end

function PreyWindowTabs.updateResourceLabelsFromPlayer()
    local preyWindow = PreyWindowTabs.window
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
        if PreyWindowTabs.huntingTasksResourceText then
            PreyWindowTabs.huntingTasksResourceText:setText('0')
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

    if PreyWindowTabs.huntingTasksResourceText and ResourceTypes and ResourceTypes.TASK_HUNTING then
        local huntingBalance = player:getResourceBalance(ResourceTypes.TASK_HUNTING)
        PreyWindowTabs.huntingTasksResourceText:setText(tostring(huntingBalance))
    end
end

function PreyWindowTabs.resetResourceDisplays()
    local preyWindow = PreyWindowTabs.window
    if not preyWindow then
        return
    end

    if preyWindow.gold then
        preyWindow.gold:setText('0')
    end

    if preyWindow.wildCards then
        preyWindow.wildCards:setText('0')
    end

    if PreyWindowTabs.huntingTasksResourceText then
        PreyWindowTabs.huntingTasksResourceText:setText('0')
    end

    updateHuntingTasksResourceVisibility()
end

function PreyWindowTabs.terminate()
    if PreyWindowTabs.tabBar then
        disconnect(PreyWindowTabs.tabBar, { onTabChange = PreyWindowTabs.onTabChange })
    end

    PreyWindowTabs.window = nil
    PreyWindowTabs.tabBar = nil
    PreyWindowTabs.tabContent = nil
    PreyWindowTabs.creaturesTab = nil
    PreyWindowTabs.huntingTasksTab = nil
    PreyWindowTabs.huntingTasksTabButton = nil
    PreyWindowTabs.huntingTasksResource = nil
    PreyWindowTabs.huntingTasksResourceText = nil
end

return PreyWindowTabs
