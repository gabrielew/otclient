local helpers = require('modules.game_forge.game_forge_helpers')

local resolveScrollContents = helpers.resolveScrollContents
local resolveForgePrice = helpers.resolveForgePrice
local formatGoldAmount = helpers.formatGoldAmount

local FusionTab = {}

local controllerState = setmetatable({}, { __mode = 'k' })

local DEFAULT_SUCCESS_RATE = '50%'
local DEFAULT_TIER_LOSS = '100%'
local DEFAULT_SUCCESS_SELECTED = '65%'
local DEFAULT_TIER_SELECTED = '50%'

local function updateControllerText(controller, propertyName, value)
    if not controller or not propertyName then
        return
    end

    if value == nil then
        value = ''
    elseif type(value) ~= 'string' then
        value = tostring(value)
    end

    if controller[propertyName] ~= value then
        controller[propertyName] = value
    end
end

local function ensureSelections(controller)
    if type(controller.fusionCoreSelections) ~= 'table' then
        controller.fusionCoreSelections = {
            success = false,
            tier = false
        }
    end
    return controller.fusionCoreSelections
end

local function getState(controller)
    local state = controllerState[controller]
    if not state then
        state = {}
        controllerState[controller] = state
    end
    ensureSelections(controller)
    return state
end

function FusionTab.registerDependencies(controller, dependencies)
    local state = getState(controller)
    dependencies = dependencies or {}
    state.resourceTypes = dependencies.resourceTypes or state.resourceTypes

    controller.fusionSelectedItemCounterText = controller.fusionSelectedItemCounterText or '0 / 1'
    controller.fusionPriceDisplay = controller.fusionPriceDisplay or '???'
    controller.fusionSuccessRateValue = controller.fusionSuccessRateValue or DEFAULT_SUCCESS_RATE
    controller.fusionTierLossValue = controller.fusionTierLossValue or DEFAULT_TIER_LOSS
    controller.fusionDustRequirementText = controller.fusionDustRequirementText
        or tostring((controller.openData and tonumber(controller.openData.convergenceDustFusion))
        or tonumber(controller.convergenceDustFusion) or 0)

    state.successRateBaseText = controller.fusionSuccessRateValue or state.successRateBaseText or DEFAULT_SUCCESS_RATE
    state.tierLossBaseText = controller.fusionTierLossValue or state.tierLossBaseText or DEFAULT_TIER_LOSS
    state.successRateSelectedText = state.successRateSelectedText or DEFAULT_SUCCESS_SELECTED
    state.tierLossSelectedText = state.tierLossSelectedText or DEFAULT_TIER_SELECTED
end

function FusionTab.resetCoreSelections(controller)
    local selections = ensureSelections(controller)
    selections.success = false
    selections.tier = false
end

function FusionTab.invalidateContext(controller)
    local state = getState(controller)
    state.context = nil

    if state.selectionGroup then
        state.selectionGroup:destroy()
        state.selectionGroup = nil
    end

    if state.convergenceGroup then
        state.convergenceGroup:destroy()
        state.convergenceGroup = nil
    end
end

