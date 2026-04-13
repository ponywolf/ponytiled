-- ponyfx

local M = {}

local function lenSqr(dx,dy,dz) return (dx * dx + dy * dy + dz * dz) end

local function offScreen(object)
  local bounds = object.contentBounds
  if not bounds then return false end
  local sox, soy = display.screenOriginX, display.screenOriginY
  if bounds.xMax < sox then return true end
  if bounds.yMax < soy then return true end
  if bounds.xMin > display.actualContentWidth - sox then return true end
  if bounds.yMin > display.actualContentHeight - soy then return true end
  return false
end

function M.flash(object, frames, listener)
  if not object.contentBounds then
    print("WARNING: Object not found")
    return false
  end

  local function flash()
    object.fill.effect = "filter.duotone"
    object.fill.effect.darkColor = { 1,1,1,1 }
    object.fill.effect.lightColor = { 1,1,1,1 }
  end

  local function revert()
    object.fill.effect = nil
  end

  object._flashFrames = math.min(180, (frames or 30) + (object._flashFrames or 0))
  local function cycle()
    if (object._flashFrames > 0) and object.contentBounds then -- flash it
      if object._flashFrames % 4 == 1 or object._flashFrames % 4 == 2 then
        revert()
      else
        flash()
      end
      object._flashFrames = object._flashFrames - 1
    else
      Runtime:removeEventListener("enterFrame", cycle)
      if listener then listener() end
    end
  end
  Runtime:addEventListener("enterFrame", cycle)
end

-- Flash screen
function M.screenFlash(color, blendMode, time)
  color = color or { 1, 1, 1, 1 }
  blendMode = blendMode or "add"
  local overlay = display.newRect(
    display.contentCenterX,
    display.contentCenterY,
    display.actualContentWidth,
    display.actualContentHeight)
  overlay:setFillColor(unpack(color))
  overlay.blendMode = blendMode
  local function destroy()
    display.remove(overlay)
  end
  transition.to(overlay, {alpha = 0, time = time or 500, transition = easing.outQuad, onComplete=destroy})
end

function M.fadeOut(onComplete, time, delay)
  local color = { 0, 0, 0, 1 }
  local overlay = display.newRect(
    display.contentCenterX,
    display.contentCenterY,
    display.actualContentWidth,
    display.actualContentHeight)
  overlay:setFillColor(unpack(color))
  overlay.alpha = 0
  local function destroy()
    if onComplete then onComplete() end
    display.remove(overlay)
  end
  transition.to(overlay, {alpha = 1, time = time or 500, delay = delay or 0, transition = easing.outQuad, onComplete=destroy})
end

function M.fadeIn(onComplete, time, delay)
  local color = { 0, 0, 0, 1 }
  local overlay = display.newRect(
    display.contentCenterX,
    display.contentCenterY,
    display.actualContentWidth,
    display.actualContentHeight)
  overlay:setFillColor(unpack(color))
  overlay.alpha = 1
  local function destroy()
    if onComplete then onComplete() end
    display.remove(overlay)
  end
  transition.to(overlay, {alpha = 0, time = time or 500, delay = delay or 1, transition = easing.outQuad, onComplete=destroy})
end

function M.dim(percent)
  local dim = display.newRect(display.contentCenterX,display.contentCenterY,display.actualContentWidth*2,display.actualContentHeight*2)
  dim:setFillColor(0,0,0,1)
  dim.alpha = percent or 0.5
  dim.isHitTestable = true
  dim.name = "dim"
  transition.from(dim, { time = 166, alpha = 0 })
  local function touch(event)
    --print("Clicked Dim", event.phase)
    return true
  end
  dim:addEventListener("touch", touch)
  return dim
end

function M.irisOut(onComplete, x, y, time, delay)
  local color = { 0, 0, 0, 1 }
  x,y = x or display.contentCenterX, y or display.contentCenterY
  local wide = display.actualContentHeight > display.actualContentWidth and display.actualContentHeight or display.actualContentWidth
  local r = 128
  local scale = wide/r + 0.15
  local overlay = display.newCircle(x,y,r)
  overlay:setStrokeColor(unpack(color))
  overlay:setFillColor(0,0,0,0)
  overlay.strokeWidth = 0
  overlay.xScale, overlay.yScale = scale, scale
  overlay:setFillColor(0,0,0,0)

  overlay.alpha = 1
  local function destroy()
    if onComplete then onComplete() end
    display.remove(overlay)
  end
  transition.to(overlay, {strokeWidth = 255, time = time or 500, delay = delay or 0, transition = easing.outQuad, onCancel = destroy, onComplete=destroy})
