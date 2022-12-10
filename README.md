# ponytiled
*ponytiled* is a simple Tiled Map Loader for Solar2D (formerly Corona SDK)

![Screenshot of ponytiled in action](http://i.imgur.com/HJQJTiw.png)

In about 675 lines of code, **ponytiled** loads a sub-set of Tiled layers, tilesets and image collections. Built in plugin hooks and extensions make it easy to add support for many custom object types.

- [x] Loads .LUA + .JSON exports from www.mapeditor.org
- [x] Adds basic properties from Tiled including physics
- [x] Supports object layers and tile layers
- [x] Supports collections of images and tileset images
- [x] Supports object x/y flipping and re-centering of anchorX/anchorY for Solar2D
- [x] Particle plugin
- [x] Rectangle shape with fillColor and strokeColor support
- [x] Polygon import with physics support for edge chains
- [x] Support for tilesheet based external tilesets (TSX files)
- [x] Basic support for collection of images external tilesets (TSX files)
- [x] Basic UI plugins for dragables, buttons and labels
- [x] Particle plugin support for JSON particles http://particle2dx.com/
- [x] Basic animated tiles

### Quick Start Guide

```
tiled = require "com.ponywolf.ponytiled"
map = tiled.new( data, dir )
```

#### data

Data is a lua table that contains an export of the Tiled map in either .lua or .json format. The easiest way to populate that table is to export a map from Tiled in .lua format and *require* it in your code.

![Lua export via Tiled](http://imgur.com/NJZuTM8.png)

```
local mapData = require "sandbox" -- load from lua export
local map = tiled.new(mapData)
```

#### dir

Most of the time you will store you maps and images/tilesets in a directory. The dir parameter overides where **ponytiled** looks for images.

```
local mapData = require "maps.objects.sandbox" -- load from lua export
local map = tiled.new(mapData, "maps/objects") -- look for images in /maps/objects/
```

#### map

**ponytiled** returns a map display object that contains all the layers, objects and tiles for the exported map. (0,0) is the *designed* upper left hand corner of the map. Objects may be above or to the left of the origin or beyond the designed width and height.

map display objects have all the same properties of a normal display group.

```
map.xScale = 2
map.alpha = 0.5
map:translate(-30,30)
```
map.designedWidth and map.designedHeight are the width and height of you map as specified in Tiled's new map options. map objects also have functions to make it easy to find image objects to manipulate them with code.

#### map:findObject(name)
This funtion will return the *first* display object with the name specified. Great for getting to the display object of a unique item in the map.

![Setting a hero name](http://imgur.com/qLJayzG.png)

```
myHero = map:findObject("hero")
myHero:toFront()
myHero:rotate(45)
```
#### map:listTypes(types)
To find multiple objects, use map:listTypes(). This will return a table of display objects matching the type specified.
![Setting a "coin" type](http://imgur.com/iR3DdDY.png)

```
myCoins = map:listTypes( "coin" )
print("Number of coins in map", #myCoins)
display.remove(myCoins[1])
```
#### map:findLayer(name)
To find a layer (which itself is a nested display group), use map:findLayer(). 
```
myLayer = map:findLayer( "hud" )
myLayer.alpha = 0.5
```
#### map:getFirstTile( property [, value ] )
This funtion will return the *first* tile-based display object with the specified property in the map. Great for getting to the display object of a unique tile in the map. Optionally, you can specify a value for the property. If the value is omitted, the function will return the first tile that has the specified property regardless of the value of the property.
``` 
finishTile = map:getFirstTile( "type", "finish" )
transition.blink( finishTile, { time=1000 } )
```
#### map:getAllTiles( property [, value ] )
Same functionality as with `map:getFirstTile( property [, value ] )` (see above), but this function will return a list of all tile-based display objects in the map with the specified property.
```
enemies = map:getAllTiles( "isEnemy" )
for i = 1, #enemies do
  print( "enemy #" .. i .. " = " .. tostring( enemies[i] ) )
end
```




### Extensions

#### map:extend(types)
The *extend()* function attaches a lua code module to a *image object*. You can use this to build custom classes in your game.

*There are code examples of this in the "com/ponywolf/plugins" folder.*

### Custom Properties

The most exciting part of working in Tiled & Solar2D is the idea of custom properites. You can select any *image object* or *tile object* on any *object layer* or *tile layer* in Tiled and add any number of custom properties. **ponytiled** will apply those properties to the image object as it loads. This allows you to put physics properties, custom draw modes, user data, etc. on an in-game item via the editor.

![Setting a bodyType object](http://imgur.com/u3Ee6dD.png)

#### bodyType

One special custom property is *bodyType*. This triggers **ponytiled** to add a physics body to an object and pass the rest of the custom properties as physics options. Rectangle bodies are currently supported by default, adding a **radius** property will give you a round body.

### Watchouts

* Only the most basic support for TSX files (also known as external tilesets)
* Ellipse types are rendered as circles
* Only supports XML or CSV layer data types (see below)

![Setting up a CSV layer type](https://i.imgur.com/w2SImSf.png)

