requirejs.config {
    baseUrl: '/js'
}
require ['log','Compass','WebPage','Label','InputMixer','DataGroup'], (log, Compass, WebPage, Label, InputMixer, DataGroup) ->
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
    $ = (id) -> return document.getElementById id

    # labels layer ( in DOM )
    labelroot = $('labelroot')

    # contents
    bookmarksGroup = new DataGroup
    bookmarksGroup.loaded = false
    historyGroup = new DataGroup
    historyGroup.loaded = false

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

    # constant
    msInYear = 1000 * 3600 * 24 * 365

    # camera
    initCamera = ->
        r = 25/cch()
        # Perspective
        pCam = new THREE.PerspectiveCamera 75, ccw()/cch(),1,100
        pCam.r = r
        pCam.update = ->
            @aspect = ccw()/cch()
            @updateProjectionMatrix()
        pCam.tgt = new THREE.Vector3
        pCam.zoomTo = (min,max)-> return
        pCam.position.set 0,0,20

        # Orthographic
        oCam = new THREE.OrthographicCamera(
            -r*ccw(), r*ccw(), r*cch(), -r*cch(), cch()/-2, cch()/2
        )
        oCam.r = r
        oCam.update = ->
            @left   = - ccw()*oCam.r
            @right  = + ccw()*oCam.r
            @top    = + cch()*oCam.r
            @bottom = - cch()*oCam.r
            @updateProjectionMatrix()
        oCam.tgt = new THREE.Vector3
        oCam.zoomTo = (min,max)->
            @zoom = (@right-@left)/(max-min) # calc zoom
            @updateProjectionMatrix() # update matrix
            @position.set ((min + max)/2),0,20
            log min,max,'zoom:',@zoom,'oCam.position.x',@position.x

        oCam.position.set 0,0,20

        return camera = oCam

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

    resetCameraView = ->
        canvas.width = ccw()
        canvas.height = cch()
        renderer.setViewport 0,0,ccw(),cch()
        render()
        # camera.update()

    init = ->
        # canvas
        canvas = document.getElementById("3jscanvas")

        # renderer
        renderer = new THREE.WebGLRenderer {canvas:canvas}
        renderer.setClearColor new THREE.Color 0x003366
        log 'renderer.precision:',renderer.getPrecision()


        # camera
        initCamera()

        # reset view
        resetCameraView()

        # gui
        $('HUD').appendChild initHUD(camera, render).domElement

        # Watch vanvas resize
        watchResize canvas, resetCameraView

        # navigation input & camera control
        InputMixer.decorate canvas # cavas now has 'zoom','rotate' ev
        camera.lookAt camera.tgt

        # helper : camera screen pixel to coordinate scale
        p2c = (pix) -> pix * camera.r * 2 / camera.zoom

        # zoom
        canvas.addEventListener 'zoom', (e) ->
            speed = 0.01
            z = (1-e.detail*speed) * camera.zoom
            camera.zoom = z if z > 0
            camera.updateProjectionMatrix()
            hud.logZoom = Math.log camera.zoom
            render()
            return

        # rotate
        canvas.addEventListener 'rotate', (e) ->
            v = camera.position.clone().sub camera.tgt
            v.applyAxisAngle(
                new THREE.Vector3(0,1,0),
                - Math.atan(p2c(e.detail)/v.length())
            )
            camera.position.copy v.add camera.tgt
            camera.lookAt camera.tgt
            render()
            return

        # pan
        canvas.addEventListener 'pan', (e) ->
            camUp = new THREE.Vector3 0,1,0
            camRight = new THREE.Vector3 1,0,0
            q = new THREE.Quaternion
            q.setFromRotationMatrix camera.matrixWorld
            camUp.applyQuaternion q
            camRight.applyQuaternion q

            v = camera.tgt.clone().sub camera.position
            camera.position.add camRight.multiplyScalar(- p2c e.detail.deltaX)
            camera.position.add camUp.multiplyScalar(p2c e.detail.deltaY)
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
        # do rendering before update, if animating
        # renderer.render(scene, camera)
        
        camera.update()

        # detach labels
        $('main').removeChild labelroot
        scene.traverse (obj) -> obj.update?(camera, renderer)
        # re attach labels
        $('main').appendChild labelroot

        mixer.update delta # animation

        # stop play after stopTime
        if clock.elapsedTime > stopTime
            for c in mixerActions
                do (c) -> c.stop()

        # do rendering after update, if not animating
        renderer.render(scene, camera)
        return

    # watch chrome history
    watchHistory = (scene) ->
        chrome.history.onVisited.addListener (hi)->
            p = new WebPage(hi.url,hi.title, hi.lastVisitTime)
            p.translateX p.atime/msInYear
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
                    p = new WebPage(hi.url,hi.title, hi.lastVisitTime)
                    p.translateX p.atime/msInYear
                    historyGroup.add p
            [cmin,cmax] = historyGroup.rangeOf Date.now(),0,(o)->
                o.atime
            camera.zoomTo cmin/msInYear,cmax/msInYear
            hud.logZoom = Math.log camera.zoom
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
                p.translateX p.atime/msInYear
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
            camera.zoomTo cmin/msInYear,cmax/msInYear
            hud.logZoom = Math.log camera.zoom
            bookmarksGroup.loaded = true
            scene.add bookmarksGroup
            render()
            return
        return

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
        # loadHistory scene,camera
        # loadBookmarks scene,camera

        # toggle on/off bookmarks
        watchToggles()

        render()
        # animate()
    , (xhr) -> console.log xhr.loaded/xhr.total*100+'% loaded'
    )

