import "xs" for Data, Render, Input
import "xs_math" for Math, Vec2

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
    exit_menu { 3 }

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
        
        // Holds previous menu information
        _menus = [] 

        // Current/Active menu.
        _menu = null
        
        // Singleton.
        __menu = this
    }

    /// Menu initializer, called by outside classes accessing singleton.
    begin(new_menu) {
        if (BaseMenu.is_initialized != true) BaseMenu.initialize()
        if (SubMenu.is_initialized != true) SubMenu.initialize()

        _menus.add(new_menu.new(0))
        _menu = _menus[_menus.count - 1]
        _menu.enter()
        
        _active = true
    }

    /// Update calls the current menu's handleInput().
    update() {
        if (!_active) return false

        // Get player input and menu results.
        var action = getAction()
        var dir = getDirection()
        var menu_result = _menu.handleInput(this, action, dir) // Returns [next, next menu, current menu cursor index] | [previous] | [same] | [exit]
        
        // Process results...
        // - Go to next menu.
        if (menu_result[0] == next_menu) {
            _menu.exit()
            _menus.add(menu_result[1].new(0)) // Set new state.
            _menu = _menus[_menus.count - 1]
            _menu.enter()

        // - Go back to previous menu.
        } else if (menu_result[0] == prev_menu) {
            _menu.exit()
            _menus.removeAt(_menus.count - 1)

            // Confirm a previous menu exists.
            if (_menus.count > 0) {
                _menu = _menus[_menus.count - 1]
                _menu.enter()

            // Otherwise, exit menu system.
            } else {
                _menu = null
                _active = false
            }        
        } else if (menu_result[0] == exit_menu) {
            _menu.exit()
            _menus.clear()
            _menu = null
            _active = false
        }

        return true
    }

    /// Draws menu(s) to screen.
    render() {
        for (m in _menus) m.render()
    }

    /// Get the direction of the player input
    getDirection() {
        for(dir in 0...4) if(Input.getButtonOnce(_buttons[dir]) || Input.getKeyOnce(_keys[dir])) return dir
        return -1
    }

    /// Get the action of the player input.
    getAction() {
        if (Input.getButtonOnce(Input.gamepadButtonSouth) || Input.getKeyOnce(Input.keyE)) return 1
        if (Input.getButtonOnce(Input.gamepadButtonWest) || Input.getKeyOnce(Input.keyQ)) return -1
        return 0
    }
}

class BaseMenu {
    static is_initialized { __is_initialized }

    static initialize() {
        __font = Render.loadFont("[game]/assets/FutilePro.ttf", 14)
        __is_initialized = true
    }

    construct new(cursor_idx) {
        // The items.
        _items = []

        // The index of the item the cursor is at.
        _cursor_idx = cursor_idx

        // Max items that can be viewed at once.
        _view_size = 5

        // What index to start showing items from. Render item list using this start index to
        // make menus with item counts larger than the view size appear to scroll.
        _start_idx = 0
                
        // Spacing parameters used for text layout.
        _gap = 20
        _padding = 3

        // A menu may have child menus. These are things like an information window.
        // Child menus do not take focus or get the cursor. They are only rendered when their parent menu renders.
        _children = []

        // Render stuff.
        _visible = false // Can not be rendered if item list is empty.
        _title_color = 0xFFFFFFFF
        _enabled_color = 0xFFFFFFFF
        _disabled_color = 0xA2A2A2FF
        _text_colors = [] // Color of each item based on the idxs list.

        // Customizable methods to set enabled items and text for items.
        _fn_isEnabled = Fn.new{ |i, item| true }
        _fn_getText = Fn.new{ |i, item| (i == _items.count - 1 ? item : "%(item)") }
    }
    
    /// Happens when menu becomes active.
    enter() {        
        updateEnabledItems()
        setVisible(true)
    }

    /// Player selection and cursor movement.
    handleInput(menu, action, dir) {}

    /// Show menu. Uses customizable functions to get the item text and color.
    render() {
        if (!_visible) return

        // Background boxes.
        {
            // Render dropshadow.
            var s_color = Data.getColor("Menu Shadow Color")
            _sbg.render(_center.x + 10, _center.y - 10, s_color)

            // Render "border" next.
            var o_color = Data.getColor("Menu Outline Color")
            _obg.render(_center.x, _center.y, o_color)

            // Render the background last.
            var color = Data.getColor("Menu Color")
            _bg.render(_center.x, _center.y, color)
        }

        // Content.
        {
            var text_line = 0
            var text_start = _offset.y + (_size.y / 2) - (_gap / 2) - 4 - _padding

            // Title
            if (_title != null) {
                Render.text(__font, _title, _offset.x - 20, text_start - text_line * _gap, 1.0, _title_color, 0x0, Render.spriteNone)
                text_line = text_line + 1
            }

            // List.
            var end_idx = Math.min(_items.count, _start_idx + _view_size)
            for (i in _start_idx...end_idx) {
                Render.text(__font, _fn_getText.call(i, _items[i]), _offset.x, text_start - text_line * _gap, 1.0, _text_colors[i], 0x0, Render.spriteNone)            
                text_line = text_line + 1
            }

            // Cursor.
            Render.text(__font, ">", _offset.x - 20, text_start - _gap - (_cursor_idx - _start_idx) * _gap, 1.0, _enabled_color, 0x0, Render.spriteNone)
        }

        // Child menus.
        for (c in _children) c.render()
    }

