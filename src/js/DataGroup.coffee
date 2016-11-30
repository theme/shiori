define ['lib/EventEmitter', 'lib/moment'], (EventEmitter, Moment) ->

    SECOND = 1000 # milliseconds
    MIN = SECOND * 60
    HOUR = MIN * 60
    DAY = HOUR * 24
    WEEK = DAY * 7
    MONTH = DAY * 30
    YEAR = MONTH * 12

    class DataGroup extends THREE.Object3D
        constructor: () ->
            super
            @event = new EventEmitter

        addPoint: (p) ->
            @add p
            @event.emit 'addpoint'

        setVisible: (f = true)->
            if @visible == f or undefined == f then return
            @visible = f
            for c in @children
                do (c) -> c.visible = f
            @event.emit 'visible',f

        rangeOf: (corr) ->
            arr = @children
            if arr.length > 0
                arr.sort (a,b)-> a.position[corr]-b.position[corr]
                cmin = arr[0].position[corr]
                cmax = arr[arr.length-1].position[corr]
                return [cmin,cmax]
            else
                return null

        layoutY: (camera, renderer) ->
            # calculate Y scale
            canvasSize = renderer.getSize()
            zoom = camera.zoom
            xrange = canvasSize.width * 1 / zoom # ms
            for p in @children
                pm = Moment(p.date)
                switch # different zoom level, different y unit
                    when xrange < 2 * SECOND
                        yrange = SECOND # in order to fully span points on y
                        msDiff = pm.diff pm.clone().startOf('second')
                    when xrange < 2 * MIN
                        yrange = MIN # in order to fully span points on y
                        msDiff = pm.diff pm.clone().startOf('minute')
                    when xrange < 2 * HOUR
                        yrange = HOUR
                        msDiff = pm.diff pm.clone().startOf('hour')
                    when xrange < 2 * DAY
                        yrange = DAY
                        msDiff = pm.diff pm.clone().startOf('day')
                    when xrange < 2 * WEEK
                        yrange = WEEK
                        msDiff = pm.diff pm.clone().startOf('week')
                    when xrange < 2 * MONTH
                        yrange = MONTH
                        msDiff = pm.diff pm.clone().startOf('month')
                    when xrange < 2 * YEAR
                        yrange = YEAR
                        msDiff = pm.diff pm.clone().startOf('year')
                    when xrange < 2 * 20 * YEAR
                        yrange = 20 * YEAR
                        msDiff = pm.diff pm.clone().subtract(20, 'years').startOf('year')
                    when xrange < 2 * 100 * YEAR
                        yrange = 100 * YEAR
                        msDiff = pm.diff pm.clone().subtract(100, 'years').startOf('year')
                    when xrange < 2 * 500 * YEAR
                        yrange = 500 * YEAR
                        msDiff = pm.diff pm.clone().subtract(500, 'years').startOf('year')
                    else
                        yrange = 5000 * YEAR
                        msDiff = pm.diff pm.clone().subtract(5000, 'years').startOf('year')

                msY = msDiff - 0.5 * yrange
                posY = msY * canvasSize.height / zoom / yrange
                p.position.y = posY
                # p.position.y = Math.random() * yrange

    return DataGroup

