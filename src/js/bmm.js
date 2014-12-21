shiori.define('bmm.bookmarks', function() {
    var bmCache = {};
    var getChildren = function( id, fun ) {
        var c = bmCache[id];
        if( c ) {
            fun( c );
        }
        else {
            chrome.bookmarks.getChildren( id, function( array ) {
                bmCache[id] = array;
                fun( array );
            });
        }
    };
    return {
        getChildren: getChildren,
    };
});
