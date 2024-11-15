import "xs_ec" for Entity, Component
import "xs" for Data, Input, Render
import "xs_math"for Math, Bits, Vec2, Color
import "xs_containers" for Grid, SparseGrid, Queue
import "xs_tools" for Tools

class LevelTile { // under tile
    construct new() {
        _type = 0
        _layer = 0
        _rotation = 0
    }

    construct new(type, layer) {
        _type = type
        _layer = layer
        _rotation = 0
    }

    construct new(type, layer, rotation) {
        _type = type
        _layer = layer
        _rotation = rotation
    }

    type {_type}
    layer {_layer}
    rotation {_rotation}
}

/// Contains the level data and the logic to manipulate it.
/// It's completely static and should be used as a singleton.
class Level {
    
    /// Initialize the level with the data from the game
    /// Must be called before using the Level class
    construct new(width, height) {
        _tileSize = Data.getNumber("Tile Size", Data.game)
        _width = width
        _height = height
        _grid = Grid.new(width, height, LevelTile.new())
    }

    reset() {
        _grid = Grid.new(width, height, LevelTile.new())
    }
    
    /// Calculate the position of a tile in the level
    calculatePos(tile) {
        return calculatePos(tile.x, tile.y)
    }

    /// Calculate the pixel position of a tile in the level
    calculatePos(tx, ty) {
        var sx = (_width - 1) * -_tileSize / 2.0
        var sy = (_height - 1)  * -_tileSize / 2.0
        var px = sx + tx * _tileSize
        var py = sy + ty * _tileSize
        return Vec2.new(px, py)        
    }

    /// Calculate the tile position of a given position in the level
    calculateTile(pos) {
        var sx = (_width - 1.0) * -_tileSize / 2.0
        var sy = (_height - 1.0)  * -_tileSize / 2.0
        var tx = (pos.x - sx) / _tileSize
        var ty = (pos.y - sy) / _tileSize
        return Vec2.new(tx.round, ty.round)
    }
    
    /// Get the tile at a given position (used for rendering)
    tileSize { _tileSize }
    
    /// Get the width of the level (in tiles)
    width { _width }

    /// Get the height of the level (in tiles)
    height { _height }

    /// Check if a tile position is inside the level
    contains(x, y) { _grid.valid(x, y) }
    contains(pos) { _grid.valid(pos.x, pos.y) }

    /// Get the tile at a given position
    [x, y] { _grid[x, y] }

    /// Set the tile at a given position
    [x, y]=(v) { _grid[x, y] = v }
    
    /// Get the tile at a given position
    [pos] { _grid[pos.x, pos.y] }

    /// Set the tile at a given position
    [pos]=(v) { _grid[pos.x, pos.y] = v }

    grid { _grid }
}

/// A compenent that represents a tile in the level.
/// It is used to store the position of the tile in the level,
/// but also to store all the tiles in the level as a static variable.
class OverworldTile is Component {
    /// Must be called from the game before using the Tile class.
    static initialize() {
        __tiles = SparseGrid.new()
    }

    /// Get the tile at a given position.
    static get(x, y) {
        if(__tiles.has(x, y)) return __tiles[x, y]
        return null
    }

    static get(pos) { 
        return get(pos.x, pos.y) 
    }

    static getAll() {
        return __tiles.values
    }
    
    static clear() {
        __tiles.clear()
    }

    /// Check if the position already has a tile.
    static isOpen(x, y) { !__tiles.has(x, y) }
    static isOpen(pos) { !__tiles.has(pos.x, pos.y) }

    /// Create a new tile at a given position.
    construct new(x, y) {
        _x = x
        _y = y        
        __tiles[x, y] = this
    }
    
    /// Move the tile to relative position.
    move(dx, dy) {
        __tiles.remove(_x, _y)
        _x = _x + dx
        _y = _y + dy
        __tiles[_x, _y] = this
    }

    move(dir) { 
        move(dir.x, dir.y) 
    }

    /// Move the tile to an absolute position.
    place(x, y) {
        __tiles.remove(_x, _y)
        _x = x
        _y = y
        __tiles[_x, _y] = this
    }

    place(pos) { 
        place(pos.x, pos.y) 
    }

    /// Remove the tile from the level (gets called when the entity is deleted).
    finalize() {
        // Check if the tile has not been replaced already
        if(__tiles[_x, _y] == this) {
            __tiles.remove(_x, _y)
        }
    }

