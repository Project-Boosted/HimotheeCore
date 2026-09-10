fx_version 'cerulean'
game 'gta5'

name 'himo_qb_bridge'
author 'HimotheeGaming'
description 'Limited QB compatibility bridge backed by HimotheeCore native services'
version '0.4.0'

lua54 'yes'

provide 'qb-core'

shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'ox_lib',
    'himo_core'
}
