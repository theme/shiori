define () ->
    class DataGroup extends THREE.Object3D
        constructor: () ->
            super

        rangeOf: (cmin, cmax, getAttr) ->
            arr = @children
            arr.sort (a,b)-> getAttr(a) - getAttr(b)
            if arr.length > 0
                m = getAttr arr[0]
                x = getAttr arr[arr.length-1]
                if m < cmin then cmin = m
                if cmax < x then cmax = x
            else
                tmp = cmin
                cmin = cmax
                cmax = tmp
            return [cmin,cmax]

    return DataGroup
