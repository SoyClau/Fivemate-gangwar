-- ========================================
-- GESTIÓN DE ZONAS VISUALES
-- ========================================

local activeZone = nil
local visualThread = nil
local timerThread = nil
local timerActive = false
local blueZone = nil
local currentGangWarData = nil -- Variable global para almacenar datos actualizados

-- ========================================
-- FUNCIONES DE TIMER
-- ========================================

--- Detener contador de tiempo
local function stopGangWarTimer()
    timerActive = false
    if timerThread then
        timerThread = nil
    end
    lib.hideTextUI()
end

--- Iniciar contador de tiempo
--- @param gangWarData table
local function startGangWarTimer(gangWarData)
    if timerActive then
        stopGangWarTimer()
    end
    
    local zoneSettings = Config.ZoneSettings[Config.ZoneType]
    if not zoneSettings or not zoneSettings.showTimer then
        return
    end
    
    timerActive = true
    
    timerThread = CreateThread(function()
        while timerActive and activeZone do
            -- Usar datos actualizados globalmente
            local currentData = currentGangWarData or gangWarData
            
            -- USAR EL TIEMPO CONFIGURADO DEL GANG WAR, NO EL FIJO DEL CONFIG
            local gangWarDuration = currentData.duration or Config.AutoEndTime
            local timeElapsed = math.floor((GetGameTimer() - currentData.startTime) / 60000) -- en minutos
            local timeRemaining = gangWarDuration - timeElapsed
            
            if timeRemaining > 0 and not currentData.canPoliceEnter then
                -- Zona roja - mostrar tiempo restante
                local minutes = math.floor(timeRemaining)
                local seconds = math.floor(((gangWarDuration * 60) - (GetGameTimer() - currentData.startTime) / 1000) % 60)
                
                -- Asegurar que no sean negativos
                minutes = math.max(0, minutes)
                seconds = math.max(0, seconds)

                local timerText = string.format(
                    '🔴 **GANG WAR ACTIVO**  \n⏱️ Tiempo restante: **%02d:%02d**  \n🚫 Zona restringida para policía',
                    minutes,
                    seconds
                )
                
                lib.showTextUI(timerText, {
                    position = "top-center",
                    icon = 'clock',
                    style = {
                        borderRadius = 8,
                        backgroundColor = '#dc2626',
                        color = 'white'
                    }
                })

            elseif currentData.canPoliceEnter then
                -- Zona azul - policía puede entrar
                -- SIEMPRE empezar desde Config.BlueZoneTime completo
                local blueStartTime = currentData.endTime or (currentData.startTime + gangWarDuration * 60000)
                local blueTimeElapsed = math.floor((GetGameTimer() - blueStartTime) / 60000)
                local blueTimeRemaining = Config.BlueZoneTime - blueTimeElapsed
                
                if blueTimeRemaining > 0 then
                    local blueMinutes = math.floor(blueTimeRemaining)
                    local blueSeconds = math.floor(((Config.BlueZoneTime * 60) - (GetGameTimer() - blueStartTime) / 1000) % 60)
                    
                    -- Asegurar que no sean negativos
                    blueMinutes = math.max(0, blueMinutes)
                    blueSeconds = math.max(0, blueSeconds)
                    
                    local blueTimerText = string.format(
                        '🔵 **ZONA LIBRE**  \n✅ Policía autorizada  \n⏱️ Desaparece en: **%02d:%02d**',
                        blueMinutes,
                        blueSeconds
                    )
                    
                    lib.showTextUI(blueTimerText, {
                        position = "top-center",
                        icon = 'shield-check',
                        style = {
                            borderRadius = 8,
                            backgroundColor = '#2563eb',
                            color = 'white'
                        }
                    })
                else
                    -- Tiempo agotado
                    lib.hideTextUI()
                    timerActive = false
                end
            else
                -- Tiempo agotado pero no es azul aún
                lib.hideTextUI()
                timerActive = false
            end
            
            Wait(1000) -- Actualizar cada segundo
        end
        
        lib.hideTextUI()
        timerActive = false
    end)
end

--- Iniciar timer solo cuando entra a la zona
--- @param gangWarData table
local function startTimerOnEnter(gangWarData)
    local zoneSettings = Config.ZoneSettings[Config.ZoneType]
    if zoneSettings and zoneSettings.showTimer then
        startGangWarTimer(gangWarData)
    end
