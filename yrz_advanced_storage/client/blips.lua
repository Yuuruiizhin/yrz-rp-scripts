-- ============================================================
--  ox_stash_store | CLIENT - BLIPS
--  Gestión de blips en el mapa
-- ============================================================

local ESX         = exports['es_extended']:getSharedObject()
local ActiveBlips = {}
local BlipsVisible = true -- Estado del toggle de blips
local CurrentPoints = {} -- Cache de puntos actuales
local BlipsVisible = true -- Estado del toggle de blips

local function ClearAllBlips()
    for _, blip in ipairs(ActiveBlips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
    ActiveBlips = {}
end

local function HasRequiredJob(point)
    if not point.job or point.job == '' then
        return true -- Sin restricción de job
    end
    
    local xPlayer = ESX.GetPlayerData()
    
    if not xPlayer or not xPlayer.job then
        if Config.Debug then
            print('[ox_stash_store] No player data or job found')
        end
        return false
    end
    
    local hasJob = xPlayer.job.name == point.job
    
    if Config.Debug then
        print(('[ox_stash_store] Player job: %s, Required job: %s, Has access: %s'):format(
            xPlayer.job.name, point.job, hasJob and 'YES' or 'NO'))
    end
    
    return hasJob
end

local function CreateBlip(point)
    if not Config.BlipsEnabled or not BlipsVisible then return end
    
    -- Verificar si el jugador tiene el job requerido
    if Config.BlipsOnlyWithJob and not HasRequiredJob(point) then
        return
    end

    local cfg    = Config.BlipConfig[point.category] or Config.BlipConfig.stash
    local coords = vector3(point.coords_x, point.coords_y, point.coords_z)
    local blip   = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, cfg.sprite)
    SetBlipColour(blip, cfg.color)
    SetBlipScale(blip, cfg.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(point.name)
    EndTextCommandSetBlipName(blip)

    table.insert(ActiveBlips, blip)
end

AddEventHandler('ox_stash_store:refreshBlips', function(points)
    CurrentPoints = points or {}
    ClearAllBlips()
    if not points then return end
    for _, p in ipairs(points) do
        CreateBlip(p)
    end
end)

-- ─── COMANDO PARA TOGGLE BLIPS ──────────────────────────────
RegisterCommand(Config.BlipsToggleCommand, function()
    BlipsVisible = not BlipsVisible
    
    if BlipsVisible then
        -- Solicitar puntos frescos del servidor cuando se activan
        TriggerServerEvent('ox_stash_store:requestPointsForBlips')
        ESX.ShowNotification('Blips activados')
    else
        ClearAllBlips()
        ESX.ShowNotification('Blips desactivados')
    end
end, false)

-- ─── COMANDO DEBUG PARA REFRESCAR BLIPS ─────────────────────
if Config.Debug then
    RegisterCommand('debugblips', function()
        print('[ox_stash_store] Forzando refresh de blips...')
        TriggerServerEvent('ox_stash_store:requestPointsForBlips')
        ESX.ShowNotification('Debug: Blips refrescados')
    end, false)
end

-- ─── ACTUALIZAR BLIPS CUANDO CAMBIA EL JOB ──────────────────
AddEventHandler('esx:setJob', function(job)
    if Config.BlipsOnlyWithJob then
        if Config.Debug then
            print(('[ox_stash_store] Job changed to: %s, requesting fresh points from server...'):format(job.name))
        end
        
        -- Solicitar puntos frescos del servidor en lugar de usar cache
        Citizen.SetTimeout(1000, function()
            TriggerServerEvent('ox_stash_store:requestPointsForBlips')
        end)
    end
end)

-- ─── TAMBIÉN ESCUCHAR OTROS EVENTOS DE JOB ───────────────────
AddEventHandler('esx:playerLoaded', function(xPlayer)
    if Config.BlipsOnlyWithJob then
        Citizen.SetTimeout(1500, function()
            TriggerEvent('ox_stash_store:refreshBlips', CurrentPoints)
        end)
    end
end)

-- ─── THREAD DE MONITOREO DE JOB (BACKUP) ────────────────────
Citizen.CreateThread(function()
    local lastJob = nil
    
    while true do
        Citizen.Wait(10000) -- Verificar cada 10 segundos (menos frecuente)
        
        if Config.BlipsOnlyWithJob then
            local xPlayer = ESX.GetPlayerData()
            if xPlayer and xPlayer.job then
                if lastJob ~= xPlayer.job.name then
                    if Config.Debug then
                        print(('[ox_stash_store] Job monitoring detected change: %s -> %s'):format(
                            lastJob or 'none', xPlayer.job.name))
                    end
                    
                    lastJob = xPlayer.job.name
                    -- Solicitar puntos frescos del servidor
                    TriggerServerEvent('ox_stash_store:requestPointsForBlips')
                end
            end
        end
    end
end)
