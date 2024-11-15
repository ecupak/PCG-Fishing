import "xs_math" for Vec2, Bits
import "xs_tools" for Tools
import "components" for Level, LevelTile

class Overworld is Level {
    construct new(width, height) {
        super(width, height)
    }

    build() {
        reset()

        // Add terrain.
        addGrass()
        addTrees()

        var pond_aabb = []
        addPond(pond_aabb)

        var forks = []                
        addPath(forks)
        var start_pos = addBuildings(forks, pond_aabb)

        addGrave()

        addFlowers()
        addRocks(OType.ruby_rock)
        addRocks(OType.amethyst_rock)
        addRocks(OType.peridot_rock)                

        // Return hero starting tile.
        return start_pos
    }

    addGrass() {
        for(i in 0...width) {
            for(j in 0...height) {
                var grass = Tools.pickOne([OType.grass_a, OType.grass_a, OType.grass_b, OType.grass_c])
                this[i, j] = LevelTile.new(grass, Layer.overworld)
            }
        }
    }

    addTrees() {
        for(i in 0...width) {
            for(j in 0...height) {
                if (Tools.random.int(0, 100) < 30) {
                    var tree = Tools.pickOne([OType.tree_a, OType.tree_b, OType.tree_c])
                    this[i, j] = LevelTile.new(tree, Layer.overworld)
                }
            } 
        }
    }

    addFlowers() {
        var amount = Tools.random.int(2, 6)
        for (i in 0...amount) {
            var pos = getRandomGrassyPointOnMap(1)
        
            var flower = Tools.pickOne([SType.i_rose, SType.i_marigold, SType.i_iris])
            Create.item(pos.x, pos.y, flower, 1)
        }
    }

    addGrave() {
        if (!(Tools.random.int(100) < 5)) return

        var pos_a = getRandomGrassyPointOnMap(1)
        
        while (!Gameplay.checkTile(pos_a + Directions[2], OType.grasses, Layer.overworld)) {
            pos_a = getRandomGrassyPointOnMap(1)
        }

        this[pos_a] = LevelTile.new(OType.grave_marker, Layer.overworld)
        this[pos_a + Directions[2]] = LevelTile.new(OType.grave_soil, Layer.overworld)        
    }

    addRocks(rock_type) {
        // Make 1 to 3 stones.
        var amount = Tools.random.int(1, 4)
        for (i in 0...amount) {
            var pos = getRandomGrassyPointOnMap(2)        
            this[pos] = LevelTile.new(rock_type, Layer.overworld)
        }
    }

    addPond(pond_aabb) {
        var origin = Vec2.new(width / 2, height / 2)
        Pond.build(origin, this.grid, pond_aabb)
    }

    addPath(forks) {
        // Add a road in the middle that also goes up and down a bit
        var can_change = 0
        var j = height / 2
        for(i in 0...width) {
            var did_change = false
            
            // Check if placing on ground or pond.
            if (Bits.checkBitFlagOverlap(this[i, j].type, OType.water)) {
                this[i, j] = LevelTile.new(OType.bridge, Layer.overworld)
            } else {
                // Only allow path changes periodically (and not over water).
                can_change = can_change + 1

                this[i, j] = LevelTile.new(OType.road, Layer.overworld)

                // If path tries to change, determine if the new cell is different.
                if (can_change > 2 && Tools.random.int(0, 100) < 80) {
                    var new_j = j + Tools.random.int(-1, 2)
                    can_change = 0

                    // Make sure new cell is within map bounds.
                    if (contains(i, new_j)) {
                        did_change = (new_j != j)
                        j = new_j
                    }
                }

                // Store random points for later use.
                if (!did_change && Tools.random.int(100) < 30) forks.add(Vec2.new(i, j))
                
                // If path changed, add connecting road to avoid disjointed path.
                if (did_change) {
                    var path_type = (Bits.checkBitFlagOverlap(this[i, j].type, OType.water) ? OType.bridge : OType.road)
                    this[i, j] = LevelTile.new(path_type, Layer.overworld)
                }
            }
        }
    }

    addBuildings(forks, pond_aabb) {
        forks.sort {|a, b| Tools.random.int(0, 100) < 50}

        var pos = null
        var start_pos = null

        for (fork in forks) {
            // Make sure not aligned with pond or too close to edges.
            if ((fork.x + 2 < pond_aabb[0].x || fork.x - 2 > pond_aabb[1].x) && (fork.x > 2 && fork.x < width - 3)) {
                var dir = (fork.y > (height / 2).floor ? 2 : 0) 

                start_pos = fork

                // Build road to buildings.
                for (i in 0...4) {
                    pos = fork + Directions[dir] * (i + 1)
                    if (this.contains(pos)) {
                        this[pos] = LevelTile.new(OType.road, Layer.overworld)
                    }
                }

                break
            } // Check if fork is outside pond boundary.
        } // Check all forks.

        if (pos == null) {
            System.print("OOPS")
            var fork = Vec2.new(1, height / 2)
            var dir = Directions[0]
            
            start_pos = fork

            for (i in 0...4) {
                pos = fork + dir * (i + 1)
                if (this.contains(pos)) {
                    this[pos] = LevelTile.new(OType.road, Layer.overworld)
                }
            }
        }

        // Place buildings.
        Create.building(pos.x - 1, pos.y, OType.shop)
        this[pos.x - 1, pos.y] = LevelTile.new(OType.road, Layer.overworld)

        Create.building(pos.x + 1, pos.y, OType.inn)
        this[pos.x + 1, pos.y] = LevelTile.new(OType.road, Layer.overworld)

        return start_pos
    }

    /// Get a random point in a room that does not have a tile on it. Padding is distance away from wall.
    getRandomGrassyPointOnMap(padding) {
        var pos = getRandomPointOnMap(padding)

        while (!Gameplay.checkTile(pos, OType.grasses, Layer.overworld)) {
            pos = getRandomPointOnMap(padding)
        }

        return pos
    }
    
    /// Get a random point on the map. Padding is distance away from edge.
    getRandomPointOnMap(padding) { Vec2.new(Tools.random.int(0 + padding, width - 1 - padding), Tools.random.int(0 + padding, height - 1 - padding)) }
    

    debugRender(font) { }
}

import "gameplay" for Gameplay
import "pond" for Pond
import "types" for SType, OType, Layer
import "create" for Create
import "directions" for Directions