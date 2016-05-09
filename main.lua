-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

-- Your code here

local tiled = require "com.ponywolf.ponytiled"
local mapData = require "demo"
local physics = require "physics"

display.setDefault("background", 0.2 )

physics.start()
--physics.setDrawMode( "hybrid" ) 

local map = tiled.new(mapData)
map.x,map.y = display.contentCenterX - map.designedWidth/2, display.contentCenterY - map.designedHeight/2

--map:extend("dragable")