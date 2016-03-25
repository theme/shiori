define ()->
    class Line extends THREE.Line
        constructor: (x1,y1,z1, x2,y2,z2, color) ->
            @material = new THREE.LineBasicMaterial({color:color})
            @geometry = new THREE.Geometry
            @geometry.vertices.push(
                @a = new THREE.Vector3(x1,y1,z1),
                @b = new THREE.Vector3(x2,y2,z2)
            )
            super @geometry,@material
            return
    return Line

