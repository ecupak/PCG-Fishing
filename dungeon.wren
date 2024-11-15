import "xs" for Data, Render
import "xs_math" for Math, Vec2
import "xs_containers" for Grid, SparseGrid, Queue
import "xs_tools" for Tools
import "components" for Level, LevelTile, DungeonTile

class Room {
    construct new() {
        _min = Vec2.new(0, 0)
        _max = Vec2.new(1, 1)
        _id = -1
        _connections = {}
        _danger = 0
    }

    construct new(min, max) {
        _min = Vec2.new(min)
        _max = Vec2.new(max)
        _id = -1
        _connections = {}
        _danger = 0
    }

    id {_id}
    id=(v) {_id = v}

    min {_min}
    min=(v) {_min = v}

    max {_max}
    max=(v) {_max = v}

    width {_max.x - _min.x + 1}
    height {_max.y - _min.y + 1}

    connections {_connections}

    danger {_danger}
    danger=(v) {_danger = v}
}

class Zone {
    static init() {
        __index = 0
    }

    static index {__index}

    construct new () {
        _room = 0
        _children = []
        __index = __index + 1
        _my_index = __index
    }

    construct new (room) {
        _room = room
        _children = []
        __index = __index + 1
        _id = __index
    }

    id {_id}

    room {_room}
    room=(value) {_room = value}

    [x] {
        _children[x]
    }

    addChild(zone) {
        _children.add(zone)
    }

    children { _children }
}

/// Creates the procedurally generated dungeon.
class Dungeon is Level {
    /// Sets up the dungeon level.
    /// Call build() when needing to change the dungeon layout.
    /// 34w x 20h was the default size.
    construct new(width, height) {
        super(width, height)
        
        __current_room_idx = 0
        __reached_room_idx = 1
        __target_room_idx = 2
        
        __visualize = Data.getBool("Visualize Generation", Data.debug)
        __short_pause = Data.getNumber("Pause Short")
        __long_pause = Data.getNumber("Pause Long")
    }

    build(difficulty) {
        System.print("Dungeon difficulty: %(difficulty)")
        reset()

        var min_size = Data.getNumber("Room Min Size")
        var room_padding = Data.getNumber("Room Padding")
        var room_limit = 3 + difficulty //Data.getNumber("Room Count")

        // Subdivide grid into rooms.
        var root
        {
            Zone.init() // Initialize internal counter.

            var min = Vec2.new(room_padding, room_padding)
            var max = Vec2.new(width - room_padding - 1, height - room_padding - 1)
            var room = Room.new(min, max)
            root = Zone.new(room)

            subdivide(root, min_size + (room_padding * 2))
        }

        // Finalize rooms and their connections.
        _rooms = []
        var rooms = _rooms
        var hall_points = []
        createRooms(root, rooms, room_padding, room_limit, hall_points)

        // Surround created level with border. Do before other tiles get added so logic is easier.
        createBorder(rooms[0].min)

        // Find all culdesacs (dead end rooms).
        var culdesac_idxs = []  // Ids of rooms that are dead ends.
        var exit_tiles = []     // The entry/exit tile of the above rooms.
        var passable_idxs = []  // Ids of rooms that are not dead ends.
        
        findCulDeSacs(rooms, culdesac_idxs, exit_tiles, passable_idxs)
        
        // Get hero starting room and position.
        // - Room is used to make danger gradient for rooms.
        // - Position is to spawn hero tile in dungeon.
        var hero_start = getHeroStart(rooms, passable_idxs)        
        setDangerLevels(rooms, hero_start[0], difficulty)

        // Put a locked door in front of each culdesac. Place keys.
        placeDoorsAndKeys(rooms, culdesac_idxs, exit_tiles, passable_idxs, hero_start[0])

        // Place map needed to escape.
        placeMap(rooms, passable_idxs, hero_start[0])

        // Place enemies.
        placeEnemies(rooms, min_size, difficulty, hall_points)

        return hero_start[1] // Return the starting position.
    }