    /// Accessors.
    x { _x }
    y { _y }
    pos { Vec2.new(_x, _y) }
}

class DungeonTile is Component {
    /// Must be called from the game before using the Tile class.
    static initialize() {
        __tiles = SparseGrid.new()
    }

    /// Get the tile at a given position.
    static get(x, y) {
        if(__tiles.has(x, y)) return __tiles[x, y]
        return null
    }

    static get(pos) { 
        return get(pos.x, pos.y) 
    }

    static getAll() {
        return __tiles.values
    }

    static clear() {
        __tiles.clear()
    }

    /// Check if the position already has a tile.
    static isOpen(x, y) { !__tiles.has(x, y) }
    static isOpen(pos) { !__tiles.has(pos.x, pos.y) }

    /// Create a new tile at a given position.
    construct new(x, y) {
        _x = x
        _y = y
        __tiles[x, y] = this
    }
    
    /// Move the tile to relative position.
    move(dx, dy) {
        __tiles.remove(_x, _y)
        _x = _x + dx
        _y = _y + dy
        __tiles[_x, _y] = this
    }

    move(dir) { 
        move(dir.x, dir.y) 
    }

    /// Move the tile to an absolute position.
    place(x, y) {
        __tiles.remove(_x, _y)
        _x = x
        _y = y
        __tiles[_x, _y] = this
    }

    place(pos) { 
        place(pos.x, pos.y) 
    }

    /// Remove the tile from the level (gets called when the entity is deleted).
    finalize() {
        // Check if the tile has not been replaced already
        if(__tiles[_x, _y] == this) {
            __tiles.remove(_x, _y)
        }
    }

    /// Accessors.
    x { _x }
    y { _y }
    pos { Vec2.new(_x, _y) }
}


class Stats is Component {
    construct new(health, damage, armor, drop) {
        _health = health    // Health points
        _damage = damage    // Damage points
        _armor = armor      // Armor points
        _drop = drop        // Drop chance
    }

    /// Clone the stats - used to create a copy of the stats and modify them
    /// without changing the original. Useful for creating new entities with
    /// similar stats
    clone() { Stats.new(_health, _damage, _armor, _drop) }

    add(other) {
        _health = _health + other.health
        _damage = _damage + other.damage
        _armor = _armor + other.armor
        _drop = _drop + other.drop
    }

    health { _health }
    damage { _damage }
    armor { _armor }
    drop { _drop }

    health=(v) { _health = v }
    damage=(v) { _damage = v }
    armor=(v) { _armor = v }
    drop=(v) { _drop = v }
}


/// A base class for all characters in the game.
/// Used by the hero and the monsters.
class Character is Component {
    /// Create a new character with a given type of attackable entities.
    construct new(attackable, layer, level) {
        _attackable = [attackable, layer]
        _level = level
    }

    /// Initialize the character by caching the stats and the tile.
    initialize() {
        _stats = owner.get(Stats)
        _tile = owner.get(Gameplay.current_overtiles)
    }

    /// Update the character - just debug rendering for now.
    update(dt) {
        if(Data.getBool("Debug Draw", Data.debug)) {
            var pos = Gameplay.current_level.calculatePos(_tile)
            Render.dbgColor(0xFFFFFFFF)
            Render.dbgText("%(owner.name)", pos.x - 7, pos.y + 7, 1)
        }
    }

    /// Implement turn logic here once and return true when done.
    turn() { true }  

    /// Check if the tile in the direction has a given type and layer.    
    checkTile(dir_pos, type, layer) {
        if (dir_pos.type == Vec2) {
            return Gameplay.checkTile(dir_pos, type, layer)
        }

        var pos = _tile.pos + Directions[dir_pos]
        return Gameplay.checkTile(pos, type, layer)
    }

    // checkTileLayer ?

    /// Move the tile in the direction
    move(dir) {
        _tile.move(Directions[dir])
    }

