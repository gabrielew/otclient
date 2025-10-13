HuntingTasks = HuntingTasks or {}

local Tasks = HuntingTasks

local tasksTab
local contentWidget
local placeholderWidget

local function destroyWidget(widget)
    if widget and not widget:isDestroyed() then
        widget:destroy()
    end
end

local function resolveTasksTab(preyWindow, tabWidget)
    if tabWidget and not tabWidget:isDestroyed() then
        return tabWidget
    end

    if not preyWindow then
        return nil
    end

    local widget = preyWindow:recursiveGetChildById('huntingTasksTab')
    if widget and widget:isDestroyed and widget:isDestroyed() then
        return nil
    end

    return widget
end

local function ensureContentWidget()
    if not tasksTab or (tasksTab.isDestroyed and tasksTab:isDestroyed()) then
        contentWidget = nil
        return nil
    end

    if contentWidget and not contentWidget:isDestroyed() then
        return contentWidget
    end

    contentWidget = tasksTab:getChildById('huntingTasksContent')
    if contentWidget and contentWidget.isDestroyed and contentWidget:isDestroyed() then
        contentWidget = nil
    end

    if not contentWidget and g_ui then
        contentWidget = g_ui.createWidget('UIWidget', tasksTab)
        contentWidget:setId('huntingTasksContent')
        if contentWidget.fill then
            contentWidget:fill('parent')
        else
            contentWidget:addAnchor(AnchorTop, 'parent', AnchorTop)
            contentWidget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            contentWidget:addAnchor(AnchorRight, 'parent', AnchorRight)
            contentWidget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        end
    end

    return contentWidget
end

function Tasks.init(preyWindow, tabWidget)
    Tasks.terminate()

    tasksTab = resolveTasksTab(preyWindow, tabWidget)
    if not tasksTab then
        return
    end

    ensureContentWidget()
    Tasks.showPlaceholder()
end

function Tasks.terminate()
    destroyWidget(placeholderWidget)
    placeholderWidget = nil

    if contentWidget and not contentWidget:isDestroyed() then
        contentWidget:destroyChildren()
    end

    contentWidget = nil
    tasksTab = nil
end

function Tasks.getTab()
    if tasksTab and not tasksTab:isDestroyed() then
        return tasksTab
    end
    return nil
end

function Tasks.getContentWidget()
    return ensureContentWidget()
end

function Tasks.clear()
    local content = ensureContentWidget()
    if not content then
        return
    end

    content:destroyChildren()
    destroyWidget(placeholderWidget)
    placeholderWidget = nil
end

function Tasks.setContent(widget, keepAnchors)
    if not widget then
        return nil
    end

    local content = ensureContentWidget()
    if not content then
        return nil
    end

    Tasks.clear()

    if widget:getParent() ~= content then
        widget:setParent(content)
    end

    widget:setVisible(true)

    if keepAnchors ~= true then
        if widget.fill then
            widget:fill('parent')
        else
            widget:addAnchor(AnchorTop, 'parent', AnchorTop)
            widget:addAnchor(AnchorLeft, 'parent', AnchorLeft)
            widget:addAnchor(AnchorRight, 'parent', AnchorRight)
            widget:addAnchor(AnchorBottom, 'parent', AnchorBottom)
        end
    end

    return widget
end

function Tasks.showPlaceholder(text)
    local content = ensureContentWidget()
    if not content then
        return nil
    end

    content:destroyChildren()
    destroyWidget(placeholderWidget)

    placeholderWidget = g_ui.createWidget('UILabel', content)
    placeholderWidget:setId('huntingTasksPlaceholder')
    placeholderWidget:fill('parent')
    placeholderWidget:setTextWrap(true)
    placeholderWidget:setTextAlign(AlignCenter)
    placeholderWidget:setFont('verdana-11px-rounded')
    placeholderWidget:setColor('#c6c6c6')
    placeholderWidget:setText(text or tr('No hunting tasks available.'))

    return placeholderWidget
end

function Tasks.setPlaceholderText(text)
    if not placeholderWidget or placeholderWidget:isDestroyed() then
        return Tasks.showPlaceholder(text)
    end

    placeholderWidget:setText(text or tr('No hunting tasks available.'))
    return placeholderWidget
end

return Tasks