    subdivide(zone, req_space) {
        // Divide room on longest dimension.
        var room = zone.room
        var x_splits = [room.min.x, room.max.x, room.min.x, room.max.x]
        var y_splits = [room.min.y, room.max.y, room.min.y, room.max.y]
        var split

        if (room.width > room.height) {
            split = Tools.random.int(room.min.x + req_space, room.max.x - req_space)
            x_splits[1] = split - 1
            x_splits[2] = split + 1 
        } else {
            split = Tools.random.int(room.min.y + req_space, room.max.y - req_space)
            y_splits[1] = split - 1
            y_splits[2] = split + 1 
        }

        // Apply divisions.
        for (i in [0, 2]) {
            var min = Vec2.new(x_splits[i + 0], y_splits[i + 0])
            var max = Vec2.new(x_splits[i + 1], y_splits[i + 1])
            var child_room = Room.new(min, max)

            // Add room if it meets minimum size req.            
            if (child_room.width >= req_space && child_room.height >= req_space) {
                zone.addChild(Zone.new(child_room))

                //System.print("- created room %(Zone.index): %(min) to %(max)")
            } else {
                //System.print("- skipping creation: room too small")
            }
        }

        // Subdivide new rooms.
        for (child_zone in zone.children) {
            subdivide(child_zone, req_space)
        }
    } // end subdivide()

    createRooms(zone, rooms, room_padding, room_limit, hall_points) {
        gatherRooms(zone, rooms, room_padding)
        randomizeOrder(rooms)
        applyRoomLimit(rooms, room_limit)
        jitterPositions(rooms)
        centerRooms(rooms)
        assignRoomIds(rooms)
        fillRooms(rooms)
        addHallways(rooms, hall_points)        
    }

    gatherRooms(zone, rooms, room_padding) {
        // Drill into each zone until a zone with no children is reached. Fill grid with that zone's room. Repeat recursively.
        if (zone.children.count > 0) {
            for (child_zone in zone.children) {
                gatherRooms(child_zone, rooms, room_padding)
            }
        } else {
            // Shrink room border. Was used to help pad against other rooms and level edge.
            zone.room.min.x = zone.room.min.x + room_padding
            zone.room.max.x = zone.room.max.x - room_padding
            zone.room.min.y = zone.room.min.y + room_padding
            zone.room.max.y = zone.room.max.y - room_padding

            // Store rooms for corridor construction. Assign them their order in the list.            
            zone.room.id = zone.id
            rooms.add(zone.room)
        }
    }

    randomizeOrder(rooms) {
        rooms.sort {|a, b| Tools.random.int(0, 100) < 50}
    }
    
    applyRoomLimit(rooms, room_limit) {
        while (rooms.count > room_limit) {
            rooms.removeAt(room_limit)
        }        
    }

    jitterPositions(rooms) {
        for (room in rooms) {
            var y_offset = Tools.random.int(-1, 2)
            var x_offset = Tools.random.int(-1, 2)

            room.min.x = room.min.x + x_offset
            room.max.x = room.max.x + x_offset
            room.min.y = room.min.y + y_offset
            room.max.y = room.max.y + y_offset
        }
    }

    centerRooms(rooms) {
        // Get max and min of area containing all rooms.
        var min = Vec2.new(width * 2, height * 2)
        var max = Vec2.new(0, 0)

        for (room in rooms) {
            min.x = Math.min(min.x, room.min.x)
            max.x = Math.max(max.x, room.max.x)
            min.y = Math.min(min.y, room.min.y)
            max.y = Math.max(max.y, room.max.y)
        }

        // Find center of room aabb.
        var room_center = Vec2.new((min.x + max.x) / 2, (min.y + max.y) / 2)
        var level_center = Vec2.new(width / 2, height / 2)

        // Apply offset and shift rooms.
        var offset = level_center - room_center
        offset.x = offset.x.floor
        offset.y = offset.y.floor

        for (room in rooms) {
            room.min = room.min + offset
            room.max = room.max + offset
        }
    }

    assignRoomIds(rooms) {
        for (i in 0...rooms.count) rooms[i].id = i
    }

    fillRooms(rooms) {
       for (i in 0...rooms.count) {
            var room = rooms[i]

            for (y in room.min.y..room.max.y) {
                for (x in room.min.x..room.max.x) {                    
                    this[x, y] = LevelTile.new(DType.floor, Layer.dungeon)
                }
            }

            if (__visualize) Fiber.yield(__short_pause)
        }
    }