    /// Attack the tile in the direction
    attack(dir) {
        System.print("Attacking from position [%(_tile.x), %(_tile.y)] in direction [%(Directions[dir])]")
        var pos = _tile.pos + Directions[dir]
        if (checkTile(pos, _attackable[0], _attackable[1])) {
            var other = Gameplay.current_overtiles.get(pos.x, pos.y)
            var stats = other.owner.get(Stats)
            
            var damage = Math.max(1, _stats.damage - stats.armor) // always deal 1 dmg
            stats.health = stats.health - damage
            Gameplay.message =  "%(owner.name) deals %(damage) damage to %(other.owner.name)"

            if (stats.health <= 0) {
                Gameplay.message = "%(owner.name) kills %(other.owner.name)"                
                other.owner.delete()
                if (Tools.random.float(0.0, 1.0) < stats.drop) Create.droptable_item(pos.x, pos.y, level)
                return other.owner.get(Character).level + 1
            }        
            return 0
        }
    }

    /// Get the tile of the character
    tile { _tile }
    stats {_stats}

    attackable {_attackable}
    level {_level}
    level=(v) {_level = v}
}

/// A class that represents the hero of the game.
/// The hero is also a singleton, so there is only one hero in the game.
class Hero is Character {        
    /// Player singleton turn
    static turn() {
        if(__hero) return __hero.turn()
    }    

    /// Get the hero singleton
    static hero { __hero }

    /// Create a new hero component
    construct new() {
        super(DType.enemy, Layer.dungeon, 1)
        // Input helpers.
        _buttons = [Input.gamepadDPadUp,
                    Input.gamepadDPadRight,
                    Input.gamepadDPadDown,
                    Input.gamepadDPadLeft ]
        
        _keys = [   Input.keyUp,
                    Input.keyRight,
                    Input.keyDown,
                    Input.keyLeft]
        
        // Hero data.
        _inventory = Inventory.new()
        _state = HeroWalking
        _prev_overworld_pos = Vec2.new()
        _air = 100
        _max_air = 100
        _max_hp = 10
        _xp = 4
        _xp_to_level = 5

        inventory.add(SType.i_axe, 4)
        inventory.add(SType.i_pick, 3)
        inventory.add(SType.i_shovel, 2)

        inventory.add(SType.i_marigold, 1)
        inventory.add(SType.i_coin, 1)
        inventory.add(SType.i_peridot, 1)
        inventory.add(SType.i_bone, 1)
        inventory.add(SType.i_rose, 1)
        inventory.add(SType.i_key, 1)
        inventory.add(SType.i_amethyst, 1)
        inventory.add(SType.i_ruby, 1)
        inventory.add(SType.i_map, 1)
        inventory.add(SType.i_iris, 1)

        // Access helper.
        __hero = this
    }

    /// Player turn logic
    turn() {        
        var action = getAction()
        var dir = getDirection()
        var next_state = _state.handleInput(this, action, dir)

        if (next_state != null) {
            _state.exit(this)
            _state = next_state
            _state.enter(this)

            return true
        }

        return false
    }
    
    setState(new_state) {
        if (new_state == null) return

        if (_state != null) _state.exit(this)

        _state = new_state
        _state.enter(this)
    }

    resetState(gameplay_state) {
        var next_state = (Gameplay.world_state == Gameplay.overworld_state ? HeroWalking : HeroExploring)
        
        setState(next_state)
    }

    addXp(amount) {
        // Add and check if level up.
        _xp = _xp + amount
        if (_xp >= _xp_to_level) {
            _xp = _xp - _xp_to_level
            level = level + 1
            _xp_to_level = _xp_to_level + 5

            Menu.openLevelUpMenu()
        }
    }

    loseAir(v) {
        air = air - v
        if (air <= 0) Menu.openGameOverMenu()
    }

    // Use tools (triggered by menu selection).
    useRod() { setState(HeroCasting) }
    useAxe() { setState(HeroCutting) }
    usePick() { setState(HeroMining) }
    useShovel() { setState(HeroDigging) }

    /// Get the direction of the player input
    getDirection() {
        for(dir in 0...4) {
            if(Input.getButtonOnce(_buttons[dir]) || Input.getKeyOnce(_keys[dir])) {
                return dir
            }
        }
        return -1
    }

    /// Get the action of the player input.
    getAction() {
        if (Input.getButtonOnce(Input.gamepadButtonSouth) || Input.getKeyOnce(Input.keyE)) {
            return 1
        }

        if (Input.getButtonOnce(Input.gamepadButtonWest) || Input.getKeyOnce(Input.keyQ)) {
            return -1
        }

        return 0
    }

    /// Called when map is swapped between overworld and dungeon.
    /// Let's hero reassign their tile to the new tile component.
    reinitialize() {
        initialize()
    }

