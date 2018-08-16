package gasm.heaps.data;

import gasm.core.math.geom.Coords;

class DataUtils {

    public static inline function defaultVal(val:Any, def:Any) {
        if(val == null) {
            val = def;
        }
        return val;
    }

    public static function convertCoord(val:Int, ratio:Float) {
    
    }
}