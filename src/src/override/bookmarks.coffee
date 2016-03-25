requirejs.config { baseUrl: '/js' }
require ['log','Compass','WebPage','InputMixer'], (log, Compass, WebPage, InputMixer) ->
    canvas = null
    scene = null

    camera = null
    pCam = null
    oCam = null

    renderer = null

    clock = new THREE.Clock
    stopTime = 5
    mixer = null    # animation player
    mixerActions = []   # animation actions list

    # helper
    ccw = -> canvas.clientWidth
    cch = -> canvas.clientHeight
    cas = -> ccw() / cch()

    # camera
    initCamera = ->
        # Perspective
        pCam = new THREE.PerspectiveCamera 75, ccw()/cch(),1,100
        pCam.update = ->
            @aspect = ccw()/cch()
            @updateProjectionMatrix()
        pCam.tgt = new THREE.Vector3
        pCam.position.set 0,5,20

        # Orthographic
        r = 4
        oCam = new THREE.OrthographicCamera(
            ccw()/-r, ccw()/+r, cch()/+r, cch()/-r, -1000, 1000
        )
        oCam.r = r
        oCam.update = ->
            @left   = - ccw()/r
            @right  = + ccw()/r
            @top    = + cch()/r
            @bottom = - cch()/r
            @updateProjectionMatrix()
        oCam.tgt = new THREE.Vector3
        oCam.position.set 0,5,20

        camera = oCam
        return

    switchCam = (type) ->
        a2b = (a,b) -> camera = b
        switch type
            when 'oCam'
                a2b pCam,oCam if camera != oCam
            when 'pCam'
                a2b oCam,pCam if camera != pCam
            when 'nextCam'
                if camera == pCam then a2b pCam,oCam
                else a2b oCam,pCam
        return camera

    # test el size after 500 ms, callback if size changed
    watchResize = (el, callback) ->
        h = el.clientHeight # remember value of now
        w = el.clientWidth
        return setInterval( -> # check value after 500ms
            if (el.clientHeight != h || el.clientWidth != w)
                h = el.clientHeight
                w = el.clientWidth
                callback()
                return
        , 500)

    resetCameraView = ->
        canvas.width = canvas.clientWidth
        canvas.height = canvas.clientHeight
        renderer.setViewport(0,0,canvas.clientWidth, canvas.clientHeight)
        camera.update()


    init = ->
        # canvas
        canvas = document.getElementById("3jscanvas")

        # renderer
        renderer = new THREE.WebGLRenderer {canvas:canvas}
        renderer.setClearColor new THREE.Color 0x003366

        # camera
        initCamera()

        # reset view
        resetCameraView()

        # Watch vanvas resize
        watchResize canvas, resetCameraView

        # navigation input & camera control
        InputMixer.decorate canvas # cavas now has 'zoom','rotate' ev
        camera.lookAt camera.tgt

        # zoom
        canvas.addEventListener 'zoom', (e) ->
            camera.zoom -= e.detail if camera.zoom-e.detail>0.1
            camera.updateProjectionMatrix()
            return

        # rotate
        canvas.addEventListener 'rotate', (e) ->
            v = camera.position.clone().sub camera.tgt
            v.applyAxisAngle(
                new THREE.Vector3(0,1,0),
                -e.detail
            )
            camera.position.copy v.add camera.tgt
            camera.lookAt camera.tgt
            return

        # pan
        canvas.addEventListener 'pan', (e) ->
            speed = 4
            camUp = new THREE.Vector3 0,1,0
            camRight = new THREE.Vector3 1,0,0
            q = new THREE.Quaternion
            q.setFromRotationMatrix camera.matrixWorld
            camUp.applyQuaternion q
            camRight.applyQuaternion q

            v = camera.tgt.clone().sub camera.position
            camera.position.add camRight.multiplyScalar(
                -e.detail.deltaX / camera.zoom * speed)
            camera.position.add camUp.multiplyScalar(
                e.detail.deltaY / camera.zoom * speed)
            camera.tgt.copy v.add camera.position
            return

        # change camera
        canvas.addEventListener 'cam', (e) ->
            switchCam e.detail
            return

    animate = ->
        requestAnimationFrame animate
        render()
        
    render = ->
        delta = clock.getDelta()
        renderer.render(scene, camera)
        scene.traverse (obj) -> obj.update?()

        mixer.update delta # animation

        # stop play after stopTime
        if clock.elapsedTime > stopTime
            for c in mixerActions
                do (c) -> c.stop()

    # watch chrome history
    watchHistory = (scene) ->
        chrome.history.onVisited.addListener (hi)->
            p = new WebPage(hi.url, hi.lastVisitTime)
            scene.add(p)

    # load scene & start render
    loader = new THREE.ObjectLoader
    loader.load("/models/untitled.json", (loadedScene) ->
        scene = loadedScene
        scene.fog = new THREE.Fog 0xffffff, 2000, 10000

        mixer = new THREE.AnimationMixer scene
        for a in loadedScene.animations
            do (a) ->
                mixerActions.push mixer.clipAction(a).play()
        # a box
        for i in [0..9]
            for j in [0..9]
                geometry = new THREE.BoxGeometry( 1, 0.1, 1 )
                material = new THREE.MeshBasicMaterial( {color: 0x55ff00} )
                cube = new THREE.Mesh( geometry, material )
                cube.position.x = i * 2
                cube.position.z = - j * 2
                scene.add( cube )

        scene.add( new Compass )
        # scene.add( new WebPage("wikipedia.org") )
        watchHistory(scene)

        #TODO calculate WebPage position

        init()
        # scene.add(camera)
        animate()
    , (xhr) -> console.log xhr.loaded/xhr.total*100+'% loaded'
    )
