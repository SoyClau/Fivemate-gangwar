-- ========================================
-- GESTIÓN DE BLIPS - VERSIÓN SIMPLIFICADA
-- ========================================

local activeBlips = {}

-- ========================================
-- FUNCIONES DE BLIPS
-- ========================================

--- Crear blip para gang war
--- @param gangWarData table
local function createBlip(gangWarData)
    print('[GangWar] createBlip llamado')
    
    if not gangWarData or not gangWarData.coords then
        print('[GangWar] ERROR: Datos inválidos para blip')
        return
    end
    
    -- Remover blip anterior si existe
    if activeBlips.gangwar then
        print('[GangWar] Removiendo blip anterior')
        removeBlip()
    end
    
    -- Validar coordenadas
    local coords = gangWarData.coords
    if not coords.x or not coords.y or not coords.z then
        print('[GangWar] ERROR: Coordenadas inválidas para blip')
        return
    end
    
    print('[GangWar] Creando blip en:', coords.x, coords.y, coords.z)
    
    -- Crear blip con manejo de errores
    local success, result = pcall(function()
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        
        if not blip or blip == 0 then
            error("No se pudo crear el blip")
        end
        
        -- Configurar blip con valores seguros
        SetBlipSprite(blip, 84)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, 1.5)
        SetBlipColour(blip, gangWarData.canPoliceEnter and 3 or 1)
        SetBlipAsShortRange(blip, false)
        
        -- Configurar nombre del blip
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Gang War Zone")
        EndTextCommandSetBlipName(blip)
        
        return blip
    end)
    
    if success and result then
        activeBlips.gangwar = result
        print('[GangWar] Blip creado exitosamente con ID:', result)
    else
        print('[GangWar] ERROR al crear blip:', result)
    end
end

--- Remover blip de gang war
local function removeBlip()
    print('[GangWar] removeBlip llamado')
    
    if activeBlips.gangwar then
        local success, error = pcall(function()
            if DoesBlipExist(activeBlips.gangwar) then
                RemoveBlip(activeBlips.gangwar)
                print('[GangWar] Blip removido exitosamente')
            else
                print('[GangWar] El blip ya no existe')
            end
        end)
        
        if not success then
            print('[GangWar] ERROR al remover blip:', error)
        end
        
        activeBlips.gangwar = nil
    else
        print('[GangWar] No hay blip para remover')
    end
end

--- Actualizar color del blip
--- @param canPoliceEnter boolean
local function updateBlipColor(canPoliceEnter)
    print('[GangWar] updateBlipColor llamado:', canPoliceEnter)
    
    if activeBlips.gangwar and DoesBlipExist(activeBlips.gangwar) then
        local success, error = pcall(function()
            local color = canPoliceEnter and 3 or 1 -- Azul o Rojo
            SetBlipColour(activeBlips.gangwar, color)
            SetBlipFlashes(activeBlips.gangwar, not canPoliceEnter)
        end)
        
        if success then
            print('[GangWar] Color de blip actualizado exitosamente')
        else
            print('[GangWar] ERROR al actualizar color de blip:', error)
        end
    else
        print('[GangWar] No hay blip activo para actualizar')
    end
end

-- ========================================
-- LIMPIAR BLIPS AL DESCARGAR RECURSO
-- ========================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        print('[GangWar] Limpiando blips al descargar recurso')
        for key, blip in pairs(activeBlips) do
            if blip and DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        activeBlips = {}
    end
end)

-- ========================================
-- EXPORTS
-- ========================================

exports('createBlip', createBlip)
exports('removeBlip', removeBlip)
exports('updateBlipColor', updateBlipColor)
