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

            return

        len: ()-> @rB.clone().sub(@rA).length()

        addScale: (name, unit, coordName, color)->
            @scales.push new RulerScale(name,unit,coordName,color)
            return

        drawBody: ()->
            @line = new Line @rA,@rB,@color
            @add @line

        drawScales: ()->
            @scales.map (s)=> s.drawOnRuler @

        reDraw: ()->
            for i in @children
                do (i) => @remove i
            @drawBody()
            @drawScales()
            return

    return Ruler

