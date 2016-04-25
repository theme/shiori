define ()->
    class Line extends THREE.Line
        constructor: (a, b, color) ->
            @material = new THREE.LineBasicMaterial({color:color})
            @geometry = new THREE.Geometry
            @geometry.vertices.push(
                a.clone(),
                b.clone()
            )
            super @geometry,@material
            return
    return Line

