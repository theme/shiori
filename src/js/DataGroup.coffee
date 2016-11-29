define ['lib/EventEmitter', 'lib/moment'], (EventEmitter, Moment) ->

    MIN = 3600 * 1000 # milliseconds
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
            console.log 'layoutY'
            # calculate Y scale
            rect = renderer.domElement.getBoundingClientRect()
            zoom = camera.zoom
            xrange = rect.width / zoom
            for p in @children
                pm = Moment(p.date)
                switch
                    when xrange < 2 * MIN
                        yrange = MIN # in order to fully span points on y
                        diff = pm.diff pm.clone().startOf('minute')
                    when xrange < 2 * HOUR
                        yrange = HOUR
                        diff = pm.diff pm.clone().startOf('hour')
                    when xrange < 2 * DAY
                        yrange = DAY
                        diff = pm.diff pm.clone().startOf('day')
                    when xrange < 2 * WEEK
                        yrange = WEEK
                        diff = pm.diff pm.clone().startOf('week')
                    when xrange < 2 * MONTH
                        yrange = MONTH
                        diff = pm.diff pm.clone().startOf('month')
                    when xrange < 2 * YEAR
                        yrange = YEAR
                        diff = pm.diff pm.clone().startOf('year')
                    when xrange < 2 * 20 * YEAR
                        yrange = 20 * YEAR
                        diff = pm.diff pm.clone().substrace(20, 'years').startOf('year')
                    when xrange < 2 * 100 * YEAR
                        yrange = 100 * YEAR
                        diff = pm.diff pm.clone().substrace(100, 'years').startOf('year')
                    when xrange < 2 * 500 * YEAR
                        yrange = 500 * YEAR
                        diff = pm.diff pm.clone().substrace(500, 'years').startOf('year')
                    else
                        yrange = 5000 * YEAR
                        diff = pm.diff pm.clone().substrace(5000, 'years').startOf('year')

                posY = ( yrange * 0.5 - diff ) / zoom
                p.position.y = posY

    return DataGroup

