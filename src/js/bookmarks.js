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
                anchor.setAttribute('id', bmNode.id);
                anchor.setAttribute('href', bmNode.url);
                anchor.setAttribute('target', '_blank');
                anchor.innerHTML = '[' + depth + '/' + bmNode.id + '/' + bmNode.index + ']' + bmNode.title;
                span.appendChild(anchor);
            } else {
                folder = document.createElement('span');
                folder.setAttribute('id', bmNode.id);
                folder.innerHTML = '[' + depth + '/' + bmNode.id + '/' + bmNode.index + '/' + bmNode.title + ']';
                span.appendChild(folder);
            }
        }
        return span;
    };

    handleKeyDown = function(e ) {
        if (e.ctrlKey && e.keyIdentifier == 'U+0032') { // Ctrl-2
            toggleSub();
        }
    };

    var forest_ = [];
    forest_.createTree = function() {
      var tree = new bmm.BookmarkTree();

      this.append(tree);
      return tree;
    };

    // // add TreeView to DOM
    // initTree = function( divId ){
    //   var div = $(''+divId);
    //
    //
    //   // init View obj
    //   var tv = bmm.bookmarks.createTreeView();
    //   // init VM obj & bind to Model
    //   var tvm = bmm.bookmarks.createTreeViewModel();
    //   tvm.setBackend(chrome.bookmarks);
    //   // set VM obj of View ( set reference & register events )
    //   tv.setViewModel(tvm);
    //   // register View events to handler in Controller ? BMM ? @TODO
    //   tv.addEventListener('click', this.handleTreeViewClick());
    //   //...
    // };

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
                if (e.target.id) {
                    listBookmarks('bm-list1', e.target.id);
                }
            }), true);
            // $('dbg1').addEventListener('click', function(e){
                // console.log(e.clientX, e.clientY);
            // });
            loadBookmarkTree('bm-tree1');

            document.addEventListener('keydown', handleKeyDown);

            // initTree('bm-tree1');
        }
    };

}).call(this);
