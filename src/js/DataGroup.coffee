define ['lib/EventEmitter', 'lib/moment'], (EventEmitter, Moment) ->

    SECOND = 1000 # milliseconds
    MIN = SECOND * 60
    HOUR = MIN * 60
    DAY = MIN * 24
    WEEK = DAY * 7
    MONTH = DAY * 30
    YEAR = MONTH * 12

    class DataGroup extends THREE.Object3D
        constructor: () ->
            super
            @event = new EventEmitter

        setVisible: (f = true)->
            if @visible == f or undefined == f then return
            @visible = f
            for c in @children
                do (c) -> c.visible = f
            @event.emit 'visible',f

        toggleVisible: ()->
            if @visible then @setVisible false
            else @setVisible true

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
            rect = renderer.domElement.getBoundingClientRect()
            zoom = camera.zoom
            xrange = rect.width / zoom
            yrange = rect.height / zoom
            for p in @children
                pm = Moment(p.date)
                switch
                    when xrange < 2 * SECOND
                        yMSspan = SECOND # in order to fully span points on y
                        msDiff = pm.diff pm.clone().startOf('second')
                    when xrange < 2 * MIN
                        yMSspan = MIN # in order to fully span points on y
                        msDiff = pm.diff pm.clone().startOf('minute')
                    when xrange < 2 * HOUR
                        yMSspan = HOUR
                        msDiff = pm.diff pm.clone().startOf('hour')
                    when xrange < 2 * DAY
                        yMSspan = DAY
                        msDiff = pm.diff pm.clone().startOf('day')
                    when xrange < 2 * WEEK
                        yMSspan = WEEK
                        msDiff = pm.diff pm.clone().startOf('week')
                    when xrange < 2 * MONTH
                        yMSspan = MONTH
                        msDiff = pm.diff pm.clone().startOf('month')
                    when xrange < 2 * YEAR
                        yMSspan = YEAR
                        msDiff = pm.diff pm.clone().startOf('year')
                    when xrange < 2 * 20 * YEAR
                        yMSspan = 20 * YEAR
                        msDiff = pm.diff pm.clone().subtract(20, 'years').startOf('year')
                    when xrange < 2 * 100 * YEAR
                        yMSspan = 100 * YEAR
                        msDiff = pm.diff pm.clone().subtract(100, 'years').startOf('year')
                    when xrange < 2 * 500 * YEAR
                        yMSspan = 500 * YEAR
                        msDiff = pm.diff pm.clone().subtract(500, 'years').startOf('year')
                    else
                        yMSspan = 5000 * YEAR
                        msDiff = pm.diff pm.clone().subtract(5000, 'years').startOf('year')

                posY = yrange * msDiff * 2 / yMSspan
                p.position.y = posY
                # console.log 'yrange=', yrange
                console.log 'p.position.y', p.position.y

    return DataGroup

