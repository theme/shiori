define ['lib/EventEmitter'], (EventEmitter) ->
    class DataGroup extends THREE.Object3D
        constructor: () ->
            super
            @event = new EventEmitter

        setVisible: (f = true)->
            if @visible == f or undefined == f then return
            @visible = f
            for c in @children
                do (c) -> c.visible = f
            @event.emit 'visible',f

        toggleVisible: ()->
            if @visible then @setVisible false
            else @setVisible true

        rangeOf: (corr) ->
            arr = @children
            if arr.length > 0
                arr.sort (a,b)-> a.position[corr]-b.position[corr]
                cmin = arr[0].position[corr]
                cmax = arr[arr.length-1].position[corr]
                return [cmin,cmax]
            else
                return [0,10]

    return DataGroup