local function resolveContext(controller)
    local state = getState(controller)
    local panel = controller:loadTab('fusion')
    if not panel then
        return nil
    end

    local context = state.context
    if not context or context.panel ~= panel or panel:isDestroyed() then
        local resultArea = panel.test
        local selectionPanel = panel.fusionSelectionArea
        local convergenceSection = panel.fusionConvergenceSection
            or (resultArea and resultArea.fusionConvergenceSection)

        context = {
            panel = panel,
            resultArea = resultArea,
            selectionPanel = selectionPanel,
            targetItem = panel.fusionTargetItemPreview,
            selectedItemIcon = panel.fusionSelectedItemIcon,
            selectedItemQuestion = panel.fusionSelectedItemQuestion,
            selectedItemCounter = panel.fusionSelectedItemCounter,
            placeholder = (resultArea and resultArea.fusionResultPlaceholder)
                or panel.fusionResultPlaceholder,
            convergenceSection = convergenceSection,
            fusionButton = panel.fusionActionButton
                or (resultArea and resultArea.fusionActionButton),
            fusionButtonItem = panel.fusionResultItemFrom,
            fusionButtonItemTo = panel.fusionResultItemTo,
            convergenceItemsPanel = nil,
            dustAmountLabel = panel.fusionConvergenceDustLabel
                or (convergenceSection and convergenceSection.fusionConvergenceDustLabel),
            costLabel = panel.fusionResultCostLabel
                or (resultArea and resultArea.fusionResultCostLabel),
            successCoreButton = panel.fusionImproveButton
                or (resultArea and resultArea.fusionImproveButton),
            tierCoreButton = panel.fusionReduceButton
                or (resultArea and resultArea.fusionReduceButton)
        }
        state.context = context
    end

    if not context.selectionPanel or context.selectionPanel:isDestroyed() then
        context.selectionPanel = panel.fusionSelectionArea
        context.selectionItemsPanel = nil
    end

    if context.resultArea and context.resultArea:isDestroyed() then
        context.resultArea = nil
    end

    if not context.resultArea then
        context.resultArea = panel.test
    end

    if context.selectionPanel and (not context.selectionItemsPanel or context.selectionItemsPanel:isDestroyed()) then
        local selectionGrid = (context.selectionPanel and context.selectionPanel.fusionSelectionGrid)
            or panel.fusionSelectionGrid
        if selectionGrid then
            context.selectionItemsPanel = resolveScrollContents(selectionGrid)
        end
    end

    if context.targetItem and context.targetItem:isDestroyed() then
        context.targetItem = nil
    end

    if not context.targetItem then
        context.targetItem = panel.fusionTargetItemPreview
    end

    if (not context.selectedItemIcon or context.selectedItemIcon:isDestroyed()) then
        context.selectedItemIcon = panel.fusionSelectedItemIcon
    end

    if context.selectedItemIcon then
        context.selectedItemIcon:setShowCount(true)
    end

    if context.placeholder and context.placeholder:isDestroyed() then
        context.placeholder = nil
    end

    if not context.placeholder then
        context.placeholder = (context.resultArea and context.resultArea.fusionResultPlaceholder)
            or panel.fusionResultPlaceholder
    end

    if not context.selectedItemQuestion or context.selectedItemQuestion:isDestroyed() then
        context.selectedItemQuestion = panel.fusionSelectedItemQuestion
    end

    if not context.selectedItemCounter or context.selectedItemCounter:isDestroyed() then
        context.selectedItemCounter = panel.fusionSelectedItemCounter
    end

    if context.fusionButton and context.fusionButton:isDestroyed() then
        context.fusionButton = nil
    end

    if not context.fusionButton then
        context.fusionButton = panel.fusionActionButton
            or (context.resultArea and context.resultArea.fusionActionButton)
    end

    if context.fusionButtonItem and context.fusionButtonItem:isDestroyed() then
        context.fusionButtonItem = nil
    end

    if not context.fusionButtonItem then
        context.fusionButtonItem = panel.fusionResultItemFrom
            or (context.fusionButton and context.fusionButton.fusionResultItemFrom)
    end

    if context.fusionButtonItemTo and context.fusionButtonItemTo:isDestroyed() then
        context.fusionButtonItemTo = nil
    end

    if not context.fusionButtonItemTo then
        context.fusionButtonItemTo = panel.fusionResultItemTo
            or (context.fusionButton and context.fusionButton.fusionResultItemTo)
    end

    if context.costLabel and context.costLabel:isDestroyed() then
        context.costLabel = nil
    end

    if not context.costLabel then
        context.costLabel = panel.fusionResultCostLabel
            or (context.resultArea and context.resultArea.fusionResultCostLabel)
    end

    if context.successCoreButton and context.successCoreButton:isDestroyed() then
        context.successCoreButton = nil
    end

    if not context.successCoreButton then
        context.successCoreButton = panel.fusionImproveButton
            or (context.resultArea and context.resultArea.fusionImproveButton)
    end

    if context.tierCoreButton and context.tierCoreButton:isDestroyed() then
        context.tierCoreButton = nil
    end

    if not context.tierCoreButton then
        context.tierCoreButton = panel.fusionReduceButton
            or (context.resultArea and context.resultArea.fusionReduceButton)
    end

    if context.convergenceSection and context.convergenceSection:isDestroyed() then
        context.convergenceSection = nil
    end

    if not context.convergenceSection then
        context.convergenceSection = panel.fusionConvergenceSection
            or (context.resultArea and context.resultArea.fusionConvergenceSection)
    end

    if context.convergenceItemsPanel and context.convergenceItemsPanel:isDestroyed() then
        context.convergenceItemsPanel = nil
    end

    if context.convergenceSection and not context.convergenceItemsPanel then
        local convergenceGrid = context.convergenceSection.fusionConvergenceGrid
            or panel.fusionConvergenceGrid
            or (context.resultArea and context.resultArea.fusionConvergenceGrid)
        if convergenceGrid then
            context.convergenceItemsPanel = resolveScrollContents(convergenceGrid)
        end
    end

    if context.dustAmountLabel and context.dustAmountLabel:isDestroyed() then
        context.dustAmountLabel = nil
    end

    if not context.dustAmountLabel then
        context.dustAmountLabel = panel.fusionConvergenceDustLabel
            or (context.convergenceSection and context.convergenceSection.fusionConvergenceDustLabel)
    end

    updateControllerText(controller, 'fusionSelectedItemCounterText',
        controller.fusionSelectedItemCounterText or '0 / 1')
    updateControllerText(controller, 'fusionPriceDisplay', controller.fusionPriceDisplay or '???')
    updateControllerText(controller, 'fusionSuccessRateValue', controller.fusionSuccessRateValue or DEFAULT_SUCCESS_RATE)
    updateControllerText(controller, 'fusionTierLossValue', controller.fusionTierLossValue or DEFAULT_TIER_LOSS)

    local defaultDustRequirement = (controller.openData and tonumber(controller.openData.convergenceDustFusion))
        or tonumber(controller.convergenceDustFusion) or 0
    updateControllerText(controller, 'fusionDustRequirementText', defaultDustRequirement)

    return context
