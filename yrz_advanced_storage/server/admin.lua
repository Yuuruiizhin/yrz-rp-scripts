-- ============================================================
--  ox_stash_store | SERVER - ADMIN  (v2 - fixed)
-- ============================================================

local ESX = exports['es_extended']:getSharedObject()

local function IsAdmin(src)
    local xp = ESX.GetPlayerFromId(src)
    return xp and xp.getGroup() == Config.AdminGroup
end

local function GetAdminInfo(src)
    local license, discord = '', ''
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1,8) == 'license:' then license = id:sub(9) end
        if id:sub(1,8) == 'discord:' then discord = id:sub(9) end
    end
    return { source = src, name = GetPlayerName(src), license = license, discord = discord }
end

-- ─── COMANDO: Abrir panel admin ─────────────────────────────
-- El servidor manda los puntos directamente al abrir (sin callback)
RegisterCommand('stashadmin', function(src)
    if src == 0 then return end
    if not IsAdmin(src) then
        TriggerClientEvent('ox_stash_store:notify', src, 'Sin permisos.', 'error')
        return
    end
    -- Mandar puntos frescos de la DB al abrir el panel
    local points = DB_GetAllPoints()
    TriggerClientEvent('ox_stash_store:openAdminPanel', src, points, Config.UIColors)
end, false)

-- ─── CREAR PUNTO ────────────────────────────────────────────
RegisterNetEvent('ox_stash_store:admin:createPoint', function(data)
    local src = source
    if not IsAdmin(src) then return end

    if not data or not data.name or data.name == '' then
        TriggerClientEvent('ox_stash_store:notify', src, 'Nombre inválido.', 'error')
        return
    end

    local admin = GetAdminInfo(src)
    data.creator_license = admin.license
    data.creator_discord = admin.discord
    data.creator_name    = admin.name

    -- coords puede venir como tabla {x,y,z}
    if data.coords then
        data.coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    else
        TriggerClientEvent('ox_stash_store:notify', src, 'Coordenadas inválidas.', 'error')
        return
    end

    local newId = DB_CreatePoint(data)
    if not newId then
        TriggerClientEvent('ox_stash_store:notify', src, 'Error en la base de datos.', 'error')
        return
    end
    data.id = newId

    if data.category == 'shop' and data.products then
        DB_SetProducts(newId, data.products)
    end

    TriggerClientEvent('ox_stash_store:notify', src,
        ('Punto "%s" (ID:%d) creado.'):format(data.name, newId), 'success')

    Log_AdminAction(admin, 'create', data)
    RefreshPointsCache()
end)

-- ─── EDITAR PUNTO ───────────────────────────────────────────
RegisterNetEvent('ox_stash_store:admin:editPoint', function(id, data)
    local src = source
    if not IsAdmin(src) then return end
    if not id or not data then return end

    if data.coords then
        data.coords = vector3(data.coords.x, data.coords.y, data.coords.z)
    end

    DB_UpdatePoint(id, data)

    if data.category == 'shop' and data.products then
        DB_SetProducts(id, data.products)
    end

    local admin = GetAdminInfo(src)
    data.id = id
    TriggerClientEvent('ox_stash_store:notify', src,
        ('Punto ID:%d actualizado.'):format(id), 'success')

    Log_AdminAction(admin, 'edit', data)
    RefreshPointsCache()
end)

-- ─── BORRAR PUNTO ───────────────────────────────────────────
RegisterNetEvent('ox_stash_store:admin:deletePoint', function(id)
    local src = source
    if not IsAdmin(src) then return end
    if not id then return end

    -- Guardar datos para el log antes de borrar
    local all = DB_GetAllPoints()
    local pointData = { id = id, name = '?', category = '?', job = '' }
    for _, p in ipairs(all) do
        if p.id == id then pointData = p; break end
    end

    DB_DeletePoint(id)

    local admin = GetAdminInfo(src)
    TriggerClientEvent('ox_stash_store:notify', src,
        ('Punto ID:%d eliminado.'):format(id), 'success')

    Log_AdminAction(admin, 'delete', pointData)
    RefreshPointsCache()
end)
