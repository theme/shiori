(function() {
  var dumpBookmarks, dumpNode, dumpTreeNodes, listBookmarks, searchBookmarks;

  $(function() {
    $('#search-button').click(function() {
      searchBookmarks();
      event.preventDefault();
    });
    $('#search-form').submit(function() {
      searchBookmarks();
      event.preventDefault();
    });
    listBookmarks('bookmarks');
  });

  listBookmarks = function(divName) {
    var bookmarkTreeNodes;
    bookmarkTreeNodes = chrome.bookmarks.getTree(function(bookmarkTreeNodes) {
      return $('#' + divName).append(dumpTreeNodes(bookmarkTreeNodes, null));
    });
  };

  searchBookmarks = function() {
    console.log('searchBookmarks()');
    if ($('#search-text').val()) {
      $('#search-results').empty();
      $('#panel-search-results').removeClass("hidden");
      dumpBookmarks($('#search-text').val());
    } else {
      $('#search-results').empty();
      $('#panel-search-results').addClass("hidden");
    }
  };

  dumpBookmarks = function(query) {
    var bookmarkTreeNodes;
    bookmarkTreeNodes = chrome.bookmarks.getTree(function(bookmarkTreeNodes) {
      $('#search-results').append(dumpTreeNodes(bookmarkTreeNodes, query));
    });
  };

  dumpTreeNodes = function(bookmarkNodes, query) {
    var list, node, _i, _len;
    list = $('<ul>');
    for (_i = 0, _len = bookmarkNodes.length; _i < _len; _i++) {
      node = bookmarkNodes[_i];
      if (!node.url){   // is folder
          list.append(dumpNode(node, query));
      }
    }
    return list;
  };

  dumpNode = function(bookmarkNode, query) {
    var anchor, folder, li, span;
    if (bookmarkNode.title) {
      if (query && !bookmarkNode.children) {
        if (String(bookmarkNode.title).indexOf(query) === -1) {
          return $('<span></span>');
        }
      }
      span = $('<span>');
      if (bookmarkNode.url) {
        anchor = $('<a>');
        anchor.attr('href', bookmarkNode.url);
        anchor.attr('target', "_blank");
        anchor.text('[' + bookmarkNode.id + '/' + bookmarkNode.index + ']' + bookmarkNode.title);
        span.append(anchor);
      } else {
        folder = $('<p>');
        folder.text('[' + bookmarkNode.id + '/' + bookmarkNode.index + '/' + bookmarkNode.title + ']');
        span.append(folder);
      }
    }
    li = $(bookmarkNode.title ? '<li>' : '<div>').append(span);
    if (bookmarkNode.children && bookmarkNode.children.length > 0) {
      li.append(dumpTreeNodes(bookmarkNode.children, query));
    }
    return li;
  };

}).call(this);