end

function M.irisIn(onComplete, x,y, time, delay)
  local color = { 0, 0, 0, 1 }
  x,y = x or display.contentCenterX, y or display.contentCenterY
  local wide = display.actualContentHeight > display.actualContentWidth and display.actualContentHeight or display.actualContentWidth
  local r = 128
  local scale = wide/r + 0.15
  local overlay = display.newCircle(x,y,r)
  overlay:setStrokeColor(unpack(color))
  overlay:setFillColor(0,0,0,0)
  overlay.strokeWidth = 255
  overlay.xScale, overlay.yScale = scale, scale

  overlay.alpha = 1
  local function destroy()
    if onComplete then onComplete() end
    display.remove(overlay)
  end
  transition.to(overlay, {strokeWidth = 0, time = time or 500, delay = delay or 0, transition = easing.inQuad, onCancel = destroy, onComplete=destroy})
end


-- Impact fx function

function M.impact(object, intensity, time)
  if not (object and object.contentBounds) then
    print("WARNING: Object not found")
    return false
  end
  intensity = 1 - (intensity or 0.25)
  time = time or 250
  local sx, sy = object.xScale, object.yScale
  local i = { time = time, rotation = 15 - math.random(30), xScale = sx / intensity, yScale = sy / intensity, transition = easing.outBounce }
  transition.from(object, i)
end

-- Bounce fx function

function M.bounce(object, intensity, time)
  if not (object and object.contentBounds) then
    print("WARNING: Object not found")
    return false
  end
  object._y = object.y
  intensity = intensity or 0.05
  time = time or 500

  local function onCancel() object.y = object._y end

  local i = { y=object._y-(object.width * intensity), transition=easing.outBounce, time=time, iterations=-1, onCancel = onCancel}
  transition.from(object, i)
end

-- Bounce fx function

function M.bounce3D(object, intensity, time)
  if not (object and object.contentBounds) then
    print("WARNING: Object not found")
    return false
  end
  object._yScale = object.yScale
  object._xScale = object.xScale
  intensity = intensity or 0.1
  time = time or 500

  local function onCancel() object.xScale, object.yScale = object._xScale, object._yScale end

  local i = {
    yScale=object._yScale + intensity,
    xScale=object._xScale + intensity,
    transition=easing.outBounce,
    time=time, iterations=-1,
    onCancel = onCancel
  }
  transition.from(object, i)
end

-- Breath fx function

function M.breath(object, intensity, time, rnd)
  if not (object and object.contentBounds) then
    print("WARNING: Object not found")
    return false
  end

  if object._isBreath then
    print("WARNING: Object already is breathing")
  end

  intensity = 1 - (intensity or 0.05)
  time = time or 250
  time = time + (rnd and math.random(rnd) or 0)
  local w,h,i,e = object.width, object.height, {}, {}
  local function inhale() object.width, object.height = w, h; transition.to(object, i) end
  local function exhale() object.width, object.height = w, h; transition.to(object, e) end

  local function onCancel()
    object.width, object.height = w, h
    object._isBreath = nil
  end

  -- set transitions
  i = { time = time, width = w * intensity, height = h / intensity, transtion = easing.inOutExpo, onComplete = exhale, onCancel = onCancel }
  e = { time = time, width = w / intensity, height = h * intensity, transtion = easing.inOutExpo, onComplete = inhale, onCancel = onCancel }

  object._isBreath = true
  inhale()
end

-- Float fx function

