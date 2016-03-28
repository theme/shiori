define ['Line','Label'], (Line, Label) ->
    class WebPage extends THREE.Object3D
        constructor: (url, title, atime = Date.now())->
            super
            @url = url
            @atime = atime
            
            # cross mark
            @.add new Line -0.1,0,0,0.1,0,0,'yellow'
            @.add new Line 0,-0.1,0,0,0.1,0,'yellow'
            if title?
                @.add new Label title
            else
            matches = url.match(/^https?\:\/\/(?:www\.)?([^\/?#]+)(?:[\/?#]|$)/i)
            @.add new Label(if matches? then matches[1] else title)

            # Blender JSON Model
            # loader = new THREE.JSONLoader
            # loader.load "/models/WebPageMark.json", (geo,mats) =>
            #     @.add new THREE.Mesh(geo,mats[0])

    return WebPage
