-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}

local centerX, centerY = display.contentCenterX, display.contentCenterY

local size, spacing, padding, caps, lineHeight = 32, 4, 32, true, 30

local function decodeTiledColor(hex)
  hex = hex or "#FF888888"
  hex = hex:gsub("#","")
  local function hexToFloat(part)
    part = part or "00"
    part = part == "" and "00" or part
    return tonumber("0x".. (part or "00")) / 255
  end
  local a, r, g, b =  hexToFloat(hex:sub(1,2)), hexToFloat(hex:sub(3,4)), hexToFloat(hex:sub(5,6)), hexToFloat(hex:sub(7,8)) 
  return r, g, b, a
end

local function split(line, separator)
  line = line or ""
  separator = separator or " "  
  local items = {}
  local i=1
  for str in string.gmatch(line, "([^"..separator.."]+)") do
    items[i] = str
    i = i + 1
  end
  return items
end

function math.clamp(low, n, high) return math.min(math.max(n, low), high) end

function M.new(instance, options) --text, wrap, align, color)
    if not instance then error("ERROR: Expected display object") end  

  -- remember inital object
  local tiledObj = instance
  
  local text = tiledObj.text or " "
  text = text:gsub("|","\n")
  local font = tiledObj.font or native.systemFont
  local size = tiledObj.size or 20
  local stroked = tiledObj.stroked
  local strokeColor = tiledObj.strokeColor or "FF000000"
  local align = tiledObj.align or "center"
  local color = tiledObj.color or "FFFFFFFF"
  local params = { parent = tiledObj.parent,
    x = tiledObj.x, y = tiledObj.y, strokeColor = strokeColor, color = color,
    text = text, font = font, fontSize = size, strokeWidth = tiledObj.labelStrokeWidth or 1,
    align = align, width = tiledObj.width } 
  
  instance = display.newGroup()

  local strong, em  = false, false
  
  color = color or { 1 }

  local words = split(text)
  local x, y, line = 0, 0, 1
  instance.word = {}
  instance.lineWidth = {}
  for i = 1, #words do
    words[i] = caps and words[i]:upper() or words[i]
    words[i] = words[i]:gsub("!","! ")    
    words[i] = words[i]:gsub("?","? ")
    if words[i]:find("*")==1 or strong then
      strong = true
      if words[i]:find("*", 2) then 
        strong = false -- single word or end
      end
      bold.text = words[i]:gsub("*","")
      instance.word[i] = display.newText(bold)
    elseif words[i]:find("_")==1 or em then
      em = true
      if words[i]:find("_", 2) then 
        em = false -- single word or end
      end
      italic.text = words[i]:gsub("_","")
      instance.word[i] = display.newText(italic)
    else
      regular.text = words[i]
      instance.word[i] = display.newText(regular)
    end
    if wrap and x > wrap then
      x = 0
      y = y + lineHeight
      line = line + 1
    end
    instance.word[i].x, instance.word[i].y = x, y
    instance.word[i].line = line
    x = x + instance.word[i].width + spacing + (words[i]:sub(-1) == "." and spacing*2 or 0)
    instance.word[i]:translate(instance.word[i].width/2 - spacing/2,0)
    instance.word[i]:setFillColor(0)
    instance:insert(instance.word[i])
    instance.lineWidth[line] = x
  end

  -- draw box

  local w,h = instance.width, instance.height
  instance.bubble = display.newRect(0,0, w + padding, h + padding / 2)
  instance.bubble:setFillColor(unpack(color))
  instance:insert(instance.bubble)
  instance.bubble:toBack()
  
--  instance.bubble = display.newCircle(0,0, (w + padding)/2)
--  instance.bubble.yScale = 0.5
--  instance.bubble:setFillColor(unpack(color))
--  instance:insert(instance.bubble)
--  instance.bubble:toBack()

  instance.arrow = display.newImageRect(instance, "scene/game/img/arrow.png", arrowSize, arrowSize)
  instance.arrow.anchorX = 0.1
  instance.arrow:toBack()
  instance.arrow:setFillColor(unpack(color))  
  instance.arrow.isVisible = false

  instance.stroke = display.newRect(0,0, w + padding + 8, h + padding / 2 + 8)
  instance.stroke:setFillColor(0)
  instance:insert(instance.stroke)
  instance.stroke:toBack()

--  instance.stroke = display.newCircle(0,0, (w + padding + 16)/2)
--  instance.stroke.yScale = 0.5
--  instance.stroke:setFillColor(0)
--  instance:insert(instance.stroke)
--  instance.stroke:toBack()

  instance.arrowStroke = display.newImageRect(instance, "scene/game/img/arrow.png", arrowSize + padding/3, arrowSize + padding/3)
  instance.arrowStroke:setFillColor(0)
  instance.arrowStroke.anchorX = 0.1
  instance.arrowStroke:toBack()
  instance.arrowStroke.isVisible = false
  
  -- draw bubbles

  for i = 1, #words do
    if align == "left" then 
      instance.word[i]:translate(-w/2,-h/2+size/2) -- left justify
    elseif align == "right" then 
      instance.word[i]:translate(-instance.lineWidth[instance.word[i].line]+w/2,-h/2+size/2) 
    else
      instance.word[i]:translate(-instance.lineWidth[instance.word[i].line]/2,-h/2+size/2) 
    end
  end

  function instance:point(x, y)
    instance.arrow.isVisible = true
    instance.arrowStroke.isVisible = true
    
    local sx, sy = instance:localToContent(0,0)
    
    local hint = (x - display.contentCenterX) / display.contentWidth
    hint = math.clamp(-0.5, hint, 0.5)
    instance.arrow.x = hint * 0.85 * w
    instance.arrowStroke.x = hint * 0.85 * w    
    
    local angle = (math.deg(math.atan2(y-sy, x-sx)) + 360) % 360          
    if y > sy then 
      angle = math.clamp(65,angle,115)
      instance.arrow.y = h / 2
      instance.arrowStroke.y = h / 2 
    else 
      angle = math.clamp(65+180,angle,115+180)
      instance.arrow.y = -h / 2
      instance.arrowStroke.y = -h / 2 
    end
    instance.arrow.rotation = angle
    instance.arrowStroke.rotation = angle
  end

  return instance
end

return M