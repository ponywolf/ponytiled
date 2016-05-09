-- Project: PonyTiled a Corona Tiled Map Loader
--
-- Loads LUA saved map files from Tiled http://www.mapeditor.org/

local M = {}
local physics = require "physics"

local function inherit(image, properties)
  for k,v in pairs(properties) do
    image[k] = v
  end
  return image
end

function M.new(data)
  local map = display.newGroup()  

  local layers = data.layers
  local tilesets = data.tilesets
  local width, height = data.width * data.tilewidth, data.height * data.tileheight

  local function gidLookup(gid)
    -- turn a gid into a filename
    for i = 1, #tilesets do
      local tileset = tilesets[i]
      local firstgid = tileset.firstgid
      local lastgid = firstgid + tileset.tilecount 
      if gid >= firstgid and gid <= lastgid then
        for j = 1, #tileset.tiles do
          local tile = tileset.tiles[j]
          if tile.id == (gid - firstgid) then
            return tile.image -- may need updating with documents directory
          end
        end
      end
    end  
    return false
  end

  for i = 1, #layers do
    local layer = layers[i]
    if layer.type == "objectgroup" then
      local objectGroup = display.newGroup()
      for j = 1, #layer.objects do
        local object = layer.objects[j]
        if object.gid then 
          local gid = gidLookup(object.gid)
          local image = display.newImageRect(gid, object.width, object.height)
          -- name and type
          image.name = object.name
          image.type = object.type        
          -- apply base properties
          image.anchorX, image.anchorY = 0, 1
          image.x, image.y = object.x, object.y
          image.rotation = object.rotation
          image.isVisible = object.visible
          -- simple phyics
          if object.properties.bodyType then
            physics.addBody(image, object.properties.bodyType, object.properties)
          end          
          -- apply custom properties
          image = inherit(image, object.properties)
          image = inherit(image, layer.properties)
          objectGroup:insert(image)
        end
      end
      objectGroup.name = layer.name
      objectGroup.isVisible = layer.visible
      objectGroup.alpha = layer.opacity
      map:insert(objectGroup)
    end
  end

  function map:extend(...)
    local plugins = arg or {}
    -- each custom object above has its own game.scene module
    for t = 1, #plugins do 
      -- load each module based on type
      local plugin = require ("com.ponywolf.plugins." .. plugins[t])
      -- find each type of tiled object
      local images = map:listTypes(plugins[t])
      if images then 
        -- do we have at least one?
        for i = 1, #images do
          -- extend the display object with its own custom code
          images[i] = plugin.new(images[i])
        end
      end  
    end
  end

  -- return first display object with name
  function map:findObject(name)
    for layers = self.numChildren,1,-1 do
      local layer = self[layers]
      if layer.numChildren then
        for i = layer.numChildren,1,-1 do
          if layer[i].name == name then
            return layer[i]
          end
        end
      end
    end
    return false
  end

  -- return all display objects with type
  function map:listTypes(...)
    local objects = {}
    for layers = self.numChildren,1,-1 do
      local layer = self[layers]
      if layer.numChildren then
        for i = layer.numChildren,1,-1 do
          for j = 1, #arg do 
            if arg[j]==nil or layer[i].type == arg[j] then
              objects[#objects+1] = layer[i]
            end
          end
        end
      end
    end
    return objects
  end
  
  -- add helpful values to the map itself
  map.designedWidth, map.designedHeight = width, height
  return map
end

return M