import "xs" for Data, Render, Input
import "xs_math" for Math, Vec2, Bits
import "xs_tools" for Tools

class Menu {
    /// Open starting menus.
    static openToolMenu() {
        __menu.begin(ToolMenu)
    }

    static openMainMenu() {
        __menu.begin(MainMenu)
    }

    static openShopMenu() {
        __menu.begin(ShopMenu)
    }

    static openInnMenu() {
        __menu.begin(InnMenu)
    }

    static openLevelUpMenu() {
        __menu.begin(LevelUpMenu)
    }

    static openDungeonMenu() {
        __menu.begin(DungeonMenu)
    }

    static openGameOverMenu() {
        __menu.begin(GameOverMenu)
    }

    prev_menu { 0 }
    same_menu { 1 }
    next_menu { 2 }

    /// Create menu. Acts as singleton, can be called by/from anywhere after creation.
    construct new() {
        // Input helpers.
        _buttons = [Input.gamepadDPadUp,
                    Input.gamepadDPadRight,
                    Input.gamepadDPadDown,
                    Input.gamepadDPadLeft ]
        
        _keys = [   Input.keyUp,
                    Input.keyRight,
                    Input.keyDown,
                    Input.keyLeft]
        
        // Menu properties.
        _font = Render.loadFont("[game]/assets/FutilePro.ttf", 14)
        _padding = 2
        _state = null
        _cursor_idx = 0
        _stack = [] // Holds previous menu and cursor_idx
        
        // Singleton.
        __menu = this
    }

    begin(new_state) {        
        _cursor_idx = 0
        _state = new_state.new(this)
        active = true
    }

    /// Update calls the current state's handleInput(). Changes state if a new state is returned.
    update() {
        var action = getAction()
        var dir = getDirection()
        var next_state = _state.handleInput(this, action, dir) // return [(0 back, 1 stay, 2 new), state, cursor_idx] :: thus [false, state, ...] means look at the stack and [false, null, ...] means menu is done.
        
        // Go to next menu.
        if (next_state[0] == next_menu) { // is true
            System.print(next_state)

            _state.exit(this)

            _stack.add([prev_menu, _state, _cursor_idx]) // Store state being left.
            
            _cursor_idx = 0
            _state = next_state[1].new(this) // set and enter new state.        

        // Go back to previous state.
        } else if (next_state[0] == prev_menu) {
            if (next_state[1] == null) {
                _state.exit(this)
                _cursor_idx = 0

                active = false
            } else {
                _state.exit(this)
                _state = next_state[1] // already instanced.
                _cursor_idx = next_state[2]
            }
        }
    }

    /// Draws menu to screen.
    render() {
        _state.render(this)
    }

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

    /// Accessors.
    state {_state}
    
    active {_active}
    active=(v) {_active = v}

    stack {_stack}

    font {_font}
    padding {_padding}
    
    cursor_idx {_cursor_idx}
    cursor_idx=(v) {_cursor_idx = v}
}

class MenuState {
    construct new() {
        _x = 0
        _y = 0
        _center = Vec2.new()
        _idxs = []
    }
    
    handleInput(menu, action, dir) {}
    exit(menu) {}

    render() {
        var s_color = Data.getColor("Menu Shadow Color")
        _sbg.render(x + center.x + 10, y - center.y - 10, s_color)

        var o_color = Data.getColor("Menu Outline Color")
        _obg.render(x + center.x, y - center.y, o_color)

        var color = Data.getColor("Menu Color")
        _bg.render(x + center.x, y - center.y, color)
    }

    createBG() {
        _bg = Visor.new(_width, _height)
        _obg = Visor.new(_width + 2, _height + 2)
        _sbg = Visor.new(_width + 2, _height + 2)
    }

    calculateCenter() {
        _center = -Vec2.new(x, y)        
    }

    getPreviousMenu(menu) {
        System.print("Returning previous menu...")
        
        if (menu.stack.count > 0) {
            return menu.stack.removeAt(menu.stack.count - 1) // Returns the previous menu.
        } else {
            return [menu.prev_menu, null, 0] // Exit menu system.
        }
    }

