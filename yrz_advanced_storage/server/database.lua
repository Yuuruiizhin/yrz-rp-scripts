-- ============================================================
--  ox_stash_store | SERVER - DATABASE
--  Gestión de la base de datos
-- ============================================================

-- ─── CREAR TABLAS SI NO EXISTEN ─────────────────────────────
CreateThread(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ox_stash_store_points` (
            `id`            INT(11) NOT NULL AUTO_INCREMENT,
            `name`          VARCHAR(100) NOT NULL,
            `category`      ENUM('stash','shop') NOT NULL DEFAULT 'stash',
            `coords_x`      FLOAT NOT NULL,
            `coords_y`      FLOAT NOT NULL,
            `coords_z`      FLOAT NOT NULL,
            `job`           VARCHAR(50) DEFAULT NULL,
            `max_weight`    INT(11) DEFAULT 100000,
            `max_slots`     INT(11) DEFAULT 50,
            `creator_license` VARCHAR(100) DEFAULT NULL,
            `creator_discord` VARCHAR(100) DEFAULT NULL,
            `creator_name`  VARCHAR(100) DEFAULT NULL,
            `created_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `updated_at`    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `ox_stash_store_products` (
            `id`        INT(11) NOT NULL AUTO_INCREMENT,
            `point_id`  INT(11) NOT NULL,
            `item_name` VARCHAR(100) NOT NULL,
            `label`     VARCHAR(100) NOT NULL,
            `price`     INT(11) NOT NULL DEFAULT 1,
            `metadata`  LONGTEXT DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `fk_point` (`point_id`),
            CONSTRAINT `fk_point` FOREIGN KEY (`point_id`)
                REFERENCES `ox_stash_store_points` (`id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])

    if Config.Debug then print('^2[ox_stash_store]^7 Tablas verificadas/creadas correctamente.') end
end)

-- ─── FUNCIONES DB ───────────────────────────────────────────

--- Obtiene todos los puntos con sus productos
---@return table
function DB_GetAllPoints()
    local points = MySQL.query.await('SELECT * FROM `ox_stash_store_points` ORDER BY `id` ASC')
    if not points then return {} end

    for i = 1, #points do
        local p = points[i]
        if p.category == 'shop' then
            p.products = MySQL.query.await(
                'SELECT * FROM `ox_stash_store_products` WHERE `point_id` = ?',
                { p.id }
            ) or {}
        end
        p.coords = vector3(p.coords_x, p.coords_y, p.coords_z)
    end

    return points
end

--- Inserta un nuevo punto
---@param data table
---@return number insertId
function DB_CreatePoint(data)
    local id = MySQL.insert.await(
        [[INSERT INTO `ox_stash_store_points`
            (`name`, `category`, `coords_x`, `coords_y`, `coords_z`,
             `job`, `max_weight`, `max_slots`,
             `creator_license`, `creator_discord`, `creator_name`)
          VALUES (?,?,?,?,?,?,?,?,?,?,?)
        ]],
        {
            data.name, data.category,
            data.coords.x, data.coords.y, data.coords.z,
            data.job ~= '' and data.job or nil,
            data.max_weight or Config.StashMaxWeight,
            data.max_slots  or Config.StashMaxSlots,
            data.creator_license, data.creator_discord, data.creator_name,
        }
    )
    return id
end

--- Actualiza un punto existente
---@param id number
---@param data table
function DB_UpdatePoint(id, data)
    MySQL.update.await(
        [[UPDATE `ox_stash_store_points` SET
            `name`=?, `category`=?, `coords_x`=?, `coords_y`=?, `coords_z`=?,
            `job`=?, `max_weight`=?, `max_slots`=?
          WHERE `id`=?
        ]],
        {
            data.name, data.category,
            data.coords.x, data.coords.y, data.coords.z,
            data.job ~= '' and data.job or nil,
            data.max_weight or Config.StashMaxWeight,
            data.max_slots  or Config.StashMaxSlots,
            id,
        }
    )
end

--- Elimina un punto y sus productos en cascada
---@param id number
function DB_DeletePoint(id)
    MySQL.update.await('DELETE FROM `ox_stash_store_points` WHERE `id`=?', { id })
end

--- Reemplaza todos los productos de una tienda
---@param pointId number
---@param products table
function DB_SetProducts(pointId, products)
    MySQL.update.await('DELETE FROM `ox_stash_store_products` WHERE `point_id`=?', { pointId })
    if not products or #products == 0 then return end

    for _, prod in ipairs(products) do
        MySQL.insert.await(
            'INSERT INTO `ox_stash_store_products` (`point_id`,`item_name`,`label`,`price`) VALUES (?,?,?,?)',
            { pointId, prod.item_name, prod.label, prod.price }
        )
    end
end

--- Obtiene los productos de una tienda
---@param pointId number
---@return table
function DB_GetProducts(pointId)
    return MySQL.query.await(
        'SELECT * FROM `ox_stash_store_products` WHERE `point_id`=?',
        { pointId }
    ) or {}
end
