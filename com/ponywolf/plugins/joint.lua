-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}

function M.new(instance, map)

  if not instance then error("ERROR: Expected display object") end
  print ("Found pivot: ",instance.name, " connects ", instance.bodyA,  "to", instance.bodyB)
  local bodyA = map:findObject(instance.bodyA)
  local bodyB = map:findObject(instance.bodyB)
  local jointType = instance.jointType or "distance"


  if jointType == "distance" then
--    if instance.points and #instance.points > 1 then
--      local p = instance.points
--      local distance = math.sqrt((p[1].x - p[2].x)*(p[1].x - p[2].x) + (p[1].y - p[2].y)*(p[1].y - p[2].y))
--      instance.joint = physics.newJoint(jointType, bodyA, bodyB, p[1].x, p[1].y, p[2].x, p[2].y)
--      instance.joint.length = distance
--    else
      instance.joint = physics.newJoint(jointType, bodyA, bodyB, bodyA.x, bodyA.y, bodyB.x, bodyB.y)
--    end
  elseif jointType == "pivot" or jointType == "weld" then
    instance.joint = physics.newJoint(jointType, bodyA, bodyB, instance.x, instance.y)
  elseif jointType == "rope" then
    instance.joint = physics.newJoint(jointType, bodyA, bodyB)
  end

  instance.joint.dampingRatio = instance.dampingRatio
  instance.joint.frequency = instance.frequency

  instance.isSensor = true
  instance.isVisible = false -- hide rect placeholder
  instance.alpha = 0.0 -- hide rect placeholder      


  return instance
end

return M