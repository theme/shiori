/* offer functions in global scope */

// $('#id') -> getElementById
// $('<tag>') -> createElement
function $(idOrType){
//     console.log('$('+idOrType+')');
    if( typeof idOrType != 'string' || idOrType.length === 0){
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
}

function assert(condition, message) {
  if (!condition) {
    message = message || "Assertion failed";
    if (typeof Error !== "undefined") {
      throw new Error(message);
    }
    throw message; // Fallback
  }
}
