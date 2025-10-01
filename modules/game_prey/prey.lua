-- sponsored by kivera-global.com
-- remade by Vithrax#5814
Prey = {}
preyWindow = nil
preyButton = nil
local preyTrackerButton
local msgWindow
local bankGold = 0
local inventoryGold = 0
local rerollPrice = 0
local bonusRerolls = 0

local PREY_BONUS_DAMAGE_BOOST = 0
local PREY_BONUS_DAMAGE_REDUCTION = 1
local PREY_BONUS_XP_BONUS = 2
local PREY_BONUS_IMPROVED_LOOT = 3
local PREY_BONUS_NONE = 4

local PREY_ACTION_LISTREROLL = 0
local PREY_ACTION_BONUSREROLL = 1
local PREY_ACTION_MONSTERSELECTION = 2
local PREY_ACTION_REQUEST_ALL_MONSTERS = 3
local PREY_ACTION_CHANGE_FROM_ALL = 4
local PREY_ACTION_OPTION = 5
local PREY_OPTION_UNTOGGLE = 0
local PREY_OPTION_TOGGLE_AUTOREROLL = 1
local PREY_OPTION_TOGGLE_LOCK_PREY = 2

local preyDescription = {}

local preyListSelection = {
    window = nil,
    list = nil,
    search = nil,
    confirmButton = nil,
    cancelButton = nil,
    counterLabel = nil,
    entries = {},
    selectedItem = nil,
    slot = nil,
    ignoreSearchEvents = false,
    ignoreFocusChange = false
}

local function hidePreyListSelectionWindow()
    if not preyListSelection.window then
        return
    end

    preyListSelection.window:hide()
    preyListSelection.slot = nil
    preyListSelection.selectedItem = nil
    preyListSelection.entries = {}
    if preyListSelection.list then
        preyListSelection.ignoreFocusChange = true
        preyListSelection.list:destroyChildren()
        preyListSelection.ignoreFocusChange = false
    end
    if preyListSelection.confirmButton then
        preyListSelection.confirmButton:disable()
    end
    if preyListSelection.counterLabel then
        preyListSelection.counterLabel:setText('0 / 0')
    end
    if preyListSelection.search then
        preyListSelection.ignoreSearchEvents = true
        preyListSelection.search:setText('')
        preyListSelection.ignoreSearchEvents = false
    end
end

local function selectPreyListItem(widget, skipFocus)
    if not widget or not widget.raceId then
        return
    end

    if preyListSelection.selectedItem and preyListSelection.selectedItem ~= widget then
        preyListSelection.selectedItem:setOn(false)
    end

    preyListSelection.selectedItem = widget
    widget:setOn(true)

    if not skipFocus and preyListSelection.list then
        preyListSelection.list:focusChild(widget, MouseFocusReason)
    end

    if preyListSelection.confirmButton then
        preyListSelection.confirmButton:enable()
    end
end

local function confirmPreyListSelection()
    if not preyListSelection.selectedItem or not preyListSelection.slot then
        return
    end

    g_game.preyAction(preyListSelection.slot, PREY_ACTION_CHANGE_FROM_ALL, preyListSelection.selectedItem.raceId)
    hidePreyListSelectionWindow()
end

