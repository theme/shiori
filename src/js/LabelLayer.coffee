define ['lib/EventEmitter', 'log'], (EventEmitter, log) ->

    MAX_LABEL_NUM = 100 # max labels visible on screen

    ds = (x1,y1,x2,y2) ->
        ( x1 - x2 ) * ( x1 - x2 ) + ( y1 - y2 ) * ( y1 - y2 )

    class LabelLayer extends EventEmitter
        constructor: ->
            @super
            @visible = false

        turnOn: ->
            @visible = true
            @emit 'visible', true

        turnOff: ->
            @visible = false
            @emit 'visible', false

        canvasCenterLabels: (labels, allLabels, renderer, camera)->
            for l in allLabels
                l.setDivVisible false

            # get current canvas center
            ccc = camera.position

            # sort labels (distance to canvas center)
            labels.sort (la, lb) ->
                pa = new THREE.Vector3
                pa.setFromMatrixPosition( la.matrixWorld )
                pb = new THREE.Vector3
                pb.setFromMatrixPosition( lb.matrixWorld )
                ds(pa.x, pa.y, ccc.x, ccc.y) - ds(pb.x, pb.y, ccc.x, ccc.y)

            # prepare for label position calculation
            mvp = new THREE.Matrix4 # proj * view * model matrix
            mvp.multiplyMatrices camera.projectionMatrix, camera.matrixWorldInverse
            rect = renderer.domElement.getBoundingClientRect()

            # draw center labels
            for i in [0 ... labels.length]
                if i >= MAX_LABEL_NUM then break

                l = labels[i]

                lpos = l.parent.position.clone()
                lpos.applyProjection mvp
                l.sX= ( lpos.x + 1 ) * rect.width / 2 + rect.left
                l.sY= ( - lpos.y + 1) * rect.height / 2 + rect.top

                l.div.style.left = l.sX
                l.div.style.top = l.sY

                l.setDivVisible @visible

    return LabelLayer