end

--- Detener timer cuando sale de la zona
local function stopTimerOnExit()
    stopGangWarTimer()
end

-- ========================================
-- FUNCIONES DE EFECTOS
-- ========================================

--- Crear efectos de partículas según configuración
--- @param coords vector3
local function createZoneEffects(coords)
    local zoneSettings = Config.ZoneSettings[Config.ZoneType]
    
    if not zoneSettings or not zoneSettings.effects then
        return -- No crear efectos si no están habilitados
    end
    
    CreateThread(function()
        while activeZone do
            Wait(10000) -- Cada 10 segundos
            
            -- Efectos simples de humo en el perímetro
            for i = 1, 8 do
                if not activeZone then break end -- Verificar si aún existe
                
                local angle = (i / 8) * 2 * math.pi
                local offsetX = math.cos(angle) * (Config.ZoneRadius - 15)
                local offsetY = math.sin(angle) * (Config.ZoneRadius - 15)
                
                local effectCoords = vector3(
                    coords.x + offsetX,
                    coords.y + offsetY,
                    coords.z + math.random(2, 8)
                )
                
                -- Efecto de humo
                RequestNamedPtfxAsset("core")
                while not HasNamedPtfxAssetLoaded("core") do
                    Wait(1)
                end
                
                UseParticleFxAssetNextCall("core")
                StartParticleFxNonLoopedAtCoord(
                    "exp_grd_bzgas_smoke",
                    effectCoords.x, effectCoords.y, effectCoords.z,
                    0.0, 0.0, 0.0,
                    0.2, false, false, false
                )
                
                Wait(300)
            end
        end
    end)
end

-- ========================================
-- FUNCIONES DE VISUALIZACIÓN
-- ========================================