local function refreshPreyListSelection(filterText)
    if not preyListSelection.list then
        return
    end

    preyListSelection.ignoreFocusChange = true
    preyListSelection.list:destroyChildren()
    preyListSelection.selectedItem = nil

    if preyListSelection.confirmButton then
        preyListSelection.confirmButton:disable()
    end

    local visibleCount = 0
    filterText = filterText or ''
    filterText = filterText:lower()

    for _, entry in ipairs(preyListSelection.entries) do
        if filterText == '' or entry.searchName:find(filterText, 1, true) then
            local item = g_ui.createWidget('PreyListItem', preyListSelection.list)
            item:setId(tostring(entry.raceId))
            item:setText(entry.displayName)
            item.raceId = entry.raceId

            item.onClick = function()
                selectPreyListItem(item)
            end

            item.onDoubleClick = function()
                selectPreyListItem(item)
                confirmPreyListSelection()
            end

            visibleCount = visibleCount + 1
        end
    end

    if visibleCount == 0 then
        local emptyLabel = g_ui.createWidget('Label', preyListSelection.list)
        emptyLabel:setText(tr('No creatures found.'))
        emptyLabel:setTextAlign(AlignCenter)
        emptyLabel:setColor('#9d9d9d')
        emptyLabel:setMarginTop(4)
        emptyLabel:setFocusable(false)
    else
        local firstChild = preyListSelection.list:getFirstChild()
        if firstChild then
            preyListSelection.list:focusChild(firstChild, KeyboardFocusReason)
        end
    end

    if preyListSelection.counterLabel then
        preyListSelection.counterLabel:setText(string.format('%d / %d', visibleCount, #preyListSelection.entries))
    end

    preyListSelection.ignoreFocusChange = false
end

local function assignPickSpecificPreyHandler(panel, slot)
    if not panel or not panel.select or not panel.select.pickSpecificPrey then
        return
    end

    panel.select.pickSpecificPrey.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_REQUEST_ALL_MONSTERS, 0)
    end
end

function bonusDescription(bonusType, bonusValue, bonusGrade)
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return 'Damage bonus (' .. bonusGrade .. '/10)'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return 'Damage reduction bonus (' .. bonusGrade .. '/10)'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return 'XP bonus (' .. bonusGrade .. '/10)'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return 'Loot bonus (' .. bonusGrade .. '/10)'
    else
        return 'Unknown bonus'
    end
    return 'Unknown bonus'
end

function timeleftTranslation(timeleft, forPreyTimeleft) -- in seconds
    if timeleft == 0 then
        if forPreyTimeleft then
            return tr('infinite bonus')
        end
        return tr('Free')
    end
    local hours = string.format('%02.f', math.floor(timeleft / 3600))
    local mins = string.format('%02.f', math.floor(timeleft / 60 - (hours * 60)))
    return hours .. ':' .. mins
end

function init()
    connect(g_game, {
        onGameStart = check,
        onGameEnd = onGameEnd,
        onResourcesBalanceChange = Prey.onResourcesBalanceChange,
        onPreyFreeRerolls = onPreyFreeRerolls,
        onPreyTimeLeft = onPreyTimeLeft,
        onPreyRerollPrice = onPreyRerollPrice,
        onPreyLocked = onPreyLocked,
        onPreyInactive = onPreyInactive,
        onPreyActive = onPreyActive,
        onPreySelection = onPreySelection,
        onPreySelectionChangeMonster = onPreySelectionChangeMonster,
        onPreyListSelection = onPreyListSelection,
        onPreyWildcardSelection = onPreyWildcardSelection
    })

    preyWindow = g_ui.displayUI('prey')
    preyWindow:hide()

    preyListSelection.window = g_ui.displayUI('prey_list_selection')
    if preyListSelection.window then
        preyListSelection.window:hide()
        preyListSelection.list = preyListSelection.window.listPanel
        preyListSelection.search = preyListSelection.window.search
        preyListSelection.confirmButton = preyListSelection.window.confirmButton
        preyListSelection.cancelButton = preyListSelection.window.cancelButton
        preyListSelection.counterLabel = preyListSelection.window.counter

        if preyListSelection.counterLabel then
            preyListSelection.counterLabel:setText('0 / 0')
        end

        if preyListSelection.list then
            preyListSelection.list.onChildFocusChange = function(list, child)
                if preyListSelection.ignoreFocusChange then
                    return
                end
                if child and child.raceId then
                    selectPreyListItem(child, true)
                end
            end
        end

        if preyListSelection.search then
            preyListSelection.search.onTextChange = function(widget, text)
                if preyListSelection.ignoreSearchEvents then
                    return
                end
                refreshPreyListSelection(text)
            end
        end

        if preyListSelection.confirmButton then
            preyListSelection.confirmButton.onClick = confirmPreyListSelection
            preyListSelection.confirmButton:disable()
        end

        if preyListSelection.cancelButton then
            preyListSelection.cancelButton.onClick = hidePreyListSelectionWindow
        end

        if preyListSelection.window.closeButton then
            preyListSelection.window.closeButton.onClick = hidePreyListSelectionWindow
        end

        preyListSelection.window.onVisibilityChange = function(widget, visible)
            if not visible then
                preyListSelection.selectedItem = nil
                preyListSelection.slot = nil
                if preyListSelection.confirmButton then
                    preyListSelection.confirmButton:disable()
                end
            end
        end
    end

    preyTracker = g_ui.createWidget('PreyTracker', modules.game_interface.getRightPanel())
    preyTracker:setup()
    preyTracker:setContentMaximumHeight(110)
    preyTracker:setContentMinimumHeight(70)
    preyTracker:hide()
    
    -- Hide buttons similar to unjustifiedpoints implementation
    local toggleFilterButton = preyTracker:recursiveGetChildById('toggleFilterButton')
    if toggleFilterButton then
        toggleFilterButton:setVisible(false)
    end
    
    local contextMenuButton = preyTracker:recursiveGetChildById('contextMenuButton')
    if contextMenuButton then
        contextMenuButton:setVisible(false)
    end
    
    local newWindowButton = preyTracker:recursiveGetChildById('newWindowButton')
    if newWindowButton then
        newWindowButton:setVisible(false)
    end
    
    -- Set up the miniwindow title and icon
    local titleWidget = preyTracker:getChildById('miniwindowTitle')
    if titleWidget then
        titleWidget:setText('Prey')
    else
        -- Fallback to old method if miniwindowTitle doesn't exist
        preyTracker:setText('Prey')
    end
    
    local iconWidget = preyTracker:getChildById('miniwindowIcon')
    if iconWidget then
        iconWidget:setImageSource('/images/game/prey/icon-prey-widget')
    end
    
    -- Position lockButton where toggleFilterButton was (to the left of minimize button)
    local lockButton = preyTracker:recursiveGetChildById('lockButton')
    local minimizeButton = preyTracker:recursiveGetChildById('minimizeButton')
    
    if lockButton and minimizeButton then
        lockButton:breakAnchors()
        lockButton:addAnchor(AnchorTop, minimizeButton:getId(), AnchorTop)
        lockButton:addAnchor(AnchorRight, minimizeButton:getId(), AnchorLeft)
        lockButton:setMarginRight(7)  -- Same margin as toggleFilterButton had
        lockButton:setMarginTop(0)
    end
    
    if g_game.isOnline() then
        check()
    end
    setUnsupportedSettings()
end

local descriptionTable = {
    ['shopPermButton'] =
    'Go to the Store to purchase the Permanent Prey Slot. Once you have completed the purchase, you can activate a prey here, no matter if your character is on a free or a Premium account.',
    ['shopTempButton'] = 'You can activate this prey whenever your account has Premium Status.',
    ['preyWindow'] = '',
    ['noBonusIcon'] =
    'This prey is not available for your character yet.\nCheck the large blue button(s) to learn how to unlock this prey slot',
    ['selectPrey'] =
    'Click here to get a bonus with a higher value. The bonus for your prey will be selected randomly from one of the following: damage boost, damage reduction, bonus XP, improved loot. Your prey will be active for 2 hours hunting time again. Your prey creature will stay the same.',
    ['pickSpecificPrey'] = 'Available only for protocols 12+',
    ['rerollButton'] =
    'If you like to select another prey crature, click here to get a new list with 9 creatures to choose from.\nThe newly selected prey will be active for 2 hours hunting time again.',
    ['preyCandidate'] = 'Select a new prey creature for the next 2 hours hunting time.',
    ['choosePreyButton'] =
    'Click on this button to confirm selected monsters as your prey creature for the next 2 hours hunting time.',
    ['automaticBonusReroll'] =
    'Do you want to enable the Automatic Bonus Reroll?\nEach time the Automatic Bonus Reroll is triggered, 1 of your Prey Wildcards will be consumed.',
    ['preyLock'] =
    'Do you want to enable the Lock Prey?\nEach time the Lock Prey is triggered, 5 of your Prey Wildcards will be consumed.'
}

function onHover(widget)
    if type(widget) == 'string' then
        return preyWindow.description:setText(descriptionTable[widget])
    elseif type(widget) == 'number' then
        local slot = 'slot' .. (widget + 1)
        local tracker = preyTracker.contentsPanel[slot]
        local desc = tracker.time:getTooltip()
        desc = desc:sub(1, desc:len() - 46)
        return preyWindow.description:setText(desc)
    end
    if widget:isVisible() then
        local id = widget:getId()
        local desc = descriptionTable[id]
        if desc then
            preyWindow.description:setText(desc)
        end
    end
end

function terminate()
    disconnect(g_game, {
        onGameStart = check,
        onGameEnd = onGameEnd,
        onResourcesBalanceChange = Prey.onResourcesBalanceChange,
        onPreyFreeRerolls = onPreyFreeRerolls,
        onPreyTimeLeft = onPreyTimeLeft,
        onPreyRerollPrice = onPreyRerollPrice,
        onPreyLocked = onPreyLocked,
        onPreyInactive = onPreyInactive,
        onPreyActive = onPreyActive,
        onPreySelection = onPreySelection,
        onPreySelectionChangeMonster = onPreySelectionChangeMonster,
        onPreyListSelection = onPreyListSelection,
        onPreyWildcardSelection = onPreyWildcardSelection
    })

    if preyButton then
        preyButton:destroy()
    end
    if preyTrackerButton then
        preyTrackerButton:destroy()
    end
    preyWindow:destroy()
    preyTracker:destroy()
    if preyListSelection.window then
        preyListSelection.window:destroy()
        preyListSelection.window = nil
        preyListSelection.list = nil
        preyListSelection.search = nil
        preyListSelection.confirmButton = nil
        preyListSelection.cancelButton = nil
        preyListSelection.counterLabel = nil
    end
    if msgWindow then
        msgWindow:destroy()
        msgWindow = nil
    end
end

local n = 0
function setUnsupportedSettings()
    local t = {'slot1', 'slot2', 'slot3'}
    for i, slot in pairs(t) do
        local panel = preyWindow[slot]
        for j, state in pairs({panel.active, panel.inactive}) do
            state.select.price.text:setText('-------')
        end
        panel.active.autoRerollPrice.text:setText('1')
        panel.active.lockPreyPrice.text:setText('5')
        panel.active.choose.price.text:setText(1)
    end
end

function check()
    if g_game.getFeature(GamePrey) then
        if not preyButton then
            preyButton = modules.game_mainpanel.addToggleButton('preyButton', tr('Prey Dialog'),
                                                                         '/images/options/button_preydialog', toggle)
        end
        if not preyTrackerButton then
            preyTrackerButton = modules.game_mainpanel.addToggleButton('preyTrackerButton', tr('Prey Tracker'),
                                                                                '/images/options/button_prey', toggleTracker)
        end
    elseif preyButton then
        preyButton:destroy()
        preyButton = nil
    end
end

function toggleTracker()
    if preyTracker:isVisible() then
        preyTracker:hide()
    else
        if not preyTracker:getParent() then
            local panel = modules.game_interface.findContentPanelAvailable(preyTracker, preyTracker:getMinimumHeight())
            if not panel then
                return
            end

            panel:addChild(preyTracker)
        end
        preyTracker:show()
    end
end

local function resetPreyWindowState()
    if not preyWindow then
        return
    end

    preyWindow.description:setText('')
    preyWindow.gold:setText('0')
    preyWindow.wildCards:setText('0')

    for slot = 0, 2 do
        onPreyInactive(slot, 0, 0)

        local prey = preyWindow['slot' .. (slot + 1)]
        if prey then
            if prey.title then
                prey.title:setText('')
            end

            if prey.inactive and prey.inactive.list then
                prey.inactive.list:destroyChildren()
            end

            if prey.active and prey.active.creatureAndBonus then
                local creatureAndBonus = prey.active.creatureAndBonus
                if creatureAndBonus.timeLeft then
                    creatureAndBonus.timeLeft:setPercent(0)
                    creatureAndBonus.timeLeft:setText('')
                end

                if creatureAndBonus.bonus and creatureAndBonus.bonus.grade then
                    creatureAndBonus.bonus.grade:destroyChildren()
                end
            end
        end
    end

    preyDescription = {}
    rerollPrice = 0
    bonusRerolls = 0
    bankGold = 0
    inventoryGold = 0
end

function onGameEnd()
    resetPreyWindowState()
    hide()
end

function hide()
    preyWindow:hide()
    hidePreyListSelectionWindow()
    if msgWindow then
        msgWindow:destroy()
        msgWindow = nil
    end
end

function show()
    if not g_game.getFeature(GamePrey) then
        return hide()
    end
    preyWindow:show()
    preyWindow:raise()
    preyWindow:focus()
    g_game.preyRequest() -- update preys, it's for tibia 12
end

function toggle()
    if preyWindow:isVisible() then
        return hide()
    end
    show()
end

function onMiniWindowOpen()
    -- Called when the MiniWindow is opened
end

function onMiniWindowClose()
    -- Called when the MiniWindow is closed
end

function onPreyFreeRerolls(slot, timeleft)
    local prey = preyWindow['slot' .. (slot + 1)]
    local percent = (timeleft / (20 * 60)) * 100
    local desc = timeleftTranslation(timeleft * 60)
    if not prey then
        return
    end
    for i, panel in pairs({prey.active, prey.inactive}) do
        local progressBar = panel.reroll.button.time
        local price = panel.reroll.price.text
        progressBar:setPercent(percent)
        progressBar:setText(desc)
        if timeleft == 0 then
            price:setText('0')
        end
    end
end

function onPreyTimeLeft(slot, timeLeft)
    -- description
    preyDescription[slot] = preyDescription[slot] or {
        one = '',
        two = ''
    }
    local text = preyDescription[slot].one .. timeleftTranslation(timeLeft, true) .. preyDescription[slot].two
    -- tracker
    local percent = (timeLeft / (2 * 60 * 60)) * 100
    slot = 'slot' .. (slot + 1)
    local tracker = preyTracker.contentsPanel[slot]
    tracker.time:setPercent(percent)
    tracker.time:setTooltip(text)
    for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
        element:setTooltip(text)
        element.onClick = function()
            show()
        end
    end
    -- main window
    local prey = preyWindow[slot]
    if not prey then
        return
    end
    local progressbar = prey.active.creatureAndBonus.timeLeft
    local desc = timeleftTranslation(timeLeft, true)
    progressbar:setPercent(percent)
    progressbar:setText(desc)
end

function onPreyRerollPrice(price)
    rerollPrice = price
    local t = {'slot1', 'slot2', 'slot3'}
    for i, slot in pairs(t) do
        local panel = preyWindow[slot]
        for j, state in pairs({panel.active, panel.inactive}) do
            local price = state.reroll.price.text
            local progressBar = state.reroll.button.time
            if progressBar:getText() ~= 'Free' then
                price:setText(comma_value(rerollPrice))
            else
                price:setText('0')
                progressBar:setPercent(0)
            end
        end
    end
end

function setTimeUntilFreeReroll(slot, timeUntilFreeReroll) -- minutes
    local prey = preyWindow['slot' .. (slot + 1)]
    if not prey then
        return
    end
    local percent = (timeUntilFreeReroll / (20 * 60)) * 100
    timeUntilFreeReroll = timeUntilFreeReroll > 720000 and 0 or timeUntilFreeReroll
    local desc = timeleftTranslation(timeUntilFreeReroll)
    for i, panel in pairs({ prey.active, prey.inactive }) do
        local reroll = panel.reroll.button.time
        reroll:setPercent(percent)
        reroll:setText(desc)
        local price = panel.reroll.price.text
        if timeUntilFreeReroll > 0 then
            price:setText(comma_value(rerollPrice))
        else
            price:setText('Free')
        end
    end
end

function onPreyLocked(slot, unlockState, timeUntilFreeReroll, wildcards)
    -- tracker
    slot = 'slot' .. (slot + 1)
    local tracker = preyTracker.contentsPanel[slot]
    if tracker then
        tracker:hide()
        preyTracker:setContentMaximumHeight(preyTracker:getHeight())
    end
    -- main window
    local prey = preyWindow[slot]
    if not prey then
        return
    end
    prey.title:setText('Locked')
    prey.inactive:hide()
    prey.active:hide()
    prey.locked:show()
end

function onPreyInactive(slot, timeUntilFreeReroll, wildcards)
    -- tracker
    local tracker = preyTracker.contentsPanel['slot' .. (slot + 1)]
    if tracker then
        tracker.creature:hide()
        tracker.noCreature:show()
        tracker.creatureName:setText('Inactive')
        tracker.time:setPercent(0)
        tracker.preyType:setImageSource('/images/game/prey/prey_no_bonus')
        for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
            element:setTooltip('Inactive Prey. \n\nClick in this window to open the prey dialog.')
            element.onClick = function()
                show()
            end
        end
    end
    -- main window
    setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
    local prey = preyWindow['slot' .. (slot + 1)]
    if not prey then
        return
    end
    prey.active:hide()
    prey.locked:hide()
    prey.inactive:show()
    assignPickSpecificPreyHandler(prey.inactive, slot)
    local rerollButton = prey.inactive.reroll.button.rerollButton
    rerollButton:setImageSource('/images/game/prey/prey_reroll_blocked')
    rerollButton:disable()
    rerollButton.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
    end
end

function setBonusGradeStars(slot, grade)
    local prey = preyWindow['slot' .. (slot + 1)]
    local gradePanel = prey.active.creatureAndBonus.bonus.grade

    gradePanel:destroyChildren()
    for i = 1, 10 do
        if i <= grade then
            local widget = g_ui.createWidget('Star', gradePanel)
            widget.onHoverChange = function(widget, hovered)
                onHover(slot)
            end
        else
            local widget = g_ui.createWidget('NoStar', gradePanel)
            widget.onHoverChange = function(widget, hovered)
                onHover(slot)
            end
        end
    end
end

function getBigIconPath(bonusType)
    local path = '/images/game/prey/'
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return path .. 'prey_bigdamage'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return path .. 'prey_bigdefense'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return path .. 'prey_bigxp'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return path .. 'prey_bigloot'
    end
end

function getSmallIconPath(bonusType)
    local path = '/images/game/prey/'
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return path .. 'prey_damage'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return path .. 'prey_defense'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return path .. 'prey_xp'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return path .. 'prey_loot'
    end
end

function getBonusDescription(bonusType)
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return 'Damage Boost'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return 'Damage Reduction'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return 'XP Bonus'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return 'Improved Loot'
    end
end

function getTooltipBonusDescription(bonusType, bonusValue)
    if bonusType == PREY_BONUS_DAMAGE_BOOST then
        return 'You deal +' .. bonusValue .. '% extra damage against your prey creature.'
    elseif bonusType == PREY_BONUS_DAMAGE_REDUCTION then
        return 'You take ' .. bonusValue .. '% less damage from your prey creature.'
    elseif bonusType == PREY_BONUS_XP_BONUS then
        return 'Killing your prey creature rewards +' .. bonusValue .. '% extra XP.'
    elseif bonusType == PREY_BONUS_IMPROVED_LOOT then
        return 'Your creature has a +' .. bonusValue .. '% chance to drop additional loot.'
    end
end

function capitalFormatStr(str)
    local formatted = ''
    str = string.split(str, ' ')
    for i, word in ipairs(str) do
        formatted = formatted .. ' ' .. (string.gsub(word, '^%l', string.upper))
    end
    return formatted:trim()
end

function onItemBoxChecked(widget)

    for i, slot in pairs({'slot1', 'slot2', 'slot3'}) do
        local list = preyWindow[slot].inactive.list:getChildren()
        if table.find(list, widget) then
            for i, child in pairs(list) do
                if child ~= widget then
                    child:setChecked(false)
                end
            end
        end
    end
    widget:setChecked(true)
end

local suppressOptionCheckHandler = false

local function setOptionCheckedSilently(checkbox, checked)
    if checkbox:isChecked() == checked then
        return
    end
    suppressOptionCheckHandler = true
    checkbox:setChecked(checked)
    suppressOptionCheckHandler = false
end

local function getToggleCheckboxes(slot)
    local prey = preyWindow and preyWindow['slot' .. (slot + 1)]
    if not prey or not prey.active then
        return nil, nil
    end

    local autoCheckbox = prey.active.autoReroll and prey.active.autoReroll.autoRerollCheck
    local lockCheckbox = prey.active.lockPrey and prey.active.lockPrey.lockPreyCheck

    return autoCheckbox, lockCheckbox
end

local function sendOption(slot, option)
    g_game.preyAction(slot, PREY_ACTION_OPTION, option)
end

local function handleToggleOptions(checkbox, slot, currentOption, checked)
    if suppressOptionCheckHandler then
        return
    end

    local autoCheckbox, lockCheckbox = getToggleCheckboxes(slot)
    local otherCheckbox = currentOption == PREY_OPTION_TOGGLE_AUTOREROLL and lockCheckbox or autoCheckbox

    if checked then
        local confirmWindow
        local wasPreyWindowVisible = preyWindow and preyWindow:isVisible()
        local preyVisibilityRestored = false

        local function restorePreyWindowVisibility()
            if not preyVisibilityRestored and wasPreyWindowVisible and preyWindow then
                preyVisibilityRestored = true
                preyWindow:show()
                preyWindow:raise()
                preyWindow:focus()
            end
        end

        if wasPreyWindowVisible then
            preyWindow:hide()
        end

        local function closeWindow()
            if confirmWindow then
                confirmWindow:destroy()
                confirmWindow = nil
                restorePreyWindowVisibility()
            end
        end

        local function confirm()
            if otherCheckbox and otherCheckbox:isChecked() then
                setOptionCheckedSilently(otherCheckbox, false)
                sendOption(PREY_OPTION_UNTOGGLE)
            end

            setOptionCheckedSilently(checkbox, true)
            sendOption(currentOption)
            closeWindow()
        end

        local function cancel()
            setOptionCheckedSilently(checkbox, false)
            closeWindow()
        end

        local description = currentOption == PREY_OPTION_TOGGLE_AUTOREROLL and
            tr(descriptionTable['automaticBonusReroll']) or tr(descriptionTable['preyLock'])

        confirmWindow = displayGeneralBox(tr('Confirmation of Using Prey Wildcards'), description, {
            {
                text = tr('No'),
                callback = cancel
            },
            {
                text = tr('Yes'),
                callback = confirm
            },
        }, confirm, cancel)

        if confirmWindow then
            confirmWindow.onDestroy = restorePreyWindowVisibility
        end

        return
    end

    sendOption(PREY_OPTION_UNTOGGLE)
end

function onPreyActive(slot, currentHolderName, currentHolderOutfit, bonusType, bonusValue, bonusGrade, timeLeft,
                      timeUntilFreeReroll, wildcards) -- locktype always 0 for protocols <12
    local tracker = preyTracker.contentsPanel['slot' .. (slot + 1)]
    currentHolderName = capitalFormatStr(currentHolderName)
    local percent = (timeLeft / (2 * 60 * 60)) * 100
    if tracker then
        tracker.creature:show()
        tracker.noCreature:hide()
        tracker.creatureName:setText(currentHolderName)
        tracker.creature:setOutfit(currentHolderOutfit)
        tracker.preyType:setImageSource(getSmallIconPath(bonusType))
        tracker.time:setPercent(percent)
        preyDescription[slot] = preyDescription[slot] or {}
        preyDescription[slot].one = 'Creature: ' .. currentHolderName .. '\nDuration: '
        preyDescription[slot].two =
            '\nValue: ' .. bonusGrade .. '/10' .. '\nType: ' .. getBonusDescription(bonusType) .. '\n' ..
                getTooltipBonusDescription(bonusType, bonusValue) .. '\n\nClick in this window to open the prey dialog.'
        for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
            element:setTooltip(preyDescription[slot].one .. timeleftTranslation(timeLeft, true) ..
                                   preyDescription[slot].two)
            element.onClick = function()
                show()
            end
        end
    end
    local prey = preyWindow['slot' .. (slot + 1)]
    if not prey then
        return
    end
    prey.inactive:hide()
    prey.locked:hide()
    prey.active:show()
    assignPickSpecificPreyHandler(prey.active, slot)
    prey.title:setText(currentHolderName)
    local creatureAndBonus = prey.active.creatureAndBonus
    creatureAndBonus.creature:setOutfit(currentHolderOutfit)
    setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
    creatureAndBonus.bonus.icon:setImageSource(getBigIconPath(bonusType))
    creatureAndBonus.bonus.icon.onHoverChange = function(widget, hovered)
        onHover(slot)
    end
    setBonusGradeStars(slot, bonusGrade)
    creatureAndBonus.timeLeft:setPercent(percent)
    creatureAndBonus.timeLeft:setText(timeleftTranslation(timeLeft))
    -- bonus reroll
    prey.active.choose.selectPrey.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_BONUSREROLL, 0)
    end
    -- creature reroll
    prey.active.reroll.button.rerollButton.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
    end

    setOptionCheckedSilently(prey.active.autoReroll.autoRerollCheck, option == PREY_ACTION_BONUSREROLL)
    prey.active.autoReroll.autoRerollCheck.onCheckChange = function(widget, checked)
        handleToggleOptions(widget, slot, PREY_OPTION_TOGGLE_AUTOREROLL, checked)
    end

    setOptionCheckedSilently(prey.active.lockPrey.lockPreyCheck, option == PREY_OPTION_TOGGLE_LOCK_PREY)
    prey.active.lockPrey.lockPreyCheck.onCheckChange = function(widget, checked)
        handleToggleOptions(widget, slot, PREY_OPTION_TOGGLE_LOCK_PREY, checked)
    end
