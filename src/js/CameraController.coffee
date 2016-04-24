define ['Ruler','InputMixer','lib/EventEmitter'],(Ruler,InputMixer,EventEmitter)->
    V3 = THREE.Vector3
    class CameraController extends EventEmitter
        constructor: (canvas)->
            super
            @canvas = canvas
            @cameraList = []
            @pCamList = []
            @oCamList = []
            @ccam = null # current Camera

            @setCurrent @newOrthoCam()

            InputMixer.decorate canvas # add following events
            @canvas.addEventListener 'zoom',(e)=> @zoomP e.detail
            @canvas.addEventListener 'rotate',(e)=> @rotateP e.detail
            @canvas.addEventListener 'pan',(e)=>
                @panP e.detail.deltaX, e.detail.deltaY
            @canvas.addEventListener 'cam',(e)=> @switchCam e.detail

            @rulers = new THREE.Object3D
            r = new Ruler
            hourInDay = 24
            r.addScale 'day', hourInDay, 'x', 'red'
            r.addScale 'hour', 1 , 'x', 'yellow'
            @rulers.add r
            @ccam.add @rulers
            @updateRulers()
            return

        # helper
        ccw: -> @canvas.clientWidth
        cch: -> @canvas.clientHeight
        p2c: (pix)-> pix * @ccam.r / @ccam.zoom # pixel to coord
        c2w: (v3)-> v3.clone().applyMatrix4 @ccam.matrixWorld

        updateRuler : (r) ->
            rLength = @p2c @ccw()
            rPosY = @p2c -0.45 * @cch()
            r.rA.copy new V3(-rLength/2,rPosY,0)
            r.rB.copy new V3( rLength/2,rPosY,0)
            r.width = @p2c 0.05 * @cch()
            z = new V3 0,0,-1
            v = z.clone().applyQuaternion @ccam.quaternion
            r.ratioW2R = Math.cos(v.angleTo z)
            r.wA = @c2w r.rA

        updateRulers: ()->
            @rulers.children.map (r)=>
                @updateRuler r
                r.reDraw()
            @emit 'touched'

        zoom: (z) ->
            if z > 0
                @ccam.zoom = z
                # @ccam.updateProjectionMatrix()
                @updateRulers()
                @emit 'zoom', @ccam.zoom

        zoomP: (p) -> # p in pixcel
            speed = 0.01
            @zoom (1- p*speed) * @ccam.zoom

        rotateP: (p) ->
            v = @ccam.position.clone().sub @ccam.tgt
            v.applyAxisAngle(
                new THREE.Vector3(0,1,0),
                - Math.atan(@p2c(p)/v.length())
            )
            @ccam.position.copy v.add @ccam.tgt
            @ccam.lookAt @ccam.tgt
            @updateRulers()

        pos: () -> @ccam.position.clone()

        moveTo: (p) ->
            v = @ccam.tgt.clone().sub @ccam.position
            @ccam.position.copy p
            @ccam.tgt.copy v.add @ccam.position
            @updateRulers()

        panP: (px,py)->
            camUp = new THREE.Vector3 0,1,0
            camRight = new THREE.Vector3 1,0,0
            v = @ccam.tgt.clone().sub @ccam.position
            @ccam.translateOnAxis(camRight, - @p2c px)
            @ccam.translateOnAxis(camUp, @p2c py)
            @ccam.tgt.copy v.add @ccam.position
            @updateRulers()

        regCamera: (camera)->
            @cameraList.push camera
            if camera instanceof THREE.PerspectiveCamera
                @pCamList.push camera
            if camera instanceof THREE.OrthographicCamera
                @oCamList.push camera
            return

        setCurrent: (camera) ->
            if (@cameraList.indexOf camera) == -1
                @regCamera camera
            @ccam = camera
            return

        currentCam: ()-> return @ccam

        switchCam: (type)->
            switch type
                when 'oCam'
                    if @ccam instanceof THREE.PerspectiveCamera
                        if @oCamList.length > 0
                            @ccam = @oCamList[0]
                            @emit 'touched'
                            return
                when 'pCam'
                    if @ccam instanceof THREE.OrthographicCamera
                        if @pCamList.length > 0
                            @ccam = @pCamList[0]
                            @emit 'touched'
                            return
                when 'nextCam'
                    i = @cameraList.indexOf @ccam
                    if i == @cameraList.length - 1
                        @ccam = @cameraList[0]
                    else
                        @ccam = @cameraList[i+1]
                    @emit 'touched'
                    return

        update: (c)->
            if c instanceof THREE.OrthographicCamera
                c.left   = - @ccw()*c.r /2
                c.right  = + @ccw()*c.r /2
                c.top    = + @cch()*c.r /2
                c.bottom = - @cch()*c.r /2
                c.updateProjectionMatrix()
            if c instanceof THREE.PerspectiveCamera
                c.aspect = @ccw()/@cch()
                c.updateProjectionMatrix()
            if c == undefined
                @update @ccam

        lookAtRange: (min,max) ->
            if @ccam instanceof THREE.OrthographicCamera
                @ccam.zoom = (@ccam.right-@ccam.left)/(max-min)
                @ccam.updateProjectionMatrix()
                @ccam.position.set ((min + max)/2),0,20
            if @ccam instanceof THREE.PerspectiveCamera
                @ccam.position.set ((min + max)/2),0,20
            @emit 'zoom', @ccam.zoom
            @updateRulers()

        newOrthoCam: ()->
            oCam = new THREE.OrthographicCamera 0,1,0,1, 0, 100
            oCam.tgt = new THREE.Vector3
            oCam.r = 25/@cch()
            oCam.position.set 0,0,20
            oCam.lookAt oCam.tgt
            @update oCam
            @regCamera oCam
            return oCam

        newPersCam: ()->
            pCam = new THREE.PerspectiveCamera 75, @ccw()/@cch(),1,100
            pCam.r = 25/@cch()
            pCam.tgt = new THREE.Vector3
            pCam.position.set 0,0,20
            pCam.lookAt pCam.tgt
            @regCamera pCam
            return pCam

        newCam: (type)->
            switch type
                when 'oCam'
                    return @newOrthoCam
                when 'pCam'
                    return @newPersCam
                else
                    return @newOrthoCam

    return CameraController