end

local function onFusionSelectionChange(controller, state, selectedWidget)
    if not selectedWidget or selectedWidget:isDestroyed() then
        controller:resetFusionConversionPanel()
        return
    end

    controller:configureFusionConversionPanel(selectedWidget)
end

local function onFusionConvergenceSelectionChange(controller, _, selectedWidget)
    if not selectedWidget or selectedWidget:isDestroyed() then
        controller.fusionSelectedItem = nil
        return
    end

    controller.fusionSelectedItem = selectedWidget.fusionItemInfo
end

function FusionTab.updateFusionCoreButtons(controller)
    if not controller.ui then
        return
    end

    local context = resolveContext(controller)
    if not context then
        return
    end

    local state = getState(controller)

    local successButton = context.successCoreButton
    if not successButton or successButton:isDestroyed() then
        successButton = context.panel and context.panel.fusionImproveButton
        context.successCoreButton = successButton
    end

    local tierButton = context.tierCoreButton
    if not tierButton or tierButton:isDestroyed() then
        tierButton = context.panel and context.panel.fusionReduceButton
        context.tierCoreButton = tierButton
    end

    local selections = ensureSelections(controller)

    local player = g_game.getLocalPlayer()
    local resourceTypes = state.resourceTypes or {}
    local coreType = resourceTypes.cores
    local coreBalance = 0
    if player and coreType then
        coreBalance = player:getResourceBalance(coreType) or 0
    end

    local function setButtonState(button, selected, enabled)
        if not button or button:isDestroyed() then
            return
        end

        if button.setOn then
            button:setOn(selected)
        end

        if button.setEnabled then
            button:setEnabled(enabled or selected)
        end
    end

    local selectedSuccess = selections.success and true or false
    local selectedTier = selections.tier and true or false

    if coreBalance <= 0 then
        if selectedSuccess then
            selections.success = false
            selectedSuccess = false
        end
        if selectedTier then
            selections.tier = false
            selectedTier = false
        end
    end

    local selectedCount = (selectedSuccess and 1 or 0) + (selectedTier and 1 or 0)
    if coreBalance > 0 and selectedCount > coreBalance then
        if selectedTier then
            selectedTier = false
            selections.tier = false
            selectedCount = selectedCount - 1
        end
        if selectedCount > coreBalance and selectedSuccess then
            selectedSuccess = false
            selections.success = false
            selectedCount = selectedCount - 1
        end
    end

    local hasAvailableCore = coreBalance > selectedCount

    local successEnabled = coreBalance > 0 and (selectedSuccess or hasAvailableCore)
    local tierEnabled = coreBalance > 0 and (selectedTier or hasAvailableCore)

    if coreBalance == 1 then
        if selectedSuccess and not selectedTier then
            tierEnabled = false
        elseif selectedTier and not selectedSuccess then
            successEnabled = false
        end
    end

    setButtonState(successButton, selectedSuccess, successEnabled)
    setButtonState(tierButton, selectedTier, tierEnabled)

    local successSelectedText = state.successRateSelectedText or DEFAULT_SUCCESS_SELECTED
    local tierSelectedText = state.tierLossSelectedText or DEFAULT_TIER_SELECTED

    local function resolveDisplay(currentValue, selectedText, defaultText, isSelected, storedBase)
        local base = storedBase
        if currentValue and currentValue ~= '' and currentValue ~= selectedText then
            base = currentValue
        end
        if not base or base == '' then
            base = defaultText
        end
        if isSelected then
            return selectedText, base
        end
        return base, base
    end

    local successDisplay, successBase = resolveDisplay(controller.fusionSuccessRateValue,
        successSelectedText, DEFAULT_SUCCESS_RATE, selectedSuccess, state.successRateBaseText)
    local tierDisplay, tierBase = resolveDisplay(controller.fusionTierLossValue, tierSelectedText,
        DEFAULT_TIER_LOSS, selectedTier, state.tierLossBaseText)

    state.successRateBaseText = successBase
    state.tierLossBaseText = tierBase
    state.lastSuccessSelection = selectedSuccess
    state.lastTierSelection = selectedTier

    updateControllerText(controller, 'fusionSuccessRateValue', successDisplay)
    updateControllerText(controller, 'fusionTierLossValue', tierDisplay)
