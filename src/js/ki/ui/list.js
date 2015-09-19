ki.define('ki.ui', function(){
    var List = ki.ui.defineConstructor( 'li' );
    List.prototype  = Object.create(HTMLLIElement.prototype);

    return {
        List: List
    };
});
