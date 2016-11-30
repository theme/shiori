define ['lib/EventEmitter', 'lib/moment'], (EventEmitter, Moment) ->

    SECOND = 1000 # milliseconds
    MIN = SECOND * 60
    HOUR = MIN * 60
    DAY = HOUR * 24
    WEEK = DAY * 7
    MONTH = DAY * 30
    YEAR = MONTH * 12

    class GrideGroup  extends THREE.Object3D
        constructor: () ->
            super

            @hourG = new THREE.GridHelper(HOUR, HOUR/MIN, 0x2222, 0x2222)
            @hourG.rotation.x = Math.PI/2
            @add @hourG

            @dayG = new THREE.GridHelper(DAY, DAY/HOUR, 0x4444, 0x4444 )
            @dayG.rotation.x = Math.PI/2
            @add @dayG

            @monthG = new THREE.GridHelper(MONTH, MONTH/DAY, 0x8888, 0x8888 )
            @monthG.rotation.x = Math.PI/2
            @add @monthG

            @yearG = new THREE.GridHelper(YEAR, YEAR/MONTH, 0xFFFF, 0xFFFF )
            @yearG.rotation.x = Math.PI/2
            @add @yearG

            @position.setZ( -1 )

        update: (cam) ->
            @hourG.position.setX( Moment(cam.position.x).startOf('hour') )
            @dayG.position.setX( Moment(cam.position.x).startOf('day') )
            @monthG.position.setX( Moment(cam.position.x).startOf('month') )
            @yearG.position.setX( Moment(cam.position.x).startOf('year') )

            @position.setY( cam.position.y )

    return GrideGroup
