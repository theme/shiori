define ['Label','Line'],(Label,Line)->
    V3 = THREE.Vector3
    class DataPoint extends THREE.Object3D
        constructor: ()->
            super
            a = new V3 -1,0,0
            b = new V3 +1,0,0
            c = new V3 0,-1,0
            d = new V3 0,+1,0
            @add new Line a,b,'yellow'
            @add new Line c,d,'yellow'
        setXYZ: (x,y,z)->
            @position.set new THREE.Vector3 x,y,z
    return DataPoint
