-- ========================================
-- CLIENT/MAIN.LUA - VERSION FINAL CORREGIDA
-- ========================================

local ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local currentGangWar = nil
local isInZone = false

-- Variables para zona visual
local activeZone = nil
local zoneBlip = nil
local visualThread = nil

-- ========================================
-- FUNCIONES DE ZONA VISUAL
-- ========================================

local function removeGangWarZone()
    print('[GangWar] Removiendo zona visual...')
    
    lib.hideTextUI()
    
    if visualThread then
        visualThread = nil
        print('[GangWar] Thread de visualización detenido')
    end
    
    if zoneBlip and DoesBlipExist(zoneBlip) then
        RemoveBlip(zoneBlip)
        zoneBlip = nil
        print('[GangWar] Blip removido')
    end
    
    if activeZone then
        activeZone:remove()
        activeZone = nil
        print('[GangWar] Zona ox_lib removida')
    end
    
    isInZone = false
    print('[GangWar] Zona visual completamente removida')
end

local function createGangWarZone(data)
    print('[GangWar] Creando zona visual...')
    
    if not data or not data.coords then
        print('[GangWar] ERROR: Datos de zona inválidos')
        return
    end
    
    local coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    print('[GangWar] Coordenadas:', coords)
    
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
    
    -- Crear zona de detección con ox_lib
    activeZone = lib.zones.sphere({
        coords = coords,
        radius = Config.ZoneRadius,
        debug = Config.Debug,
        onEnter = function()
            isInZone = true
            lib.notify({
                title = 'Gang War',
                description = 'Has entrado en una zona de Gang War',
                type = 'inform'
            })
        end,
        onExit = function()
            isInZone = false
            lib.hideTextUI()
            lib.notify({
                title = 'Gang War',
                description = 'Has salido de la zona de Gang War',
                type = 'inform'
            })
        end
    })
    
    -- Crear visualización (cilindro rojo/azul)
    visualThread = CreateThread(function()
        print('[GangWar] Thread de visualización iniciado')
        
        while currentGangWar and activeZone do -- VERIFICAR AMBOS
            Wait(0)
            
            -- VERIFICACIÓN CRÍTICA
            if not currentGangWar or not activeZone then
                print('[GangWar] Condición de salida: currentGangWar o activeZone es null')
                break
            end
            
            local playerPos = GetEntityCoords(PlayerPedId())
            local distance = #(playerPos - coords)
            
            if distance < 300.0 then
                local color = currentGangWar.canPoliceEnter and 
                    {r = 0, g = 0, b = 255, a = 80} or
                    {r = 255, g = 0, b = 0, a = 80}
                
                -- Dibujar cilindro
                DrawMarker(
                    1,
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    Config.ZoneRadius * 2.0, Config.ZoneRadius * 2.0, 100.0,
                    color.r, color.g, color.b, color.a,
                    false, true, 2, false, nil, nil, false
                )
                
                -- TIMER CORREGIDO
                if isInZone and distance < Config.ZoneRadius then
                    if not currentGangWar.canPoliceEnter then
                        -- USAR EL MISMO TIEMPO BASE QUE EL SERVIDOR
                        local currentTime = GetGameTimer()
                        local startTime = currentGangWar.startTime
                        local timeElapsedMs = currentTime - startTime
                        local totalTimeMs = 15 * 60 * 1000 -- 15 minutos exactos
                        local remainingMs = math.max(0, totalTimeMs - timeElapsedMs)
                        
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
            else
                Wait(1000)
                lib.hideTextUI()
            end
        end
        
        print('[GangWar] Thread de visualización terminado')
        lib.hideTextUI()
    end)
    
    print('[GangWar] Zona visual creada exitosamente')
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
            description = 'Terminar conflicto actual',
            icon = 'flag-checkered',
            disabled = currentGangWar == nil,
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Confirmar',
                    content = '¿Finalizar el Gang War actual?',
                    centered = true,
                    cancel = true
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('gangwar:end')
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
    
    -- LIMPIEZA FORZADA SIEMPRE
    lib.hideTextUI()
    removeGangWarZone()
    Wait(500)
    
    currentGangWar = data
    
    if data then
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

RegisterKeyMapping('gangwar', 'Abrir menú Gang War', 'keyboard', 'F6')

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
