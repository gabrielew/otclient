imageSizeBroad = 0
imageSizeThin = 0
extraImageSizeBroad = 0
extraImageSizeThin = 0

mapPanel = modules.game_interface.getMapPanel()
gameRootPanel = modules.game_interface.gameBottomPanel
gameLeftPanel = modules.game_interface.getLeftPanel()
gameTopMenu = modules.client_topmenu.getTopMenu()

function currentViewMode()
    return modules.game_interface.currentViewMode
end

healthCircle = nil
healthCircleExtra = nil
manaCircle = nil
expCircle = nil
skillCircle = nil

healthCircleFront = nil
healthCircleExtraFront = nil
manaCircleFront = nil
expCircleFront = nil
skillCircleFront = nil

optionPanel = nil

isHealthCircle = not g_settings.getBoolean('healthcircle_hpcircle')
isManaCircle = not g_settings.getBoolean('healthcircle_mpcircle')
isExpCircle = g_settings.getBoolean('healthcircle_expcircle')
isSkillCircle = g_settings.getBoolean('healthcircle_skillcircle')
skillTypes = g_settings.getNode('healthcircle_skilltypes')
skillsLoaded = false

if not skillTypes then
    skillTypes = {}
end

distanceFromCenter = g_settings.getNumber('healthcircle_distfromcenter')
opacityCircle = g_settings.getNumber('healthcircle_opacity', 0.35)

function init()
    g_ui.importStyle("game_healthcircle.otui")
    healthCircle = g_ui.createWidget('HealthCircle', mapPanel)
    healthCircleExtra = g_ui.createWidget('HealthCircleExtra', mapPanel)
    manaCircle = g_ui.createWidget('ManaCircle', mapPanel)
    expCircle = g_ui.createWidget('ExpCircle', mapPanel)
    skillCircle = g_ui.createWidget('SkillCircle', mapPanel)

    healthCircleFront = g_ui.createWidget('HealthCircleFront', mapPanel)
    healthCircleExtraFront = g_ui.createWidget('HealthCircleExtraFront', mapPanel)
    manaCircleFront = g_ui.createWidget('ManaCircleFront', mapPanel)
    expCircleFront = g_ui.createWidget('ExpCircleFront', mapPanel)
    skillCircleFront = g_ui.createWidget('SkillCircleFront', mapPanel)

    imageSizeBroad = healthCircle:getHeight()
    imageSizeThin = healthCircle:getWidth()
    extraImageSizeBroad = healthCircleExtra:getHeight()
    extraImageSizeThin = healthCircleExtra:getWidth()

    whenMapResizeChange()
    initOnHpAndMpChange()
    initOnGeometryChange()
    initOnLoginChange()

    if not isHealthCircle then
        healthCircle:setVisible(false)
        healthCircleFront:setVisible(false)
        healthCircleExtra:setVisible(false)
        healthCircleExtraFront:setVisible(false)
    end

    if not isManaCircle then
        manaCircle:setVisible(false)
        manaCircleFront:setVisible(false)
    end

    if not isExpCircle then
        expCircle:setVisible(false)
        expCircleFront:setVisible(false)
    end

    if not isSkillCircle then
        skillCircle:setVisible(false)
        skillCircleFront:setVisible(false)
    end

    -- Add option window in options module
    addToOptionsModule()

    connect(g_game, {
        onGameStart = setPlayerValues
    })
end

function terminate()
    healthCircle:destroy()
    healthCircle = nil
    healthCircleExtra:destroy()
    healthCircleExtra = nil
    manaCircle:destroy()
    manaCircle = nil
    expCircle:destroy()
    expCircle = nil
    skillCircle:destroy()
    skillCircle = nil

    healthCircleFront:destroy()
    healthCircleFront = nil
    healthCircleExtraFront:destroy()
    healthCircleExtraFront = nil
    manaCircleFront:destroy()
    manaCircleFront = nil
    expCircleFront:destroy()
    expCircleFront = nil
    skillCircleFront:destroy()
    skillCircleFront = nil

    terminateOnHpAndMpChange()
    terminateOnGeometryChange()
    terminateOnLoginChange()

    -- Delete from options module
    destroyOptionsModule()

    disconnect(g_game, {
        onGameStart = setPlayerValues
    })
    statsBarMenuLoaded = false
