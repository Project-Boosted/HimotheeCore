fx_version 'cerulean'
game 'gta5'

name 'himo_qb_bridge'
author 'HimotheeGaming'
description 'Internal QB compatibility engine backed by HimotheeCore native services'
version '0.5.4'

lua54 'yes'

shared_script '@ox_lib/init.lua'

client_scripts {
    'client/main.lua',
    'client/helpers.lua',
    'client/catalog.lua'
}

server_scripts {
    'server/main.lua',
    'server/helpers.lua',
    'server/shared.lua',
    'server/catalog.lua'
}

dependencies {
    'ox_lib',
    'himo_core'
}
