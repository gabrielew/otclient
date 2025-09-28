imageSizeBroad = 0
imageSizeThin = 0

mapPanel = modules.game_interface.getMapPanel()
gameRootPanel = modules.game_interface.gameBottomPanel
gameLeftPanel = modules.game_interface.getLeftPanel()
gameTopMenu = modules.client_topmenu.getTopMenu()

function currentViewMode()
    return modules.game_interface.currentViewMode
end

healthCircle = nil
manaCircle = nil
manaShieldCircle = nil
expCircle = nil
skillCircle = nil

healthCircleFront = nil
manaCircleFront = nil
manaShieldCircleFront = nil
expCircleFront = nil
skillCircleFront = nil


healthCircleExtra = nil
healthCircleExtraFront = nil

extraImageSizeBroad = 0
extraImageSizeThin = 0
manaShieldImageSizeBroad = 0
manaShieldImageSizeThin = 0

extraCircleOffsetX = -60
extraCircleOffsetY = 8
manaShieldCircleOffsetX = -62
manaShieldCircleOffsetY = 7

healthCircleVirtue = nil
virtueOffsetX = -42
virtueOffsetY = 105
virtueImageSizeBroad = 0
virtueImageSizeThin = 0

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

monkCircleOffsetLeft = g_settings.getNumber('healthcircle_monkcircle_offset_left', 0)
monkCircleOffsetRight = g_settings.getNumber('healthcircle_monkcircle_offset_right', -65)

function init()
    g_ui.importStyle("game_healthcircle.otui")
    healthCircle = g_ui.createWidget('HealthCircle', mapPanel)
    healthCircleExtra = g_ui.createWidget('HealthCircleExtra', mapPanel)
    manaCircle = g_ui.createWidget('ManaCircle', mapPanel)
    manaShieldCircle = g_ui.createWidget('ManaShieldCircle', mapPanel)
    expCircle = g_ui.createWidget('ExpCircle', mapPanel)
    skillCircle = g_ui.createWidget('SkillCircle', mapPanel)

    healthCircleFront = g_ui.createWidget('HealthCircleFront', mapPanel)
    healthCircleExtraFront = g_ui.createWidget('HealthCircleExtraFront', mapPanel)
    -- Ensure the harmony circle uses the expected tint before the first update
    healthCircleExtraFront:setImageColor('#BE713E')
    healthCircleVirtue = g_ui.createWidget('HealthCircleVirtue', mapPanel)
    manaCircleFront = g_ui.createWidget('ManaCircleFront', mapPanel)
    manaShieldCircleFront = g_ui.createWidget('ManaShieldCircleFront', mapPanel)
    expCircleFront = g_ui.createWidget('ExpCircleFront', mapPanel)
    skillCircleFront = g_ui.createWidget('SkillCircleFront', mapPanel)

    imageSizeBroad = healthCircle:getHeight()
    imageSizeThin = healthCircle:getWidth()
    extraImageSizeBroad = healthCircleExtra:getHeight()
    extraImageSizeThin = healthCircleExtra:getWidth()
    manaShieldImageSizeBroad = manaShieldCircle:getHeight()
    manaShieldImageSizeThin = manaShieldCircle:getWidth()

    manaShieldCircle:setVisible(false)
    manaShieldCircleFront:setVisible(false)
    virtueImageSizeBroad = healthCircleVirtue:getHeight()
    virtueImageSizeThin = healthCircleVirtue:getWidth()

    whenMapResizeChange()
    initOnHpAndMpChange()
    initOnGeometryChange()
    initOnLoginChange()

    if not isHealthCircle then
        healthCircle:setVisible(false)
        healthCircleFront:setVisible(false)
        healthCircleExtra:setVisible(false)
        healthCircleExtraFront:setVisible(false)
        healthCircleVirtue:setVisible(false)
    end

    if not isManaCircle then
        manaCircle:setVisible(false)
        manaCircleFront:setVisible(false)
        manaShieldCircle:setVisible(false)
        manaShieldCircleFront:setVisible(false)
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
    manaCircle:destroy()
    manaCircle = nil
    manaShieldCircle:destroy()
    manaShieldCircle = nil
    expCircle:destroy()
    expCircle = nil
    skillCircle:destroy()
    skillCircle = nil

    healthCircleFront:destroy()
    healthCircleFront = nil
    healthCircleExtra:destroy()
    healthCircleExtra = nil
    healthCircleExtraFront:destroy()
    healthCircleExtraFront = nil
    healthCircleVirtue:destroy()
    healthCircleVirtue = nil
    manaCircleFront:destroy()
    manaCircleFront = nil
    manaShieldCircleFront:destroy()
    manaShieldCircleFront = nil
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
        onHarmonyChange = whenHarmonyChange,
        onManaChange = whenManaChange,
        onManaShieldChange = whenManaShieldChange,
        onSkillChange = whenSkillsChange,
        onMagicLevelChange = whenSkillsChange,
        onLevelChange = whenSkillsChange,
        onVocationChange = whenVocationChange
    })
