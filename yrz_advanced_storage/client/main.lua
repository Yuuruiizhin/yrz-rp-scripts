-- ============================================================
--  ox_stash_store | CLIENT - MAIN  (v2 - ox_target)
-- ============================================================

local Points       = {}
local TargetZones  = {}
local IsUIOpen     = false

-- ─── NUI FOCUS ──────────────────────────────────────────────
local function OpenNUI()
    IsUIOpen = true
    SetNuiFocus(true, true)
end

local function CloseNUI()
    IsUIOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

-- ─── LIMPIAR ZONAS ANTERIORES ───────────────────────────────
local function ClearTargetZones()
    for _, zoneId in ipairs(TargetZones) do
        exports.ox_target:removeZone(zoneId)
    end
    TargetZones = {}
end

-- ─── CREAR ZONAS OX_TARGET ──────────────────────────────────
local function CreateTargetZones()
    ClearTargetZones()
    
    for _, p in ipairs(Points) do
        local options = {}
        
        if p.category == 'stash' then
            table.insert(options, {
                name = 'stash_open_' .. p.id,
                icon = 'fas fa-box',
                label = 'Abrir Almacén',
                distance = 2.5,
                onSelect = function()
                    TriggerServerEvent('ox_stash_store:openStash', p.id)
                end
            })
        elseif p.category == 'shop' then
            table.insert(options, {
                name = 'shop_open_' .. p.id,
                icon = 'fas fa-shopping-cart',
                label = 'Abrir Tienda',
                distance = 2.5,
                onSelect = function()
                    TriggerEvent('ox_stash_store:openShopUI', p)
                end
            })
        end
        
        local zoneId = exports.ox_target:addSphereZone({
            coords = vector3(p.coords_x, p.coords_y, p.coords_z),
            radius = 2.5,
            options = options,
            debug = Config.Debug or false
        })
        
        table.insert(TargetZones, zoneId)
    end
end

-- ─── SYNC PUNTOS DESDE SERVIDOR ─────────────────────────────
RegisterNetEvent('ox_stash_store:syncPoints', function(serverPoints)
    Points = serverPoints or {}
    CreateTargetZones()
    TriggerEvent('ox_stash_store:refreshBlips', Points)
end)

-- ─── ABRIR TIENDA ───────────────────────────────────────────
AddEventHandler('ox_stash_store:openShopUI', function(point)
    if IsUIOpen then return end
    TriggerServerEvent('ox_stash_store:requestShopProducts', point.id)
end)

RegisterNetEvent('ox_stash_store:receiveShopProducts', function(point, products, imageConfig, uiColors)
    SendNUIMessage({
        action   = 'openShop',
        point    = point,
        products = products,
        imageConfig = imageConfig,
        uiColors = uiColors,
    })
    OpenNUI()
end)

-- ─── ABRIR STASH UI ──────────────────────────────────────────
RegisterNetEvent('ox_stash_store:openStashUI', function(point, stashInv, playerInv, imageConfig, uiColors)
    SendNUIMessage({
        action = 'openStash',
        point  = point,
        stash  = stashInv,
        player = playerInv,
        imageConfig = imageConfig,
        uiColors = uiColors,
    })
    OpenNUI()
end)

RegisterNetEvent('ox_stash_store:updateStashUI', function(stashInv, playerInv, imageConfig, uiColors)
    SendNUIMessage({
        action = 'updateStash',
        stash  = stashInv,
        player = playerInv,
        imageConfig = imageConfig,
        uiColors = uiColors,
    })
end)

-- ─── ABRIR PANEL ADMIN ───────────────────────────────────────
RegisterNetEvent('ox_stash_store:openAdminPanel', function(points, uiColors)
    if IsUIOpen then return end
    local pos = GetEntityCoords(PlayerPedId())
    SendNUIMessage({
        action       = 'openAdmin',
        points       = points,
        playerCoords = { x = pos.x, y = pos.y, z = pos.z },
        uiColors = uiColors,
    })
    OpenNUI()
end)

-- ─── NUI CALLBACKS ──────────────────────────────────────────

RegisterNUICallback('closeUI', function(_, cb)
    CloseNUI()
    cb('ok')
end)

RegisterNUICallback('buyItem', function(data, cb)
    cb('ok')
    TriggerServerEvent('ox_stash_store:buyItem', data.pointId, data.itemName, data.amount)
end)

RegisterNUICallback('admin:createPoint', function(data, cb)
    if data.useCurrentCoords then
        local pos   = GetEntityCoords(PlayerPedId())
        data.coords = { x = pos.x, y = pos.y, z = pos.z }
    end
    cb('ok')
    TriggerServerEvent('ox_stash_store:admin:createPoint', data)
end)

RegisterNUICallback('admin:editPoint', function(data, cb)
    cb('ok')
    TriggerServerEvent('ox_stash_store:admin:editPoint', data.id, data)
end)

RegisterNUICallback('admin:deletePoint', function(data, cb)
    cb('ok')
    TriggerServerEvent('ox_stash_store:admin:deletePoint', data.id)
end)

-- Refresh sincrono: devuelve los puntos que ya tiene el cliente en cache
RegisterNUICallback('moveToStash', function(data, cb)
    cb('ok')
    if data.pointId and data.itemName and data.count then
        TriggerServerEvent('ox_stash_store:moveToStash', data.pointId, data.itemName, data.count, data.fromSlot)
    end
end)

RegisterNUICallback('moveToPlayer', function(data, cb)
    cb('ok')
    if data.pointId and data.itemName and data.count then
        TriggerServerEvent('ox_stash_store:moveToPlayer', data.pointId, data.itemName, data.count, data.fromSlot)
    end
end)

RegisterNUICallback('admin:refreshPoints', function(_, cb)
    local pos = GetEntityCoords(PlayerPedId())
    cb({ points = Points, playerCoords = { x = pos.x, y = pos.y, z = pos.z } })
end)

-- ─── RECIBIR ACTUALIZACIÓN DE PUNTOS (tras CRUD admin) ───────
RegisterNetEvent('ox_stash_store:adminPointsUpdated', function(newPoints)
    Points = newPoints or {}
    TriggerEvent('ox_stash_store:refreshBlips', Points)
    if IsUIOpen then
        local pos = GetEntityCoords(PlayerPedId())
        SendNUIMessage({
            action       = 'refreshAdminPoints',
            points       = Points,
            playerCoords = { x = pos.x, y = pos.y, z = pos.z },
        })
    end
end)

-- ─── NOTIFICACIONES ─────────────────────────────────────────
RegisterNetEvent('ox_stash_store:notify', function(msg, ntype)
    lib.notify({ title = 'Stash & Store', description = msg, type = ntype or 'inform' })
end)

-- ─── DRAW 3D TEXT ────────────────────────────────────────────
function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end

    local dist  = #(vector3(x, y, z) - GetGameplayCamCoords())
    local scale = (1 / dist) * 2.0
    local fov   = (1 / GetGameplayCamFov()) * 100

    SetTextScale(0.0, scale * fov)
    SetTextFont(0)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextOutline()
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(sx, sy)
    DrawRect(sx, sy + 0.025, 0.015 + #text * 0.001, 0.03, 0, 0, 0, 100)
end
