GemAtelier = {}  
  
function GemAtelier.show(container)
    if not container then
        return
    end

    local gemUI = container:recursiveGetChildById('gemContainer')
    if gemUI then
        gemUI:setVisible(true)
        gemUI:fill('parent')
    end
end