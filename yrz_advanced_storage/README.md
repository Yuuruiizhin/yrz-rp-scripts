# 📦 ox_stash_store

**Sistema de Almacenamiento y Tienda** para FiveM/ESX compatible directamente con **OX-Inventory**.

---

## 🔧 Dependencias

| Recurso | Uso |
|---|---|
| `es_extended` | Framework ESX |
| `ox_inventory` | Inventario |
| `ox_lib` | Notificaciones / TextUI |
| `oxmysql` | Base de datos |

---

## 📁 Estructura del Proyecto

```
ox_stash_store/
├── fxmanifest.lua
├── ox_stash_store.sql          ← Ejecutar en tu BD primero
├── config/
│   └── config.lua              ← Configuración principal
├── client/
│   ├── main.lua                ← Lógica cliente principal
│   ├── ui.lua                  ← TextUI de interacción
│   └── blips.lua               ← Blips del mapa
├── server/
│   ├── main.lua                ← Lógica servidor principal
│   ├── admin.lua               ← Endpoints de administración
│   ├── logs.lua                ← Discord Webhooks
│   └── database.lua            ← Funciones de base de datos
└── html/
    ├── index.html
    ├── css/style.css
    └── js/
        ├── app.js              ← UI tienda + bridge NUI
        └── admin.js            ← Panel de administración
```

---

## 🚀 Instalación

1. **Importar SQL** — Ejecuta `ox_stash_store.sql` en tu base de datos.
2. **Copiar el recurso** — Pega la carpeta en `resources/[local]/`.
3. **Agregar al server.cfg**:
   ```
   ensure ox_stash_store
   ```
4. **Configurar** — Edita `config/config.lua`:
   - Agrega tus **Discord Webhooks**
   - Ajusta el **grupo admin** (`Config.AdminGroup`)
   - Configura pesos y slots por defecto

---

## ⚙️ Configuración (config.lua)

```lua
Config.AdminGroup        = 'admin'     -- Grupo que puede usar /stashadmin
Config.InteractionDistance = 2.0       -- Metros para interactuar
Config.BlipsEnabled      = true        -- Blips en el mapa
Config.BlipsOnlyWithJob  = true        -- Solo mostrar blips si tienes el job requerido
Config.BlipsToggleCommand = 'toggleblips' -- Comando para mostrar/ocultar blips

Config.Webhooks = {
    stash_open     = 'TU_WEBHOOK_AQUI',
    stash_deposit  = 'TU_WEBHOOK_AQUI',
    stash_withdraw = 'TU_WEBHOOK_AQUI',
    shop_purchase  = 'TU_WEBHOOK_AQUI',
    admin_action   = 'TU_WEBHOOK_AQUI',
}
```

---

## 🗺️ Blips en el Mapa

Los blips se muestran automáticamente en el mapa según la configuración:

### Configuración de Blips
```lua
Config.BlipsEnabled      = true        -- Activar/desactivar blips globalmente
Config.BlipsOnlyWithJob  = true        -- Solo mostrar blips si tienes el job requerido
Config.BlipsToggleCommand = 'toggleblips' -- Comando para mostrar/ocultar blips
```

### Comportamiento
- **Sin restricción de job**: Los blips se muestran para todos los jugadores
- **Con restricción de job**: Solo se muestran los blips de puntos que puedes acceder
- **Toggle manual**: Usa `/toggleblips` para mostrar/ocultar todos los blips visibles
- **Actualización automática**: Los blips se actualizan automáticamente cuando cambias de job
- **Monitoreo continuo**: Sistema de respaldo que verifica cambios de job cada 10 segundos

### Configuración Visual
```lua
Config.BlipConfig = {
    stash = { sprite = 473, color = 3, scale = 0.8, label = 'Almacenamiento' },
    shop  = { sprite = 52,  color = 2, scale = 0.8, label = 'Tienda' },
}
```

---

## 🎮 Comandos

| Comando | Descripción | Permiso |
|---|---|---|
| `/stashadmin` | Abrir panel de administración | `admin` |
| `/toggleblips` | Mostrar/ocultar blips en el mapa | Todos |
| `/debugblips` | Forzar actualización de blips (solo debug) | Todos |

### Interacción en el mundo
- **[E]** — Interactuar con un punto (stash o tienda) al acercarte

---

## 📊 Datos de cada Punto

| Campo | Descripción |
|---|---|
| `id` | ID único auto-generado |
| `name` | Nombre del punto |
| `category` | `stash` o `shop` |
| `coords` | Coordenadas X, Y, Z |
| `job` | Job requerido (vacío = público) |
| `max_weight` | Peso máximo del stash en gramos |
| `max_slots` | Slots máximos del stash |
| `creator_license` | License del admin que lo creó |
| `creator_discord` | Discord ID del admin que lo creó |
| `creator_name` | Nombre del admin que lo creó |

---

## 📡 Discord Logs

Cada acción genera un embed diferente en Discord:

| Evento | Webhook | Color |
|---|---|---|
| Stash abierto | `stash_open` | 🔵 Azul |
| Item depositado | `stash_deposit` | 🟢 Verde |
| Item retirado | `stash_withdraw` | 🔴 Rojo |
| Compra en tienda | `shop_purchase` | 🟠 Naranja |
| Acción admin (crear/editar/borrar) | `admin_action` | Variable |

---

## 🔒 Seguridad

- El panel admin **solo es accesible** con el grupo configurado en `Config.AdminGroup`
- Todas las acciones del servidor **verifican el grupo** antes de ejecutar
- El comando `/stashadmin` se ignora si el jugador no tiene el grupo correcto
- Los jobs se verifican **server-side** para evitar exploits

---

## 🛒 Integración OX Inventory

Los stashes se registran automáticamente con:
```lua
exports['ox_inventory']:RegisterStash(
    'ox_stash_' .. id,   -- identificador único
    name,                -- nombre mostrado
    max_slots,
    max_weight
)
```

Los nombres de items en las tiendas **deben coincidir** exactamente con los registros en OX Inventory.

---

## 📝 Licencia

Script desarrollado para uso privado en servidores de FiveM con ESX + OX Inventory.
