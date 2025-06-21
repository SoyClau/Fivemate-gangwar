-- ========================================
-- GESTIÓN DE ZONAS VISUALES - VERSIÓN SIMPLIFICADA
-- ========================================

local activeZone = nil
local currentGangWarData = nil

-- ========================================
-- FUNCIONES PRINCIPALES
-- ========================================

--- Crear zona visual para el gang war
--- @param gangWarData table
local function createZone(gangWarData)
    print('[GangWar] createZone llamado con datos:', json.encode(gangWarData))
    
    if not gangWarData then
        print('[GangWar] ERROR: No hay datos de gang war')
        return
    end
    
    if not gangWarData.coords then
        print('[GangWar] ERROR: No hay coordenadas en los datos')
        return
    end
    
    if activeZone then
        print('[GangWar] Removiendo zona anterior')
        removeZone()
    end
    
    -- Validar coordenadas individualmente
    if not gangWarData.coords.x or not gangWarData.coords.y or not gangWarData.coords.z then
        print('[GangWar] ERROR: Coordenadas inválidas:', gangWarData.coords.x, gangWarData.coords.y, gangWarData.coords.z)
        return
    end
    
    local coords = vector3(gangWarData.coords.x, gangWarData.coords.y, gangWarData.coords.z)
    print('[GangWar] Coordenadas procesadas:', coords)
    
    -- Almacenar datos globalmente
    currentGangWarData = gangWarData
    
    -- Crear zona usando ox_lib con manejo de errores
    local success, error = pcall(function()
        activeZone = lib.zones.sphere({
            coords = coords,
            radius = Config.ZoneRadius or 80.0,
            debug = Config.Debug or false,
            onEnter = function()
                print('[GangWar] Jugador entró a la zona')
                lib.notify({
                    title = 'Gang War',
                    description = 'Has entrado en una zona de Gang War',
                    type = 'inform'
                })
                TriggerEvent('gangwar:client:enteredZone', gangWarData)
            end,
            onExit = function()
                print('[GangWar] Jugador salió de la zona')
                lib.notify({
                    title = 'Gang War',
                    description = 'Has salido de la zona de Gang War',
                    type = 'inform'
                })
                TriggerEvent('gangwar:client:exitedZone')
            end
        })
    end)
    
    if success then
        print('[GangWar] Zona creada exitosamente')
        
        -- Crear visualización simple
        createSimpleVisual(coords, gangWarData)
    else
        print('[GangWar] ERROR al crear zona:', error)
    end
end

--- Crear visualización simple sin efectos complejos
--- @param coords vector3
--- @param gangWarData table
local function createSimpleVisual(coords, gangWarData)
    print('[GangWar] Creando visualización simple')
    
    CreateThread(function()
        while activeZone do
            Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - coords)
            
            if distance < 200.0 then
                local color = gangWarData.canPoliceEnter and {r = 0, g = 0, b = 255, a = 100} or {r = 255, g = 0, b = 0, a = 100}
                
                -- Dibujar un marcador simple
                DrawMarker(
                    1, -- Cilindro
                    coords.x, coords.y, coords.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    (Config.ZoneRadius or 80.0) * 2.0, (Config.ZoneRadius or 80.0) * 2.0, 50.0,
                    color.r, color.g, color.b, color.a,
                    false, true, 2, false, nil, nil, false
                )
            else
                Wait(1000)
            end
        end
        print('[GangWar] Thread de visualización terminado')
    end)
end

--- Remover zona activa
local function removeZone()
    print('[GangWar] removeZone llamado')
    
    if activeZone then
        local success, error = pcall(function()
            activeZone:remove()
        end)
        
        if success then
            print('[GangWar] Zona removida exitosamente')
        else
            print('[GangWar] ERROR al remover zona:', error)
        end
        
        activeZone = nil
    end
    
    currentGangWarData = nil
end

--- Actualizar color de la zona
--- @param canPoliceEnter boolean
--- @param additionalData table|nil
local function updateZoneColor(canPoliceEnter, additionalData)
    print('[GangWar] updateZoneColor llamado:', canPoliceEnter)
    
    if currentGangWarData then
        currentGangWarData.canPoliceEnter = canPoliceEnter
        
        if additionalData then
            if additionalData.manuallyEnded then
                currentGangWarData.manuallyEnded = true
                currentGangWarData.endTime = additionalData.endTime
            end
        end
        
        print('[GangWar] Color de zona actualizado')
    end
end

-- ========================================
-- EXPORTS
-- ========================================

exports('createZone', createZone)
exports('removeZone', removeZone)
exports('updateZoneColor', updateZoneColor)
