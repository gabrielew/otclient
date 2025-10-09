forgeWindow = nil
fusionMenu = nil
transferMenu = nil
conversionMenu = nil
historyMenu = nil
resultWindow = nil

local function appendOtuiExtension(path)
  if path:sub(-5) == '.otui' then
    return path
  end
  return path .. '.otui'
end

local function instantiateWidget(styleName, uiPath, parent, expectedId)
  local widget = g_ui.createWidget(styleName, parent)
  if widget then
    return widget
  end

  local resolvedUiPath = uiPath
  g_logger.warning(string.format("Failed to create widget '%s' from style, attempting to load UI '%s'", styleName, resolvedUiPath))

  local fallbackRoot = g_ui.loadUI(resolvedUiPath, parent)

  if not fallbackRoot then
    resolvedUiPath = appendOtuiExtension(uiPath)
    if resolvedUiPath ~= uiPath then
      g_logger.warning(string.format("Retrying fallback load for widget '%s' using '%s'", styleName, resolvedUiPath))
      fallbackRoot = g_ui.loadUI(resolvedUiPath, parent)
    end
  end

  if not fallbackRoot then
    g_logger.error(string.format("Unable to load fallback UI '%s' for widget '%s'", resolvedUiPath, styleName))
    return nil
  end

  if not expectedId or fallbackRoot:getId() == expectedId then
    return fallbackRoot
  end

  local resolved = fallbackRoot:recursiveGetChildById(expectedId)
  if resolved then
    return resolved
  end

  g_logger.error(string.format("Widget '%s' not found inside fallback UI '%s'", expectedId, uiPath))
  return nil
end

selectedItemFusionRadio = nil
selectedConvergenceFusionRadio = nil
selectedItemFusionConvectionRadio = nil

function init()
  g_ui.importStyle('styles/compat')
  g_ui.importStyle('styles/fusion')
  g_ui.importStyle('styles/transfer')
  g_ui.importStyle('styles/conversion')
  g_ui.importStyle('styles/history')
  g_ui.importStyle('styles/result')

  forgeWindow = g_ui.displayUI('forge')
  mainPanel = forgeWindow:getChildById('contentPanel')

  fusionMenu = instantiateWidget('FusionMenu', 'styles/fusion', mainPanel, 'fusionMenu')
  transferMenu = instantiateWidget('TransferMenu', 'styles/transfer', mainPanel, 'transferMenu')
  conversionMenu = instantiateWidget('ConversionMenu', 'styles/conversion', mainPanel, 'conversionMenu')
  historyMenu = instantiateWidget('HistoryMenu', 'styles/history', mainPanel, 'historyMenu')
  resultWindow = instantiateWidget('ResultMainWindow', 'styles/result', g_ui.getRootWidget(), 'resultMainWindow')

  if not fusionMenu or not transferMenu or not conversionMenu or not historyMenu or not resultWindow then
    g_logger.error('Failed to initialize forge menus; aborting module setup')
    return
  end

  fusionMenu:hide()
  transferMenu:hide()
  conversionMenu:hide()
  historyMenu:hide()
  resultWindow:hide()

  loadMenu('fusionMenu')
  hideForge()

  connect(g_game, {
    onForgeInit = ForgeSystem.init,
    onForgeData = ForgeSystem.onForgeData,
    onForgeFusion = ForgeSystem.onForgeFusion,
    onForgeTransfer = ForgeSystem.onForgeTransfer,
    onForgeHistory = ForgeSystem.onForgeHistory,
    onResourceBalance = onResourceBalance,
    onGameEnd = offlineForge,
  })
end

function terminate()
  if forgeWindow then
    forgeWindow:destroy()
    forgeWindow = nil
  end
  if resultWindow then
    resultWindow:destroy()
    resultWindow = nil
  end
  disconnect(g_game, {
    onForgeInit = ForgeSystem.init,
    onForgeData = ForgeSystem.onForgeData,
    onForgeFusion = ForgeSystem.onForgeFusion,
    onForgeTransfer = ForgeSystem.onForgeTransfer,
    onForgeHistory = ForgeSystem.onForgeHistory,
    onResourceBalance = onResourceBalance,
    onGameEnd = offlineForge,
  })
end

function toggle()
  ForgeSystem.fusionData = {}
  ForgeSystem.fusionConvergenceData = {}
  ForgeSystem.transferData = {}
  ForgeSystem.transferConvergenceData = {}
  if forgeWindow:isVisible() then
    forgeWindow:hide()
    g_client.setInputLockWidget(nil)
  else
    forgeWindow:show(true)
    g_client.setInputLockWidget(forgeWindow)
    ForgeSystem.sideButton = true
    loadMenu('conversionMenu')
    forgeWindow:raise()
    forgeWindow:focus()
  end
end

