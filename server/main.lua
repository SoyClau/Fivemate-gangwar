-- ========================================
-- VARIABLES GLOBALES DEL SERVIDOR
-- ========================================

local ESX = exports['es_extended']:getSharedObject()
local activeGangWar = nil
local gangWarTimer = nil
local gangWarHistory = {}

-- ========================================
-- FUNCIONES AUXILIARES
-- ========================================

--- Verificar si un jugador tiene permiso para gestionar gang wars
--- @param xPlayer table
--- @return boolean
local function hasPermission(xPlayer)
    if not xPlayer.job then return false end
    
    for _, job in pairs(Config.AuthorizedJobs) do
        if xPlayer.job.name == job then
            return true
        end
    end
    return false
end

--- Verificar si un jugador es policía
--- @param xPlayer table
--- @return boolean
local function isPolice(xPlayer)
    if not xPlayer.job then return false end
    
    for _, job in pairs(Config.PoliceJobs) do
        if xPlayer.job.name == job then
            return true
        end
    end
    return false
end

--- Obtener jugadores policías online
--- @return table
local function getPolicePlayers()
    local police = {}
    local xPlayers = ESX.GetExtendedPlayers()
    
    for _, xPlayer in pairs(xPlayers) do
        if isPolice(xPlayer) then
            table.insert(police, xPlayer)
        end
    end
    
    return police
end

--- Sincronizar gang war con todos los clientes
local function syncGangWarToAll()
    TriggerClientEvent('gangwar:client:syncZone', -1, activeGangWar)
end

--- Enviar notificación a un jugador específico
--- @param source number
--- @param message string
--- @param type string
--- @param duration number
local function sendNotification(source, message, type, duration)
    TriggerClientEvent('gangwar:client:notification', source, message, type, duration)
end

--- Registrar evento en el historial
--- @param eventType string
--- @param data table
local function logGangWarEvent(eventType, data)
    table.insert(gangWarHistory, {
        timestamp = os.time(),
        type = eventType,
        data = data
    })
    
    if Config.Debug then
        print(string.format('[GangWar] Evento registrado: %s - %s', eventType, json.encode(data)))
    end
end

-- ========================================
-- FUNCIONES PRINCIPALES
-- ========================================

--- Crear nuevo gang war
--- @param source number
--- @param data table
local function createGangWar(source, data)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        if Config.Debug then
            print('[GangWar] Error: Jugador no encontrado')
        end
        return
    end
    
    -- Verificar permisos
    if not hasPermission(xPlayer) then
        sendNotification(source, Locale.notifications.no_permission, 'error')
        return
    end
    
    -- Verificar si ya hay un gang war activo
    if activeGangWar then
        sendNotification(source, Locale.notifications.already_active, 'error')
        return
    end
    
    -- Crear gang war
    activeGangWar = {
        id = math.random(100000, 999999),
        coords = data.coords,
        type = data.type or 'territory',
        description = data.description or '',
        duration = data.duration or Config.AutoEndTime,
        startTime = GetGameTimer(),
        creator = {
            source = source,
            identifier = xPlayer.identifier,
            name = xPlayer.getName(),
            job = xPlayer.job.name
        },
        canPoliceEnter = false,
        participants = {}
    }
    
    -- Iniciar timer automático
    if gangWarTimer then
        ClearTimeout(gangWarTimer)
    end
    
    gangWarTimer = SetTimeout(activeGangWar.duration * 60000, function()
        if activeGangWar then
            activeGangWar.canPoliceEnter = true
            TriggerClientEvent('gangwar:client:updateZoneStatus', -1, true)
            
            -- Notificar a la policía que ya pueden intervenir
            local police = getPolicePlayers()
            for _, xPolice in pairs(police) do
                sendNotification(xPolice.source, Locale.notifications.police_can_enter, 'inform')
            end
            
            logGangWarEvent('auto_police_allowed', {gangwar_id = activeGangWar.id})
            
            -- Timer para remover la zona automáticamente después del tiempo azul
            SetTimeout(Config.BlueZoneTime * 60000, function()
                if activeGangWar and activeGangWar.canPoliceEnter then
                    -- Enviar webhook de finalización automática
                    sendWebhook(
                        "🟢 Gang War Finalizado Automáticamente",
                        "El gang war ha finalizado automáticamente después del tiempo azul",
                        ServerConfig.Webhook.color.auto_ended,
                        {
                            {name = "👤 Creador Original", value = activeGangWar.creator.name, inline = true},
                            {name = "💼 Trabajo", value = activeGangWar.creator.job, inline = true},
                            {name = "⏱️ Duración Total", value = math.floor((GetGameTimer() - activeGangWar.startTime) / 60000) .. " minutos", inline = true},
                            {name = "🆔 Gang War ID", value = activeGangWar.id, inline = true},
                            {name = "🎯 Tipo", value = activeGangWar.type, inline = true},
                            {name = "📝 Descripción", value = activeGangWar.description ~= "" and activeGangWar.description or "Sin descripción", inline = false}
                        }
                    )

                    -- Finalizar automáticamente
                    logGangWarEvent('auto_ended_after_blue', {
                        gangwar_id = activeGangWar.id,
                        total_duration = math.floor((GetGameTimer() - activeGangWar.startTime) / 60000)
                    })
                    
                    activeGangWar = nil
                    TriggerClientEvent('gangwar:client:syncZone', -1, nil)
                    TriggerClientEvent('gangwar:client:notification', -1, 'Gang War finalizado automáticamente', 'inform')
                    
                    if Config.Debug then
                        print('[GangWar] Gang War removido automáticamente después del periodo azul')
                    end
                end
            end)
        end
    end)
    
    -- Sincronizar con todos los clientes
    syncGangWarToAll()
    
    -- Enviar dispatch a la policía
    TriggerEvent('gangwar:server:sendDispatch', activeGangWar)
    
    -- Notificar al creador
    sendNotification(source, Locale.notifications.gangwar_started, 'success')
    
    -- Enviar webhook de gang war iniciado
    sendWebhook(
        "🔴 Gang War Iniciado",
        string.format("**%s** ha iniciado un gang war", xPlayer.getName()),
        ServerConfig.Webhook.color.started,
        {
            {name = "👤 Usuario", value = xPlayer.getName(), inline = true},
            {name = "💼 Trabajo", value = xPlayer.job.label .. " (" .. xPlayer.job.name .. ")", inline = true},
            {name = "📍 Ubicación", value = string.format("X: %.1f, Y: %.1f", data.coords.x, data.coords.y), inline = true},
            {name = "🎯 Tipo", value = data.type, inline = true},
            {name = "⏱️ Duración", value = activeGangWar.duration .. " minutos", inline = true},
            {name = "📝 Descripción", value = data.description ~= "" and data.description or "Sin descripción", inline = false}
        }
    )

    logGangWarEvent('created', {
        gangwar_id = activeGangWar.id,
        creator = activeGangWar.creator.name,
        location = activeGangWar.coords,
        type = activeGangWar.type
    })
    
    if Config.Debug then
        print(string.format('[GangWar] Gang War creado por %s en %s', xPlayer.getName(), json.encode(data.coords)))
    end
