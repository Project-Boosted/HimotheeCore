fx_version 'cerulean'
game 'gta5'

name 'qb-core'
author 'HimotheeGaming'
description 'QBCore compatibility facade backed by HimotheeCore'
version '0.4.3'

lua54 'yes'

shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

files {
    'shared/locale.lua'
}

dependencies {
    'ox_lib',
    'himo_core',
    'himo_qb_bridge'
}
