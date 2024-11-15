import "xs" for Data, Input, Render
import "xs_ec" for Entity, Component
import "xs_math"for Math, Vec2, Bits
import "xs_tools" for Tools

class Inventory {
    construct new() {
        _contents = {}
    }

    has(key) { _contents.containsKey(key) }

    get(key) { has(key) ? _contents[key] : 0 }

    add(key, amount) {
        add(key, amount, 0)
    }

    add(key, amount, min) { 
        _contents[key] = get(key) + amount
        if (get(key) < min) _contents[key] = min
    }

    set(key, amount) {
        _contents[key] = amount
    }

    contents {_contents}
}

class HeroState {
    enter(hero) {}
    handleInput(hero, action, dir) {}
    exit(hero) {}
}

/// Overworld walking state.
class HeroWalking is HeroState {
    static enter(hero) { }

    static handleInput(hero, action, dir) {
        // Moving has priority.
        if (dir >= 0) {     
            if(hero.checkTile(dir, SType.items, Layer.shared)) {
                collect(hero, dir)
            } else if(hero.checkTile(dir, OType.buildings, Layer.overworld)) {
                visit(hero, dir)
            } else if (!hero.checkTile(dir, OType.hero_block, Layer.overworld)) {
                var pos = hero.tile.pos + Directions[dir]
                if (Gameplay.overworld_level.contains(pos)) hero.move(dir)
            }
        }

        // Open main menu.
        if (action == -1) {
            Menu.openMainMenu()
        }
        
        // Open tool menu.
        if (action == 1) {
            Menu.openToolMenu()
        }

        return null
    }

    static collect(hero, dir) {
        var pos = hero.tile.pos + Directions[dir]
        var t = Gameplay.overworld_overtiles.get(pos)
        if(t != null) {
            var item_flag = t.owner.tag
            var amount = t.owner.get(Amount).amount

            hero.inventory.add(item_flag, amount)
            t.owner.delete()

            Gameplay.message = "Collected %(t.owner.name) x%(amount)"
        }
    }

    static visit(hero, dir) {
        var pos = hero.tile.pos + Directions[dir]
        var t = Gameplay.overworld_overtiles.get(pos)
        if(t != null) {
            var item_flag = t.owner.tag
            
            if (item_flag == OType.shop) Menu.openShopMenu()
            if (item_flag == OType.inn) Menu.openInnMenu()
        }
    }

    static exit(hero) { }
}

/// Overworld casting state.
class HeroCasting is HeroState {
    static enter(hero) { 
        // Find valid location on map.
        for (i in [2, 1, 3, 0]) { // try down, right, left, up
            var target_tile = hero.tile.pos + Directions[i]
            if (Gameplay.overworld_level.contains(target_tile)) {
                var target_icon = Create.toolTarget(target_tile)
                
                // Set sprite based on if water is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.water, Layer.overworld)
                target_icon.tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
                
                break
            }
        }
    }

    static handleInput(hero, action, dir) {
        // Cancel, return to walking.
        if (action == -1) {
            return HeroWalking
        }

        // Confirm, use tool.
        if (action == 1) {
            var target = Entity.withTagInLayer(OType.target_good, Layer.overworld)
            if (target.count > 0) {
                // Store position on overworld.
                hero.prev_overworld_pos = hero.tile.pos
                
                // Determine dungeon difficulty (shore, shallow, or deep water)
                var pos = target[0].get(Gameplay.overworld_overtiles).pos
                var water_type = Gameplay.overworld_level[pos].type

                var difficulty = 0
                if (water_type == OType.pond) difficulty = 1
                if (water_type == OType.pond_deep) difficulty = 2

                // Start dungeon.
                Gameplay.enterDungeon(difficulty)
                return HeroExploring
            }
        }

        // Move target.
        if (dir >= 0) {
            // Check that location is valid on map and not already occupied.
            var d = Directions[dir]
            var target_tile = hero.tile.pos + d
            if (Gameplay.overworld_level.contains(target_tile) && Gameplay.overworld_overtiles.isOpen(target_tile)) {
                // Move target.
                var target_icon = Entity.withTagOverlapInLayer(OType.target_good | OType.target_bad, Layer.overworld)
                target_icon[0].get(Gameplay.overworld_overtiles).place(target_tile)

                // Set sprite based on if water is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.water, Layer.overworld)
                target_icon[0].tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
            }
        }
        return null
    }