end

-------------------------------------------------
-- Scripts----------------------------------------
-------------------------------------------------

function initOnHpAndMpChange()
    connect(LocalPlayer, {
        onHealthChange = whenHealthChange,
        onManaChange = whenManaChange,
        onSkillChange = whenSkillsChange,
        onMagicLevelChange = whenSkillsChange,
        onLevelChange = whenSkillsChange
    })
end

function terminateOnHpAndMpChange()
    disconnect(LocalPlayer, {
        onHealthChange = whenHealthChange,
        onManaChange = whenManaChange,
        onSkillChange = whenSkillsChange,
        onMagicLevelChange = whenSkillsChange,
        onLevelChange = whenSkillsChange
    })
end

function initOnGeometryChange()
    connect(mapPanel, {
        onGeometryChange = whenMapResizeChange
    })
end

function terminateOnGeometryChange()
    disconnect(mapPanel, {
        onGeometryChange = whenMapResizeChange
    })
end

function initOnLoginChange()
    connect(g_game, {
        onGameStart = whenMapResizeChange
    })
end

function terminateOnLoginChange()
    disconnect(g_game, {
        onGameStart = whenMapResizeChange
    })
end

function whenHealthChange()
    if g_game.isOnline() then
        -- Fix By TheMaoci ~ if your server doesn't have this properly implemented,
        -- it will cause alot of unnecessary deaths from players which will be unfair.
        -- My friend reported me that while he was using his otcv8 and asked for a fix so here you go :)
        local player = g_game.getLocalPlayer()
        if not player then
            return
        end

        local maxHealth = player:getMaxHealth()
        if maxHealth <= 0 then
            return
        end

        local healthPercent = math.floor(player:getHealth() / maxHealth * 100)
        -- Old leaved for ppl who have that implemented correctly
        --local healthPercent = math.floor(player:getHealthPercent())

        local yhppc = math.floor(imageSizeBroad * (1 - (healthPercent / 100)))
        local restYhppc = imageSizeBroad - yhppc

        healthCircleFront:setY(healthCircle:getY() + yhppc)
        healthCircleFront:setHeight(restYhppc)
        healthCircleFront:setImageClip({
            x = 0,
            y = yhppc,
            width = imageSizeThin,
            height = restYhppc
        })

        healthCircle:setHeight(yhppc)
        healthCircle:setImageClip({
            x = 0,
            y = 0,
            width = imageSizeThin,
            height = yhppc
        })

        if healthCircleExtra and healthCircleExtraFront then
            local harmonyPercent = 0
            local shouldShowHarmony = false
            local maxHarmony = 5

            if isHealthCircle and player.getHarmony and maxHarmony > 0 then
                local success, harmonyValue = pcall(player.getHarmony, player)
                if success and type(harmonyValue) == 'number' then
                    harmonyValue = math.max(0, math.min(maxHarmony, harmonyValue))
                    harmonyPercent = harmonyValue / maxHarmony * 100
                    shouldShowHarmony = true
                end
            end

            if shouldShowHarmony then
                local yhppcExtra = math.floor(extraImageSizeBroad * (1 - (harmonyPercent / 100)))
                local restYhppcExtra = extraImageSizeBroad - yhppcExtra

                healthCircleExtra:setVisible(true)
                healthCircleExtraFront:setVisible(true)

                healthCircleExtraFront:setY(healthCircleExtra:getY() + yhppcExtra)
                healthCircleExtraFront:setHeight(restYhppcExtra)
                healthCircleExtraFront:setImageClip({
                    x = 0,
                    y = yhppcExtra,
                    width = extraImageSizeThin,
                    height = restYhppcExtra
                })
                healthCircleExtraFront:setImageColor('#BE713E')

                healthCircleExtra:setHeight(yhppcExtra)
                healthCircleExtra:setImageClip({
                    x = 0,
                    y = 0,
                    width = extraImageSizeThin,
                    height = yhppcExtra
                })
            else
                healthCircleExtra:setVisible(false)
                healthCircleExtraFront:setVisible(false)
            end
        end

        if healthPercent > 92 then
            healthCircleFront:setImageColor('#00BC00')
        elseif healthPercent > 60 then
            healthCircleFront:setImageColor('#50A150')
        elseif healthPercent > 30 then
            healthCircleFront:setImageColor('#A1A100')
        elseif healthPercent > 8 then
            healthCircleFront:setImageColor('#BF0A0A')
        elseif healthPercent > 3 then
            healthCircleFront:setImageColor('#910F0F')
        else
            healthCircleFront:setImageColor('#850C0C')
        end
    end
