-- ============================================================
--  ox_stash_store | SERVER - MAIN  (v2 - fixed)
-- ============================================================

local ESX    = exports['es_extended']:getSharedObject()
local Points = {}

-- ─── HELPER: Construir URL de imagen desde ox_inventory ──────
local function GetImagePath(itemName, imageField)
    if not itemName then 
        return Config.ImageConfig.basePath .. (Config.ImageConfig.defaultImage or 'default.png')
    end
    
    local basePath = Config.ImageConfig.basePath or 'nui://ox_inventory/web/images/'
    local defaultImg = Config.ImageConfig.defaultImage or 'default.png'
    
    -- Si ox_inventory provee image field, usarlo
    if imageField and imageField ~= '' then
        -- Si ya tiene la ruta completa, devolverla
        if imageField:sub(1, 6) == 'nui://' or imageField:sub(1, 7) == 'http://' or imageField:sub(1, 8) == 'https://' then
            return imageField
        end
        -- Si es solo el nombre, agregar basePath
        return basePath .. imageField
    end
    
    -- Construir desde itemName
    return basePath .. itemName .. '.png'
end

-- ─── HELPER: Info del jugador ────────────────────────────────
local function GetPlayerInfo(src)
    local license = ''
    local discord = ''
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1,8)  == 'license:' then license = id:sub(9)  end
        if id:sub(1,8)  == 'discord:' then discord = id:sub(9)  end
    end
    return {
        source  = src,
        name    = GetPlayerName(src) or 'Desconocido',
        license = license,
        discord = discord,
        xPlayer = ESX.GetPlayerFromId(src),
    }
end

-- ─── HELPER: Registrar un stash en OX ───────────────────────
local function RegisterOxStash(p)
    local success, err = pcall(function()
        exports.ox_inventory:RegisterStash(
            ('ox_stash_%d'):format(p.id),
            p.name,
            p.max_slots  or Config.StashMaxSlots,
            p.max_weight or Config.StashMaxWeight
        )
    end)
    if not success then
        print(('^1[yrz_advanced_storage] Error registering stash %s: %s^0'):format(p.name, err))
    else
        print(('^2[yrz_advanced_storage] Successfully registered stash: %s^0'):format(p.name))
    end
end