    static exit(hero) { 
        var target_icon = Entity.withTagOverlapInLayer(OType.target_good | OType.target_bad, Layer.overworld)
        if (target_icon.count > 0) target_icon[0].delete()
    }
}

/// Hero uses axe to cut down trees on overworld.
class HeroCutting is HeroState {
    static enter(hero) { 
        // Find valid location on map.
        for (i in [2, 1, 3, 0]) { // try down, right, left, up
            var target_tile = hero.tile.pos + Directions[i]
            if (Gameplay.overworld_level.contains(target_tile)) {
                var target_icon = Create.toolTarget(target_tile)
                
                // Set sprite based on if tree is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.trees, Layer.overworld)
                target_icon.tag = (is_targeting_resource ? OType.target_good : OType.target_bad)

                break
            }
        }
    }

    static handleInput(hero, action, dir) {
        // Cancel, return to walking.
        if (action == -1) {
            return HeroWalking
        }

        // Confirm, use tool.
        if (action == 1) {
            var target = Entity.withTagInLayer(OType.target_good, Layer.overworld)
            if (target.count > 0) {
                // Replace tree with grass.
                var pos = target[0].get(Gameplay.overworld_overtiles).pos
                var grass = Tools.pickOne([OType.grass_a, OType.grass_a, OType.grass_b, OType.grass_c])
                Gameplay.overworld_level[pos] = LevelTile.new(grass, Layer.overworld)

                // Add wood to inventory.
                var amount = Tools.random.int(1, 3)
                hero.inventory.add(SType.i_wood, amount)

                // Reduce tool durability.
                hero.inventory.add(SType.i_axe, -1)
                var durability = hero.inventory.get(SType.i_axe)

                Gameplay.message = "Gained wood x%(amount). Axe lost durability (%(durability)/10)"

                return HeroWalking
            }
        }

        // Move target.
        if (dir >= 0) {
            // Check that location is valid on map and not already occupied.
            var d = Directions[dir]
            var target_tile = hero.tile.pos + d
            if (Gameplay.overworld_level.contains(target_tile) && Gameplay.overworld_overtiles.isOpen(target_tile)) {
                // Move target.
                var target_icon = Entity.withTagOverlapInLayer(OType.target_good | OType.target_bad, Layer.overworld)
                target_icon[0].get(Gameplay.overworld_overtiles).place(target_tile)

                // Set sprite based on if tree is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.trees, Layer.overworld)
                target_icon[0].tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
            }
        }
        return null
    }

    static exit(hero) { 
        var target_icon = Entity.withTagOverlapInLayer(OType.target_good | OType.target_bad, Layer.overworld)
        if (target_icon.count > 0) target_icon[0].delete()
    }
}

/// Hero uses pickaxe to mine rocks for gems on overworld.
class HeroMining is HeroState {
    static enter(hero) { 
        // Find valid location on map.
        for (i in [2, 1, 3, 0]) { // try down, right, left, up
            var target_tile = hero.tile.pos + Directions[i]
            if (Gameplay.overworld_level.contains(target_tile)) {
                var target_icon = Create.toolTarget(target_tile)
                
                // Set sprite based on if rock is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.rocks, Layer.overworld)
                target_icon.tag = (is_targeting_resource ? OType.target_good : OType.target_bad)

                break
            }
        }
    }