end

--- Finalizar gang war activo
--- @param source number
local function endGangWar(source)
    if not activeGangWar then
        sendNotification(source, Locale.notifications.no_active_gangwar, 'error')
        return
    end
    
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        return
    end
    
    -- Verificar permisos (creador o admin)
    if not hasPermission(xPlayer) and activeGangWar.creator.source ~= source then
        sendNotification(source, Locale.notifications.no_permission, 'error')
        return
    end
    
    -- Limpiar timer principal
    if gangWarTimer then
        ClearTimeout(gangWarTimer)
        gangWarTimer = nil
    end
    
    -- Enviar webhook de finalización manual
    sendWebhook(
        "🔵 Gang War Finalizado Manualmente",
        string.format("**%s** ha finalizado el gang war manualmente", xPlayer.getName()),
        ServerConfig.Webhook.color.ended,
        {
            {name = "👤 Finalizador", value = xPlayer.getName(), inline = true},
            {name = "💼 Trabajo", value = xPlayer.job.label .. " (" .. xPlayer.job.name .. ")", inline = true},
            {name = "⏱️ Duración Total", value = math.floor((GetGameTimer() - activeGangWar.startTime) / 60000) .. " minutos", inline = true},
            {name = "🆔 Gang War ID", value = activeGangWar.id, inline = true},
            {name = "👤 Creador Original", value = activeGangWar.creator.name, inline = true},
            {name = "🎯 Tipo", value = activeGangWar.type, inline = true}
        }
    )
    
    -- Registrar evento
    logGangWarEvent('ended_manually', {
        gangwar_id = activeGangWar.id,
        ended_by = xPlayer.getName(),
        duration = math.floor((GetGameTimer() - activeGangWar.startTime) / 60000)
    })
    
    -- Cambiar a estado azul por 1 minuto antes de finalizar
    activeGangWar.canPoliceEnter = true
    activeGangWar.manuallyEnded = true
    activeGangWar.endTime = GetGameTimer()
    
    -- Enviar datos actualizados a todos los clientes
    TriggerClientEvent('gangwar:client:updateZoneStatus', -1, true, {
        manuallyEnded = true,
        endTime = activeGangWar.endTime
    })
    
    -- Notificar el cambio a azul
    sendNotification(source, 'Gang War finalizado - Zona azul por ' .. Config.BlueZoneTime .. ' minuto(s)', 'success')
    TriggerClientEvent('gangwar:client:notification', -1, 'Gang War finalizado - Policía puede intervenir', 'inform')
    
    -- Timer para remover completamente después del tiempo azul
    SetTimeout(Config.BlueZoneTime * 60000, function()
        if activeGangWar then
            -- Limpiar gang war completamente
            activeGangWar = nil
            
            -- Sincronizar con todos los clientes (remover zona)
            TriggerClientEvent('gangwar:client:syncZone', -1, nil)
            TriggerClientEvent('gangwar:client:notification', -1, 'Zona de Gang War removida', 'inform')
            
            if Config.Debug then
                print('[GangWar] Gang War completamente removido después del periodo azul')
            end
        end
    end)
    
    if Config.Debug then
        print(string.format('[GangWar] Gang War finalizado manualmente por %s - Entrando en periodo azul', xPlayer.getName()))
    end