-- ─── CARGA INICIAL ──────────────────────────────────────────
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    Wait(1500)

    Points = DB_GetAllPoints()

    for _, p in ipairs(Points) do
        if p.category == 'stash' then
            RegisterOxStash(p)
        end
    end

    if Config.Debug then
        print(('^2[ox_stash_store]^7 %d puntos cargados.'):format(#Points))
    end
end)

-- Sincronizar puntos al jugador cuando entra
AddEventHandler('esx:playerLoaded', function(playerId)
    Wait(1000)
    TriggerClientEvent('ox_stash_store:syncPoints', playerId, Points)
end)

-- ─── FUNCIÓN GLOBAL: Actualizar cache y notificar clientes ──
function RefreshPointsCache()
    Points = DB_GetAllPoints()

    for _, p in ipairs(Points) do
        if p.category == 'stash' then
            RegisterOxStash(p)
        end
    end

    -- Sincronizar a todos los clientes
    TriggerClientEvent('ox_stash_store:syncPoints', -1, Points)
    -- Mandar actualización específica al panel admin si está abierto
    TriggerClientEvent('ox_stash_store:adminPointsUpdated', -1, Points)
end

-- ─── ABRIR STASH ────────────────────────────────────────────
RegisterNetEvent('ox_stash_store:openStash', function(pointId)
    local src   = source
    local point = nil
    for _, p in ipairs(Points) do
        if p.id == pointId then point = p; break end
    end
    if not point then return end

    local player = GetPlayerInfo(src)

    -- Verificar job
    if point.job and point.job ~= '' then
        if not player.xPlayer or player.xPlayer.job.name ~= point.job then
            TriggerClientEvent('ox_stash_store:notify', src, 'No tienes acceso a este almacén.', 'error')
            return
        end
    end

    -- Obtener inventarios
    local stashId = ('ox_stash_%d'):format(pointId)
    local stashInv = exports.ox_inventory:GetInventory(stashId, false)
    local playerInv = exports.ox_inventory:GetInventory(src, false)

    -- Enviar datos al cliente para abrir UI custom
    TriggerClientEvent('ox_stash_store:openStashUI', src, point, stashInv, playerInv, Config.ImageConfig, Config.UIColors)

    Log_StashOpen(player, point.name, pointId)
end)

-- ─── PRODUCTOS DE TIENDA (respuesta directa al cliente) ──────
RegisterNetEvent('ox_stash_store:requestShopProducts', function(pointId)
    local src      = source
    local products = {}
    local point    = nil

    for _, p in ipairs(Points) do
        if p.id == pointId then point = p; break end
    end

    if point and point.category == 'shop' then
        products = point.products or {}

        -- Verificar job antes de enviar
        if point.job and point.job ~= '' then
            local xp = ESX.GetPlayerFromId(src)
            if not xp or xp.job.name ~= point.job then
                TriggerClientEvent('ox_stash_store:notify', src, 'No tienes acceso a esta tienda.', 'error')
                return
            end
        end

        -- Agregar imágenes de items desde ox_inventory
        for i, prod in ipairs(products) do
            local item = exports.ox_inventory:Items(prod.item_name)
            if item and item.image and item.image ~= '' then
                prod.image = GetImagePath(prod.item_name, item.image)
            else
                prod.image = GetImagePath(prod.item_name, nil)
            end
        end
    end

    TriggerClientEvent('ox_stash_store:receiveShopProducts', src, point, products, Config.ImageConfig, Config.UIColors)
end)

-- ─── COMPRA EN TIENDA ────────────────────────────────────────
RegisterNetEvent('ox_stash_store:buyItem', function(pointId, itemName, amount)
    local src   = source
    local point = nil
    for _, p in ipairs(Points) do
        if p.id == pointId then point = p; break end
    end
    if not point or point.category ~= 'shop' then return end

    local player  = GetPlayerInfo(src)
    local xPlayer = player.xPlayer
    if not xPlayer then return end

    -- Verificar job
    if point.job and point.job ~= '' then
        if xPlayer.job.name ~= point.job then
            TriggerClientEvent('ox_stash_store:notify', src, 'No tienes acceso a esta tienda.', 'error')
            return
        end
    end

    -- Buscar producto
    local product = nil
    for _, prod in ipairs(point.products or {}) do
        if prod.item_name == itemName then product = prod; break end
    end
    if not product then return end

    amount = math.max(1, math.floor(tonumber(amount) or 1))
    local total = product.price * amount

    if xPlayer.getMoney() < total then
        TriggerClientEvent('ox_stash_store:notify', src, 'No tienes suficiente dinero.', 'error')
        return
    end

    xPlayer.removeMoney(total)
    exports.ox_inventory:AddItem(src, itemName, amount)

    TriggerClientEvent('ox_stash_store:notify', src,
        ('Compraste %dx %s por $%d'):format(amount, product.label, total), 'success')

    Log_ShopPurchase(player, point.name, pointId, itemName, amount, total)
end)

-- ─── MOVER ITEMS EN STASH ────────────────────────────────────
RegisterNetEvent('ox_stash_store:moveToStash', function(pointId, itemName, count, fromSlot)
    local src = source
    local player = GetPlayerInfo(src)

    -- Verificar permisos (job)
    local point = nil
    for _, p in ipairs(Points) do
        if p.id == pointId then point = p; break end
    end
    if not point or (point.job and point.job ~= '' and (not player.xPlayer or player.xPlayer.job.name ~= point.job)) then
        TriggerClientEvent('ox_stash_store:notify', src, 'No tienes acceso.', 'error')
        return
    end

    -- Mover item de player a stash
    local success = exports.ox_inventory:RemoveItem(src, itemName, count, nil, fromSlot)
    if success then
        exports.ox_inventory:AddItem(('ox_stash_%d'):format(pointId), itemName, count)
        Log_StashDeposit(player, point.name, pointId, itemName, count)
        -- Actualizar UI
        local stashInv = exports.ox_inventory:GetInventory(('ox_stash_%d'):format(pointId), false)
        local playerInv = exports.ox_inventory:GetInventory(src, false)
        TriggerClientEvent('ox_stash_store:updateStashUI', src, stashInv, playerInv, Config.ImageConfig, Config.UIColors)
    end
end)

RegisterNetEvent('ox_stash_store:moveToPlayer', function(pointId, itemName, count, fromSlot)
    local src = source
    local player = GetPlayerInfo(src)

    -- Verificar permisos
    local point = nil
    for _, p in ipairs(Points) do
        if p.id == pointId then point = p; break end
    end
    if not point or (point.job and point.job ~= '' and (not player.xPlayer or player.xPlayer.job.name ~= point.job)) then
        TriggerClientEvent('ox_stash_store:notify', src, 'No tienes acceso.', 'error')
        return
    end

    -- Mover item de stash a player
    local stashId = ('ox_stash_%d'):format(pointId)
    local success = exports.ox_inventory:RemoveItem(stashId, itemName, count, nil, fromSlot)
    if success then
        exports.ox_inventory:AddItem(src, itemName, count)
        Log_StashWithdraw(player, point.name, pointId, itemName, count)
        -- Actualizar UI
        local stashInv = exports.ox_inventory:GetInventory(stashId, false)
        local playerInv = exports.ox_inventory:GetInventory(src, false)
        TriggerClientEvent('ox_stash_store:updateStashUI', src, stashInv, playerInv, Config.ImageConfig, Config.UIColors)
    end
end)

-- ─── TRACKING: Items movidos en stashes ─────────────────────
AddEventHandler('ox_inventory:itemMoved', function(src, fromInv, toInv, item, count)
    if not src or src == 0 then return end

    local stashId, action = nil, nil

    if fromInv and fromInv:sub(1,9) == 'ox_stash_' then
        stashId = tonumber(fromInv:sub(10)); action = 'withdraw'
    elseif toInv and toInv:sub(1,9) == 'ox_stash_' then
        stashId = tonumber(toInv:sub(10)); action = 'deposit'
    end

    if not stashId then return end

    local point = nil
    for _, p in ipairs(Points) do
        if p.id == stashId then point = p; break end
    end
    if not point then return end

    local player = GetPlayerInfo(src)
    if action == 'deposit' then
        Log_StashDeposit(player, point.name, stashId, item.name, count)
    else
        Log_StashWithdraw(player, point.name, stashId, item.name, count)
    end
end)

-- ─── SOLICITAR PUNTOS PARA BLIPS (CUANDO CAMBIA JOB) ────────
RegisterNetEvent('ox_stash_store:requestPointsForBlips', function()
    local src = source
    -- Enviar puntos frescos al cliente para actualizar blips según el job
    TriggerClientEvent('ox_stash_store:syncPoints', src, Points)
end)