function M.float(object, intensity, time, rnd)
  if not (object and object.contentBounds) then
    print("WARNING: Object not found")
    return false
  end

  intensity = intensity or 0.025
  time = time or 1000
  if rnd then time = time + math.random(rnd) end
  local x,y,i,e = object.x, object.y, {}, {}
  local function inhale() transition.to(object, i) end
  local function exhale() transition.to(object, e) end

  local function onCancel() object.x, object.y = x, y end

  -- set transitions
  i = { tag = "float", time = time, y = y + intensity * object.height, transtion = easing.outExpo, onComplete = exhale, onCancel = onCancel }
  e = { tag = "float", time = time, y = y - intensity * object.height, transtion = easing.outExpo, onComplete = inhale, onCancel = onCancel }

  inhale()
end

-- Sway

function M.sway(object, intensity, time, rnd)
  if not object.contentBounds then
    print("WARNING: Object not found")
    return false
  end

  intensity = intensity or 0.1
  time = time or 1000
  time = time + (rnd and math.random(rnd) or 0)
  local x1,y1 = object.path.x1, object.path.y1
  local x4,y4 = object.path.x4, object.path.y4
  local size = object.height
  local i,e = {}, {}
  local function inhale() transition.to(object.path, i) end
  local function exhale() transition.to(object.path, e) end

  -- set transitions
  i = { time = time, x1 = x1 + intensity * size , x4 = x4 + intensity * size, transtion = easing.inOutExpo, onComplete = exhale }
  e = { time = time, x1 = x1 - intensity * size , x4 = x4 - intensity * size, transtion = easing.inOutExpo, onComplete = inhale }

  inhale()
end

-- Shake object function

function M.shake(object, frames, intensity)
  if not object.contentBounds then
    print("WARNING: Object not found")
    return false
  end

  if object._shakeFrames then
    print("WARNING: Object already shaking")
    return false
  end

  -- add frames to count
  object._shakeFrames = math.min(180, (frames or 30) + (object._shakeFrames or 0))
  object._iX, object._iY = 0,0

  local function shake()
    if (object._shakeFrames > 0) and object.contentBounds then -- shake it
      intensity = intensity or 16
      if object._shakeFrames % 2 == 1 then
        object._iX = (math.random(intensity) - (intensity/2))*(object._shakeFrames/100)
        object._iY = (math.random(intensity) - (intensity/2))*(object._shakeFrames/100)
        object.x = object.x + object._iX
        object.y = object.y + object._iY
      else
        object.x = object.x - object._iX
        object.y = object.y - object._iY
      end
      object._shakeFrames = object._shakeFrames - 1
    else
      Runtime:removeEventListener("enterFrame", shake)
      object._shakeFrames = nil
    end
  end

  -- get shaking
  Runtime:addEventListener("enterFrame", shake)
end

-- Object Trails

function M.newTrail(object, options)
  if not object.contentBounds then
    print("WARNING: Object not found")
    return false
  end

  options = options or {}

  local image = options.image or "com/ponywolf/ponyfx/circle.png"

  local dw, dh = object.width, object.height
  local size = options.size or (dw > dh) and (dw * 0.9) or (dh * 0.9)
  local w, h = size, size

  local ox, oy = options.offsetX or 0, options.offsetY or 0
  local trans = options.transition or { time = 250, alpha = 0, delay = 50, xScale = 0.01, yScale = 0.01 }
  local delay = options.delay or 0
  local color = options.color or { 1.0 }
  local alpha = options.alpha or 0.5
  local blendMode = options.blendMode or "add"
  local frameSkip = options.frameSkip or 1
  local frame = 1

  local trail = display.newGroup()
  if options.parent then
    options.parent:insert(trail)
    trail:toBack()
  else
    if object.parent then object.parent:insert(trail) end
    trail:toBack()
  end
  trail.ox, trail.oy, trail.oz, trail.oa = object.x, object.y, (object.z or 0), object.rotation
  trail.alpha = alpha

  local function enterFrame()
    frame = frame + 1
    if offScreen(object) then return end

    -- object destroyed
    if not object.contentBounds then
      trail:finalize()
      return false
    end

    -- haven't moved
    if lenSqr(object.x - trail.ox, object.y - trail.oy, (object.z or 0) - trail.oz) < 1 * 1 then return false end
    trail.ox, trail.oy, trail.oz = object.x, object.y, (object.z or 0)

    if frame > frameSkip then
      frame = 1
    else
      return false
    end

    -- create trail
    local particle = display.newImageRect(trail, image, w, h)
    transition.from (particle, {alpha = 0, time = delay })

    -- color
    particle:setFillColor(unpack(color))
    particle.blendMode = blendMode

    -- place
    particle.x, particle.y = object.x + ox, object.y + oy - (object.z or 0)
    particle.rotation = object.rotation

    -- finalization
    trans.onComplete = function ()
      display.remove(particle)
      particle = nil
    end

    -- transition
    transition.to(particle, trans)
    --object:toFront()
  end

  Runtime:addEventListener("enterFrame", enterFrame)

  function trail:finalize()
    Runtime:removeEventListener( "enterFrame", enterFrame)
    local function onComplete()
      display.remove(self)
      trail = nil
    end
    transition.to(trail, {alpha = 0, onComplete = onComplete })
  end

  trail:addEventListener( "finalize" )
  return trail