end

function FusionTab.onToggleFusionCore(controller, coreType)
    if not controller.ui then
        return
    end

    if coreType ~= 'success' and coreType ~= 'tier' then
        return
    end

    local context = resolveContext(controller)
    if not context then
        return
    end

    local button
    if coreType == 'success' then
        button = context.successCoreButton
        if not button or button:isDestroyed() then
            context.successCoreButton = context.panel and context.panel.fusionImproveButton or nil
            button = context.successCoreButton
        end
    else
        button = context.tierCoreButton
        if not button or button:isDestroyed() then
            context.tierCoreButton = context.panel and context.panel.fusionReduceButton or nil
            button = context.tierCoreButton
        end
    end

    if not button or button:isDestroyed() then
        return
    end

    local selections = ensureSelections(controller)
    local isSelected = selections[coreType] and true or false

    local player = g_game.getLocalPlayer()
    local resourceTypes = getState(controller).resourceTypes or {}
    local coreTypeId = resourceTypes.cores
    local coreBalance = 0
    if player and coreTypeId then
        coreBalance = player:getResourceBalance(coreTypeId) or 0
    end

    if isSelected then
        selections[coreType] = false
        FusionTab.updateFusionCoreButtons(controller)
        return
    end

    local otherType = coreType == 'success' and 'tier' or 'success'
    local otherSelected = selections[otherType] and 1 or 0
    if coreBalance <= otherSelected then
        return
    end

    selections[coreType] = true
    FusionTab.updateFusionCoreButtons(controller)
end

