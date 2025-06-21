-- ========================================
-- INTERFAZ DE DISPATCH PARA POLICÍA
-- ========================================

local activeDispatches = {}
local dispatchSound = true

-- ========================================
-- FUNCIONES DE DISPATCH UI
-- ========================================

--- Mostrar dispatch de gang war a la policía
--- @param dispatchData table
local function showDispatch(dispatchData)
    if not exports['FiveMate_Gangwar']:isPolice() then
        return
    end
    
    -- Reproducir sonido de dispatch
    if dispatchSound then
        PlaySoundFrontend(-1, "Menu_Accept", "Phone_SoundSet_Default", true)
    end
    
    -- Mostrar notificación principal
    lib.notify({
        id = 'gangwar_dispatch_' .. dispatchData.id,
        title = dispatchData.title,
        description = string.format('%s\n📍 %s\n📏 %sm de distancia\n⏰ %s', 
            dispatchData.message,
            dispatchData.location,
            dispatchData.distance,
            dispatchData.time
        ),
        type = 'error',
        duration = 15000,
        position = 'top',
        style = {
            backgroundColor = '#dc2626',
            color = '#ffffff'
        }
    })
    
    -- Mostrar alerta detallada
    local alert = lib.alertDialog({
        header = '🚨 DISPATCH - GANG WAR',
        content = string.format([[
**📍 Ubicación:** %s

**📏 Distancia:** %sm

**⏰ Hora:** %s

**🎯 Tipo:** %s

**👮 Unidades necesarias:** %s

**⚠️ IMPORTANTE:**
%s

**Instrucciones:**
- Dirigirse al área marcada
- Establecer perímetro de seguridad
- NO INTERVENIR hasta nueva orden
- Monitorear situación
        ]], 
            dispatchData.location,
            dispatchData.distance,
            dispatchData.time,
            dispatchData.type or 'Gang War',
            dispatchData.units_needed or '2-4 unidades',
            Locale.dispatch.zone_info
        ),
        centered = true,
        cancel = false,
        labels = {
            confirm = 'Entendido'
        }
    })
    
    -- Guardar dispatch activo
    activeDispatches[dispatchData.id] = {
        data = dispatchData,
        timestamp = GetGameTimer()
    }
    
    if Config.Debug then
        print('[GangWar] Dispatch mostrado:', dispatchData.title)
    end
end

--- Mostrar actualización de dispatch
--- @param updateData table
local function showDispatchUpdate(updateData)
    if not exports['FiveMate_Gangwar']:isPolice() then
        return
    end
    
    -- Reproducir sonido diferente para actualizaciones
    PlaySoundFrontend(-1, "CLICK_BACK", "WEB_NAVIGATION_SOUNDS_PHONE", true)
    
    local notificationType = updateData.canEnter and 'success' or 'inform'
    local backgroundColor = updateData.canEnter and '#16a34a' or '#0ea5e9'
    
    lib.notify({
        id = 'gangwar_update_' .. updateData.id,
        title = updateData.title,
        description = string.format('%s\n📍 %s', 
            updateData.message,
            updateData.location
        ),
        type = notificationType,
        duration = 10000,
        position = 'top',
        style = {
            backgroundColor = backgroundColor,
            color = '#ffffff'
        }
    })
    
    -- Si la policía puede entrar, mostrar alerta especial
    if updateData.canEnter then
        lib.alertDialog({
            header = '✅ AUTORIZACIÓN POLICIAL',
            content = string.format([[
**🎯 Gang War ID:** %s

**📍 Ubicación:** %s

**✅ ESTADO:** AUTORIZADO PARA INTERVENIR

La zona de Gang War ha sido liberada para intervención policial.

**Instrucciones actualizadas:**
- Proceder con precaución al área
- Establecer control de la zona
- Aplicar protocolos estándar
- Documentar la situación
            ]], 
                updateData.id,
                updateData.location
            ),
            centered = true,
            cancel = false,
            labels = {
                confirm = 'Confirmado'
            }
        })
    end
    
    if Config.Debug then
        print('[GangWar] Actualización de dispatch mostrada')
    end
end

--- Mostrar menú de dispatches activos
local function showActiveDispatches()
    if not exports['FiveMate_Gangwar']:isPolice() then
        return
    end
    
    local options = {}
    local hasActiveDispatches = false
    
    for id, dispatch in pairs(activeDispatches) do
        hasActiveDispatches = true
        local timeAgo = math.floor((GetGameTimer() - dispatch.timestamp) / 1000 / 60) -- minutos
        
        table.insert(options, {
            title = string.format('🚨 Gang War #%s', id),
            description = string.format('%s - Hace %s min\n📍 %s', 
                dispatch.data.title,
                timeAgo,
                dispatch.data.location
            ),
            icon = 'exclamation-triangle',
            iconColor = 'red',
            onSelect = function()
                showDispatchDetails(dispatch.data)
            end
        })
    end
    
    if not hasActiveDispatches then
        table.insert(options, {
            title = '📭 Sin dispatches activos',
            description = 'No hay gang wars reportados actualmente',
            icon = 'info',
            disabled = true
        })
    end
    
    table.insert(options, {
        title = '⚙️ Configuración',
        description = 'Configurar alertas de dispatch',
        icon = 'cog',
        onSelect = function()
            showDispatchSettings()
        end
    })
    
    lib.registerContext({
        id = 'gangwar_dispatches',
        title = '🚨 Dispatches Activos',
        options = options
    })
    
    lib.showContext('gangwar_dispatches')
