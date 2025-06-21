# 🔫 FiveMate-GangWar

Sistema avanzado de gestión de Gang Wars para servidores FiveM con ESX, diseñado para controlar conflictos entre organizaciones de manera organizada y realista.

## 📋 Características Principales

- **Zonas Visuales**: Círculos rojos/azules que indican el estado del gang war
- **Sistema de Permisos**: Solo trabajos autorizados pueden crear gang wars
- **Timer Automático**: Después de 15 minutos la policía puede intervenir
- **Dispatch Policial**: Notificaciones automáticas a la policía
- **Menús Intuitivos**: Interfaz fácil de usar con ox_lib
- **Blips Dinámicos**: Marcadores en el mapa que cambian según el estado
- **Múltiples Integraciones**: Compatible con sistemas de dispatch populares

## 🎮 Funcionamiento

### Para Organizaciones Criminales
1. Usar comando `/gangwar` o tecla `F6` para abrir el menú
2. Seleccionar "Iniciar Gang War" y configurar opciones
3. Se crea una zona roja de restricción policial
4. Después del tiempo configurado, la zona se vuelve azul (policía puede entrar)
5. Finalizar manualmente cuando termine el conflicto

### Para Policía
1. Recibir dispatch automático cuando inicie un gang war
2. Ver zona roja en el mapa = NO INTERVENIR
3. Cuando la zona se vuelva azul = AUTORIZADO PARA INTERVENIR
4. Usar `/dispatches` o `F11` para ver gang wars activos

## 🛠️ Instalación

1. **Descargar y extraer** el recurso en tu carpeta de resources
2. **Configurar dependencias** en tu server.cfg:
   ```cfg
   ensure es_extended
   ensure ox_lib
   ensure fivemate-gangwar
   ```
3. **Personalizar configuración** en `config.lua`
4. **Ajustar traducciones** en `locale.lua` si es necesario

## ⚙️ Configuración

### Trabajos Autorizados
```lua
Config.AuthorizedJobs = {
    'mafia',
    'cartel',
    'gang',
    'ballas',
    'families',
    'vagos',
    'bloods',
    'crips'
}
```

### Trabajos de Policía
```lua
Config.PoliceJobs = {
    'police',
    'sheriff',
    'fbi',
    'swat'
}
```

### Configuración de Zona
```lua
Config.ZoneRadius = 150.0          -- Radio en metros
Config.AutoEndTime = 15            -- Minutos antes de permitir policía
```

## 🎨 Personalización Visual

### Colores de Zona
```lua
Config.ZoneColors = {
    active = {r = 255, g = 0, b = 0, a = 100},    -- Rojo (activo)
    ending = {r = 0, g = 0, b = 255, a = 100}     -- Azul (policía puede entrar)
}
```

### Configuración de Blips
```lua
Config.BlipConfig = {
    sprite = 84,           -- Icono del blip
    color_active = 1,      -- Color rojo
    color_ending = 3,      -- Color azul
    scale = 1.5,
    label = 'Gang War Zone'
}
```

## 📡 Sistema de Eventos

El recurso utiliza un sistema de eventos estandarizado con el formato `gangwar:category:action`:

### Eventos del Cliente
- `gangwar:client:syncZone` - Sincronizar zona con servidor
- `gangwar:client:updateZoneStatus` - Actualizar estado de zona
- `gangwar:client:notification` - Mostrar notificación
- `gangwar:client:dispatch` - Recibir dispatch policial
- `gangwar:client:enteredZone` - Jugador entró a zona
- `gangwar:client:exitedZone` - Jugador salió de zona

### Eventos del Servidor
- `gangwar:server:create` - Crear gang war
- `gangwar:server:end` - Finalizar gang war
- `gangwar:server:getInfo` - Obtener información
- `gangwar:server:sendDispatch` - Enviar dispatch
- `gangwar:server:addParticipant` - Agregar participante

## 🎯 Comandos

### Para Jugadores
- `/gangwar` - Abrir menú principal (también `F6`)
- `/dispatches` - Ver dispatches activos (solo policía, también `F11`)

### Para Administradores
- `/gangwar_admin end` - Finalizar gang war forzadamente
- `/gangwar_admin info` - Ver información del gang war activo
- `/gangwar_admin history [cantidad]` - Ver historial de events

## 🔧 Exports Disponibles

### Cliente
```lua
-- Verificar permisos
local hasPermission = exports.fivemate_gangwar:hasPermission()

-- Verificar si es policía
local isPolice = exports.fivemate_gangwar:isPolice()

-- Obtener gang war actual
local currentGangWar = exports.fivemate_gangwar:getCurrentGangWar()

-- Verificar si está en zona
local inZone = exports.fivemate_gangwar:isInZone()

-- Abrir menú
exports.fivemate_gangwar:openGangWarMenu()
```

### Servidor
```lua
-- Obtener gang war activo
local activeGangWar = exports.fivemate_gangwar:getActiveGangWar()

-- Verificar si hay gang war activo
local isActive = exports.fivemate_gangwar:isGangWarActive()

-- Crear gang war programáticamente
exports.fivemate_gangwar:createGangWar(source, gangWarData)

-- Finalizar gang war
exports.fivemate_gangwar:endGangWar(source)
```

## 🔌 Integraciones

### Sistemas de Dispatch Compatibles
- **cd_dispatch** - Integración automática
- **qs-dispatch** - Integración automática
- **Sistema personalizado** - Incluido por defecto

### Dependencias Requeridas
- **es_extended** - Framework ESX
- **ox_lib** - Para menús, notificaciones y zonas

## 🐛 Resolución de Problemas

### Problemas Comunes

**P: Los menús no aparecen**
R: Verifica que ox_lib esté actualizado y funcionando correctamente

**P: Los blips no se muestran**
R: Asegúrate de que el jugador tenga los permisos correctos y el trabajo esté en la lista autorizada

**P: La zona no es visible**
R: Verifica que Config.Debug esté en true para ver mensajes de error

**P: Los dispatches no llegan a la policía**
R: Confirma que los trabajos de policía estén correctamente configurados en Config.PoliceJobs

### Modo Debug
Activa el modo debug en `config.lua`:
```lua
Config.Debug = true
```

## 📝 Registro de Cambios

### Versión 1.0.0
- ✅ Sistema básico de gang wars
- ✅ Zonas visuales con colores dinámicos
- ✅ Sistema de dispatch policial
- ✅ Menús interactivos con ox_lib
- ✅ Blips y marcadores en el mapa
- ✅ Sistema de permisos por trabajo
- ✅ Timer automático para intervención policial
- ✅ Comandos de administración
- ✅ Exports para desarrolladores
- ✅ Integración con sistemas de dispatch populares

## 🤝 Soporte

Para soporte, reportar bugs o sugerir mejoras:
- Crea un issue en el repositorio
- Contacta al desarrollador
- Únete a la comunidad de FiveMate

## 📄 Licencia

Este recurso es de código abierto y está disponible bajo la licencia MIT.

---

**Desarrollado por FiveMate** 🚀
*Elevando la experiencia de roleplay en FiveM*