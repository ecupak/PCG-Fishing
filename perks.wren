System.print("11 + Perks")


import "xs_ec" for Component


class Perk is Component {
    construct new(level) {
        _level = level
        _id = 1        
    }

    static nextID() {
        if (__id == null) __id = 0

        var id = __id
        __id = __id + 1
        
        return id
    }

    level {_level}
    
    id {_id}
    id=(v) {_id = v}
}


/// Perk that increases picked up gold. Only for hero.
class RichesPerk is Perk {
    construct new(level) {
        super(level)
    }

    initialize() {
        owner.get(Character).onCoinPickup.addListener(id, this)
        System.print("Riches added")
    }

    getBonusGold(amount) { (0.2 + (level - 1) * 0.05) * amount }

    call(who, packet) {
        System.print("Perk called!")

        // Add (10% + 5% per perk level) additional gold.
        packet[1] = packet[1] + getBonusGold(packet[0])

        // Add it again if at half hp.
        if (who.get(Stats).health <= who.get(Stats).max_hp / 2) {
            packet[1] = packet[1] + getBonusGold(packet[0])
            System.print("- 1/2 HP bonus!")
        }
    }

    finalize() {
        owner.get(Character).onCoinPickup.removeListener(id)
    }
}

// Already in module registry.
import "components" for Stats, Character


System.print("11 - Perks")