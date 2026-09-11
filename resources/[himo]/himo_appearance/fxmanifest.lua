fx_version 'cerulean'
game 'gta5'

name 'himo_appearance'
author 'HimotheeGaming'
description 'HimotheeCore appearance persistence with Illenium bridge'
version '0.5.3'

lua54 'yes'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client/main.lua',
    'client/auto_creator.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'himo_core',
    'himo_qb_bridge',
    'qb-core',
    'illenium-appearance'
}
