(function() {
    var dumpBookmarks, dumpNode, dumpTreeNodes, makeNode;
    var loadBookmarkTree, listBookmarks, searchBookmarks;
    var toggleSub;

    toggleSub = function(){
        var x = document.querySelectorAll('.sub');
        for( var i = 0 ; i< x.length ; i++){
            console.log(x[i].style.display);
            if ( x[i].style.display == 'none'){
                x[i].style.display = 'block';
            }else {
                x[i].style.display = 'none';
            }
        }
    }
    
    listBookmarks = function( destDivName, bmId ){
        var dest = $('#' + destDivName);
        while( dest && dest.firstChild ){ // clear
            dest.removeChild(dest.firstChild);
        }
        chrome.bookmarks.getChildren(bmId, function(bmarray){
            dest.appendChild(dumpTreeNodes(bmarray, false, 1) );
        });
    }

    loadBookmarkTree = function(divName) {
        dumpBookmarks(divName, null); // no query
    };

    searchBookmarks = function(query) {
        if (query) {
            dumpBookmarks('bookmarks-list', query);
        }
    };

    dumpBookmarks = function( destDivName, query ) {
        var dest = $('#' + destDivName);
        while( dest && dest.firstChild ){
            dest.removeChild(dest.firstChild);
        }
        if( query ) {
            chrome.bookmarks.search(query, function(bmarray) {
                dest.appendChild(dumpTreeNodes(bmarray));
            });
        } else {
            chrome.bookmarks.getTree(function(bmarray) {
                dest.appendChild(dumpTreeNodes(bmarray, true));
            });
        }
    };


    dumpTreeNodes = function(nodeArray, dir_only, max_depth, curr_depth) {
        var list, node, _i, _len;
        list = $('<ul>');
        curr_depth = curr_depth || 0;
        max_depth = max_depth || -1;
        if( --max_depth == -1 ) return list;
        for (_i = 0, _len = nodeArray.length; _i < _len; _i++) {
            node = nodeArray[_i];
            if ( node.url && dir_only){   // is link
                continue;
            }
            list.appendChild(dumpNode(node, dir_only, max_depth, curr_depth));
        }
        return list;
    };

    dumpNode = function(bmNode, dir_only, max_depth, curr_depth) {
        var li = $(bmNode.title ? '<li>' : '<div>');

        li.appendChild( makeNode(bmNode, curr_depth) );

        if ( bmNode.children && bmNode.children.length > 0) {
            li.appendChild(dumpTreeNodes(bmNode.children, dir_only, max_depth, ++curr_depth));
        }
        return li;
    };

    makeNode = function(bmNode, depth){
        var anchor, folder, span;
        span = $('<span>');
        if (bmNode.title) {
            if (bmNode.url) {
                anchor = $('<a>');
                anchor.setAttribute('id', bmNode.id);
                anchor.setAttribute('href', bmNode.url);
                anchor.setAttribute('target', "_blank");
                anchor.innerHTML= '['+ depth +'/' + bmNode.id + '/' + bmNode.index + ']' + bmNode.title;
                span.appendChild(anchor);
            } else {
                folder = $('<span>');
                folder.setAttribute('id', bmNode.id);
                folder.innerHTML = '['+ depth +'/' + bmNode.id + '/' + bmNode.index + '/' + bmNode.title + ']';
                span.appendChild(folder);
            }
        }
        return span;
    }

    document.onreadystatechange = function () {
        if (document.readyState == "complete") {
            var searchFun = (function(e) {
                var query = $('#search-text').value;
                searchBookmarks(query);
                e.preventDefault();
            });
            $('#search-button').addEventListener('click', searchFun);
            $('#toggle-sub').addEventListener('click', toggleSub);
            $('#search-form').addEventListener('submit', searchFun);
            $('#panel-bm-tree').addEventListener('click',( function(e) {
                if( e.target.id ){
                    listBookmarks('bookmarks-list', e.target.id );
                }
            }),true);
            loadBookmarkTree('bookmarks-tree');
        }
    };

}).call(this);