    addHallways(rooms, hall_points) {
        // Connect each room to the next in the list (and connect first and last to make a loop).
        for (i in 0...rooms.count) {            
            var next_index = (i + 1) % rooms.count
            var a = rooms[i]
            var b = rooms[next_index]

            // Create a hall between a random point from each room. Use A.x and B.y as the midpoint.
            // The hall will usually have 1 elbow in it.
            var point_a = Vec2.new(Tools.random.int(a.min.x, a.max.x), Tools.random.int(a.min.y, a.max.y))
            var point_b = Vec2.new(Tools.random.int(b.min.x, b.max.x), Tools.random.int(b.min.y, b.max.y))
            var midpoint = Vec2.new(point_a.x, point_b.y)
            
            System.print("")
            System.print("Connecting room %(i) (%(point_a) in %(rooms[i].min)) to room %(next_index) (%(point_b) in %(rooms[next_index].min))")
            
            // Debug - show start-, mid-, and end- points before placing.
            if (__visualize) {
                // Show...
                this[point_a.x, point_a.y] = LevelTile.new(DType.e_crab, Layer.dungeon)            
                this[point_b.x, point_b.y] = LevelTile.new(DType.e_gator, Layer.dungeon)
                
                var prev_mid = this[midpoint.x, midpoint.y]
                if (midpoint != point_a && midpoint != point_b) {
                    this[midpoint.x, midpoint.y] = LevelTile.new(DType.e_squid, Layer.dungeon)
                }

                Fiber.yield(__long_pause)

                // Hide...
                this[point_a.x, point_a.y] = LevelTile.new(DType.floor, Layer.dungeon)
                this[point_b.x, point_b.y] = LevelTile.new(DType.floor, Layer.dungeon)
                
                if (midpoint != point_a && midpoint != point_b) {
                    this[midpoint.x, midpoint.y] = prev_mid
                }
            }
            
            // Create hallway between rooms. Will not create connections between intermediary rooms if those rooms are already connected.
            var end_points = [midpoint, point_b]
            var room_indices = [a.id, -1, b.id]            
            var hallway = getHallway(point_a, end_points, rooms, room_indices)

            // Add hallway to level.
            var count = 0
            var iteration = 0
            var iteration_max = hallway.count
            var safe_to_place = false
            for (tile in hallway) {
                // Can add up to 2 points in hall as spawn points for enemies or items.
                // Do not place close to the ends of the hallway - crowds the room.
                safe_to_place = (iteration > 4 && iteration_max - iteration > 4)                
                if (safe_to_place && count < 1 && Tools.random.int(100) < 10) {
                    hall_points.add(tile)
                    count = count + 1
                }

                this[tile.x, tile.y] = LevelTile.new(DType.floor, Layer.dungeon)

                iteration = iteration + 1
            }
        }
    }    

    getHallway(start_point, end_points, rooms, room_indices) {
        var tile = start_point
        var direction = (end_points[0] - tile).normal

        // Check if tile is on end point.
        // - If true, get next end point.
        if (isTileAtEndPoint(tile, end_points, false)) {
            // Check if there are any more end points remaining.
            // - If true, find direction to new end point.
            if (end_points.count > 0) {
                direction = (end_points[0] - tile).normal

            // - If none remain, exit hall construction.
            // - (Should never reach this point. Last end point is always in target room.)
            } else {
                return hallway
            }
        }    

        var hallway = []
        var hallway_addition = [tile]
        var mid_room_data = [{}, []]
        resetMidRoomData(mid_room_data, room_indices[__current_room_idx])

        while (true) {
            // Get next tile.            
            tile = tile + direction

            // Check if tile is adjacent to another room.
            checkForMidRooms(tile, rooms, room_indices, mid_room_data)

            // Check if tile is in another room.
            if (isTileInAnotherRoom(tile, rooms, room_indices)) {
                if (room_indices[__reached_room_idx] != room_indices[__current_room_idx]) {
                    System.print("- reached other room (%(room_indices[__reached_room_idx]))")
                    
                    if (areRoomsConnected(rooms, room_indices)) {
                        hallway_addition.clear()

                    // - If they are not connected, connect them and any mid rooms found. Expand hallway.
                    } else {
                        connectMidRooms(mid_room_data, rooms)                        
                    
                        hallway = hallway + hallway_addition
                        hallway_addition.clear()                    
                    }
                    
                    // If reached target room, exit hallway construction.
                    if (room_indices[__reached_room_idx] == room_indices[__target_room_idx]) return hallway 

                    // Reset room data.
                    resetRoomData(room_indices, mid_room_data)
                }
            // Otherwise, check if tile is on a hallway.
            } else if (isTileOnAnotherHall(tile)) {
                if (hasPathToTarget(tile, hallway_addition[0]) && mid_room_data.count == 1) {
                    hallway_addition.clear()
                }
            }

            // Check if tile is on end point.
            // - If true, get next end point.
            if (isTileAtEndPoint(tile, end_points, false)) {                
                // Check if there are any more end points remaining.
                // - If true, find direction to new end point.
                if (end_points.count > 0) {
                    direction = (end_points[0] - tile).normal

                // - If none remain, exit hall construction.
                // - (Should never reach this point. Last end point is always in target room.)
                } else {
                    return hallway
                }
            }            

            // Tile is good, add to hall.
            hallway_addition.add(tile)
        }
    }

