require ['log','Axis','Compass','WebPage','Label','InputMixer','DataGroup','CameraController'], (log, Axis, Compass, WebPage, Label, InputMixer, DataGroup, CameraController) ->
    canvas = null
    scene = null

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
        canvas.width = ccw() # is needed for renderer.setViewport
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
        # cameraCtl.newPersCam()
        cameraCtl.setCurrent cameraCtl.newOrthoCam()
        cameraCtl.on 'render', render

        # Viewport
        handleCanvasResize()
        watchResize canvas, handleCanvasResize

        # HUD widget
        $('HUD').appendChild initHUD(render).domElement
        cameraCtl.on 'zoom', (z)->
            hud.logZoom = Math.log cameraCtl.currentCam().zoom
        cameraCtl.on 'render', ()->
            hud.camX = cameraCtl.currentCam().position.x
            hud.camY = cameraCtl.currentCam().position.y

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
        cameraCtl.update()

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

    loadHistory = (scene) ->
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

    loadBookmarks = (scene)->
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
            loadHistory scene if not historyGroup.loaded
            set3objVis historyGroup,e.target?.checked
            render()
            return
        $('check-bookmarks').addEventListener 'change', (e)->
            loadBookmarks scene if not bookmarksGroup.loaded
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

