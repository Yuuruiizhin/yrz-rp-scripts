-- ============================================================
--  ox_stash_store | CONFIG
--  Configuración principal del script
-- ============================================================

Config = {}

-- ─── GENERAL ────────────────────────────────────────────────
Config.Debug = false                    -- Activar mensajes de debug en consola
Config.AdminGroup = 'admin'             -- Grupo requerido para acceder al panel de administración
Config.InteractionDistance = 2.0        -- Distancia en metros para interactuar con un punto
Config.BlipsEnabled = true              -- Mostrar blips en el mapa
Config.BlipsOnlyWithJob = true          -- Solo mostrar blips si tienes el job requerido
Config.BlipsToggleCommand = 'toggleblips' -- Comando para mostrar/ocultar blips
Config.DrawTextEnabled = true           -- Mostrar texto 3D sobre los puntos

-- ─── OX INVENTORY ───────────────────────────────────────────
Config.OxInventory = 'ox_inventory'     -- Nombre del recurso de OX Inventory
Config.StashMaxWeight = 100000          -- Peso máximo del stash (en gramos)
Config.StashMaxSlots = 50               -- Slots máximos del stash

-- ─── DISCORD WEBHOOKS ───────────────────────────────────────
Config.Webhooks = {
    stash_open     = 'https://discord.com/api/webhooks/1487902984972275824/54lILl5glzelVC3M21glvdEUOyX9hM9SRKzmoWwJFYBR63DVnJrxKXEMZNIEEzGAkbvE',    -- Webhook cuando alguien abre un stash
    stash_deposit  = 'https://discord.com/api/webhooks/1487902984972275824/54lILl5glzelVC3M21glvdEUOyX9hM9SRKzmoWwJFYBR63DVnJrxKXEMZNIEEzGAkbvE',    -- Webhook cuando alguien mete items al stash
    stash_withdraw = 'https://discord.com/api/webhooks/1487902984972275824/54lILl5glzelVC3M21glvdEUOyX9hM9SRKzmoWwJFYBR63DVnJrxKXEMZNIEEzGAkbvE',    -- Webhook cuando alguien saca items del stash
    shop_purchase  = 'https://discord.com/api/webhooks/1487902984972275824/54lILl5glzelVC3M21glvdEUOyX9hM9SRKzmoWwJFYBR63DVnJrxKXEMZNIEEzGAkbvE',    -- Webhook cuando alguien compra en una tienda
    admin_action   = 'https://discord.com/api/webhooks/1487902984972275824/54lILl5glzelVC3M21glvdEUOyX9hM9SRKzmoWwJFYBR63DVnJrxKXEMZNIEEzGAkbvE',    -- Webhook para acciones administrativas (crear/editar/borrar)
}

Config.WebhookBotName   = 'YRZ Advanced Storage Logs'
Config.WebhookAvatarURL = 'https://r2.fivemanage.com/hGUqZBBCPbN5ULtrKE55Y/logo_highpx.png' -- Avatar del bot en Discord

-- ─── COLORES DISCORD ────────────────────────────────────────
Config.Colors = {
    stash_open     = 3447003,    -- Azul
    stash_deposit  = 2067276,    -- Verde
    stash_withdraw = 15158332,   -- Rojo
    shop_purchase  = 15844367,   -- Naranja
    admin_create   = 1146986,    -- Verde oscuro
    admin_edit     = 16776960,   -- Amarillo
    admin_delete   = 16711680,   -- Rojo intenso
}

-- ─── BLIP CONFIG ────────────────────────────────────────────
Config.BlipConfig = {
    stash = {
        sprite  = 473,
        color   = 3,
        scale   = 0.8,
        label   = 'Almacenamiento',
    },
    shop = {
        sprite  = 52,
        color   = 2,
        scale   = 0.8,
        label   = 'Tienda',
    },
}

-- ─── IMÁGENES ───────────────────────────────────────────────
Config.ImageConfig = {
    basePath = 'nui://ox_inventory/web/images/',  -- Ruta NUI a ox_inventory
    defaultImage = 'default.png',
    useFallback = true,
}

-- ─── COLORES UI (HEX) ───────────────────────────────────────
-- Todos los colores de la interfaz gráfica. Modifica en formato #RRGGBB
Config.UIColors = {
    -- Colores primarios
    primaryAccent      = '#00d4ff',   -- Azul/Cyan principal
    secondaryAccent    = '#0098d9',   -- Azul más oscuro para hover
    tertiaryAccent     = '#005a8c',   -- Azul muy oscuro para estados
    
    -- Colores de estado
    success            = '#00e676',   -- Verde
    error              = '#ff3d57',   -- Rojo
    warning            = '#ffc107',   -- Amarillo (se reemplaza por azul)
    
    -- Bordes
    borderPrimaryColor = '#00d4ff',   -- Bordes azul
    borderOpacity      = 0.2,         -- Opacidad de bordes (0.0-1.0)
    borderSecondary    = '#0098d9',   -- Bordes azul secundario
    
    -- Textos
    textPrimary        = '#e8eaf0',   -- Texto principal (blanco)
    textSecondary      = '#7b8499',   -- Texto secundario (gris)
}

-- ─── PUNTOS POR DEFECTO (se cargan desde la DB al iniciar) ──
-- Estos son los puntos de ejemplo; en producción se gestionan desde el panel admin
Config.DefaultPoints = {
    -- Ejemplo de Stash
    -- {
    --     name        = 'Almacén Mecánico',
    --     category    = 'stash',
    --     coords      = vector3(0.0, 0.0, 0.0),
    --     job         = 'mechanic',
    --     max_weight  = 100000,
    --     max_slots   = 50,
    -- },
    -- Ejemplo de Tienda
    -- {
    --     name        = 'Tienda 24/7',
    --     category    = 'shop',
    --     coords      = vector3(0.0, 0.0, 0.0),
    --     job         = '',   -- Vacío = accesible para todos
    --     products    = {
    --         { name = 'water', label = 'Agua', price = 2 },
    --         { name = 'sandwich', label = 'Sándwich', price = 5 },
    --     },
    -- },
}
