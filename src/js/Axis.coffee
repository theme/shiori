define ['Line'], (Line) ->
    V3 = THREE.Vector3
    class Axis extends THREE.Object3D
        constructor: (a = new V3, b = new V3(10,0,0),m,n,name,c,r)->
            super
            startPoint = a
            endPoint = b
            @lower = if m then m else 0
            @upper = if n then n else 0
            @name = if name then name else ''
            @color = if c then c else 'yellow'

            # property
            @vector = endPoint.clone().sub(startPoint)
            @length = @vector.length()
            @rangeLength = @upper - @lower
            @scaleRatio = @length / @rangeLength

            # axis line
            line = new Line a.x,a.y,a.z,b.x,b.y,b.z,@color
            @.add(line)
            # arraow and marks
            arrowGeo = new THREE.CylinderGeometry(0, 1, 5, 8, 8)
            material = new THREE.MeshBasicMaterial {color:@color}
            arrow = new THREE.Mesh(arrowGeo, material)

            arrow.position.set(0,2.5,0)  # move up, reset center
            arrow.updateMatrix()
            arrow.geometry.applyMatrix(arrow.matrix)
            arrow.matrix.identity()
            arrow.position.copy(endPoint)
            arrow.quaternion.setFromUnitVectors(
                new THREE.Vector3(0,1,0),
                @vector.normalize()
            )
            @.add(arrow)

            # ruler marks
            marks = new THREE.Object3D()
            @rulerMarks = if r then r.sort((a,b)-> a < b) else [10,5,1]
            @rulerMarks.map (u) ->
                [0...@rangeLength/u].map (i) -> # draw the scale marks
                    lineGeo = new THREE.Geometry
                    y = i*u*@scaleRatio
                    lineGeo.vertices.push(
                        new THREE.Vector3(0, y, 0),
                        new THREE.Vector3(u*0.1, y, 0)
                    )
                    marks.add(new THREE.Line(lineGeo, material))
                    return
                return

            marks.quaternion.setFromUnitVectors(
                new THREE.Vector3(0,1,0),
                @vector.normalize()
            )
            @.add(marks)
            return
    return Axis
