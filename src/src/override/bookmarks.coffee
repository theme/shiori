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

    # contents
    bookmarksObj = new THREE.Object3D

    # helper
    ccw = -> canvas.clientWidth
    cch = -> canvas.clientHeight
    cas = -> ccw() / cch()
    $ = (id) -> return document.getElementById id

    # constant
    msInYear = 1000 * 3600 * 24 * 365

    # camera
    initCamera = ->
        # Perspective
        pCam = new THREE.PerspectiveCamera 75, ccw()/cch(),1,100
        pCam.update = ->
            @aspect = ccw()/cch()
            @updateProjectionMatrix()
        pCam.tgt = new THREE.Vector3
        pCam.zoomTo = (min,max)-> return
        pCam.position.set 0,0,20

        # Orthographic
        r = 4
        oCam = new THREE.OrthographicCamera(
            ccw()/-r, ccw()/+r, cch()/+r, cch()/-r, -1000, 1000
        )
        oCam.r = r
        oCam.update = ->
            @left   = - ccw()/oCam.r
            @right  = + ccw()/oCam.r
            @top    = + cch()/oCam.r
            @bottom = - cch()/oCam.r
            @updateProjectionMatrix()
        oCam.tgt = new THREE.Vector3
        oCam.zoomTo = (min,max)->
            # calc zoom
            z = (@right-@left)/(max-min)
            # set zoom
            @zoom = z
            log min,max,'zoom',@zoom
            # update matrix
            @updateProjectionMatrix()
            # set position
            c = (min + max)/2
            log 'oCam.position.x',c
            @position.set c,0,20

        oCam.position.set 0,0,20

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
            speed = 0.1
            z = camera.zoom-e.detail*speed*camera.zoom
            camera.zoom = z if z > 0
            camera.updateProjectionMatrix()
            log 'zoom',camera.zoom
            render()
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
            render()
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
            render()
            return

        # change camera
        canvas.addEventListener 'cam', (e) ->
            switchCam e.detail
            render()
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
            log 'history onVisited',p.id,p.url
            scene.add(p)

    showAllHistory = (scene, camera) ->
        min = Date.now()
        max = 0
        # show history
        chrome.history.search {text:'',maxResults:1000},(a)->
            log a.length,'history record(s)'
            for hi in a
                do (hi) ->
                    if hi.lastVisitTime < min then min = hi.lastVisitTime
                    if max < hi.lastVisitTime then max = hi.lastVisitTime
                    p = new WebPage(hi.url, hi.lastVisitTime)
                    p.translateX p.atime/msInYear
                    scene.add p
            camera.zoomTo min/msInYear,max/msInYear
            render()
            return
        # show bookmarks
        bmCount = 0
        chrome.bookmarks.getTree (bmlist)->
            addBmNode = (n)->
                if n.dateAdded < min then min = n.dateAdded
                if max < n.dateAdded then max = n.dateAdded
                bmCount += 1
                p = new WebPage n.url,n.dateAdded
                p.translateX p.atime/msInYear
                bookmarksObj.add p
                return
            traverseTree = (bmlist, callback)-> # define
                for bm in bmlist
                    do (bm)->
                        if bm.url? then callback bm
                        if bm.children?
                            traverseTree bm.children, callback
                return
            traverseTree bmlist,addBmNode
            log bmCount,'bookmarks'
            camera.zoomTo min/msInYear,max/msInYear
            scene.add bookmarksObj
            render()
            return
        return

    watchToggles = () ->
        $('check-bookmarks').addEventListener 'change', (e)->
            if !e.target?.checked then bookmarksObj.traverse (o) ->
                o.visible = false
            else bookmarksObj.traverse (o) -> o.visible = true
            render()
            return
        return

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


        init()
        watchHistory scene
        showAllHistory scene,camera

        # toggle on/off bookmarks
        watchToggles()

        # animate()
    , (xhr) -> console.log xhr.loaded/xhr.total*100+'% loaded'
    )

