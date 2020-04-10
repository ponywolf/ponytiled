-- thumb component of the slider

local M = {}

function M.new(instance)

  if not instance then error("ERROR: Expected display object") end

  local horizontal, min, max

  --do we have a slider?
  if instance.slider then 
    local map = instance.parent.parent
    if map.findObject then -- are we a tiled map
      instance.slider = map:findObject(instance.slider)
    end
  end

  if not instance.slider then error("ERROR: Expected display object for slider") end

  function instance.reset()
    if instance.slider then -- are we an image
      local map = instance.parent
      horizontal = instance.slider.width > instance.slider.height
      if horizontal then
        min = map:contentToLocal(instance.slider.contentBounds.xMin)
        max = map:contentToLocal(instance.slider.contentBounds.xMax)
      else
        local _
        _,min = map:contentToLocal(0,instance.slider.contentBounds.yMin)
        _,max = map:contentToLocal(0,instance.slider.contentBounds.yMax)
      end
    end
  end

  function instance:set( value )
    instance.reset()
    value = value or 0.0
    value = math.min(1,math.max(0,value))
    if horizontal then 
      self.x = min + ((max - min) * value)
    else
      self.y = min + ((max - min) * (1-value))
    end
    return true
  end

  function instance:get( value )
    instance.reset()
    if horizontal then 
      value = (self.x - min) / (max - min)
    else
      value = 1 - (self.y - min) / (max - min)
    end
    value = math.min(1,math.max(0,value))
    return value
  end

  function instance:touch( event )
    local value = self:get()
    if event.phase == "began" then
      instance.reset()
      display.getCurrentStage():setFocus( self, event.id )
      self.isFocus = true
      self.markX = self.x
      self.markY = self.y
      local uiEvent = {name = "ui", phase = "pressed", value = value, target = self, tag = self.tag, buttonName = self.name or "none"}
      Runtime:dispatchEvent(uiEvent)
    elseif self.isFocus then
      if event.phase == "moved" then
        if horizontal then 
          self.x = event.x - event.xStart + self.markX
          self.x = math.min(math.max(self.x, min), max)
        else
          self.y = event.y - event.yStart + self.markY
          self.y = math.min(math.max(self.y, min), max)
        end
        local uiEvent = {name = "ui", phase = "slid", value = value,  target = self, tag = self.tag, buttonName = self.name or "none"}
        Runtime:dispatchEvent(uiEvent)
      elseif event.phase == "ended" or event.phase == "cancelled" then
        local uiEvent = {name = "ui", phase = "released", value = value, target = self, tag = self.tag, buttonName = self.name or "none"}
        Runtime:dispatchEvent(uiEvent)
        display.getCurrentStage():setFocus( self, nil )
        self.isFocus = false
      end
    end
    return true
  end

  instance:addEventListener("touch")
  return instance
end

return M