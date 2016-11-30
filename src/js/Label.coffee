define ['log', 'Model'],(log, Model) ->

    labelRootEl = document.getElementById('labelroot')

    class Label extends THREE.Object3D
        constructor: (txt)->
            super
            @text = txt
            Model.allLabels.push @

            @div = document.createElement 'div'

            @div.innerHTML = @text
            @div.classList.add 'label'
            @div.classList.add 'notvisible'

            labelRootEl.appendChild @div
            return

        setDivVisible: (y)->
            if y
                @div.classList.remove 'notvisible'
            else
                @div.classList.add 'notvisible'
            return

    return Label

