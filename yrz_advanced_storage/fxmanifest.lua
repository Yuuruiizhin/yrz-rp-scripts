fx_version 'cerulean'
game 'gta5'

author 'OX Stash & Store | ESX Framework'
description 'Sistema de Almacenamiento y Tienda compatible con OX-Inventory'
version '1.0.0'

dependencies {
    'ox_inventory',
    'es_extended',
    'ox_lib',
    'ox_target'
}

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/ui.lua',
    'client/blips.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/admin.lua',
    'server/logs.lua',
    'server/database.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/js/admin.js',
}

lua54 'yes'