    static handleInput(hero, action, dir) {
        // Cancel, return to walking.
        if (action == -1) {
            return HeroWalking
        }

        // Confirm, use tool.
        if (action == 1) {
            var target = Entity.withTagInLayer(OType.target_good, Layer.overworld)
            if (target.count > 0) {
                var pos = target[0].get(Gameplay.overworld_overtiles).pos

                // Get gem type based on rock type. (Same bitflags on different layers!)
                var gem_type = Gameplay.overworld_level[pos].type

                // Replace rock with grass. 
                var grass = Tools.pickOne([OType.grass_a, OType.grass_a, OType.grass_b, OType.grass_c])
                Gameplay.overworld_level[pos] = LevelTile.new(grass, Layer.overworld)

                // Add gem to inventory.
                var amount = Tools.random.int(1, 3)
                hero.inventory.add(gem_type, amount)

                // Reduce tool durability.
                hero.inventory.add(SType.i_pick, -1)
                var durability = hero.inventory.get(SType.i_pick)

                Gameplay.message = "Gained %(Create.getItemName(gem_type)) x%(amount). Pick lost durability (%(durability)/10)"
                
                return HeroWalking
            }
        }

        // Move target.
        if (dir >= 0) {
            // Check that location is valid on map and not already occupied.
            var d = Directions[dir]
            var target_tile = hero.tile.pos + d
            if (Gameplay.overworld_level.contains(target_tile) && Gameplay.overworld_overtiles.isOpen(target_tile)) {
                // Move target.
                var target_icon = Entity.withTagOverlapInLayer(OType.target_good | OType.target_bad, Layer.overworld)
                target_icon[0].get(Gameplay.overworld_overtiles).place(target_tile)

                // Set sprite based on if rock is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.rocks, Layer.overworld)
                target_icon[0].tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
            }
        }
        return null
    }

    static exit(hero) { 
        var target_icon = Entity.withTagOverlapInLayer(OType.target_good | OType.target_bad, Layer.overworld)
        if (target_icon.count > 0) target_icon[0].delete()
    }
}

/// Hero uses shovel to dig in grass and grave soil on overworld.
class HeroDigging is HeroState {
    static enter(hero) { 
        // Find valid location on map.
        for (i in [2, 1, 3, 0]) { // try down, right, left, up
            var target_tile = hero.tile.pos + Directions[i]
            if (Gameplay.overworld_level.contains(target_tile)) {
                var target_icon = Create.toolTarget(target_tile)
                
                // Set sprite based on if diggable soil is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.diggable, Layer.overworld)
                target_icon.tag = (is_targeting_resource ? OType.target_good : OType.target_bad)

                break
            }
        }
    }

    static handleInput(hero, action, dir) {
        // Cancel, return to walking.
        if (action == -1) {
            return HeroWalking
        }

        // Confirm, use tool.
        if (action == 1) {
            var target = Entity.withTagInLayer(OType.target_good, Layer.overworld)
            if (target.count > 0) {
                // Determine if any bones found. Guaranteed when on a grave.
                var pos = target[0].get(Gameplay.overworld_overtiles).pos
                var dig_site_type = Gameplay.overworld_level[pos].type
                var is_on_grave = Bits.checkBitFlagOverlap(dig_site_type, OType.grave_soil)
                
                var chance = Tools.random.int(0, 100)
                var amount = (chance < 5 || is_on_grave ? 1 : 0) * (is_on_grave ? 6 : 1)
                hero.inventory.add(SType.i_wood, amount)
                
                // Replace grass with hole.
                Gameplay.overworld_level[pos] = LevelTile.new(OType.hole, Layer.overworld)

                // Reduce tool durability.
                hero.inventory.add(SType.i_shovel, -1)
                var durability = hero.inventory.get(SType.i_shovel)

                if (amount > 0) {
                    Gameplay.message = "Gained bone x%(amount). Shovel lost durability (%(durability)/10)"
                } else {
                    Gameplay.message = "Gained nothing. Shovel lost durability (%(durability)/10)"
                }

                return HeroWalking
            }
        }

        // Move target.
        if (dir >= 0) {
            // Check that location is valid on map and not already occupied.
            var d = Directions[dir]
            var target_tile = hero.tile.pos + d
            if (Gameplay.overworld_level.contains(target_tile) && Gameplay.overworld_overtiles.isOpen(target_tile)) {
                // Move target.
                var target_icon = Entity.withTagOverlapInLayer(OType.target_good | OType.target_bad, Layer.overworld)
                target_icon[0].get(Gameplay.overworld_overtiles).place(target_tile)

                // Set sprite based on if diggable soil is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.diggable, Layer.overworld)
                target_icon[0].tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
            }
        }
        return null
    }

