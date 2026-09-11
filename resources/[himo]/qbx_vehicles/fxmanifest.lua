fx_version 'cerulean'
game 'gta5'

name 'qbx_vehicles'
author 'HimotheeGaming'
description 'Qbox vehicle API compatibility facade backed by HimotheeCore vehicles'
version '1.2.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'himo_core',
    'qbx_core'
}
