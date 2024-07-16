# Tile Painter

Want to make your base look pretty?

The mod adds a tool to select an area to fill with a tile blueprint or even select specific tiles to go under an entity.

Click the shortcut button or press `Alt + P` to get the Tile Painter. 
Use `Shift + Scroll` to cycle between tools.

## Tools

### Entity

Configure the settings in the GUI window to select which tiles you want to place around specific entities.

![Entity GUI](https://github.com/Caleb-Wishart/tile-painter/raw/master/resources/entity-gui.png)

Hold `Left-click` and Drag to select an entities to paint tiles according to your configuration.
Hold `Shift + Left-click` to remove the selected tiles from the entities.

Tiles can be set for under the entity, 1 tile away, or 2 tiles away.m

The `Anything` option will apply those settings to ALL entities that do not have a specific configuration.
In **Blacklist** mode, the settings will apply to all entities except those listed.

You can have up to 10 different presets and export / import settings across saves.

![Entity GUI Example](https://github.com/Caleb-Wishart/tile-painter/raw/master/resources/entity-gui-rail-example.png)

The above image shows an example of the Entity tool being used to paint rails with stone directly underneath and 1 tile away from the rails.
Hazard concrete is also placed 2 tile away from the rails and directly under ANY non-rail entity.

Selecting an intersection with this configuration will result in the following:

![Entity GUI Example After](https://github.com/Caleb-Wishart/tile-painter/raw/master/resources/entity-gui-rail-example-after.png)

Use `Ctrl + Shift + Scroll` to cycle between presets.

![Entity Assembler Example](https://github.com/Caleb-Wishart/tile-painter/raw/master/resources/entity-example-assembler.mp4)

### Shape

Configure the settings in the GUI window to select which shape you want to place.

![Shape GUI](https://github.com/Caleb-Wishart/tile-painter/raw/master/resources/shape-gui.png)

Each shape can only be made out of a single Tile.

The available shapes are:

- Circle
- Line
- Triangle
- Square
- Pentagon
- Hexagon
- Heptagon
- Octagon
- Nonagon

Select the center of the shape with `Right-click` and an outer vertex with `Left-click`.
The points will snap to the center of the tile selected unless `Shift` is held.

The Angle and Radius (Distance from Center to Vertex) can be adjusted in the GUI.
The angle can also be represented in degrees or radians or as a compass bearing.

![Shape GUI Example - Before](https://github.com/Caleb-Wishart/tile-painter/raw/master/resources/shape-gui-before.png)

After setting the tile to "Stone Path" and pressing **Confirm** the above configuration will result in the following:

![Shape GUI Example - After](https://github.com/Caleb-Wishart/tile-painter/raw/master/resources/shape-gui-after.png)

Shapes can either be filled or outlined.
s
Use `Ctrl + Shift + Scroll` to cycle between polygons.

![Shape Example](https://github.com/Caleb-Wishart/tile-painter/raw/master/resources/shape-example.mp4)


-----

## Recommendations

- Remove `Shift + Scroll` zoom keybinds in _Controls_ settings to stop it interfering with tool cycling

## Warnings

- Selecting a large area with the Entity tool can cause a noticeable lag spike, especially rails or any entities that don't have a simple square bounding box.
- Confirming a large area with the Shape tool can cause a lag spike due to the large number of tiles that have to be scanned.
- Adding or removing tiles in this way does NOT go in the tiles undo/redo stack.
