-- ========================================
-- SISTEMA DE MENÚS
-- ========================================

-- Declarar funciones locales al inicio
local openCreateGangWarMenu
local confirmEndGangWar
local openQuickSettingsMenu

--- Abrir menú principal de gang war
local function openGangWarMenu()
    if not exports['FiveMate_Gangwar']:hasPermission() then
        lib.notify({
            title = Config.NotificationTitle,
            description = Locale.menu.no_permission,
            type = 'error'
        })
        return
    end
    
    local currentGangWar = exports['FiveMate_Gangwar']:getCurrentGangWar()
    
    local options = {
        {
            title = Locale.menu.create_title,
            description = Locale.menu.create_description,
            icon = 'flag',
            iconColor = 'red',
            disabled = currentGangWar ~= nil,
            onSelect = function()
                openCreateGangWarMenu()
            end
        },
        {
            title = Locale.menu.end_title,
            description = Locale.menu.end_description,
            icon = 'flag-checkered',
            iconColor = 'blue',
            disabled = currentGangWar == nil,
            onSelect = function()
                confirmEndGangWar()
            end
        },
        {
            title = Locale.menu.status_title,
            description = Locale.menu.status_description,
            icon = 'info',
            iconColor = 'yellow',
            disabled = currentGangWar == nil,
            onSelect = function()
                exports['FiveMate_Gangwar']:showGangWarInfo()
            end
        }
    }
    
    lib.registerContext({
        id = 'gangwar_main_menu',
        title = Locale.menu.title,
        options = options
    })
    
    lib.showContext('gangwar_main_menu')
end

--- Menú para crear gang war
openCreateGangWarMenu = function()
    local input = lib.inputDialog(Locale.menu.create_title, {
        {
            type = 'select',
            label = 'Tipo de Gang War',
            description = 'Selecciona el tipo de enfrentamiento',
            options = {
                {value = 'territory', label = '🏘️ Disputa Territorial'},
                {value = 'revenge', label = '⚔️ Venganza'},
                {value = 'business', label = '💰 Conflicto de Negocios'},
                {value = 'custom', label = '🎯 Personalizado'}
            },
            required = true,
            default = 'territory'
        },
        {
            type = 'input',
            label = 'Descripción (Opcional)',
            description = 'Describe brevemente el motivo del conflicto',
            placeholder = 'Ej: Disputa por el control del barrio...',
            max = 100
        }
    })
    
    if input then
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        TriggerServerEvent('gangwar:server:create', {
            coords = {
                x = playerCoords.x,
                y = playerCoords.y,
                z = playerCoords.z
            },
            type = input[1],
            description = input[2] or '',
            duration = Config.AutoEndTime -- Usar tiempo fijo del config
        })
    end
end

--- Confirmar finalización de gang war
confirmEndGangWar = function()
    local alert = lib.alertDialog({
        header = 'Confirmar Acción',
        content = '¿Estás seguro de que quieres finalizar el Gang War actual?',
        centered = true,
        cancel = true,
        labels = {
            cancel = 'Cancelar',
            confirm = 'Sí, finalizar'
        }
    })
    
    if alert == 'confirm' then
        TriggerServerEvent('gangwar:server:end')
    end
end

--- Menú de configuración rápida
openQuickSettingsMenu = function()
    local options = {
        {
            title = '⚡ Gang War Rápido',
            description = 'Crear gang war con configuración por defecto',
            icon = 'bolt',
            onSelect = function()
                local playerCoords = GetEntityCoords(PlayerPedId())
                
                TriggerServerEvent('gangwar:server:create', {
                    coords = {
                        x = playerCoords.x,
                        y = playerCoords.y,
                        z = playerCoords.z
                    },
                    type = 'territory',
                    description = 'Gang War iniciado rápidamente',
                    duration = Config.AutoEndTime
                })
            end
        },
        {
            title = '🎯 Gang War Personalizado',
            description = 'Crear con opciones avanzadas',
            icon = 'cog',
            onSelect = function()
                openCreateGangWarMenu()
            end
        }
    }
    
    lib.registerContext({
        id = 'gangwar_quick_menu',
        title = '⚡ Configuración Rápida',
        options = options
    })
    
    lib.showContext('gangwar_quick_menu')
end

--- Menú contextual (botón derecho)
local function openContextMenu()
    local currentGangWar = exports['FiveMate_Gangwar']:getCurrentGangWar()
    local isInZone = exports['FiveMate_Gangwar']:isInZone()
    
    local options = {}
    
    if currentGangWar then
        table.insert(options, {
            title = '📊 Estado del Gang War',
            description = 'Ver información detallada',
            icon = 'info-circle',
            onSelect = function()
                exports['FiveMate_Gangwar']:showGangWarInfo()
            end
        })
        
        if isInZone then
            table.insert(options, {
                title = '📍 Mi Posición',
                description = 'Estás dentro de la zona de conflicto',
                icon = 'map-marker',
                disabled = true
            })
        end
        
        table.insert(options, {
            title = '🏁 Finalizar Gang War',
            description = 'Terminar el conflicto actual',
            icon = 'flag-checkered',
            iconColor = 'red',
            onSelect = function()
                confirmEndGangWar()
            end
        })
    else
        table.insert(options, {
            title = '🚩 Iniciar Gang War',
            description = 'Crear nueva zona de conflicto',
            icon = 'flag',
            iconColor = 'red',
            onSelect = function()
                openQuickSettingsMenu()
            end
        })
    end
    
    if #options > 0 then
        lib.registerContext({
            id = 'gangwar_context_menu',
            title = '🔫 Gang War',
            options = options
        })
        
        lib.showContext('gangwar_context_menu')
    end
end

-- ========================================
-- EXPORTS
-- ========================================

exports('openGangWarMenu', openGangWarMenu)
exports('openCreateGangWarMenu', openCreateGangWarMenu)
exports('openContextMenu', openContextMenu)
exports('confirmEndGangWar', confirmEndGangWar)