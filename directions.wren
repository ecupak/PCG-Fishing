import "xs_math" for Vec2

class Directions {
    /// Directly iterate over vectors.
    static cardinal() {
        __card = [ // up, right, down, left (CW)
            Vec2.new( 0,  1),
            Vec2.new( 1,  0),
            Vec2.new( 0, -1),
            Vec2.new(-1,  0),
        ]

        return __card
    }

    /// Directly iterate over vectors.
    static ordinal() {
        __ord = [
            Vec2.new(-1,  1),
            Vec2.new( 1,  1),
            Vec2.new( 1, -1),
            Vec2.new(-1, -1),
        ]

        return __ord
    }

    /// General notation of cardinals.
    static up_idx       { 0 }
    static right_idx    { 1 }
    static down_idx     { 2 }
    static left_idx     { 3 }
    static none_idx     { 4 }

    static [i] {
        if(i == 0) {
            return Vec2.new(0, 1)   // Up
        } else if(i == 1) {
            return Vec2.new(1, 0)   // Right
        } else if(i == 2) {
            return Vec2.new(0, -1)  // Down
        } else if(i == 3) {
            return Vec2.new(-1, 0)  // Left
        } else if(i == 4) {
            return Vec2.new(0, 0)   // None
        }
    } 
}