    getNextIdx(current_idx, max_idx, value) {
        var new_idx = current_idx + value

        System.print(" ")
        System.print("Cur %(current_idx) -> %(new_idx) | Max %(max_idx) | Val %(value)")
        System.print("Idxs: %(idxs)")

        if (new_idx < 0) return 0
        if (new_idx >= idxs.count) return idxs.count - 1

        return new_idx
    }

    // Determined by the menu state.
    width {_width}
    width=(v) {_width = v}

    height {_height}
    height=(v) {_height = v}
    
    center {_center}

    idxs {_idxs}

    // Set after width and height are known.
    bg {_bg} // rectangle shape
    
    x {_x}
    x=(v) {_x = v}    
    
    y {_y}
    y=(v) {_y = v}
}

class MainMenu is MenuState{
/// The "enter" mode.
    construct new(menu) {
        super()

        _items = []
        _items.add("Inventory")
        if (Gameplay.world_state == Gameplay.overworld_state) _items.add("Crafting")
        // Return
        
        for (i in 0...(_items.count + 1)) idxs.add(i + 1)
        
        _gap = 20

        width = 120
        height = (_items.count + 2) * _gap + menu.padding * 2
        x = 30

        calculateCenter()
        createBG()
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return getPreviousMenu(menu)
        }

        if (action == 1) {
            if (idxs[menu.cursor_idx] == 1) {
                return [2, InventoryMenu, menu.cursor_idx]
            }

            if (idxs[menu.cursor_idx] == 2) {
                //return [2, CraftingMenu, menu.cursor_idx]
                Gameplay.message = "TODO"
            }

            return getPreviousMenu(menu)
        }

        if (dir >= 0) {
            var d = Directions[dir]
            menu.cursor_idx = getNextIdx(menu.cursor_idx, _items.count, -(d.y))
        }

