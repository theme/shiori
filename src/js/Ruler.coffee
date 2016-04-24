define ['RulerScale','Line'],(RulerScale,Line) ->
    V3 = THREE.Vector3
    class Ruler extends THREE.Object3D
        constructor: (rA =new V3, rB =new V3, width =5, color='yellow')->
            super

            # on lens, coordinate in camera space
            @rA = rA
            @rB = rB
            @width = width
            @color = color
            @scales = []

            # world space
            @ratio = 1 # Math.cos( 0 )
            @wA = new THREE.Vector3

            return

        len: ()-> @rB.clone().sub(@rA).length()

        addScale: (name, unit, coordName, color)->
            @scales.push new RulerScale(name,unit,coordName,color)
            return

        drawBody: ()->
            f = @rA
            t = @rB
            @add new Line f.x,f.y,f.z,t.x,t.y,t.z,@color

        drawScales: ()->
            @scales.map (s)=> s.drawOnRuler @

        reDraw: ()->
            @children.map (i)=> @remove i
            @drawBody()
            @drawScales()
            return

    return Ruler

