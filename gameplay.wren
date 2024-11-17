import "xs" for Data, Render
import "xs_ec" for Entity
import "xs_math" for Bits
import "xs_tools" for Tools // temp

/// Combines level and character logic to create the gameplay
class Gameplay {
    static heroTurn   { 1 }
    static computerTurn { 2 }

    // World keys.
    static overworld_state  { 0 }
    static dungeon_state    { 1 }
    static gameover_state   { 2 } 

    // World value accessors.
    static worldLevel       { 0 }
    static overTiles        { 1 }
    static underTiles       { 2 }
    static tileColors       { 3 }
    static worldType        { 4 }
    
    static worlds           {__worlds}
    static world_state      {__world_state}

    static overworld_level      {__worlds[overworld_state][worldLevel]}
    static overworld_overtiles  {__worlds[overworld_state][overTiles]}
    static overworld_undertiles {__worlds[overworld_state][underTiles]}
    static overworld_tilecolors {__worlds[overworld_state][tileColors]}
    static overworld_type       {__worlds[overworld_state][worldType]}
    
    static dungeon_level        {__worlds[dungeon_state][worldLevel]}
    static dungeon_overtiles    {__worlds[dungeon_state][overTiles]}
    static dungeon_undertiles   {__worlds[dungeon_state][underTiles]}
    static dungeon_tilecolors   {__worlds[dungeon_state][tileColors]}
    static dungeon_type         {__worlds[dungeon_state][worldType]}

    static current_level        {__worlds[__world_state][worldLevel]}
    static current_overtiles    {__worlds[__world_state][overTiles]}
    static current_undertiles   {__worlds[__world_state][underTiles]}
    static current_tilecolors   {__worlds[__world_state][tileColors]}
    static current_type         {__worlds[__world_state][worldType]}

    static shared_tiles     {__shared_tiles}
    static shared_colors    {__shared_colors}

    // Menu
    static menu_state   { false }
    static menu_index   { 0 }
    static menu_curosr  { 0 }

