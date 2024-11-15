///////////////////////////////////////////////////////////////////////////////
// Entity / Component 
///////////////////////////////////////////////////////////////////////////////

import "xs_math" for Math, Bits
import "xs_tools" for Tools

// A base class for components that can be added to the entities.
class Component {

    // Creates a new component. Make sure to call super() when inheriting
    // from this class. Other components might still not be avaialbe on the
    // owning entity.
    construct new() {
        _owner = null
        _initialized = false
    }

    // Called right before the first update. Good place to query and cache other
    // components.
    initialize() {}

    // Called when the component/entity is deleted. Set any references to other
    // entities and components to null.
    finalize() {}

    // Called once per update with delta time. Put your logic here.
    update(dt) {}

    // The Entity object that owns this compoenent
    owner { _owner }

    // Private (used by Entity)
    owner=(o) { _owner = o }

    // Private (used by Entity)
    initialized_ { _initialized }

    // Private (used by Entity)
    initialized_=(i) { _initialized = i }
}

class Entity {

    // Creates a new entity, visible to the rest of the game in
    // the next update. 
    construct new() {
        _components = {}
        _deleted = false
        _name = ""
        _tag = 0
        _layer = 0
        _compDeleteQueue = []
        __addQueue.add(this)        
    }

    // Adds a component to the entity. The component must be a subclass of
    // the Component class. The component will be initialized and updated
    // in the order they are added.
    add(component) {
        var c = get(component.type)
        if(c != null) {
            c.finalize()
            // remove from the delete list (if it was there)
            Tools.removeFromList(_compDeleteQueue, c.type)
            // _compDeleteQueue.remove(c.type)
        }

        component.owner = this
        _components[component.type] = component
    }

    // Get a component of a matching type.    
    get(type) {
        if (_components.containsKey(type)) {
            return _components[type]            
        }
        for(v in _components.values) {
            if(v is type) {
                return v    
            }
        }
        return null
    }

    // Will mark the component for removal at the end of the update
    remove(type) {
        if (_components.containsKey(type)) {
            _compDeleteQueue.add(type)
        } else {
            for(v in _components.values) {
                if(v is type) {
                    _compDeleteQueue.add(v.type)
                }
            }   
        }
    }

    // Get all to components 
    components { _components.values }

    // Checks if the entity is marked for removal. Set reference to this entity
    // to null if true
    deleted { _deleted }

    // Will mark the entity for removal at the end of the update
    delete() { _deleted = true }

    // Components can have names. This makes debugguig much easier
    name { _name }
    name=(n){ _name = n }

    // Tag. Used as a bitflag when getting entities of certain type   
    tag { _tag }
    tag=(t) { _tag = t }

     // Layer. Used as a bitflag when getting entities of certain type   
    layer { _layer }
    layer=(l) { _layer = l }

    // Call from the initialize() function of you entry point (game class)
    static initialize() {
        __entities = []
        __addQueue = []
    }

    // Call from the update() function of you entry point (game class)
    // Updates the all entities and their compoenets.
    // Add/removes entities and componenets.
    static update(dt) {
        for (e in __entities) {
            e.removeDeletedComponents_()
        }

        for(a in __addQueue) {
            __entities.add(a)
        }
        __addQueue.clear()

        for (e in __entities) {
            for(c in e.components) {
                if(!c.initialized_) {
                    c.initialize()
                    c.initialized_ = true
                }
                c.update(dt)
            }
        }

        var i = 0
        while(i < __entities.count) {
            var e = __entities[i]
            if(e.deleted) {
                for(c in e.components) {
                    c.finalize()
                }
                __entities.removeAt(i)
            } else {
                i = i + 1
            }
        }
    }

    // Get all the entities where the tag matches with a given tag.
    static withTag(tag) {
        var found = []
        for (e in __entities) {
                if(Bits.checkBitFlag(e.tag, tag)) {
                found.add(e)
            }
        }
        return found
    }

    // Get all the entities where the tag matches (has bit overlap)
    // with a given tag.
    static withTagOverlap(tag) {
        var found = []
        for (e in __entities) {
                if(Bits.checkBitFlagOverlap(e.tag, tag)) {
                found.add(e)
            }
        }
        return found
    }

    // Get all the entities where the layer matches with a given layer.
    static inLayer(layer) {
        var found = []
        for (e in __entities) {
                if(Bits.checkBitFlag(e.layer, layer)) {
                found.add(e)
            }
        }
        return found
    }

    // Get all the entities where the layer matches (has bit overlap)
    // with a given layer.
    static inLayerOverlap(layer) {
        var found = []
        for (e in __entities) {
                if(Bits.checkBitFlagOverlap(e.layer, layer)) {
                found.add(e)
            }
        }
        return found
    }

    // Get all the entities where the tag and layer matches with a given tag and layer.
    static withTagInLayer(tag, layer) {
        var found = []
        for (e in __entities) {
                if(Bits.checkBitFlag(e.tag, tag) && Bits.checkBitFlag(e.layer, layer)) {
                found.add(e)
            }
        }
        return found
    }

    // Get all the entities where the tag overlaps any other tag within the given layer.
    static withTagOverlapInLayer(tag, layer) {
        var found = []
        for (e in __entities) {
                if(Bits.checkBitFlagOverlap(e.tag, tag) && Bits.checkBitFlag(e.layer, layer)) {
                found.add(e)
            }
        }
        return found
    }

    // All the entities active in the system
    static entities { __entities }

    toString {
        var s = "{ Name: %(name) Tag: %(tag) Layer %(layer)"
            for(c in _components) {
                s = s + "     %(c)"
            }
            s = s + "  }"
        return s
    }

    // Does a formated print of all the entities and their componenets
    static print() {
        System.print("<<<<<<<<<< ecs stats >>>>>>>>>>")
        System.print("Active: %(__entities.count)")
        var i = 0
        for (e in __entities) {
            System.print("%(i) { Name: %(e.name) Tag:%(e.tag) Layer:%(e.layer)")
            for(c in e.components) {
                System.print("     %(c.toString)")
            }
            System.print("  }")
            i = i + 1
        }
        System.print("<<<<<<<<<<<<< end >>>>>>>>>>>>>")
    }    

    // Private (actually removes the components)
    removeDeletedComponents_() {
        for(c in _compDeleteQueue) {
            _components[c].finalize()
            _components.remove(c)
        }
        _compDeleteQueue.clear()
    }
}
