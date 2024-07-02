fx_version 'cerulean'
games { 'gta5' }

name 'pg-rpc'
author 'Meepso'
description 'pretty good callbacks'
version '1.0.0'

lua54 'yes' -- idk what this dose

shared_script {
    'main.lua'
} -- This is the path to the shared script

provide 'pg-rpc' -- This is the name of the resource

-- for debugging
if false then
   
    server_script {
        'test/server.lua'
    } -- This is the path to the server script
    
    client_script {
        'test/client.lua'
    } -- This is the path to the client script

end