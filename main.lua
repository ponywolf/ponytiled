-- This is a little demo project using the assets from
-- Sticker Knight https://github.com/coronalabs/Sticker-Knight-Platformer
-- and Generic Platform Tiles by surt http://opengameart.org/content/generic-platformer-tiles 

-- The goal is to show basic map loading for object & tile based
-- maps via JSON or lua

local tiled = require "com.ponywolf.ponytiled"
local physics = require "physics"
local json = require "json"

-- if you use physics bodies in your map, you must
-- start() physics before you load your map
physics.start()

-- Demo 1 

-- Load a "pixel perfect" map from a JSON export
--display.setDefault("magTextureFilter", "nearest")
--display.setDefault("minTextureFilter", "nearest")
--local mapData = json.decodeFile(system.pathForFile("maps/tiles/tilemap.json", system.ResourceDirectory))  -- load from json export
--local map = tiled.new(mapData, "maps/tiles")

-- Demo 2 

-- Load an object based map from a lua file
local mapData = require "maps.objects.sandbox" -- load from lua export
local map = tiled.new(mapData, "maps/objects") -- look for images is /maps/objects/

-- center the map on screen
map.x,map.y = display.contentCenterX - map.designedWidth/2, display.contentCenterY - map.designedHeight/2

-- drag the whole map for fun
local dragable = require "com.ponywolf.plugins.dragable"
map = dragable.new(map)

