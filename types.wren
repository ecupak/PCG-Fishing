System.print("03 + Types")


class Group {
    static none         { 0 }
    static shared       { 1 }
    static overworld    { 2 }
    static dungeon      { 3 }
    static gear         { 4 }

    static coin_perk        { 5 }
    static health_perk      { 6 }
    static attack_perk      { 7 }
    static lose_hp_perk     { 8 }
    static trap_perk        { 9 }

    static [index] {
        if (shared) return SType
        if (overworld) return OType
        if (dungeon) return DType        
        return null
    }
}

class GType { 
    static empty        { 0 <<  0 }

    static pole       { 1 <<  0 }
    static bobber     { 1 <<  1 }
    static hook       { 1 <<  2 }

    // Combinations
    static gear         { pole | bobber | hook }
}

class SType {
    static empty        { 0 <<  0 }  

    static player       { 1 <<  0 }

    static key        { 1 <<  1 }
    static coin       { 1 <<  2 }
    static bubble     { 1 <<  3 }
    static health     { 1 <<  4 }

    static rod        { 1 <<  5 }
    static axe        { 1 <<  6 }
    static shovel     { 1 <<  7 }
    static pick       { 1 <<  8 }    

    static wood       { 1 <<  9 }
    static bone       { 1 << 10 }

    static rose       { 1 << 11 }
    static marigold   { 1 << 12 }
    static iris       { 1 << 13 }

    static ruby       { 1 << 14 }
    static amethyst   { 1 << 15 }
    static peridot    { 1 << 16 }

    static map        { 1 << 17 }

    // Combinations.
    static tools        { rod | axe | shovel | pick }
    static flowers      { rose | marigold | iris }
    static gems         { ruby | amethyst | peridot }
    static items        { key | coin | rod | axe | shovel | pick | bubble | health | wood | bone | rose | marigold | iris | ruby | amethyst | peridot | map }
}

/// Overworld types.
class OType {
    static empty        { 0 <<  0 }

    static target_good  { 1 <<  0 }
    static target_bad   { 1 <<  1 }

    static grass_a      { 1 <<  2 }
    static grass_b      { 1 <<  3 }
    static grass_c      { 1 <<  4 }

    static tree_a       { 1 <<  5 }
    static tree_b       { 1 <<  6 }
    static tree_c       { 1 <<  7 }

    static road         { 1 <<  8 }
    static bridge       { 1 <<  9 }

    static pond         { 1 << 10 }
    static pond_deep    { 1 << 11 }
    static pond_side    { 1 << 12 }
    static pond_corner  { 1 << 13 }
    
    static ruby_rock    { 1 << 14 }
    static amethyst_rock{ 1 << 15 }
    static peridot_rock { 1 << 16 }

    static grave_marker { 1 << 17 }
    static grave_soil   { 1 << 18 }

    static hole         { 1 << 19 }

    static shop         { 1 << 20 }
    static inn          { 1 << 21 }

    // Combined
    static paths    { road | bridge }
    static grasses  { grass_a | grass_b | grass_c}
    static diggable { grasses | grave_soil }

    static trees    { tree_a | tree_b  | tree_c}
    static water    { pond | pond_deep | pond_side | pond_corner }
    static rocks    { ruby_rock | amethyst_rock | peridot_rock }

    static buildings    { shop | inn }
    static obstacle     { trees | water | rocks }
    static hero_block   { obstacle | buildings }
}

/// Dungeon types.
class DType {
    static empty    { 0 <<  0 }
    
    static wall     { 1 <<  0 }
    static floor    { 1 <<  1 }
    static gate     { 1 <<  2 }

    static e_crab   { 1 <<  3 }
    static e_eel    { 1 <<  4 }
    static e_squid  { 1 <<  5 }
    static e_octo   { 1 <<  6 }
    static e_gator  { 1 <<  7 }

    // Combined    
    static obstacle { wall | gate }
    static enemy    { e_eel | e_squid | e_crab | e_octo | e_gator }    
    
    static hero_block       { obstacle | enemy }
    static monster_block    { obstacle | enemy }    
}


System.print("03 - Types")