-- tiled Plugin template

-- Use this as a template to extend a tiled object with functionality
local M = {}

function M.new(instance)
	if not instance then error("ERROR: Expected display object") end
	local sox, soy = display.screenOriginX - instance.contentWidth, display.screenOriginY - instance.contentHeight
	local cw, ch = display.actualContentWidth + instance.contentWidth, display.actualContentHeight + instance.contentHeight
	local map = instance.parent.parent or { xScale = 1, yScale = 1 } 

	local yRandomish = (cw / map.xScale) / 3
	local xRandomish = (ch / map.yScale) / 3   

	local function enterFrame()
		if not instance then return end
		local bounds = instance.contentBounds
		instance:translate(instance.xScroll or 0, instance.yScroll or 0)
		if bounds.xMin > cw + sox then  
			instance:translate(-cw/map.xScale - (bounds.xMax - bounds.xMin),
				instance.yScroll and math.random(-yRandomish, yRandomish) or 0)
		elseif bounds.xMax < sox then
			instance:translate(cw/map.xScale + (bounds.xMax - bounds.xMin),
				instance.yScroll and math.random(-yRandomish, yRandomish) or 0)
		end
		if bounds.yMin > ch + soy then
			instance:translate(instance.xScroll and math.random(-xRandomish, xRandomish) or 0,
				-ch/map.xScale - instance.height/map.xScale)
		elseif bounds.yMax < soy then
			instance:translate(instance.xScroll and math.random(-xRandomish, xRandomish) or 0,
				ch/map.xScale + instance.height/map.xScale)
		end
		if instance.angularMomentum then instance:rotate(instance.angularMomentum) end
	end

	function instance:finalize()
		-- On remove, cleanup instance 
		Runtime:removeEventListener("enterFrame", enterFrame)
	end

	instance:addEventListener("finalize")
	Runtime:addEventListener("enterFrame", enterFrame)

	return instance
end

return M