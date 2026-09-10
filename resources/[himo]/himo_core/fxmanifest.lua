fx_version 'cerulean'
game 'gta5'

name 'himo_core'
author 'HimotheeGaming'
description 'HimotheeCore framework foundation'
version '0.3.1'

lua54 'yes'

shared_scripts {
    'shared/config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logger.lua',
    'server/database.lua',
    'server/identifiers.lua',
    'server/characters.lua',
    'server/money.lua',
    'server/player.lua',
    'server/lifecycle.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/lifecycle.lua'
}

dependency 'oxmysql'
