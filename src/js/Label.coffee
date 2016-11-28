define ['log', 'Cube'],(log, Cube) ->
    # singleton container
    allLabels = []
    labelRootEl = document.getElementById('labelroot')
    dummyGeometry = new THREE.Geometry

    class Label extends THREE.Points # in order to use onBeforeRender
        constructor: (txt)->
            @geometry = dummyGeometry
            super @geometry
            @text = txt
            @makeDOMdiv()
            @onAfterRender = (renderer, scene, camera, geometry, material, group)=>
                log "Label::onAfterRender"
                if not @div? then @makeDOMdiv()
                @updateDivPos camera, renderer
                if not @visible then @setDivVisible false

        makeDOMdiv: ->
            if @div?
                return
            log "Label::makeDOMdiv"
            @div = document.createElement 'div'
            labelRootEl.appendChild @div
            @div.innerHTML = @text
            @div.classList.add 'label'
            # @div.classList.add 'notvisible'
            allLabels.push @
            return

        setDivVisible: (y)->
            if y
                @div.classList.remove 'notvisible'
            else
                @div.classList.add 'notvisible'
            return

        # TODO: update & remove Label
        updateDivPos: (camera, renderer)-> #TODO this means bad design
            log "Label::updateDivPos"
            if @parent == undefined
                @setDivVisible false
                return
            pos = @parent.position.clone()
            rect = renderer.domElement.getBoundingClientRect()
            # calculate on screen X,Y
            rect.width = rect.right - rect.left
            rect.height = rect.top - rect.bottom
            mvp = new THREE.Matrix4 # proj * view * model matrix
            mvp.multiplyMatrices camera.projectionMatrix, camera.matrixWorldInverse
            pos.applyProjection mvp

            @sX= ( pos.x + 1 ) * rect.width / 2 + rect.left
            @sY= ( - pos.y + 1) * rect.height / 2 + rect.top
            @div.style.left = @sX
            @div.style.top = @sY
            return

        isOnScreen: (camera, renderer)->
            log "Label::isOnScreen"
            rect = renderer.domElement.getBoundingClientRect()
            return (rect.left < @sX < rect.right) and (rect.top < @sY <rect.bottom)

        update: (camera, renderer)->
            log "Label::update"
            # if not @visible then @setDivVisible false
            # else @setDivVisible @isOnScreen camera, renderer
            return


    return Label