function FusionTab.configureConversionPanel(controller, selectedWidget)
    if not selectedWidget or not selectedWidget.itemPtr then
        return
    end

    local state = getState(controller)
    local context = resolveContext(controller)
    if not context then
        return
    end

    if context.convergenceSection and (not context.convergenceItemsPanel or context.convergenceItemsPanel:isDestroyed()) then
        local convergenceGrid = context.convergenceSection.fusionConvergenceGrid
            or (context.resultArea and context.resultArea.fusionConvergenceGrid)
            or (context.panel and context.panel.fusionConvergenceGrid)
        if convergenceGrid then
            context.convergenceItemsPanel = resolveScrollContents(convergenceGrid)
        end
    end

    local itemPtr = selectedWidget.itemPtr
    local itemWidget = selectedWidget.item
    local itemCount = 1
    if itemWidget and itemWidget.getItemCount then
        itemCount = tonumber(itemWidget:getItemCount()) or itemCount
    elseif itemPtr and itemPtr.getCount then
        itemCount = tonumber(itemPtr:getCount()) or itemCount
    elseif itemPtr and itemPtr.getCountOrSubType then
        itemCount = tonumber(itemPtr:getCountOrSubType()) or itemCount
    end
    local itemTier = itemPtr:getTier() or 0

    controller.fusionItem = itemPtr
    controller.fusionItemCount = itemCount

    if context.selectedItemIcon then
        local selectedPreview = Item.create(itemPtr:getId(), itemCount)
        selectedPreview:setTier(itemTier)
        context.selectedItemIcon:setItem(selectedPreview)
        context.selectedItemIcon:setItemCount(itemCount)
        g_logger.info(">> selectedItemIcon id: " ..
            itemPtr:getId() .. " tier: " .. itemTier .. " target tier: " .. itemTier + 1)
        ItemsDatabase.setTier(context.selectedItemIcon, selectedPreview)
    end

    if context.targetItem then
        local targetDisplay = Item.create(itemPtr:getId(), itemCount)
        targetDisplay:setTier(itemTier)
        context.targetItem:setItem(targetDisplay)
        context.targetItem:setItemCount(itemCount)
        ItemsDatabase.setTier(context.targetItem, targetDisplay)
    end

    if context.selectedItemQuestion then
        context.selectedItemQuestion:setVisible(false)
    end

    local ownedCount = math.max(itemCount, 0)
    updateControllerText(controller, 'fusionSelectedItemCounterText', string.format('%d / 1', ownedCount))

    if context.fusionButtonItem then
        context.fusionButtonItem:setItemId(itemPtr:getId())
        context.fusionButtonItem:setItemCount(1)
        ItemsDatabase.setTier(context.fusionButtonItem, math.max(itemTier - 1, 0))
    end

    if context.fusionButtonItemTo then
        context.fusionButtonItemTo:setItemId(itemPtr:getId())
        context.fusionButtonItemTo:setItemCount(1)
        ItemsDatabase.setTier(context.fusionButtonItemTo, itemTier + 1)

        g_logger.info(">> fusionButtonItemTo id: " ..
            itemPtr:getId() .. " tier: " .. itemTier .. " target tier: " .. itemTier + 1)
    end

    if context.convergenceItemsPanel then
        context.convergenceItemsPanel:destroyChildren()
    end

    if state.convergenceGroup then
        state.convergenceGroup:destroy()
        state.convergenceGroup = nil
    end

    local convergenceGroup = UIRadioGroup.create()
    convergenceGroup.onSelectionChange = function(group, widget)
        onFusionConvergenceSelectionChange(controller, group, widget)
    end
    state.convergenceGroup = convergenceGroup

    controller.fusionSelectedItem = nil

    local player = g_game.getLocalPlayer()
    local resourceTypes = state.resourceTypes or {}
    local dustType = resourceTypes.dust
    local dustRequirement = (controller.openData and tonumber(controller.openData.convergenceDustFusion))
        or tonumber(controller.convergenceDustFusion) or 0
    local priceList = controller.fusionPrices or (controller.openData and controller.openData.fusionPrices) or {}
    local price = resolveForgePrice(priceList, itemPtr, itemTier)

    if context.dustAmountLabel and player and dustType then
        local dustBalance = player:getResourceBalance(dustType) or 0
        local hasEnoughDust = dustRequirement <= 0 or dustBalance >= dustRequirement
        context.dustAmountLabel:setColor(hasEnoughDust and '$var-text-cip-color' or '#d33c3c')
    end

    updateControllerText(controller, 'fusionDustRequirementText', dustRequirement)
    controller.fusionPrice = price

    if context.costLabel then
        updateControllerText(controller, 'fusionPriceDisplay', formatGoldAmount(price))
        if player then
            local totalMoney = player:getTotalMoney() or 0
            context.costLabel:setColor(totalMoney >= price and '$var-text-cip-color' or '#d33c3c')
        end
    end

    local hasConvergenceOptions = false
    local convergenceData = controller.convergenceFusion or {}
    if context.convergenceItemsPanel then
        for _, option in ipairs(convergenceData) do
            if type(option) == 'table' then
                for _, fusionInfo in ipairs(option) do
                    if type(fusionInfo) == 'table' and fusionInfo.id then
                        local widget = g_ui.createWidget('UICheckBox', context.convergenceItemsPanel)
                        if widget then
                            widget:setFocusable(true)
                            widget:setHeight(36)
                            widget:setWidth(36)
                            widget:setMargin(2)

                            local itemDisplay = g_ui.createWidget('UIItem', widget)
                            if itemDisplay then
                                itemDisplay:fill('parent')
                                itemDisplay:setItemId(fusionInfo.id)
                                if fusionInfo.count and fusionInfo.count > 0 then
                                    itemDisplay:setItemCount(fusionInfo.count)
                                end
                                ItemsDatabase.setTier(itemDisplay, fusionInfo.tier or 0)
                                widget.item = itemDisplay
                            end

                            widget.fusionItemInfo = fusionInfo
                            convergenceGroup:addWidget(widget)
                            hasConvergenceOptions = true
                        end
                    end
                end
            end
        end
    end

    if context.convergenceSection then
        context.convergenceSection:setVisible(controller.modeFusion and hasConvergenceOptions)
    end

    local firstWidget = convergenceGroup:getFirstWidget()
    if firstWidget then
        convergenceGroup:selectWidget(firstWidget, true)
        onFusionConvergenceSelectionChange(controller, convergenceGroup, firstWidget)
    end

    FusionTab.updateFusionCoreButtons(controller)
