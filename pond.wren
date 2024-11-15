import "xs" for Data
import "xs_containers" for Grid 
import "xs_math" for Math, Vec2, Bits
import "xs_tools" for Tools

class Pond {
    static canExpand(expansion_chance) { Tools.random.int(0, 100) <= expansion_chance }

    /*
        Creates pond around origin point. Minimum (starting) size is 3x3.
        Pond will add a maximum of 'expansion_tiles' to its starting size.
        Chance for a tile to add additional tiles is based on 'expansion_chance'.
        Chance decreases by 'chance_dropoff' after a tile is placed.
        Pond is complete when all tiles are placed or 'expansion_chance' drops to 0.

        After placement the edges are autotiled (correct tile is selected to make border).
        The inner parts of the pond are colored darker to represent deep water.
    */
    static build(origin, grid, pond_aabb) {
        var frontier = []
        var new_frontier = []
        var all_pond_tiles = []
        var pond_map = Grid.new(grid.width, grid.height, LevelTile.new())

        var expansion_chance = Data.getNumber("Pond Grow Chance")
        var chance_dropoff = Data.getNumber("Pond Grow Dropoff")
        var expansion_tiles = Data.getNumber("Pond Grow Tiles")
        
        var surroundings = Directions.cardinal() + Directions.ordinal()

        // Initial pond setup.
        for (dir in surroundings) {
            var cell = origin + dir
            pond_map[cell.x, cell.y] = LevelTile.new(OType.pond, Layer.overworld)
            frontier.add(cell)
            all_pond_tiles.add(cell)
        }        
        
        // Expand pond while there is a chance and available tiles.
        while (frontier.count > 0) {
            while (frontier.count > 0) {
                // Get random element to evaluate.
                var cell = frontier.removeAt(Tools.random.int(0, frontier.count - 1))
                
                // Check for any non-water tile and possibly make it new expansion tile.
                for (dir in Directions.cardinal()) {
                    var other_cell = cell + dir
                    
                    if (pond_map.valid(other_cell.x, other_cell.y)) { 
                        if (pond_map[other_cell.x, other_cell.y].type != OType.pond) {
                            
                            if (Tools.random.int(0, 100) <= expansion_chance && expansion_tiles > 0) {
                                new_frontier.add(other_cell)
                                pond_map[other_cell.x, other_cell.y] = LevelTile.new(OType.pond, Layer.overworld)
                                
                                expansion_chance = expansion_chance - chance_dropoff
                                expansion_tiles = expansion_tiles - 1
                            }
                        }
                    }
                } // End expansion checks around current cell.
            }// End inner while loop - all frontier tiles have been checked.

            // Store new frontier.
            for (cell in new_frontier) {
                frontier.add(cell)
                all_pond_tiles.add(cell)
            }
            new_frontier.clear()
        } // End outer while loop - frontier is empty after resetting values.       
        
        // Force expansion around generated edges. Smooths border.
        new_frontier.clear()
        for (cell in all_pond_tiles) {
            for (dir in surroundings) {
                var other_cell = cell + dir

                if (pond_map.valid(other_cell.x, other_cell.y)) {
                    if (pond_map[other_cell.x, other_cell.y].type == 0) {
                        new_frontier.add(other_cell)
                        pond_map[other_cell.x, other_cell.y] = LevelTile.new(OType.pond, Layer.overworld)
                    }
                }
            }
        }
        all_pond_tiles = all_pond_tiles + new_frontier

        // Apply autotiling (make edges of pond make sense graphically)
        var up      = 1 << 0
        var right   = 1 << 1
        var down    = 1 << 2
        var left    = 1 << 3

        for (cell in all_pond_tiles) {
            var neighbors = 0

            // Check 4 directions.
            for (i in 0...4) {
                var other_cell = cell + Directions[i]
                var other_type = pond_map[other_cell.x, other_cell.y].type

                if (Bits.checkBitFlagOverlap(other_type, OType.water)) {
                    neighbors = (neighbors | ( 1 << i))
                }
            }
            
            // Replace tile info based on neighbors.
            var tile = LevelTile.new(OType.pond, Layer.overworld)
            
            if (neighbors == (right | down))        { tile = LevelTile.new(OType.pond_corner, Layer.overworld, Math.radians(0.0))     }
            if (neighbors == (up | right))          { tile = LevelTile.new(OType.pond_corner, Layer.overworld, Math.radians(90.0))    }
            if (neighbors == (up | left))           { tile = LevelTile.new(OType.pond_corner, Layer.overworld, Math.radians(180.0))   }
            if (neighbors == (left | down))         { tile = LevelTile.new(OType.pond_corner, Layer.overworld, Math.radians(270.0))   }

            if (neighbors == (up | right | down))   { tile = LevelTile.new(OType.pond_side, Layer.overworld, Math.radians(0.0))       }
            if (neighbors == (left | up | right))   { tile = LevelTile.new(OType.pond_side, Layer.overworld, Math.radians(90.0))      }
            if (neighbors == (down | left | up))    { tile = LevelTile.new(OType.pond_side, Layer.overworld, Math.radians(180.0))     }
            if (neighbors == (right | down | left)) { tile = LevelTile.new(OType.pond_side, Layer.overworld, Math.radians(270.0))     }
            
            pond_map[cell.x, cell.y] = tile
        }

        // Set deep pond tiles (pond tile that is surrounded by only pond tiles)
        new_frontier.clear()
        for (cell in all_pond_tiles) {
            var neighbors = 0

            // Check directions for pond tile. Only deep if not touching the border of the pond.
            for (i in 0...4) {
                var other_cell = cell + Directions[i]
                if (pond_map[other_cell.x, other_cell.y].type == OType.pond) neighbors = neighbors + 1
            }

            if (neighbors == 4) {
                new_frontier.add(cell)
            }
        }

        for (cell in new_frontier) {
            pond_map[cell.x, cell.y] = LevelTile.new(OType.pond_deep, Layer.overworld)
        }

        // Apply pond to grid. Also get the aabb of the pond.
        var min_x = Num.largest
        var max_x = Num.smallest
        var min_y = Num.largest
        var max_y = Num.smallest

        for (cell in all_pond_tiles) {
            if (cell.x < min_x) min_x = cell.x
            if (cell.x > max_x) max_x = cell.x
            if (cell.y < min_y) min_y = cell.y
            if (cell.y > max_y) max_y = cell.y

            grid[cell.x, cell.y] = pond_map[cell.x, cell.y]
        }

        pond_aabb.add(Vec2.new(min_x, min_y))
        pond_aabb.add(Vec2.new(max_x, max_y))
    }
}

import "types" for OType, Layer
import "directions" for Directions
import "components" for LevelTile