end

function terminateOnHpAndMpChange()
    disconnect(LocalPlayer, {
        onHealthChange = whenHealthChange,
        onHarmonyChange = whenHarmonyChange,
        onManaChange = whenManaChange,
        onManaShieldChange = whenManaShieldChange,
        onSkillChange = whenSkillsChange,
        onMagicLevelChange = whenSkillsChange,
        onLevelChange = whenSkillsChange,
        onVocationChange = whenVocationChange
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
        onGameStart = onHealthCircleGameStart,
        onVirtueProtocol = onVirtueProtocol,
        onSereneProtocol = onSereneProtocol,
        onHarmonyProtocol = onHarmonyProtocol,
    })
end

function terminateOnLoginChange()
    disconnect(g_game, {
        onGameStart = onHealthCircleGameStart,
        onVirtueProtocol = onVirtueProtocol,
        onSereneProtocol = onSereneProtocol,
        onHarmonyProtocol = onHarmonyProtocol,
    })
end

function onHealthCircleGameStart()
    whenMapResizeChange()
    whenHarmonyChange()
    whenManaShieldChange()
end

function whenHealthChange()
    if g_game.isOnline() then
        -- Fix By TheMaoci ~ if your server doesn't have this properly implemented,
        -- it will cause alot of unnecessary deaths from players which will be unfair.
        -- My friend reported me that while he was using his otcv8 and asked for a fix so here you go :)
        local healthPercent = math.floor(g_game.getLocalPlayer():getHealth() / g_game.getLocalPlayer():getMaxHealth() *
            100)
        -- Old leaved for ppl who have that implemented correctly
        --local healthPercent = math.floor(g_game.getLocalPlayer():getHealthPercent())

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

function whenHarmonyChange()
    if g_game.isOnline() then
        local player = g_game.getLocalPlayer()
        local harmony = player:getHarmony()
        local maxSquares = 5
        if harmony < 0 then harmony = 0 end
        if harmony > maxSquares then harmony = maxSquares end
        local squareSize = extraImageSizeBroad / maxSquares

        -- pixels "preenchidos" devem ser múltiplos exatos de squareSize
        -- arredonda para o inteiro mais próximo de pixel p/ evitar serrilhado
        local filledPixels = math.floor(harmony * squareSize + 0.5)
        if filledPixels > extraImageSizeBroad then
            filledPixels = extraImageSizeBroad
        end

        local yhppcExtra = extraImageSizeBroad - filledPixels -- parte vazia (em cima)

        local restYhppcExtra = filledPixels                   -- parte preenchida (em baixo)

        healthCircleExtraFront:setX(healthCircleExtra:getX())
        healthCircleExtraFront:setY(healthCircleExtra:getY() + yhppcExtra)
        healthCircleExtraFront:setHeight(restYhppcExtra)

        healthCircleExtraFront:setImageClip({
            x = 0,
            y = yhppcExtra,
            width = extraImageSizeThin,
            height = restYhppcExtra
        })

        healthCircleExtra:setHeight(yhppcExtra)
        healthCircleExtra:setImageClip({
            x = 0,
            y = 0,
            width = extraImageSizeThin,
            height = yhppcExtra
        })

        healthCircleExtraFront:setImageColor('#BE713E')
    end
end

local defaultManaCircleEmpty = '/data/images/game/healthcircle/right_empty'
local defaultManaCircleFull = '/data/images/game/healthcircle/right_full'
local defaultManaWithManaShieldCircleEmpty = '/data/images/game/healthcircle/right_empty_test'
local defaultManaWithManaShieldCircleFull = '/data/images/game/healthcircle/right_full_test'
local manaShieldManaCircleEmpty = '/data/images/game/healthcircle/right_extra_empty'
local manaShieldManaCircleFull = '/data/images/game/healthcircle/right_extra_full'

local function resetManaCircleImages()
    if manaCircle then
        manaCircle:setImageSource(defaultManaCircleEmpty)
    end

    if manaCircleFront then
        manaCircleFront:setImageSource(defaultManaCircleFull)
    end
end

