System.print("13 + Menus")


import "xs_math" for Vec2, Bits
import "xs_tools" for Tools
import "xs_ec" for Entity

// No extra imports.
import "types" for SType, GType, Group

// For inheritance.
import "menu" for BaseMenu


class MainMenu is BaseMenu {
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        // Fill item list.
        title = "Menu-"
        
        items.add("Character")
        items.add("Gear")
        items.add("Crafting")
        items.add("Inventory")
        items.add("Return")
        
        // Crafting is only allowed while in the overworld.
        _is_crafting_allowed = Gameplay.world_state == Gameplay.overworld_state
        
        // Customize enabled text.
        fn_isEnabled = Fn.new { |i, item| (item != "Crafting" || _is_crafting_allowed) }

        // Size and position of box containing items.
        var size = Vec2.new(120, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-30, 0)

        setMenuData(size, center, offset)
    }
    
    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == items.count - 1) return [menu.prev_menu]
        
            if (cursor_idx == 0) {
                setVisible(false)
                return [menu.next_menu, CharacterMenu, cursor_idx]
            } else if (cursor_idx == 1) {
                setVisible(false)
                return [menu.next_menu, GearMenu, cursor_idx]
            } else if (cursor_idx == 2 && _is_crafting_allowed) {
                setVisible(false)
                return [menu.next_menu, CraftingMenu, cursor_idx]
            } else if (cursor_idx == 3) {
                setVisible(false)
                return [menu.next_menu, InventoryMenu, cursor_idx]
            }
            
        } else if (dir >= 0) {
            moveCursor(dir)
        }
        
        return [menu.same_menu]        
    }
}

class InventoryMenu is BaseMenu{    
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Inventory-"

        // Fill content.
        for (entry in Hero.hero.inventory.contents) {
            if (entry.value > 0 && !Bits.checkBitFlagOverlap(entry.key, SType.tools)) items.add([entry.key, entry.value])
        }
        items.add("Return")
        
        // Customize item parser.
        fn_getText = Fn.new{ |i, item| (i == items.count - 1 ? item : "x%(item[1]) %(Create.getItemName(item[0]))") }

        // Size and position of box containing items.
        var size = Vec2.new(140, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-35, 0)

        setMenuData(size, center, offset)

        // Info screen.
        children.add(InventoryInfoMenu.new(center, size))        
        _info = children[0]
    }

    enter() {
        super()
        updateChild()
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == items.count - 1) return [menu.prev_menu]
        } else if (dir >= 0) {
            moveCursor(dir)
            updateChild()
        }

        return [menu.same_menu]
    }

    updateChild() {
        if (cursor_idx == items.count - 1) {
            _info.setVisible(false)
        } else {
            _info.setVisible(true)
            _info.update(items[cursor_idx][0])
        }
    }
}

class GearMenu is BaseMenu{    
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Gear-"

        // Fill items.
        items = ["Poles", "Bobbers", "Hooks", "Perks", "Return"]
        
        // Size and position of box containing items.
        var size = Vec2.new(140, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-35, 0)

        setMenuData(size, center, offset)
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == 0) return [menu.next_menu, PoleMenu, cursor_idx]
            if (cursor_idx == 1) return [menu.prev_menu]
            if (cursor_idx == 2) return [menu.prev_menu]
            if (cursor_idx == 3) return [menu.prev_menu]            
            return [menu.prev_menu]
        } else if (dir >= 0) {
            moveCursor(dir)
        }

        return [menu.same_menu]
    }
}

class CharacterMenu is BaseMenu{    
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Character-"

        // Fill content.
        items.add([true, "Stats"])
        for (g in [GType.pole, GType.bobber, GType.hook]) {
            var gear = Hero.hero.equipment[g]
            items.add((gear ? [g, gear.name] : [false, "No " + Craft.getBaseName(g)]))
        }
        items.add([true, "Return"])
        
        // Customize item parser. Disable color if equipped.
        fn_getText = Fn.new { |i, item| item[1] }
        fn_isEnabled = Fn.new { |i, item| item[0]}
        
        // Size and position of box containing items.
        var size = Vec2.new(140, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-35, 0)

        setMenuData(size, center, offset)

        // Info screen.
        //children.add(PoleInfoMenu.new(center, size))
        //_info = children[0]
    }

    enter() {
        super()
        //updateChild()
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == items.count - 1) return [menu.prev_menu]
            // Toggle gear window to show bonuses from perks.
            // Toggle stats window to show underlying math (base + bonuses)            
            return [menu.prev_menu]
        } else if (dir >= 0) {
            moveCursor(dir)
            //updateChild()
        }

        return [menu.same_menu]
    }

