-- Particle Extension template

local M = {}

function M.new(instance)
  if not instance then error("ERROR: Expected display object") end
  local parent = instance.parent
  local name, tiledType = instance.name, instance.type
  local particle = require("particles." .. name)
  local emitter = display.newEmitter(particle)
  emitter.x,emitter.y = instance.x + instance.contentWidth/2, instance.y + instance.contentHeight/2
  emitter.alpha = instance.alpha
  display.remove(instance) -- get rid of placeholder
  instance = emitter
  instance.name, instance.type = name, tiledType
  parent:insert(instance)
  return instance
end

return M