    isTileInAnotherRoom(tile, rooms, room_indices) {
        for (r in 0...rooms.count) {            
            if (isTileInRoom(tile, rooms[r])) {
                room_indices[__reached_room_idx] = r
                return true
            }             
        }

        return false
    }

    isTileInRoom(point, room) { point.x >= room.min.x && point.x <= room.max.x && point.y >= room.min.y && point.y <= room.max.y }

    resetRoomData(room_indices, mid_room_data) {    
        room_indices[__current_room_idx] = room_indices[__reached_room_idx]
        room_indices[__reached_room_idx] = -1

        resetMidRoomData(mid_room_data, room_indices[__current_room_idx])
    }

    areRoomsConnected(rooms, room_indices) { rooms[room_indices[__current_room_idx]].connections.containsKey(room_indices[__reached_room_idx]) }

    connectRooms(rooms, a, b) {
        rooms[a].connections[b] = true
        rooms[b].connections[a] = true

        System.print("- - connected rooms %(a) and %(b)")
    }
    
    checkForMidRooms(tile, rooms, room_indices, mid_room_data) {
        // If adjacent to a room, add to list of mid_room_indices
        for (dir in Directions.cardinal()) {
            var adjacent = tile + dir

            // If adjacent pos is in a room that is not in the mid room data, add it.
            if (isTileInAnotherRoom(adjacent, rooms, room_indices)) {
                if (!mid_room_data[0].containsKey(room_indices[__reached_room_idx])) {
                    mid_room_data[0][room_indices[__reached_room_idx]] = true
                    mid_room_data[1].add(room_indices[__reached_room_idx])

                    System.print("- passed adjacent room: %(room_indices[__reached_room_idx])")
                }
            }
        }
    }

    connectMidRooms(mid_room_data, rooms) {
        // Will always have the starting and end room of the hall in list.
        for (i in 0...mid_room_data[1].count - 1) {
            connectRooms(rooms, mid_room_data[1][i], mid_room_data[1][i + 1])
        }        
    }

    resetMidRoomData(mid_room_data, current_room_index) {
        mid_room_data[0].clear()
        mid_room_data[1].clear()

        mid_room_data[0][current_room_index] = true
        mid_room_data[1].add(current_room_index)
    } 

    isTileAtEndPoint(tile, end_points, is_deep_check) {
        if (tile == end_points[0]) {
            // Remove end point.
            end_points.removeAt(0)

            // Check if there is another end point to move towards.
            // - If true, confirm tile is not on that end point.
            if (end_points.count > 0) {
                // Recursive. Will always return true at this point.
                // But each iteration may edit the end point.
                return isTileAtEndPoint(tile, end_points, true)

            // - No more end points exist.
            } else {
                return false
            }

        // Not on end point.
        // - If initial check, keep using same direction.
        // - If deep check, need to get new direction. 
        } else {
            return is_deep_check
        }
    }

    isTileOnAnotherHall(tile) { this[tile].type == DType.floor }    

    hasPathToTarget(start, target) {
        var visited = SparseGrid.new()
        var fill = Queue.new()

        fill.push(start)
        visited[start] = true

        var iterations = 0
        while (!fill.empty()) {            
            var tile = fill.pop()

            if (tile == target) {
                System.print("- - found path from hall to room in %(iterations) iterations")
                return true
            }

            // Fill ground until target is reached.
            for (dir in Directions.cardinal()) {
                var check = tile + dir
                
                if (this[check].type == DType.floor && !visited.has(check)) {
                    fill.push(check)
                    visited[check] = true
                }
            }

            iterations = iterations + 1
        }

        System.print("- - did NOT find path from hall to room after %(iterations) iterations")
        return false
    }

