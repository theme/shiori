define ['Label','Line'],(Label,Line)->
    class DataPoint extends THREE.Object3D
        constructor: ()->
            super
            @add new Line -1,0,0, 1,0,0,'yellow'
            @add new Line 0,-1,0, 0,1,0,'yellow'
        setXYZ: (x,y,z)->
            @position.set new THREE.Vector3 x,y,z
    return DataPoint
