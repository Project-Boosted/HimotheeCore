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
    'server/groups_catalog.lua',
    'server/main.lua'
}

files {
    'modules/playerdata.lua',
    'shared/vehicles.lua'
}

dependencies {
    'ox_lib',
    'himo_core',
    'himo_qb_bridge',
    'qb-core'
}