    createBorder(start) {
        System.print(" ")
        System.print("Creating border")
        
        var visited = SparseGrid.new()
        var fill = Queue.new()

        fill.push(start)
        visited[start] = true
        
        var count = 0
        while (!fill.empty()) {            
            var tile = fill.pop()

            // Replace cardinally-adjacent filler tiles with walls.
            // Add floor tiles to search list.
            for (dir in Directions.cardinal()) {
                var check = tile + dir
                var type = this[check].type
                
                if (!visited.has(check)) {
                    if (type == DType.floor) {
                        fill.push(check)                        
                    } else if (type == DType.empty) {
                        this[check] = LevelTile.new(DType.wall, Layer.dungeon)
                    }
                    visited[check] = true
                }
            }

            // Replace ordinally-adjacent filler tiles with walls.
            for (dir in Directions.ordinal()) {
                var check = tile + dir                

                if (this[check].type == DType.empty) {
                    this[check] = LevelTile.new(DType.wall, Layer.dungeon)
                }
            }
        }
    }

    findCulDeSacs(rooms, culdesac_idxs, exit_tiles, passable_idxs) {
        for (r in 0...rooms.count) {
            var room = rooms[r]
            
            // Check surrounding tiles for count of floors. If only 1 floor, then only 1 path in/out.
            // Must check, because hallways may "graze" room and create many exits while still only connecting room to 1 other.
            var tile = room.min - Vec2.new(1, 1)
            var exits = []

            var strides = [room.height, room.width, room.height, room.width]
            
            for (d in 0...4) {
                for (i in 1...(strides[d] + 2)) {
                    tile = tile + Directions[d]
            
                    if (this[tile].type == DType.floor) {
                        exits.add(tile)

                        if (exits.count > 1) break
                    }
                }

                if (exits.count > 1) break
            }
            
            if (exits.count == 1) {
                culdesac_idxs.add(r)
                exit_tiles.add(exits[0])
            }
        }

        // Find all non-dead end rooms (passable).
        var temp_passable_idxs = Tools.toList(0, rooms.count)
        for (p in temp_passable_idxs) passable_idxs.add(p)
        for (e in 0...culdesac_idxs.count) passable_idxs.removeAt(passable_idxs.indexOf(culdesac_idxs[e]))
    }

    getHeroStart(rooms, passable_idxs) {
        var hero_start = [] // room id, position in room

        /// Find smallest passable room to be the hero start room.
        var smallest = Num.largest
        var hero_room_idx = -1
        for (r in passable_idxs) {
            var room = rooms[r]
            var area = room.width * room.height
            if (area < smallest) {
                smallest = area
                hero_room_idx = room.id
            }
        }
        hero_start.add(hero_room_idx)

        // Find starting point.
        var room = rooms[hero_start[0]]
        hero_start.add(getFreePointInRoom(room))

        return hero_start
    }

    setDangerLevels(rooms, hero_room_idx, difficulty) {
        // Danger increases further away from hero.
        var visited = {}
        var open = Queue.new()
        rooms[hero_room_idx].danger = 0
        open.push([hero_room_idx, 0])

        while (!open.empty()) {            
            var next = open.pop()
            var index = next[0]

            if (!visited.containsKey(index)) {
                var danger = next[1] == 0 ? difficulty : next[1]
                var room = rooms[index]
                
                for (entry in room.connections) {
                    if (!visited.containsKey(entry.key)) {
                        open.push([entry.key, danger + 1])
                        rooms[entry.key].danger = danger + 1                    
                    }
                }

                visited[index] = true
            }
        }
    }

