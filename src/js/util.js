/* $ -> getElementById */
function $(idOrType){
//     console.log('$('+idOrType+')');
    if( typeof idOrType != 'string' || idOrType.length == 0){
            return null;
        }
    var el;
    switch ( idOrType.charAt(0) ){
        case '#':
            el = document.getElementById(idOrType.substring(1));
            break;
        case '<':
            var t = idOrType.substring(1,idOrType.length-1);
            el = document.createElement(t);
            break;
    }
    return el;
};


