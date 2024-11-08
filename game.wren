// Import the necessary modules
import "xs" for Render, Input, Data // The engine-level xs API
import "xs_math" for Math, Color    // Math and Color functionality
import "xs_tools" for ShapeBuilder  
import "xs_containers" for Grid     // Grid is a 
import "background" for Background  // Wobbly background - local module
import "random" for Random          // Random number generator - system module

// Just some names for the different things that can be on the grid
class Type {
    static empty       { 0 << 0 }   // This is actually a function that returns 0
    static tree_one    { 1 << 0 }   // Static means that the function is a class function
    static tree_two    { 1 << 1 }   // The << operator is a bit shift operator
    static tree_three  { 1 << 2 }   // The value of each type is a power of 2
    static grass_one   { 1 << 3 }   // This is so that they can be combined into a single value
    static grass_two   { 1 << 4 }   // This is useful for collision detection
    static grass_three { 1 << 5 }   // For example, a player can be on a tree and grass
    static road        { 1 << 6 }   // but not on two trees at the same time
    static player      { 1 << 7 }   // The player is a special type of tile
    
    static pond         { 1 <<  8 }
    static pond_deep    { 1 <<  9 }
    static pond_side    { 1 << 10 }
    static pond_corner  { 1 << 11 } 

    static ground       { 1 << 12 }
    static obstacle     { 1 << 13 }

    static bridge     { 1 << 14 }
}

class Point {
    construct new() {
        _x = 0.0
        _y = 0.0
    }

    construct new(newX, newY) {
        _x = newX
        _y = newY
    }

    x {_x}
    x=(value) {_x = value}

    y {_y}
    y=(value) {_y = value}    
}

class Tile {
    construct new() {
        _tile_id = Type.empty
        _rotation = 0.0
        _layer = 0
    }

    construct new(tile_id, rotation, layer) {
        _tile_id = tile_id
        _rotation = rotation
        _layer = layer
    }

    tile_id { _tile_id }
    tile_id=(value) { _tile_id = value }

    rotation { _rotation }
    rotation=(value) { _rotation = value }

    layer { _layer }
    layer=(value) { _layer = value }
}

class Player { // Player State
    static walking  { 1 }
    static casting  { 2 }
    static fishing  { 3 }

    construct new(position) {
        _position = position
        _state = Player.walking
        _cast_target = Point.new()
    }

    state {_state}
    state=(value) {_state = value}

    position {_position}
    position=(value) {_position = value}

    cast_target {_cast_target}
    cast_target=(value) {_cast_target = value}
}

class Game {
    static toRadians(degree) {
        return (degree * __PI / 180.0)
    }
    static pickOne(list) {
        return list[__random.int(0, list.count)]    
    }

    static checkBit(value, bit) {
        return (value & bit) != 0
    }

    static canExpand(expansion_chance) { __random.int(0, 100) <= expansion_chance }