end

--- Enviar webhook de Discord
--- @param title string
--- @param description string
--- @param color number
--- @param fields table
local function sendWebhook(title, description, color, fields)
    if not Config.Webhook.enabled or not Config.Webhook.url or Config.Webhook.url == "" then
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
                icon_url = "https://cdn.discordapp.com/emojis/🔫.png"
            }
        }
    }
    
    local payload = {
        username = Config.Webhook.botName,
        embeds = embed
    }
    
    PerformHttpRequest(Config.Webhook.url, function(err, text, headers) end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

--- @param source number
local function getGangWarInfo(source)
    if not activeGangWar then
        sendNotification(source, Locale.notifications.no_active_gangwar, 'error')
        return
    end
    
    TriggerClientEvent('gangwar:client:syncZone', source, activeGangWar)
end

-- ========================================
-- EVENTOS DEL SERVIDOR
-- ========================================

RegisterNetEvent('gangwar:server:create')
AddEventHandler('gangwar:server:create', function(data)
    createGangWar(source, data)
end)

RegisterNetEvent('gangwar:server:end')
AddEventHandler('gangwar:server:end', function()
    endGangWar(source)
end)

RegisterNetEvent('gangwar:server:getInfo')
AddEventHandler('gangwar:server:getInfo', function()
    getGangWarInfo(source)
end)

RegisterNetEvent('gangwar:server:addParticipant')
AddEventHandler('gangwar:server:addParticipant', function(participantData)
    if activeGangWar then
        table.insert(activeGangWar.participants, {
            source = source,
            identifier = participantData.identifier,
            name = participantData.name,
            job = participantData.job,
            joinTime = GetGameTimer()
        })
        
        logGangWarEvent('participant_joined', {
            gangwar_id = activeGangWar.id,
            participant = participantData.name
        })
    end
end)

-- ========================================
-- EVENTOS ESX
-- ========================================

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    -- Sincronizar gang war activo con el jugador que se conecta
    if activeGangWar then
        SetTimeout(2000, function() -- Esperar a que el cliente esté listo
            TriggerClientEvent('gangwar:client:syncZone', playerId, activeGangWar)
        end)
    end
end)

AddEventHandler('esx:playerDropped', function(playerId, reason)
    -- Remover jugador de participantes si está en gang war
    if activeGangWar and activeGangWar.participants then
        for i, participant in ipairs(activeGangWar.participants) do
            if participant.source == playerId then
                table.remove(activeGangWar.participants, i)
                break
            end
        end
    end
end)

-- ========================================
-- COMANDOS DE ADMINISTRADOR
-- ========================================

RegisterCommand('gangwar_admin', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer or xPlayer.getGroup() ~= 'admin' then
        return
    end
    
    local action = args[1]
    
    if action == 'end' then
        if activeGangWar then
            endGangWar(source)
        else
            sendNotification(source, 'No hay gang war activo', 'error')
        end
    elseif action == 'info' then
        if activeGangWar then
            local info = string.format(
                'Gang War ID: %s\nCreador: %s\nTipo: %s\nDuración: %s min\nParticipantes: %s',
                activeGangWar.id,
                activeGangWar.creator.name,
                activeGangWar.type,
                activeGangWar.duration,
                #activeGangWar.participants
            )
            sendNotification(source, info, 'inform', 10000)
        else
            sendNotification(source, 'No hay gang war activo', 'error')
        end
    elseif action == 'history' then
        local count = tonumber(args[2]) or 5
        local recentEvents = {}
        
        for i = math.max(1, #gangWarHistory - count + 1), #gangWarHistory do
            table.insert(recentEvents, gangWarHistory[i])
        end
        
        print('[GangWar] Historial reciente:')
        for _, event in ipairs(recentEvents) do
            print(string.format('  %s: %s - %s', 
                os.date('%Y-%m-%d %H:%M:%S', event.timestamp),
                event.type,
                json.encode(event.data)
            ))
        end
    end
end, true)

-- ========================================
-- EXPORTS
-- ========================================

exports('getActiveGangWar', function() return activeGangWar end)
exports('isGangWarActive', function() return activeGangWar ~= nil end)
exports('getGangWarHistory', function() return gangWarHistory end)
exports('createGangWar', createGangWar)
exports('endGangWar', endGangWar)

-- ========================================
-- INICIALIZACIÓN
-- ========================================

CreateThread(function()
    print('[GangWar] Sistema iniciado correctamente')
    
    if Config.Debug then
        print('[GangWar] Modo debug activado')
        print('[GangWar] Trabajos autorizados:', json.encode(Config.AuthorizedJobs))
        print('[GangWar] Trabajos de policía:', json.encode(Config.PoliceJobs))
    end
end)