    static initialize() {
        __font = Render.loadFont("[game]/assets/FutilePro.ttf", 14)
        
        __tileSize = 16
        var tileset = Render.loadImage("[game]/assets/monochrome-transparent_packed.png") // Load the image in a local variable
        var r = 49
        var c = 22

        __shared_tiles = {      
            SType.empty: Render.createGridSprite(tileset, r, c, 253),
            
            SType.player: Render.createGridSprite(tileset, r, c, Tools.pickOne([74, 76, 77])),

            SType.i_key: Render.createGridSprite(tileset, r, c, 571),
            SType.i_coin: Render.createGridSprite(tileset, r, c, 237),
            SType.i_bubble: Render.createGridSprite(tileset, r, c, 574),
            SType.i_health: Render.createGridSprite(tileset, r, c, 529),
            
            SType.i_rod: Render.createGridSprite(tileset, r, c, 0),
            SType.i_axe: Render.createGridSprite(tileset, r, c, 433),
            SType.i_shovel: Render.createGridSprite(tileset, r, c, 287),
            SType.i_pick: Render.createGridSprite(tileset, r, c, 288),

            SType.i_wood: Render.createGridSprite(tileset, r, c, 139),
            SType.i_bone: Render.createGridSprite(tileset, r, c, 139),

            SType.i_rose: Render.createGridSprite(tileset, r, c, 309),
            SType.i_marigold: Render.createGridSprite(tileset, r, c, 310),
            SType.i_iris: Render.createGridSprite(tileset, r, c, 311),

            SType.i_ruby: Render.createGridSprite(tileset, r, c, 219),
            SType.i_amethyst: Render.createGridSprite(tileset, r, c, 219),
            SType.i_peridot: Render.createGridSprite(tileset, r, c, 219),
            
            SType.i_map: Render.createGridSprite(tileset, r, c, 767),
        }

        var player_color = Data.getColor("Player Color")
        var green = Data.getColor("Grass Color")
        var alsoGreen = Data.getColor("Tree Color")
        var blue = Data.getColor("Shallow Water Color")
        var deep_blue = Data.getColor("Deep Water Color")
        var c_rose = Data.getColor("Color Rose")
        var c_marigold = Data.getColor("Color Marigold")
        var c_iris = Data.getColor("Color Iris")
        var c_ruby = Data.getColor("Color Ruby")
        var c_amethyst = Data.getColor("Color Amethyst")
        var c_peridot = Data.getColor("Color Peridot")
        var brown = Data.getColor("Bridge Color")
        var gold = Data.getColor("Gold Color")
        var tool = Data.getColor("Tool Color")
        var health = Data.getColor("Health Color")
        var floor = Data.getColor("Floor Color")
        var c_bone = Data.getColor("Color Bone") //0xD2D2D2FF
        var c_door_key = c_bone

        __shared_colors = {
            SType.empty: 0x00000000,
            
            SType.player: player_color,

            SType.i_key: c_door_key,
            SType.i_coin: gold,
            SType.i_bubble: blue,
            SType.i_health: health,
            
            SType.i_rod: 0x0,
            SType.i_axe: tool,
            SType.i_shovel: tool,
            SType.i_pick: tool,
            
            SType.i_wood: brown,
            SType.i_bone: c_bone,
            
            SType.i_rose: c_rose,
            SType.i_marigold: c_marigold,
            SType.i_iris: c_iris,
            
            SType.i_ruby: c_ruby,
            SType.i_amethyst: c_amethyst,
            SType.i_peridot: c_peridot,

            SType.i_map: brown,
        }

        // "Sheet" to dim overworld and background when dungeon is up.
        __visor = Visor.new(8 + Data.getNumber("Width", Data.system), 8 + Data.getNumber("Height", Data.system))

        // Setup worlds.
        __worlds = {}
        
        // ... Overworld.
        __worlds[overworld_state] = []
        __worlds[overworld_state].add(Overworld.new(34, 18))
        __worlds[overworld_state].add(OverworldTile)
        __worlds[overworld_state].add(
            {
                OType.target_bad: Render.createGridSprite(tileset, r, c, 715),
                OType.target_good: Render.createGridSprite(tileset, r, c, 715),
                
                OType.grass_a: Render.createGridSprite(tileset, r, c, 5),
                OType.grass_b: Render.createGridSprite(tileset, r, c, 1),
                OType.grass_c: Render.createGridSprite(tileset, r, c, 7),

                OType.tree_a: Render.createGridSprite(tileset, r, c, 51),
                OType.tree_b: Render.createGridSprite(tileset, r, c, 52),
                OType.tree_c: Render.createGridSprite(tileset, r, c, 53),

                OType.road: Render.createGridSprite(tileset, r, c, 3),
                OType.bridge: Render.createGridSprite(tileset, r, c, 252),                
                
                OType.pond: Render.createGridSprite(tileset, r, c, 253),
                OType.pond_deep: Render.createGridSprite(tileset, r, c, 253),
                OType.pond_side: Render.createGridSprite(tileset, r, c, 254),
                OType.pond_corner: Render.createGridSprite(tileset, r, c, 255),

                OType.grave_marker: Render.createGridSprite(tileset, r, c, 687),
                OType.grave_soil: Render.createGridSprite(tileset, r, c, 591),

                OType.ruby_rock: Render.createGridSprite(tileset, r, c, 522),
                OType.amethyst_rock: Render.createGridSprite(tileset, r, c, 522),
                OType.peridot_rock: Render.createGridSprite(tileset, r, c, 522),

                OType.hole: Render.createGridSprite(tileset, r, c, 301), 

                OType.shop: Render.createGridSprite(tileset, r, c, 981), 
                OType.inn: Render.createGridSprite(tileset, r, c, 980), 
            }
        )
        __worlds[overworld_state].add(
            {
                OType.target_good: 0x00FF00FF,
                OType.target_bad: 0xFFFF00FF,

                OType.grass_a: green,
                OType.grass_b: green,
                OType.grass_c: green,

                OType.tree_a: alsoGreen,
                OType.tree_b: alsoGreen,
                OType.tree_c: alsoGreen,

                OType.road: 0xFFFFFFFF,
                OType.bridge: brown,
                
                OType.pond: blue,
                OType.pond_deep: deep_blue,
                OType.pond_side: blue,
                OType.pond_corner: blue,

                OType.grave_marker: c_door_key,
                OType.grave_soil: brown,

                OType.ruby_rock: c_ruby,
                OType.amethyst_rock: c_amethyst,
                OType.peridot_rock: c_peridot,

                OType.hole: brown,

                OType.shop: brown, 
                OType.inn: brown,
            }        
        )
        __worlds[overworld_state].add(OType)

        // ... Dungeon.
        __worlds[dungeon_state] = []
        __worlds[dungeon_state].add(Dungeon.new(34, 20))
        __worlds[dungeon_state].add(DungeonTile)
        __worlds[dungeon_state].add(
            {
                DType.floor: Render.createGridSprite(tileset, r, c, 68),
                DType.wall: Render.createGridSprite(tileset, r, c, 843),
                DType.gate: Render.createGridSprite(tileset, r, c, 150),

                DType.e_crab: Render.createGridSprite(tileset, r, c, 270),
                DType.e_eel: Render.createGridSprite(tileset, r, c, 420),
                DType.e_squid: Render.createGridSprite(tileset, r, c, 419),
                DType.e_octo: Render.createGridSprite(tileset, r, c, 417),
                DType.e_gator: Render.createGridSprite(tileset, r, c, 421),
            }
        )
        __worlds[dungeon_state].add(
            {
                DType.floor: floor,
                DType.wall: deep_blue,
                DType.gate: c_door_key,

                DType.e_crab: 0xFFFFFFFF,
                DType.e_eel: 0xFFFFFFFF,
                DType.e_squid: 0xFFFFFFFF,
                DType.e_octo: 0xFFFFFFFF,
                DType.e_gator: 0xFFFFFFFF,
            }        
        )
        __worlds[dungeon_state].add(DType)

        // Start!
        __menu = Menu.new()
        beginGame(0)
    }