    /// Finalize the hero singleton by setting it to null
    finalize() {
        __hero = null
        Menu.openGameOverMenu()
    }

    inventory { _inventory }
    
    max_hp {_max_hp}
    max_hp=(v) {_max_hp = v}

    air {_air}
    air=(v) {_air = v}

    max_air {_max_air}

    prev_overworld_pos { _prev_overworld_pos }
    prev_overworld_pos=(v) { _prev_overworld_pos = v }
}

/// A class that represents the monsters in the game.
/// The monsters are controlled by the computer and the class
/// contains the logic to play a turn for all the monsters.
class Monster is Character {
    /// Create a new monster component
    construct new(level) {
        super(SType.player, Layer.shared, level)
        
        var stats = Stats.new(1, 1, 1, 1)
    }

    /// Single monster turn logic
    turn() {
        var dir = getDirection()                                                         
        if(dir >= 0) {
            if(checkTile(dir, attackable[0], attackable[1])) {
                attack(dir)
                __loudness = 5
                Hero.hero.loseAir(1)
            } else if(!checkTile(dir, DType.monster_block, Layer.dungeon)) {
                move(dir)
                return 1
            }
            return 0
        } 
    }

    /// Get the direction of the monster
    getDirection() {
        if(__fill) {
            if(__fill.has(tile.x, tile.y)) {
                return __fill[tile.x, tile.y]
            }
        }
        return -1
    }

    /// Computer turn logic for all the monsters
    static turn() {
        if (__turn_order == null || __turn_order.empty()) {            
            __turn_order = Queue.new()
            __loudness = 0

            var entities = Entity.withTagOverlapInLayer(DType.enemy, Layer.dungeon)
            if (entities.count == 0) return 1
            
            for(e in entities) __turn_order.push(e)
        }

        var entity = __turn_order.pop()  
        floodFill() // Run for each enemy because an previous enemy may block path.
        var enemy = entity.get(Monster)
        var result = enemy.turn()

        if (__turn_order.empty()) return 1 // enemies are done with their collective turns.
        if (result == 1) return 2 // enemy moved.
        return 0 // enemy did not move.
    }

    /// An algorithm to fill the level with the directions to the hero    
    static floodFill() {
        if(Hero.hero) {
            var hero = Hero.hero.tile
            var open = Queue.new()
            var count = Queue.new()
            var max_count = 7 + __loudness
            open.push(Vec2.new(hero.x, hero.y))
            count.push(0)
            __fill = SparseGrid.new()
            __fill[hero.x, hero.y] = Directions.none_idx
            while(!open.empty()) {
                var next = open.pop()
                var cur_count = count.pop()
                if (cur_count >= max_count) continue // Only look a controlled number of spaces out.
                for(i in 0...4) {
                    var nghb = next + Directions[i]
                    if(Gameplay.current_level.contains(nghb.x, nghb.y) && !__fill.has(nghb.x, nghb.y)) {
                        if (!Gameplay.checkTile(nghb, DType.obstacle, Layer.dungeon) && !Gameplay.checkTile(nghb, SType.items, Layer.shared)) {
                            __fill[nghb.x, nghb.y] = (i + 2) % 4 // Opposite direction 
                            open.push(nghb)
                            count.push(cur_count + 1)
                        }
                    }                     
                }
            }   
        }
    }

    /// Debug render the flood fill algorithm
    static debugRender() { 
        Render.dbgColor(0xFF0000FF)    
        if(__fill != null) { 
            for (x in 0...Gameplay.current_level.width) {
                for (y in 0...Gameplay.current_level.height) {
                    if(__fill.has(x, y)) { 
                        var dr = Directions[__fill[x, y]]
                        var fr = Gameplay.current_level.calculatePos(x, y)
                        var to = Gameplay.current_level.calculatePos(x + dr.x, y + dr.y)
                        Render.dbgLine(fr.x, fr.y, to.x, to.y)
                    }
                }
            }
        }
    }
}

class Amount is Component {
    construct new(amount) {
        _amount = amount
    }

    amount {_amount}
}

import "types" for SType, DType, Layer
import "menu" for Menu
import "hero" for HeroWalking, HeroCasting, HeroCutting, HeroMining, HeroDigging, HeroExploring, Inventory
import "create" for Create
import "dungeon" for Dungeon
import "directions" for Directions
import "gameplay" for Gameplay