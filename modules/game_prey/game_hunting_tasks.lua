PreyHuntingTasks = {}

local preyTabBar
local huntingTasksPanel
local openTasksButton

local function configureTabAppearance(tab)
    if not tab then
        return
    end

    tab:setWidth(200)
    tab:setIconSize({ width = 20, height = 20 })
end

local function updateOpenTasksButtonState()
    if not openTasksButton or openTasksButton:isDestroyed() then
        return
    end

    local hasTasksModule = modules and modules.game_tasks and modules.game_tasks.toggleWindow
    if hasTasksModule then
        openTasksButton:setEnabled(true)
        openTasksButton:setTooltip(tr('Open the standalone hunting tasks window.'))
    else
        openTasksButton:setEnabled(false)
        openTasksButton:setTooltip(tr('The Tasks module is not available.'))
    end
end

function PreyHuntingTasks.setup(preyWindow)
    if not preyWindow then
        return
    end

    preyTabBar = preyWindow:getChildById('preyTabBar')
    local tabContent = preyWindow:getChildById('preyTabContent')

    if not preyTabBar or not tabContent then
        return
    end

    preyTabBar:setContentWidget(tabContent)

    local creaturesPanel = tabContent:getChildById('preyCreaturesPanel')
    if creaturesPanel then
        local creaturesTabName = tr('Prey Creatures')
        local creaturesTab = preyTabBar:getTab(creaturesTabName)
        if not creaturesTab then
            creaturesTab = preyTabBar:addTab(creaturesTabName, creaturesPanel, '/images/game/prey/icon-prey-widget')
        end
        configureTabAppearance(creaturesTab)

        if creaturesTab and not preyTabBar:getCurrentTab() then
            preyTabBar:selectTab(creaturesTab)
        end
    end

    huntingTasksPanel = tabContent:getChildById('huntingTasksPanel')
    if not huntingTasksPanel then
        return
    end

    if not huntingTasksPanel:getChildById('huntingTasksContent') then
        g_ui.loadUI('hunting_tasks', huntingTasksPanel)
    end

    openTasksButton = huntingTasksPanel:recursiveGetChildById('openTasksButton')

    local huntingTasksTabName = tr('Hunting Tasks')
    local huntingTasksTab = preyTabBar:getTab(huntingTasksTabName)
    if not huntingTasksTab then
        huntingTasksTab = preyTabBar:addTab(huntingTasksTabName, huntingTasksPanel, '/modules/game_tasks/images/taskIconColorless')
    end
    configureTabAppearance(huntingTasksTab)

    updateOpenTasksButtonState()
end

function PreyHuntingTasks.refresh()
    updateOpenTasksButtonState()
end

function PreyHuntingTasks.terminate()
    preyTabBar = nil
    huntingTasksPanel = nil
    openTasksButton = nil
end
