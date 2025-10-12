preyController = Controller:new()
local preyButton = nil
local preyTrackerButton = nil
local windowTypes = {}
local TAB_ORDER = { 'preyCreatures', 'huntingTasks' }

local function hide()
    if not preyController.ui then
        return
    end

    preyController.ui:hide()

    if preyButton then
        preyButton:setOn(false)
    end
end

function preyController:close()
    hide()
end

local TAB_CONFIG = {
    preyCreatures = {
        modeProperty = 'modePreyCreatures'
    },
    huntingTasks = {
        modeProperty = 'modeHuntingTasks'
    },
}

ui = {
    panels = {}
}

local function hideAllPanels()
    for _, panel in pairs(ui.panels) do
        if panel and panel.hide then
            panel:hide()
        end
    end
end

local function resetWindowTypes()
    for key in pairs(windowTypes) do
        windowTypes[key] = nil
    end
end

local function loadTabFragment(tabName)
    if not preyController or not preyController.ui then
        return nil
    end

    g_logger.info(('modules/%s/tab/%s/%s.html'):format(preyController.name, tabName, tabName))
    local fragment = io.content(('modules/%s/tab/%s/%s.html'):format(preyController.name, tabName, tabName))
    local container = preyController.ui:prepend(fragment)
    local panel = container
    if panel and panel.hide then
        panel:hide()
    end
    return panel
end

function preyController:getCurrentWindow()
    return self.currentWindowType and windowTypes[self.currentWindowType]
end

function preyController:loadTab(tabName)
    if ui.panels[tabName] then
        return ui.panels[tabName]
    end

    local panel = loadTabFragment(tabName)
    if panel then
        ui.panels[tabName] = panel
    end
    return panel
end

local function show(self)
    local needsReload = not self.ui or self.ui:isDestroyed()
    if needsReload then
        self:loadHtml('htmlsample.html')
        ui.panels = {}
    end

    if not self.ui then
        return
    end

    self.modeFusion, self.modeTransfer = false, false

    resetWindowTypes()
    self:loadTab('preyCreatures')


    hideAllPanels()

    local buttonPanel = self.ui.buttonPanel
    for tabName, config in pairs(TAB_CONFIG) do
        windowTypes[tabName .. 'Menu'] = {
            obj = buttonPanel and buttonPanel[tabName .. 'Btn'],
            panel = tabName,
            modeProperty = config.modeProperty
        }
    end

    self.ui:centerIn('parent')
    self.ui:show()
    self.ui:raise()
    self.ui:focus()

    if preyButton then
        preyButton:setOn(true)
    end

    SelectWindow('preyCreaturesMenu')
end

local function toggle(self)
    if not self.ui or self.ui:isDestroyed() then
        show(self)
        return
    end

    if self.ui:isVisible() then
        hide()
    else
        show(self)
    end
end

function preyController:toggle()
    toggle(self)
end

function preyController:show()
    show(self)
end

function preyController:hide()
    hide()
end

local function setWindowState(window, enabled)
    if window.obj then
        window.obj:setOn(not enabled)
        if enabled then
            window.obj:enable()
        else
            window.obj:disable()
        end
    end
end

function preyController:loadMenu(a, b, c)
    SelectWindow(a)
end

function SelectWindow(type, isBackButtonPress)
    local nextWindow = windowTypes[type]
    if not nextWindow then
        return
    end

    for windowType, window in pairs(windowTypes) do
        if windowType ~= type then
            setWindowState(window, true)
        end
    end

    setWindowState(nextWindow, false)
    preyController.currentWindowType = type

    hideAllPanels()
    local panel = preyController:loadTab(nextWindow.panel)
    if panel then
        panel:show()
        panel:raise()
    end

    if type == "preyCreaturesMenu" then
        if not isBackButtonPress then
            g_game.preyRequest()
        end
        return
    end

    if type == "huntingTasksMenu" then
    end
end

function preyController:onInit()
    g_logger.info(">>>>")

    if g_game.getFeature(GamePrey) then
        if not preyButton then
            preyButton = modules.game_mainpanel.addToggleButton('preyButton', tr('Prey Dialog'),
                '/images/options/button_preydialog', function() toggle(self) end)
        end
        -- if not preyTrackerButton then
        --     preyTrackerButton = modules.game_mainpanel.addToggleButton('preyTrackerButton', tr('Prey Tracker'),
        --         '/images/options/button_prey', toggleTracker)
        -- end
    elseif preyButton then
        preyButton:destroy()
        preyButton = nil
    end
    self.players = {}
end

function preyController:terminate()
    if preyButton then
        preyButton:destroy()
    end
    if preyTrackerButton then
        preyTrackerButton:destroy()
    end
end
