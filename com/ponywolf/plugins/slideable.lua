-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}

function M.new(instance, slideX, slideY)
  instance.slideX = slideX == nil or slideX
  instance.slideY = slideY == nil or slideY
  

  if not instance then error("ERROR: Expected display object") end

  local dx, lastx, dy, lasty 

  function instance:set()
    self.markX, lastx = self.x, self.x
    self.markY, lasty = self.y, self.y
    dx, dy = 0, 0
  end

  function instance:touch(event)
    if event.phase == "follow" then
      self.isFocus = true
    end
    if event.phase == "began" then
      display.getCurrentStage():setFocus(self, event.id)
      transition.cancel(self)
      self.isFocus = true
      self:set()
    elseif self.isFocus then
      if event.phase == "moved" or event.phase == "follow" then
        self.x = instance.slideX and event.x - event.xStart + self.markX or self.x
        self.y = instance.slideY and (event.y - event.yStart) * 0.25 + self.markY or self.y
        if self.boundsCheck then self:boundsCheck() end
        dx, dy = (dx*9 + (self.x - lastx))/10, (dy*9 + (self.y - lasty))/10      
        lastx, lasty = self.x, self.y      
      elseif event.phase == "ended" or event.phase == "cancelled" then
        self:translate(dx * dx * (dx < 0 and -0.75 or 0.75), dy * dy * (dy < 0 and -0.5 or 0.5)) -- this just felt right
        local durration = 166 + (16 * math.sqrt(dx*dx + dy*dy))
        if self.boundsCheck then self:boundsCheck() end
        transition.from(self, { x = lastx, y = lasty, time = durration, transition = easing.outExpo })
        display.getCurrentStage():setFocus(self, nil)
        self.isFocus = false
      end
    end
    return true
  end

  instance:addEventListener("touch")
  return instance
end

return M