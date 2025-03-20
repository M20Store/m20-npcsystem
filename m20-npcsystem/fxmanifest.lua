fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'NPC Spawn System'
description 'A system to spawn and manage NPCs with animations'
author 'M20 Store'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'qb-core'
}