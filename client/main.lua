-- ========================================
-- CLIENT/MAIN.LUA - VERSIÓN FINAL LIMPIA
-- ========================================

local ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local currentGangWar = nil
local isInZone = false
local isFinalizingGangWar = false -- NUEVO: Control de finalización

-- Variables para zona visual (UNA SOLA IMPLEMENTACIÓN)
local activeZone = nil
local zoneBlip = nil
local visualThread = nil

-- ========================================
-- FUNCIONES DE ZONA VISUAL (UNIFICADA)
-- ========================================

local function removeGangWarZone()
    print('[GangWar] Removiendo zona visual...')
    
    lib.hideTextUI()
    
    if visualThread then
        visualThread = nil
    end
    
    if zoneBlip and DoesBlipExist(zoneBlip) then
        RemoveBlip(zoneBlip)
        zoneBlip = nil
    end
    
    if activeZone then
        activeZone:remove()
        activeZone = nil
    end
    
    isInZone = false
    print('[GangWar] Zona visual completamente removida')
end

local function createGangWarZone(data)
    print('[GangWar] Creando zona visual única...')
    
    if not data or not data.coords then
        print('[GangWar] ERROR: Datos de zona inválidos')
        return
    end
    
    local coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    print('[GangWar] Coordenadas:', coords)
    print('[GangWar] startTime recibido del servidor:', data.startTime)
    print('[GangWar] GetGameTimer actual del cliente:', GetGameTimer())
    print('[GangWar] Diferencia de tiempo:', GetGameTimer() - data.startTime)
    
    -- CORREGIR EL TIEMPO: Usar tiempo del cliente para evitar desincronización
    local clientStartTime = GetGameTimer()
    print('[GangWar] 🔧 USANDO TIEMPO DEL CLIENTE:', clientStartTime)
    
    -- Actualizar los datos con el tiempo correcto
    data.startTime = clientStartTime
    print('[GangWar] GetGameTimer actual:', GetGameTimer())
    print('[GangWar] Diferencia de tiempo:', GetGameTimer() - data.startTime)
    
    -- Crear blip en el mapa
    zoneBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    if zoneBlip and zoneBlip ~= 0 then
        SetBlipSprite(zoneBlip, 84)
        SetBlipScale(zoneBlip, 1.5)
        SetBlipColour(zoneBlip, data.canPoliceEnter and 3 or 1)
        SetBlipAsShortRange(zoneBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Gang War Zone")
        EndTextCommandSetBlipName(zoneBlip)
        print('[GangWar] Blip creado')
    end
    
    -- Crear zona de detección con ox_lib (SIN DEBUG VISUAL)
    activeZone = lib.zones.sphere({
        coords = coords,
        radius = Config.ZoneRadius,
        debug = Config.Debug, -- USAR CONFIG PARA DEBUG
        onEnter = function()
            isInZone = true
            print('[GangWar] ✅ ENTRÓ A LA ZONA OX_LIB')
            lib.notify({
                title = 'Gang War',
                description = 'Has entrado en una zona de Gang War',
                type = 'inform'
            })
        end,
        onExit = function()
            isInZone = false
            lib.hideTextUI()
            print('[GangWar] ❌ SALIÓ DE LA ZONA OX_LIB')
            lib.notify({
                title = 'Gang War',
                description = 'Has salido de la zona de Gang War',
                type = 'inform'
            })
        end
    })
    
    print('[GangWar] Zona de detección ox_lib creada (debug:', Config.Debug, ')')
    
    -- Thread de visualización usando la configuración del Config
    visualThread = CreateThread(function()
        print('[GangWar] Thread de visualización iniciado')
        
        while currentGangWar and activeZone do
            Wait(0)
            
            if not currentGangWar or not activeZone then
                break
            end
            
            local playerPos = GetEntityCoords(PlayerPedId())
            local distance = #(playerPos - coords)
            
            -- DIBUJAR ZONA VISUAL SEGÚN CONFIGURACIÓN
            if distance < 300.0 then
                local zoneSettings = Config.ZoneSettings[Config.ZoneType] or Config.ZoneSettings.simple
                local color = currentGangWar.canPoliceEnter and 
                    Config.ZoneColors.ending or Config.ZoneColors.active
                
                if Config.ZoneType == 'simple' then
                    -- Cilindro completo como en la configuración original
                    DrawMarker(
                        1, -- Cilindro
                        coords.x, coords.y, coords.z - (zoneSettings.underground or 20),
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        Config.ZoneRadius * 2.0, Config.ZoneRadius * 2.0, (zoneSettings.height or 100) + (zoneSettings.underground or 20),
                        color.r, color.g, color.b, color.a,
                        false, true, 2, false, nil, nil, false
                    )
                end
                
                -- Mostrar texto si está configurado y cerca
                if zoneSettings.showText and distance < (zoneSettings.textDistance or 50) then
                    local text = currentGangWar.canPoliceEnter and 
                        '~b~ZONA LIBRE~w~\nPolicia puede intervenir' or 
                        '~r~GANG WAR ACTIVO~w~\nZona restringida'
                    
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
                    SetDrawOrigin(coords.x, coords.y, coords.z + (zoneSettings.height or 100) / 2, 0)
                    DrawText(0.0, 0.0)
                    ClearDrawOrigin()
                end
            else
                Wait(1000)
            end
            
            -- MOSTRAR TIMER SOLO CUANDO ESTÁ EN LA ZONA
            if isInZone and distance < Config.ZoneRadius then
                if not currentGangWar.canPoliceEnter then
                    -- CÁLCULO CORREGIDO DEL TIMER CON DEBUG
                    local currentTime = GetGameTimer()
                    local startTime = currentGangWar.startTime
                    local timeElapsedMs = currentTime - startTime
                    local totalTimeMs = 15 * 60 * 1000 -- 15 minutos exactos
                    local remainingMs = math.max(0, totalTimeMs - timeElapsedMs)
                    
                    -- DEBUG CADA 5 SEGUNDOS
                    if GetGameTimer() % 5000 < 50 then
                        print('[GangWar] 🕐 TIMER DEBUG (CORREGIDO):')
                        print('  - currentTime:', currentTime)
                        print('  - startTime:', startTime)
                        print('  - timeElapsedMs:', timeElapsedMs)
                        print('  - remainingMs:', remainingMs)
                        print('  - minutos restantes:', math.floor(remainingMs / 1000 / 60))
                        print('  - ✅ Debe mostrar 15 minutos iniciales')
                    end
                    
                    if remainingMs > 0 then
                        local totalSecondsRemaining = math.floor(remainingMs / 1000)
                        local minutes = math.floor(totalSecondsRemaining / 60)
                        local seconds = totalSecondsRemaining % 60
                        
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
                    else
                        lib.hideTextUI()
                    end
                    
                elseif currentGangWar.canPoliceEnter then
                    lib.showTextUI('🔵 **ZONA LIBRE**  \n✅ Policía autorizada para intervenir', {
                        position = "top-center",
                        icon = 'shield-check',
                        style = {
                            borderRadius = 8,
                            backgroundColor = '#2563eb',
                            color = 'white'
                        }
                    })
                end
            else
                lib.hideTextUI()
            end
        end
        
        print('[GangWar] Thread de visualización terminado')
        lib.hideTextUI()
    end)
    
    print('[GangWar] Zona unificada creada exitosamente')
end

-- ========================================
-- FUNCIONES PRINCIPALES
-- ========================================

local function hasPermission()
    if not PlayerData or not PlayerData.job then return false end
    
    for _, job in pairs(Config.AuthorizedJobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

local function openGangWarMenu()
    if not hasPermission() then
        lib.notify({
            title = 'Gang War',
            description = 'No tienes permisos para usar este sistema',
            type = 'error'
        })
        return
    end
    
    local options = {
        {
            title = '🚩 Iniciar Gang War',
            description = 'Crear nueva zona de conflicto',
            icon = 'flag',
            disabled = currentGangWar ~= nil,
            onSelect = function()
                local input = lib.inputDialog('Iniciar Gang War', {
                    {
                        type = 'select',
                        label = 'Tipo de conflicto',
                        options = {
                            {value = 'territory', label = 'Disputa Territorial'},
                            {value = 'revenge', label = 'Venganza'},
                            {value = 'business', label = 'Conflicto de Negocios'}
                        },
                        required = true
                    },
                    {
                        type = 'input',
                        label = 'Descripción (opcional)',
                        placeholder = 'Describe el motivo...',
                        max = 100
                    }
                })
                
                if input then
                    local coords = GetEntityCoords(PlayerPedId())
                    TriggerServerEvent('gangwar:create', {
                        coords = {x = coords.x, y = coords.y, z = coords.z},
                        type = input[1],
                        description = input[2] or ''
                    })
                end
            end
        },
        {
            title = '🏁 Finalizar Gang War',
            description = currentGangWar and (currentGangWar.canPoliceEnter and 'Esperando auto-finalización...' or 'Terminar conflicto actual') or 'No hay gang war activo',
            icon = 'flag-checkered',
            disabled = currentGangWar == nil or isFinalizingGangWar or currentGangWar.canPoliceEnter,
            onSelect = function()
                if isFinalizingGangWar then
                    lib.notify({
                        title = 'Gang War',
                        description = 'Ya hay una finalización en proceso, espera...',
                        type = 'error'
                    })
                    return
                end
                
                local confirm = lib.alertDialog({
                    header = 'Confirmar',
                    content = '¿Finalizar el Gang War actual?',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    isFinalizingGangWar = true
                    TriggerServerEvent('gangwar:end')
                    
                    -- Reset después de 5 segundos por seguridad
                    SetTimeout(5000, function()
                        isFinalizingGangWar = false
                    end)
                end
            end
        }
    }
    
    lib.registerContext({
        id = 'gangwar_menu',
        title = '🔫 Gang War System',
        options = options
    })
    
    lib.showContext('gangwar_menu')
end

-- ========================================
-- EVENTOS ESX
-- ========================================

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    TriggerServerEvent('gangwar:requestSync')
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- ========================================
-- EVENTOS DEL GANG WAR
-- ========================================

RegisterNetEvent('gangwar:sync')
AddEventHandler('gangwar:sync', function(data)
    print('[GangWar] Sincronizando:', data and 'CON DATOS' or 'SIN DATOS')
    
    -- Reset estado de finalización
    isFinalizingGangWar = false
    
    -- LIMPIEZA COMPLETA
    lib.hideTextUI()
    removeGangWarZone()
    Wait(500)
    
    currentGangWar = data
    
    if data then
        -- CORREGIR TIEMPO ANTES DE CREAR LA ZONA
        local clientTime = GetGameTimer()
        print('[GangWar] 🔧 Corrigiendo startTime de', data.startTime, 'a', clientTime)
        data.startTime = clientTime
        currentGangWar.startTime = clientTime
        
        createGangWarZone(data)
        lib.notify({
            title = 'Gang War',
            description = 'Gang War activo detectado',
            type = 'inform'
        })
    end
end)

RegisterNetEvent('gangwar:updateStatus')
AddEventHandler('gangwar:updateStatus', function(canPoliceEnter)
    print('[GangWar] Actualizando estado:', canPoliceEnter and 'AZUL' or 'ROJO')
    
    if currentGangWar then
        currentGangWar.canPoliceEnter = canPoliceEnter
        
        -- Solo actualizar blip
        if zoneBlip and DoesBlipExist(zoneBlip) then
            SetBlipColour(zoneBlip, canPoliceEnter and 3 or 1)
        end
        
        if canPoliceEnter then
            isFinalizingGangWar = false -- Reset estado
            lib.notify({
                title = 'Gang War',
                description = 'La policía ya puede intervenir',
                type = 'inform'
            })
        end
    end
end)

RegisterNetEvent('gangwar:notification')
AddEventHandler('gangwar:notification', function(message, type)
    lib.notify({
        title = 'Gang War',
        description = message,
        type = type or 'inform'
    })
end)

-- ========================================
-- COMANDOS
-- ========================================

RegisterCommand('gangwar', function()
    openGangWarMenu()
end, false)


-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    while not ESX or not PlayerData.job do
        Wait(100)
    end
    
    TriggerServerEvent('gangwar:requestSync')
    print('[GangWar] Cliente inicializado')
end)