end

function FusionTab.resetConversionPanel(controller)
    local state = getState(controller)
    local context = resolveContext(controller)
    if not context then
        return
    end

    controller.fusionItem = nil
    controller.fusionItemCount = nil
    controller.fusionSelectedItem = nil

    if context.targetItem then
        context.targetItem:setItemId(0)
        context.targetItem:setItemCount(0)
        ItemsDatabase.setTier(context.targetItem, 0)
    end

    if context.selectedItemIcon then
        context.selectedItemIcon:setItemId(0)
        context.selectedItemIcon:setItemCount(0)
        ItemsDatabase.setTier(context.selectedItemIcon, 0)
    end

    if context.selectedItemQuestion then
        context.selectedItemQuestion:setVisible(true)
    end

    updateControllerText(controller, 'fusionSelectedItemCounterText', '0 / 1')

    if context.placeholder then
        context.placeholder:setVisible(true)
    end

    if context.convergenceSection then
        context.convergenceSection:setVisible(false)
    end

    if context.fusionButtonItem then
        context.fusionButtonItem:setItemId(0)
        context.fusionButtonItem:setItemCount(0)
        ItemsDatabase.setTier(context.fusionButtonItem, 0)
    end

    if context.fusionButtonItemTo then
        context.fusionButtonItemTo:setItemId(0)
        context.fusionButtonItemTo:setItemCount(0)
        ItemsDatabase.setTier(context.fusionButtonItemTo, 0)
    end

    if context.convergenceItemsPanel then
        context.convergenceItemsPanel:destroyChildren()
    end

    if state.convergenceGroup then
        state.convergenceGroup:destroy()
        state.convergenceGroup = nil
    end

    if context.dustAmountLabel then
        context.dustAmountLabel:setColor('$var-text-cip-color')
    end

    local resetDustRequirement = (controller.openData and tonumber(controller.openData.convergenceDustFusion))
        or tonumber(controller.convergenceDustFusion) or 0
    updateControllerText(controller, 'fusionDustRequirementText', resetDustRequirement)

    if context.costLabel then
        updateControllerText(controller, 'fusionPriceDisplay', '???')
        context.costLabel:setColor('$var-text-cip-color')
    end

    state.lastSuccessSelection = false
    state.lastTierSelection = false

    FusionTab.resetCoreSelections(controller)
    FusionTab.updateFusionCoreButtons(controller)
