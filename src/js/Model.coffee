define ['DataGroup', 'log'], (DataGroup, Log) ->

    Model = {
        # Data
        historyGroup : new DataGroup,
        bookmarksGroup : new DataGroup,

        # Labeling
        allLabels: []
        renderedLabels: []
        visible: false
    }

    return Model