end

function onPreySelection(slot, names, outfits, timeUntilFreeReroll, wildcards)
    -- tracker
    local tracker = preyTracker.contentsPanel['slot' .. (slot + 1)]
    if tracker then
        tracker.creature:hide()
        tracker.noCreature:show()
        tracker.creatureName:setText('Inactive')
        tracker.time:setPercent(0)
        tracker.preyType:setImageSource('/images/game/prey/prey_no_bonus')
        for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
            element:setTooltip('Inactive Prey. \n\nClick in this window to open the prey dialog.')
            element.onClick = function()
                show()
            end
        end
    end
    -- main window
    local prey = preyWindow['slot' .. (slot + 1)]
    setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
    if not prey then
        return
    end
    prey.active:hide()
    prey.locked:hide()
    prey.inactive:show()
    assignPickSpecificPreyHandler(prey.inactive, slot)
    prey.title:setText(tr('Select monster'))
    local rerollButton = prey.inactive.reroll.button.rerollButton
    rerollButton.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
    end
    local list = prey.inactive.list
    list:destroyChildren()
    for i, name in ipairs(names) do
        local box = g_ui.createWidget('PreyCreatureBox', list)
        name = capitalFormatStr(name)
        box:setTooltip(name)
        box.creature:setOutfit(outfits[i])
    end
    prey.inactive.choose.choosePreyButton.onClick = function()
        for i, child in pairs(list:getChildren()) do
            if child:isChecked() then
                return g_game.preyAction(slot, PREY_ACTION_MONSTERSELECTION, i - 1)
            end
        end
        return showMessage(tr('Error'), tr('Select monster to proceed.'))
    end
