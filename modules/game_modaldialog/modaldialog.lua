modalDialog = nil

function init()
    g_ui.importStyle('modaldialog')

    connect(g_game, {
        onModalDialog = onModalDialog,
        onGameEnd = destroyDialog
    })

    local dialog = rootWidget:recursiveGetChildById('modalDialog')
    if dialog then
        modalDialog = dialog
    end
end

function terminate()
    disconnect(g_game, {
        onModalDialog = onModalDialog,
        onGameEnd = destroyDialog
    })
end

function destroyDialog()
    if modalDialog then
        modalDialog:destroy()
        modalDialog = nil
    end
end

local function parseSimpleHtml(text)
    local hasHtml = false
    local images = {}
    local parsed = text:gsub('<br ?/?>', '\n')

    parsed = parsed:gsub('<img%s+src="([^"]+)"%s*/?>', function(src)
        hasHtml = true
        table.insert(images, src)
        return ''
    end)

    parsed = parsed:gsub('<font%s+color="?(#[%x]+)"?>(.-)</font>', function(color, content)
        hasHtml = true
        return string.format('{%s,%s}', content, color)
    end)
    parsed = parsed:gsub('</?[bB]>', '')
    parsed = parsed:gsub('</?[iI]>', '')
    parsed = parsed:gsub('</?[uU]>', '')
    return parsed, hasHtml, images
end

function onModalDialog(id, title, message, buttons, enterButton, escapeButton, choices, priority)
    -- priority parameter is unused, not sure what its use is.
    if modalDialog then
        return
    end

    modalDialog = g_ui.createWidget('ModalDialog', rootWidget)

    local messageLabel = modalDialog:getChildById('messageLabel')
    local choiceList = modalDialog:getChildById('choiceList')
    local choiceScrollbar = modalDialog:getChildById('choiceScrollBar')
    local buttonsPanel = modalDialog:getChildById('buttonsPanel')

    modalDialog:setText(title)

    local parsedMessage, messageHasHtml, messageImages = parseSimpleHtml(message)
    if messageHasHtml then
        messageLabel:setColoredText(parsedMessage)
    else
        messageLabel:setText(parsedMessage)
    end

    local insertIndex = modalDialog:getChildIndex(choiceList)
    local anchorId = 'messageLabel'
    local imageWidgets = {}
    for i = 1, #messageImages do
        local src = messageImages[i]
        local image = g_ui.createWidget('ImageView')
        image:setId('modalImage' .. i)
        image:setImageSource(src)
        image:setMarginTop(4)
        image:addAnchor(AnchorLeft, 'parent', AnchorLeft)
        image:addAnchor(AnchorTop, anchorId, AnchorBottom)
        modalDialog:insertChild(insertIndex, image)
        insertIndex = insertIndex + 1
        anchorId = image:getId()
        table.insert(imageWidgets, image)
    end

    if #imageWidgets > 0 then
        choiceList:removeAnchor(AnchorTop)
        choiceList:addAnchor(AnchorTop, anchorId, AnchorBottom)
        choiceScrollbar:removeAnchor(AnchorTop)
        choiceScrollbar:addAnchor(AnchorTop, anchorId, AnchorBottom)
    end

    local labelHeight
    for i = 1, #choices do
        local choiceId = choices[i][1]
        local choiceName = choices[i][2]

        local label = g_ui.createWidget('ChoiceListLabel', choiceList)
        label.choiceId = choiceId

        local parsedChoice, choiceHasHtml = parseSimpleHtml(choiceName)
        if choiceHasHtml then
            label:setColoredText(parsedChoice)
        else
            label:setText(parsedChoice)
        end
        label:setPhantom(false)
        if not labelHeight then
            labelHeight = label:getHeight()
        end
    end
    choiceList:focusChild(choiceList:getFirstChild())

    g_keyboard.bindKeyPress('Down', function()
        choiceList:focusNextChild(KeyboardFocusReason)
    end, modalDialog)
    g_keyboard.bindKeyPress('Up', function()
        choiceList:focusPreviousChild(KeyboardFocusReason)
    end, modalDialog)

    local buttonsWidth = 0
    for i = 1, #buttons do
        local buttonId = buttons[i][1]
        local buttonText = buttons[i][2]

        local button = g_ui.createWidget('ModalButton', buttonsPanel)
        button:setText(buttonText)
        button.onClick = function(self)
            local focusedChoice = choiceList:getFocusedChild()
            local choice = 0xFF
            if focusedChoice then
                choice = focusedChoice.choiceId
            end
            g_game.answerModalDialog(id, buttonId, choice)
            destroyDialog()
        end
        buttonsWidth = buttonsWidth + button:getWidth() + button:getMarginLeft() + button:getMarginRight()
    end

    local additionalHeight = 0
    if #choices > 0 then
        choiceList:setVisible(true)
        choiceScrollbar:setVisible(true)

        additionalHeight = math.min(modalDialog.maximumChoices, math.max(modalDialog.minimumChoices, #choices)) *
                               labelHeight
        additionalHeight = additionalHeight + choiceList:getPaddingTop() + choiceList:getPaddingBottom()
    end

    local horizontalPadding = modalDialog:getPaddingLeft() + modalDialog:getPaddingRight()
    buttonsWidth = buttonsWidth + horizontalPadding

    modalDialog:setWidth(math.min(modalDialog.maximumWidth,
                                  math.max(buttonsWidth, messageLabel:getWidth(), modalDialog.minimumWidth)))
    messageLabel:setWidth(math.min(modalDialog.maximumWidth,
                                   math.max(buttonsWidth, messageLabel:getWidth(), modalDialog.minimumWidth)) -
                              horizontalPadding)

    local contentHeight = messageLabel:getHeight()
    for i = 1, #imageWidgets do
        contentHeight = contentHeight + imageWidgets[i]:getHeight() + imageWidgets[i]:getMarginTop()
    end

    modalDialog:setHeight(modalDialog:getHeight() + additionalHeight + contentHeight - 8)

    local enterFunc = function()
        local focusedChoice = choiceList:getFocusedChild()
        local choice = 0xFF
        if focusedChoice then
            choice = focusedChoice.choiceId
        end
        g_game.answerModalDialog(id, enterButton, choice)
        destroyDialog()
    end

    local escapeFunc = function()
        local focusedChoice = choiceList:getFocusedChild()
        local choice = 0xFF
        if focusedChoice then
            choice = focusedChoice.choiceId
        end
        g_game.answerModalDialog(id, escapeButton, choice)
        destroyDialog()
    end

    choiceList.onDoubleClick = enterFunc

    modalDialog.onEnter = enterFunc
    modalDialog.onEscape = escapeFunc
end
