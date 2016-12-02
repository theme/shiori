define ['lib/EventEmitter', 'lib/moment'], (EventEmitter, Moment) ->

    SECOND = 1000 # milliseconds
    MIN = SECOND * 60
    HOUR = MIN * 60
    DAY = HOUR * 24
    WEEK = DAY * 7
    MONTH = DAY * 30
    YEAR = MONTH * 12

    HOUR_COLOR = 'yellow'
    DAY_COLOR = 'green'
    MONTH_COLOR = 'aqua'
    YEAR_COLOR = 'white'

    class GrideGroup  extends THREE.Object3D
        constructor: () ->
            super

            @hourG = new THREE.GridHelper(HOUR/2, HOUR/MIN, HOUR_COLOR, HOUR_COLOR)
            @hourG.rotation.x = Math.PI/2
            @add @hourG

            @dayG = new THREE.GridHelper(DAY/2, DAY/HOUR, DAY_COLOR, DAY_COLOR)
            @dayG.rotation.x = Math.PI/2
            @add @dayG

            @monthG = new THREE.GridHelper(MONTH/2, MONTH/DAY, MONTH_COLOR, MONTH_COLOR)
            @monthG.rotation.x = Math.PI/2
            @add @monthG

            @yearG = new THREE.GridHelper(YEAR/2, YEAR/MONTH, YEAR_COLOR, YEAR_COLOR)
            @yearG.rotation.x = Math.PI/2
            @add @yearG

            @position.setZ( -1 )

        update: (cam) ->
            m = Moment(cam.position.x)
            @hourG.position.setX( m.clone().startOf('hour').add(0.5, 'hour'))
            @dayG.position.setX( m.clone().startOf('day').add(0.5, 'day') )
            @monthG.position.setX( m.clone().startOf('month').add(0.5, 'month') )
            @yearG.position.setX( m.clone().startOf('year').add(0.5, 'year') )

            @position.setY( cam.position.y )

    return GrideGroup
