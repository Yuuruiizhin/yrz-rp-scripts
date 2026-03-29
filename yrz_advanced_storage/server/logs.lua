-- ============================================================
--  ox_stash_store | SERVER - LOGS (Discord Webhooks)
-- ============================================================

---@param webhookUrl string
---@param embed table
local function SendWebhook(webhookUrl, embed)
    if not webhookUrl or webhookUrl == '' then return end

    PerformHttpRequest(webhookUrl, function(err, text, headers) end, 'POST',
        json.encode({
            username   = Config.WebhookBotName,
            avatar_url = Config.WebhookAvatarURL,
            embeds     = { embed },
        }),
        { ['Content-Type'] = 'application/json' }
    )
end

---@param color number
---@param title string
---@param fields table   [{name, value, inline?}]
---@param footer string?
local function BuildEmbed(color, title, fields, footer)
    return {
        color  = color,
        title  = title,
        fields = fields,
        footer = { text = footer or os.date('%d/%m/%Y %H:%M:%S') },
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
    }
end

-- ─── FUNCIONES PÚBLICAS ─────────────────────────────────────

--- Log: Stash abierto
function Log_StashOpen(player, pointName, pointId)
    local embed = BuildEmbed(Config.Colors.stash_open, '📦 Stash Abierto', {
        { name = '🏪 Punto',    value = ('**%s** (ID: %d)'):format(pointName, pointId), inline = true },
        { name = '👤 Jugador',  value = player.name,     inline = true },
        { name = '🪪 License',  value = ('`%s`'):format(player.license), inline = false },
        { name = '💬 Discord',  value = player.discord ~= '' and ('<@%s>'):format(player.discord) or 'N/A', inline = true },
        { name = '🎮 Server ID',value = ('`%d`'):format(player.source), inline = true },
    })
    SendWebhook(Config.Webhooks.stash_open, embed)
end

--- Log: Item depositado en stash
function Log_StashDeposit(player, pointName, pointId, itemName, amount)
    local embed = BuildEmbed(Config.Colors.stash_deposit, '⬆️ Item Depositado en Stash', {
        { name = '🏪 Punto',    value = ('**%s** (ID: %d)'):format(pointName, pointId), inline = true },
        { name = '📦 Item',     value = ('`%s` x%d'):format(itemName, amount), inline = true },
        { name = '👤 Jugador',  value = player.name,    inline = true },
        { name = '🪪 License',  value = ('`%s`'):format(player.license), inline = false },
        { name = '💬 Discord',  value = player.discord ~= '' and ('<@%s>'):format(player.discord) or 'N/A', inline = true },
    })
    SendWebhook(Config.Webhooks.stash_deposit, embed)
end

--- Log: Item retirado de stash
function Log_StashWithdraw(player, pointName, pointId, itemName, amount)
    local embed = BuildEmbed(Config.Colors.stash_withdraw, '⬇️ Item Retirado del Stash', {
        { name = '🏪 Punto',    value = ('**%s** (ID: %d)'):format(pointName, pointId), inline = true },
        { name = '📦 Item',     value = ('`%s` x%d'):format(itemName, amount), inline = true },
        { name = '👤 Jugador',  value = player.name,    inline = true },
        { name = '🪪 License',  value = ('`%s`'):format(player.license), inline = false },
        { name = '💬 Discord',  value = player.discord ~= '' and ('<@%s>'):format(player.discord) or 'N/A', inline = true },
    })
    SendWebhook(Config.Webhooks.stash_withdraw, embed)
end

--- Log: Compra en tienda
function Log_ShopPurchase(player, pointName, pointId, itemName, amount, totalPrice)
    local embed = BuildEmbed(Config.Colors.shop_purchase, '🛒 Compra en Tienda', {
        { name = '🏪 Tienda',   value = ('**%s** (ID: %d)'):format(pointName, pointId), inline = true },
        { name = '📦 Item',     value = ('`%s` x%d'):format(itemName, amount), inline = true },
        { name = '💰 Total',    value = ('$%d'):format(totalPrice), inline = true },
        { name = '👤 Jugador',  value = player.name,    inline = true },
        { name = '🪪 License',  value = ('`%s`'):format(player.license), inline = false },
        { name = '💬 Discord',  value = player.discord ~= '' and ('<@%s>'):format(player.discord) or 'N/A', inline = true },
    })
    SendWebhook(Config.Webhooks.shop_purchase, embed)
end

--- Log: Acción administrativa
function Log_AdminAction(admin, action, pointData)
    local actionEmoji = { create = '✅', edit = '✏️', delete = '🗑️' }
    local actionColor = {
        create = Config.Colors.admin_create,
        edit   = Config.Colors.admin_edit,
        delete = Config.Colors.admin_delete,
    }
    local actionLabel = { create = 'Punto Creado', edit = 'Punto Modificado', delete = 'Punto Eliminado' }

    local embed = BuildEmbed(
        actionColor[action] or 0,
        ('%s %s'):format(actionEmoji[action] or '⚙️', actionLabel[action] or action),
        {
            { name = '🏪 Punto',     value = ('**%s** (ID: %s)'):format(pointData.name or 'N/A', tostring(pointData.id or 'Nuevo')), inline = true },
            { name = '📂 Categoría', value = pointData.category or 'N/A', inline = true },
            { name = '💼 Job',       value = (pointData.job and pointData.job ~= '') and pointData.job or 'Público', inline = true },
            { name = '👤 Admin',     value = admin.name,   inline = true },
            { name = '🪪 License',   value = ('`%s`'):format(admin.license), inline = false },
            { name = '💬 Discord',   value = admin.discord ~= '' and ('<@%s>'):format(admin.discord) or 'N/A', inline = true },
        }
    )
    SendWebhook(Config.Webhooks.admin_action, embed)
end
