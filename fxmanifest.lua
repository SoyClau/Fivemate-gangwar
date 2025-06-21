fx_version 'cerulean'
game 'gta5'

author 'FiveMate'
description 'Sistema de GangWar para ESX con zonas controladas'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'locale.lua'
}

client_scripts {
    'client/main.lua',
    'client/zones.lua',
    'client/menu.lua',
    'client/blips.lua',
    'client/dispatch_ui.lua'
}

server_scripts {
    'server/main.lua',
    'server/events.lua',
    'server/dispatch.lua'
}

dependencies {
    'es_extended',
    'ox_lib'
}

lua54 'yes'