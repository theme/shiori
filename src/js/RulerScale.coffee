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
            dA = r.wA[@coordName] # data A vlue
            dS = @unit * Math.ceil (dA / @unit) # data Start value
            rVec = r.rB.clone().sub(r.rA)
            rLen = rVec.length()
            dLen = rLen * r.ratioW2R
            times = Math.floor(( dLen - (dS-dA)) / @unit) + 1
            if times > @limitTimes then return

            v = rVec.clone().setLength(1)
            rS = r.rA.clone().addScaledVector(v,(dS-dA)/dLen)
            rUnit = @unit / r.ratio

            console.log 'dA',dA,'dS',dS
            console.log 'r.ratio',r.ratio,'rLen',rLen, 'dLen', dLen, 'times', times
            [0...times].map (i)=>
                a = rS.clone().addScaledVector(v, i * rUnit)
                b = a.clone().add new V3(0, -r.width/2, 0)
                line = new Line a.x,a.y,a.z,b.x,b.y,b.z,@color
                r.add line
            return

    return RulerScale

