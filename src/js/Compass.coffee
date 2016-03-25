define ['log','axis'], (log, Axis) ->
    V3 = THREE.Vector3 # helper
    class Compass extends THREE.Object3D
        constructor: () ->
            THREE.Object3D.call @
            v = new THREE.Vector3
            @.add new Axis(v, new V3(10,0,0),0,10,'Time','red',[10,5,1])
            @.add new Axis(v, new V3(0,10,0),0,10,'y','green',[10,5,1])
            @.add new Axis(v, new V3(0,0,-10),0,10,'-z','blue',[10,5,1])
            return
    return Compass
