-- ========================================
-- EVENTOS PERSONALIZADOS
-- ========================================

RegisterNetEvent('gangwar:client:enteredZone')
AddEventHandler('gangwar:client:enteredZone', function(gangWarData)
    isInZone = true
    
    if Config.Debug then
        print('[GangWar] Jugador entró a la zona')
    end
end)

RegisterNetEvent('gangwar:client:exitedZone')
AddEventHandler('gangwar:client:exitedZone', function()
    isInZone = false
    
    if Config.Debug then
        print('[GangWar] Jugador salió de la zona')
    end
end)-- ========================================
-- VARIABLES GLOBALES
-- ========================================

local ESX = exports['es_extended']:getSharedObject()
local PlayerData = {}
local currentGangWar = nil
local isInZone = false
local gangWarBlip = nil

-- ========================================
-- EVENTOS ESX
-- ========================================

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- ========================================
-- FUNCIONES PRINCIPALES
-- ========================================

--- Verificar si el jugador tiene permiso para gestionar gang wars
--- @return boolean
local function hasPermission()
    if not PlayerData.job then return false end
    
    for _, job in pairs(Config.AuthorizedJobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

--- Verificar si el jugador es policía
--- @return boolean
local function isPolice()
    if not PlayerData.job then return false end
    
    for _, job in pairs(Config.PoliceJobs) do
        if PlayerData.job.name == job then
            return true
        end
    end
    return false
end

--- Crear notificación usando ox_lib
--- @param message string
--- @param type string
--- @param duration number
local function showNotification(message, type, duration)
    lib.notify({
        title = Config.NotificationTitle,
        description = message,
        type = type or 'inform',
        duration = duration or 5000
    })
end

--- Mostrar información del gang war activo
local function showGangWarInfo()
    if not currentGangWar then
        showNotification(Locale.notifications.no_active_gangwar, 'error')
        return
    end
    
    local timeElapsed = math.floor((GetGameTimer() - currentGangWar.startTime) / 60000)
    local timeRemaining = Config.AutoEndTime - timeElapsed
    
    local status = currentGangWar.canPoliceEnter and Locale.status.ending or Locale.status.active
    
    local alert = lib.alertDialog({
        header = Locale.menu.status_title,
        content = string.format([[
**Estado:** %s

**%s**

**%s**

**%s**
        ]], 
            status,
            string.format(Locale.status.info_location, currentGangWar.coords.x, currentGangWar.coords.y),
            string.format(Locale.status.info_time, timeElapsed),
            timeRemaining > 0 and string.format(Locale.status.info_remaining, timeRemaining) or 'Finalizando...'
        ),
        centered = true,
        cancel = true
    })
end

-- ========================================
-- COMANDOS
-- ========================================

RegisterCommand(Config.MenuCommand, function()
    if hasPermission() then
        exports['FiveMate_Gangwar']:openGangWarMenu()
    else
        showNotification(Locale.notifications.no_permission, 'error')
    end
end, false)

-- ========================================
-- KEYBINDING
-- ========================================

RegisterKeyMapping(Config.MenuCommand, 'Gang War Menu', 'keyboard', Config.MenuKey)

-- ========================================
-- EVENTOS DEL SERVIDOR
-- ========================================

RegisterNetEvent('gangwar:client:syncZone')
AddEventHandler('gangwar:client:syncZone', function(gangWarData)
    currentGangWar = gangWarData
    
    if gangWarData then
        -- Crear zona usando el export del archivo zones.lua
        exports['FiveMate_Gangwar']:createZone(gangWarData)
        -- Crear blip usando el export del archivo blips.lua
        exports['FiveMate_Gangwar']:createBlip(gangWarData)
        
        if Config.Debug then
            print('[GangWar] Zona sincronizada:', json.encode(gangWarData))
        end
    else
        -- Remover zona y blip
        exports['FiveMate_Gangwar']:removeZone()
        exports['FiveMate_Gangwar']:removeBlip()
        
        if Config.Debug then
            print('[GangWar] Zona removida')
        end
    end
end)

RegisterNetEvent('gangwar:client:updateZoneStatus')
AddEventHandler('gangwar:client:updateZoneStatus', function(canPoliceEnter, additionalData)
    if currentGangWar then
        currentGangWar.canPoliceEnter = canPoliceEnter
        
        -- Actualizar datos adicionales si se proporcionan
        if additionalData then
            if additionalData.manuallyEnded then
                currentGangWar.manuallyEnded = true
                currentGangWar.endTime = additionalData.endTime
            end
        end
        
        exports['FiveMate_Gangwar']:updateZoneColor(canPoliceEnter, additionalData)
        exports['FiveMate_Gangwar']:updateBlipColor(canPoliceEnter)
        
        -- Si el jugador está en la zona, actualizar el timer
        if isInZone then
            local zoneSettings = Config.ZoneSettings[Config.ZoneType]
            if zoneSettings and zoneSettings.showTimer then
                exports['FiveMate_Gangwar']:stopGangWarTimer()
                exports['FiveMate_Gangwar']:startGangWarTimer(currentGangWar)
            end
        end
        
        if canPoliceEnter then
            showNotification(Locale.notifications.police_can_enter, 'inform')
        end
    end
end)

RegisterNetEvent('gangwar:client:notification')
AddEventHandler('gangwar:client:notification', function(message, type, duration)
    showNotification(message, type, duration)
end)

RegisterNetEvent('gangwar:client:dispatch')
AddEventHandler('gangwar:client:dispatch', function(dispatchData)
    if isPolice() then
        exports['FiveMate_Gangwar']:showDispatch(dispatchData)
    end
end)

-- ========================================
-- EXPORTS
-- ========================================

exports('hasPermission', hasPermission)
exports('isPolice', isPolice)
exports('getCurrentGangWar', function() return currentGangWar end)
exports('isInZone', function() return isInZone end)
exports('showGangWarInfo', showGangWarInfo)

-- ========================================
-- THREAD PRINCIPAL (simplificado ya que ox_lib maneja la detección)
-- ========================================

CreateThread(function()
    while true do
        Wait(5000) -- Reducido a cada 5 segundos ya que ox_lib maneja la detección
        
        -- Solo mostrar información si hay gang war activo
        if currentGangWar then
            local timeElapsed = math.floor((GetGameTimer() - currentGangWar.startTime) / 60000)
            local timeRemaining = Config.AutoEndTime - timeElapsed
            
            if timeRemaining > 0 and timeRemaining <= 5 then
                -- Notificar cuando quedan pocos minutos
                showNotification(string.format(Locale.notifications.time_remaining, timeRemaining), 'inform', 3000)
            end
        end
    end
end)