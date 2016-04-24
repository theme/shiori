define ['RulerScale','Line'],(RulerScale,Line) ->
    V3 = THREE.Vector3
    class Ruler extends THREE.Object3D
        constructor: (rA =new V3, rB =new V3, width =5, color='yellow')->
            super
            # ruler's 2 ends in camera space (A -> B)
            @rA = rA
            @rB = rB
            @width = width
            @color = color
            @scales = []
            # corresponding data ranges's 2 value: [A, B]
            @dA = rA
            @dB = rB
            return

        len: ()-> @rB.clone().sub(@rA).length()

        addScale: (name, unit, coordName, color)->
            @scales.push new RulerScale(name,unit,coordName,color)
            return

        drawBody: ()->
            f = @rA
            t = @rB
            line = new Line f.x,f.y,f.z,t.x,t.y,t.z,@color
            @add line

        drawScales: ()->
            @scales.map (s)=> s.drawOnRuler @

        reDraw: ()->
            for i in @children
                do (i) => @remove i
            @drawBody()
            @drawScales()
            return

    return Ruler

