fx_version 'cerulean'
game 'gta5'

name 'himo_characters'
author 'HimotheeGaming'
description 'HimotheeCore multicharacter selection, creation and spawn lifecycle'
version '0.2.1'

lua54 'yes'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependencies {
    'himo_core',
    'spawnmanager'
}
