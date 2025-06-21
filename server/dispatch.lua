-- ========================================
-- SISTEMA DE DISPATCH POLICIAL
-- ========================================

local ESX = exports['es_extended']:getSharedObject()

-- ========================================
-- FUNCIONES DE DISPATCH
-- ========================================

--- Enviar dispatch a la policía sobre gang war
--- @param gangWarData table
local function sendDispatchToPolice(gangWarData)
    if not Config.DispatchConfig.enabled then
        return
    end
    
    local xPlayers = ESX.GetExtendedPlayers()
    local policeCount = 0
    
    for _, xPlayer in pairs(xPlayers) do
        if isPoliceJob(xPlayer.job.name) then
            policeCount = policeCount + 1
            
            local playerCoords = xPlayer.getCoords(true)
            local distance = #(playerCoords - vector3(gangWarData.coords.x, gangWarData.coords.y, gangWarData.coords.z))
            
            -- Preparar datos del dispatch
            local dispatchData = {
                id = gangWarData.id,
                title = Config.DispatchConfig.title,
                message = Locale.dispatch.message,
                location = getLocationName(gangWarData.coords),
                coords = gangWarData.coords,
                distance = math.floor(distance),
                time = os.date('%H:%M:%S'),
                type = gangWarData.type,
                priority = 'high',
                units_needed = calculateUnitsNeeded(gangWarData),
                restrictions = {
                    canEnter = false,
                    timeRemaining = gangWarData.duration
                }
            }
            
            -- Enviar dispatch al cliente
            TriggerClientEvent('gangwar:client:dispatch', xPlayer.source, dispatchData)
            
            -- Crear blip temporal en el mapa
            TriggerClientEvent('gangwar:client:createDispatchBlip', xPlayer.source, {
                coords = gangWarData.coords,
                sprite = 161, -- Icono de advertencia
                color = 1,    -- Rojo
                scale = 1.2,
                label = 'Gang War - Zona Restringida',
                duration = Config.DispatchConfig.blip_time
            })
            
            if Config.Debug then
                print(string.format('[GangWar] Dispatch enviado a %s (Distancia: %sm)', xPlayer.getName(), distance))
            end
        end
    end
    
    -- Log del dispatch
    print(string.format('[GangWar] Dispatch enviado a %d oficiales de policía', policeCount))
end

--- Verificar si un trabajo es de policía
--- @param jobName string
--- @return boolean
function isPoliceJob(jobName)
    for _, job in pairs(Config.PoliceJobs) do
        if job == jobName then
            return true
        end
    end
    return false
end

--- Obtener nombre de ubicación basado en coordenadas
--- @param coords table
--- @return string
local function getLocationName(coords)
    -- Ubicaciones conocidas en el mapa
    local locations = {
        {name = "Los Santos International Airport", coords = vector3(-1037.0, -2738.0, 13.8), radius = 500},
        {name = "Vinewood Hills", coords = vector3(127.0, 566.0, 183.9), radius = 400},
        {name = "Downtown Los Santos", coords = vector3(215.0, -810.0, 30.7), radius = 300},
        {name = "Vespucci Beach", coords = vector3(-1375.0, -1026.0, 13.0), radius = 250},
        {name = "Grove Street", coords = vector3(-127.0, -1611.0, 32.5), radius = 200},
        {name = "Ballas Territory", coords = vector3(84.3, -1959.5, 21.1), radius = 200},
        {name = "Families Territory", coords = vector3(-127.7, -1611.8, 32.5), radius = 200},
        {name = "Vagos Territory", coords = vector3(331.2, -2012.0, 22.5), radius = 200},
        {name = "Sandy Shores", coords = vector3(1836.0, 3672.0, 34.2), radius = 400},
        {name = "Paleto Bay", coords = vector3(-448.0, 6019.0, 31.7), radius = 300},
        {name = "Mount Chiliad", coords = vector3(425.0, 5614.0, 766.5), radius = 500},
        {name = "Port of Los Santos", coords = vector3(1201.0, -3253.0, 5.8), radius = 300}
    }
    
    local targetCoords = vector3(coords.x, coords.y, coords.z)
    
    for _, location in pairs(locations) do
        local distance = #(targetCoords - location.coords)
        if distance <= location.radius then
            return location.name
        end
    end
    
    -- Si no encuentra una ubicación específica, usar zona general
    if coords.x > 0 and coords.y > 0 then
        return "North East Los Santos"
    elseif coords.x < 0 and coords.y > 0 then
        return "North West Los Santos"
    elseif coords.x < 0 and coords.y < 0 then
        return "South West Los Santos"
    else
        return "South East Los Santos"
    end
end

