require ['log','Axis','Compass','WebPage','Label','InputMixer','DataGroup','CameraController'], (log, Axis, Compass, WebPage, Label, InputMixer, DataGroup, CameraController) ->
    canvas = null
    scene = null

    camera = null
    pCam = null
    oCam = null
    cameraCtl = null

    renderer = null

    clock = new THREE.Clock
    stopTime = 5
    mixer = null    # animation player
    mixerActions = []   # animation actions list

    # helper
    ccw = -> canvas.clientWidth
    cch = -> canvas.clientHeight
    $ = (id) -> return document.getElementById id

    # labels layer ( in DOM )
    labelroot = $('labelroot')

    # contents
    bookmarksGroup = new DataGroup
    bookmarksGroup.loaded = false
    historyGroup = new DataGroup
    historyGroup.loaded = false
    msInHour = 1000 * 3600

    # HUD on canvas
    hud = null
    class HUD
        constructor: () ->
            @logZoom = 0.8

    initHUD = (camera, render) ->
        hud = new HUD()
        gui = new dat.GUI()
        z = gui.add(hud, 'logZoom', -15, 15).listen()
        z.onFinishChange (value) ->
            camera.zoom = Math.exp(value)
            render()
            return
        return gui

    initCamera = ->
        r = 25/cch()
        # Perspective
        pCam = new THREE.PerspectiveCamera 75, ccw()/cch(),1,100
        pCam.r = r
        pCam.tgt = new THREE.Vector3
        pCam.position.set 0,0,20
        pCam.lookAt pCam.tgt
        pCam.update = ->
            @aspect = ccw()/cch()
            @updateProjectionMatrix()
        pCam.lookAtRange = (min,max)-> return

        # Orthographic
        oCam = new THREE.OrthographicCamera(
            -r*ccw()/2, r*ccw()/2, r*cch()/2, -r*cch()/2, 0, 100
        )
        oCam.r = r
        oCam.tgt = new THREE.Vector3
        oCam.position.set 0,0,20
        oCam.lookAt oCam.tgt
        oCam.update = ->
            @left   = - ccw()*oCam.r /2
            @right  = + ccw()*oCam.r /2
            @top    = + cch()*oCam.r /2
            @bottom = - cch()*oCam.r /2
            @updateProjectionMatrix()
        oCam.lookAtRange = (min,max)->
            @zoom = (@right-@left)/(max-min) # calc zoom
            @updateProjectionMatrix() # update matrix
            @position.set ((min + max)/2),0,20
            log min,max,'zoom:',@zoom,'oCam.position.x',@position.x
        return

    # watch window resize, adjust canvas
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

    handleCanvasResize = ->
        # renderer.setViewport 0,0,ccw(),cch()
        render()

    init = ->
        # canvas
        canvas = document.getElementById("3jscanvas")

        # renderer
        renderer = new THREE.WebGLRenderer {canvas:canvas}
        renderer.setClearColor new THREE.Color 0x003366
        log 'renderer.precision:',renderer.getPrecision()

        # Camera
        initCamera()

        # Camera Control
        cameraCtl = new CameraController canvas, [oCam,pCam]
        cameraCtl.setCurrent oCam
        cameraCtl.on 'render', render

        # Viewport
        handleCanvasResize()
        watchResize canvas, handleCanvasResize

        # HUD widget
        $('HUD').appendChild initHUD(camera, render).domElement
        cameraCtl.on('zoom', (z)->
            hud.logZoom = Math.log cameraCtl.currentCam().zoom
        )

        return

    updateAnimations = ->
        delta = clock.getDelta()

        mixer.update delta
        
        # stop animations after stopTime
        if clock.elapsedTime > stopTime
            for c in mixerActions
                do (c) -> c.stop()

        return
        
    render = ->
        cameraCtl.currentCam().update()

        $('main').removeChild labelroot  # reduce re-flow times
        scene.traverse (obj) -> obj.update?(cameraCtl.currentCam(), renderer)
        $('main').appendChild labelroot

        # updateAnimations()

        renderer.render(scene, cameraCtl.currentCam())
        return

    # watch chrome history
    watchHistory = (scene) ->
        chrome.history.onVisited.addListener (hi)->
            p = new WebPage(hi.url,hi.title, hi.lastVisitTime)
            p.translateX p.atime/msInHour
            log 'history onVisited',p.id,p.url
            historyGroup.add(p)
            render()

    loadHistory = (scene, camera) ->
        if historyGroup.loaded then return
        # show history
        chrome.history.search {text:'',maxResults:1000},(a)->
            log a.length,'history record(s)'
            for hi in a
                do (hi) ->
                    p = new WebPage(hi.url,hi.title,hi.lastVisitTime)
                    p.translateX p.atime/msInHour
                    historyGroup.add p
            [cmin,cmax] = historyGroup.rangeOf Date.now(),0,(o)->
                o.atime
            cameraCtl.lookAtRange cmin/msInHour,cmax/msInHour
            historyGroup.loaded = true
            scene.add historyGroup
            render()
            return

    loadBookmarks = (scene, camera)->
        if bookmarksGroup.loaded then return
        # show bookmarks
        bmCount = 0
        chrome.bookmarks.getTree (bmlist)->
            addBmNode = (n)->
                bmCount += 1
                p = new WebPage n.url,n.title,n.dateAdded
                p.translateX p.atime/msInHour
                bookmarksGroup.add p
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
            [cmin,cmax] = bookmarksGroup.rangeOf Date.now(),0,(o)->
                o.atime
            cameraCtl.lookAtRange cmin/msInHour,cmax/msInHour
            bookmarksGroup.loaded = true
            scene.add bookmarksGroup
            render()
            return
        return

    # TODO: add toggle to DataGroup, let DataGroup extends EventEmitter
    set3objVis = (o, isVis = true)-> o.traverse (n)->
        n.visible = isVis

    watchToggles = () ->
        $('check-history').addEventListener 'change', (e)->
            loadHistory scene,camera if not historyGroup.loaded
            set3objVis historyGroup,e.target?.checked
            render()
            return
        $('check-bookmarks').addEventListener 'change', (e)->
            loadBookmarks scene,camera if not bookmarksGroup.loaded
            set3objVis bookmarksGroup,e.target?.checked
            render()
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

        # toggle on/off bookmarks
        watchToggles()

        render()
    , (xhr) -> console.log xhr.loaded/xhr.total*100+'% loaded'
    )

