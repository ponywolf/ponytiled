-- Project: PonyTiled a Solar2D Tiled Map Loader (formerly Corona SDK)
--
-- Loads LUA saved map files from Tiled http://www.mapeditor.org/

local physics = require "physics"
local xml = require("com.coronalabs.xml").newParser()
--local path = require "com.luapower.path" --optional to resolve relative paths on android
--local translate = require "com.ponywolf.translator"
--local json = require "json"

local M = {}
local defaultExtensions = "com.ponywolf.plugins."

local FlippedHorizontallyFlag   = 0x80000000
local FlippedVerticallyFlag     = 0x40000000
local FlippedDiagonallyFlag     = 0x20000000

local function hasbit(x, p) return x % (p + p) >= p end
local function setbit(x, p) return hasbit(x, p) and x or x + p end
local function clearbit(x, p) return hasbit(x, p) and x - p or x end

local function tiledProperties(properties)
  if (#properties > 0) then
    --new tiled style
    local t = {}
    for i = 1, #properties do     
      if translate then
        if properties[i].type == "string" and (properties[i].name == "text") and (not tonumber(properties[i].value)) then
          if translate then
            properties[i].value = translate(properties[i].value)
          end
        end
      end
      
      if properties[i].value ~= "" then t[properties[i].name] = properties[i].value end
    end
    return t
  else
    return properties
  end
end

local function inherit(image, properties)
  for k,v in pairs(properties) do
    if v ~= "" then image[k] = v or image[k] end
  end
  return image
end

local function centerAnchor(image, anchorX, anchorY)
  anchorX, anchorY = anchorX or 0.5, anchorY or 0.5
  if image.contentBounds then
    local bounds = image.contentBounds
    local actualCenterX, actualCenterY =  (bounds.xMin * (1 - anchorX) + (bounds.xMax * anchorX)),
    (bounds.yMin * (1 - anchorY)) + (bounds.yMax * anchorY)
    image.x = actualCenterX
    image.y = actualCenterY
    image.anchorX, image.anchorY = anchorX, anchorY
  end
end

local function decodeTiledColor(hex)
  hex = hex or "#FF888888"
  hex = hex:gsub("#","")
  local function hexToFloat(part)
    return tonumber("0x".. part or "00") / 255
  end
  local a, r, g, b =  hexToFloat(hex:sub(1,2)), hexToFloat(hex:sub(3,4)), hexToFloat(hex:sub(5,6)), hexToFloat(hex:sub(7,8))
  return r, g, b, a
end

local function unpackPoints(points, dx, dy)
  local t = {}
  for i = 1,#points do
    t[#t+1] = points[i].x + (dx or 0)
    t[#t+1] = points[i].y + (dy or 0)
  end
  return t
end

local width = display.actualContentWidth
local height = display.actualContentHeight
local originX = display.screenOriginX
local originY = display.screenOriginY
local centerX = display.contentCenterX
local centerY = display.contentCenterY

local safeOriginX = display.safeScreenOriginX
local safeOriginY = display.safeScreenOriginY
local safeWidth = display.safeActualContentWidth
local safeHeight = display.safeActualContentHeight

local function snap(map, object, alignment, margin, safe)
  if not object or not object.x or not object.y then return nil end
  local anchorX, anchorY = object.anchorX, object.anchorY

  -- Let's do it!
  alignment = string.lower(alignment or "center")
  margin = margin or 0

  local w = object.contentWidth
  local h = object.contentHeight

  local x, y = object:localToContent(0,0)

  if string.find(alignment,"center") then
    x, y = centerX, centerY
  end
  if string.find(alignment,"top") or string.find(alignment,"upper") then
    y = (safe and safeOriginY or originY) + margin + (anchorY * h)
  end
  if string.find(alignment,"bottom") or string.find(alignment,"lower") then
    y = (safe and safeHeight or height) - margin - (anchorY * h) + (safe and safeOriginY or originY)
  end
  if string.find(alignment,"left") then
    x = (safe and safeOriginX or originX) + margin + (anchorX * w)
  end
  if string.find(alignment,"right") then
    x = (safe and safeWidth or width) - margin - (anchorX * w) + (safe and safeOriginX or originX)
  end

  object.x, object.y = map:contentToLocal(x,y)
  return object.x, object.y -- new x, y if you need it
end

function M.new(data, dir)
  local map = display.newGroup()
  dir = dir and (dir .. "/") or "" -- where does the map live?

  local layers = data.layers
  local tilesets = data.tilesets
  local width, height = data.width * data.tilewidth, data.height * data.tileheight
  local sheets = {}

  -- Check each tileset for its tiles definition table and copy
  -- every tile's properties to their own table for later lookup.
  local _tileData = {}

  for i = 1, #tilesets do
    if type( tilesets[i].tiles ) == "table" then
      local firstgid = tilesets[i].firstgid

      for _, t in pairs( tilesets[i].tiles ) do
        local n = t.id+firstgid
        _tileData[n] = {}

        if t.properties then
          for j = 1, #t.properties do
            local t = t.properties[j]
            _tileData[n][t.name] = t.value
          end
        end
      end
    end
  end

  -- List of tiles in the current map.
  local _levelTiles = {}

  -- Reserved tile property names for physics bodies.
  local physicsProperties = {
    density = true,
    friction = true,
    bounce = true,
    bodyType = true,
    radius = true,
    shape = true,
    box = true,
    chain = true,
    connectFirstAndLastChainVertex  = true,
    outline = true,
    isSensor = true,
  }

  -- Check if a tile has the given property and return the first tile with a matching value.
  function map.getFirstTile( property, value )
    for i = 1, #_levelTiles do
      local key = _levelTiles[i][property]
      -- If the value isn't specified, then just return the first tile with the given property.
      if key and (value == nil or value == key) then
        return _levelTiles[i]
      end
    end
  end

  function map.getAllTiles( property, value )
    local t = {}
    for i = 1, #_levelTiles do
      local key = _levelTiles[i][property]
      if key and (value == nil or value == key) then
        t[#t+1] = _levelTiles[i]
      end
    end
    return t
  end

  local function loadTileset(num)
    local tileset = tilesets[num]

    local tsiw, tsih = tileset.imagewidth, tileset.imageheight
    local margin, spacing = tileset.margin or 0, tileset.spacing or 0
    local w, h = tileset.tilewidth, tileset.tileheight

    local options = {
      frames = {},
      sheetContentWidth =  tsiw,
      sheetContentHeight = tsih,
    }

    local frames = options.frames
    local tsh = tileset.tilecount / tileset.columns
    local tsw = tileset.columns

    for j=1, tsh do
      for i=1, tsw do
        local element = {
          x = (i-1)*(w + spacing) + margin,
          y = (j-1)*(h + spacing) + margin,
          width = w,
          height = h,
        }
        frames[#frames + 1] = element
      end
    end
    --print("LOADED:", dir .. tileset.image)
    local filename = path and path.normalize(dir .. tileset.image) or dir .. tileset.image
    return graphics.newImageSheet(dir .. tileset.image, options)
  end

  local function findLast(tileset)
    local last = tileset.firstgid
    if tileset.image then
      return tileset.firstgid + tileset.tilecount - 1
    elseif tileset.tiles then
      for k,v in pairs(tileset.tiles) do
        local l = (v.id or tonumber(k)) + tileset.firstgid
        if l > last then
          last = l
        end
      end
      return last
    end
  end

  local function gidLookup(gid)
    -- flipping merged from code by Sergey Lerg
    local flip = {}
    flip.x = hasbit(gid, FlippedHorizontallyFlag)
    flip.y = hasbit(gid, FlippedVerticallyFlag)
    flip.xy = hasbit(gid, FlippedDiagonallyFlag)
    gid = clearbit(gid, FlippedHorizontallyFlag)
    gid = clearbit(gid, FlippedVerticallyFlag)
    gid = clearbit(gid, FlippedDiagonallyFlag)
    -- turn a gid into a filename or sheet/frame
    for i = 1, #tilesets do
      local tileset = tilesets[i]
      local firstgid = tileset.firstgid
      if tileset.source then
        print ("WARNING: External tilesets only suported for tilesheets...")
        local externalSet = xml:loadFile(dir .. tileset.source)
        tileset.image = externalSet.child[1].properties.source
        tileset.width = externalSet.child[1].properties.width
        tileset.height = externalSet.child[1].properties.height
        tileset.tileheight = externalSet.properties.tileheight
        tileset.tilewidth = externalSet.properties.tilewidth
        tileset.columns = externalSet.properties.columns
        tileset.name = externalSet.properties.name
        tileset.tilecount = externalSet.properties.tilecount
        tileset.source = nil -- no longer load the XML
      end
      local lastgid = findLast(tileset)

      if gid >= firstgid and gid <= lastgid then
        if tileset.image then -- spritesheet
          local sequenceData
          if not sheets[i] then
            sheets[i] = loadTileset(i)
          end
          if tileset.tiles then
            for t = 1, #tileset.tiles do
              local tile = tileset.tiles[t]
              tile.properties = tiledProperties(tile.properties or {})
              if tile.animation and tile.id == (gid - firstgid + (data.luaversion and 1 or 0)) then
                sequenceData = {
                  name="imported",
                  frames= {},
                  time = 0,
                  loopCount = tile.properties.loopCount or 0,
                  loopDirection = tile.properties.loopDirection,
                }
                for frame=1, #tile.animation do
                  table.insert(sequenceData.frames, tile.animation[frame].tileid + 1)
                  sequenceData.time = sequenceData.time + tile.animation[frame].duration -- Solar2D wants the total time, not the frame time
                end
              end
            end
          end
          return gid - firstgid + 1, flip, sheets[i], sequenceData
        else -- collection of images
          if not tileset.tiles[1] then
            for k,v in pairs(tileset.tiles) do
              if tonumber(k) == (gid - firstgid + (data.luaversion and 1 or 0)) then
                return v.image, flip -- may need updating with documents directory
              end
            end
          end
          -- newer tiled format is found here
          for t = 1, #tileset.tiles do
            local tile = tileset.tiles[t]
            if tonumber(tile.id) == gid - firstgid  + (data.luaversion and 1 or 0) then
              return tile.image, flip -- may need updating with documents directory
            end
          end
        end
      end
    end
    return false
  end

  for i = 1, #layers do
    local layer = layers[i]
    layer.properties = tiledProperties(layer.properties or {}) -- make sure we have a properties table
    local objectGroup = display.newGroup()
    if layer.type == "tilelayer" then
      if layer.compression or layer.encoding then
        print ("ERROR: Tile layer encoding/compression not supported. Choose CSV or XML in map options.")
      end
      local item = 0
      for ty=0, data.height-1 do
        for tx=0, data.width-1 do
          item = 1 + (ty * data.width) + tx
          local tileNumber = layer.data[item] or 0
          local gid, flip, sheet, animation = gidLookup(tileNumber)
          if gid then
            local image
            if animation then
              --print("Animating:", gid)
              image = display.newSprite(objectGroup, sheet, animation)
              image:play()
            else
              image = sheet and display.newImage(objectGroup, sheet, gid, 0, 0) or display.newImage(objectGroup, dir .. gid, 0, 0)
            end
            image.anchorX, image.anchorY = 0,1
            image.gid = tileNumber
            image.x, image.y = tx * data.tilewidth, (ty+1) * data.tileheight
            centerAnchor(image)

            -- Assign any properties set in Tiled to the actual tile object.
            local data = _tileData[tileNumber]
            if type( data ) == "table" then
              local physicsData = {}

              -- Separate physics properties from everything else.
              for k, v in pairs( data ) do
                if physicsProperties[k] then
                  physicsData[k] = v
                else
                  image[k] = v
                end
              end
              -- number of the tile in its image sheet.
              image.tileNum = gid

              if physicsData.bodyType then
                physics.addBody( image, physicsData.bodyType, physicsData )
              end
            end

            -- Add the tile to a table for later access.
            _levelTiles[#_levelTiles+1] = image

            -- apply custom properties
            image = inherit(image, layer.properties)
            -- flip it
            if flip.xy then
              print("WARNING: Unsupported Tiled mirror x, y in tile ", tx,ty)
            else
              if flip.x then image.xScale = -1 * image.xScale end
              if flip.y then image.yScale = -1 * image.yScale end
            end
          end
        end
      end
    elseif layer.type == "objectgroup" then
      for j = 1, #layer.objects do
        local object = layer.objects[j]
        object.properties = object.properties or {} -- make sure we have a properties table
        object.properties = tiledProperties(object.properties)
        if object.gid then
          local gid, flip, sheet, animation = gidLookup(object.gid)
          if gid then
            local image
            if animation then
              --print("Animating:", gid)
              image = display.newSprite(objectGroup, sheet, animation)
              image:play()
              image.xScale = object.width / image.width
              image.yScale = object.height / image.height
            else
              image = sheet and display.newImageRect(objectGroup, sheet, gid, object.width, object.height) or
              display.newImageRect(objectGroup, path and path.normalize(dir .. gid) or (dir .. gid), object.width, object.height)
            end
            -- missing
            if not image then -- placeholder
              image = display.newRect(objectGroup, 0,0, object.width, object.height)
              image:setFillColor(1,0,0,0.5)
            end
            -- name and type
            image.name = object.name
            image.type = object.type
            image.id = object.id
            image.filename = sheet and "none" or (dir .. gid)
            -- apply base properties
            local anchorX, anchorY = object.properties.anchorX, object.properties.anchorY
            object.properties.anchorX, object.properties.anchorY = nil, nil
            image.anchorX, image.anchorY = 0, 1
            image.x, image.y = object.x, object.y
            image.rotation = object.rotation
            image.isVisible = object.visible
            image.gid = object.gid
            centerAnchor(image, anchorX, anchorY)
            if image.fillColor then image:setFillColor(decodeTiledColor(image.fillColor)) end
            -- flip it
            if flip.xy then
              print("WARNING: Unsupported Tiled rotation x, y in ", object.name)
            else
              if flip.x then image.xScale = -1 * image.xScale end
              if flip.y then image.yScale = -1 * image.yScale end
            end
            -- autotrace shape
            local autoShape = object.properties.autoShape
            if autoShape then
              if not sheet then
                object.properties.outline = graphics.newOutline(autoShape, path and path.normalize(dir .. gid) or (dir .. gid))
              else
                object.properties.outline = graphics.newOutline(autoShape, sheet, gid)
              end
            end
            -- not so simple physics
            if object.properties.bodyType or layer.properties.bodyType then
              if object.properties.isBox then
                object.properties.box = {
                  halfWidth = (object.properties.boxWidth or 0.5) * image.width,
                  halfHeight = (object.properties.boxHeight or 0.5) * image.height,
                  x = object.properties.boxX or 0,
                  y = object.properties.boxY or 0,
                  angle= object.properties.boxAngle or 0 }
              end
              physics.addBody(image, object.properties.bodyType, object.properties)
            end
            -- apply custom properties
            image = inherit(image, layer.properties)
            image = inherit(image, object.properties)
          end
        elseif object.polygon or object.polyline then -- Polygon/line
          local points = object.polygon or object.polyline
          local polygon, originX, originY
          if object.polygon then
            local xMax, xMin, yMax, yMin = -4294967296, 4294967296, -4294967296, 4294967296 -- 32 ^ 2 a large number
            for p = 1, #points do
              if points[p].x < xMin then xMin = points[p].x end
              if points[p].y < yMin then yMin = points[p].y end
              if points[p].x > xMax then xMax = points[p].x end
              if points[p].y > yMax then yMax = points[p].y end
            end
            originX, originY = (xMax + xMin) / 2, (yMax + yMin) / 2
            polygon = display.newPolygon(objectGroup, object.x, object.y, unpackPoints(points))
            polygon:translate(originX, originY)
          else
            polygon = display.newLine(objectGroup, points[1].x, points[1].y, points[2].x, points[2].y)
            originX, originY = points[1].x, points[1].y
            for p = 3, #points do
              polygon:append(points[p].x, points[p].y)
            end
            polygon.x,polygon.y = object.x, object.y
            polygon:translate(originX, originY)
          end
          polygon.points = points
          -- simple physics
          if object.properties.bodyType then
            if true then -- always make chains
              object.properties.chain = unpackPoints(points, -originX, -originY)
              object.properties.connectFirstAndLastChainVertex = object.polygon and true or false
            else
              object.properties.shape = unpackPoints(points, -originX, -originY)
            end
            physics.addBody(polygon, object.properties.bodyType, object.properties)
          end
          -- name and type
          polygon.name = object.name
          polygon.type = object.type
          polygon.id = object.id
          -- apply custom properties
          polygon = inherit(polygon, layer.properties)
          polygon = inherit(polygon, object.properties)
          polygon.rotation = object.rotation
          -- vector properties
          if polygon.fillColor then polygon:setFillColor(decodeTiledColor(polygon.fillColor)) end
          if polygon.strokeColor then polygon:setStrokeColor(decodeTiledColor(polygon.strokeColor)) end
        elseif object.ellipse then -- circles
          local circle = display.newCircle(objectGroup, 0, 0, (object.width + object.height) * 0.25)
          circle.anchorX, circle.anchorY = 0, 0
          circle.x, circle.y = object.x, object.y
          circle.rotation = object.rotation
          circle.isVisible = object.visible
          centerAnchor(circle)
          -- simple physics
          if object.properties.bodyType then
            physics.addBody(circle, object.properties.bodyType, object.properties)
          end
          -- name and type
          circle.name = object.name
          circle.type = object.type
          circle.id = object.id
          -- apply custom properties
          circle = inherit(circle, layer.properties)
          circle = inherit(circle, object.properties)
          -- vector properties
          if circle.fillColor then circle:setFillColor(decodeTiledColor(circle.fillColor)) end
          if circle.strokeColor then circle:setStrokeColor(decodeTiledColor(circle.strokeColor)) end
        else -- if all else fails make a simple rect
          local rect = display.newRect(objectGroup, 0, 0, object.width, object.height)
          rect.anchorX, rect.anchorY = 0, 0
          rect.x, rect.y = object.x, object.y
          rect.rotation = object.rotation
          rect.isVisible = object.visible
          centerAnchor(rect)
          -- simple physics
          if object.properties.bodyType then
            physics.addBody(rect, object.properties.bodyType, object.properties)
          end
          -- name and type
          rect.name = object.name
          rect.type = object.type
          rect.id = object.id
          -- apply custom properties
          rect = inherit(rect, layer.properties)
          rect = inherit(rect, object.properties)
          -- vector properties
          if rect.fillColor then rect:setFillColor(decodeTiledColor(rect.fillColor)) end
          if rect.strokeColor then rect:setStrokeColor(decodeTiledColor(rect.strokeColor)) end
        end
      end
    end
    objectGroup.name = layer.name
    objectGroup.isVisible = layer.visible
    objectGroup.alpha = layer.opacity
    map:insert(objectGroup)
  end

  function map:extend(...)
    local extensions = arg or {}
    -- each custom object above has its own ponywolf.plugin module
    for t = 1, #extensions do
      -- load each module based on type
      local plugin = require ((self.extensions or defaultExtensions) .. extensions[t])
      -- find each type of tiled object
      local images = self:listTypes(extensions[t])
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
  function map:findObject(name, type)
    if not self.numChildren then return false end
    for layers = self.numChildren,1,-1 do
      local layer = self[layers]
      if layer.numChildren then
        for i = layer.numChildren,1,-1 do
          if layer[i].name == name then
            if type then
              if layer[i].type == type then
                return layer[i]
              end
            else
              return layer[i]
            end
          end
        end
      end
    end
    return false
  end

-- return all display objects with names
  function map:findObjects(...)
    local objects = {}
    for layers = self.numChildren,1,-1 do
      local layer = self[layers]
      if layer.numChildren then
        for i = layer.numChildren,1,-1 do
          for j = 1, #arg do
            if arg[j]==nil or layer[i].name == arg[j] then
              objects[#objects+1] = layer[i]
            end
          end
        end
      end
    end
    return objects
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

  function map:findLayer(name)
    if self.numChildren then
      for layers=1, self.numChildren do
        if self[layers].name==name then -- search layers
          return self[layers]
        end
      end
    end
    return false
  end

  function map:searchLayers(name)
    local found = {}
    if self.numChildren then
      for layers=1, self.numChildren do
        if self[layers].name:find(name) then -- search layers
          found[#found+1] = self[layers]
        end
      end
    end
    return found
  end

  function map:centerObject(obj, tween)
    -- moves the world, so the specified object is on screen
    obj = self:findObject(obj)
    if not obj then return false end

    -- easiest way to scroll a map based on a character
    -- find the difference between the hero and the display center
    -- and move the world to compensate
    local objx, objy = obj:localToContent(0,0)
    objx, objy = centerX - objx , centerY - objy
    if tween then
      self.x, self.y = self.x + objx/8, self.y + objy/8
    else
      self.x, self.y = self.x + objx, self.y + objy
    end
  end

  function map:centerAnchor()
    for layer = 1, self.numChildren do
      for object = 1, map[layer].numChildren do
        map[layer][object]:translate(-width/2, -height/2)
      end
    end
    map.anchorX, map.anchorX = 0.5, 0.5
  end

-- Make sure map stays on screen
  function map:boundsCheck(border)
    if self.translate then
      border = border or 0
      local xMax, yMax = width * self.xScale, height * self.yScale
      local minX = xMax /2 - display.contentWidth + display.screenOriginX - border
      local minY = yMax /2 - display.contentHeight + display.screenOriginY - border
      if self.x < -minX then self.x = -minX end
      if self.y < -minY then self.y = -minY end
      local maxX = xMax /2 + display.screenOriginX + border
      local maxY = yMax /2 + display.screenOriginY + border
      if self.x > maxX then self.x = maxX end
      if self.y > maxY then self.y = maxY end
      -- smaller than the screen
      if xMax < display.actualContentWidth then self.x = display.contentCenterX end
      if yMax < display.actualContentHeight then self.y = display.contentCenterY end
    end
  end

  local function rightToLeft(a,b)
    return (a.x or 0) + (a.width or 0) * 0.5 > (b.x or 0) + (b.width or 0) * 0.5
  end

  local function leftToRight(a,b)
    return (a.x or 0) + (a.width or 0) * 0.5 < (b.x or 0) + (b.width or 0) * 0.5
  end

  local function upToDown(a,b)
    return (a.y or 0) + (a.height or 0) * ((1 - a.anchorY) or 0.5) < (b.y or 0) + (b.height or 0) * ((1 - b.anchorY)or 0.5)
  end

  local function downToUp(a,b)
    return (a.y or 0) + (a.height or 0) * ((1 - a.anchorY) or 0.5) > (b.y or 0) + (b.height or 0) * ((1 - b.anchorY) or 0.5)
  end

  function map:sort(reverse)
    for layer = 1, self.numChildren do
      local objects = {}
      local layerToSort = self[layer] or {}
      if layerToSort.numChildren then
        for i = 1, layerToSort.numChildren do
--          if not layerToSort[i].strokeWidth then
          objects[#objects+1] = layerToSort[i]
--          end
        end
        table.sort(objects, reverse and leftToRight or rightToLeft)
        table.sort(objects, reverse and downToUp or upToDown)
      end
      for i = #objects, 1, -1 do
        if objects[i].toBack then
          objects[i]:toBack()
        end
      end
    end
  end

  function map:sortLayer(layer, reverse)
    local objects = {}
    local layerToSort = map:findLayer(layer) or {}
    if layerToSort.numChildren then
      for i = 1, layerToSort.numChildren do
        objects[#objects+1] = layerToSort[i]
      end
      table.sort(objects, reverse and leftToRight or rightToLeft)
      table.sort(objects, reverse and downToUp or upToDown)
    end
    for i = #objects, 1, -1 do
      if objects[i].toBack then
        objects[i]:toBack()
      end
    end
  end

  function map:showLayer(...)
    if self.numChildren then
      for i=1, self.numChildren do
        for j = 1, #arg do
          if (self[i].name == arg[j]) or (arg[j] == "*") then
            self[i].isVisible = true
          end
        end
      end
    end
    return false
  end

  function map:hideLayer(...)
    if self.numChildren then
      for i=1, self.numChildren do
        for j = 1, #arg do
          if (self[i].name == arg[j]) or (arg[j] == "*") then
            self[i].isVisible = false
          end
        end
      end
    end
    return false
  end

  function map:soloLayer(...)
    if self.numChildren then
      for i=1, self.numChildren do
        self[i].wasVisible = self[i].isVisible
        self[i].isVisible = false
        for j = 1, #arg do
          if self[i].name == arg[j] then
            self[i].isVisible = true
          end
        end
      end
    end
    return false
  end

  function map:defaultLayers()
    if self.numChildren then
      for i=1, self.numChildren do
        self[i].isVisible = (self[i].wasVisible == nil) and self[i].isVisible or self[i].wasVisible
      end
    end
  end

  function map:pauseAnimations()
    for i = self.numChildren,1,-1 do
      local layers = self[i]
      for j = 1, layers.numChildren do
        if layers[j].play then
          layers[j]:pause()
        end
      end
    end
  end
  
  function map:playAnimation(layer)
    for i = self.numChildren,1,-1 do
      local layers = self[i]
      if layers.name:find(layer) then
        for j = 1, layers.numChildren do
          if layers[j].play then
            layers[j]:play()
          end
        end
      end
    end
  end  

  function map:restartAnimation(layer)
    for i = self.numChildren,1,-1 do
      local layers = self[i]
      if layers.name:find(layer) then
        for j = 1, layers.numChildren do
          if layers[j].play then
            layers[j]:pause()
            layers[j]:setFrame(1)
            layers[j]:play()
          end
        end
      end
    end
  end

  function map:snap()
    for i = self.numChildren,1,-1 do
      local layers = self[i]
      for j = 1, layers.numChildren do
        if layers[j].snap then
          print ("MAP: Snapping", layers[j].name)
          snap(self, layers[j], layers[j].snap, layers[j].margin, layers[j].safe)
        end
      end
    end
  end

-- sort map by defaults
  map:sort()

-- add helpful values to the map itself
  map.designedWidth, map.designedHeight = width, height

-- set the background color to the map background
  if data.backgroundcolor then
    if type(data.backgroundcolor) == "string" then
      display.setDefault("background", decodeTiledColor("FF" .. data.backgroundcolor))
    elseif type(data.backgroundcolor) == "table" then
      for i = 1, #data.backgroundcolor do data.backgroundcolor[i] = data.backgroundcolor[i] / 255 end
      display.setDefault("background", unpack(data.backgroundcolor))
    end
  end

  return map
end

return M
