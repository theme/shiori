define () ->
    # singleton container
    allLabels = []
    labelRootEl = document.getElementById('labelroot')
    if not labelRootEl
        labelRootEl = document.createElement 'div'
        labelRootEl.id = 'labelroot'
        document.body.appendChild labelRootEl

    class Label extends THREE.Object3D
        constructor: (txt)->
            super
            @text = txt
            @div = document.createElement 'div'
            labelRootEl.appendChild @div
            @div.innerHTML = @text
            @div.classList.add 'label'
            @div.classList.add 'notvisible'
            allLabels.push @
            return

        setVisible: (y)->
            if y then @div.classList.remove 'notvisible'
            else @div.classList.add 'notvisible'
            return

        updatePos: (camera, renderer)->
            if not @parent?
                @setVisible false
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
            # every change of label div style triggers layout of web page, this is slow.
            # to solve: try detach all div and update its style, after that, re-attach all label.
            # this can be down using a absolute div (0,0) as parent.
            @div.style.left = @sX
            @div.style.top = @sY
            return

        isOnScreen: (camera, renderer)->
            rect = renderer.domElement.getBoundingClientRect()
            return (rect.left < @sX < rect.right) and (rect.top < @sY <rect.bottom)

        update: (camera, renderer)->
            @updatePos camera, renderer
            if not @visible then @setVisible false
            else @setVisible @isOnScreen camera, renderer
            return

    return Label