end

function whenManaChange()
    if g_game.isOnline() then
        local maxMana = g_game.getLocalPlayer():getMaxMana()
        if maxMana <= 0 then
            manaCircle:setVisible(false)
            manaCircleFront:setVisible(false)
            return
        elseif isManaCircle then
            manaCircle:setVisible(true)
            manaCircleFront:setVisible(true)
        end

        local manaPercent = math.floor(maxMana - (maxMana - g_game.getLocalPlayer():getMana())) * 100 / maxMana

        local ymppc = math.floor(imageSizeBroad * (1 - (manaPercent / 100)))
        local restYmppc = imageSizeBroad - ymppc

        manaCircleFront:setY(manaCircle:getY() + ymppc)
        manaCircleFront:setHeight(restYmppc)
        manaCircleFront:setImageClip({
            x = 0,
            y = ymppc,
            width = imageSizeThin,
            height = restYmppc
        })

        manaCircle:setHeight(ymppc)
        manaCircle:setImageClip({
            x = 0,
            y = 0,
            width = imageSizeThin,
            height = ymppc
        })
    end
end

function whenSkillsChange()
    if g_game.isOnline() then
        if isExpCircle then
            local player = g_game.getLocalPlayer()
            local Xexpc = math.floor(imageSizeBroad * (1 - player:getLevelPercent() / 100))

            expCircleFront:setImageClip({
                x = 0,
                y = 0,
                width = imageSizeBroad - Xexpc,
                height = imageSizeThin
            })
            expCircleFront:setWidth(imageSizeBroad - Xexpc)

            expCircle:setImageClip({
                x = imageSizeBroad - Xexpc,
                y = 0,
                width = Xexpc,
                height = imageSizeThin
            })
            expCircle:setWidth(Xexpc)
            expCircle:setX(expCircleFront:getX() + expCircleFront:getWidth())
        end

        if isSkillCircle then
            local player = g_game.getLocalPlayer()

            local skillPercent
            local skillColor
            local skillType = skillTypes[player:getName()]

            if skillType == 'fist' then
                skillPercent = player:getSkillLevelPercent(0)
                skillColor = '#9900cc'
            elseif skillType == 'club' then
                skillPercent = player:getSkillLevelPercent(1)
                skillColor = '#cc3399'
            elseif skillType == 'sword' then
                skillPercent = player:getSkillLevelPercent(2)
                skillColor = '#FF7F00'
            elseif skillType == 'axe' then
                skillPercent = player:getSkillLevelPercent(3)
                skillColor = '#696969'
            elseif skillType == 'distance' then
                skillPercent = player:getSkillLevelPercent(4)
                skillColor = '#A62A2A'
            elseif skillType == 'shielding' then
                skillPercent = player:getSkillLevelPercent(5)
                skillColor = '#663300'
            elseif skillType == 'fishing' then
                skillPercent = player:getSkillLevelPercent(6)
                skillColor = '#ffff33'
            else
                -- default skill: MAGIC
                skillPercent = player:getMagicLevelPercent()
                skillColor = '#00ffcc'
            end

            local Xskpc = math.floor(imageSizeBroad * (1 - skillPercent / 100))
            skillCircleFront:setImageColor(skillColor)

            skillCircleFront:setImageClip({
                x = 0,
                y = 0,
                width = imageSizeBroad - Xskpc,
                height = imageSizeThin
            })
            skillCircleFront:setWidth(imageSizeBroad - Xskpc)

            skillCircle:setImageClip({
                x = imageSizeBroad - Xskpc,
                y = 0,
                width = Xskpc,
                height = imageSizeThin
            })
            skillCircle:setWidth(Xskpc)
            skillCircle:setX(skillCircleFront:getX() + skillCircleFront:getWidth())
        end
    end
