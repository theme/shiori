require ['log','lib/moment','lib/EventEmitter','WebPage','DataGroup','CameraController','Model','LabelLayer'], (log, Moment, EventEmitter, WebPage, DataGroup, CameraController, Model, LabelLayer) ->

    # helper functions
    V3 = THREE.Vector3
    $ = (id) -> return document.getElementById id

    # App components
    scene = null
    compass = null # object in the scene
    canvas = null
    cameraCtl = null
    renderer = null

    labelLayer = null

    # labels layer ( in DOM )
    labelroot = $('labelroot')

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
            @LabelVisible = false

    initHUD = (render) ->
        hud = new HUD()
        gui = new dat.GUI()
        s = 0.000001
        # Data (model)
        fData  = gui.addFolder 'Data'

        bookmarksSearch = fData.add(hud, 'BookmarksSearch').listen()
        bookmarksSearch.onFinishChange (t) ->
            console.log t

        bookmarksToggle = fData.add(hud, 'Bookmarks').listen()
        bookmarksToggle.onFinishChange (t) ->
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
        CENTURY_MS = Moment.duration(5000, 'years').asMilliseconds()
        SCREEN_PIXEL = 4000
        fCamera = gui.addFolder 'Camera'
        z = fCamera.add(hud, 'logZoom', -Math.log(CENTURY_MS), Math.log(SCREEN_PIXEL)).listen()
        z.onFinishChange (v) -> cameraCtl.zoom Math.exp(v)
        camX = fCamera.add(hud, 'camX').step(s).listen()
        camX.onFinishChange (v) ->
            cameraCtl.moveTo cameraCtl.pos().setX(v)
        camY = fCamera.add(hud, 'camY').step(s).listen()
        camY.onFinishChange (v) ->
            cameraCtl.moveTo cameraCtl.pos().setY(v)
        fCamera.open()

        # Labels
        fLabel = gui.addFolder 'Label'
        labelingToggle = fLabel.add(hud, 'LabelVisible').listen()
        labelingToggle.onFinishChange (t) ->
            labelLayer.labelingToggle = t
        fLabel.open()

        return gui

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
        # Model.historyGroup.event.on 'visible',render
        Model.historyGroup.event.on 'added', ()->
            render() if Model.historyGroup.visible
        Model.bookmarksGroup = new DataGroup
        Model.bookmarksGroup.loaded = false
        Model.bookmarksGroup.event.on 'loaded',render
        # Model.bookmarksGroup.event.on 'visible',render

        # Labeling
        labelLayer = new LabelLayer
        labelLayer.on 'visible', (t) -> render

        return

    render = (f = true)->
        if not f then return

        # before render
        
        cameraCtl.update() # set camera
        cam = cameraCtl.currentCam()

        cw = canvas.clientWidth # set renderer
        ch = canvas.clientHeight
        renderer.setSize cw, ch, true

        $('labelcontainer').removeChild labelroot  # to reduce re-flow
        # scene.traverse (obj) -> obj.update?(cameraCtl.currentCam(), renderer)
        Model.historyGroup.layoutY( cam, renderer) # datapoints, set position
        Model.bookmarksGroup.layoutY( cam, renderer)

        Model.renderedLabels = []
        
        # do render
        renderer.render(scene, cam)

        # after render
        labelLayer.canvasCenterLabels(
            Model.renderedLabels, Model.allLabels, renderer, cam
        )

        $('labelcontainer').appendChild labelroot # to reduce re-flow

        return

    # watch chrome history
    addHistoryPoint = (url, title, lastVisitTime) ->
        p = new WebPage(url, title, lastVisitTime)
        p.translateX p.atime
        Model.historyGroup.addPoint p
        return p

    watchHistory = (scene) ->
        chrome.history.onVisited.addListener (hi)->
            p = addHistoryPoint(hi.url,hi.title,hi.lastVisitTime)
            log 'history onVisited',p.id,p.url

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
                p.translateX p.atime
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

        init()

        watchHistory scene

        render()
    , (xhr) -> console.log xhr.loaded/xhr.total*100+'% loaded'
    )

