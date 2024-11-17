import "xs_math" for Vec2, Bits
import "xs_tools" for Tools
import "menu" for BaseMenu

class MainMenu is BaseMenu {
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        // Fill item list.
        title = "Menu-"
        
        items.add("Inventory")
        if (Gameplay.world_state == Gameplay.overworld_state) items.add("Crafting")
        items.add("Return")
        
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
            if (cursor_idx == 0) {
                setVisible(false)
                return [menu.next_menu, InventoryMenu, cursor_idx]
            } else if (cursor_idx == 1) {
                setVisible(false)
                return [menu.next_menu, CraftingMenu, cursor_idx]
            } else if (cursor_idx == 2) {
                return [menu.prev_menu]
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

class InnMenu is BaseMenu {
/// 1-time setup happens here. Repeated events when this becomes the active menu go under "enter()".
    construct new(initial_cursor_idx) {
        super(initial_cursor_idx)

        updateTitleAndMoney()

        // Fill content.
        _costs = [5 * Hero.hero.level, 30]

        items.add("Room")
        items.add("Bus")
        items.add("Return")
        
        // Customize item state.
        fn_isEnabled = Fn.new{ |i, item| (i == items.count - 1 ? true : (Hero.hero.inventory.get(SType.i_coin) >= _costs[i])) }
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
                Hero.hero.inventory.add(SType.i_coin, -(_costs[0]))
                Hero.hero.stats.health = Hero.hero.max_hp
                Gameplay.message = "Recovered full health"
                updateTitleAndMoney()
            } else if (cursor_idx == 1) {
                Hero.hero.inventory.add(SType.i_coin, -(_costs[1]))
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
        title = "Inn- (%(Hero.hero.inventory.get(SType.i_coin)) gp)"

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
        fn_isEnabled = Fn.new{ |i, item| (i == items.count - 1 ? true : (Hero.hero.inventory.get(SType.i_coin) >= _costs[i] && _costs[i] > 0)) }
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
                Hero.hero.inventory.add(SType.i_coin, -(_costs[0]))
                Hero.hero.inventory.set(SType.i_axe, 10)
                Gameplay.message = "Restored axe to full durability"                
                updateTitleAndShopCosts()
            } else if (cursor_idx == 1) {
                Hero.hero.inventory.add(SType.i_coin, -(_costs[1]))
                Hero.hero.inventory.set(SType.i_pick, 10)
                Gameplay.message = "Restored pick to full durability"
                updateTitleAndShopCosts()
            } else if (cursor_idx == 2) {
                Hero.hero.inventory.add(SType.i_coin, -(_costs[2]))
                Hero.hero.inventory.set(SType.i_shovel, 10)
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
        title = "Repairs- (%(Hero.hero.inventory.get(SType.i_coin)) gp)"

        _costs = [5, 10, 5]
        var durabilities = [Hero.hero.inventory.get(SType.i_axe), Hero.hero.inventory.get(SType.i_pick), Hero.hero.inventory.get(SType.i_shovel)]
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
        items.add(["Fish", SType.i_rod])
        items.add(["Cut", SType.i_axe])
        items.add(["Mine", SType.i_pick])
        items.add(["Dig", SType.i_shovel])
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
        if (Hero.hero.inventory.get(SType.i_map) > 0) {
            items.add("Don't Use Yet")
        } else {
            items.add("Don't Have Yet")
        }
        items.add("Use To Escape")
        
        // Customize item state and text.
        fn_isEnabled = Fn.new{ |i, item| (i == 0 ? true : (Hero.hero.inventory.get(SType.i_map) > 0)) }        

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
                return [menu.prev_menu]//return [menu.next_menu, BobberCraftingMenu, cursor_idx]
            } else if (cursor_idx == 2) {
                return [menu.prev_menu]//return [menu.next_menu, HookCraftingMenu, cursor_idx]
            } else if (cursor_idx == 3) {
                return [menu.prev_menu]//return [menu.next_menu, PerkCraftingMenu, cursor_idx]
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
        var names = PartMaker.getPartNames(SType.i_pole)
        for (material in PartMaker.getMaterials()) {
            items.add([material, names[material]])
        }
        items.add("Return")

        // Customize item state and text.
        fn_isEnabled = Fn.new { |i, item|
            if (i == items.count - 1 ) return true

            var costs = PartMaker.getCraftingCost(SType.i_pole, item[0])
            System.print(costs)
            for (cost in costs) {
                if (Hero.hero.inventory.get(cost[0]) < cost[1]) {
                    return false
                }
            }
            return true
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
            return [menu.prev_menu]
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

import "hero" for Inventory
import "types" for SType
import "create" for Create
import "parts" for PartMaker
import "gameplay" for Gameplay
import "components" for Hero
import "submenus" for InventoryInfoMenu, ToolInfoMenu, PoleCraftingInfoMenu