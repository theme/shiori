define ['Line','Label'],(Line,Label) ->
    # TODO delete Cube
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
            vA = r.dA[@coordName] # value at data point A
            vB = r.dB[@coordName]
            vLen = vB - vA # TODO abs ?
            if vLen = 0 then return
            vS = @unit * Math.ceil (vA / @unit) # data Start value
            times = Math.floor(( vLen - (vS-vA)) / @unit) + 1
            if times > @limitTimes then return

            rVec = r.rB.clone().sub(r.rA)
            rLen = rVec.length()
            v = rVec.clone().setLength 1
            rS = r.rA.clone().addScaledVector(v, (vS-vA)/vLen)
            rUnit = @unit * (rLen / vLen)
            [0...times].map (i)=>
                a = rS.clone().addScaledVector(v, i * rUnit)
                b = a.clone().add new V3(0, -r.width/2, 0)
                line = new Line a.x,a.y,a.z,b.x,b.y,b.z,@color
                r.add line
            return

    return RulerScale