end

function whenMapResizeChange()
    if g_game.isOnline() then

        local barDistance = 90
        if not (math.floor(mapPanel:getHeight() / 2 * 0.2) < 100) then -- 0.381
            barDistance = math.floor(mapPanel:getHeight() / 2 * 0.2)
        end

        if currentViewMode() == 2 then
            local healthX = math.floor(mapPanel:getWidth() / 2 - barDistance - imageSizeThin) - distanceFromCenter
            local manaX = math.floor(mapPanel:getWidth() / 2 + barDistance) + distanceFromCenter

            healthCircleFront:setX(healthX)
            manaCircleFront:setX(manaX)

            healthCircle:setX(healthX)
            manaCircle:setX(manaX)

            local healthY = mapPanel:getHeight() / 2 - imageSizeBroad / 2
            healthCircle:setY(healthY)
            manaCircle:setY(healthY)

            if healthCircleExtra and healthCircleExtraFront then
                local extraHealthX = math.floor(mapPanel:getWidth() / 2 - barDistance - extraImageSizeThin) - distanceFromCenter
                local extraHealthY = mapPanel:getHeight() / 2 - extraImageSizeBroad / 2
                healthCircleExtra:setX(extraHealthX)
                healthCircleExtraFront:setX(extraHealthX)
                healthCircleExtra:setY(extraHealthY)
                healthCircleExtraFront:setY(extraHealthY)
            end

            if isExpCircle then
                expCircleFront:setY(math.floor(mapPanel:getHeight() / 2 - barDistance - imageSizeThin) -
                                        distanceFromCenter)

                expCircleFront:setX(math.floor(mapPanel:getWidth() / 2 - imageSizeBroad / 2))
                expCircle:setY(math.floor(mapPanel:getHeight() / 2 - barDistance - imageSizeThin) - distanceFromCenter)
            end

            if isSkillCircle then
                skillCircleFront:setY(math.floor(mapPanel:getHeight() / 2 + barDistance) + distanceFromCenter)

                skillCircleFront:setX(math.floor(mapPanel:getWidth() / 2 - imageSizeBroad / 2))
                skillCircle:setY(math.floor(mapPanel:getHeight() / 2 + barDistance) + distanceFromCenter)
            end
        else
            local healthX = mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeThin - barDistance - distanceFromCenter
            local manaX = mapPanel:getX() + mapPanel:getWidth() / 2 + barDistance + distanceFromCenter

            healthCircleFront:setX(healthX)
            manaCircleFront:setX(manaX)

            healthCircle:setX(healthX)
            manaCircle:setX(manaX)

            local healthY = mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeBroad / 2
            healthCircle:setY(healthY)
            manaCircle:setY(healthY)

            if healthCircleExtra and healthCircleExtraFront then
                local extraHealthX = mapPanel:getX() + mapPanel:getWidth() / 2 - extraImageSizeThin - barDistance - distanceFromCenter
                local extraHealthY = mapPanel:getY() + mapPanel:getHeight() / 2 - extraImageSizeBroad / 2
                healthCircleExtra:setX(extraHealthX)
                healthCircleExtraFront:setX(extraHealthX)
                healthCircleExtra:setY(extraHealthY)
                healthCircleExtraFront:setY(extraHealthY)
            end

            if isExpCircle then
                expCircleFront:setY(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeThin - barDistance -
                                        distanceFromCenter)

                expCircleFront:setX(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeBroad / 2)
                expCircle:setY(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeThin - barDistance -
                                   distanceFromCenter)
            end

            if isSkillCircle then
                skillCircleFront:setY(mapPanel:getY() + mapPanel:getHeight() / 2 + barDistance + distanceFromCenter)

                skillCircleFront:setX(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeBroad / 2)
                skillCircle:setY(mapPanel:getY() + mapPanel:getHeight() / 2 + barDistance + distanceFromCenter)
            end
        end

        whenHealthChange()
        whenManaChange()
        if isExpCircle or isSkillCircle then
            whenSkillsChange()
        end
    end
