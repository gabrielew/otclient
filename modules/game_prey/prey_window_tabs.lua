PreyWindowTabs = PreyWindowTabs or {}

local Tabs = PreyWindowTabs

local PREY_WINDOW_TABS_UI = [=[
MainWindow
  id: preyWindow
  !text: tr('Prey')
  size: 698 520
  @onEscape: modules.game_prey.hide()
  padding: 20
  @onHoverChange: modules.game_prey.onHover(self)

  TabBar
    id: preyTabBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 34

  Panel
    id: preyTabContent
    anchors.top: preyTabBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: bottomSep.top

    Panel
      id: preyCreaturesTab
      anchors.fill: parent

      SlotPanel
        id: slot1
        anchors.left: parent.left
        anchors.top: parent.top
        margin-top: 10

      SlotPanel
        id: slot2
        anchors.verticalCenter: prev.verticalCenter
        anchors.left: prev.right
        margin-left: 10

      SlotPanel
        id: slot3
        anchors.verticalCenter: prev.verticalCenter
        anchors.left: prev.right
        margin-left: 10

      FlatLabel
        id: description
        anchors.left: slot1.left
        anchors.top: slot1.bottom
        anchors.right: slot3.right
        anchors.bottom: bottomSep.top
        margin-bottom: 10
        margin-top: 10
        text-wrap: true

    Panel
      id: huntingTasksTab
      anchors.fill: parent

  HorizontalSeparator
    id: bottomSep
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeButton.top
    margin-bottom: 10

  Button
    id: closeButton
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    size: 45 21
    text: Close
    font: cipsoftFont
    @onClick: modules.game_prey.hide()

  GoldLabel
    id: gold
    anchors.left: bottomSep.left
    anchors.verticalCenter: closeButton.verticalCenter
    size: 105 20

  CardLabel
    id: wildCards
    anchors.left: prev.right
    margin-left: 10
    anchors.verticalCenter: closeButton.verticalCenter
    size: 55 20

  UIButton
    id: openStore
    anchors.left: prev.right
    margin-left: 10
    size: 26 20
    anchors.verticalCenter: closeButton.verticalCenter
    tooltip: Go to the Store to get more Prey Wildcards!
    image-source: /images/game/prey/prey_smallstore
    image-clip: 0 0 26 20
    background-color: #17354e
    @onClick: modules.game_mainpanel.toggleStore()

    $pressed:
      image-clip: 0 0 26 20
      image-source: /images/game/prey/prey_smallstore_clicked
      image-clip: -1 -1 27 21

  HuntingTaskLabel
    id: huntingTasksResource
    anchors.left: prev.right
    margin-left: 10
    anchors.verticalCenter: closeButton.verticalCenter
    size: 70 20
    visible: false
]=]

function Tabs.createWindow(parent)
    local targetParent = parent or g_ui.getRootWidget()
    return g_ui.loadUIFromString(PREY_WINDOW_TABS_UI, targetParent)
end

local CREATURES_TAB_STYLE = 'PreyCreaturesTabButton'
local TASKS_TAB_STYLE = 'PreyTasksTabButton'

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
end

return Tabs
