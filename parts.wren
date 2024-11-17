import "xs_ec" for Entity, Component

class PartMaker {
    static getMaterials() {__materials}
    static getPartNames(part_type) {__part_names[part_type]}
    static getPartName(part_type, item_type) {__part_names[part_type][item_type]}
    static getCraftingCost(part_type, item_type) {__crafting_costs[part_type][item_type]}

    static initialize() {
        __materials = [
            SType.i_wood,
            SType.i_bone,

            SType.i_rose,
            SType.i_marigold,
            SType.i_iris,

            SType.i_ruby,
            SType.i_amethyst,
            SType.i_peridot,
        ]

        /// Names of each part.
        __pole_names = {
            SType.i_wood: "Wood Pole",
            SType.i_bone: "Bone Pole",

            SType.i_rose: "Rose Pole",
            SType.i_marigold: "Marigold Pole",
            SType.i_iris: "Iris Pole",

            SType.i_ruby: "Ruby Pole",
            SType.i_amethyst: "Amethyst Pole",
            SType.i_peridot: "Peridot Pole",
        }

        __bobber_names = {}
        __hook_names = {}

        __part_names = {
            SType.i_pole: __pole_names,
            SType.i_bobber: __bobber_names,
            SType.i_hook: __hook_names,
        }

        /// Perk slots of each part.
        __pole_slot_counts = {
            SType.i_wood: 2,
            SType.i_bone: 2,

            SType.i_rose: 2,
            SType.i_marigold: 2,
            SType.i_iris: 2,

            SType.i_ruby: 2,
            SType.i_amethyst: 2,
            SType.i_peridot: 2,
        }
        
        __bobber_slot_counts = {}
        __hook_slot_counts = {}

        __slots_counts = {
            SType.i_pole: __pole_slot_counts,
            SType.i_bobber: __bobber_slot_counts,
            SType.i_hook: __hook_slot_counts,
        }

        /// Crafting cost of each part.
        __pole_crafting_costs = {
            SType.i_wood: [[SType.i_wood, 4]],
            SType.i_bone: [[SType.i_bone, 16], [SType.i_wood, 8]],

            SType.i_rose: [[SType.i_rose, 12], [SType.i_peridot, 6], [SType.i_wood, 4]],
            SType.i_marigold: [[SType.i_marigold, 12], [SType.i_ruby, 6], [SType.i_wood, 4]],
            SType.i_iris: [[SType.i_iris, 10], [SType.i_amethyst, 6], [SType.i_bone, 8]],

            SType.i_ruby: [[SType.i_ruby, 14], [SType.i_rose, 8], [SType.i_wood, 4]],
            SType.i_amethyst: [[SType.i_amethyst, 14], [SType.i_marigold, 8], [SType.i_wood, 4]],
            SType.i_peridot: [[SType.i_peridot, 10], [SType.i_iris, 8], [SType.i_bone, 8]],
        }

        __bobber_crafting_costs = {}
        __hook_crafting_costs = {}

        __crafting_costs = {
            SType.i_pole: __pole_crafting_costs,
            SType.i_bobber: __bobber_crafting_costs,
            SType.i_hook: __hook_crafting_costs,
        }
    }

    static createPole(item_base_type) {
        var entity = Entity.new()

        var slots = __slot_counts[item_base_type]
        var pole = Pole.new(slots)
        entity.add(pole)

        var tag = SType.i_pole
        entity.tag = tag
        entity.name = __part_names[tag][item_base_type]
        System.print("Created %(entity.name)")

        return entity
    }

    static createBobber() {}

    static createHook() {}

    static createPerk() {}
}

class Part is Component {
    construct new(slots) {
        //_type = type
        _slots = slots
        _perks = 0
    }

    add(perk_class) {
        if (_perks == _slots) return false
    
        var perk = perk_class.new()
        owner.add(perk)
        _perks = _perks + 1
        
        return true
    }

    slots {_slots}    
    perks {_perks}
}

class Pole is Part {
    construct new(slots) {
        super(slots)

        // Depending on item base type, add component representing part bonus.
        // ie. iris pole give chance after moving to auto attack in same direction as movement.
    }
}

class Perk is Component {
    construct new() {
        _level = 1
    }

    level {_level}
    level=(v) {_level = v}
}

class Bobber is Part {
    construct new(slots) {
        super(slots)

        // Depending on item base type, add component representing part bonus.
        // ie. ruby bobber gives chance to raise attack (temporarily) after regaining health.
    }
}

class Hook is Part {
    construct new(slots) {
        super(slots)

        // Depending on item base type, add component representing part bonus.
        // ie. peridot hook give chance to knock back an enemy after attacking (upgrades increase # of enemies in a line to affect)
    }
}

import "types" for SType