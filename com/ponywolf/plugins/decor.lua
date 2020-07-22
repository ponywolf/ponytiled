-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}
local fx = require "com.ponywolf.ponyfx"

function M.new(instance)

  if not instance then error("ERROR: Expected display object") end

  if instance.decorType == "bounce" then
    fx.bounce(instance, instance.intensity, instance.time, instance.rnd)
  elseif instance.decorType == "bounce3D" then
    fx.bounce3D(instance, instance.intensity, instance.time, instance.rnd)
  elseif instance.decorType == "breath" then
    fx.breath(instance, instance.intensity, instance.time, instance.rnd)
  elseif instance.decorType == "float" then
    fx.float(instance, instance.intensity, instance.time, instance.rnd)
  elseif instance.decorType == "sway" then
    fx.sway(instance, instance.intensity, instance.time, instance.rnd)
  elseif instance.decorType == "spin" then
    instance.rotation = 0
    transition.to (instance, {time = instance.time or 6000, rotation = 360, iterations =-1})
  end

  return instance
end

return M