require ['log','lib/moment','Axis','Compass','Ruler','Cube','WebPage','InputMixer','DataGroup','CameraController','Model','Labeling'], (log, Moment, Axis, Compass, Ruler, Cube, WebPage, InputMixer, DataGroup, CameraController, Model, Labeling) ->
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
            @History = false
            @Bookmarks = false
            @BookmarksSearch = ''

    initHUD = (render) ->
        hud = new HUD()
        gui = new dat.GUI()
        s = 0.000001
        # Data (model)
        fData  = gui.addFolder 'Data'

        bookmarksSearch = fData.add(hud, 'BookmarksSearch').listen()
        bookmarksSearch  .onFinishChange (t) ->
            console.log t

        bookmarksToggle = fData.add(hud, 'Bookmarks').listen()
        bookmarksToggle .onFinishChange (t) ->
            if not Model.bookmarksGroup.loaded
                loadBookmarks scene
            Model.bookmarksGroup.setVisible t

        historyToggle = fData.add(hud, 'History').listen()
        historyToggle.onFinishChange (t) ->
            if not Model.historyGroup.loaded
                loadHistory scene
            Model.historyGroup.setVisible t

        fData.open()

        # Camera
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
        Model.historyGroup = new DataGroup
        Model.historyGroup.loaded = false
        Model.historyGroup.event.on 'loaded',render
        Model.historyGroup.event.on 'visible',render
        Model.historyGroup.event.on 'added', ()->
            render() if Model.historyGroup.visible
        Model.bookmarksGroup = new DataGroup
        Model.bookmarksGroup.loaded = false
        Model.bookmarksGroup.event.on 'loaded',render
        Model.bookmarksGroup.event.on 'visible',render

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

        $('labelcontainer').removeChild labelroot  # to reduce re-flow
        # scene.traverse (obj) -> obj.update?(cameraCtl.currentCam(), renderer)

        # updateAnimations()

        # before render
        Model.renderedLabels = []
        
        # do render
        renderer.render(scene, cameraCtl.currentCam())

        # after render
        # do labeling
        Labeling.canvasCenterLabels(
            Model.renderedLabels, Model.allLabels, renderer, cameraCtl.currentCam())

        # clear flags
        $('labelcontainer').appendChild labelroot

        return

    # watch chrome history
    addHistoryPoint = (url, title, lastVisitTime) ->
        p = new WebPage(url, title, lastVisitTime)
        p.translateX p.atime/msInHour
        p.translateY (12 - ((p.atime % msInDay)/msInHour))
        # log p.position.y, p.title, p.url
        Model.historyGroup.add p
        return p

    watchHistory = (scene) ->
        chrome.history.onVisited.addListener (hi)->
            p = addHistoryPoint(hi.url,hi.title,hi.lastVisitTime)
            log 'history onVisited',p.id,p.url
            Model.historyGroup.event.emit 'added'

    loadHistory = (scene) ->
        chrome.history.search {text:'',maxResults:2000},(a)->
            log a.length,'history record(s)'
            for hi in a
                do (hi) ->
                    addHistoryPoint(hi.url,hi.title,hi.lastVisitTime)
            [cmin,cmax] = Model.historyGroup.rangeOf 'x'
            cameraCtl.lookAtRange cmin,cmax
            scene.add Model.historyGroup
            Model.historyGroup.loaded = true
            Model.historyGroup.event.emit 'loaded'
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
                # log p.position.y
                Model.bookmarksGroup.add p
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
            [cmin,cmax] = Model.bookmarksGroup.rangeOf 'x'
            cameraCtl.lookAtRange cmin,cmax
            scene.add Model.bookmarksGroup
            Model.bookmarksGroup.loaded = true
            Model.bookmarksGroup.event.emit 'loaded'
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

        init()

        scene.add cameraCtl.currentCam()
        compass = new Compass
        scene.add(compass)

        watchHistory scene

        render()
    , (xhr) -> console.log xhr.loaded/xhr.total*100+'% loaded'
    )

