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

-- Demo 1 
--local mapData = require "demo" -- load from lua export
--map:extend("dragable")
--map:extend("particle")

-- Demo 2
display.setDefault("magTextureFilter", "nearest")
display.setDefault("minTextureFilter", "nearest")
local mapData = json.decodeFile("demo2.json") -- load from json export

-- Base loading
local map = tiled.new(mapData)
map.x,map.y = display.contentCenterX - map.designedWidth/2, display.contentCenterY - map.designedHeight/2