local function updateManaShieldDisplay()
    if not manaShieldCircle or not manaShieldCircleFront or not manaCircle or not manaCircleFront then
        return
    end

    if not g_game.isOnline() or not isManaCircle then
        manaShieldCircle:setVisible(false)
        manaShieldCircleFront:setVisible(false)
        resetManaCircleImages()
        return
    end

    local player = g_game.getLocalPlayer()
    if not player then
        return
    end

    local maxShield = player:getMaxManaShield()
    local remainingShield = player:getManaShield()

    if remainingShield <= 0 then
        manaShieldCircle:setVisible(false)
        manaShieldCircleFront:setVisible(false)
        resetManaCircleImages()
        return
    end

    if maxShield <= 0 then
        maxShield = remainingShield
    end

    manaCircle:setImageSource(defaultManaWithManaShieldCircleEmpty)
    manaCircleFront:setImageSource(defaultManaWithManaShieldCircleFull)
    manaShieldCircle:setImageSource(manaShieldManaCircleEmpty)
    manaShieldCircleFront:setImageSource(manaShieldManaCircleFull)
    manaShieldCircle:setVisible(true)
    manaShieldCircleFront:setVisible(true)

    local clampedShield = math.max(math.min(remainingShield, maxShield), 0)
    local shieldPercent = clampedShield / maxShield

    local emptyPixels = math.floor(manaShieldImageSizeBroad * (1 - shieldPercent))
    if emptyPixels < 0 then
        emptyPixels = 0
    end
    if emptyPixels > manaShieldImageSizeBroad then
        emptyPixels = manaShieldImageSizeBroad
    end

    local filledPixels = manaShieldImageSizeBroad - emptyPixels

    manaShieldCircleFront:setY(manaShieldCircle:getY() + emptyPixels)
    manaShieldCircleFront:setHeight(filledPixels)
    manaShieldCircleFront:setImageClip({
        x = 0,
        y = emptyPixels,
        width = manaShieldImageSizeThin,
        height = filledPixels
    })

    manaShieldCircle:setHeight(emptyPixels)
    manaShieldCircle:setImageClip({
        x = 0,
        y = 0,
        width = manaShieldImageSizeThin,
        height = emptyPixels
    })
end

function whenManaShieldChange()
    updateManaShieldDisplay()
end

function whenVocationChange()
    updateManaShieldDisplay()
end

