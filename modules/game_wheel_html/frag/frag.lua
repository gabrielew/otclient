FragmentWorkshop = {}  
  
function FragmentWorkshop.show(container)
    if not container then
        return
    end

    local fragUI = container:recursiveGetChildById('fragContainer')
    if fragUI then
        fragUI:setVisible(true)
        fragUI:fill('parent')
    end
end