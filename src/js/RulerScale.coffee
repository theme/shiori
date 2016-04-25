define ['Line','Label'],(Line,Label) ->
    V3 = THREE.Vector3
    class RulerScale extends THREE.Object3D
        constructor: (name,wUnit,coordName,color)->
            super
            @name = name
            @wUnit = wUnit # coordinate unit to draw scale
            @coordName = coordName
            @limitTimes = 50
            @color = color
            return
        
        drawOnRuler: (r)->
            # wA---(Offset)--wS---wB : points in world space
            # rA             rS   rB : points in ruler local space
            #                ||||||| : drawings of ruler scales
            #                 (rSi) 
            # 
            # know: rA, rB, wUnit
            # Q: rS, n, rSi
            #
            wA = r.rA.clone()
            r.localToWorld wA

            wAc = wA[@coordName]
            wSc = @wUnit * Math.ceil (wAc / @wUnit)
            wS = wA.clone()
            wS[@coordName] = wSc

            rS = wS.clone()
            r.localToWorld rS

            wB = r.rB.clone()
            r.localToWorld wB
            wSB = wS.distanceTo wB
            n = wSB / @wUnit
            if n > @limitTimes then return

            rvSB = r.rB.clone().sub rS
            
            for i in [0...n]
                do (i)=>
                    a = rS.clone().addScaledVector(rvSB, i / n)
                    b = a.clone().add new V3(0, -r.width/2, 0)
                    line = new Line a,b,@color
                    r.add line
            return

    return RulerScale

