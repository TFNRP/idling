fx_version 'cerulean'
game 'gta5'

repository 'https://github.com/TFNRP/idling'
description
[[
  Allows you to idle your resources
  when no players are in your server
]]
version '0.0.0'
author 'Reece Stokes <hagen@hyena.gay>'
licesne 'Apache License 2.0'

server_script {
  'dependencies/**.lua',
  'config.lua',
  'util.lua',
  'server.lua',
}