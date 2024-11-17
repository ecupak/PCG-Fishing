import "xs_math" for Vec2
import "menu" for SubMenu

/// Displays information about the highlighted item.
class InventoryInfoMenu is SubMenu {
    construct new(p_center, p_size) {
        super()

        System.print("submenu: c %(p_center) s %(p_size)")

        _info = {
            0: "???",

            SType.i_key: "Opens locked doors.",
            SType.i_coin: "Spend at shops.",            

            SType.i_wood: "Crafting item.",
            SType.i_bone: "Crafting item.",

            SType.i_rose: "Crafting item.",
            SType.i_marigold: "Crafting item.",
            SType.i_iris: "Crafting item.",

            SType.i_ruby: "Crafting item.",
            SType.i_amethyst: "Crafting item.",
            SType.i_peridot: "Crafting item.",

            SType.i_map: "Used to escape \ndungeons.",
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

/// Displays pole crafting information for the highlighted pole.
class PoleCraftingInfoMenu is SubMenu {
    construct new(p_center, p_size) {
        super()

        _description = {
            SType.i_wood: "Basic fishing pole.\n \n",
            SType.i_bone: "1\% of remaining Air \nis added to Armor. \n",

            SType.i_rose: "Max Health +10\%\n \n",
            SType.i_marigold: "5\% of gold is added \nto Damage.\n",
            SType.i_iris: "No turn cost to pick \nup or use keys.\n",

            SType.i_ruby: "Regain 5\% of Health \non enemy defeat.\n",
            SType.i_amethyst: "Reduce detection \nrange by 2.\n",
            SType.i_peridot: "10\% chance on hit \nto push enemy.\n",
        }

        // Fill items.
        for (material in PartMaker.getMaterials()) {
            // Add description.
            items.add([true, _description[material] + "Requires:"])
            // Add material costs.
            var costs = PartMaker.getCraftingCost(SType.i_pole, material)
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
                return "- x%(cost[1]) %(material)"
            }
        }        

        // Size and position of box containing items.        
        var size = Vec2.new(165, gap * 6 + padding * 2)
        var center = Vec2.new(alignAfter(size, p_center, p_size) + 12, alignTop(size, p_center, p_size))
        var offset = center + Vec2.new(5 + -size.x / 2, 0)

        setMenuData(size, center, offset)
    }

    update(item_key) {
        var index = PartMaker.getMaterials().indexOf(item_key)
        i_start = index * 4
        i_end = i_start + 4
        
        updateEnabledItems()
    }
}

import "types" for SType
import "parts" for PartMaker
import "create" for Create
import "components" for Hero