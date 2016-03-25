define ['Line'], (Line) ->
    class WebPage extends THREE.Object3D
        constructor: (url, atime = Date.now())->
            super
            @url = url
            @atime = atime
            
            # cross mark
            @.add new Line -0.1,0,0,0.1,0,0,'yellow'
            @.add new Line 0,-0.1,0,0,0.1,0,'yellow'

            # Blender JSON Model
            # loader = new THREE.JSONLoader
            # loader.load "/models/WebPageMark.json", (geo,mats) =>
            #     @.add new THREE.Mesh(geo,mats[0])

    return WebPage
