-- ========================================
-- SERVER/MAIN.LUA - VERSIÓN NUEVA COMPLETA
-- ========================================

local ESX = exports['es_extended']:getSharedObject()
local activeGangWar = nil
local autoEndTimer = nil

-- ========================================
-- FUNCIONES AUXILIARES
-- ========================================

local function hasPermission(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    
    for _, job in pairs(Config.AuthorizedJobs) do
        if xPlayer.job.name == job then
            return true
        end
    end
    return false
end

local function isPolice(xPlayer)
    if not xPlayer or not xPlayer.job then return false end
    
    for _, job in pairs(Config.PoliceJobs) do
        if xPlayer.job.name == job then
            return true
        end
    end
    return false
end

local function sendToAllClients(event, data)
    TriggerClientEvent(event, -1, data)
end

local function sendToPolice(event, data)
    local xPlayers = ESX.GetExtendedPlayers()
    for _, xPlayer in pairs(xPlayers) do
        if isPolice(xPlayer) then
            TriggerClientEvent(event, xPlayer.source, data)
        end
    end
end

local function sendDispatch(gangWarData)
    if not Config.UseDispatchSystem then return end
    
    local locationName = "Zona de Los Santos"
    
    if Config.DispatchSystem == "origen_police" then
        -- CORREGIR COORDS - convertir a vector3
        local coords = vector3(gangWarData.coords.x, gangWarData.coords.y, gangWarData.coords.z)
        
        exports['origen_police']:SendAlert({
            coords = coords, -- Enviar como vector3
            title = "Gang War detectado - Zona restringida",
            type = 'GENERAL',
            message = string.format("🚨 GANG WAR ACTIVO\n📍 %s\n⚠️ NO INTERVENIR", locationName),
            job = 'police',
        })
        print('[GangWar] Dispatch enviado via origen_police')
    else
        sendToPolice('gangwar:notification', 'Gang War detectado - Zona restringida para policía', 'error')
        print('[GangWar] Dispatch enviado via notificación directa')
    end
end

-- ========================================
-- FUNCIONES PRINCIPALES
-- ========================================

local function createGangWar(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    print('[GangWar] Solicitud de creación de:', xPlayer.getName())
    
    if not hasPermission(xPlayer) then
        TriggerClientEvent('gangwar:notification', source, 'No tienes permisos', 'error')
        return
    end
    
    if activeGangWar then
        TriggerClientEvent('gangwar:notification', source, 'Ya hay un Gang War activo', 'error')
        return
    end
    
    -- USAR EL TIEMPO DEL CLIENTE PARA SINCRONIZACIÓN
    local clientTime = GetGameTimer()

    activeGangWar = {
        id = math.random(100000, 999999),
        coords = data.coords,
        type = data.type,
        description = data.description,
        startTime = clientTime, -- USAR TIEMPO ACTUAL DEL SERVIDOR
        creator = {
            source = source,
            name = xPlayer.getName(),
            job = xPlayer.job.name
        },
        canPoliceEnter = false
    }
    
    print('[GangWar] Gang War creado con ID:', activeGangWar.id)
    print('[GangWar] startTime establecido:', clientTime)
    
    -- Sincronizar con todos los clientes
    sendToAllClients('gangwar:sync', activeGangWar)
    
    -- Enviar dispatch a policía
    sendDispatch(activeGangWar)
    
    -- Notificar al creador
    TriggerClientEvent('gangwar:notification', source, 'Gang War iniciado exitosamente', 'success')
    
    -- Timer automático de 15 minutos
    if autoEndTimer then
        ClearTimeout(autoEndTimer)
    end
    
    autoEndTimer = SetTimeout(15 * 60 * 1000, function() -- 15 minutos exactos
        if activeGangWar then
            print('[GangWar] Tiempo cumplido - Policía puede intervenir')
            activeGangWar.canPoliceEnter = true
            
            -- Notificar cambio de estado
            sendToAllClients('gangwar:updateStatus', true)
            sendToPolice('gangwar:notification', 'Gang War - Autorizado para intervenir', 'success')
            
            -- Auto-finalizar después de 1 minuto adicional
            SetTimeout(1 * 60 * 1000, function() -- 1 minuto más
                if activeGangWar then
                    print('[GangWar] Auto-finalizando gang war')
                    activeGangWar = nil
                    sendToAllClients('gangwar:sync', nil)
                    sendToAllClients('gangwar:notification', 'Gang War finalizado automáticamente', 'inform')
                end
            end)
        end
    end)
    
    print('[GangWar] Timer de 15 minutos iniciado')
end

local function endGangWar(source)
    if not activeGangWar then
        TriggerClientEvent('gangwar:notification', source, 'No hay Gang War activo', 'error')
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Verificar permisos
    if not hasPermission(xPlayer) and activeGangWar.creator.source ~= source then
        TriggerClientEvent('gangwar:notification', source, 'No tienes permisos', 'error')
        return
    end
    
    print('[GangWar] Gang War finalizado manualmente por:', xPlayer.getName())
    
    -- Limpiar timer
    if autoEndTimer then
        ClearTimeout(autoEndTimer)
        autoEndTimer = nil
    end
    
    -- Cambiar a estado azul por 1 minuto
    activeGangWar.canPoliceEnter = true
    sendToAllClients('gangwar:updateStatus', true)
    TriggerClientEvent('gangwar:notification', source, 'Gang War finalizado - Zona azul por 1 minuto', 'success')
    sendToAllClients('gangwar:notification', 'Gang War finalizado - Policía puede intervenir', 'inform')
    
    -- REMOVER COMPLETAMENTE DESPUÉS DE 1 MINUTO
    SetTimeout(1 * 60 * 1000, function()
        if activeGangWar then
            print('[GangWar] Removiendo gang war completamente')
            activeGangWar = nil
            sendToAllClients('gangwar:sync', nil) -- ESTO DEBERÍA LIMPIAR TODO
            sendToAllClients('gangwar:notification', 'Zona de Gang War removida', 'inform')
        end
    end)
end

local function syncGangWar(source)
    print('[GangWar] Sincronización solicitada por cliente')
    TriggerClientEvent('gangwar:sync', source, activeGangWar)
end

-- ========================================
-- EVENTOS
-- ========================================

RegisterNetEvent('gangwar:create')
AddEventHandler('gangwar:create', function(data)
    createGangWar(source, data)
end)

RegisterNetEvent('gangwar:end')
AddEventHandler('gangwar:end', function()
    endGangWar(source)
end)

RegisterNetEvent('gangwar:requestSync')
AddEventHandler('gangwar:requestSync', function()
    syncGangWar(source)
end)

-- ========================================
-- EVENTOS ESX
-- ========================================

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    -- Sincronizar gang war activo con jugador que se conecta
    SetTimeout(2000, function()
        TriggerClientEvent('gangwar:sync', playerId, activeGangWar)
    end)
end)

-- ========================================
-- COMANDOS DE ADMIN
-- ========================================

RegisterCommand('gangwar_admin', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then return end
    
    local action = args[1]
    
    if action == 'end' then
        if activeGangWar then
            endGangWar(source)
        else
            TriggerClientEvent('gangwar:notification', source, 'No hay gang war activo', 'error')
        end
    elseif action == 'info' then
        if activeGangWar then
            print('[GangWar] Gang War activo:', json.encode(activeGangWar))
            TriggerClientEvent('gangwar:notification', source, 'Ver consola para información completa', 'inform')
        else
            TriggerClientEvent('gangwar:notification', source, 'No hay gang war activo', 'error')
        end
    end
end, true)

-- ========================================
-- EXPORTS
-- ========================================

exports('getActiveGangWar', function() return activeGangWar end)
exports('isGangWarActive', function() return activeGangWar ~= nil end)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    print('[GangWar] Servidor iniciado')
    print('[GangWar] Trabajos autorizados:', json.encode(Config.AuthorizedJobs))
    print('[GangWar] Sistema de dispatch:', Config.DispatchSystem)
end)