end

function onPreySelectionChangeMonster(slot, names, outfits, bonusType, bonusValue, bonusGrade, timeUntilFreeReroll,
                                      wildcards)
    -- tracker
    local tracker = preyTracker.contentsPanel['slot' .. (slot + 1)]
    if tracker then
        tracker.creature:hide()
        tracker.noCreature:show()
        tracker.creatureName:setText('Inactive')
        tracker.time:setPercent(0)
        tracker.preyType:setImageSource('/images/game/prey/prey_no_bonus')
        for i, element in pairs({tracker.creatureName, tracker.creature, tracker.preyType, tracker.time}) do
            element:setTooltip('Inactive Prey. \n\nClick in this window to open the prey dialog.')
            element.onClick = function()
                show()
            end
        end
    end
    -- main window
    local prey = preyWindow['slot' .. (slot + 1)]
    setTimeUntilFreeReroll(slot, timeUntilFreeReroll)
    if not prey then
        return
    end
    prey.active:hide()
    prey.locked:hide()
    prey.inactive:show()
    assignPickSpecificPreyHandler(prey.inactive, slot)
    prey.title:setText(tr('Select monster'))
    local rerollButton = prey.inactive.reroll.button.rerollButton
    rerollButton.onClick = function()
        g_game.preyAction(slot, PREY_ACTION_LISTREROLL, 0)
    end
    local list = prey.inactive.list
    list:destroyChildren()
    for i, name in ipairs(names) do
        local box = g_ui.createWidget('PreyCreatureBox', list)
        name = capitalFormatStr(name)
        box:setTooltip(name)
        box.creature:setOutfit(outfits[i])
    end
    prey.inactive.choose.choosePreyButton.onClick = function()
        for i, child in pairs(list:getChildren()) do
            if child:isChecked() then
                return g_game.preyAction(slot, PREY_ACTION_MONSTERSELECTION, i - 1)
            end
        end
        return showMessage(tr('Error'), tr('Select monster to proceed.'))
    end
