// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE.Chromium file.

var global = this;

/** Platform, package, object property, and Event support. **/
this.ki = ( function(){
    "use strict";

    /**
     * Export dot seperated object name chain
     */
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

    /**
     * Add fields of fun returned object to name.
     * @param {!string} name a path string like 'foo.bar'.
     */
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
