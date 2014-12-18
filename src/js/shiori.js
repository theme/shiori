var global = this ;

this.shiori = ( function(){
    "use strict";

    /* exportPath() : export dot seperated object name chain */
    function exportPath( path, opt_obj, opt_to_obj){
        var parts = path.split('.');
        var cur = opt_to_obj || global;

        for( var part ; parts.length && (part = parts.shift()); ){
            if( !parts.length && opt_obj !== undefined ){
                // add last part into path
                cur[part] = opt_obj;
            }else if ( part in cur ){
                // has this part in path, move on to next
                cur = cur[part];
            }else {
                // not has this part in path, add it
                cur = cur[part] = {};
            }
        }
        return cur;
    }

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
    };
})();

