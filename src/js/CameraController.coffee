define ['InputMixer','lib/EventEmitter'], (InputMixer,EventEmitter) ->
    class CameraController extends EventEmitter
        constructor: (canvas)->
            super
            @canvas = canvas
            @cameraList = []
            @pCamList = []
            @oCamList = []
            @ccam = null # current Camera

            self = this
            InputMixer.decorate canvas # add following events
            @canvas.addEventListener 'zoom', (e) -> self.zoomP e.detail
            @canvas.addEventListener 'rotate', (e) -> self.rotateP e.detail
            @canvas.addEventListener 'pan', (e) ->
                self.panP e.detail.deltaX, e.detail.deltaY
            @canvas.addEventListener 'cam', (e) -> self.switchCam e.detail

        # helper
        ccw: -> @canvas.clientWidth
        cch: -> @canvas.clientHeight
        p2c: (pix) -> pix * @ccam.r / @ccam.zoom

        zoom: (z) ->
            @ccam.zoom = z if z > 0
            @ccam.updateProjectionMatrix()
            @emit 'zoom', @ccam.zoom
            @emit 'render'

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
            @emit 'render'

        pos: () -> @ccam.position.clone()

        moveTo: (p) ->
            v = @ccam.tgt.clone().sub @ccam.position
            @ccam.position.copy p
            @ccam.tgt.copy v.add @ccam.position
            @emit 'render'

        panP: (px,py)->
            camUp = new THREE.Vector3 0,1,0
            camRight = new THREE.Vector3 1,0,0
            v = @ccam.tgt.clone().sub @ccam.position
            @ccam.translateOnAxis(camRight, - @p2c px)
            @ccam.translateOnAxis(camUp, @p2c py)
            @ccam.tgt.copy v.add @ccam.position
            @emit 'render'

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
                            @emit 'render'
                            return
                when 'pCam'
                    if @ccam instanceof THREE.OrthographicCamera
                        if @pCamList.length > 0
                            @ccam = @pCamList[0]
                            @emit 'render'
                            return
                when 'nextCam'
                    i = @cameraList.indexOf @ccam
                    if i == @cameraList.length - 1
                        @ccam = @cameraList[0]
                    else
                        @ccam = @cameraList[i+1]
                    @emit 'render'
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
            @emit 'render'

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