end

-------------------------------------------------
-- Controls---------------------------------------
-------------------------------------------------

function setHealthCircle(value)
    value = toboolean(value)
    isHealthCircle = value
    if value then
        healthCircle:setVisible(true)
        healthCircleFront:setVisible(true)
        if healthCircleExtra and healthCircleExtraFront then
            healthCircleExtra:setVisible(true)
            healthCircleExtraFront:setVisible(true)
        end
        whenMapResizeChange()
    else
        healthCircle:setVisible(false)
        healthCircleFront:setVisible(false)
        if healthCircleExtra and healthCircleExtraFront then
            healthCircleExtra:setVisible(false)
            healthCircleExtraFront:setVisible(false)
        end
    end

    g_settings.set('healthcircle_hpcircle', not value)

    whenHealthChange()
end

function setManaCircle(value)
    value = toboolean(value)
    isManaCircle = value
    if value then
        manaCircle:setVisible(true)
        manaCircleFront:setVisible(true)
        whenMapResizeChange()
    else
        manaCircle:setVisible(false)
        manaCircleFront:setVisible(false)
    end

    g_settings.set('healthcircle_mpcircle', not value)
end

function setExpCircle(value)
    value = toboolean(value)
    isExpCircle = value

    if value then
        expCircle:setVisible(true)
        expCircleFront:setVisible(true)
        whenMapResizeChange()
    else
        expCircle:setVisible(false)
        expCircleFront:setVisible(false)
    end

    g_settings.set('healthcircle_expcircle', value)
end

function setSkillCircle(value)
    value = toboolean(value)
    isSkillCircle = value

    if value then
        skillCircle:setVisible(true)
        skillCircleFront:setVisible(true)
        whenMapResizeChange()
    else
        skillCircle:setVisible(false)
        skillCircleFront:setVisible(false)
    end

    g_settings.set('healthcircle_skillcircle', value)
end

function setSkillType(skill)
    if not skillsLoaded then
        return
    end

    local char = g_game.getCharacterName()
    local skillType = skillTypes[char]

    skillTypes[char] = skill
    whenMapResizeChange()
    g_settings.setNode('healthcircle_skilltypes', skillTypes)
end

function setDistanceFromCenter(value)
    distanceFromCenter = value
    whenMapResizeChange()

    g_settings.set('healthcircle_distfromcenter', value)
end

function setCircleOpacity(value)
    healthCircle:setOpacity(value)
    healthCircleFront:setOpacity(value)
    if healthCircleExtra and healthCircleExtraFront then
        healthCircleExtra:setOpacity(value)
        healthCircleExtraFront:setOpacity(value)
    end
    manaCircle:setOpacity(value)
    manaCircleFront:setOpacity(value)
    expCircle:setOpacity(value)
    expCircleFront:setOpacity(value)
    skillCircle:setOpacity(value)
    skillCircleFront:setOpacity(value)

    g_settings.set('healthcircle_opacity', value)
end

-------------------------------------------------
-- Option Settings--------------------------------
-------------------------------------------------

optionPanel = nil
healthCheckBox = nil
manaCheckBox = nil
experienceCheckBox = nil
skillCheckBox = nil
chooseSkillComboBox = nil
chooseStatsBarDimension = nil
chooseStatsBarPlacement = nil
distFromCenScrollbar = nil
opacityScrollbar = nil

