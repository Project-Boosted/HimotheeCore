fx_version 'cerulean'
game 'gta5'

name 'himo_characters'
author 'HimotheeGaming'
description 'HimotheeCore tutorial-session multicharacter lifecycle'
version '0.5.4'

lua54 'yes'

shared_script '@ox_lib/init.lua'
client_script 'client/main.lua'
server_script 'server/main.lua'

dependencies {
    'ox_lib',
    'himo_core',
    'himo_spawn',
    'himo_appearance',
    'spawnmanager'
}