end

function FusionTab.updateFusionItems(controller, fusionData)
    local state = getState(controller)
    local context = resolveContext(controller)
    if not context then
        return
    end

    if context.selectionPanel and (not context.selectionItemsPanel or context.selectionItemsPanel:isDestroyed()) then
        local selectionGrid = context.selectionPanel.fusionSelectionGrid
            or (context.panel and context.panel.fusionSelectionGrid)
        if selectionGrid then
            context.selectionItemsPanel = resolveScrollContents(selectionGrid)
        end
    end

    FusionTab.resetConversionPanel(controller)

    local itemsPanel = context.selectionItemsPanel
    if not itemsPanel then
        return
    end

    itemsPanel:destroyChildren()

    if state.selectionGroup then
        state.selectionGroup:destroy()
        state.selectionGroup = nil
    end

    local selectionGroup = UIRadioGroup.create()
    selectionGroup:clearSelected()
    selectionGroup.onSelectionChange = function(group, widget)
        onFusionSelectionChange(controller, state, widget)
    end
    state.selectionGroup = selectionGroup

    local data = fusionData
    if not data then
        if controller.modeFusion then
            data = controller.convergenceFusion
        else
            data = controller.fusionItems
        end
    end

    local function applySelectionHighlight(widget, checked)
        if not widget or widget:isDestroyed() then
            return
        end

        if checked then
            widget:setBorderWidth(1)
            widget:setBorderColor('#ffffff')
        else
            widget:setBorderWidth(0)
        end
    end

    local function appendItem(info)
        if type(info) ~= 'table' or not info.id or info.id <= 0 then
            return
        end

        local widget = g_ui.createWidget('UICheckBox', itemsPanel)
        if not widget then
            return
        end

        widget:setFocusable(true)
        widget:setSize('36 36')
        widget:setBorderWidth(0)
        widget:setBorderColor('#ffffff')

        widget.onCheckChange = function(selfWidget, checked)
            applySelectionHighlight(selfWidget, checked)
        end

        local frame = g_ui.createWidget('UIWidget', widget)
        frame:setSize('34 34')
        frame:setMarginLeft(1)
        frame:setMarginTop(1)
        frame:addAnchor(AnchorTop, 'parent', AnchorTop)
        frame:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        frame:setImageSource('/images/ui/item')
        frame:setPhantom(true)
        frame:setFocusable(false)

        local itemWidget = g_ui.createWidget('UIItem', widget)
        itemWidget:setSize('32 32')
        itemWidget:setMarginTop(2)
        itemWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
        itemWidget:addAnchor(AnchorHorizontalCenter, 'parent', AnchorHorizontalCenter)
        itemWidget:setPhantom(true)
        itemWidget:setVirtual(true)
        itemWidget:setShowCount(true)
        local itemPtr = Item.create(info.id, info.count or 1)
        itemPtr:setTier(info.tier or 0)
        g_logger.info("item id: " .. itemPtr:getId() .. " tier: " .. itemPtr:getTier())
        itemWidget:setItem(itemPtr)
        itemWidget:setItemCount(info.count or itemPtr:getCount())
        ItemsDatabase.setRarityItem(itemWidget, itemPtr)
        ItemsDatabase.setTier(itemWidget, itemPtr)


        widget.item = itemWidget
        widget.itemPtr = itemPtr
        widget.fusionItemInfo = info

        applySelectionHighlight(widget, widget:isChecked())

        selectionGroup:addWidget(widget)
    end

    local function processEntries(entries)
        if type(entries) ~= 'table' then
            return
        end

        for _, entry in ipairs(entries) do
            if type(entry) == 'table' then
                if entry.id then
                    appendItem(entry)
                else
                    processEntries(entry)
                end
            end
        end
    end

    processEntries(data or {})
end

return FusionTab
