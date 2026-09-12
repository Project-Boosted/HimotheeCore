fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'himo_mining_progression'
author 'HimotheeGaming'
description 'Persistent skill progression companion for jim-mining'
version '0.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'ox_inventory',
    'qbx_core',
    'jim-mining'
}
