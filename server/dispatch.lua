-- ========================================
-- SISTEMA DE DISPATCH POLICIAL
-- ========================================

local ESX = exports['es_extended']:getSharedObject()

-- ========================================
-- FUNCIÓN PRINCIPAL DE DISPATCH
-- ========================================

--- Enviar alerta de dispatch para gang wars
--- @param data table
function SendDispatchAlert(data)
    if not Config.UseDispatchSystem then 
        return 
    end
    
    -- CD Dispatch
    if Config.DispatchSystem == "cd_dispatch" then
        local dispatchData = {
            message = data.message,
            codeName = data.code or "10-90",
            coords = data.coords,
            blipSprite = data.blipSprite or 161,
            blipColour = data.blipColour or 1,
            blipScale = data.blipScale or 1.5,
            blipLength = data.blipLength or 2,
            blipFlash = data.blipFlash or false,
            sound = data.sound and 1 or 0,
            soundName = data.sound or "Lose_1st",
            infoM = data.info or "Gang War detectado - Zona restringida"
        }
        exports['cd_dispatch']:SendDispatch(dispatchData)
        
    -- PS Dispatch
    elseif Config.DispatchSystem == "ps-dispatch" then
        exports['ps-dispatch']:CustomAlert({
            coords = data.coords,
            message = data.message,
            dispatchCode = data.code or "10-90",
            description = data.info or "Gang War detectado - Zona restringida",
            radius = 0,
            sprite = data.blipSprite or 161,
            color = data.blipColour or 1,
            scale = data.blipScale or 1.5,
            length = data.blipLength or 2,
        })
        
    -- Linden OutlawAlert
    elseif Config.DispatchSystem == "linden_outlawalert" then
        local coords = data.coords or vector3(0.0, 0.0, 0.0)
        TriggerClientEvent('linden_outlawalert:triggerAlert', -1, {
            type = data.type or 'gangwar',
            coords = {x = coords.x, y = coords.y, z = coords.z},
            text = data.message
        })
        
    -- QS Dispatch
    elseif Config.DispatchSystem == "qs-dispatch" then
        exports['qs-dispatch']:CreateDispatchCall({
            job = {'police'},
            message = data.message,
            coords = data.coords,
            dispatchCode = data.code or "10-90",
            description = data.info or "Gang War detectado - Zona restringida",
            radius = 0,
            sprite = data.blipSprite or 161,
            color = data.blipColour or 1,
            scale = data.blipScale or 1.5,
            length = data.blipLength or 2,
        })
        
    -- Origen Police
    elseif Config.DispatchSystem == "origen_police" then
        exports['origen_police']:SendAlert({
            coords = data.coords,
            title = data.info or "Gang War detectado - Zona restringida",
            type = 'GENERAL',
            message = data.message,
            job = 'police',
        })
        
    -- Sistema personalizado
    elseif Config.DispatchSystem == "custom" then
        -- SISTEMA DE DISPATCH PERSONALIZADO
        -- Añade tu código de dispatch personalizado aquí
        
        -- Ejemplo:
        -- TriggerEvent('tu-dispatch:enviarAlerta', data)
        
        -- Notificación básica para policía si no hay sistema
        local xPlayers = ESX.GetExtendedPlayers()
        for _, xPlayer in pairs(xPlayers) do
            if isPoliceJob(xPlayer.job.name) then
                TriggerClientEvent('gangwar:client:notification', xPlayer.source, data.message, 'error', 8000)
            end
        end
    end
    
    if Config.Debug then
        print('[GangWar] Dispatch enviado via ' .. Config.DispatchSystem)
    end
end

-- ========================================
-- FUNCIONES DE DISPATCH
-- ========================================

--- Enviar dispatch a la policía sobre gang war
--- @param gangWarData table
local function sendDispatchToPolice(gangWarData)
    if not Config.DispatchConfig.enabled then
        return
    end
    
    local locationName = getLocationName(gangWarData.coords)
    
    -- Preparar datos para el dispatch
    local dispatchData = {
        coords = gangWarData.coords,
        message = string.format("🚨 GANG WAR DETECTADO\n📍 %s\n⚠️ ZONA RESTRINGIDA - NO INTERVENIR", locationName),
        code = "10-90",
        info = "Gang War detectado - Zona restringida para policía",
        type = "gangwar",
        blipSprite = 161,
        blipColour = 1,
        blipScale = 1.5,
        blipLength = 5,
        blipFlash = true,
        sound = "Lose_1st"
    }
    
    -- Enviar usando el sistema configurado
    SendDispatchAlert(dispatchData)
    
    -- Log del dispatch
    if Config.Debug then
        print(string.format('[GangWar] Dispatch enviado para Gang War ID: %s en %s', gangWarData.id, locationName))
    end
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
function getLocationName(coords)
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

--- Enviar actualización de dispatch cuando la policía puede intervenir
--- @param gangWarData table
local function sendPoliceCanEnterDispatch(gangWarData)
    if not Config.DispatchConfig.enabled then
        return
    end
    
    local locationName = getLocationName(gangWarData.coords)
    
    -- Preparar datos para el dispatch de autorización
    local dispatchData = {
        coords = gangWarData.coords,
        message = string.format("✅ AUTORIZACIÓN POLICIAL\n📍 %s\n🟢 INTERVENCIÓN AUTORIZADA", locationName),
        code = "10-22",
        info = "Gang War - Policía autorizada para intervenir",
        type = "gangwar_clear",
        blipSprite = 161,
        blipColour = 2, -- Verde
        blipScale = 1.2,
        blipLength = 3,
        blipFlash = false,
        sound = "CLICK_BACK"
    }
    
    -- Enviar usando el sistema configurado
    SendDispatchAlert(dispatchData)
    
    if Config.Debug then
        print('[GangWar] Dispatch de autorización enviado a la policía')
    end
end

--- Enviar dispatch personalizado
--- @param title string
--- @param message string
--- @param coords table
--- @param priority string
local function sendCustomDispatch(title, message, coords, priority)
    local dispatchData = {
        coords = coords,
        message = string.format("%s\n%s", title, message),
        code = priority == 'high' and "10-90" or "10-22",
        info = title,
        type = "custom",
        blipSprite = 161,
        blipColour = priority == 'high' and 1 or 3,
        blipScale = 1.3,
        blipLength = 4,
        blipFlash = priority == 'high',
        sound = priority == 'high' and "Lose_1st" or "CLICK_BACK"
    }
    
    SendDispatchAlert(dispatchData)
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
-- EXPORTS
-- ========================================

exports('SendDispatchAlert', SendDispatchAlert)
exports('sendDispatchToPolice', sendDispatchToPolice)
exports('sendPoliceCanEnterDispatch', sendPoliceCanEnterDispatch)
exports('sendCustomDispatch', sendCustomDispatch)
exports('getLocationName', getLocationName)
exports('isPoliceJob', isPoliceJob)
