-- smart button

local M = {}
local label = require "com.ponywolf.plugins.label"
local isMobile = ("ios" == system.getInfo("platform")) or ("android" == system.getInfo("platform"))
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
  local parent = instance.parent or {}

  -- store inital scale
  instance._xScale, instance._yScale = instance.xScale, instance.yScale
  instance._rotation = instance.rotation 
  local toggleImage = false
  local toggleText = false
  local map = parent.parent

  instance.isHitTestable = true -- for invisible buttons

  -- are we an image toggle?
  if instance.toggleImage then 
    local map = parent.parent
    if map.findObject then -- are we a tiled map
      instance.toggleImage = map:findObject(instance.toggleImage)
      if instance.toggleImage then -- are we an image
        instance.toggleImage.x = instance.x
        instance.toggleImage.y = instance.y
        instance.toggleImage.isVisible = false
        instance.isHitTestable = true
        toggleImage = true
      end
    end
  end

  -- are we a text toggle?
  if instance.text then
    instance.keepInstance = true
    instance.label = label.new(instance)
    instance.label.name = (instance.label.name or "") .. "Label"
    parent:insert(instance.label)
    if instance.toggleText then
      toggleText = true
      instance.defaultText = instance.toggleText
    end
  end

  -- mouse down/over code here
  local function sizeButton(scale)
    if instance.label then
--      instance.label.x, instance.label.y = instance.x, instance.y
      instance.label.xScale, instance.label.yScale = scale or 1, scale or 1
    end
    instance.xScale, instance.yScale = instance._xScale * (scale or 1), instance._yScale * (scale or 1)
  end

  -- are we a toggle and default
  function instance:getToggle()
    if toggleImage or toggleText then    
      if toggleText then 
        return not (self.text == instance.defaultText) -- true if in non-default state
      elseif toggleImage then
        return self.isVisible
      end
    else
      return nil
    end
  end

  -- force a toggle state
  function instance:setToggle(default)
    if toggleImage or toggleText then
      if default == false then
        if toggleText then 
          self.text = instance.defaultText
          self.label:update(self.text)
        end
        if toggleImage then 
          self.isVisible, self.toggleImage.isVisible = true, false
        end
      else --true or nil
        if toggleText then 
          self.text = self.toggleText
          self.label:update(self.text)        
        end
        if toggleImage then 
          self.isVisible, self.toggleImage.isVisible = false, true
        end
      end
      return self:getToggle()
    else
      return nil
    end
  end

  -- toggle a button state
  function instance:toggle()
    if toggleImage or toggleText then
      if toggleText then 
        self.text, self.toggleText = self.toggleText, self.text
        self.label:update(self.text)
      end
      if toggleImage then 
        self.isVisible, self.toggleImage.isVisible = self.toggleImage.isVisible, self.isVisible
      end
      return self:getToggle()
    else
      return nil
    end
  end

  function instance:enable()
    self.enabled = true
    self:setFillColor(1)
  end

  function instance:disable()
    self.enabled = false
    self:setFillColor(0)
  end

  -- touch code
  function instance:touch(event)
    local phase, name = event.phase, event.name
    if self.enabled == false then return false end
    -- press in animation
    if phase == "began" then
      if event.id then stage:setFocus(self) end
      self.isFocus = true
      sizeButton(0.95)
      -- set map if exists
      if map and map.set then
        map:set()
      end
      -- send event
      local uiEvent = {name = "ui", phase = "pressed", target = self, map = self.parent.parent, tag = self.tag, buttonName = self.name or "none"}
      Runtime:dispatchEvent(uiEvent)
    elseif phase == "moved" and self.isFocus then
      if inBounds(event, self) and not self.isCancelled then -- inside
        sizeButton(0.95)
      else -- outside
        if (not self.noFollow) and map and map.touch then
          self.isCancelled = true
          event.phase = "follow"
          map:touch(event)
        end
        sizeButton()    
      end        
      -- release animation
    elseif (phase == "ended" or phase == "cancelled") and self.isFocus then
      if event.id then stage:setFocus(nil) end
      if inBounds(event, self) and not self.isCancelled then -- inside
        local uiEvent = {name = "ui", phase = "released", target = self,  map = self.parent.parent, tag = self.tag, buttonName = self.name or "none"}
        uiEvent.toggled = self:toggle()
        Runtime:dispatchEvent(uiEvent)
      else -- outside
        if map and map.touch then 
          map:touch(event)
        end
      end        
      sizeButton()
      self.isFocus = false
      self.isCancelled = false
      -- look for mouse events in our content bounds
    elseif name == "mouse" and not self.isFocus then -- mouse overs
      if inBounds(event, self) then -- inside
        sizeButton(1.025)
      else -- outside
        sizeButton()    
      end 
    end
    if toggleImage then -- match other image size
      self.toggleImage.x, self.toggleImage.y = self.x, self.y
      self.toggleImage.xScale, self.toggleImage.yScale = self.xScale, self.yScale
    end
    return true  
  end

  -- for mouse interfaces only
  local function mouseOver(event)
    instance:touch(event)
  end

  function instance:finalize()
    Runtime:removeEventListener("mouse", mouseOver)
  end

  if not isMobile then 
    Runtime:addEventListener("mouse", mouseOver)    
  end

  -- add event
  instance:addEventListener('finalize')
  instance:addEventListener("touch")

  return instance
end

return M