        return [menu.same_menu]
    }

    render(menu) {
        super()
        
        var xi = center.x
        var yi = center.y + (height / 2) - (_gap / 2) - 4 - menu.padding

        // Title
        var count = 0
        Render.text(menu.font, "Menu-", xi - 20, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // List.        
        count = count + 1
        for (item in _items) {
            Render.text(menu.font, item, xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
            count = count + 1
        }
        Render.text(menu.font, "Return", xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
        
        // Cursor.
        Render.text(menu.font, ">", xi - 20, yi - idxs[menu.cursor_idx] * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
    }

    exit(menu) {}
}

class InventoryMenu is MenuState{
/// The "enter" mode.
    construct new(menu) {
        super()

        _show_length = 5
        _start_idx = Math.max(0, menu.cursor_idx - _show_length - 1)
        _items = []
        for (entry in Hero.hero.inventory.contents) {
            if (entry.value > 0 && !Bits.checkBitFlagOverlap(entry.key, SType.tools)) _items.add([Create.getItemName(entry.key), entry.value])
        }
        _items.add("Return")
        
        for (i in 0...(_items.count)) idxs.add(i + 1)
        
        _gap = 20

        width = 140
        height = (_show_length + 1) * _gap + menu.padding * 2
        x = 35

        calculateCenter()
        createBG()
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return getPreviousMenu(menu)
        }

        if (action == 1) {
            if (idxs[menu.cursor_idx] == _items.count) {
                return getPreviousMenu(menu)
            }
        }

        if (dir >= 0) {
            var d = Directions[dir]
            menu.cursor_idx = getNextIdx(menu.cursor_idx, _items.count, -(d.y))
            if (menu.cursor_idx > _start_idx + _show_length - 1) _start_idx = _start_idx + 1
            if (menu.cursor_idx < _start_idx) _start_idx = _start_idx - 1
        }

        return [menu.same_menu]
    }

    render(menu) {
        super()
        
        var xi = center.x
        var yi = center.y + (height / 2) - (_gap / 2) - 4 - menu.padding

        // Title
        var count = 0
        Render.text(menu.font, "Inventory-", xi - 20, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // List.        
        count = count + 1
        var max = Math.min(_items.count, _start_idx + _show_length)
        for (i in _start_idx...(max)) {            
            if (i == _items.count - 1) {
                Render.text(menu.font, "Return", xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
            } else {
                var text = "x%(_items[i][1]) %(_items[i][0])"
                Render.text(menu.font, text, xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
            }
            
            count = count + 1
        }
        
        // Cursor.
        Render.text(menu.font, ">", xi - 20, yi - idxs[menu.cursor_idx - _start_idx] * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
    }

    exit(menu) {}
}

class CraftingMenu is MenuState{
}

class InnMenu is MenuState{
/// The "enter" mode.
    construct new(menu) {
        super()
        _costs = [5 * Hero.her.level]

        _items = []
        _items.add("Room: %(_costs[0]) gp")
        // Return
        
        for (i in 0...(_items.count + 1)) idxs.add(i + 1)
        
        _gap = 20

        width = 140
        height = (_items.count + 2) * _gap + menu.padding * 2
        x = 40

        calculateCenter()
        createBG()
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return getPreviousMenu(menu)
        }

        if (action == 1) {
            if (idxs[menu.cursor_idx] == 1) {
                Hero.hero.inventory.add(SType.i_coin, -(_costs[0]))            
            }

            return getPreviousMenu(menu)
        }

        if (dir >= 0) {
            var d = Directions[dir]
            menu.cursor_idx = getNextIdx(menu.cursor_idx, _items.count + 1, -(d.y))
        }

        return [menu.same_menu]
    }

    render(menu) {
        super()

        idxs.clear()

        var xi = center.x
        var yi = center.y + (height / 2) - (_gap / 2) - 4 - menu.padding

        // Title
        var count = 0
        var gold = Hero.hero.inventory.get(SType.i_coin)
        Render.text(menu.font, "Rent- %(gold) gp", xi - 20, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // List.        
        count = count + 1
        for (i in 0..._items.count) {
            var color = (gold >= _costs[i] ? 0xFFFFFF : 0xA2A2A2FF)
            if (gold >= _costs[i]) idxs.add(count)

            Render.text(menu.font, _items[i], xi, yi - count * _gap, 1.0, color, 0x0, Render.spriteNone)
            count = count + 1
        }
        idxs.add(count)
        Render.text(menu.font, "Return", xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
        
        // Cursor.
        Render.text(menu.font, ">", xi - 20, yi - idxs[menu.cursor_idx] * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
    }

    exit(menu) {}
}

class ShopMenu is MenuState{
/// The "enter" mode.
    construct new(menu) {
        super()
        _costs = [50, 100, 50]

        _items = []
        _items.add("Axe: %(_costs[0]) gp")
        _items.add("Pick: %(_costs[1]) gp")
        _items.add("Shovel: %(_costs[2]) gp")
        // Return
        
        for (i in 0...(_items.count + 1)) idxs.add(i + 1)
        
        _gap = 20

        width = 140
        height = (_items.count + 2) * _gap + menu.padding * 2
        x = 40

        calculateCenter()
        createBG()
    }

    handleInput(menu, action, dir) {
        if (action == -1) {
            return getPreviousMenu(menu)
        }

        if (action == 1) {
            if (idxs[menu.cursor_idx] == 1) {
                Hero.hero.inventory.add(SType.i_coin, -(_costs[0]))
                return getPreviousMenu(menu)
            }

            if (idxs[menu.cursor_idx] == 2) {
                Hero.hero.inventory.add(SType.i_coin, -(_costs[1]))
                return getPreviousMenu(menu)
            }

            if (idxs[menu.cursor_idx] == 3) {
                Hero.hero.inventory.add(SType.i_coin, -(_costs[2]))
                return getPreviousMenu(menu)
            }
            return getPreviousMenu(menu)
        }

        if (dir >= 0) {
            var d = Directions[dir]
            menu.cursor_idx = getNextIdx(menu.cursor_idx, _items.count + 1, -(d.y))
        }

        return [menu.same_menu]
    }

    render(menu) {
        super()

        idxs.clear()

        var xi = center.x
        var yi = center.y + (height / 2) - (_gap / 2) - 4 - menu.padding

        // Title
        var count = 0
        var gold = Hero.hero.inventory.get(SType.i_coin)
        Render.text(menu.font, "Shop- %(gold) gp", xi - 20, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // List.        
        count = count + 1
        for (i in 0..._items.count) {
            var color = (gold >= _costs[i] ? 0xFFFFFF : 0xA2A2A2FF)
            if (gold >= _costs[i]) idxs.add(count)

            Render.text(menu.font, _items[i], xi, yi - count * _gap, 1.0, color, 0x0, Render.spriteNone)
            count = count + 1
        }
        idxs.add(count)
        Render.text(menu.font, "Return", xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
        
        // Cursor.
        Render.text(menu.font, ">", xi - 20, yi - idxs[menu.cursor_idx] * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
    }

    exit(menu) {}
}

class LevelUpMenu is MenuState{
/// The "enter" mode.
    construct new(menu) {
        super()
        _amounts = [Tools.random.int(1, 3), Tools.random.int(1, 3), Tools.random.int(1, 3)]

        _items = []
        _items.add("+%(_amounts[0]) Max HP")
        _items.add("+%(_amounts[1]) Damage")
        _items.add("+%(_amounts[2]) Armor")
        
        for (i in 0...(_items.count)) idxs.add(i + 1)
        
        _gap = 20

        width = 120
        height = (_items.count + 1) * _gap + menu.padding * 2
        x = 30

        calculateCenter()
        createBG()
    }

    handleInput(menu, action, dir) {
        if (action == 1) {
            if (idxs[menu.cursor_idx] == 1) {
                Hero.hero.stats.health = Hero.hero.stats.health + _amounts[0]
                Hero.hero.max_hp = Hero.hero.max_hp + _amounts[0]
                return getPreviousMenu(menu)
            }

            if (idxs[menu.cursor_idx] == 2) {
                Hero.hero.stats.damage = Hero.hero.stats.damage + _amounts[1]
                return getPreviousMenu(menu)
            }

            if (idxs[menu.cursor_idx] == 3) {
                Hero.hero.stats.armor = Hero.hero.stats.armor + _amounts[2]
                return getPreviousMenu(menu)
            }
        }

        if (dir >= 0) {
            var d = Directions[dir]
            menu.cursor_idx = getNextIdx(menu.cursor_idx, _items.count, -(d.y))
        }

        return [menu.same_menu]
    }

    render(menu) {
        super()
        
        var xi = center.x
        var yi = center.y + (height / 2) - (_gap / 2) - 4 - menu.padding

        // Title
        var count = 0
        Render.text(menu.font, "Level %(Hero.hero.level)-", xi - 20, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // List.        
        count = count + 1
        for (item in _items) {
            Render.text(menu.font, item, xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
            count = count + 1
        }
        
        // Cursor.
        Render.text(menu.font, ">", xi - 20, yi - idxs[menu.cursor_idx] * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
    }

    exit(menu) {}
}

class ToolMenu is MenuState {
    /// The "enter" mode.
    construct new(menu) {
        super()
        
        _items = []
        _items.add(["Rod", SType.i_rod])
        _items.add(["Axe", SType.i_axe])
        _items.add(["Pick", SType.i_pick])
        _items.add(["Shovel", SType.i_shovel])
        // Return is final item.
        
        for (i in 0...(_items.count + 1)) idxs.add(i + 1)
        
        _gap = 20

        width = 90
        height = (_items.count + 2) * _gap + menu.padding * 2
        x = 16

        calculateCenter()
        createBG()
    }

    handleInput(menu, action, dir) {
        // Action takes priority.
        if (action == -1) {
            return getPreviousMenu(menu)
        }

        if (action == 1) {
            if (idxs[menu.cursor_idx] == 1) Hero.hero.useRod()
            if (idxs[menu.cursor_idx] == 2) Hero.hero.useAxe()
            if (idxs[menu.cursor_idx] == 3) Hero.hero.usePick()
            if (idxs[menu.cursor_idx] == 4) Hero.hero.useShovel()            
            return getPreviousMenu(menu)
        }

        if (dir >= 0) {
            var d = Directions[dir]
            menu.cursor_idx = getNextIdx(menu.cursor_idx, _items.count, -(d.y))
        }

        return [menu.same_menu]
    }

    render(menu) {
        super()

        idxs.clear()
        
        var xi = center.x
        var yi = center.y + (height / 2) - (_gap / 2) - 4 - menu.padding

        // Title
        var count = 0
        Render.text(menu.font, "Tools-", xi - 20, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // List.
        count = count + 1
        for (pair in _items) {
            var name = pair[0]
            var key = pair[1]
            
            var color = 0xA2A2A2FF            
            if (Hero.hero.inventory.get(key) > 0 || key == SType.i_rod) {
                color = 0xFFFFFFFF
                idxs.add(count)
            }

            Render.text(menu.font, name, xi, yi - count * _gap, 1.0, color, 0x0, Render.spriteNone)
            count = count + 1
        }
        idxs.add(count)
        Render.text(menu.font, "Return", xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // Cursor.
        Render.text(menu.font, ">", xi - 20, yi - idxs[menu.cursor_idx] * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
    }

    exit(menu) {}
}


class DungeonMenu is MenuState {
    /// The "enter" mode.
    construct new(menu) {
        super()
        
        _items = []
        if (Hero.hero.inventory.get(SType.i_map) > 0) {
            _items.add("Don't Use Yet")
        } else {
            _items.add("Don't Have Yet")
        }
        _items.add("Use To Escape")
        
        for (i in 0..._items.count) idxs.add(i + 1) // Account for the position of the title
        
        _gap = 20

        width = 180
        height = (_items.count + 1) * _gap + menu.padding * 2
        x = 60

        calculateCenter()
        createBG()
    }

    handleInput(menu, action, dir) {
        // Action takes priority.
        if (action == -1) {
            return getPreviousMenu(menu)
        }

        if (action == 1) {
            if (idxs[menu.cursor_idx] == 2) Gameplay.exitDungeon()
            return getPreviousMenu(menu)
        }

        if (dir >= 0) {
            var d = Directions[dir]
            menu.cursor_idx = getNextIdx(menu.cursor_idx, _items.count, -(d.y))
        }

        return [menu.same_menu]
    }

    render(menu) {
        super()

        idxs.clear()

        var xi = center.x
        var yi = center.y + (height / 2) - (_gap / 2) - 4 - menu.padding

        // Title
        var count = 0
        Render.text(menu.font, "Map-", xi - 20, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // List.
        count = count + 1
        var color = 0xFFFFFFFF
        Render.text(menu.font, _items[0], xi, yi - count * _gap, 1.0, color, 0x0, Render.spriteNone)
        idxs.add(count)
        
        count = count + 1
        var has_map = (Hero.hero.inventory.get(SType.i_map) > 0)
        color = (has_map ? 0xFFFFFFFF : 0xA2A2A2FF)
        if (has_map) idxs.add(count)
        Render.text(menu.font, _items[1], xi, yi - count * _gap, 1.0, color, 0x0, Render.spriteNone)

        // Cursor.
        Render.text(menu.font, ">", xi - 20, yi - idxs[menu.cursor_idx] * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
    }
    
    exit(menu) {}
}

class GameOverMenu is MenuState {
    /// The "enter" mode.
    construct new(menu) {
        super()
        
        _items = []
        _items.add("Try Again")
        _items.add("Get Better")
        _items.add("Seek Revenge") 
        
        for (i in 0..._items.count) idxs.add(i + 1) // Account for the position of the title
        
        _gap = 20

        width = 150
        height = (_items.count + 1) * _gap + menu.padding * 2
        x = 40

        calculateCenter()
        createBG()
    }

    handleInput(menu, action, dir) {
        // Only 1 way forward.
        if (action == 1) {
            Gameplay.startOver()
            return getPreviousMenu(menu)
        }

        if (dir >= 0) {
            var d = Directions[dir]
            menu.cursor_idx = getNextIdx(menu.cursor_idx, _items.count - 1, -(d.y))
        }

        return [menu.same_menu]
    }

    render(menu) {
        super()

        var xi = center.x
        var yi = center.y + (height / 2) - (_gap / 2) - 4 - menu.padding

        // Title
        var count = 0
        Render.text(menu.font, "Game Over", xi - 20, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)

        // List.
        count = count + 1
        for (name in _items) {
            Render.text(menu.font, name, xi, yi - count * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
            count = count + 1
        }

        // Cursor.
        Render.text(menu.font, ">", xi - 20, yi - idxs[menu.cursor_idx] * _gap, 1.0, 0xFFFFFFFF, 0x0, Render.spriteNone)
    }
        
    exit(menu) {}
}

import "gameplay" for Gameplay
import "hero" for Inventory
import "types" for SType
import "visor" for Visor
import "create" for Create
import "components" for Hero
import "directions" for Directions