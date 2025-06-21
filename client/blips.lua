-- ========================================
-- GESTIÓN DE BLIPS
-- ========================================

local activeBlips = {}

-- ========================================
-- FUNCIONES DE BLIPS
-- ========================================

--- Crear blip para gang war
--- @param gangWarData table
local function createBlip(gangWarData)
    if activeBlips.gangwar then
        RemoveBlip(activeBlips.gangwar)
    end
    
    local coords = vector3(gangWarData.coords.x, gangWarData.coords.y, gangWarData.coords.z)
    local color = gangWarData.canPoliceEnter and Config.BlipConfig.color_ending or Config.BlipConfig.color_active
    
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    SetBlipSprite(blip, Config.BlipConfig.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.BlipConfig.scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, false)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.BlipConfig.label)
    EndTextCommandSetBlipName(blip)
    
    -- Hacer que el blip parpadee si está activo
    if not gangWarData.canPoliceEnter then
        SetBlipFlashes(blip, true)
    end
    
    activeBlips.gangwar = blip
    
    if Config.Debug then
        print('[GangWar] Blip creado en:', coords)
    end
end

--- Remover blip de gang war
local function removeBlip()
    if activeBlips.gangwar then
        RemoveBlip(activeBlips.gangwar)
        activeBlips.gangwar = nil
        
        if Config.Debug then
            print('[GangWar] Blip removido')
        end
    end
end

--- Actualizar color del blip
--- @param canPoliceEnter boolean
local function updateBlipColor(canPoliceEnter)
    if activeBlips.gangwar then
        local color = canPoliceEnter and Config.BlipConfig.color_ending or Config.BlipConfig.color_active
        SetBlipColour(activeBlips.gangwar, color)
        
        -- Quitar parpadeo si la policía puede entrar
        if canPoliceEnter then
            SetBlipFlashes(activeBlips.gangwar, false)
        end
        
        if Config.Debug then
            print('[GangWar] Color de blip actualizado:', canPoliceEnter and 'azul' or 'rojo')
        end
    end
end

--- Crear blip de dispatch para policía
--- @param dispatchData table
local function createDispatchBlip(dispatchData)
    if not exports.FiveMate_Gangwar:isPolice() then
        return
    end
    
    local coords = vector3(dispatchData.coords.x, dispatchData.coords.y, dispatchData.coords.z)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    SetBlipSprite(blip, dispatchData.sprite or 161)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, dispatchData.scale or 1.2)
    SetBlipColour(blip, dispatchData.color or 1)
    SetBlipAsShortRange(blip, false)
    SetBlipFlashes(blip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(dispatchData.label or 'Gang War Dispatch')
    EndTextCommandSetBlipName(blip)
    
    -- Remover automáticamente después del tiempo especificado
    if dispatchData.duration then
        SetTimeout(dispatchData.duration, function()
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end)
    end
    
    -- Guardar referencia para actualizaciones
    activeBlips.dispatch = blip
    
    if Config.Debug then
        print('[GangWar] Blip de dispatch creado')
    end
end

--- Actualizar blip de dispatch
--- @param updateData table
local function updateDispatchBlip(updateData)
    if activeBlips.dispatch and DoesBlipExist(activeBlips.dispatch) then
        if updateData.color then
            SetBlipColour(activeBlips.dispatch, updateData.color)
        end
        
        if updateData.label then
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(updateData.label)
            EndTextCommandSetBlipName(activeBlips.dispatch)
        end
        
        -- Quitar parpadeo si la zona está libre
        if updateData.color == 2 then -- Verde
            SetBlipFlashes(activeBlips.dispatch, false)
        end
        
        if Config.Debug then
            print('[GangWar] Blip de dispatch actualizado')
        end
    end
end

--- Crear blip temporal
--- @param coords vector3
--- @param duration number
--- @param sprite number
--- @param color number
--- @param label string
local function createTemporaryBlip(coords, duration, sprite, color, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    SetBlipSprite(blip, sprite or 1)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.0)
    SetBlipColour(blip, color or 1)
    SetBlipAsShortRange(blip, true)
    
    if label then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(label)
        EndTextCommandSetBlipName(blip)
    end
    
    -- Remover después del tiempo especificado
    SetTimeout(duration or 30000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
    
    return blip
end

-- ========================================
-- EVENTOS
-- ========================================

RegisterNetEvent('gangwar:client:createDispatchBlip')
AddEventHandler('gangwar:client:createDispatchBlip', function(dispatchData)
    createDispatchBlip(dispatchData)
end)

RegisterNetEvent('gangwar:client:updateDispatchBlip')
AddEventHandler('gangwar:client:updateDispatchBlip', function(updateData)
    updateDispatchBlip(updateData)
end)

-- ========================================
-- LIMPIAR BLIPS AL DESCARGAR RECURSO
-- ========================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, blip in pairs(activeBlips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
    end
end)

-- ========================================
-- EXPORTS
-- ========================================

exports('createBlip', createBlip)
exports('removeBlip', removeBlip)
exports('updateBlipColor', updateBlipColor)
exports('createDispatchBlip', createDispatchBlip)
exports('updateDispatchBlip', updateDispatchBlip)
exports('createTemporaryBlip', createTemporaryBlip)