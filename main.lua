-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

--local serpent = require "com.pkulchenko.serpent"
--function dump(...) 
--  print(serpent.block(...))
--end

local tiled = require "com.ponywolf.ponytiled"
local physics = require "physics"
local json = require "json"

display.setDefault("background", 0.2 )

physics.start()
--physics.setDrawMode( "hybrid" ) 


--local mapData = require "demo" -- load from lua export
local mapData = json.decodeFile("demo.json") -- load from json export
local map = tiled.new(mapData)
map.x,map.y = display.contentCenterX - map.designedWidth/2, display.contentCenterY - map.designedHeight/2

map:extend("dragable")
map:extend("particle")