end

function M.newFootprint(object, options)
  if not object.contentBounds then
    print("WARNING: Object not found")
    return false
  end

  options = options or {}

  local image = options.image or "gfx/footprints.png"
  options.parent = options.parent or object.parent

  local size = options.size or 14
  local w, h = size, size

  local ox, oy = options.offsetX or 0, options.offsetY or 0
  local trans = options.transition or { time = 250, alpha = 0, delay = 3000 }
  local delay = options.delay or 0
  local color = options.color or { 1.0 }
  local alpha = options.alpha or 0.33
  local blendMode = options.blendMode

  local trail = display.newGroup()
  if options.parent then
    options.parent:insert(trail)
    trail:toBack()
  else
    if object.parent then object.parent:insert(trail) end
    trail:toBack()
  end
  trail.ox, trail.oy, trail.oz, trail.oa = object.x, object.y, (object.z or 0), object.rotation
  trail.alpha = alpha

  local function enterFrame()
    if offScreen(object) then return end

    -- object destroyed
    if not object.contentBounds then
      trail:finalize()
      return false
    end

    -- haven't moved
    if lenSqr(object.x - trail.ox, object.y - trail.oy, (object.z or 0) - trail.oz) < size * size * 1.5 then return false end
    local rotation = math.deg(math.atan2(object.y - trail.oy, object.x - trail.ox))
    trail.ox, trail.oy, trail.oz = object.x, object.y, (object.z or 0)

    -- create trail
    local particle = display.newImageRect(trail, image, w, h)
    transition.from (particle, {alpha = 0, time = delay })

    -- color
    particle:setFillColor(unpack(color))
    particle.blendMode = blendMode

    -- place
    particle.x, particle.y = object.x + ox, object.y + oy - (object.z or 0)
    particle.rotation = rotation

    -- finalization
    trans.onComplete = function ()
      display.remove(particle)
      particle = nil
    end

    -- transition
    transition.to(particle, trans)
    --object:toFront()
  end

  Runtime:addEventListener("enterFrame", enterFrame)

  function trail:finalize()
    Runtime:removeEventListener( "enterFrame", enterFrame)
    local function onComplete()
      display.remove(self)
      trail = nil
    end
    transition.to(trail, {alpha = 0, onComplete = onComplete })
  end

  trail:addEventListener( "finalize" )
  return trail
end

-- lightning

function M.newBolt(x1, y1, x2, y2, options)
  options = options or {}
  x1, y1 = x1 or 0, y1 or 0
  x2, y2 = x2 or 0, y2 or 0
  local pixelsPerSeg = options.pixelsPerSeg or 8
  local dx, dy = x2 - x1, y2 - y1
  local dist = math.sqrt(dx*dx + dy*dy)
  local steps = math.round(dist/pixelsPerSeg)
  local parent = options.parent

  dx, dy = dx/steps, dy/steps

  -- line based
  local rx, ry = math.random(pixelsPerSeg) - pixelsPerSeg/2, math.random(pixelsPerSeg) - pixelsPerSeg / 2
  local bolt = parent and display.newLine(parent,x1,y1,x1+dx+rx,y1+dy+ry) or display.newLine(x1,y1,x1+dx+rx,y1+dy+ry)
  for i = 1, steps do
    rx, ry = math.random(pixelsPerSeg) - pixelsPerSeg/2, math.random(pixelsPerSeg) - pixelsPerSeg / 2
    rx, ry = math.floor(rx), math.floor(ry)
    bolt:append(x1 + dx*i + rx, y1 + dy*i + ry)
  end
  bolt:append(x2, y2)
  bolt.strokeWidth = 2 --+ math.random(1)
  local paint = {
    type = "image",
    filename = "com/ponywolf/ponyfx/bolt.png"
  }
  bolt.stroke = paint

  local remove = function() display.remove(bolt) end
  transition.to(bolt, {alpha = 0, time = 166, onComplete = remove} )
  return bolt
