define ['Line','Label'],(Line,Label) ->
    V3 = THREE.Vector3
    class RulerScale extends THREE.Object3D
        constructor: (name,unit,coordName,color)->
            super
            @name = name
            @unit = unit # coordinate unit to draw scale
            @coordName = coordName
            @limitTimes = 50
            @color = color
            return
        
        drawOnRuler: (r)->
            # wA-------------wS---wB : points in world space
            # rA---(Offset)--rS---rB : points in ruler local space
            #                ||||||| : drawings of ruler scales
            # aA-------------aS---aB : label of ruler scales
            # 
            # number of scales: n = wSB / unit
            #
            # start of scales: rS = rA + rAB * (aAS / aAB)
            #
            # pos of scale i:     = rS + i * rUnit 
            #
            # among them:
            # rUnit = @unit * (rSB / wSB)
            # aS = @unit * Math.ceil (aA / @unit)
            
            aA = r.rA[@coordName]
            aB = r.rB[@coordName]
            aAB = aB - aA
            aS = @unit * Math.ceil (aA / @unit)
            aAS = aS - aA
            
            rAB = r.rB.clone().sub(r.rA)
            rS = rAB.multiplyScalar(aAS/aAB).add r.rA

            wS = rS.clone()
            r.localToWorld wS
            wB = r.rB.clone()
            r.localToWorld wB

            wSB = wS.distanceTo wB
            n = wSB / @unit
            if n > @limitTimes then return

            rSB = rS.distanceTo r.rB
            rUnit = @unit * (rSB / wSB)

            v = r.rB.clone().sub(rS).setLength 1
            for i in [0...n]
                do (i)=>
                    a = rS.clone().addScaledVector(v, i * rUnit)
                    b = a.clone().add new V3(0, -r.width/2, 0)
                    line = new Line a,b,@color
                    r.add line
            return

    return RulerScale

