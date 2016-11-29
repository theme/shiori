define ->

    class DataPoint extends THREE.Points
        constructor: (date)->
            geometry = new THREE.Geometry
            geometry.vertices.push(
                new THREE.Vector3( 0, 0, 0 ),
            )
            super geometry
            @date = date

    return DataPoint