function hideForge()
  forgeWindow:hide()
  g_client.setInputLockWidget(nil)
end

function show()
  if not forgeWindow:isVisible() then
    forgeWindow:show(true)
    forgeWindow:raise()
    forgeWindow:focus()
    loadMenu('fusionMenu')
  end
  g_client.setInputLockWidget(forgeWindow)


  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  forgeWindow.sliversPanel.slivers:setText(player:getResourceValue(ResourceForgeSlivers))
  forgeWindow.exaltedcorePanel.exaltedcore:setText(player:getResourceValue(ResourceForgeExaltedCore))
  forgeWindow.dustPanel.dust:setText(player:getResourceValue(ResourceForgeDust) .. '/' .. ForgeSystem.maxPlayerDust)
  forgeWindow.moneyPanel.gold:setText(formatMoney(
    player:getResourceValue(ResourceBank) + player:getResourceValue(ResourceInventary), ","))
end

function loadMenu(menuId)
  --mainPanel:destroyChildren()

  if fusionMenu:isVisible() then
    fusionMenu:hide()
  end

  if transferMenu:isVisible() then
    transferMenu:hide()
  end

  if conversionMenu:isVisible() then
    conversionMenu:hide()
  end

  if historyMenu:isVisible() then
    historyMenu:hide()
  end

  g_game.doThing(false)
  g_game.requestResource(ResourceBank)
  g_game.requestResource(ResourceInventary)
  g_game.requestResource(ResourceForgeDust)
  g_game.requestResource(ResourceForgeSlivers)
  g_game.requestResource(ResourceForgeExaltedCore)
  g_game.doThing(false)

  local fusionMenuButton = forgeWindow.panelButtons:getChildById('fusionButton')
  local transferMenuButton = forgeWindow.panelButtons:getChildById('transferButton')
  local conversionMenuButton = forgeWindow.panelButtons:getChildById('conversionButton')
  local historyMenuButton = forgeWindow.panelButtons:getChildById('historyButton')

  transferMenuButton:setChecked(false)
  conversionMenuButton:setChecked(false)
  historyMenuButton:setChecked(false)
  fusionMenuButton:setChecked(false)
  if menuId == 'fusionMenu' then
    fusionMenu:show(true)
    ForgeSystem.updateFusion()
    fusionMenuButton:setChecked(true)
  elseif menuId == 'transferMenu' then
    transferMenu:show(true)
    ForgeSystem.updateTransfer()
    transferMenuButton:setChecked(true)
  elseif menuId == 'conversionMenu' then
    conversionMenu:show(true)
    ForgeSystem.updateConversion()
    conversionMenuButton:setChecked(true)
  elseif menuId == 'historyMenu' then
    historyMenu:show(true)
    historyMenuButton:setChecked(true)
    g_game.sendForgeBrowseHistoryRequest(0)
  end

  local player = g_game.getLocalPlayer()
  if not player then return end

  forgeWindow.sliversPanel.slivers:setText(player:getResourceValue(ResourceForgeSlivers))
  forgeWindow.exaltedcorePanel.exaltedcore:setText(player:getResourceValue(ResourceForgeExaltedCore))
  forgeWindow.dustPanel.dust:setText(player:getResourceValue(ResourceForgeDust) .. '/' .. ForgeSystem.maxPlayerDust)
  forgeWindow.moneyPanel.gold:setText(formatMoney(
    player:getResourceValue(ResourceBank) + player:getResourceValue(ResourceInventary), ","))
end

function offlineForge()
  forgeWindow:hide()
  resultWindow:hide()
  g_client.setInputLockWidget(nil)
  ForgeSystem.clearFusion()
  ForgeSystem.clearTransfer()

  ForgeSystem.fusionData = {}
  ForgeSystem.fusionConvergenceData = {}
  ForgeSystem.transferData = {}
  ForgeSystem.transferConvergenceData = {}
end

function onResourceBalance(type, amount)
  local player = g_game.getLocalPlayer()
  if not player then
    return
  end

  if table.contains({ ResourceBank, ResourceInventary, ResourceForgeDust, ResourceForgeSlivers, ResourceForgeExaltedCore }, type) then
    forgeWindow.sliversPanel.slivers:setText(player:getResourceValue(ResourceForgeSlivers))
    forgeWindow.exaltedcorePanel.exaltedcore:setText(player:getResourceValue(ResourceForgeExaltedCore))
    forgeWindow.dustPanel.dust:setText(player:getResourceValue(ResourceForgeDust) .. '/' .. ForgeSystem.maxPlayerDust)
    forgeWindow.moneyPanel.gold:setText(formatMoney(
      player:getResourceValue(ResourceBank) + player:getResourceValue(ResourceInventary), ","))

    ForgeSystem.checkFusionButton()
    ForgeSystem.updateConversion()
  end
end
