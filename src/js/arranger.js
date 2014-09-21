(function() {
    var dumpBookmarks, dumpNode, dumpTreeNodes, listBookmarks, searchBookmarks;

    document.onreadystatechange = function () {
        if (document.readyState == "complete") {
            var sbtn = $('#search-button');
            sbtn.addEventListener('click', (function(e) {
                searchBookmarks();
                e.preventDefault();
            }));
            var sform = $('#search-form');
            sform.addEventListener('submit',(function(e) {
                searchBookmarks();
                e.preventDefault();
            }));
            listBookmarks('bookmarks');
        }
    };

    listBookmarks = function(divName) {
        console.log('listBookmarks()');
        var bookmarkTreeNodes, bmlist;
        bookmarkTreeNodes = chrome.bookmarks.getTree(function(bmt) {
            $('#' + divName).appendChild(dumpTreeNodes(bmt, null));
        });
    };

    searchBookmarks = function() {
        console.log('searchBookmarks()');
        if ($('#search-text').value) {
            var results = $('#search-results')
            while( results.firstChild ){
                results.removeChild(result.firstChild);
            }
            var panelresults = $('#panel-search-results');
            panelresults.className.replace(/(?:^|\s)hidden(?!\S)/g,'');
            dumpBookmarks($('#search-text').value);
        } else {
            var results = $('#search-results')
            while( results.firstChild ){
                results.removeChild(result.firstChild);
            }
            var panelresults = $('#panel-search-results');
            panelresults.className += "hidden";
        }
    };

    dumpBookmarks = function(query) {
        console.log('dumpBookmarks()');
        var bookmarkTreeNodes;
        bookmarkTreeNodes = chrome.bookmarks.getTree(function(bmt) {
            $('#search-results').appendChild(dumpTreeNodes(bmt, query));
        });
    };

    dumpTreeNodes = function(bookmarkNodes, query) {
        var list, node, _i, _len;
        list = $('<ul>');
        for (_i = 0, _len = bookmarkNodes.length; _i < _len; _i++) {
            node = bookmarkNodes[_i];
            if (!node.url){   // is folder
                list.appendChild(dumpNode(node, query));
            }
        }
        return list;
    };

    dumpNode = function(bookmarkNode, query) {
        var anchor, folder, li, span;
        span = $('<span>');
        if (bookmarkNode.title) {
            if (query && !bookmarkNode.children) {
                if (String(bookmarkNode.title).indexOf(query) === -1) {
                    return span;
                }
            }
            if (bookmarkNode.url) {
                anchor = $('<a>');
                anchor.setAttribute('href', bookmarkNode.url);
                anchor.setAttribute('target', "_blank");
                anchor.innerHTML= '[' + bookmarkNode.id + '/' + bookmarkNode.index + ']' + bookmarkNode.title;
                span.appendChild(anchor);
            } else {
                folder = $('<p>');
                folder.innerHTML = '[' + bookmarkNode.id + '/' + bookmarkNode.index + '/' + bookmarkNode.title + ']';
                span.appendChild(folder);
            }
        }

        li = $(bookmarkNode.title ? '<li>' : '<div>');
        li.appendChild(span);
        if (bookmarkNode.children && bookmarkNode.children.length > 0) {
            li.appendChild(dumpTreeNodes(bookmarkNode.children, query));
        }
        return li;
    };

}).call(this);