    placeDoorsAndKeys(rooms, culdesac_idxs, exit_tiles, passable_idxs, hero_room_idx) {
        // If there are no culdesacs, can't lock any rooms.
        if (culdesac_idxs.count == 0) return

        // Each culdesac will have a locked door in front of it and a key inside.
        // If every culdesac is visited, the hero will have 1 leftover key.
        // So 1 culdesac will have its key replaced with a special item.

        // A key must be placed outside of a locked room for the hero to get into any of them.
        // If this key happens to be placed in a culdesac, that culdesac will not have a locked door.
        // That culdesac can also not be the one to have a special item.
        
        // Find the furthest room from the hero start to place the free key in.
        var visited = {}
        var safe_rooms = {}
        var adjacent_rooms = {}
        var culdesac_rooms = {}
        var open = Queue.new()        
        open.push([hero_room_idx, 0]) // room, distance away from hero room

        while (!open.empty()) {
            var next = open.pop()
            var index = next[0]
            var distance = next[1]
            var is_adjacent = false

            if (!visited.containsKey(index)) {
                var room = rooms[index]
                for (entry in room.connections) {
                    if (!visited.containsKey(entry.key)) {
                        // Check if connected to a culdesac.
                        if (Tools.isInList(entry.key, culdesac_idxs)) {
                            is_adjacent = true
                        }
                        open.push([entry.key, distance + 1])
                    }
                }

                // Check if this room is a culdesac and add to appropriate list.
                var is_culdesac = Tools.isInList(index, culdesac_idxs)
                if (is_culdesac) culdesac_rooms[index] = distance
                if (is_adjacent) adjacent_rooms[index] = distance                        
                if (!is_culdesac && !is_adjacent) safe_rooms[index] = distance
                
                // Complete room.
                visited[index] = distance
            }
        }

        // Use largest distance from the list that has at least 1 value.
        var key_rooms = null
        if (safe_rooms.count > 0) { // Always prioritize a safe room.
            key_rooms = safe_rooms
        } else if (culdesac_rooms.count > 1) { // If there are multiple culdesacs, use one.
            key_rooms = culdesac_rooms
        } else if (adjacent_rooms.count > 0) { // If no other choices, choose an adjacent room.
            key_rooms = adjacent_rooms
        } else {
            // Somehow?
            return
        }

        // Find largest distance.
        var largest = 0
        var key_room_idx = hero_room_idx
        for (entry in key_rooms) {
            if (entry.value > largest) {
                largest = entry.value
                key_room_idx = entry.key
            }
        }
        
        // Place key in the above room.
        var pos = getFreePointInRoom(rooms[key_room_idx])
        Create.item(pos.x, pos.y, SType.i_key, 1)

        // One of the locked culdesacs will not have a key replaced with a bubble item.
        // This makes sure the bubble room is not also the key room selected earlier.
        var culdesac_bubble_idx = Tools.random.int(culdesac_idxs.count)
        if (culdesac_idxs[culdesac_bubble_idx] == key_room_idx) {
            culdesac_bubble_idx = (culdesac_bubble_idx + 1) % culdesac_idxs.count
        }
        var bubble_room_idx = culdesac_idxs[culdesac_bubble_idx]

        // Add a door and key to each culdesac.
        // Skip the key room from earlier. Don't add a key to the bubble room.
        for (i in 0...culdesac_idxs.count) {
            var room_idx = culdesac_idxs[i]
            
            // If not the key room, add door and key.
            if (room_idx != key_room_idx) {
                
                // If not the bubble room, add key.
                if (room_idx != bubble_room_idx) {
                    var pos = getFreePointInRoom(rooms[room_idx])
                    Create.item(pos.x, pos.y, SType.i_key, 1)
                }
                
                Create.door(exit_tiles[i].x, exit_tiles[i].y)
            }
        }

        // Mark bubble room for special item.
        rooms[bubble_room_idx].danger = -1
    }    

    placeMap(rooms, passable_idxs, hero_room_idx) {
        System.print(" ")
        System.print("Placing map")

        var room_idx = hero_room_idx
        
        if (passable_idxs.count > 1) {
            while (room_idx == hero_room_idx) {
                room_idx = Tools.pickOne(passable_idxs)
            }
        }

        var pos = getFreePointInRoom(rooms[room_idx])
        Create.item(pos.x, pos.y, SType.i_map, 1)
    }