end

function onPreyListSelection(slot, races, nextFreeReroll, wildcards)
    if not preyListSelection.window then
        return
    end

    preyListSelection.slot = slot
    races = races or {}
    preyListSelection.entries = {}

    for _, raceId in ipairs(races) do
        local raceData = g_things.getRaceData(raceId)
        local name = raceData and raceData.name or ''

        if not name or name == '' then
            name = string.format('%s %d', tr('Unknown'), raceId)
        end

        local formattedName = capitalFormatStr(name)
        table.insert(preyListSelection.entries, {
            raceId = raceId,
            displayName = formattedName,
            searchName = formattedName:lower()
        })
    end

    table.sort(preyListSelection.entries, function(a, b)
        return a.searchName < b.searchName
    end)

    if preyListSelection.search then
        preyListSelection.ignoreSearchEvents = true
        preyListSelection.search:setText('')
        preyListSelection.ignoreSearchEvents = false
    end

    refreshPreyListSelection('')
    preyListSelection.window:show()
    preyListSelection.window:raise()
    preyListSelection.window:focus()
end

function hidePreyListSelection()
    hidePreyListSelectionWindow()
end

function onPreyWildcardSelection(slot, races, nextFreeReroll, wildcards)
end

function Prey.onResourcesBalanceChange(balance, oldBalance, type)
    if type == ResourceTypes.BANK_BALANCE then -- bank gold
        bankGold = balance
    elseif type == ResourceTypes.GOLD_EQUIPPED then -- inventory gold
        inventoryGold = balance
    elseif type == ResourceTypes.PREY_WILDCARDS then -- bonus rerolls
        bonusRerolls = balance
    end
    local player = g_game.getLocalPlayer()
    g_logger.debug('' .. tostring(type) .. ', ' .. tostring(balance))
    if player then
        preyWindow.wildCards:setText(tostring(player:getResourceBalance(ResourceTypes.PREY_WILDCARDS)))
        preyWindow.gold:setText(comma_value(player:getTotalMoney()))
    end
end

function showMessage(title, message)
    if msgWindow then
        msgWindow:destroy()
    end

    msgWindow = displayInfoBox(title, message)
    msgWindow:show()
    msgWindow:raise()
    msgWindow:focus()
end
