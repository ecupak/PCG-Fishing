import "xs" for Data, Input, Render
import "xs_ec" for Entity, Component
import "xs_math"for Math, Vec2, Bits
import "xs_tools" for Tools

// For inheritance
import "components" for Character


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
        super(DType.enemy, Group.dungeon, 1)
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
        _inventory = Inventory.new() // regular items and tools
        //_equipment = Equipment.new() // equipped gear
        _equipment = {}
        _state = HeroWalking
        _prev_overworld_pos = Vec2.new()
        _air = 100
        _max_air = 100
        _max_hp = 10
        _xp = 4
        _xp_to_level = 5

        inventory.add(SType.axe, 4)
        inventory.add(SType.pick, 3)
        inventory.add(SType.shovel, 2)

        inventory.add(SType.marigold, 1)
        inventory.add(SType.coin, 50)
        inventory.add(SType.peridot, 1)
        inventory.add(SType.bone, 1)
        inventory.add(SType.rose, 1)
        inventory.add(SType.wood, 6)
        inventory.add(SType.amethyst, 1)
        inventory.add(SType.ruby, 1)
        inventory.add(SType.map, 1)
        inventory.add(SType.iris, 1)

        //RichesPerk.new(this)

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

    // After defeating enemy, gain xp. (Maybe after crafting and collecting items too?)
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

    // While in dungeon, air is consumed.
    loseAir(v) {
        air = air - v
        if (air <= 0) Menu.openGameOverMenu()
    }

    // Gain crafted item.
    craft(part, material) {
        var costs = Craft.getGearCost(part, material)

        for (cost in costs) {
            inventory.add(cost[0], -(cost[1]))
        }

        Craft.gear(part, material)
    }

    equipGear(gear_entity) {
        // Unequip.
        if (_equipment[gear_entity.tag]) {            
            var gear = _equipment[gear_entity.tag].get(Gear)
            gear.is_equipped = false
            
            // Unregister from delegates and remove perks.
            if (gear.primary_perk) {
                owner.get(gear.primary_perk).unregister()
                owner.remove(gear.primary_perk)
            }

            for (perk in gear.accessory_perks) {
                owner.get(perk).unregister()
                owner.remove(perk)
            }

            Entity.update(0) // Force removal before adding new skill and perks.
        }
        
        System.print("Equipped %(gear_entity.name): tag %(gear_entity.tag)")
        
        // Equip.
        {
            _equipment[gear_entity.tag] = gear_entity
            var gear = gear_entity.get(Gear)
            gear.is_equipped = true

            // Add perks gear. Perks register with delegates.
            if (gear.primary_perk) owner.add(gear.primary_perk.new(gear.level))
            for (perk in gear.accessory_perks) owner.add(perk[0].new(perk[1]))
        }
    }

    gainStartingEquipment() {
        //equipGear(Craft.pole(SType.empty))
        equipGear(Craft.pole(SType.wood))
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
    gear {_gear}
    equipment {_equipment}

    max_hp {_max_hp}
    max_hp=(v) {_max_hp = v}

    air {_air}
    air=(v) {_air = v}

    max_air {_max_air}

    prev_overworld_pos { _prev_overworld_pos }
    prev_overworld_pos=(v) { _prev_overworld_pos = v }
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
            if(hero.checkTile(dir, SType.items, Group.shared)) {
                collect(hero, dir)
            } else if(hero.checkTile(dir, OType.buildings, Group.overworld)) {
                visit(hero, dir)
            } else if (!hero.checkTile(dir, OType.hero_block, Group.overworld)) {
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
                var is_targeting_resource = hero.checkTile(target_tile, OType.water, Group.overworld)
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
            var target = Entity.withTagInGroup(OType.target_good, Group.overworld)
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
                var target_icon = Entity.withTagOverlapInGroup(OType.target_good | OType.target_bad, Group.overworld)
                target_icon[0].get(Gameplay.overworld_overtiles).place(target_tile)

                // Set sprite based on if water is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.water, Group.overworld)
                target_icon[0].tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
            }
        }
        return null
    }

    static exit(hero) { 
        var target_icon = Entity.withTagOverlapInGroup(OType.target_good | OType.target_bad, Group.overworld)
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
                var is_targeting_resource = hero.checkTile(target_tile, OType.trees, Group.overworld)
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
            var target = Entity.withTagInGroup(OType.target_good, Group.overworld)
            if (target.count > 0) {
                // Replace tree with grass.
                var pos = target[0].get(Gameplay.overworld_overtiles).pos
                var grass = Tools.pickOne([OType.grass_a, OType.grass_a, OType.grass_b, OType.grass_c])
                Gameplay.overworld_level[pos] = LevelTile.new(grass, Group.overworld)

                // Add wood to inventory.
                var amount = Tools.random.int(1, 3)
                hero.inventory.add(SType.wood, amount)

                // Reduce tool durability.
                hero.inventory.add(SType.axe, -1)
                var durability = hero.inventory.get(SType.axe)

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
                var target_icon = Entity.withTagOverlapInGroup(OType.target_good | OType.target_bad, Group.overworld)
                target_icon[0].get(Gameplay.overworld_overtiles).place(target_tile)

                // Set sprite based on if tree is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.trees, Group.overworld)
                target_icon[0].tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
            }
        }
        return null
    }

    static exit(hero) { 
        var target_icon = Entity.withTagOverlapInGroup(OType.target_good | OType.target_bad, Group.overworld)
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
                var is_targeting_resource = hero.checkTile(target_tile, OType.rocks, Group.overworld)
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
            var target = Entity.withTagInGroup(OType.target_good, Group.overworld)
            if (target.count > 0) {
                var pos = target[0].get(Gameplay.overworld_overtiles).pos

                // Get gem type based on rock type. (Same bitflags on different layers!)
                var gem_type = Gameplay.overworld_level[pos].type

                // Replace rock with grass. 
                var grass = Tools.pickOne([OType.grass_a, OType.grass_a, OType.grass_b, OType.grass_c])
                Gameplay.overworld_level[pos] = LevelTile.new(grass, Group.overworld)

                // Add gem to inventory.
                var amount = Tools.random.int(1, 3)
                hero.inventory.add(gem_type, amount)

                // Reduce tool durability.
                hero.inventory.add(SType.pick, -1)
                var durability = hero.inventory.get(SType.pick)

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
                var target_icon = Entity.withTagOverlapInGroup(OType.target_good | OType.target_bad, Group.overworld)
                target_icon[0].get(Gameplay.overworld_overtiles).place(target_tile)

                // Set sprite based on if rock is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.rocks, Group.overworld)
                target_icon[0].tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
            }
        }
        return null
    }

    static exit(hero) { 
        var target_icon = Entity.withTagOverlapInGroup(OType.target_good | OType.target_bad, Group.overworld)
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
                var is_targeting_resource = hero.checkTile(target_tile, OType.diggable, Group.overworld)
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
            var target = Entity.withTagInGroup(OType.target_good, Group.overworld)
            if (target.count > 0) {
                // Determine if any bones found. Guaranteed when on a grave.
                var pos = target[0].get(Gameplay.overworld_overtiles).pos
                var dig_site_type = Gameplay.overworld_level[pos].type
                var is_on_grave = Bits.checkBitFlagOverlap(dig_site_type, OType.grave_soil)
                
                var chance = Tools.random.int(0, 100)
                var amount = (chance < 5 || is_on_grave ? 1 : 0) * (is_on_grave ? 6 : 1)
                hero.inventory.add(SType.wood, amount)
                
                // Replace grass with hole.
                Gameplay.overworld_level[pos] = LevelTile.new(OType.hole, Group.overworld)

                // Reduce tool durability.
                hero.inventory.add(SType.shovel, -1)
                var durability = hero.inventory.get(SType.shovel)

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
                var target_icon = Entity.withTagOverlapInGroup(OType.target_good | OType.target_bad, Group.overworld)
                target_icon[0].get(Gameplay.overworld_overtiles).place(target_tile)

                // Set sprite based on if diggable soil is below.
                var is_targeting_resource = hero.checkTile(target_tile, OType.diggable, Group.overworld)
                target_icon[0].tag = (is_targeting_resource ? OType.target_good : OType.target_bad)
            }
        }
        return null
    }

    static exit(hero) { 
        var target_icon = Entity.withTagOverlapInGroup(OType.target_good | OType.target_bad, Group.overworld)
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
            if (hero.checkTile(dir, DType.enemy, Group.dungeon)) {
                var xp = hero.attack(dir)
                if (xp > 0) {
                    Gameplay.message = "Gained %(xp) XP"
                    hero.addXp(xp)
                }                
            } else if(hero.checkTile(dir, SType.items, Group.shared)) {
                collect(hero, dir)
            } else if(hero.checkTile(dir, DType.gate, Group.dungeon)) {
                unlock(hero, dir)
            } else if(!hero.checkTile(dir, DType.hero_block, Group.dungeon)) {
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

            System.print("%(item_flag) | %(SType.health)")

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
            } else if (item_flag == SType.health) {
                can_add = false
                var hp_recovered = (amount / 10).ceil
                hp_recovered = Math.min(hp_recovered, hero.max_hp - hero.stats.health) // can't exceed max
                hero.stats.health = hero.stats.health + hp_recovered
                Gameplay.message = "Recovered %(hp_recovered) Health (%(hero.stats.health)/%(hero.max_hp))"

            // Bubbles.
            } else if (item_flag == SType.bubble) {
                can_add = false
                var air_recovered = hero.max_air - hero.air
                hero.air = hero.air + air_recovered
                Gameplay.message = "Air replenished"
            
            // Coins.
            } else if (item_flag == SType.coin) {
                // Trigger any on_coin_pickup perks.
                var bonus = 0
                hero.onCoinPickup.notify(hero, [amount, bonus])

                System.print("Coin: base %(amount) + bonus %(bonus)")
                amount = amount + bonus
                Gameplay.message = "Collected %(t.owner.name) x%(amount)"

            // Other.
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
            var key = SType.key
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
import "types" for DType, OType, SType, Group
import "create" for Create
import "craft" for Craft
import "dungeon" for Dungeon
import "gameplay" for Gameplay
import "overworld" for Overworld
import "directions" for Directions
import "components" for LevelTile, Stats, Amount, Gear