    /// What happens when the menu is removed. Removes child menus.
    exit() {
        _children.clear()
    }
    
    /// Sets what items are enabled/disabled using a customizable function.
    /// Called during 'enter()', but can be called whenever the item states might change.
    updateEnabledItems() {
        _text_colors.clear()

        for (i in 0..._items.count) {
            if (_fn_isEnabled.call(i, _items[i])) {        
                _text_colors.add(_enabled_color)
            } else {
                _text_colors.add(_disabled_color)
            }
        }
    }

    /// Called during derived class constructor, sets the menu boxes.    
    setMenuData(size, center, offset) {
        _size = size
        _center = center
        _offset = offset
        
        _bg = Visor.new(size.x, size.y)
        _obg = Visor.new(size.x + 2, size.y + 2)
        _sbg = Visor.new(size.x + 2, size.y + 2)
    }

    /// Sets menu visiblity. Use to hide old menus. Or continue showing them for a cascading effect (need to adjust box positions as well).
    /// Can not be visible if there are no items to show.
    setVisible(is_visible) {
        if (is_visible && _items.count > 0) {
            _visible = true
        } else {
            _visible = false
        }
    }

    /// Moves cursor up/down. If list is scrolling, moves items up/down by 1 as long as cursor is at end of visible range.
    moveCursor(dir) {
        _cursor_idx = _cursor_idx - Directions[dir].y
        
        // Keep within bounds of enabled items.
        if (_cursor_idx < 0) _cursor_idx = 0
        if (_cursor_idx >= _items.count) _cursor_idx = _items.count - 1
        
        // Update starting index for rendering items.
        if (_cursor_idx > _start_idx + _view_size - 1) _start_idx = _start_idx + 1
        if (_cursor_idx < _start_idx) _start_idx = _start_idx - 1
    }
    
    /// Returns the smallest height to fit the items. If item count is greater than the view size, uses the view size.
    getMinimumHeight() {
        var count = (items.count > view_size ? view_size : items.count)
        return gap * (count + 1) + padding * 2
    }

    // Box positioning.
    size {_size}
    center {_center}

    // Used to help place text.    
    gap {_gap}
    padding {_padding}
    view_size {_view_size}

    // Tracks menu items and cursor.
    items {_items}
    items=(v) {_items = v}

    cursor_idx {_cursor_idx}
    cursor_idx=(v) {_cursor_idx = v}

    // Custom functions for rendering.
    fn_getText=(v) {_fn_getText = v}
    fn_isEnabled=(v) {_fn_isEnabled = v}

    // Render settings.
    title=(v) {_title = v}

    title_color {_title_color}
    title_color=(v) {_title_color = v}

    enabled_color {_enabled_color}
    enabled_color=(v) {_enabled_color = v}

    disabled_color {_disabled_color}
    disabled_color=(v) {_disabled_color = v}

    // Child menus.
    children {_children}
}

/// Screen that appears alongside menu. Usually used to display additional information, but not actively navigated.
/// Cannot scroll.
class SubMenu {
    static is_initialized { __is_initialized }

    static initialize() {
        __font = Render.loadFont("[game]/assets/FutilePro.ttf", 14)
        __is_initialized = true
    }

    construct new() {
        // The items.
        _items = []

        // Spacing parameters used for text layout.
        _gap = 20
        _padding = 3

        // Render stuff.
        _visible = false // Can not be rendered if item list is empty.
        _title_color = 0xFFFFFFFF
        _enabled_color = 0xFFFFFFFF
        _disabled_color = 0xA2A2A2FF
        _text_colors = [] // Color of each item based on the idxs list.

        // Current item index.
        _i_start = 0
        _i_end = 1

        // Customizable methods to set enabled items and text for items.
        _fn_isEnabled = Fn.new{ |i, item| true }
        _fn_getText = Fn.new{ |i, item| (i == _items.count - 1 ? item : "%(item)") }
    }