    static buildPond() {
        var frontier = []
        var new_frontier = []
        var all_pond_tiles = []
        var expansion_chance = Data.getNumber("Pond Expansion Chance")
        var available_pond_tiles = Data.getNumber("Pond Expansion Tiles")

        var origin = Point.new(__width / 2, __height / 2)
        var pond_map = Grid.new(__width, __height, Tile.new())
        
        // Initial pond setup.
        for (y in -1..1) {
            for (x in -1..1) {
                var loci = Point.new(x + origin.x, y + origin.y)
                pond_map[loci.x, loci.y] = Tile.new(Type.pond, 0.0, Type.pond)
                frontier.add(loci)
                all_pond_tiles.add(loci)
            }
        }
        
        // Expand pond while there is a chance and available tiles.
        while (frontier.count > 0) {
            while (frontier.count > 0) {
                // Get random element to evaluate.
                var loci = frontier.removeAt(__random.int(0, frontier.count - 1))
                
                // Check for any non-water tile and possibly make it new expansion tile.
                for (y in -1..1) {
                    for (x in -1..1) {
                        if (x != 0 && y != 0) continue

                        var other_loci = Point.new(loci.x + x, loci.y + y)
                        
                        if (!pond_map.valid(other_loci.x, other_loci.y)) continue

                        if (pond_map[other_loci.x, other_loci.y].layer != Type.pond) {
                            // Try to add new pond tile.
                            if (canExpand(expansion_chance) && available_pond_tiles > 0) {
                                new_frontier.add(other_loci)
                                pond_map[other_loci.x, other_loci.y] = Tile.new(Type.pond, 0.0, Type.pond)
                                
                                expansion_chance = expansion_chance - 5
                                available_pond_tiles = available_pond_tiles - 1
                            }
                        }
                    }                
                } // End expansion checks around current loci.
            }

            // Store new frontier.
            for (loci in new_frontier) {
                frontier.add(loci)
                all_pond_tiles.add(loci)
            }
            new_frontier.clear()
        } // End while loop - frontier is empty        
        
        // Force expansion around generated edges. Smooths border.
        new_frontier.clear()
        for (loci in all_pond_tiles) {
            for (y in -1..1) {
                for (x in -1..1) {
                    var other_loci = Point.new(loci.x + x, loci.y + y)

                    if (!pond_map.valid(other_loci.x, other_loci.y)) continue

                    if (pond_map[other_loci.x, other_loci.y].tile_id == Type.empty) {
                        new_frontier.add(other_loci)
                        pond_map[other_loci.x, other_loci.y] = Tile.new(Type.pond, 0.0, Type.pond)
                    }
                }
            }
        }
        all_pond_tiles = all_pond_tiles + new_frontier

        // Apply autotiling (make edges of pond make sense graphically)
        var left        = 1 << 0
        var right       = 1 << 1
        var up          = 1 << 2
        var down        = 1 << 3

        for (loci in all_pond_tiles) {
            var neighbors = 0

            // Check 4 directions.
            if (pond_map[loci.x - 1, loci.y    ].layer == Type.pond) { neighbors = neighbors + left}
            if (pond_map[loci.x + 1, loci.y    ].layer == Type.pond) { neighbors = neighbors + right}
            if (pond_map[loci.x    , loci.y + 1].layer == Type.pond) { neighbors = neighbors + up}
            if (pond_map[loci.x    , loci.y - 1].layer == Type.pond) { neighbors = neighbors + down}
            
            // Replace tile info based on neighbors.
            var tile = Tile.new(Type.pond, 0.0, Type.pond)

            if (neighbors == (right + down))    { tile = Tile.new(Type.pond_corner, toRadians(0.0), Type.pond) }
            if (neighbors == (right + up))      { tile = Tile.new(Type.pond_corner, toRadians(90.0), Type.pond) }
            if (neighbors == (left + up))       { tile = Tile.new(Type.pond_corner, toRadians(180.0), Type.pond) }
            if (neighbors == (left + down))     { tile = Tile.new(Type.pond_corner, toRadians(270.0), Type.pond) }

            if (neighbors == (up + right + down))   { tile = Tile.new(Type.pond_side, toRadians(0.0), Type.pond) }
            if (neighbors == (left + up + right))   { tile = Tile.new(Type.pond_side, toRadians(90.0), Type.pond) }
            if (neighbors == (down + left + up))    { tile = Tile.new(Type.pond_side, toRadians(180.0), Type.pond) }
            if (neighbors == (right + down + left)) { tile = Tile.new(Type.pond_side, toRadians(270.0), Type.pond) }
            
            pond_map[loci.x, loci.y] = tile
        }

        // Set deep pond tiles (pond tile that is surrounded by only pond tiles)
        new_frontier.clear()
        for (loci in all_pond_tiles) {
            var neighbors = 0

            // Check directions for pond tile.
            if (pond_map[loci.x - 1, loci.y    ].tile_id == Type.pond) { neighbors = neighbors + 1}
            if (pond_map[loci.x + 1, loci.y    ].tile_id == Type.pond) { neighbors = neighbors + 1}
            if (pond_map[loci.x    , loci.y + 1].tile_id == Type.pond) { neighbors = neighbors + 1}
            if (pond_map[loci.x    , loci.y - 1].tile_id == Type.pond) { neighbors = neighbors + 1}

            if (neighbors == 4) {
                new_frontier.add(loci)
            }
        }

        for (loci in new_frontier) {
            pond_map[loci.x, loci.y].tile_id = Type.pond_deep
        }

        // Apply pond to grid.
        for (loci in all_pond_tiles) __grid[loci.x, loci.y] = pond_map[loci.x, loci.y]        
    }