end

--- Mostrar detalles de un dispatch específico
--- @param dispatchData table
local function showDispatchDetails(dispatchData)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - vector3(dispatchData.coords.x, dispatchData.coords.y, dispatchData.coords.z))
    
    local options = {
        {
            title = '📍 Navegar al lugar',
            description = 'Establecer waypoint en el mapa',
            icon = 'map-marker-alt',
            onSelect = function()
                SetNewWaypoint(dispatchData.coords.x, dispatchData.coords.y)
                lib.notify({
                    title = 'Navegación',
                    description = 'Waypoint establecido en el mapa',
                    type = 'success'
                })
            end
        },
        {
            title = '📊 Información detallada',
            description = 'Ver todos los detalles del dispatch',
            icon = 'info-circle',
            onSelect = function()
                lib.alertDialog({
                    header = string.format('Gang War #%s', dispatchData.id),
                    content = string.format([[
**📍 Ubicación:** %s
**📏 Distancia actual:** %sm
**⏰ Reportado:** %s
**🎯 Tipo:** %s
**👮 Unidades:** %s
**📝 Mensaje:** %s

**Coordenadas:** %s, %s
                    ]], 
                        dispatchData.location,
                        math.floor(distance),
                        dispatchData.time,
                        dispatchData.type or 'Gang War',
                        dispatchData.units_needed or 'No especificado',
                        dispatchData.message,
                        math.floor(dispatchData.coords.x),
                        math.floor(dispatchData.coords.y)
                    ),
                    centered = true,
                    cancel = true
                })
            end
        }
    }
    
    lib.registerContext({
        id = 'gangwar_dispatch_details',
        title = string.format('🚨 Gang War #%s', dispatchData.id),
        options = options
    })
    
    lib.showContext('gangwar_dispatch_details')
end

--- Mostrar configuración de dispatch
local function showDispatchSettings()
    local options = {
        {
            title = dispatchSound and '🔊 Sonido: Activado' or '🔇 Sonido: Desactivado',
            description = 'Alternar sonidos de dispatch',
            icon = dispatchSound and 'volume-up' or 'volume-mute',
            onSelect = function()
                dispatchSound = not dispatchSound
                lib.notify({
                    title = 'Configuración',
                    description = dispatchSound and 'Sonidos activados' or 'Sonidos desactivados',
                    type = 'inform'
                })
                showDispatchSettings() -- Refrescar menú
            end
        },
        {
            title = '🗑️ Limpiar dispatches',
            description = 'Remover todos los dispatches activos',
            icon = 'trash',
            iconColor = 'red',
            onSelect = function()
                activeDispatches = {}
                lib.notify({
                    title = 'Configuración',
                    description = 'Dispatches limpiados',
                    type = 'success'
                })
            end
        }
    }
    
    lib.registerContext({
        id = 'gangwar_dispatch_settings',
        title = '⚙️ Configuración de Dispatch',
        options = options
    })
    
    lib.showContext('gangwar_dispatch_settings')
end

-- ========================================
-- COMANDOS PARA POLICÍA
-- ========================================

RegisterCommand('dispatches', function()
    if exports['FiveMate_Gangwar']:isPolice() then
        showActiveDispatches()
    else
        lib.notify({
            title = 'Error',
            description = 'Solo disponible para policía',
            type = 'error'
        })
    end
end, false)

-- RegisterKeyMapping('dispatches', 'Ver Dispatches de Gang War', 'keyboard', 'F11')

-- ========================================
-- EVENTOS
-- ========================================

RegisterNetEvent('gangwar:client:dispatch')
AddEventHandler('gangwar:client:dispatch', function(dispatchData)
    showDispatch(dispatchData)
end)

RegisterNetEvent('gangwar:client:dispatchUpdate')
AddEventHandler('gangwar:client:dispatchUpdate', function(updateData)
    showDispatchUpdate(updateData)
end)

-- ========================================
-- LIMPIAR DISPATCHES ANTIGUOS
-- ========================================

CreateThread(function()
    while true do
        Wait(300000) -- Cada 5 minutos
        
        local currentTime = GetGameTimer()
        
        for id, dispatch in pairs(activeDispatches) do
            -- Remover dispatches de más de 30 minutos
            if currentTime - dispatch.timestamp > 1800000 then
                activeDispatches[id] = nil
            end
        end
    end
end)

-- ========================================
-- EXPORTS
-- ========================================

exports('showDispatch', showDispatch)
exports('showDispatchUpdate', showDispatchUpdate)
exports('showActiveDispatches', showActiveDispatches)
exports('getActiveDispatches', function() return activeDispatches end)