    static exit(hero) { 
        var target_icon = Entity.withTagOverlapInLayer(OType.target_good | OType.target_bad, Layer.overworld)
        if (target_icon.count > 0) target_icon[0].delete()
    }
}

/// Dungeon walking state.
class HeroExploring is HeroState {
    static enter(hero) { }
    
    static handleInput(hero, action, dir) {
        // Open (limited) main menu - no crafting available.
        if (action == -1) {
            Menu.openMainMenu()
        }

        // Open dungeon menu.
        if (action == 1) {
            Menu.openDungeonMenu()
        }

        // Movement.
        if (dir >= 0) {
            if (hero.checkTile(dir, DType.enemy, Layer.dungeon)) {
                var xp = hero.attack(dir)
                if (xp > 0) {
                    Gameplay.message = "Gained %(xp) XP"
                    hero.addXp(xp)
                }                
            } else if(hero.checkTile(dir, SType.items, Layer.shared)) {
                collect(hero, dir)
            } else if(hero.checkTile(dir, DType.gate, Layer.dungeon)) {
                unlock(hero, dir)
            } else if(!hero.checkTile(dir, DType.hero_block, Layer.dungeon)) {
                hero.move(dir)                
            } else {
                return null
            }    
            hero.loseAir(1)        
            return HeroExploring // Return same state so Hero will return true to gameplay for hero/monster turn loop. True = turn done.
        }
        return null
    }

    static collect(hero, dir) {
        var pos = hero.tile.pos + Directions[dir]
        var t = Gameplay.dungeon_overtiles.get(pos)
        if(t != null) {
            var can_add = true
            var item_flag = t.owner.tag
            var amount = t.owner.get(Amount).amount

            System.print("%(item_flag) | %(SType.i_health)")

            // Tools.
            if (Bits.checkBitFlagOverlap(item_flag, SType.tools)) {
                var durability = hero.inventory.get(item_flag)
                if (durability < 10) {
                    amount = Math.min(amount, 10 - durability) // can't exceed max
                    Gameplay.message = "%(t.owner.name) durability recovered by %(amount) (%(durability + amount)/10)"
                } else {
                    Gameplay.message = "%(t.owner.name) durability already at max"
                    can_add = false
                }

            // Heart.
            } else if (item_flag == SType.i_health) {
                can_add = false
                var hp_recovered = (amount / 10).ceil
                hp_recovered = Math.min(hp_recovered, hero.max_hp - hero.stats.health) // can't exceed max
                hero.stats.health = hero.stats.health + hp_recovered
                Gameplay.message = "Recovered %(hp_recovered) Health (%(hero.stats.health)/%(hero.max_hp))"

            // Bubbles.
            } else if (item_flag == SType.i_bubble) {
                can_add = false
                var air_recovered = hero.max_air - hero.air
                hero.air = hero.air + air_recovered
                Gameplay.message = "Air replenished"
            } else {
                Gameplay.message = "Collected %(t.owner.name) x%(amount)"
            }

            if (can_add) hero.inventory.add(item_flag, amount)
            t.owner.delete()
        }
    }

    static unlock(hero, dir) {
        var pos = hero.tile.pos + Directions[dir]
        var t = Gameplay.dungeon_overtiles.get(pos)
        if (t != null) {
            // Try to remove 1 key from inventory.
            var key = SType.i_key
            if (hero.inventory.get(key) > 0) {
                hero.inventory.add(key, -1)
                t.owner.delete()
                Gameplay.message = "%(hero.owner.name) used 1 key"
            } else {
                Gameplay.message = "%(hero.owner.name) has 0 keys"                
            }
        }
    }
    
    static exit(hero) { }
}



import "menu" for Menu
import "types" for DType, OType, SType, Layer
import "create" for Create
import "dungeon" for Dungeon
import "gameplay" for Gameplay
import "overworld" for Overworld
import "directions" for Directions
import "components" for LevelTile, Stats, Amount