    static initialize() {
        __PI = 22.0 / 7.0
        __random = Random.new() // Create a new random number generator
        __width = Data.getNumber("Level Width", Data.game)  // Get the width of the level from the game.json data file.
        __height = Data.getNumber("Level Height", Data.game) // All Data variables are visible from the UI
        __background = Background.new() // All variables that start with __ are static variables
        __font = Render.loadFont("[game]/assets/monogram.ttf", 16)
        __tileSize = 16
        var r = 49
        var c = 22
        var image = Render.loadImage("[game]/assets/monochrome-transparent_packed.png") // Load the image in a local variable
        __tiles = {            
            Type.empty: Render.createGridSprite(image, r, c, 624),
            Type.tree_one: Render.createGridSprite(image, r, c, 51),
            Type.tree_two: Render.createGridSprite(image, r, c, 52),
            Type.tree_three: Render.createGridSprite(image, r, c, 53),
            Type.grass_one: Render.createGridSprite(image, r, c, 5),
            Type.grass_two: Render.createGridSprite(image, r, c, 1),
            Type.grass_three: Render.createGridSprite(image, r, c, 6),
            Type.road: Render.createGridSprite(image, r, c, 3),
            Type.player: Render.createGridSprite(image, r, c, 76),

            Type.pond: Render.createGridSprite(image, r, c, 253),
            Type.pond_deep: Render.createGridSprite(image, r, c, 253),
            Type.pond_side: Render.createGridSprite(image, r, c, 254),
            Type.pond_corner: Render.createGridSprite(image, r, c, 255),

            Type.bridge: Render.createGridSprite(image, r, c, 252),
        }        
        
        var green = Data.getColor("Grass Color")
        var alsoGreen = Data.getColor("Tree Color")
        var blue = Data.getColor("Shallow Water Color")
        var deep_blue = Data.getColor("Deep Water Color")
        var brown = Data.getColor("Bridge Color")
        __colors = {
            Type.empty: 0xFFFFFFFF,
            Type.road: 0xFFFFFFFF,
            Type.player: 0xFFFFFFFF,            
            Type.grass_one: green,
            Type.grass_two: green,
            Type.grass_three: green,
            Type.tree_one: alsoGreen,
            Type.tree_two: alsoGreen,
            Type.tree_three: alsoGreen,

            Type.pond: blue,
            Type.pond_deep: deep_blue,
            Type.pond_side: blue,
            Type.pond_corner: blue,

            Type.bridge: brown,
        }

        // Initialize the level grid and the player        
        __grid = Grid.new(__width, __height, Tile.new()) // Create a new grid with the width and height
        
        // Fill the grid with grass
        for(i in 0...__width) {
            for(j in 0...__height) {
                var grass = Game.pickOne([Type.grass_one, Type.grass_one, Type.grass_two, Type.grass_three])
                __grid[i, j] = Tile.new(grass, 0.0, Type.ground)
            }
        }

        // Add some trees
        for(i in 0...__width) {
            for(j in 0...__height) {
                if (__random.int(0, 100) < 30) {
                    var tree = Game.pickOne([Type.tree_one, Type.tree_two, Type.tree_three])
                    __grid[i, j] = Tile.new(tree, 0.0, Type.obstacle)
                }
            }
        }

        // Add water.
        buildPond()

        // Add a road in the middle that also goes up and down a bit
        var can_change = 0
        var j = __height / 2
        for(i in 0...__width) {
            // Check if placing on ground or pond.
            if (checkBit(__grid[i, j].layer, Type.pond)) {
                __grid[i, j] = Tile.new(Type.bridge, 0.0, Type.ground)
            } else {
                can_change = can_change + 1

                __grid[i, j] = Tile.new(Type.road, 0.0, Type.ground)
                
                if (can_change > 2 && __random.int(0, 100) < 80) {
                    j = j + __random.int(-1, 2)
                    can_change = 0
                }
                
                if (j < 0) {
                    j = 0
                }
                
                if (j >= __height) {
                    j = __height - 1
                }
                
                __grid[i, j] = Tile.new(Type.road, 0.0, Type.ground)
            }
        }

        // Add the player
        __player = Player.new(Point.new(0, __height / 2))
    }