    static update(dt) {
        // Clear old messages.
        __timer = __timer - dt 
        if (__timer <= 0) {
            __message = ""
        }

        // Menu blocks game loop from happening.
        if (__menu.update()) return

        // Game loop - overworld and dungeon.
        if (__world_state == overworld_state) {
            // Only hero needs to move.
            Hero.turn()
        } else {            
            // if (__timer <= 0) loopDungeon()
            // Alternate between hero and enemy turns.
            if (__turn == Gameplay.heroTurn) {
                if (Hero.turn()) {
                    __turn = Gameplay.computerTurn
                }
            } else if (__turn == Gameplay.computerTurn) {
                if (__timer <= 0) {
                    var result = Monster.turn()
                    // All enemies completed turn.
                    if (result == 1) { 
                        __turn = Gameplay.heroTurn
                    // Enemy moved - give time for player to process.
                    } else if (result == 2) { 
                        __timer = (__timer <= 0 ? Data.getNumber("Enemy Turn Pause", Data.game) : __timer)
                    }
                }
            }
        }
    }

    /// For showcasing dungeon RNG.
    static loopDungeon() {
        // Destroy all entities still in dungeon (not hero)
        var dungeon_tiles = dungeon_overtiles.getAll()
        for (tile in dungeon_tiles) if (tile.owner.tag != SType.player) tile.owner.delete()

        // Build dungeon.
        var difficulty = Tools.random.int(3)

        // Place hero in dungeon.
        var hero_start = dungeon_level.build(difficulty)
        Hero.hero.tile.place(hero_start)
    }

    /// Starts new dungeon run.
    static enterDungeon(difficulty) {
        message = "You've been pulled under"

        // Set active world.
        __world_state = dungeon_state

        // Place hero in dungeon.
        var hero_start = dungeon_level.build(difficulty)
        swapHeroTile(hero_start, overworld_overtiles, dungeon_overtiles)

        // Remove all keys and maps (items, not data structs).
        Hero.hero.inventory.add(SType.i_key, -10)
        Hero.hero.inventory.add(SType.i_map, -10)

        // Start!
        __turn = heroTurn
    }

    /// Cleans up after a dungeon has been exited.
    static exitDungeon() {
        // Set active world.
        __world_state = overworld_state
       
        // Place hero in overworld.
        var hero_start = Hero.hero.prev_overworld_pos
        swapHeroTile(hero_start, dungeon_overtiles, overworld_overtiles)
        
        // Destroy all entities still in dungeon (not hero)
        var dungeon_tiles = dungeon_overtiles.getAll()
        for (tile in dungeon_tiles) if (tile.owner.tag != SType.player) tile.owner.delete()
    }

    /// Move hero tile from 'from' tilset to 'to' tilset at position.
    static swapHeroTile(pos, from, to) {        
        Hero.hero.owner.remove(from)

        var tile = to.new(pos.x, pos.y)
        Hero.hero.owner.add(tile)

        Hero.hero.reinitialize()

        Hero.hero.resetState(world_state)
    }

    /// When hero uses the bus: load a new overworld.
    static travel() {
        for (e in Entity.entities) if (e.tag != SType.player) e.delete()
        Entity.update(0) // Flush deleted entities out of system.

        var hero_start = overworld_level.build()
        Hero.hero.owner.get(overworld_overtiles).place(hero_start)

        Gameplay.message = "Traveled to a new land"
    }

    /// When hero dies: erase all entities and begin anew.
    static startOver(start_mode) {
        for (e in Entity.entities) e.delete()
        Entity.update(0) // Flush deleted entities out of system.

        beginGame(start_mode)
    }