/*
    updateChild() {
        if (cursor_idx == items.count - 1) {
            _info.setVisible(false)
        } else {
            _info.setVisible(true)            
            _info.update(items[cursor_idx])
        }
    }
    */
}

class PoleMenu is BaseMenu{    
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Poles-"

        // Fill content.
        var poles = Entity.withTagInGroup(GType.pole, Group.gear)
        for (pole in poles) {
            items.add(pole)
        }
        items.add("Return")
        
        // Customize item parser. Disable color if equipped.
        fn_getText = Fn.new { |i, item| (i == items.count - 1 ? item : (item.get(Gear).is_equipped ? "E %(item.name)" : "%(item.name)")) }
        fn_isEnabled = Fn.new { |i, item| (i == items.count - 1 ? true : !item.get(Gear).is_equipped) }
        
        // Size and position of box containing items.
        var size = Vec2.new(140, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-35, 0)

        setMenuData(size, center, offset)

        // Info screen.
        children.add(PoleInfoMenu.new(center, size))        
        _info = children[0]
    }

    enter() {
        super()
        updateChild()
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == items.count - 1) return [menu.prev_menu]
            
            // Equip gear if not already equipped.
            if (!items[cursor_idx].get(Gear).is_equipped) {
                // Create methods for the confirmation menu.
                {
                    var on_ok = Fn.new { 
                        Hero.hero.equipGear(items[cursor_idx])                    
                        return [menu.prev_menu]
                    }
                    var on_cancel = Fn.new {
                        return [menu.prev_menu] 
                    }
                    return [menu.next_menu, ConfirmMenu, cursor_idx, [on_ok, on_cancel, "Equip?", "Yes", "No"]]
                }
            }
        } else if (dir >= 0) {
            moveCursor(dir)
            updateChild()
        }

        return [menu.same_menu]
    }

    updateChild() {
        if (cursor_idx == items.count - 1) {
            _info.setVisible(false)
        } else {
            _info.setVisible(true)            
            _info.update(items[cursor_idx])
        }
    }
}

class InnMenu is BaseMenu {
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        updateTitleAndMoney()

        // Fill content.
        _costs = [5 * Hero.hero.level, 30]

        items.add("Room")
        items.add("Bus")
        items.add("Return")
        
        // Customize item state.
        fn_isEnabled = Fn.new{ |i, item| (i == items.count - 1 ? true : (Hero.hero.inventory.get(SType.coin) >= _costs[i])) }
        fn_getText = Fn.new{ |i, item| (i == items.count - 1 ? item : "%(item): %(_costs[i]) gp") }

        // Size and position of box containing items.
        var size = Vec2.new(130, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-30, 0)

        setMenuData(size, center, offset)
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == 0) {
                Hero.hero.inventory.add(SType.coin, -(_costs[0]))
                Hero.hero.stats.health = Hero.hero.max_hp
                Gameplay.message = "Recovered full health"
                updateTitleAndMoney()
            } else if (cursor_idx == 1) {
                Hero.hero.inventory.add(SType.coin, -(_costs[1]))
                updateTitleAndMoney()
                Gameplay.travel()
                return [menu.exit_menu]
            } else {
                return [menu.prev_menu]
            }
        } else if (dir >= 0) {
            moveCursor(dir)
        }

        return [menu.same_menu]
    }

    updateTitleAndMoney() {
        title = "Inn- (%(Hero.hero.inventory.get(SType.coin)) gp)"

        updateEnabledItems()
    }
}

class ShopMenu is BaseMenu{
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        updateTitleAndShopCosts()

        // Fill content.
        items.add("Axe")
        items.add("Pick")
        items.add("Shovel")
        items.add("Return")
        
        // Customize item state and text.
        fn_isEnabled = Fn.new{ |i, item| (i == items.count - 1 ? true : (Hero.hero.inventory.get(SType.coin) >= _costs[i] && _costs[i] > 0)) }
        fn_getText = Fn.new{ |i, item| (i == items.count - 1 ? item : (_costs[i] > 0 ? "%(item): %(_costs[i]) gp" : "%(item): OK")) }

        // Size and position of box containing items.
        var size = Vec2.new(140, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-40, 0)

