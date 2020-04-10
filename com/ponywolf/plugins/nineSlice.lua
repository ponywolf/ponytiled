-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}

local function newSlice(options) 
  local slice = {}

  options = options or {}

  local filename = options.filename
  local border = options.border or 32
  local top = options.top or border
  local left = options.left or border
  local right = options.right or border
  local bottom = options.bottom or border
  local width = options.textureWidth or 256 
  local height = options.textureHeight or 256	

  -- Image Sheet needs to be set like this...

  --	+----+-----+-----+
  --	|  1 |  2  |  3  |
  --	+----+-----+-----+
  --	|  4 |  5  |  6  |
  --	+----+-----+-----+	
  --	|  7 |  8  |  9  |
  --	+----+-----+-----+

  local sheetOptions = 
  {
    sheetContentWidth = width,  -- width of original 1x size of entire sheet
    sheetContentHeight = height,  -- height of original 1x size of entire sheet
    frames =
    {	-- frame 1, upper left corner
      {	x = 0,
        y = 0,
        width = left,
        height = top,
      }, -- frame 2, top
      {	x = left,
        y = 0,
        width = width - left - right,
        height = top,
      },-- frame 3, upper right corner
      {	x = width - right,
        y = 0,
        width = right,
        height = top,
      }, -- frame 4, middle left
      {	x = 0,
        y = top,
        width = left,
        height = height - top - bottom,
      },-- frame 5, center
      {	x = left,
        y = top,
        width = width - left - right,
        height = height - top - bottom,
      }, -- frame 6, middle right
      {	x = width - right,
        y = top,
        width = right,
        height = height - top - bottom,
      },-- frame 7, bottom left corner
      {	x = 0,
        y = height - bottom,
        width = left,
        height = bottom,
      },-- frame 8, bottom
      {	x = left,
        y = height - bottom,
        width = width - left - right,
        height = bottom,
      },-- frame 9, bottom right corner
      {	x = width - right,
        y = height - bottom,
        width = right,
        height = bottom,
      },				
    }
  }		

  slice.top = top
  slice.left = left 
  slice.right = right 
  slice.bottom = bottom 
  slice.width = width 
  slice.height = height

  slice.sheetOptions = sheetOptions
  slice.sheet = graphics.newImageSheet( filename, sheetOptions )	

  function slice:render(options)
    local sliceGroup = display.newGroup()

    options = options or {}
    local x = options.x or 0
    local y = options.y or 0
    local width = options.width or 512 
    local height = options.height or 512

    -- Guide image (debug only)
--		local guide = display.newRect(x,y,width,height)
--		guide.alpha = 0.2

    local topLeft = display.newImageRect(sliceGroup, self.sheet, 1, self.left, self.top )
    topLeft.anchorX, topLeft.anchorY = 0,0
    topLeft.x, topLeft.y = x, y

    local top = display.newImageRect(sliceGroup, self.sheet, 2, width - self.left - self.right, self.top  )
    top.anchorX, top.anchorY = 0,0
    top.x, top.y = x + self.left, y

    local topRight = display.newImageRect(sliceGroup, self.sheet, 3, self.right, self.top  )
    topRight.anchorX, topRight.anchorY = 0,0
    topRight.x, topRight.y = x + width - self.right, y

    local left = display.newImageRect(sliceGroup, self.sheet, 4, self.left, height - self.top - self.bottom   )
    left.anchorX, left.anchorY = 0,0 
    left.x, left.y = x, y + self.top

    local middle = display.newImageRect(sliceGroup, self.sheet, 5, width - self.left - self.right, height - self.top - self.bottom   )
    middle.anchorX, middle.anchorY = 0,0 
    middle.x, middle.y = x + self.left, y + self.top

    local right = display.newImageRect(sliceGroup, self.sheet, 6, self.right, height - self.top - self.bottom   )
    right.anchorX, right.anchorY = 0,0 
    right.x, right.y = x + width - self.right, y + self.top

    local bottomLeft = display.newImageRect(sliceGroup, self.sheet, 7, self.left, self.bottom )
    bottomLeft.anchorX, bottomLeft.anchorY = 0,0 
    bottomLeft.x, bottomLeft.y = x, y + height - self.bottom

    local bottom = display.newImageRect(sliceGroup, self.sheet, 8, width - self.left - self.right, self.bottom  )
    bottom.anchorX, bottom.anchorY = 0,0 
    bottom.x, bottom.y = x + self.left, y + height - self.bottom

    local bottomRight = display.newImageRect(sliceGroup, self.sheet, 9, self.right, self.bottom  )
    bottomRight.anchorX, bottomRight.anchorY = 0,0 
    bottomRight.x, bottomRight.y = x + width - self.right, y + height - self.bottom

    for i = sliceGroup.numChildren, 1, -1 do
      sliceGroup[i]:translate(-width/2, -height/2)
    end

    return sliceGroup
  end	

  return slice
end

function M.new(instance)

  if not instance then error("ERROR: Expected display object") end
  if not instance.filename then error("ERROR: Expected display object with filename parameter") end
  
  instance.alpha = 0.2
  
  local panel = newSlice({ border = 32, textureWidth = instance.textureWidth, textureHeight = instance.textureHeight, filename = instance.filename }) 
  local parent,x,y,w,h = instance.parent, instance.x, instance.y, instance.width * instance.xScale, instance.height * instance.yScale  
  
  display.remove(instance)
  instance = panel:render( { width = w, height = h } )
  parent:insert(instance)
  instance.x, instance.y = x,y
  
  return instance
end

return M