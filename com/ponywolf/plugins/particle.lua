-- Particle Extension template

local M = {}
local pex = require "com.ponywolf.pex"

function M.new(instance)
  if not instance then error("ERROR: Expected display object") end
  local parent = instance.parent
  --print("file = " .. instance.filename, instance.filename:gsub(".pex", ".png"))
  local particle = pex.load(instance.filename, instance.filename:gsub(".pex", ".png"))
  local emitter = display.newEmitter(particle)
  emitter.absolutePosition = false
  emitter.x,emitter.y = instance.x, instance.y
  emitter.alpha = instance.alpha
  instance.isVisible = false -- get rid of placeholder
  instance.emitter = emitter
  parent:insert(instance.emitter)
  return instance
end

return M