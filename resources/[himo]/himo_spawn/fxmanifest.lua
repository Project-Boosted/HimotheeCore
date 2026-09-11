fx_version 'cerulean'
game 'gta5'

name 'himo_spawn'
author 'HimotheeGaming'
description 'HimotheeCore spawn selection and handoff'
version '0.5.7'

lua54 'yes'

shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'

dependencies {
    'ox_lib',
    'himo_core'
}