        setMenuData(size, center, offset)
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == 0) {
                Hero.hero.inventory.add(SType.coin, -(_costs[0]))
                Hero.hero.inventory.set(SType.axe, 10)
                Gameplay.message = "Restored axe to full durability"                
                updateTitleAndShopCosts()
            } else if (cursor_idx == 1) {
                Hero.hero.inventory.add(SType.coin, -(_costs[1]))
                Hero.hero.inventory.set(SType.pick, 10)
                Gameplay.message = "Restored pick to full durability"
                updateTitleAndShopCosts()
            } else if (cursor_idx == 2) {
                Hero.hero.inventory.add(SType.coin, -(_costs[2]))
                Hero.hero.inventory.set(SType.shovel, 10)
                Gameplay.message = "Restored shovel to full durability"
                updateTitleAndShopCosts()
            } else {
                return [menu.prev_menu]
            }
        } else if (dir >= 0) {
            moveCursor(dir)
        }

        return [menu.same_menu]
    }

    updateTitleAndShopCosts() {
        title = "Repairs- (%(Hero.hero.inventory.get(SType.coin)) gp)"

        _costs = [5, 10, 5]
        var durabilities = [Hero.hero.inventory.get(SType.axe), Hero.hero.inventory.get(SType.pick), Hero.hero.inventory.get(SType.shovel)]
        for (i in 0...durabilities.count) {
            _costs[i] = (10 - durabilities[i]) * _costs[i]
        }

        updateEnabledItems()
    }
}

class LevelUpMenu is BaseMenu{
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Level %(Hero.hero.level)-"

        // Fill items.
        _amounts = [Tools.random.int(8, 13), Tools.random.int(1, 3), Tools.random.int(1, 3)]

        items.add("+%(_amounts[0]) Max HP")
        items.add("+%(_amounts[1]) Damage")
        items.add("+%(_amounts[2]) Armor")
        
        // Size and position of box containing items.
        var size = Vec2.new(120, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-30, 0)

        setMenuData(size, center, offset)        
    }

    handleInput(menu, action, dir) {
        if (action == 1) {
            if (cursor_idx == 0) {
                Hero.hero.stats.health = Hero.hero.stats.health + _amounts[0]
                Hero.hero.max_hp = Hero.hero.max_hp + _amounts[0]
                return [menu.prev_menu]
            } else if (cursor_idx == 1) {
                Hero.hero.stats.damage = Hero.hero.stats.damage + _amounts[1]
                return [menu.prev_menu]
            } else if (cursor_idx == 2) {
                Hero.hero.stats.armor = Hero.hero.stats.armor + _amounts[2]
                return [menu.prev_menu]
            }
        } else if (dir >= 0) {
            moveCursor(dir)
        }

        return [menu.same_menu]
    }
}

class ToolMenu is BaseMenu {
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Action-"

        // Fill items.
        items.add(["Fish", SType.rod])
        items.add(["Cut", SType.axe])
        items.add(["Mine", SType.pick])
        items.add(["Dig", SType.shovel])
        items.add("Return")
        
        // Customize item state and text.
        fn_isEnabled = Fn.new{ |i, item| (i == items.count - 1 || i == 0 ? true : (Hero.hero.inventory.get(item[1]) > 0)) }
        fn_getText = Fn.new{ |i, item| (i == items.count - 1 ? item : "%(item[0])") }        

        // Size and position of box containing items.
        var size = Vec2.new(100, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-18, 0)

        setMenuData(size, center, offset)

        children.add(ToolInfoMenu.new(center, size))
        _info = children[0]
    }

    enter() {
        super()
        updateChild()    
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == 0) Hero.hero.useRod()
            if (cursor_idx == 1) Hero.hero.useAxe()
            if (cursor_idx == 2) Hero.hero.usePick()
            if (cursor_idx == 3) Hero.hero.useShovel()            
            return [menu.exit_menu]
        } else if (dir >= 0) {
            moveCursor(dir)
            updateChild()
        }

        return [menu.same_menu]
    }

    updateChild() {
        if (cursor_idx == items.count - 1) {
            _info.setVisible(false)
        } else {
            _info.setVisible(true)            
            _info.update(items[cursor_idx][1])
        }
    }
}

class DungeonMenu is BaseMenu {
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Map-"

        // Fill items.
        if (Hero.hero.inventory.get(SType.map) > 0) {
            items.add("Don't Use Yet")
        } else {
            items.add("Don't Have Yet")
        }
        items.add("Use To Escape")
        
        // Customize item state and text.
        fn_isEnabled = Fn.new{ |i, item| (i == 0 ? true : (Hero.hero.inventory.get(SType.map) > 0)) }        

        // Size and position of box containing items.
        var size = Vec2.new(154, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-46, 0)

        setMenuData(size, center, offset)        
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == 1) Gameplay.exitDungeon()
            return [menu.exit_menu]
        } else if (dir >= 0) {
            moveCursor(dir)
        }

        return [menu.same_menu]
    }
}

class GameOverMenu is BaseMenu {
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Game Over-"

        // Fill items.
        items.add("Try Again")
        items.add("Get Better")
        items.add("Seek Revenge")
        
        // Size and position of box containing items.
        var size = Vec2.new(150, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-40, 0)

