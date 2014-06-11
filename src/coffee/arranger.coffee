# jQuery : document.jeady
$ ->
    console.log('document.ready()')
    # when user click
    $('#search-button').click ->
        searchBookmarks()
        event.preventDefault()
        return
    # when user input enter
    $('#search-form').submit ->
        searchBookmarks()
        event.preventDefault()
        return
    return

# search function
searchBookmarks = ->
    console.log('searchBookmarks()')
    if $('#search-text').val()
        $('#search-results').empty()
        $('#panel-search-results').removeClass("hidden")
        dumpBookmarks($('#search-text').val())
    else
        $('#search-results').empty()
        $('#panel-search-results').addClass("hidden")
    return

# Traverse the bookmark tree, and print the folder and nodes.
dumpBookmarks = (query) ->
  bookmarkTreeNodes = chrome.bookmarks.getTree(
    (bookmarkTreeNodes) ->
      $('#search-results').append(dumpTreeNodes(bookmarkTreeNodes, query))
      return
  )
  return

dumpTreeNodes = (bookmarkNodes, query) ->
  list = $('<ul>')
  for node in bookmarkNodes
    list.append(dumpNode(node, query))
  return list

dumpNode = (bookmarkNode, query) ->
    # only search in titles
    if bookmarkNode.title
        if query and !bookmarkNode.children # not folder
            if String(bookmarkNode.title).indexOf(query) == -1
                return $('<span></span>')

        anchor = $('<a>')
        anchor.attr('href', bookmarkNode.url)
        anchor.attr('target', "_blank")
        anchor.text(bookmarkNode.title)
    
        span = $('<span>')

    # adjust span
        span.append(anchor)

    li = $( if bookmarkNode.title then '<li>' else '<div>').append(span)
    if bookmarkNode.children and bookmarkNode.children.length > 0
        li.append(dumpTreeNodes(bookmarkNode.children, query))
    return li
 
