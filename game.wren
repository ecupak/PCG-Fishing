import "xs" for Data, Input, Render
import "xs_ec"for Entity
import "xs_tools" for Tools
import "background" for Background

// There needs class called Game in you main file
class Game {

    // There are the states of the game
    // Wren does not have enums, so we use static variables
    static loading_state    { 0 }    
    static generating_state { 1 }    
    static playing_state    { 2 }
    static gameover_state   { 3 }

    // Initialize the game, which means initializing all the systems
    // and some variables that are used in the game`s logic
    static initialize() {
        Entity.initialize()
        OverworldTile.initialize()
        DungeonTile.initialize()
        Tools.initialize()
        Create.initialize()
        Craft.initialize()
        Gameplay.initialize()
        
        __time = 0        
        __state = playing_state // skip generating
        __background = Background.new()

        __genFiber = Fiber.new { Gameplay.dungeon_level.build(0) }

        Gameplay.beginGame(0)
    }   
    
    // Update the game, which means updating all the systems
    static update(dt) {  
        if(__state == generating_state) {
            genStep(dt)
        } else {
            Gameplay.update(dt)
        }

        Entity.update(dt)
        __background.update(dt)
    }

    // This function is called when the game is in the generating state.
    static genStep(dt) {
        var visualize = Data.getBool("Visualize Generation", Data.debug)
        if(visualize) {
            __time = __time - dt
            if(__time <= 0.0) {
                if(!__genFiber.isDone) {
                    __time = __genFiber.call()
                } else {
                    __state = playing_state
                }
            }
        } else {
            while(!__genFiber.isDone) {
                __genFiber.call()
            } 
            __state = playing_state
        }
    }

    // Render the game, which means rendering all the systems and entities
    static render() {    
        __background.render()
        Gameplay.render()
    }
 }

/// Import classes from other files that might have circular dependencies (import each other)
import "gameplay" for Level, OverworldTile, DungeonTile, Gameplay
import "create" for Create
import "craft" for Craft
