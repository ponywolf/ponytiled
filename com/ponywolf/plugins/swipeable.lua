-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}
local sensitivity = 128

function M.new(instance)

  if not instance then error("ERROR: Expected display object") end

  function instance:touch(event)
    if event.phase == "began" and not self.isFocus then
      display.getCurrentStage():setFocus(self, event.id)
      self.isFocus = true
      self.markX = self.x
      self.markY = self.y
    elseif self.isFocus then
      if event.phase == "moved" then
        --self.x = event.x - event.xStart + self.markX
        --self.y = event.y - event.yStart + self.markY
      elseif event.phase == "ended" or event.phase == "cancelled" then
        display.getCurrentStage():setFocus(self, nil)
        if event.x > event.xStart + sensitivity then
          transition.to(self, { x = self.markX, transition = easing.outExpo, time = 0,
              onComplete = function () 
                Runtime:dispatchEvent({ name = "ui", phase = "swipe", tag = instance.tag, buttonName = "previous", target = self })
                self.isFocus = false
              end
            })
        elseif event.x < event.xStart - sensitivity then
          transition.to(self, { x = self.markX, transition = easing.outExpo, time = 0,
              onComplete = function () 
                Runtime:dispatchEvent({ name = "ui", phase = "swipe", tag = instance.tag, buttonName = "next", target = self })
                self.isFocus = false
              end
            })
        else
          transition.to(self, { x = self.markX, transition = easing.outExpo, time = 0, 
              onComplete = function () 
                Runtime:dispatchEvent({ name = "ui", phase = "none", tag = instance.tag, target = self })
                self.isFocus = false
              end
            })     
        end
      end
    end
    return true
  end

  instance:addEventListener("touch")
  return instance
end

return M