-- ============================================================
--  ox_stash_store | SQL INSTALL
--  Ejecutar en tu base de datos de FiveM
-- ============================================================

CREATE TABLE IF NOT EXISTS `ox_stash_store_points` (
    `id`              INT(11)       NOT NULL AUTO_INCREMENT,
    `name`            VARCHAR(100)  NOT NULL,
    `category`        ENUM('stash','shop') NOT NULL DEFAULT 'stash',
    `coords_x`        FLOAT         NOT NULL,
    `coords_y`        FLOAT         NOT NULL,
    `coords_z`        FLOAT         NOT NULL,
    `job`             VARCHAR(50)   DEFAULT NULL COMMENT 'NULL = accesible para todos',
    `max_weight`      INT(11)       DEFAULT 100000,
    `max_slots`       INT(11)       DEFAULT 50,
    `creator_license` VARCHAR(100)  DEFAULT NULL,
    `creator_discord` VARCHAR(100)  DEFAULT NULL,
    `creator_name`    VARCHAR(100)  DEFAULT NULL,
    `created_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      TIMESTAMP     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Puntos de Stash y Tienda';

CREATE TABLE IF NOT EXISTS `ox_stash_store_products` (
    `id`        INT(11)      NOT NULL AUTO_INCREMENT,
    `point_id`  INT(11)      NOT NULL,
    `item_name` VARCHAR(100) NOT NULL COMMENT 'Nombre del item en OX Inventory',
    `label`     VARCHAR(100) NOT NULL,
    `price`     INT(11)      NOT NULL DEFAULT 1,
    `metadata`  LONGTEXT     DEFAULT NULL COMMENT 'Metadata JSON opcional para el item',
    PRIMARY KEY (`id`),
    KEY `fk_point` (`point_id`),
    CONSTRAINT `fk_point` FOREIGN KEY (`point_id`)
        REFERENCES `ox_stash_store_points` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Productos de las tiendas';