end

function M.newStrike(x, y, object, frames)
  if not object.contentBounds then
    print("WARNING: Object not found")
    return false
  end
  local instance = display.newGroup()
  local toX, toY = object:localToContent(0,0)

  -- add frames to count
  object._boltFrames = math.min(180, (frames or 30) + (object._shakeFrames or 0))

  local function strike()
    if object and (object._boltFrames > 0) and object.contentBounds then -- shake it
      if object._boltFrames % 2 == 1 then
        local bolt = M.newBolt(x, y, toX, toY)
      end
      object._boltFrames = object._boltFrames - 1
    else
      Runtime:removeEventListener("enterFrame", strike)
      display.remove(instance)
    end
  end
  -- get bolting
  Runtime:addEventListener("enterFrame", strike)
  return instance
end

-- Spinning streaks for menus and such

function M.newStreak(options)

  local streaks = display.newGroup()

  options = options or {}

  local image = options.image or "com/ponywolf/ponyfx/streaksPixel.png"

  local dw, dh = display.actualContentWidth, display.actualContentHeight
  local length = options.length or (dw > dh) and (dw * 0.666) or (dh * 0.666)
  local count = options.count or 18
  local speed = options.speed or 0.333
  local ratio = options.ratio or 2.666
  local color = options.color or { 1.0 }

  for i=1, math.floor(360 / count) do
    local streak = display.newImageRect(image, length, length / count * ratio)
    streak.anchorX = 0
    streak.x, streak.y = 0,0
    streak.rotation = i * count
    streak:setFillColor(unpack(color))
    streaks:insert(streak)
  end

  local function spin()
    streaks:rotate(speed)
  end

  function streaks:start()
    Runtime:addEventListener("enterFrame", spin)
  end

  function streaks:stop()
    Runtime:removeEventListener("enterFrame", spin)
  end

  function streaks:finalize()
    self:stop()
  end

  streaks:addEventListener("finalize")
  streaks:start()
  return streaks
end

function M.comic(text, x, y)
  local stroke = require "com.ponywolf.ponystroke"
  local default = {
    text = text or "Critical Hit!",
    x = x or display.contentCenterX,
    y = y or 192,
    --width = display.contentWidth * 0.8,
    font = "Bangers-Regular.ttf",
    fontSize = 99,
    align = "center",
    color = {0.9,0.4,0.35,1},
    strokeColor = {1,1,1,1},
    strokeWidth = 2
  }
  local comicText = stroke.newText(default)
  comicText.rotation = math.random(12) - 6
  comicText.xScale, comicText.yScale = 3.0, 3.0

  local function remove()
    display.remove(comicText.raw)
    comicText = nil
  end

  transition.to(comicText, {
      xScale = 0.75, yScale = 0.75,
      transition=easing.outElastic,
      time=750,
    })

  transition.to(comicText, {
      alpha = 0,
      delay= 750,
      time=333,
      onComplete = remove,
    })

  return comicText.raw
end

function M.extrudedTileset(w,h,cols,rows,margin,spacing)
  if not w or not h then
    print("WARNING: Need tile w,h plus rows and columns")
  end

  margin, spacing = margin or 0, spacing or 0

  local options = {
    frames = {},
  }

  local frames = options.frames

  for j=1, cols do
    for i=1, rows do
      local element = {
        x = (i-1)*(w + spacing) + margin,
        y = (j-1)*(h + spacing) + margin,
        width = w,
        height = h,
      }
      frames[#frames+1] = element
    end
  end

  return options
end


return M
