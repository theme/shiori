define ['DataPoint'], (DataPoint) ->
    class WebPage extends DataPoint
        constructor: (url, title, atime = Date.now())->
            super
            if title?
                @title = title
            else
                matches = url.match(/^https?\:\/\/(?:www\.)?([^\/?#]+)(?:[\/?#]|$)/i)
                @title (if matches? then matches[1] else title)
            @url = url
            @atime = atime

    return WebPage
