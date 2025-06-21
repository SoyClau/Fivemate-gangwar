-- ========================================
-- SERVER/MAIN.LUA - FINALIZACIÓN CORREGIDA
-- ========================================

local ESX = exports['es_extended']:getSharedObject()
local activeGangWar = nil
local autoEndTimer = nil
local isEnding = false -- NUEVO: Control de finalización

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
        local coords = vector3(gangWarData.coords.x, gangWarData.coords.y, gangWarData.coords.z)
        
        exports['origen_police']:SendAlert({
            coords = coords,
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

--- Enviar webhook de Discord
--- @param title string
--- @param description string
--- @param color number
--- @param fields table
local function sendWebhook(title, description, color, fields)
    if not ServerConfig or not ServerConfig.Webhook or not ServerConfig.Webhook.enabled then
        print('[GangWar] Webhook deshabilitado o no configurado')
        return
    end
    
    if not ServerConfig.Webhook.url or ServerConfig.Webhook.url == "" then
        print('[GangWar] ERROR: URL de webhook no configurada')
        return
    end
    
    local embed = {
        {
            title = title,
            description = description,
            color = color,
            fields = fields or {},
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            footer = {
                text = "Gang War System",
                icon_url = "https://cdn.discordapp.com/attachments/123456789/123456789/icon.png"
            }
        }
    }
    
    local payload = {
        username = ServerConfig.Webhook.botName or "Gang War System",
        embeds = embed
    }
    
    print('[GangWar] 📤 Enviando webhook:', title)
    print('[GangWar] 🔗 URL:', ServerConfig.Webhook.url)
    
    PerformHttpRequest(ServerConfig.Webhook.url, function(err, text, headers)
        if err == 200 or err == 204 then
            print('[GangWar] ✅ Webhook enviado exitosamente')
        else
            print('[GangWar] ❌ Error en webhook. Código:', err)
            print('[GangWar] Respuesta:', text)
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
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
    
    if isEnding then
        TriggerClientEvent('gangwar:notification', source, 'Hay una finalización en proceso, espera...', 'error')
        return
    end
    
    -- OBTENER TIEMPO EXACTO AL MOMENTO DE CREACIÓN
    local serverTime = GetGameTimer()
    
    activeGangWar = {
        id = math.random(100000, 999999),
        coords = data.coords,
        type = data.type,
        description = data.description,
        startTime = serverTime, -- TIEMPO EXACTO DEL SERVIDOR
        creator = {
            source = source,
            name = xPlayer.getName(),
            job = xPlayer.job.name
        },
        canPoliceEnter = false
    }
    
    print('[GangWar] Gang War creado con ID:', activeGangWar.id)
    print('[GangWar] startTime SERVER establecido:', serverTime)
    
    -- Sincronizar con todos los clientes INMEDIATAMENTE
    sendToAllClients('gangwar:sync', activeGangWar)
    
    -- Enviar dispatch a policía
    sendDispatch(activeGangWar)
    
    -- Notificar al creador
    TriggerClientEvent('gangwar:notification', source, 'Gang War iniciado exitosamente', 'success')
    
    -- Timer automático de 15 minutos EXACTOS
    if autoEndTimer then
        ClearTimeout(autoEndTimer)
    end
    
    autoEndTimer = SetTimeout(15 * 60 * 1000, function() -- 900,000 ms = 15 minutos exactos
        if activeGangWar and not isEnding then
            print('[GangWar] TIMER AUTOMÁTICO: 15 minutos cumplidos - Policía puede intervenir')
            activeGangWar.canPoliceEnter = true
            
            -- Notificar cambio de estado
            sendToAllClients('gangwar:updateStatus', true)
            sendToPolice('gangwar:notification', 'Gang War - Autorizado para intervenir', 'success')
            
            -- Auto-finalizar después de 1 minuto adicional
            SetTimeout(1 * 60 * 1000, function()
                if activeGangWar and not isEnding then
                    print('[GangWar] TIMER AUTOMÁTICO: Auto-finalizando gang war')
                    activeGangWar = nil
                    isEnding = false
                    sendToAllClients('gangwar:sync', nil)
                    sendToAllClients('gangwar:notification', 'Gang War finalizado automáticamente', 'inform')
                end
            end)
        end
    end)
    
    print('[GangWar] Timer de 15 minutos iniciado correctamente')
end

local function endGangWar(source)
    if not activeGangWar then
        TriggerClientEvent('gangwar:notification', source, 'No hay Gang War activo', 'error')
        return
    end
    
    if isEnding then
        TriggerClientEvent('gangwar:notification', source, 'Ya hay una finalización en proceso, espera a que termine...', 'error')
        return
    end
    
    if activeGangWar.canPoliceEnter then
        TriggerClientEvent('gangwar:notification', source, 'El Gang War ya está finalizándose automáticamente...', 'error')
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    if not hasPermission(xPlayer) and activeGangWar.creator.source ~= source then
        TriggerClientEvent('gangwar:notification', source, 'No tienes permisos', 'error')
        return
    end
    
    print('[GangWar] Gang War finalizado manualmente por:', xPlayer.getName())
    
    -- MARCAR COMO EN PROCESO DE FINALIZACIÓN
    isEnding = true
    
    -- Limpiar timer automático
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
            print('[GangWar] Removiendo gang war completamente tras finalización manual')
            activeGangWar = nil
            isEnding = false
            sendToAllClients('gangwar:sync', nil)
            sendToAllClients('gangwar:notification', 'Zona de Gang War removida', 'inform')
        else
            isEnding = false -- Reset por seguridad
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
            isEnding = false -- Force reset
            endGangWar(source)
        else
            TriggerClientEvent('gangwar:notification', source, 'No hay gang war activo', 'error')
        end
    elseif action == 'info' then
        if activeGangWar then
            print('[GangWar] Gang War activo:', json.encode(activeGangWar))
            print('[GangWar] isEnding:', isEnding)
            TriggerClientEvent('gangwar:notification', source, 'Ver consola para información completa', 'inform')
        else
            TriggerClientEvent('gangwar:notification', source, 'No hay gang war activo', 'error')
        end
    elseif action == 'reset' then
        isEnding = false
        TriggerClientEvent('gangwar:notification', source, 'Estado de finalización reseteado', 'success')
    end
end, true)

-- ========================================
-- EXPORTS
-- ========================================

exports('getActiveGangWar', function() return activeGangWar end)
exports('isGangWarActive', function() return activeGangWar ~= nil end)
exports('isGangWarEnding', function() return isEnding end)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    print('[GangWar] Servidor iniciado')
    print('[GangWar] Trabajos autorizados:', json.encode(Config.AuthorizedJobs))
    print('[GangWar] Sistema de dispatch:', Config.DispatchSystem)
end)

RegisterCommand('test_webhook', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then 
        TriggerClientEvent('gangwar:notification', source, 'Solo administradores', 'error')
        return 
    end
    
    print('[GangWar] 🧪 Probando webhook...')
    
    sendWebhook(
        "🧪 PRUEBA DE WEBHOOK",
        "Esta es una prueba para verificar que el webhook funciona correctamente",
        16711680, -- Color rojo
        {
            {name = "👤 Administrador", value = xPlayer.getName(), inline = true},
            {name = "⏰ Fecha", value = os.date('%Y-%m-%d %H:%M:%S'), inline = true},
            {name = "🆔 Servidor", value = GetConvar('sv_hostname', 'Servidor FiveM'), inline = false}
        }
    )
    
    TriggerClientEvent('gangwar:notification', source, 'Webhook de prueba enviado - revisa Discord', 'success')
end, true)
