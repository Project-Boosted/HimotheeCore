fx_version 'cerulean'
game 'gta5'

name 'qbx_core'
author 'HimotheeGaming'
description 'Qbox compatibility facade backed by HimotheeCore'
version '1.23.0'

lua54 'yes'

shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'
server_scripts {
    'server/vehicles.lua',
    'server/main.lua'
}

files {
    'modules/playerdata.lua'
}

dependencies {
    'ox_lib',
    'himo_core',
    'qb-core'
}
