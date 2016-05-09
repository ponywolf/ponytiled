-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}

function M.new(instance)

  if not instance then error("ERROR: Expected display object") end
    
  return instance
end

return M