define ['lib/EventEmitter', 'DataGroup', 'log'], (EventEmitter, DataGroup, Log) ->

    Model = {
        historyGroup : new DataGroup,
        bookmarksGroup : new DataGroup,

        allLabels: []
        renderedLabels: []
    }

    return Model