    placeEnemies(rooms, min_size, difficulty, hall_points) {
        // Based on difficulty and danger level, add different enemy combinations.
        var enemy_table = [DType.e_crab, DType.e_eel, DType.e_squid, DType.e_octo, DType.e_gator]
        enemy_table = enemy_table[0...(3 + difficulty)]
        
        System.print(enemy_table)

        for (room in rooms) {
            System.print(" ")
            System.print("Placing enemies in room %(room.id) | min at %(room.min) | w %(room.width) h %(room.height)")
            if (room.danger == -1) {
                // Bubble room.
                var pos = getFreePointInRoom(room, 1)
                Create.item(pos.x, pos.y, SType.i_bubble, 1) 

                room.danger = 1
            } else if (room.danger == 0) {
                // Hero start room.
                continue
            }

            var capacity_regulator = 9
            var capacity = Math.max(1, ((room.width * room.height) / capacity_regulator).floor)
            var danger_value = room.danger * (1 + difficulty)
            System.print("Difficulty %(difficulty) | Room danger %(room.danger) | Danger value %(danger_value) | Capacity %(capacity)")

            // Add enemies until danger value has been met. If capacity is reached, "promote" 1 enemy.
            var enemies = []
            while (danger_value > 0) {
                if (enemies.count < capacity) {
                    var max_idx = Math.min(danger_value, enemy_table.count)
                    var enemy_idx = Tools.random.int(max_idx)
                    danger_value = danger_value - enemy_idx - 1
                    enemies.add(enemy_idx)
                    System.print("- enemy %(enemy_idx) added; remaining danger %(danger_value)")
                } else {
                    var enemy_idx = Tools.random.int(enemies.count)
                    enemies[enemy_idx] = Math.min(enemy_table.count - 1, enemies[enemy_idx] + 1)
                    System.print("- enemy %(enemies[enemy_idx]) was promoted")                    
                    break
                }
            }

            // Create enemies.
            for (i in enemies) {
                var type = enemy_table[i]
                var pos = getFreePointInRoom(room, 1)
                Create.monster(pos.x, pos.y, type, i + difficulty, difficulty)
                System.print("- enemy %(i) placed at %(pos)")
            }

            // Create item based on average enemy level and difficulty.
            var avg_enemy_level = (difficulty / 2).floor
            for (i in enemies) avg_enemy_level = avg_enemy_level + i
            var droptable_idx = Math.min(Create.droptables_count - 1, (avg_enemy_level / enemies.count).floor)
            droptable_idx = Math.max(difficulty, droptable_idx)
            System.print("- - avg level %(avg_enemy_level) | max idx %(Create.droptables_count - 1) | calc idx %((avg_enemy_level / enemies.count).floor)")

            var value = Tools.random.int(0, 4) + (1 + difficulty) * 5

            System.print("- %(value) item(s) placed from table %(droptable_idx) | AEL %((avg_enemy_level / enemies.count).floor)")
            placeItemInRoom(room, 1, droptable_idx)

            // Chance to place another item based on difficulty.
            var item_chance = 10 * difficulty
            if (Tools.random.int(0, 100) < item_chance) {
                droptable_idx = Math.max(0, droptable_idx - 1)
                value = (value / 2).ceil
                placeItemInRoom(room, 1, droptable_idx)
                System.print("- chance %(item_chance)/100: %(value) item(s) placed from table %(droptable_idx)")
            }
        } // Added enemies to all rooms.

        // Add to hallways.
        for (tile in hall_points) {
            if (Tools.random.int(100) < 30) {
                Create.droptable_item(tile.x, tile.y, difficulty + Tools.random.int(1, 3))
            } else {
                var i = Tools.random.int(enemy_table.count)
                Create.monster(tile.x, tile.y, enemy_table[i], i + difficulty, difficulty)
            }
        }
    }   

    /// Create item in room using the given drop table.
    placeItemInRoom(room, padding, drop_table_idx) {
        var pos = getFreePointInRoom(room, 1)
        Create.droptable_item(pos.x, pos.y, drop_table_idx)
    }

    /// Get a random point in a room that does not have a tile on it. Padding is distance away from wall.
    getFreePointInRoom(room, padding) {
        var pos = getPointInRoom(room, padding)

        while (!DungeonTile.isOpen(pos)) {
            pos = getPointInRoom(room, padding)
        }

        return pos
    }
    getFreePointInRoom(room) { getFreePointInRoom(room, 0) }
    
    /// Get a random point in a room. Padding is distance away from wall.
    getPointInRoom(room, padding) { Vec2.new(Tools.random.int(room.min.x + padding, room.max.x + 1 - padding), Tools.random.int(room.min.y + padding, room.max.y + 1 - padding)) }
    getPointInRoom(room) { getPointInRoom(room, 0) }

    debugRender(font) { 
        Render.dbgColor(0xFFFFFFFF)
        for (room in _rooms) {
            var pix2 = calculatePos(room.min.x, room.max.y)            
            Render.text(font, "%(room.id)", pix2.x, pix2.y, 1.0, 0xFFFF00FF, 0x0, Render.spriteCenter)
        }
    }
}

import "Types" for SType, DType, Layer
import "create" for Create
import "directions" for Directions