(function() {
    var dumpBookmarks, dumpNode, dumpTreeNodes, makeNode;
    var loadBookmarkTree, listBookmarks, searchBookmarks;

    document.onreadystatechange = function () {
        if (document.readyState == "complete") {
            var searchFun = (function(e) {
                var query = $('#search-text').value;
                searchBookmarks(query);
                e.preventDefault();
            });
            $('#search-button').addEventListener('click', searchFun);
            $('#search-form').addEventListener('submit', searchFun);
            $('#panel-bmtree').addEventListener('click',( function(e) {
                console.log(e.target.id);
                if( e.target.id ){
                    listBookmarks('bookmarks-list', e.target.id );
                }
            }),true);
            loadBookmarkTree('bookmarks-tree');
        }
    };
    
    listBookmarks = function( divName, bmId ){
        chrome.bookmarks.getChildren(bmId, function(bmarray){
            $('#'+divName).appendChild(dumpTreeNodes(bmarray, false, 1) );
        });
    }

    loadBookmarkTree = function(divName) {
        console.log('loadBookmarkTree()');
        dumpBookmarks(divName, null); // no query
    };

    /* get keyword and search */
    searchBookmarks = function(query) {
        var results = $('#search-results');
        var panel = $('#panel-search-results');

        if (query) {
            console.log('searchBookmarks()');
            // clear
            while( results && results.firstChild ){
                results.removeChild(results.firstChild);
            }
            // show panel
            panel.className = panel.className.replace ( /(?:^|\s)hidden(?!\S)/g , '' )
            // append
            dumpBookmarks('search-results', query);
        } else {
            panel.className += "hidden";
        }
    };

    dumpBookmarks = function( dest, query ) {
        console.log('dumpBookmarks() query=', query);
        if( query ) {
            chrome.bookmarks.search(query, function(bmarray) {
                console.log('\tsearch');
                $('#'+dest).appendChild(dumpTreeNodes(bmarray));
            });
        } else {
            chrome.bookmarks.getTree(function(bmarray) {
                console.log('\tgetTree');
                $('#'+dest).appendChild(dumpTreeNodes(bmarray, true));
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
                folder = $('<p>');
                folder.setAttribute('id', bmNode.id);
                folder.innerHTML = '['+ depth +'/' + bmNode.id + '/' + bmNode.index + '/' + bmNode.title + ']';
                span.appendChild(folder);
            }
        }
        return span;
    }

}).call(this);
