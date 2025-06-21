-- ========================================
-- CONFIGURACIÓN PRIVADA DEL SERVIDOR
-- ========================================
-- Este archivo contiene configuraciones sensibles que NO deben estar en el cliente

ServerConfig = {}

-- ========================================
-- CONFIGURACIÓN DE WEBHOOKS
-- ========================================

ServerConfig.Webhook = {
    enabled = true, -- Activar/desactivar webhooks
    url = "https://discord.com/api/webhooks/1385982360331358238/F2oEqSOS1c1rxdn999t8tFEmzLPGs-gVLIf8k4IO1wBpdzi5yXAPb8pwHCQQZlH-_KGe", -- COLOCA TU URL DE WEBHOOK DE DISCORD AQUÍ
    botName = "Gang War System",
    color = {
        started = 15158332, -- Rojo para gang war iniciado (#E74C3C)
        ended = 3447003,   -- Azul para gang war terminado (#3498DB)  
        auto_ended = 10181046 -- Verde para finalizacion automatica (#2ECC71)
    }
}

-- ========================================
-- CONFIGURACIÓN DE DISPATCH POR SISTEMA
-- ========================================

ServerConfig.DispatchEvents = {
    ['origen'] = {
        eventName = "SendAlert:police",
        enabled = true
    },
    ['custom'] = {
        eventName = "tu:evento:personalizado", -- Cambiar por tu evento
        enabled = false
    }
    -- 'default' usa el sistema interno, no necesita configuración
}

-- ========================================
-- CONFIGURACIÓN DE SEGURIDAD
-- ========================================

ServerConfig.Security = {
    -- Límite de gang wars por jugador por hora
    playerCooldown = 2, -- máximo 2 gang wars por hora por jugador
    
    -- Distancia mínima entre gang wars simultáneos
    minDistance = 500.0, -- metros
    
    -- Verificar si el jugador tiene el trabajo requerido al crear
    strictJobCheck = true
}