function addToOptionsModule()
    -- Add to options module
    optionPanel = g_ui.loadUI('option_healthcircle',modules.client_options:getPanel())

    -- UI values
    healthCheckBox = optionPanel:recursiveGetChildById('healthCheckBox')
    manaCheckBox = optionPanel:recursiveGetChildById('manaCheckBox')
    experienceCheckBox = optionPanel:recursiveGetChildById('experienceCheckBox')
    skillCheckBox = optionPanel:recursiveGetChildById('skillCheckBox')
    chooseSkillComboBox = optionPanel:recursiveGetChildById('chooseSkillComboBox')
    chooseStatsBarDimension = optionPanel:recursiveGetChildById('chooseStatsBarDimension')
    chooseStatsBarPlacement = optionPanel:recursiveGetChildById('chooseStatsBarPlacement')
    distFromCenScrollbar = optionPanel:recursiveGetChildById('distFromCenScrollbar')
    opacityScrollbar = optionPanel:recursiveGetChildById('opacityScrollbar')

    -- ComboBox start values
    chooseSkillComboBox:addOption('Magic Level', 'magic')
    chooseSkillComboBox:addOption('Fist Fighting', 'fist')
    chooseSkillComboBox:addOption('Club Fighting', 'club')
    chooseSkillComboBox:addOption('Sword Fighting', 'sword')
    chooseSkillComboBox:addOption('Axe Fighting', 'axe')
    chooseSkillComboBox:addOption('Distance Fighting', 'distance')
    chooseSkillComboBox:addOption('Shielding', 'shielding')
    chooseSkillComboBox:addOption('Fishing', 'fishing')

    chooseStatsBarPlacement:addOption(tr('Top'), 'top')
    chooseStatsBarPlacement:addOption(tr('Bottom'), 'bottom')

    chooseStatsBarDimension:addOption(tr('Hide'), 'hide')
    chooseStatsBarDimension:addOption(tr('Compact'), 'compact')
    chooseStatsBarDimension:addOption(tr('Default'), 'default')
    chooseStatsBarDimension:addOption(tr('Large'), 'large')
    chooseStatsBarDimension:addOption(tr('Parallel'), 'parallel')

    statsBarMenuLoaded = true

    chooseStatsBarDimension:setCurrentOptionByData(g_settings.getString('statsbar_dimension'), true)
    chooseStatsBarPlacement:setCurrentOptionByData(g_settings.getString('statsbar_placement'), true)

    -- Set values
    healthCheckBox:setChecked(isHealthCircle)
    manaCheckBox:setChecked(isManaCircle)
    experienceCheckBox:setChecked(isExpCircle)
    skillCheckBox:setChecked(isSkillCircle)

    -- Prevent skill overwritten before initialize
    skillsLoaded = true

    distFromCenScrollbar:setText(tr('Distance') .. ': ' .. distanceFromCenter)
    distFromCenScrollbar:setValue(distanceFromCenter)
    opacityScrollbar:setText(tr('Opacity') .. ': ' .. opacityCircle)
    opacityScrollbar:setValue(opacityCircle * 100)
    modules.client_options.addButton("Interface", "HP/MP Circle", optionPanel)
end

function updateStatsBar()
    if statsBarMenuLoaded then
        modules.game_interface.updateStatsBar(chooseStatsBarDimension:getCurrentOption().data, chooseStatsBarPlacement:getCurrentOption().data)
    end
end

function setPlayerValues()
    local skillType = skillTypes[g_game.getCharacterName()]
    if not skillType then
        skillType = 'magic'
    end
    chooseSkillComboBox:setCurrentOptionByData(skillType, true)
end

function setStatsBarOption(dimension, placement)
    chooseStatsBarDimension:setCurrentOptionByData(dimension, true)
    chooseStatsBarPlacement:setCurrentOptionByData(placement, true)
end

function destroyOptionsModule()
    healthCheckBox = nil
    manaCheckBox = nil
    experienceCheckBox = nil
    skillCheckBox = nil
    chooseSkillComboBox = nil
    distFromCenScrollbar = nil
    opacityScrollbar = nil
    chooseStatsBarDimension = nil
    chooseStatsBarPlacement = nil

    modules.client_options.removeButton("Interface", "HP/MP Circle")
    optionPanel = nil
end
