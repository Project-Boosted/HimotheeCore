fx_version 'cerulean'
game 'gta5'

name 'qb-inventory'
author 'HimotheeGaming'
description 'qb-inventory compatibility facade backed by ox_inventory'
version '0.5.1'

lua54 'yes'
shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'ox_lib',
    'ox_inventory'
}