    static update(dt) {
        __background.update(dt)

        if (__player.state == Player.walking) {
            movePlayer()
        }

        if (__player.state == Player.casting) {
            System.print("State: %(__player.state)")
            movePlayer()
        }
    }

   
    static movePlayer() {        
        if (Input.getKeyOnce(Input.keySpace)) {
            __player.state = Player.casting
            __player.cast_target = Point.new(__player.position.x, __player.position.y - 1)
            return
        }
        
        var dx = 0
        var dy = 0

        // In wren new line have a meaning so you can put the if statement in one line
        // without the need of curly braces. Otherwise you need to use curly braces
        if (Input.getKeyOnce(Input.keyA)) dx = -1    
        if (Input.getKeyOnce(Input.keyD)) dx = 1
        if (Input.getKeyOnce(Input.keyS)) dy = -1
        if (Input.getKeyOnce(Input.keyW)) dy = 1
        
        if (dx != 0 || dy != 0) {
            var nx = __player.position.x + dx
            var ny = __player.position.y + dy
            if (__grid.valid(nx, ny)) { // Check if in bounds (This is the full way of writing the if statement)
                if (__grid[nx, ny].layer == Type.ground) {
                    __player.position.x = nx
                    __player.position.y = ny
                }
            }
        }
    }


    static render() {
        // Render the purple(ish) background
        __background.render()   
        var s = __tileSize  

        // Calculate the starting x and y positions
        var sx = (__width - 1) * -s / 2   
        var sy = (__height - 1)  * -s / 2        

        // Go over all the tiles in the grid
        for (x in 0...__width) {
            for (y in 0...__height) {                
                if(x == __player.position.x && y == __player.position.y) {
                    // Render the player
                    var tile = __tiles[Type.player]
                    Render.sprite(                      // direct call to the Render function
                        tile,                           // sprite
                        sx + x * s,                     // x position
                        sy + y * s,                     // y position
                        0.0,                            // z position (depth sorting)
                        1.0,                            // scale 
                        0.0,                            // rotation
                        Data.getColor("Player Color"),  // multiply color
                        0x0,                            // add color
                        Render.spriteCenter)            // sprite flags
                } else {
                    // Render the tile at the current position
                    var px = sx + x * s
                    var py = sy + y * s
                    var tile_data = __grid[x, y]
                    var tile_image = __tiles[tile_data.tile_id]
                    var color = __colors[tile_data.tile_id]
                    Render.sprite(
                        tile_image, px, py,
                        0.0, 1.0, tile_data.rotation,
                        color, 0x0,
                        Render.spriteCenter)
                }                
            }
        }

        // Render cast icon.
        if (__player.state == Player.casting) {
            var color = 0xFF0000FF

            var target = __player.cast_target
            if (__grid[target.x, target.y].layer == Type.pond) color = 0x00FF00FF

            var tile = __tiles[Type.road]
            Render.sprite(                      // direct call to the Render function
                tile,                           // sprite
                sx + target.x * s,                     // x position
                sy + target.y * s,                     // y position
                0.0,                            // z position (depth sorting)
                1.0,                            // scale 
                0.0,                            // rotation
                Data.getColor("Player Color"),  // multiply color
                0x0,                            // add color
                Render.spriteCenter)            // sprite flags
        }

        Render.text(
            __font,                 // font
            "use WASD to move",     // text
            0.0,                    // x
            -160,                   // y
            0.0,                    // z
            0xFFFFFFFF,             // multiply color
            0x0,                    // add color
            Render.spriteCenter)    // flags
    }
}