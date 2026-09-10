fx_version 'cerulean'
game 'gta5'

name 'himo_core'
author 'HimotheeGaming'
description 'HimotheeCore modular roleplay framework core services'
version '0.4.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logger.lua',
    'server/database.lua',
    'server/state.lua',
    'server/callbacks.lua',
    'server/permissions.lua',
    'server/commands.lua',
    'server/sessions.lua',
    'server/identifiers.lua',
    'server/money.lua',
    'server/jobs.lua',
    'server/metadata.lua',
    'server/characters.lua',
    'server/player.lua',
    'server/lifecycle.lua',
    'server/admin.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/callbacks.lua',
    'client/lifecycle.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