function whenManaChange()
    if g_game.isOnline() then
        local player = g_game.getLocalPlayer()
        local maxMana = player:getMaxMana()
        if maxMana <= 0 then
            manaCircle:setVisible(false)
            manaCircleFront:setVisible(false)
            if manaShieldCircle and manaShieldCircleFront then
                manaShieldCircle:setVisible(false)
                manaShieldCircleFront:setVisible(false)
            end
            resetManaCircleImages()
            return
        elseif isManaCircle then
            manaCircle:setVisible(true)
            manaCircleFront:setVisible(true)
        end

        updateManaShieldDisplay()

        local manaPercent = math.floor(maxMana - (maxMana - player:getMana())) * 100 / maxMana

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
    local barDistance = 90
    if not (math.floor(mapPanel:getHeight() / 2 * 0.2) < 100) then -- 0.381
        barDistance = math.floor(mapPanel:getHeight() / 2 * 0.2)
    end

    if currentViewMode() == 2 then
        healthCircleFront:setX(math.floor(mapPanel:getWidth() / 2 - barDistance - imageSizeThin) -
            distanceFromCenter)
        manaCircleFront:setX(math.floor(mapPanel:getWidth() / 2 + barDistance) + distanceFromCenter)

        healthCircle:setX(math.floor(mapPanel:getWidth() / 2 - barDistance - imageSizeThin) - distanceFromCenter)
        manaCircle:setX(math.floor((mapPanel:getWidth() / 2 + barDistance)) + distanceFromCenter)

        if manaShieldCircle and manaShieldCircleFront then
            manaShieldCircle:setX(manaCircle:getX() - manaShieldImageSizeThin - manaShieldCircleOffsetX)
            manaShieldCircleFront:setX(manaShieldCircle:getX())
        end

        healthCircleExtra:setX(healthCircle:getX() + imageSizeThin + extraCircleOffsetX)
        healthCircleExtraFront:setX(healthCircleExtra:getX())
        healthCircleVirtue:setX(healthCircleExtra:getX() + extraImageSizeThin + virtueOffsetX)
        healthCircle:setY(mapPanel:getHeight() / 2 - imageSizeBroad / 2 + 0)
        manaCircle:setY(mapPanel:getHeight() / 2 - imageSizeBroad / 2 + 0)

        if manaShieldCircle and manaShieldCircleFront then
            manaShieldCircle:setY(manaCircle:getY() + manaShieldCircleOffsetY)
            manaShieldCircleFront:setY(manaShieldCircle:getY())
        end
        healthCircleExtra:setY(healthCircle:getY() + extraCircleOffsetY)
        healthCircleExtraFront:setY(healthCircleExtra:getY())
        healthCircleVirtue:setY(healthCircleExtra:getY() + virtueOffsetY)

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
        healthCircleFront:setX(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeThin - barDistance -
            distanceFromCenter)
        manaCircleFront:setX(mapPanel:getX() + mapPanel:getWidth() / 2 + barDistance + distanceFromCenter)

        healthCircle:setX(mapPanel:getX() + mapPanel:getWidth() / 2 - imageSizeThin - barDistance -
            distanceFromCenter)
        manaCircle:setX(mapPanel:getX() + mapPanel:getWidth() / 2 + barDistance + distanceFromCenter)

        if manaShieldCircle and manaShieldCircleFront then
            manaShieldCircle:setX(manaCircle:getX() - manaShieldImageSizeThin - manaShieldCircleOffsetX)
            manaShieldCircleFront:setX(manaShieldCircle:getX())
        end

        healthCircleExtra:setX(healthCircle:getX() + imageSizeThin + extraCircleOffsetX)
        healthCircleExtraFront:setX(healthCircleExtra:getX())
        healthCircleVirtue:setX(healthCircleExtra:getX() + extraImageSizeThin + virtueOffsetX)

        healthCircle:setY(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeBroad / 2)
        manaCircle:setY(mapPanel:getY() + mapPanel:getHeight() / 2 - imageSizeBroad / 2)

        if manaShieldCircle and manaShieldCircleFront then
            manaShieldCircle:setY(manaCircle:getY() + manaShieldCircleOffsetY)
            manaShieldCircleFront:setY(manaShieldCircle:getY())
        end
        healthCircleExtra:setY(healthCircle:getY() + extraCircleOffsetY)
        healthCircleExtraFront:setY(healthCircleExtra:getY())
        healthCircleVirtue:setY(healthCircleExtra:getY() + virtueOffsetY)

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

    if g_game.isOnline() then
        whenHealthChange()
        whenHarmonyChange()
        whenManaChange()
        if isExpCircle or isSkillCircle then
            whenSkillsChange()
        end
    end

    updateManaShieldDisplay()
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
        healthCircleExtra:setVisible(true)
        healthCircleExtraFront:setVisible(true)
        healthCircleVirtue:setVisible(true)
        whenMapResizeChange()
    else
        healthCircle:setVisible(false)
        healthCircleFront:setVisible(false)
        healthCircleExtra:setVisible(false)
        healthCircleExtraFront:setVisible(false)
        healthCircleVirtue:setVisible(false)
    end

    g_settings.set('healthcircle_hpcircle', not value)
end

function setManaCircle(value)
    value = toboolean(value)
    isManaCircle = value
    if value then
        manaCircle:setVisible(true)
        manaCircleFront:setVisible(true)
        whenMapResizeChange()
        updateManaShieldDisplay()
    else
        manaCircle:setVisible(false)
        manaCircleFront:setVisible(false)
        if manaShieldCircle and manaShieldCircleFront then
            manaShieldCircle:setVisible(false)
            manaShieldCircleFront:setVisible(false)
        end
        resetManaCircleImages()
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

function setMonkCircleSide(side)
    if side ~= 'left' and side ~= 'right' then return end
    monkCircleSide = side
    whenMapResizeChange()
    g_settings.set('healthcircle_monkcircle_side', side)
end

function setMonkCircleOffsetLeft(value)
    monkCircleOffsetLeft = value
    whenMapResizeChange()
    g_settings.set('healthcircle_monkcircle_offset_left', value)
end

function setMonkCircleOffsetRight(value)
    monkCircleOffsetRight = value
    whenMapResizeChange()
    g_settings.set('healthcircle_monkcircle_offset_right', value)
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
    healthCircleExtra:setOpacity(value)
    healthCircleExtraFront:setOpacity(value)
    healthCircleVirtue:setOpacity(value)
    manaCircle:setOpacity(value)
    manaCircleFront:setOpacity(value)
    if manaShieldCircle then
        manaShieldCircle:setOpacity(value)
    end
    if manaShieldCircleFront then
        manaShieldCircleFront:setOpacity(value)
    end
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
    optionPanel = g_ui.loadUI('option_healthcircle', modules.client_options:getPanel())

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
        modules.game_interface.updateStatsBar(chooseStatsBarDimension:getCurrentOption().data,
            chooseStatsBarPlacement:getCurrentOption().data)
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

function onVirtueProtocol(test)
    print("onVirtueProtocol", test)
end

function onSereneProtocol(test)
    print("onSereneProtocol", test)
end

function onHarmonyProtocol(test)
    print("onHarmonyProtocol", test)
end