        setMenuData(size, center, offset)        
    }

    handleInput(menu, action, dir) {
        if (action == 1) {
            Gameplay.startOver(cursor_idx)
            return [menu.exit_menu]
        } else if (dir >= 0) {
            moveCursor(dir)
        }

        return [menu.same_menu]
    }
}

class CraftingMenu is BaseMenu{
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Craft-"

        // Fill items.
        items = ["Poles", "Bobbers", "Hooks", "Perks", "Return"]
        
        // Size and position of box containing items.
        var size = Vec2.new(140, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-35, 0)

        setMenuData(size, center, offset)        
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx == 0) {
                setVisible(false)
                return [menu.next_menu, PoleCraftingMenu, cursor_idx]
            } else if (cursor_idx == 1) {
                return [menu.prev_menu]
            } else if (cursor_idx == 2) {
                return [menu.prev_menu]
            } else if (cursor_idx == 3) {
                return [menu.prev_menu]
            } else {
                return [menu.prev_menu]
            }
        } else if (dir >= 0) {
            moveCursor(dir)
        }

        return [menu.same_menu]
    }
}

class PoleCraftingMenu is BaseMenu{
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        title = "Craft Pole-"

        // Fill items.
        var names = Craft.getGearNames(GType.pole)
        for (material in Craft.getMaterials()) {
            items.add([material, names[material]])
        }
        items.add("Return")

        // Customize item state and text.
        fn_isEnabled = Fn.new { |i, item|
            return (i == items.count - 1 ? true : canCraft(item[0]))
        }

        fn_getText = Fn.new{ |i, item| (i == items.count - 1 ? item : item[1]) }
        
        // Size and position of box containing items.
        var size = Vec2.new(150, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-45, 0)

        setMenuData(size, center, offset)

        children.add(PoleCraftingInfoMenu.new(center, size))        
        _info = children[0]
    }

    enter() {
        super()
        updateChild()
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return [menu.prev_menu]
        } else if (action == 1) {
            if (cursor_idx != (items.count - 1) && canCraft(items[cursor_idx][0])) {
                // Create methods for the confirmation menu.
                {
                    var on_ok = Fn.new { 
                        Hero.hero.craft(GType.pole, items[cursor_idx][0])                        
                        return [menu.prev_menu]
                    }
                    var on_cancel = Fn.new {
                        return [menu.prev_menu] 
                    }
                    return [menu.next_menu, ConfirmMenu, cursor_idx, [on_ok, on_cancel, "Craft?", "Yes", "No"]]
                }
            } else {
                return [menu.prev_menu]
            }
        } else if (dir >= 0) {
            moveCursor(dir)
            updateChild()
        }

        return [menu.same_menu]
    }

    updateChild() {
        if (cursor_idx == items.count - 1) {
            _info.setVisible(false)
        } else {
            _info.setVisible(true)
            _info.update(items[cursor_idx][0])
        }
    }

    canCraft(item_type) {
        var costs = Craft.getGearCost(GType.pole, item_type)            
        for (cost in costs) {
            if (Hero.hero.inventory.get(cost[0]) < cost[1]) {
                return false
            }
        }
        return true
    }
}

class ConfirmMenu is BaseMenu {
    construct new(initial_cursor_idx, fwding_args) {
        super(initial_cursor_idx)

        // Only the first 2 arguments are required - what to do on selections.
        _on_ok = fwding_args[0] 
        _on_cancel = fwding_args[1]

        title = fwding_args.count >= 2 ? fwding_args[2] : "Confirm?-"

        // Fill items.
        fwding_args.count >= 3 ? items.add(fwding_args[3]) : items.add("Ok")
        fwding_args.count >= 4 ? items.add(fwding_args[4]) : items.add("Cancel")
        
        // Size and position of box containing items.
        var size = Vec2.new(150, getMinimumHeight())
        var center = Vec2.new(0, 0)
        var offset = Vec2.new(-45, 0)

        setMenuData(size, center, offset)
    }

    handleInput(menu, action, dir) {
        if (action == -1) {            
            return _on_cancel.call()
        } else if (action == 1) {
            if (cursor_idx == 0) {
                return _on_ok.call()
            } else {
                return _on_cancel.call()
            }
        } else if (dir >= 0) {
            moveCursor(dir)            
        }

        return [menu.same_menu]
    }
}


// Already in module registry.
import "gameplay" for Gameplay
import "hero" for Hero, Inventory
import "create" for Create
import "craft" for Craft, Gear

// New modules.
import "submenus" for InventoryInfoMenu, ToolInfoMenu, PoleCraftingInfoMenu, PoleInfoMenu


System.print("13 - Menus")