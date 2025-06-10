fx_version 'cerulean'
game 'gta5'

author '5mg-storages'
description 'Storage Units System'
version '2.0.0'
lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/framework.lua'
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/script.js',
    'web/assets/**/*'
}

dependencies {
    'ox_lib',
    'ox_inventory',
    'oxmysql'
}


optional_dependencies {
    'es_extended',
    'qb-core',
    'qbx_core',
    'ox_core'
}
