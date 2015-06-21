(function() {
    var dumpBookmarks, dumpNode, dumpTreeNodes, makeNode;
    var loadBookmarkTree, listBookmarks, searchBookmarks;
    var toggleSub;
    var handleKeyDown;

    var initTree;

    toggleSub = function() {
        var x = document.querySelectorAll('#main');
        for (var i = 0; i < x.length; i++) {
            x[i].classList.toggle('double');
        }
    };

    listBookmarks = function(destDivName, bmId ) {
        var dest = $('' + destDivName);
        while (dest && dest.firstChild) { // clear
            dest.removeChild(dest.firstChild);
        }
        bmm.bookmarks.getChildren(bmId, function(bmarray) {
            dest.appendChild(dumpTreeNodes(bmarray, false, 1));
        });
    };

    loadBookmarkTree = function(divName) {
        dumpBookmarks(divName, null); // no query
    };

    searchBookmarks = function(query) {
        if (query) {
            dumpBookmarks('bm-list1', query);
        }
    };

    dumpBookmarks = function(destDivName, query ) {
        var dest = $('' + destDivName);
        while (dest && dest.firstChild) {
            dest.removeChild(dest.firstChild);
        }
        if (query) {
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
        list = document.createElement('ul');
        curr_depth = curr_depth || 0;
        max_depth = max_depth || -1;
        if (--max_depth == -1) return list;
        for (_i = 0, _len = nodeArray.length; _i < _len; _i++) {
            node = nodeArray[_i];
            if (node.url && dir_only) {   // is link
                continue;
            }
            list.appendChild(dumpNode(node, dir_only, max_depth, curr_depth));
        }
        return list;
    };

    dumpNode = function(bmNode, dir_only, max_depth, curr_depth) {
        var li = document.createElement(bmNode.title ? 'li' : 'div');

        li.appendChild(makeNode(bmNode, curr_depth));
        li.setAttribute('draggable', 'true');

        if (bmNode.children && bmNode.children.length > 0) {
            li.appendChild(dumpTreeNodes(bmNode.children, dir_only, max_depth, ++curr_depth));
        }
        return li;
    };

    makeNode = function(bmNode, depth) {
        var anchor, folder, span;
        span = document.createElement('span');
        if (bmNode.title) {
            if (bmNode.url) {
                anchor = document.createElement('a');
                anchor.setAttribute('class', 'bookmark');
                anchor.setAttribute('bmid', bmNode.id);
                anchor.setAttribute('href', bmNode.url);
                anchor.setAttribute('target', '_blank');
                anchor.innerHTML = '[' + depth + '/' + bmNode.id + '/' + bmNode.index + ']' + bmNode.title;
                span.appendChild(anchor);
            } else {
                folder = document.createElement('span');
                folder.setAttribute('class', 'bookmark');
                folder.setAttribute('bmid', bmNode.id);
                folder.innerHTML = '[' + depth + '/' + bmNode.id + '/' + bmNode.index + '/' + bmNode.title + ']';
                span.appendChild(folder);
            }
        }
        return span;
    };

    var handleDebugKey = function(){ // DEBUG
        // test speed
        var getBookmarksFromCollection = function( collection, id){
            var coll = [];
            for ( var i = 0, len = collection.length; i< len; i++){
                if (collection[i].getAttribute('bmid') === id){
                    coll.push(collection[i]);
                }
            }
            return coll;
        }
        var dbgId = "1716";
        var start1 = new Date().getTime();
        var collect1 = document.getElementsByClassName('bookmark');
        // console.log(collect1);
        collect1 = getBookmarksFromCollection( collect1, dbgId );
        var end1 = new Date().getTime();
        var time1 = end1 - start1 ;
        console.log(collect1, start1, end1, time1);

        var start2 = new Date().getTime();
        var collect2 = document.querySelectorAll('.bookmark');
        // console.log(collect2);
        collect2 = getBookmarksFromCollection( collect2, dbgId );
        var end2 = new Date().getTime();
        var time2 = end2 - start2 ;
        console.log(collect2, start2, end2, time2);
    }

    handleKeyDown = function(e ) {
        if (e.ctrlKey && e.keyIdentifier == 'U+0032') { // Ctrl-2
            toggleSub();
        }
        // DEBUG
        if (e.ctrlKey && e.keyIdentifier == 'U+0030') { // Ctrl-0
            handleDebugKey();
        }
    };

    var forest_ = [];
    forest_.createTree = function() {
        var tree = new bmm.BookmarkTree();

        this.append(tree);
        return tree;
    };

    document.onreadystatechange = function() {
        if (document.readyState == 'complete') {
            var searchFun = (function(e) {
                var query = $('search-text').value;
                searchBookmarks(query);
                e.preventDefault();
            });
            // $('search-button').addEventListener('click', searchFun);
            // $('toggle-sub').addEventListener('click', toggleSub);
            $('search-form').addEventListener('submit', searchFun);
            $('bm-tree1').addEventListener('click', (function(e) {
                if (e.target.getAttribute('bmid')) {
                    listBookmarks('bm-list1', e.target.getAttribute('bmid'));
                }
            }), true);
            $('bm-tree2').addEventListener('click', (function(e) {
                console.log('click', e.target);
                if (e.target.getAttribute('bmid')) {
                    listBookmarks('bm-list2', e.target.getAttribute('bmid'));
                }
                if (/\s*cmd\s*/.test(e.target.className)){
                    console.log('click a cmd!!', e.target.id);
                    switch( e.target.id ){
                        case "cmd-recycle": // move to recycle bin
                            // ensure recycle bin folder TODO
                            // chrome.bookmarks.move(id, dest, callback);
                            // bmm.menu.getParentBookmarkNode());
                            var recycleBinName = 'shiori recycle bin';
                            break;
                        case "cmd-rename": // move to recycle bin
                            break;
                        case "cmd-copy": // move to recycle bin
                            break;
                    }
                }
            }), true);
            // TODO: reuse these method on bm-tree1 and bm-tree2
            $('bm-tree2').addEventListener('contextmenu', function(ev) {
                ev.preventDefault();
                // TODO: draw menu
                var bmNode = ev.target;
                while (bmNode !== null && (typeof bmNode.className === 'undefined'
                    || !bmNode.className.match(/(?:^|\s)bookmark(?!\S)/)) ){
                        bmNode = bmNode.parentNode; // search up for bookmarkNode
                    }
                    if (bmNode === null){return false;}
                    if ( typeof bmm.menu === "undefined"){
                        bmm.menu = document.createElement('div');
                        bmm.menu.setAttribute('class', 'context-menu');
                    } else {
                        if ( bmNode === bmm.menu ) { return false; }
                        if ( bmNode === bmm.menu.parentNode ) { return false; }
                        bmm.menu.parentNode.removeChild(bmm.menu);
                    }
                    var rect = bmNode.getBoundingClientRect();
                    bmm.menu.innerHTML =
                        '<p id="cmd-recycle" class="menu-item cmd">Recycle</p>\
                    <p id="cmd-rename" class="menu-item cmd">Rename</p>\
                    <p id="cmd-copy" class="menu-item cmd">Copy</p>\
                    <style> p.menu-item {\
                    display:inline-block;\
                    margin: 0 1em;\
                    heith: 2em;\
                    background-color: #beb\
                    }<style>';
                    bmNode.appendChild(bmm.menu);
                    bmm.menu.parentNode = bmNode;
                    return false; // disable default contest menu
            }, false);
            // $('dbg1').addEventListener('click', function(e){
            // console.log(e.clientX, e.clientY);
            // });
            loadBookmarkTree('bm-tree1');
            loadBookmarkTree('bm-tree2');

            document.addEventListener('keydown', handleKeyDown);

            // listen for bookmark change
            chrome.bookmarks.onCreated.addListener(function(id, bookmark){
                console.log('cb created'+ id + bookmark.id + bookmark.title + bookmark.url );
            });
            chrome.bookmarks.onRemoved.addListener(function(id, removeInfo){
                console.log('cb removed'+ id , removeInfo);
            });
            chrome.bookmarks.onChanged.addListener(function(id, changeInfo){
                console.log('cb changed'+ id , changeInfo);
            });
            chrome.bookmarks.onMoved.addListener(function(id, moveInfo){
                console.log('cb moved'+ id , moveInfo);
            });
            chrome.bookmarks.onChildrenReordered.addListener(function(id, reorderInfo){
                console.log('cb onChildrenReordered'+ id , reorderInfo);
            });
            chrome.bookmarks.onImportBegan.addListener(function(){
                console.log('cb onImportBegan');
            });
            chrome.bookmarks.onImportEnded.addListener(function(){
                console.log('cb onImportEnded');
            });
        }
    };

}).call(this);