--- Crear visualización de la zona
--- @param coords vector3
--- @param gangWarData table
local function createZoneVisuals(coords, gangWarData)
    if visualThread then
        return
    end
    
    local zoneSettings = Config.ZoneSettings[Config.ZoneType]
    
    if not zoneSettings then
        print('[GangWar] Error: Tipo de zona no válido:', Config.ZoneType)
        return
    end
    
    -- Si es tipo minimal y solo quiere blip, no crear visualización
    if zoneSettings.onlyBlip then
        return
    end
    
    visualThread = CreateThread(function()
        while activeZone do
            Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - coords)
            
            if distance < 400.0 then
                -- Usar datos actualizados globalmente
                local currentData = currentGangWarData or gangWarData
                local color = currentData.canPoliceEnter and Config.ZoneColors.ending or Config.ZoneColors.active
                
                -- RENDERIZAR SOLO UNA ZONA SEGÚN EL TIPO
                if Config.ZoneType == 'simple' then
                    -- Cilindro que va desde bajo tierra hasta muy arriba
                    DrawMarker(
                        1, -- Cilindro
                        coords.x, coords.y, coords.z - zoneSettings.underground, -- Empezar bajo tierra
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.ZoneRadius * 2.0, Config.ZoneRadius * 2.0, zoneSettings.height + zoneSettings.underground, -- Altura total
                        color.r, color.g, color.b, color.a,
                        false, true, 2, false, nil, nil, false
                    )
                    
                elseif Config.ZoneType == 'minimal' then
                    -- SOLO un cilindro muy bajo
                    DrawMarker(
                        1, -- Cilindro muy bajo
                        coords.x, coords.y, coords.z - 0.5,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.ZoneRadius * 2.0, Config.ZoneRadius * 2.0, zoneSettings.height,
                        color.r, color.g, color.b, 120,
                        false, true, 2, false, nil, nil, false
                    )
                    
                elseif Config.ZoneType == 'dome' then
                    -- SOLO un domo/corona
                    DrawMarker(
                        28, -- Corona/domo
                        coords.x, coords.y, coords.z + 25.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.ZoneRadius * 2.0, Config.ZoneRadius * 2.0, zoneSettings.height,
                        color.r, color.g, color.b, 120,
                        false, true, 2, false, nil, nil, false
                    )
                    
                elseif Config.ZoneType == 'advanced' then
                    -- Cilindro base
                    DrawMarker(
                        1, -- Cilindro base
                        coords.x, coords.y, coords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.ZoneRadius * 2.0, Config.ZoneRadius * 2.0, zoneSettings.height,
                        color.r, color.g, color.b, color.a,
                        false, true, 2, false, nil, nil, false
                    )
                    
                    -- Círculo pulsante encima (SOLO para advanced)
                    if zoneSettings.pulseEffect then
                        local pulseTime = (GetGameTimer() % 3000) / 3000.0
                        local pulseScale = 1.0 + math.sin(pulseTime * math.pi * 2) * 0.1
                        local pulseAlpha = 40 + math.sin(pulseTime * math.pi * 2) * 20
                        
                        DrawMarker(
                            25, -- Círculo pulsante
                            coords.x, coords.y, coords.z + zoneSettings.height + 5,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            Config.ZoneRadius * 2.1 * pulseScale, Config.ZoneRadius * 2.1 * pulseScale, Config.ZoneRadius * 2.1 * pulseScale,
                            color.r, color.g, color.b, pulseAlpha,
                            false, true, 2, false, nil, nil, false
                        )
                    end
                    
                elseif Config.ZoneType == 'columns' then
                    -- Base pequeña
                    DrawMarker(
                        1, -- Cilindro base
                        coords.x, coords.y, coords.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.ZoneRadius * 2.0, Config.ZoneRadius * 2.0, 5.0,
                        color.r, color.g, color.b, color.a,
                        false, true, 2, false, nil, nil, false
                    )
                    
                    -- Columnas SOLO si está cerca (para performance)
                    if distance < 150.0 then
                        for i = 1, zoneSettings.columnCount do
                            local angle = (i / zoneSettings.columnCount) * 2 * math.pi
                            local offsetX = math.cos(angle) * (Config.ZoneRadius - 5)
                            local offsetY = math.sin(angle) * (Config.ZoneRadius - 5)
                            
                            DrawMarker(
                                1, -- Cilindro vertical
                                coords.x + offsetX, coords.y + offsetY, coords.z,
                                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                2.0, 2.0, zoneSettings.columnHeight,
                                color.r, color.g, color.b, 150,
                                false, true, 2, false, nil, nil, false
                            )
                        end
                    end
                    
                -- NUEVO: ox_lib default (usa la visualización por defecto)
                elseif Config.ZoneType == 'oxlib' then
                    -- Para ox_lib, solo mostrar texto si está configurado
                    -- La visualización esférica la maneja ox_lib automáticamente con debug=true
                    -- No dibujar ningún marker personalizado
                    
                end
                -- FIN de los tipos - NO MÁS DrawMarker después de esto
                
                -- Mostrar texto SOLO si está configurado y cerca
                if zoneSettings.showText and distance < zoneSettings.textDistance then
                    local text = currentData.canPoliceEnter and '~b~ZONA LIBRE~w~\nPolicia puede intervenir' or '~r~GANG WAR ACTIVO~w~\nZona restringida'
                    
                    SetTextFont(4)
                    SetTextProportional(1)
                    SetTextScale(0.0, 0.6)
                    SetTextColour(255, 255, 255, 255)
                    SetTextDropshadow(0, 0, 0, 0, 255)
                    SetTextEdge(2, 0, 0, 0, 150)
                    SetTextDropShadow()
                    SetTextOutline()
                    SetTextCentre(1)
                    SetTextEntry("STRING")
                    AddTextComponentString(text)
                    SetDrawOrigin(coords.x, coords.y, coords.z + (zoneSettings.height or 15), 0)
                    DrawText(0.0, 0.0)
                    ClearDrawOrigin()
                end
            else
                Wait(1000)
            end
        end
        
        visualThread = nil
    end)
end

--- Crear zona azul adicional para oxlib
--- @param coords vector3
local function createBlueZone(coords)
    if blueZone then
        blueZone:remove()
    end
    
    -- Crear segunda zona ligeramente más grande y azul
    blueZone = lib.zones.sphere({
        coords = coords,
        radius = Config.ZoneRadius + 5, -- Ligeramente más grande
        debug = true,
        -- Sin callbacks, solo visual
    })
end

-- ========================================
-- FUNCIONES PRINCIPALES
-- ========================================

