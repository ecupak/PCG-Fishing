System.print("09 + Create")


import "xs" for Data, Input, Render
import "xs_math"for Math, Bits, Vec2, Color
import "xs_ec"for Entity, Component
import "xs_components" for Transform, Body, Renderable, Sprite, GridSprite, AnimatedSprite
import "xs_tools" for Tools
import "random" for Random

// No extra imports.
import "types" for SType, OType, DType, Group

/// This class is used to create entities in the game
/// by adding components to them
/// As a game programming pattern, it is a factory class
class Create {

    static getItemName(item_type) {__itemNames[item_type]}

    static initialize() {
        __random = Random.new()
        __id = 0
        
        // Create a list of all the types of monsters
        
        __monsterNames = {
            DType.e_crab: "Crab",
            DType.e_eel: "Eel",
            DType.e_squid: "Squid",
            DType.e_octo: "Octopus",
            DType.e_gator: "Gator",
        }
        __monsterStats = {
            // HP, DMG, ARM, DRP
            DType.e_crab: Stats.new(2, 1, 3, 0.3),
            DType.e_eel: Stats.new(5, 2, 0, 0.4),
            DType.e_squid: Stats.new(5, 3, 1, 0.5),
            DType.e_octo: Stats.new(4, 4, 2, 0.6),
            DType.e_gator: Stats.new(4, 5, 3, 0.7),
        }
        __itemNames = {
            0: "???",
            
            SType.key: "Key",
            SType.coin: "Coin",

            SType.rod: "Rod",
            SType.axe: "Axe",
            SType.shovel: "Shovel",
            SType.pick: "Pick",
            
            SType.bubble: "Bubble",
            SType.health: "Health",

            SType.wood: "Wood",
            SType.bone: "Bone",

            SType.rose: "Rose",
            SType.marigold: "Marigold",
            SType.iris: "Iris",

            SType.ruby: "Ruby",
            SType.amethyst: "Amethyst",
            SType.peridot: "Peridot",

            SType.map: "Map",
        }

        /*
        __itemStats = {
            Type.helmet: Stats.new(0, 0, 1, 0),
            Type.armor: Stats.new(0, 0, 2, 0),
            Type.sword: Stats.new(0, 1, 0, 0),
            Type.food: Stats.new(1, 0, 0, 0)
        }
        */

        __droptables = [
            [SType.coin, SType.health],
            [SType.coin, SType.coin, SType.coin, SType.health, SType.health, SType.axe, SType.pick],
            [SType.health, SType.axe, SType.shovel, SType.pick],
            [SType.health, SType.axe, SType.shovel, SType.pick, SType.rose, SType.marigold, SType.iris],
            [SType.health, SType.rose, SType.marigold, SType.iris, SType.ruby, SType.amethyst, SType.peridot],
            [SType.health, SType.rose, SType.marigold, SType.iris, SType.ruby, SType.amethyst, SType.peridot],
            [SType.bone],
        ]
    }

    static droptables_count {__droptables.count}
    
    static character(x, y) {
        var entity = Entity.new()
        var transform = Transform.new(Gameplay.current_level.calculatePos(x, y))
        entity.add(transform)
        var tile = Gameplay.current_overtiles.new(x, y)
        entity.add(tile)
        return entity
    }

    static hero(start_mode) {
        var entity = Entity.new()

        var transform = Transform.new(Vec2.new())
        entity.add(transform)

        var hero = Hero.new()
        entity.add(hero)

        var stats = Stats.new(10, 4, 0, 0)
        if (start_mode == 1) {
            stats.damage = 3
            stats.armor = 1
        } else if (start_mode == 2) {
            stats.health = 7
            stats.damage = 5
        }
        entity.add(stats)
        
        entity.tag = SType.player
        entity.group = Group.shared
        
        entity.name = "Hero"
        
        return entity
    }

    static toolTarget(pos) {
        var entity = Entity.new()
        
        var tile = Gameplay.current_overtiles.new(pos.x, pos.y)
        entity.add(tile)

        entity.tag = Gameplay.current_type.target_bad
        entity.group = Group.overworld
        entity.name = "Target"

        return entity
    }

    static monster(x, y, type, level, difficulty) {
        var entity = character(x, y)
        var monster = Monster.new(level)
        entity.add(monster)

        var stats = __monsterStats[type].clone()
        stats.health = stats.health * (1 + difficulty)
        stats.damage = stats.damage * (1 + difficulty)
        stats.armor = stats.armor * (1 + difficulty)
        entity.add(stats)
        
        entity.tag = type
        entity.group = Group.dungeon
        entity.name = __monsterNames[type]

        return entity
    }    

    /*
    static equip(x, y) {
        var entity = Entity.new()
        var transform = Transform.new(Gameplay.current_level.calculatePos(x, y))
        entity.add(transform)
        var tile = Gameplay.current_overtiles.new(x, y)
        entity.add(tile)
        var type = Tools.pickOne([
            Type.helmet, Type.armor, Type.sword, Type.food])
        entity.tag = type
        entity.name = __itemNames[type]
        //var stats = __itemStats[type].clone()
        entity.add(stats)
        return entity
    }
    */

    static droptable_item(x, y, drop_table_idx) {
        var entity = Entity.new()
        var transform = Transform.new(Gameplay.current_level.calculatePos(x, y))
        entity.add(transform)
        
        var tile = Gameplay.current_overtiles.new(x, y)
        entity.add(tile)

        var item_type = Tools.pickOne(__droptables[drop_table_idx])
        entity.tag = item_type
        entity.group = Group.shared
        entity.name = __itemNames[item_type]
        
        // Set amount found.
        var item_count = 1

        if (item_type == SType.coin) {
            item_count = (1 + drop_table_idx) * Tools.random.int(2, 5)
        } else if (item_type == SType.health) {
            item_count = Math.min(100, (1 + drop_table_idx) * Tools.random.int(10, 15 + drop_table_idx))
        } else if (Bits.checkBitFlagOverlap(item_type, SType.flowers)) {
            item_count = Tools.random.int(1, drop_table_idx)
        } else if (Bits.checkBitFlagOverlap(item_type, SType.gems)) {
            item_count = Tools.random.int(1, (drop_table_idx / 2).ceil )
        }
        
        var amount = Amount.new(item_count)
        entity.add(amount)

        return entity
    }

    static item(x, y, item_type, item_amount) {
        var entity = Entity.new()
        var transform = Transform.new(Gameplay.current_level.calculatePos(x, y))
        entity.add(transform)
        var tile = Gameplay.current_overtiles.new(x, y)
        entity.add(tile)
        var amount = Amount.new(item_amount)
        entity.add(amount)
        entity.tag = item_type
        entity.group = Group.shared
        entity.name = __itemNames[item_type]
        return entity
    }

    static door(x, y) {
        var entity = Entity.new()
        var tile = Gameplay.dungeon_overtiles.new(x, y)
        entity.add(tile)
        var type = DType.gate
        entity.tag = type
        entity.group = Group.dungeon
        entity.name = "gate"
        return entity
    }

    static building(x, y, type) {
        var entity = Entity.new()

        var tile = Gameplay.overworld_overtiles.new(x, y)
        entity.add(tile)
        
        entity.tag = type
        entity.group = Group.overworld

        entity.name = "Building"

        return entity
    }
}


// Already in module registry.
import "gameplay" for Gameplay
import "components" for Monster, OverworldTile, DungeonTile, Level, Stats, Amount
import "hero" for Hero


System.print("09 - Create")