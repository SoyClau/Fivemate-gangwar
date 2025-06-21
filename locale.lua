Locale = {}

-- ========================================
-- MENSAJES DE MENÚ
-- ========================================

Locale.menu = {
    title = '🔫 Gang War Management',
    subtitle = 'Gestión de zonas de conflicto',
    
    create_title = '🚩 Iniciar Gang War',
    create_description = 'Crear una nueva zona de conflicto',
    
    end_title = '🏁 Finalizar Gang War',
    end_description = 'Terminar el gang war activo',
    
    status_title = '📊 Estado Actual',
    status_description = 'Ver información del gang war',
    
    no_permission = 'No tienes permisos para usar este menú',
    no_active_gangwar = 'No hay ningún gang war activo'
}

-- ========================================
-- MENSAJES DE NOTIFICACIONES
-- ========================================

Locale.notifications = {
    -- Éxito
    gangwar_started = 'Gang War iniciado en tu ubicación',
    gangwar_ended = 'Gang War finalizado correctamente',
    gangwar_auto_ended = 'El Gang War ha terminado automáticamente',
    police_can_enter = 'La policía ya puede intervenir en la zona',
    blue_zone_active = 'Zona azul activada - Policía puede intervenir',
    zone_will_disappear = 'La zona desaparecerá en %s minuto(s)',
    
    -- Errores
    no_permission = 'No tienes permisos para ejecutar esta acción',
    already_active = 'Ya hay un Gang War activo',
    no_active_gangwar = 'No hay ningún Gang War activo',
    too_close_players = 'Hay demasiados jugadores cerca para iniciar',
    
    -- Información
    zone_entered = 'Has entrado en una zona de Gang War',
    zone_exited = 'Has salido de la zona de Gang War',
    time_remaining = 'Tiempo restante: %s minutos'
}

-- ========================================
-- MENSAJES DE DISPATCH
-- ========================================

Locale.dispatch = {
    title = '🚨 GANG WAR DETECTADO',
    message = 'Se ha reportado un enfrentamiento entre organizaciones',
    location = 'Ubicación: %s',
    distance = 'Distancia: %sm',
    units_respond = 'Se requiere respuesta de unidades',
    zone_info = 'ZONA RESTRINGIDA - No intervenir hasta orden contraria',
    can_enter = '✅ ZONA LIBRE - Policía autorizada para intervenir'
}

-- ========================================
-- MENSAJES DE ESTADO
-- ========================================

Locale.status = {
    active = '🔴 ACTIVO',
    ending = '🔵 FINALIZANDO',
    inactive = '⚫ INACTIVO',
    
    info_location = 'Ubicación: %s, %s',
    info_time = 'Tiempo transcurrido: %s minutos',
    info_remaining = 'Tiempo restante: %s minutos',
    info_creator = 'Iniciado por: %s'
}

-- ========================================
-- MENSAJES DE ERROR
-- ========================================

Locale.errors = {
    invalid_job = 'Tu trabajo no está autorizado para crear gang wars',
    system_error = 'Error en el sistema de Gang War',
    invalid_location = 'Ubicación no válida para crear gang war',
    cooldown_active = 'Debes esperar antes de crear otro gang war'
}