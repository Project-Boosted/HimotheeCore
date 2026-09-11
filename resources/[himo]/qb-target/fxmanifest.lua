fx_version 'cerulean'
game 'gta5'

name 'qb-target'
author 'HimotheeGaming'
description 'qb-target compatibility facade backed by ox_target'
version '0.5.6'

lua54 'yes'
shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'

dependencies {
    'ox_lib',
    'ox_target'
}
