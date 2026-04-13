-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}

local centerX, centerY = display.contentCenterX, display.contentCenterY

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
  instance = display.newGroup()

  local text = tiledObj.text or " "
  text = text:gsub("|","\n")
  local font = tiledObj.font or native.systemFont
  local size = tiledObj.size or 20
  local align = tiledObj.align or "center"
  local valign = tiledObj.valign or "center"
  local color = tiledObj.color or "FFFFFFFF"
  local wrap = tiledObj.width
  local spacing = tiledObj.spacing or math.ceil(size / 10)
  local lineHeight = tiledObj.lineHeight or size * 0.8
  local caps = tiledObj.caps
  local width = tiledObj.width
  local height = tiledObj.height

  local params = { parent = instance, color = color, x = 0, y = 0,
    text = text, font = font, fontSize = size }

  function instance:update(newText)
    newText = newText:gsub("\n", "|")
    newText = newText:gsub("|", " | ")
    local words = split(newText)
    local x, y = 0, 0
    if instance.word then
      for i = 1, #instance.word do
        display.remove(instance.word[i])
      end
    end
    instance.word = {}
    local lf = 1
    for i = 1, #words do
      words[i] = caps and words[i]:upper() or words[i]
      -- add some space to punctuation
      words[i] = words[i]:gsub("!","! ")
      words[i] = words[i]:gsub("?","? ")
      words[i] = words[i]:gsub("%.",". ")
      params.text = words[i] == "|" and "" or words[i]
      instance.word[i] = display.newText(params)
      instance.word[i].anchorX, instance.word[i].anchorY = 0,0
      local space = instance.word[i].width + spacing
      if (x + space) > wrap or words[i] == "|" then
        x = 0
        y = y + lineHeight
        local w = width - (instance.word[i-1].x + instance.word[i-1].width)
        if align == "center" then
          for j = lf, i-1 do
            instance.word[j]:translate(w/2,0)
          end
        elseif align == "right" then
          for j = lf, i-1 do
            instance.word[j]:translate(w,0)
          end
        end
        lf = i
      end
      instance.word[i].x, instance.word[i].y = x, y
      x = x + space
      instance.word[i]:setFillColor(decodeTiledColor(color))
      instance:insert(instance.word[i])
    end
    -- last line
    local w = width - (instance.word[#instance.word].x + instance.word[#instance.word].width)
    if align == "center" then
      for j = lf, #instance.word do
        instance.word[j]:translate(w/2,0)
      end
    elseif align == "right" then
      for j = lf, #instance.word do
        instance.word[j]:translate(w,0)
      end
    end

    -- center anchor around instance x, y
    for i = 1, #instance.word do
      instance.word[i]:translate(-width/2, -height/2)
    end

    if valign == "center" then
      local h = height - instance.contentHeight
      for i = 1, #instance.word do
        instance.word[i]:translate(0, h/2)
      end
    elseif valign == "bottom" then
      local h = height - instance.contentHeight
      for i = 1, #instance.word do
        instance.word[i]:translate(0, h)
      end
    end
  end

  tiledObj.parent:insert(instance)
  instance.x, instance.y = tiledObj.x, tiledObj.y
  instance.name, instance.type = tiledObj.name, tiledObj.type
  display.remove(tiledObj)
  instance:update(text)
  return instance
end

return M