--- Calcular unidades necesarias basado en el tipo de gang war
--- @param gangWarData table
--- @return number
local function calculateUnitsNeeded(gangWarData)
    local baseUnits = 2
    
    if gangWarData.type == 'territory' then
        return baseUnits + 2
    elseif gangWarData.type == 'revenge' then
        return baseUnits + 3
    elseif gangWarData.type == 'business' then
        return baseUnits + 1
    else
        return baseUnits
    end
end

--- Enviar actualización de dispatch cuando la policía puede intervenir
--- @param gangWarData table
local function sendPoliceCanEnterDispatch(gangWarData)
    local xPlayers = ESX.GetExtendedPlayers()
    
    for _, xPlayer in pairs(xPlayers) do
        if isPoliceJob(xPlayer.job.name) then
            local updateData = {
                id = gangWarData.id,
                title = '✅ AUTORIZACIÓN POLICIAL',
                message = Locale.dispatch.can_enter,
                location = getLocationName(gangWarData.coords),
                coords = gangWarData.coords,
                canEnter = true,
                priority = 'medium'
            }
            
            TriggerClientEvent('gangwar:client:dispatchUpdate', xPlayer.source, updateData)
            
            -- Actualizar blip a color verde
            TriggerClientEvent('gangwar:client:updateDispatchBlip', xPlayer.source, {
                coords = gangWarData.coords,
                color = 2, -- Verde
                label = 'Gang War - Intervención Autorizada'
            })
        end
    end
    
    print('[GangWar] Dispatch de autorización enviado a la policía')
end

--- Enviar dispatch personalizado
--- @param title string
--- @param message string
--- @param coords table
--- @param priority string
local function sendCustomDispatch(title, message, coords, priority)
    local xPlayers = ESX.GetExtendedPlayers()
    
    for _, xPlayer in pairs(xPlayers) do
        if isPoliceJob(xPlayer.job.name) then
            local dispatchData = {
                title = title,
                message = message,
                location = getLocationName(coords),
                coords = coords,
                priority = priority or 'medium',
                time = os.date('%H:%M:%S')
            }
            
            TriggerClientEvent('gangwar:client:dispatch', xPlayer.source, dispatchData)
        end
    end
end

-- ========================================
-- EVENTOS DEL SERVIDOR
-- ========================================

RegisterNetEvent('gangwar:server:sendDispatch')
AddEventHandler('gangwar:server:sendDispatch', function(gangWarData)
    sendDispatchToPolice(gangWarData)
end)

RegisterNetEvent('gangwar:server:policeCanEnter')
AddEventHandler('gangwar:server:policeCanEnter', function(gangWarData)
    sendPoliceCanEnterDispatch(gangWarData)
end)

RegisterNetEvent('gangwar:server:customDispatch')
AddEventHandler('gangwar:server:customDispatch', function(title, message, coords, priority)
    sendCustomDispatch(title, message, coords, priority)
end)

-- ========================================
-- INTEGRACIÓN CON SISTEMAS DE DISPATCH EXTERNOS
-- ========================================

--- Integración con cd_dispatch (si está disponible)
local function sendCDDispatch(gangWarData)
    if GetResourceState('cd_dispatch') == 'started' then
        local data = exports['cd_dispatch']:GetPlayerInfo()
        
        TriggerEvent('cd_dispatch:AddNotification', {
            job_table = Config.PoliceJobs,
            coords = gangWarData.coords,
            title = Config.DispatchConfig.title,
            message = Locale.dispatch.message .. '\n' .. Locale.dispatch.zone_info,
            flash = true,
            unique_id = tostring(gangWarData.id),
            blip = {
                sprite = 161,
                scale = 1.2,
                colour = 1,
                flashes = true,
                text = 'Gang War Zone'
            }
        })
        
        if Config.Debug then
            print('[GangWar] Dispatch enviado via cd_dispatch')
        end
    end
end

--- Integración con qs-dispatch (si está disponible)
local function sendQSDispatch(gangWarData)
    if GetResourceState('qs-dispatch') == 'started' then
        exports['qs-dispatch']:CreateDispatchCall({
            job = Config.PoliceJobs,
            callLocation = gangWarData.coords,
            callCode = { name = 'Gang War', color = 1 },
            message = Locale.dispatch.message,
            flashes = true,
            image = nil,
            blip = {
                sprite = 161,
                scale = 1.2,
                colour = 1,
                flashes = true,
                text = 'Gang War Zone'
            }
        })
        
        if Config.Debug then
            print('[GangWar] Dispatch enviado via qs-dispatch')
        end
    end
end

-- ========================================
-- EXPORTS
-- ========================================

exports('sendDispatchToPolice', sendDispatchToPolice)
exports('sendPoliceCanEnterDispatch', sendPoliceCanEnterDispatch)
exports('sendCustomDispatch', sendCustomDispatch)
exports('getLocationName', getLocationName)
exports('isPoliceJob', isPoliceJob)