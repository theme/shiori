var global = this ;

this.shiori = ( function(){
    "use strict";

    /* exportPath() : export dot seperated object name chain */
    function exportPath( path, opt_obj, opt_to_obj){
        var parts = path.split('.');
        var cur_obj = opt_to_obj || global;

        for( var part ; parts.length && (part = parts.shift()); ){
            if( !parts.length && opt_obj != undefined ){
                // add last part into path
                cur_obj[part] = opt_obj;
            }else if ( part in cur_obj ){
                // has this part in path, move on to next
                cur_obj = cur_obj[part];
            }else {
                // not has this part in path, add it
                cur_obj[part] = {};
            }
        }
        return cur_obj;
    };

    /* add fields of fun returned object to name */
    function define( name, fun ){
        var obj = exportPath( name );
        var exports = fun();

        for( var propertyName in exports ) {
            var propertyDesc = Object.getOwnPropertyDescriptor(exports, propertyName);
            if( propertyDesc ){
                Object.defineProperty( obj, propertyName, propertyDesc );
            }
        }
    }

    return {
        define : define
    }
})();

