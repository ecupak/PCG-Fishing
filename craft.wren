System.print("10 + Craft")


import "xs_ec" for Entity, Component

// No extra imports.
import "types" for SType, GType, Group


class Craft {
    static getMaterials() {__materials}

    static getGearCost(part, material) {__crafting_costs[part][material]}
    static getGearName(part, material) {__part_names[part][material]}
    static getGearNames(part) {__part_names[part]}
    static getGearModifier(part, material) {__modifiers[part][material]}
    static getGearDescription(part, material) {__descriptions[part][material]}
    static getBaseName(part) {__base_names[part]}

    /// Description using an item's stats (for gear info).
    static getFullGearDescription(gear) {
        var d = __descriptions[gear.part][gear.material]
        var m = Craft.getGearModifier(gear)
        return d.replace("[value]", "%(m)")
    }

    /// Description using base stats (for crafting info).
    static getFullGearDescription(part, material) {
        var d = __descriptions[part][material]
        var m = __modifiers[part][material]
        return d.replace("[value]", "%(m[0])")
    }

    /// Returns pre-calculated stats of an item.
    static getGearModifier(gear) {
        var modifier = getGearModifier(gear.part, gear.material)
        return modifier[0] + modifier[1] * (gear.level - 1)
    }

    /// Description using an equipped perk (for gear info).
    static getFullPerkDescription(perk) {
        var name = __perk_names[perk[0]]
        var tier = "I"
        for (i in 1...perk[2]) tier = tier + "I"
        
        return tier + " " + name
    }

    static initialize() {
        __materials = [
            SType.wood,
            SType.bone,

            SType.rose,
            SType.marigold,
            SType.iris,

            SType.ruby,
            SType.amethyst,
            SType.peridot,
        ]

        // Base names of each part.
        __base_names = {
            GType.pole: "Pole",
            GType.bobber: "Bobber",
            GType.hook: "Hook",
        }

        /// Names of each part.
        __pole_names = {
            SType.empty: "Weak Pole",

            SType.wood: "Wood Pole",
            SType.bone: "Bone Pole",

            SType.rose: "Rose Pole",
            SType.marigold: "Marigold Pole",
            SType.iris: "Iris Pole",

            SType.ruby: "Ruby Pole",
            SType.amethyst: "Amethyst Pole",
            SType.peridot: "Peridot Pole",
        }

        __bobber_names = {}
        __hook_names = {}

        __part_names = {
            GType.pole: __pole_names,
            GType.bobber: __bobber_names,
            GType.hook: __hook_names,
        }

        /// Perk slots of each part.
        __pole_slot_counts = {
            SType.empty: 0,

            SType.wood: 2,
            SType.bone: 2,

            SType.rose: 2,
            SType.marigold: 2,
            SType.iris: 2,

            SType.ruby: 2,
            SType.amethyst: 2,
            SType.peridot: 2,
        }
        
        __bobber_slot_counts = {}
        __hook_slot_counts = {}

        __slot_counts = {
            GType.pole: __pole_slot_counts,
            GType.bobber: __bobber_slot_counts,
            GType.hook: __hook_slot_counts,
        }

        /// Crafting cost of each part.
        __pole_crafting_costs = {
            SType.empty: [],
            SType.wood: [[SType.wood, 4]],
            SType.bone: [[SType.bone, 16], [SType.wood, 8]],

            SType.rose: [[SType.rose, 12], [SType.peridot, 6], [SType.wood, 4]],
            SType.marigold: [[SType.marigold, 12], [SType.ruby, 6], [SType.wood, 4]],
            SType.iris: [[SType.iris, 10], [SType.amethyst, 6], [SType.bone, 8]],

            SType.ruby: [[SType.ruby, 14], [SType.rose, 8], [SType.wood, 4]],
            SType.amethyst: [[SType.amethyst, 14], [SType.marigold, 8], [SType.wood, 4]],
            SType.peridot: [[SType.peridot, 10], [SType.iris, 8], [SType.bone, 8]],
        }

        __bobber_crafting_costs = {}
        __hook_crafting_costs = {}

        __crafting_costs = {
            GType.pole: __pole_crafting_costs,
            GType.bobber: __bobber_crafting_costs,
            GType.hook: __hook_crafting_costs,
        }

        /// Description of each part.
        __pole_description = {
            SType.empty: "No bonus.\n \n",

            SType.wood: "+[value]\% gold collected. \n+[value]\% more at 1/2 HP.\n",
            SType.bone: "[value]\% of remaining Air \nis added to Armor. \n",

            SType.rose: "Max Health +[value]\%\n \n",
            SType.marigold: "[value]\% of gold is added \nto Damage.\n",
            SType.iris: "No turn cost to pick \nup or use keys.\n",

            SType.ruby: "Heal [value]\% of Health \non enemy defeat.\n",
            SType.amethyst: "Reduce detection \nrange by [value].\n",
            SType.peridot: "[value]\% chance on hit \nto push enemy.\n",
        }

        __bobber_description = {}
        __hook_description = {}

        __descriptions = {
            GType.pole: __pole_description,
            GType.bobber: __bobber_description,
            GType.hook: __hook_description,
        }

        /// Modifiers of each part.
        /// [base_value, value_to_multiply_by_level] => base_value + value_to_multiply_by_level * (level - 1) = true_value
        __pole_modifiers = {
            SType.empty: [0, 0],

            SType.wood: [10, 10],
            SType.bone: [3, 1.5],

            SType.rose: [10, 15],
            SType.marigold: [5, 5],
            SType.iris: [0, 0],

            SType.ruby: [5, 2],
            SType.amethyst: [2, 1],
            SType.peridot: [10, 5],
        }

        __bobber_modifiers = {}
        __hook_modifiers = {}

        __modifiers = {
            GType.pole: __pole_modifiers,
            GType.bobber: __bobber_modifiers,
            GType.hook: __hook_modifiers,
        }

        /// Skills of each part.
        __pole_skills = {
            SType.empty: RichesPerk,

            SType.wood: RichesPerk, // RichesPerk
            SType.bone: RichesPerk,

            SType.rose: RichesPerk,
            SType.marigold: RichesPerk,
            SType.iris: RichesPerk,

            SType.ruby: RichesPerk,
            SType.amethyst: RichesPerk,
            SType.peridot: RichesPerk,
        }

        __bobber_skills = {}
        __hook_skills = {}

        __skills = {
            GType.pole: __pole_skills,
            GType.bobber: __bobber_skills,
            GType.hook: __hook_skills,
        }

        /// Name of each perk.
        __perk_names = {
            RichesPerk: "Riches",
        }

        __id = 0
    }

    static pole(material) {
        var entity = Entity.new()

        var perk_slots = __pole_slot_counts[material]
        var perk = RichesPerk // __pole_skills[material]
        System.print("material: %(material), perk: %(RichesPerk)")
        var part = Gear.new(nextID(), GType.pole, material, perk, perk_slots)
        entity.add(part)
        
        entity.name = __pole_names[material]
        entity.tag = GType.pole
        entity.group = Group.gear

        return entity
    }

    static bobber(material) {}

    static hook(material) {}

    static gear(part, material) {
        if (part == GType.pole) return pole(material)
        if (part == GType.bobber) return bobber(material)
        if (part == GType.hook) return hook(material)
    }

    static createPerk() {}

    static nextID() {
        var id = __id
        __id = __id + 1
        return id
    }
}

// Already in module registry.
import "components" for Gear

// New modules.
import "perks" for RichesPerk


System.print("10 - Craft")