--- Crear zona visual para el gang war
--- @param gangWarData table
local function createZone(gangWarData)
    if activeZone then
        removeZone()
    end
    
    local coords = vector3(gangWarData.coords.x, gangWarData.coords.y, gangWarData.coords.z)
    local zoneSettings = Config.ZoneSettings[Config.ZoneType]
    
    -- Almacenar datos globalmente para actualizaciones
    currentGangWarData = gangWarData
        
    -- Para tipo oxlib, determinar color según estado
    local useDebug = false
    if Config.ZoneType == 'oxlib' then
        useDebug = true -- Siempre mostrar para oxlib
    else
        useDebug = Config.Debug
    end
    
    -- Crear zona usando ox_lib
    activeZone = lib.zones.sphere({
        coords = coords,
        radius = Config.ZoneRadius,
        debug = useDebug,
        onEnter = function()
            lib.notify({
                title = Config.NotificationTitle,
                description = Locale.notifications.zone_entered,
                type = 'inform'
            })
            TriggerEvent('gangwar:client:enteredZone', gangWarData)
            
            -- Iniciar timer SOLO cuando entra a la zona
            startTimerOnEnter(currentGangWarData or gangWarData)
        end,
        onExit = function()
            lib.notify({
                title = Config.NotificationTitle,
                description = Locale.notifications.zone_exited,
                type = 'inform'
            })
            TriggerEvent('gangwar:client:exitedZone')
            
            -- Detener timer cuando sale de la zona
            stopTimerOnExit()
        end
    })
    
    -- Si es tipo oxlib, crear zona azul adicional cuando sea necesario
    if Config.ZoneType == 'oxlib' and gangWarData.canPoliceEnter then
        createBlueZone(coords)
    end
    
    -- Si NO es tipo oxlib, crear visualización personalizada
    if Config.ZoneType ~= 'oxlib' then
        createZoneVisuals(coords, gangWarData)
    end
    
    -- Crear efectos SOLO si están habilitados
    if zoneSettings and zoneSettings.effects then
        createZoneEffects(coords)
    end
    
    -- NO iniciar timer automáticamente - solo cuando entre a la zona
    
    if Config.Debug then
        print('[GangWar] Zona creada en:', coords, '| Tipo:', Config.ZoneType, '| Estado:', gangWarData.canPoliceEnter and 'azul' or 'rojo')
    end
end

--- Remover zona activa
local function removeZone()
    if activeZone then
        activeZone:remove()
        activeZone = nil
    end
    
    if blueZone then
        blueZone:remove()
        blueZone = nil
    end
    
    if visualThread then
        -- El thread se detendrá automáticamente cuando activeZone sea nil
    end
    
    -- Limpiar datos globales
    currentGangWarData = nil
        
    -- Detener timer
    stopGangWarTimer()
    
    if Config.Debug then
        print('[GangWar] Zona removida')
    end
end

--- Actualizar color de la zona
--- @param canPoliceEnter boolean
--- @param additionalData table|nil
local function updateZoneColor(canPoliceEnter, additionalData)
    if activeZone then
        -- Actualizar datos globales para que el thread de visualización use el nuevo estado
        if currentGangWarData then
            currentGangWarData.canPoliceEnter = canPoliceEnter
            
            -- Aplicar datos adicionales si se proporcionan
            if additionalData then
                if additionalData.manuallyEnded then
                    currentGangWarData.manuallyEnded = true
                    currentGangWarData.endTime = additionalData.endTime
                end
            end
        end
        
        -- Para oxlib, crear zona azul cuando sea necesario
        if Config.ZoneType == 'oxlib' and canPoliceEnter then
            local coords = vector3(activeZone.coords.x, activeZone.coords.y, activeZone.coords.z)
            createBlueZone(coords)
        elseif Config.ZoneType == 'oxlib' and not canPoliceEnter and blueZone then
            blueZone:remove()
            blueZone = nil
        end
        
        if Config.Debug then
            print('[GangWar] Color de zona actualizado:', canPoliceEnter and 'azul' or 'rojo')
            if additionalData and additionalData.manuallyEnded then
                print('[GangWar] Finalización manual detectada')
            end
        end
    end
end

-- ========================================
-- EXPORTS
-- ========================================

exports('createZone', createZone)
exports('removeZone', removeZone)
exports('updateZoneColor', updateZoneColor)
exports('createZoneEffects', createZoneEffects)
exports('startGangWarTimer', startGangWarTimer)
exports('stopGangWarTimer', stopGangWarTimer)
exports('startTimerOnEnter', startTimerOnEnter)
exports('stopTimerOnExit', stopTimerOnExit)