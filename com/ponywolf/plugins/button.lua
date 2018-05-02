-- tiledObject template

-- Use this as a template to extend a tiled object with functionality

local M = {}
local stage = display.getCurrentStage()

local function inBounds(event, object)
  local ex, ey = event.x or 0, event.y or 0
  local bounds = object.contentBounds or {}
  if bounds then
    if ex < bounds.xMin or ex > bounds.xMax or ey < bounds.yMin or ey > bounds.yMax then   
      return false
    else 
      return true
    end
    return false
  end
end

function M.new(instance)

  if not instance then error("ERROR: Expected display object") end

  -- remember inital scale
  instance._xScale, instance._yScale = instance.xScale, instance.yScale
  instance._rotation = instance.rotation 
 
  function instance:touch(event)
    local phase = event.phase
    local name = event.name
    -- press in animation
    if phase=="began" then
      if event.id then stage:setFocus(event.target, event.id) end
      self.isFocus = true
      instance.xScale, instance.yScale = instance.xScale * 0.95, instance.yScale * 0.95
      local uiEvent = {name = "ui", phase = "pressed", buttonName = self.name or "none"}
      Runtime:dispatchEvent(uiEvent)
    elseif phase == "moved" and self.isFocus then
      if inBounds(event, self) then -- inside
        self.xScale, self.yScale = self._xScale * 0.95, self._yScale * 0.95
      else -- outside
        self.xScale, self.yScale = self._xScale, self._yScale
      end        
    -- release animation
    elseif phase == "ended" or phase == "canceled" then
      if event.id then stage:setFocus(nil, event.id) end
      self.isFocus = false
      if inBounds(event, self) then -- inside
        local uiEvent = {name = "ui", phase = "released", buttonName = self.name or "none"}
        Runtime:dispatchEvent(uiEvent)
      end        
      self.xScale, self.yScale = self._xScale, self._yScale
    -- look for mouse events in our content bounds
    elseif name == "mouse" and not self.isFocus then -- mouse overs
      if inBounds(event, self) then -- inside
        self.xScale, self.yScale = self._xScale * 1.025, self._yScale * 1.025
      else -- outside
        self.xScale, self.yScale = self._xScale, self._yScale
      end 
    end
    return true  
  end

  local function mouseOver(event)
    instance:touch(event)
  end

  function instance:finalize()
    Runtime:removeEventListener("mouse", mouseOver)
  end

  instance:addEventListener('finalize')
  instance:addEventListener("touch")
  Runtime:addEventListener("mouse", mouseOver)    

  return instance
end

return M