class Layer {
    static none         { 0 }
    static shared       { 1 }
    static overworld    { 2 }
    static dungeon      { 3 }

    static [index] {
        if (shared) return SType
        if (overworld) return OType
        if (dungeon) return DType        
        return null
    }
}

class SType {
    static empty        { 0 <<  0 }  

    static player       { 1 <<  0 }

    static i_key        { 1 <<  1 }
    static i_coin       { 1 <<  2 }
    static i_bubble     { 1 <<  3 }
    static i_health     { 1 <<  4 }

    static i_rod        { 1 <<  5 }
    static i_axe        { 1 <<  6 }
    static i_shovel     { 1 <<  7 }
    static i_pick       { 1 <<  8 }    

    static i_wood       { 1 <<  9 }
    static i_bone       { 1 << 10 }

    static i_rose       { 1 << 11 }
    static i_marigold   { 1 << 12 }
    static i_iris       { 1 << 13 }

    static i_ruby       { 1 << 14 }
    static i_amethyst   { 1 << 15 }
    static i_peridot    { 1 << 16 }

    static i_map        { 1 << 17 }

    // Combinations.
    static tools        { i_rod | i_axe | i_shovel | i_pick }
    static flowers      { i_rose | i_marigold | i_iris }
    static gems         { i_ruby | i_amethyst | i_peridot }
    static items        { i_key | i_coin | i_rod | i_axe | i_shovel | i_pick | i_bubble | i_health | i_wood | i_bone | i_rose | i_marigold | i_iris | i_ruby | i_amethyst | i_peridot | i_map }
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