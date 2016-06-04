require ['log','Axis','Compass','Ruler','Cube','WebPage','Label','InputMixer','DataGroup','CameraController'], (log, Axis, Compass, Ruler, Cube, WebPage, Label, InputMixer, DataGroup, CameraController) ->
    canvas = null
    scene = null

    cameraCtl = null

    renderer = null

    # animation vars
    clock = new THREE.Clock
    stopTime = 5
    mixer = null    # animation player
    mixerActions = []   # animation actions list

    # helper
    V3 = THREE.Vector3
    ccw = -> canvas.clientWidth
    cch = -> canvas.clientHeight
    $ = (id) -> return document.getElementById id

    # labels layer ( in DOM )
    labelroot = $('labelroot')

    # contents
    bookmarksGroup = null
    historyGroup = null
    msInHour = 1000 * 3600
    msInDay = msInHour * 24

    compass = null

    # HUD on canvas
    hud = null
    class HUD
        constructor: () ->
            @logZoom = 0.8
            @camX = 0
            @camY = 0

    initHUD = (render) ->
        hud = new HUD()
        gui = new dat.GUI()
        s = 0.000001
        fCamera = gui.addFolder 'Camera'
        z = fCamera.add(hud, 'logZoom',-25,25).listen()
        z.onFinishChange (v) -> cameraCtl.zoom Math.exp(v)
        camX = fCamera.add(hud, 'camX').step(s).listen()
        camX.onFinishChange (v) ->
            cameraCtl.moveTo cameraCtl.pos().setX(v)
        camY = fCamera.add(hud, 'camY').step(s).listen()
        camY.onFinishChange (v) ->
            cameraCtl.moveTo cameraCtl.pos().setY(v)
        fCamera.open()
        return gui

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
        canvas.width = ccw() # needed for renderer.setViewport
        canvas.height = cch()
        renderer.setViewport 0,0,ccw(),cch()
        render()

    init = ->
        # canvas
        canvas = document.getElementById("3jscanvas")

        # renderer
        renderer = new THREE.WebGLRenderer {canvas:canvas}
        renderer.setClearColor new THREE.Color 0x003366
        log 'renderer.precision:',renderer.getPrecision()

        # Camera
        cameraCtl = new CameraController canvas
        cameraCtl.on 'touched', render

        # Viewport
        handleCanvasResize()
        watchResize canvas, handleCanvasResize

        # HUD widget
        $('HUD').appendChild initHUD(render).domElement
        cameraCtl.on 'zoom', (z)->
            hud.logZoom = Math.log cameraCtl.currentCam().zoom
        cameraCtl.on 'touched', ()->
            hud.camX = cameraCtl.currentCam().position.x
            hud.camY = cameraCtl.currentCam().position.y

        # Contents
        historyGroup = new DataGroup
        historyGroup.loaded = false
        historyGroup.event.on 'loaded',render
        historyGroup.event.on 'visible',render
        historyGroup.event.on 'added', ()->
            render() if historyGroup.visible
        bookmarksGroup = new DataGroup
        bookmarksGroup.loaded = false
        bookmarksGroup.event.on 'loaded',render
        bookmarksGroup.event.on 'visible',render

        return

    updateAnimations = ->
        delta = clock.getDelta()

        mixer.update delta
        
        # stop animations after stopTime
        if clock.elapsedTime > stopTime
            for c in mixerActions
                do (c) -> c.stop()

        return
        
    render = (f = true)->
        if not f then return
        cameraCtl.update()

        $('main').removeChild labelroot  # reduce re-flow times
        scene.traverse (obj) -> obj.update?(cameraCtl.currentCam(), renderer)
        $('main').appendChild labelroot

        # updateAnimations()

        renderer.render(scene, cameraCtl.currentCam())
        return

    # watch chrome history
    addHistoryPoint = (url, title, lastVisitTime) ->
        p = new WebPage(url, title, lastVisitTime)
        p.translateX p.atime/msInHour
        p.translateY (12 - ((p.atime % msInDay)/msInHour))
        log p.position.y, p.title, p.url
        historyGroup.add p
        return p

    watchHistory = (scene) ->
        chrome.history.onVisited.addListener (hi)->
            p = addHistoryPoint(hi.url,hi.title,hi.lastVisitTime)
            log 'history onVisited',p.id,p.url
            historyGroup.event.emit 'added'

    loadHistory = (scene) ->
        chrome.history.search {text:'',maxResults:2000},(a)->
            log a.length,'history record(s)'
            for hi in a
                do (hi) ->
                    addHistoryPoint(hi.url,hi.title,hi.lastVisitTime)
            [cmin,cmax] = historyGroup.rangeOf 'x'
            cameraCtl.lookAtRange cmin,cmax
            scene.add historyGroup
            historyGroup.event.emit 'loaded'
            return
        return

    # bookmarks
    loadBookmarks = (scene)->
        bmCount = 0
        chrome.bookmarks.getTree (bmlist)->
            addBmNode = (n)->
                bmCount += 1
                p = new WebPage n.url,n.title,n.dateAdded
                p.translateX p.atime/msInHour
                p.translateY (12 - ((p.atime % msInDay)/msInHour))
                log p.position.y
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
            [cmin,cmax] = bookmarksGroup.rangeOf 'x'
            cameraCtl.lookAtRange cmin,cmax
            scene.add bookmarksGroup
            bookmarksGroup.loaded = true
            bookmarksGroup.event.emit 'loaded'
            return
        return

    watchToggles = () ->
        $('check-history').addEventListener 'change', (e)->
            if not historyGroup.loaded
                loadHistory scene
            historyGroup.setVisible e.target?.checked
            return
        $('check-bookmarks').addEventListener 'change', (e)->
            if not bookmarksGroup.loaded
                loadBookmarks scene
            bookmarksGroup.setVisible e.target?.checked
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

        init()

        scene.add cameraCtl.currentCam()
        compass = new Compass
        scene.add(compass)

        watchHistory scene

        # toggle on/off bookmarks
        watchToggles()

        render()
    , (xhr) -> console.log xhr.loaded/xhr.total*100+'% loaded'
    )

