preyController = Controller:new()
local preyButton = nil
local preyTrackerButton = nil
local windowTypes = {}
local TAB_ORDER = { 'preyCreatures', 'huntingTasks' }
preyController.lookType1 = 2599
preyController.lookType2 = 2599
preyController.lookType3 = 2599



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
    for key, panel in pairs(ui.panels) do
        if panel then
            if panel:isDestroyed() then
                ui.panels[key] = nil
            elseif panel.hide then
                panel:hide()
            end
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
    local panel = ui.panels[tabName]
    if panel and panel:isDestroyed() then
        ui.panels[tabName] = nil
        panel = nil
    end

    if panel then
        return panel
    end

    panel = loadTabFragment(tabName)
    if panel then
        ui.panels[tabName] = panel
    end
    return panel
end

function preyController:toggle()
    if not self.ui or self.ui:isDestroyed() then
        self:show()
        return
    end

    if self.ui:isVisible() then
        self:hide()
    else
        self:show()
    end
end

local buttons = {
    normal = { x = 0, y = 0, width = 340, height = 34 },
    pressed = { x = 0, y = 34, width = 340, height = 34 },
}

local preySelectButtons = {
    normal = { x = 0, y = 0, width = 65, height = 66 },
    pressed = { x = 0, y = 66, width = 65, height = 66 },
    disabled = { x = 0, y = 132, width = 65, height = 66 },
}

function preyController:selectPrey(slotId)
end

function preyController:show()
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
    self.buttons.prey = buttons.pressed
end

function preyController:hide()
    if not self.ui then
        return
    end

    self.ui:hide()

    if preyButton then
        preyButton:setOn(false)
    end
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

preyController.buttons = {
    prey = buttons.pressed,
    task = buttons.normal
}

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
        preyController.buttons.prey = buttons.pressed
        preyController.buttons.task = buttons.normal
        if not isBackButtonPress then
            g_game.preyRequest()
        end
        return
    end

    if type == "huntingTasksMenu" then
        preyController.buttons.prey = buttons.normal
        preyController.buttons.task = buttons.pressed
    end
end

function preyController:onInit()
    g_logger.info(">>>>")

    if g_game.getFeature(GamePrey) then
        if not preyButton then
            preyButton = modules.game_mainpanel.addToggleButton('preyButton', tr('Prey Dialog'),
                '/images/options/button_preydialog', function() self:toggle() end)
        end
        -- if not preyTrackerButton then
        --     preyTrackerButton = modules.game_mainpanel.addToggleButton('preyTrackerButton', tr('Prey Tracker'),
        --         '/images/options/button_prey', toggleTracker)
        -- end
    elseif preyButton then
        preyButton:destroy()
        preyButton = nil
    end

    preyController.slot_1_stars = { 1, 2, 3, 4, 5 }

    preyController.slots = {
        { id = 1, stars = 10, name = "Rat",    prey = "/images/game/prey/prey_bigxp.png",     lookType = 56,   reroll = true,  lockPrey = false, nextFreeReroll = "02:50", timeleft = "19:59" },
        { id = 2, stars = 5,  name = "Bat",    prey = "/images/game/prey/prey_bigloot.png",   lookType = 34,   reroll = false, lockPrey = true,  nextFreeReroll = "02:50", timeleft = "19:12" },
        { id = 3, stars = 10, name = "Wyvern", prey = "/images/game/prey/prey_bigdamage.png", lookType = 1794, reroll = true,  lockPrey = false, nextFreeReroll = "02:50", timeleft = "19:11" },
    }
end

function preyController:terminate()
    if preyButton then
        preyButton:destroy()
    end
    if preyTrackerButton then
        preyTrackerButton:destroy()
    end
end
