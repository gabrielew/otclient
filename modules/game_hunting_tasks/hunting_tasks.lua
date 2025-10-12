huntingTasksController = Controller:new()
huntingTasks = nil
huntingTasksWindow = nil

huntingTasksController.difficultyByRaceId = {}
huntingTasksController.optionsByDifficultyAndStars = {}
huntingTasksController.tabPanel = nil
huntingTasksController.tabHtmlId = nil

function onPreyRaceListItemClicked(widget)

end

function onPreyRaceListItemHoverChange(widget)

end

local function applyDefaultLabel(query, text)
    local widgets = huntingTasksController:findWidgets(query)
    if type(widgets) ~= 'table' then
        return
    end

    for _, widget in pairs(widgets) do
        if widget and widget.setText then
            widget:setText(text)
        end
    end
end

function setUnsupportedSettings()
    if not huntingTasksController.tabPanel or huntingTasksController.tabPanel:isDestroyed() then
        return
    end

    applyDefaultLabel('#hunting_tasks_slot_1 #select .action-label', 'Select (5)')
    applyDefaultLabel('#hunting_tasks_slot_1 #choose .action-label', 'Choose (1)')
    applyDefaultLabel('#hunting_tasks_slot_1 #reroll .action-price', '5')
end

local function getPreySlotWidget(slot)
    if not huntingTasksWindow then
        return nil
    end
    return huntingTasksWindow['hunting_tasks_slot_' .. (slot + 1)]
end

function huntingTasksController:onInit()
    self:registerEvents(g_game, {
        onTaskHuntingData = onTaskHuntingData,
        taskHuntingBasicData = taskHuntingBasicData,
    })

    setUnsupportedSettings()
end

function huntingTasksController:createTabPanel(widgetId)
    if self.tabPanel and not self.tabPanel:isDestroyed() then
        if widgetId and self.tabPanel.setId then
            self.tabPanel:setId(widgetId)
        end
        return self.tabPanel
    end

    if self.tabHtmlId then
        self:destroyUI()
        self.tabPanel = nil
        self.tabHtmlId = nil
    end

    local tempParent = g_ui.createWidget('Panel', g_ui.getRootWidget())
    tempParent:setVisible(false)
    local htmlId = g_html.load(self.name, 'hunting_tasks_content.html', tempParent)
    local root = g_html.getRootWidget(htmlId)

    if not root then
        tempParent:destroy()
        return nil
    end

    root:setParent(nil)
    tempParent:destroy()

    if widgetId and root.setId then
        root:setId(widgetId)
    end

    self.tabHtmlId = htmlId
    self.htmlId = htmlId
    self.tabPanel = root
    self.ui = root

    setUnsupportedSettings()

    return root
end

function huntingTasksController:onTerminate()
    self.tabPanel = nil
    self.tabHtmlId = nil
end

function taskHuntingBasicData(data)
    g_logger.info(("taskHuntingBasicData: preys=%d, options=%d")
        :format(#(data.preys or {}), #(data.options or {})))

    -- Log compacto
    for i, p in ipairs(data.preys or {}) do
        huntingTasksController.difficultyByRaceId[p.raceId] = p.difficulty
        -- g_logger.info(("  Prey[%d] raceId=%d difficulty=%d"):format(i, p.raceId, p.difficulty))
    end

    huntingTasksController.optionsByDifficultyAndStars = data.options or {}

    -- for i, o in ipairs(data.options or {}) do
    --     g_logger.info(("  Option[%d] diff=%d stars=%d firstKill=%d firstReward=%d secondKill=%d secondReward=%d")
    --         :format(i, o.difficulty, o.stars, o.firstKill, o.firstReward, o.secondKill, o.secondReward))
    -- end

    -- Acesso fácil por dificuldade/estrela:
    -- ex.: pegar os dados de difficulty=2, stars=4:
    local d2 = data.optionsByDifficulty and data.optionsByDifficulty[2]
    local star4 = d2 and d2[4]
    if star4 then
        g_logger.info(("  D2*4 = firstKill=%d secondKill=%d"):format(star4.firstKill, star4.secondKill))
    end
end

function onTaskHuntingData(data)
    g_logger.info(("TaskHuntingData received: slotId=%d, state=%d, freeRerollRemainingSeconds=%d")
        :format(data.slotId, data.state, data.freeRerollRemainingSeconds or 0))

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
    end

    -- Completed
    if data.completed then
        local c = data.completed
        g_logger.info(("  [Completed] selectedRaceId=%d, upgrade=%s, requiredKills=%d, achievedKills=%d, rarity=%d")
            :format(c.selectedRaceId, tostring(c.upgrade), c.requiredKills, c.achievedKills, c.rarity))
    end
end
