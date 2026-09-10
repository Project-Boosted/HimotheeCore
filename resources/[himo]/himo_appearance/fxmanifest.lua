fx_version 'cerulean'
game 'gta5'

name 'himo_appearance'
author 'HimotheeGaming'
description 'HimotheeCore appearance persistence and Illenium integration'
version '0.3.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'himo_core',
    'illenium-appearance'
}
