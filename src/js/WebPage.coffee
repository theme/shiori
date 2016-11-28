define ['DataPoint','Label', 'Model'], (DataPoint,Label, Model) ->
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

            l = new Label title
            @onAfterRender = ()->
                Model.renderedLabels.push l
            @add l
    return WebPage

