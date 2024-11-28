import "xs_math" for Vec2
import "menu" for SubMenu

/// Displays information about the highlighted item.
class InventoryInfoMenu is SubMenu {
    construct new(p_center, p_size) {
        super()

        System.print("submenu: c %(p_center) s %(p_size)")

        _info = {
            0: "???",

            SType.key: "Opens locked doors.",
            SType.coin: "Spend at shops.",            

            SType.wood: "Crafting item.",
            SType.bone: "Crafting item.",

            SType.rose: "Crafting item.",
            SType.marigold: "Crafting item.",
            SType.iris: "Crafting item.",

            SType.ruby: "Crafting item.",
            SType.amethyst: "Crafting item.",
            SType.peridot: "Crafting item.",

            SType.map: "Used to escape \ndungeons.",
        }

        _item_key = [0]
        items.add("???")

        // Customize item parser.
        fn_getText = Fn.new { |i, item| _info[_item_key[0]] }

        // Size and position of box containing items.        
        var size = Vec2.new(165, gap * 2 + padding * 2)
        var center = Vec2.new(alignAfter(size, p_center, p_size) + 12, alignTop(size, p_center, p_size))
        var offset = center + Vec2.new(5 + -size.x / 2, 0)

        setMenuData(size, center, offset)
    }

    update(item_key) {
        _item_key[0] = (_info.containsKey(item_key) ? item_key : 0)
        updateEnabledItems()
    }
}

/// Displays tool information for the highlighted action.
class ToolInfoMenu is SubMenu {
    construct new(p_center, p_size) {
        super()

        _item_key = [0]
        items.add("???")

        // Customize item parser.
        fn_getText = Fn.new { |i, item|
            var durability = Hero.hero.inventory.get(_item_key[0])
            var name = Create.getItemName(_item_key[0])            
            return "Uses %(name).\nDurability is %(durability) / 10."
        }

        // Size and position of box containing items.        
        var size = Vec2.new(165, gap * 2 + padding * 2)
        var center = Vec2.new(alignAfter(size, p_center, p_size) + 12, alignTop(size, p_center, p_size))
        var offset = center + Vec2.new(5 + -size.x / 2, 0)

        setMenuData(size, center, offset)        
    }

    update(item_key) {        
        _item_key[0] = item_key
        updateEnabledItems()
    }
}

/// Displays pole information for the highlighted pole.
class PoleInfoMenu is SubMenu {
    construct new(p_center, p_size) {
        super()

        // Fill items.
        items = ["Desc", "P1", "P2", "P3"]
        start = 0
        end = 4
        
        // If the material required is not in inventory, show it in disabled color.
        fn_isEnabled = Fn.new { |i, item| (item != "empty") }

        // Show items with a leading 'true' as-is. Only need to format the material costs.
        //fn_getText = Fn.new { |i, item| }

        // Size and position of box containing items.        
        var size = Vec2.new(165, gap * 6 + padding * 2)
        var center = Vec2.new(alignAfter(size, p_center, p_size) + 12, alignTop(size, p_center, p_size))
        var offset = center + Vec2.new(5 + -size.x / 2, 0)

        setMenuData(size, center, offset)
    }

    update(gear_entity) {
        // Add description.
        var gear = gear_entity.get(Gear)
        var description = Craft.getFullGearDescription(gear)
        var perk_text = (gear.perk_slots > 0 ? "Perks:" : "No perk slots.")

        items.clear()
        items.add(description + perk_text)

        for (i in 0...gear.perk_slots) {
            System.print("i from 0 to %(end)")
            if (gear.accessory_perks.count >= i + 1) {
                var perk_description = Craft.getFullPerkDescription(gear.accessory_perks[i])
                items.add(perk_description)
            } else {
                items.add("empty")
            }
        }
        end = gear.perk_slots + 1
        System.print("end = %(end)")

        updateEnabledItems()
    }
}

/// Displays pole crafting information for the highlighted pole.
class PoleCraftingInfoMenu is SubMenu {
    construct new(p_center, p_size) {
        super()

        // Fill items.
        for (material in Craft.getMaterials()) {
            // Add description.
            var description = Craft.getFullGearDescription(GType.pole, material)    
            items.add([true, description + "Requires:"])
            // Add material costs.
            var costs = Craft.getGearCost(GType.pole, material)
            for (i in 0...3) {
                if (i < costs.count) {
                    items.add([false, costs[i]])
                } else {
                    items.add([true, ""])
                }
            }
        }

        // If the material required is not in inventory, show it in disabled color.
        fn_isEnabled = Fn.new { |i, item|
            if (item[0]) {
                return true
            } else {
                var cost = item[1]                
                return Hero.hero.inventory.get(cost[0]) >= cost[1]
            }
        }

        // Show items with a leading 'true' as-is. Only need to format the material costs.
        fn_getText = Fn.new { |i, item|
            if (item[0]) {
                return item[1]
            } else {
                var cost = item[1]
                var material = Create.getItemName(cost[0])
                return "x%(cost[1]) %(material)"
            }
        }        

        // Size and position of box containing items.        
        var size = Vec2.new(165, gap * 6 + padding * 2)
        var center = Vec2.new(alignAfter(size, p_center, p_size) + 12, alignTop(size, p_center, p_size))
        var offset = center + Vec2.new(5 + -size.x / 2, 0)

        setMenuData(size, center, offset)
    }

    update(item_key) {
        var index = Craft.getMaterials().indexOf(item_key)
        start = index * 4
        end = start + 4
        
        updateEnabledItems()
    }
}

import "types" for SType, GType
import "craft" for Craft
import "create" for Create
import "components" for Hero, Gear