    /// Start of every new game, set hero in overworld.
    static beginGame(start_mode) {       
        // Start in overworld state.
        __world_state = overworld_state

        // Create overworld and place hero.
        Create.hero(start_mode)
        var hero_start = overworld_level.build()
        var hero_tile = overworld_overtiles.new(hero_start.x, hero_start.y)
        Hero.hero.owner.add(hero_tile)
        
        // Welcome player.
        __message = "A hero is born"
        __timer = Data.getNumber("Message Time", Data.game)
    }

    /// Finds the combined bitflags of the level and dynamic tiles at location.
    static getFlags(x, y, layer) {
        var flags = 0

        if(current_level.contains(x, y)) {        
            // Undertile flag.
            var under_tile = current_level[x, y]
            if (under_tile.layer == layer) flags = under_tile.type

            // Overtile flag.
            var over_tile = current_overtiles.get(x, y)
            if(over_tile != null && over_tile.owner.layer == layer) flags = (flags | over_tile.owner.tag)
        }

        return flags
    }

    /// Check if the tile in the direction has a given type flag
    static checkTile(pos, type, layer) {
        // Get the flags of the tiles if they match the wanted layer.
        var flags = getFlags(pos.x, pos.y, layer)
        // Compare to the wanted type.
        return Bits.checkBitFlagOverlap(flags, type)
    }

    /// Render the level and the UI
    static render() {
        // Show overworld map.
        renderMap(overworld_state)

        // Place a dimming wall between overworld and dungeon maps.
        if (__world_state == dungeon_state) {
            var color = Data.getColor("Visor Color")
            __visor.render(0, 0, color)
            renderMap(dungeon_state)
        }

        // HUD.
        if(Hero.hero) {
            renderUI()
        }

        // Menu.
        __menu.render()
    }

    /// Draw the tiles on the map. Detemine if tile is from shared layer or default level's layer.
    static renderMap(map) {
        var level = __worlds[map][worldLevel]
        var overtiles = __worlds[map][overTiles]
        var undertiles = __worlds[map][underTiles]
        var colors = __worlds[map][tileColors]

        var s = level.tileSize  
        var sx = (level.width  - 1) * -s / 2
        var sy = (level.height - 1) * -s / 2
        
        for (x in 0...level.width) {
            for (y in 0...level.height) {
                var px = sx + x * s
                var py = sy + y * s
                var level_tile = level[x, y]
                var overtile = overtiles.get(x, y)

                // Render the over tile if it exists.
                if(overtile != null) {
                    var pos = level.calculatePos(overtile)

                    // Find the layer of the tile and use that to figure out the lookup tables to use.
                    var on_shared_layer = (overtile.owner.layer == Layer.shared)
                    var tag = overtile.owner.tag
                    var sprite = (on_shared_layer ? shared_tiles[tag] : undertiles[tag])
                    var color = (on_shared_layer ? shared_colors[tag] : colors[tag])

                    Render.sprite(sprite, pos.x, pos.y, 0.0, 1.0, 0.0, color, 0x0, Render.spriteCenter)

                // Otherwise, render the undertile instead. Undertiles are always on the level's default layer.
                } else {
                    var sprite = undertiles[level_tile.type]
                    var color = colors[level_tile.type]
                    var rot = level_tile.rotation
                    if(sprite != null) {
                        Render.sprite(sprite, px, py, 0.0, 1.0, rot, color, 0x0, Render.spriteCenter)
                    }
                }
            }
            
            if (map == dungeon_state) {
                Monster.debugRender()
                level.debugRender(__font)
            }
        }        
    }

    static message=(v) {
        __message = v
        __timer = Data.getNumber("Message Time", Data.game)
    }

    static renderUI() {
        var hero = Hero.hero
        var stats = hero.owner.get(Stats)
        var message = "Health: %(stats.health)  Damage: %(stats.damage)  Armor: %(stats.armor)"    
        if (__world_state == dungeon_state) {
            message = message + "  Air: %(hero.air)"
        }        
        Render.text(__font, message, 0, -170, 1.0, 0xFFFFFFFF, 0x0, Render.spriteCenter)
        Render.text(__font, __message, 0, 160, 1.0, 0xFFFFFFFF, 0x0, Render.spriteCenter)
    }
}

import "menu" for Menu
import "visor" for Visor
import "types" for SType, OType, DType, Layer
import "create" for Create
import "dungeon" for Dungeon
import "overworld" for Overworld
import "components" for Level, OverworldTile, DungeonTile, Hero, Monster, Stats