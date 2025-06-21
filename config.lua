Config = {}

-- ========================================
-- CONFIGURACIÓN GENERAL
-- ========================================

-- Trabajos autorizados para crear gang wars
Config.AuthorizedJobs = {
    'mafia1',
    'mafia2',
    'mafia3',
    'cartel1',
    'cartel2',
    'cartel3',
    'cartel4',
    'cartel5',
    'cartel6',
    'ganga1',
    'ganga2',
    'ganga3',
    'ganga4',
    'ganga5',
    'ganga6',
    'ganga7',
    'ganga8',
    'ganga9',
    'ganga10',
    'ganga11',
    'ganga12',
    'ganga13',
}

-- Trabajos de policía
Config.PoliceJobs = {
    'police',
    'sheriff',
    'fbi',
}

-- ========================================
-- CONFIGURACIÓN DE DISPATCH
-- ========================================

-- Sistema de dispatch a utilizar
Config.DispatchSystem = "origen_police" -- Options: "cd_dispatch", "ps-dispatch", "linden_outlawalert", "qs-dispatch", "origen_police", "custom", "none"

-- Activar/desactivar sistema de dispatch
Config.UseDispatchSystem = true

-- ========================================
-- CONFIGURACIÓN DE ZONAS
-- ========================================

-- Radio de la zona de gangwar (en metros)
Config.ZoneRadius = 80.0

-- Tiempo de duración automática del gangwar (en minutos) - FIJO
Config.AutoEndTime = 15

-- Tiempo que la zona permanece azul antes de desaparecer (en minutos) - FIJO
Config.BlueZoneTime = 1

-- TIPO DE ZONA VISUAL - Elige el estilo que prefieras
Config.ZoneType = 'simple' -- Opciones: 'simple', 'advanced', 'dome', 'columns', 'minimal', 'sphere', 'barrier', 'fortress', 'oxlib'

-- Configuración específica por tipo de zona
Config.ZoneSettings = {
    simple = {
        height = 100.0,             -- Altura del cilindro (más alto)
        underground = 20.0,         -- Profundidad bajo tierra
        showText = true,            -- Mostrar texto informativo
        textDistance = 50.0,        -- Distancia para mostrar texto
        effects = false,            -- Sin efectos de partículas
        showTimer = true            -- Mostrar contador de tiempo
    },
    
    advanced = {
        height = 25.0,
        showText = true,
        textDistance = 80.0,
        effects = true,
        pulseEffect = true,         -- Efecto de pulso
        borderRings = 1             -- Anillos en el borde
    },
    
    dome = {
        height = 50.0,              -- Domo alto
        showText = true,
        textDistance = 100.0,
        effects = true,
        pulseEffect = true,
        domeStyle = true            -- Estilo cúpula
    },
    
    columns = {
        height = 80.0,              -- Columnas altas
        showText = true,
        textDistance = 120.0,
        effects = true,
        pulseEffect = true,
        columnCount = 12,           -- Número de columnas en perímetro
        columnHeight = 80.0
    },
    
    minimal = {
        height = 3.0,               -- Muy bajo, casi en el suelo
        showText = false,           -- Sin texto
        textDistance = 0.0,
        effects = false,            -- Minimalista
        onlyBlip = true            -- Solo blip en mapa
    },
    
    -- NUEVO: Domo esférico completo
    sphere = {
        height = 60.0,              -- Altura de la esfera
        showText = true,
        textDistance = 100.0,
        effects = true,
        pulseEffect = true,
        sphereLayers = 4,           -- Capas de la esfera
        sphereRadius = 0.8          -- Factor de radio para las capas
    },
    
    -- NUEVO: Barrera energética
    barrier = {
        height = 40.0,
        showText = true,
        textDistance = 90.0,
        effects = true,
        pulseEffect = true,
        barrierPosts = 8,           -- Postes de energía
        barrierHeight = 35.0,       -- Altura de los postes
        energyEffect = true         -- Efectos de energía
    },
    
    -- NUEVO: Fortaleza
    fortress = {
        height = 25.0,
        showText = true,
        textDistance = 110.0,
        effects = true,
        pulseEffect = false,
        wallCount = 16,             -- Número de secciones de muralla
        wallHeight = 20.0,          -- Altura de las murallas
        towerCount = 4,             -- Torres en las esquinas
        towerHeight = 35.0          -- Altura de las torres
    },
    
    -- NUEVO: ox_lib default (simple y redondo)
    oxlib = {
        height = 0,                 -- Sin altura (no se usa)
        showText = true,            -- Mostrar texto básico
        textDistance = 30.0,        -- Solo cuando estás muy cerca
        effects = false,            -- Sin efectos
        useDefaultDebug = true      -- Usar visualización por defecto de ox_lib
    }
}

-- Colores de las zonas (aumentada la opacidad)
Config.ZoneColors = {
    active = {r = 255, g = 0, b = 0, a = 180},    -- Rojo cuando está activo (más opaco)
    ending = {r = 0, g = 0, b = 255, a = 180}     -- Azul cuando puede entrar policía (más opaco)
}

-- ========================================
-- CONFIGURACIÓN DE COMANDOS
-- ========================================

-- Comando para abrir el menú de gangwar
Config.MenuCommand = 'gangwar'

-- ========================================
-- CONFIGURACIÓN DE NOTIFICACIONES
-- ========================================

-- Título para las notificaciones
Config.NotificationTitle = 'Gang War System'

-- Configuración del dispatch policial
Config.DispatchConfig = {
    enabled = true,
    title = '🚨 GANG WAR DETECTADO',
    coords_precision = 1, -- Precisión de coordenadas (0 = exactas, 1 = aproximadas)
    show_distance = true,
    blip_time = 300000 -- Tiempo del blip en el mapa (5 minutos)
}

-- ========================================
-- CONFIGURACIÓN DE BLIPS
-- ========================================

Config.BlipConfig = {
    sprite = 84,        -- Icono del blip
    color_active = 1,   -- Color rojo
    color_ending = 3,   -- Color azul
    scale = 1.5,
    label = 'Gang War Zone'
}

-- ========================================
-- CONFIGURACIÓN DE DEBUG
-- ========================================

Config.Debug = true -- Cambiar a true para mostrar mensajes de debug
