fx_version 'cerulean'
games { 'gta5' }

author 'CivDev'
description 'oil_rig: multi-framework oil rig jobs using ox_lib'
version '1.0.0'

shared_script '@ox_lib/init.lua'

client_scripts {
    'config.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- auto-switch handled in config (oxmysql or ghmattimysql)
    'config.lua',
    'server/main.lua',
    'server/exports.lua',
}

lua54 'yes'

dependency 'ox_lib'
