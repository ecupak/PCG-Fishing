System.print("05 + Components")


import "xs_ec" for Entity, Component
import "xs" for Data, Input, Render
import "xs_math"for Math, Bits, Vec2, Color
import "xs_containers" for Grid, SparseGrid, Queue, RingBuffer
import "xs_tools" for Tools

// No extra imports.
import "types" for SType, DType, Group
import "delegate" for PerkTrigger
import "directions" for Directions


/// Tile data for the "static" layer (vs the "dynamic" tiles on top)
class LevelTile { // under tile
    construct new() {
        _type = 0
        _group = 0
        _rotation = 0
    }

    construct new(type, group) {
        _type = type
        _group = group
        _rotation = 0
    }

    construct new(type, group, rotation) {
        _type = type
        _group = group
        _rotation = rotation
    }

    type {_type}
    group {_group}
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
        _max_hp = health
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
        _max_hp = _max_hp + other.max_hp
        _health = _health + other.health
        _damage = _damage + other.damage
        _armor = _armor + other.armor
        _drop = _drop + other.drop
    }

    max_hp { _max_hp }
    health { _health }
    damage { _damage }
    armor { _armor }
    drop { _drop }

    max_hp=(v) { _max_hp = v }
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

        _onCoinPickup = PerkTrigger.new()
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

    /// Move the tile in the direction
    move(dir) {
        _tile.move(Directions[dir])
    }

    /// Attack the tile in the direction
    attack(dir) {
        var gained_xp = 0

        System.print("Attacking from position [%(_tile.x), %(_tile.y)] in direction [%(Directions[dir])]")

        var pos = _tile.pos + Directions[dir]
        if (checkTile(pos, _attackable[0], _attackable[1])) {
            var other = Gameplay.current_overtiles.get(pos.x, pos.y)
            var stats = other.owner.get(Stats)
        
            // Get components of the attacker and defender.
            var attacker_perks = owner.components
            var defender_perks = other.owner.components

            // Deal damage.            
            var damage = Math.max(1, _stats.damage - stats.armor) // always deal 1 dmg
            stats.health = stats.health - damage
            Gameplay.message = "%(owner.name) deals %(damage) damage to %(other.owner.name)"

            // Check for death.
            if (stats.health <= 0) {
                Gameplay.message = "%(owner.name) kills %(other.owner.name)"                
                other.owner.delete()
                gained_xp = other.owner.get(Character).level + 1

                // Drop loot.
                if (Tools.random.float(0.0, 1.0) < stats.drop) Create.droptable_item(pos.x, pos.y, level)                
            }
        }

        // Return xp.
        return gained_xp
    }

    /// A list of dispatchers.
    onCoinPickup {_onCoinPickup}

    /// Get the tile of the character
    tile { _tile }
    stats {_stats}

    attackable {_attackable}
    level {_level}
    level=(v) {_level = v}
}


/// A class that represents the monsters in the game.
/// The monsters are controlled by the computer and the class
/// contains the logic to play a turn for all the monsters.
class Monster is Character {
    /// Create a new monster component
    construct new(level) {
        super(SType.player, Group.shared, level)
        
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
            } else if(!checkTile(dir, DType.monster_block, Group.dungeon)) {
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

            var entities = Entity.withTagOverlapInGroup(DType.enemy, Group.dungeon)
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
        if (__ring == null) {
            __ring = RingBuffer.new(4, 0)            
            __ring.push(1)
            __ring.push(2)
            __ring.push(3)
        }
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
                    var dir = __ring.read()
                    var nghb = next + Directions[dir]
                    if(Gameplay.current_level.contains(nghb.x, nghb.y) && !__fill.has(nghb.x, nghb.y)) {
                        if (!Gameplay.checkTile(nghb, DType.obstacle, Group.dungeon) && !Gameplay.checkTile(nghb, SType.items, Group.shared)) {
                            __fill[nghb.x, nghb.y] = (dir + 2) % 4 // Opposite direction 
                            open.push(nghb)
                            count.push(cur_count + 1)
                        }
                    }                     
                }
                __ring.read() // Cause the next direction/neighbor loop to start at a different index. Will still complete all checks.
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


class Gear is Component {
    construct new(id, part, material, perk, perk_slots) {
        _id = id
        _part = part
        _material = material

        _primary_perk = perk
        System.print("Gear perk: %(RichesPerk)")

        _perk_slots = perk_slots
        _accessory_perks = []
        
        _level = 1        
        _is_equipped = false
    }

    add(perk) {
        if (_accessory_perks.count == _slots) return false
        // Add to gear's list of perk data.
        _accessory_perks.add([perk.skill, perk.level])

        // If currently equipped, auto-add as perk component.
        if (_is_equipped) Hero.hero.owner.add(perk.skill.new(perk.level))

        return true
    }

    id {_id}
    part {_part}
    material {_material}

    primary_perk {_primary_perk}
    perk_slots {_perk_slots}    
    accessory_perks {_accessory_perks}

    level {_level}
    is_equipped {_is_equipped}
    is_equipped=(v) {_is_equipped = v}    
}


// Already in module registry.
import "gameplay" for Gameplay

// New modules.
import "hero" for Hero // must be imported before create

// Now in module registry from "hero".
import "create" for Create
import "craft" for Craft
import "perks" for RichesPerk
import "menu" for Menu // imports Hero
import "dungeon" for Dungeon // imports create

//import "hero" for Inventory, Equipment, HeroWalking, HeroCasting, HeroCutting, HeroMining, HeroDigging, HeroExploring


System.print("05 - Components")