    construct new(items) {
        // The items.
        _items = items

        // Spacing parameters used for text layout.
        _gap = 20
        _padding = 3

        // Render stuff.
        _visible = false // Can not be rendered if item list is empty.
        _title_color = 0xFFFFFFFF
        _enabled_color = 0xFFFFFFFF
        _disabled_color = 0xA2A2A2FF
        _text_colors = [] // Color of each item based on the idxs list.

        // Current item index.
        _i_start = 0
        _i_end = 1

        // Customizable methods to set enabled items and text for items.
        _fn_isEnabled = Fn.new{ |i, item| true }
        _fn_getText = Fn.new{ |i, item| (i == _items.count - 1 ? item : "%(item)") }
    }

    /// Show child menu.
    render() {        
        if (!_visible) return

        // Background boxes.
        {
            // Render dropshadow.
            var s_color = Data.getColor("Menu Shadow Color")
            _sbg.render(_center.x + 10, _center.y - 10, s_color)

            // Render "border" next.
            var o_color = Data.getColor("Menu Outline Color")
            _obg.render(_center.x, _center.y, o_color)

            // Render the background last.
            var color = Data.getColor("Menu Color")
            _bg.render(_center.x, _center.y, color)
        }

        // Content.
        {
            var text_line = 0
            var text_start = _offset.y + (_size.y / 2) - (_gap / 2) - 4 - _padding

            // Title
            if (_title != null) {
                Render.text(__font, _title, _offset.x - 20, text_start - text_line * _gap, 1.0, _title_color, 0x0, Render.spriteNone)
                text_line = text_line + 1
            }

            // Item/Info.
            for (i in _i_start..._i_end) {
                var lines = _fn_getText.call(i, _items[i]).split("\n")
                var color = _text_colors[i]
                for (line in lines) {
                    Render.text(__font, line, _offset.x, text_start - text_line * _gap, 1.0, color, 0x0, Render.spriteNone)            
                    text_line = text_line + 1
                }
            }
        }   
    }

    /// Called during derived class constructor, sets the menu boxes.
    /// If called before the item list is filled, 'setVisible()' will need to be manually called again.
    setMenuData(size, center, offset) {
        _size = size
        _center = center
        _offset = offset
        
        _bg = Visor.new(size.x, size.y)
        _obg = Visor.new(size.x + 2, size.y + 2)
        _sbg = Visor.new(size.x + 2, size.y + 2)

        setVisible(true)
    }

    /// Sets menu visiblity. Use to hide old menus. Or continue showing them for a cascading effect (need to adjust box positions as well).
    /// Can not be visible if there are no items to show.
    setVisible(is_visible) {
        if (is_visible && _items.count > 0) {
            _visible = true
        } else {
            _visible = false
        }
    }
    
    /// Sets what items are enabled/disabled using a customizable function.
    /// Can be called whenever the item states might change.
    updateEnabledItems() {
        _text_colors.clear()

        for (i in 0..._items.count) {        
            if (_fn_isEnabled.call(i, _items[i])) {                
                _text_colors.add(_enabled_color)
            } else {
                _text_colors.add(_disabled_color)
            }
        }
    }

    // Helps align submenu relative to parent.
    alignTop(size, p_center, p_size) { p_center.y + p_size.y / 2 - size.y / 2 }
    alignRight(size, p_center, p_size) { p_center.x + p_size.x / 2 - size.x / 2 }
    alignBottom(size, p_center, p_size) { p_center.y - p_size.y / 2 + size.y / 2 }
    alignLeft(size, p_center, p_size) { p_center.x - p_size.x / 2 + size.x / 2 }

    alignAbove(size, p_center, p_size) { p_center.y + p_size.y / 2 + size.y / 2 }
    alignAfter(size, p_center, p_size) { p_center.x + p_size.x / 2 + size.x / 2 }
    alignBelow(size, p_center, p_size) { p_center.y - p_size.y / 2 - size.y / 2 }
    alignBefore(size, p_center, p_size) { p_center.x - p_size.x / 2 - size.x / 2 }

    // Used to help place text.    
    gap {_gap}
    padding {_padding}

    // Tracks menu items.
    items {_items}    
    items=(v) {_items = v}

    i_start {_i_start}
    i_start=(v) {_i_start = v}

    i_end {_i_end}
    i_end=(v) {_i_end = v}

    // Render settings.
    fn_isEnabled=(v) {_fn_isEnabled = v}
    fn_getText=(v) {_fn_getText = v}

    title=(v) {_title = v}

    title_color {_title_color}
    title_color=(v) {_title_color = v}

    item_color {_item_color}
    item_color=(v) {_item_color = v}

    text_colors=(v) {_text_colors = v}
}

//import "hero" for Inventory
//import "types" for SType
import "visor" for Visor
//import "create" for Create
//import "parts" for PartMaker
//import "components" for Hero
import "directions" for Directions
import "menus" for MainMenu, InventoryMenu, CraftingMenu
import "menus" for ToolMenu, ShopMenu, InnMenu
import "menus" for DungeonMenu, LevelUpMenu, GameOverMenu
import "menus" for PoleCraftingMenu
