// navigation input events
// on a DOM element (that has: wheel, mousedown, mousemove)
//
// # TODO: Normalise input amount to [-1,1]
// # to reduce zoom amount, I have to make wheel and touchpad scale nearly same amount
// #
// # wheel input is very large, check it from log:
// # +,- 636~ 5888 for every tick
// #
// # while touchpad relativly small:
// # +,- 1 ~ 332 (depends on speed)
// #
// # ?? can I get device resolution ?
// # WEb API seems not giving the device's one tick amount.
// 
// # then we have to adapt according to the input.
// # HOPE: scroll gives in equal max of moving.
// # Normalise mouse wheel and touch pad into [-1,1]
// # then the actual effective max zoom speed (a setting) can be set in other part of the application ( as long as input is always in 0 ~ 1)
//
// # The normalisation can be done in the InputMixer module.
//
// # Algorithm: each input has a related variable recording the max amount ever seen.
// # then every input is divided by this max value, getting an output in range [0, 1]
// #
// #   Does this has to be a class?
// #       in: data is 'type', event, deltaClintX, Y, Z
// #       out: normalised value.
// #       its a algorithm, but every input need a max var to be memorized.
// #   the simple solution is put the max var in the call back function.  This is very natural in JS.
//
// #   And we can use a function factory to describe this algorithm.
//      these functions are the same, factory does not need arguments
// #

function genFunNormaliser (){
    return function () {
        var max = 0;
        return function (v){
            abs = Math.abs(v);
            if (abs > max) { max = abs; }
            return v / max;
        }
    }();
}

define(function(){
    var zoomRatio = 1;
    var rotateRatio = 1;
    var panRatio = 1;
    var cursor = {};


    function decorate(el){
        // helper: dispatch custom event
        function dispatch(el, na, val){
            el.dispatchEvent(new CustomEvent(na, {'detail': val}));
        }

        var spaceKey = false;
        document.addEventListener('keydown', function(e){
            switch (e.code){
                case "Space":
                    spaceKey = true;
                    break;
            }
            if (e.altKey) {
                switch (e.code){
                    case "KeyO":
                        dispatch(el, 'cam', 'oCam');
                        break;
                    case "KeyI":
                        dispatch(el, 'cam', 'pCam');
                        break;
                    case "KeyC":
                        dispatch(el, 'cam', 'nextCam');
                        break;
                }
            }
        });

        document.addEventListener('keyup', function(e){
            if(e.keyCode == 32) {
                spaceKey = false;
                dispatch(el, 'panstop');
            }
        });

        // wheel zoom
        el.addEventListener('wheel', function(e){
            norm = genFunNormaliser();
            dispatch(el, 'zoom', norm(e.deltaY) * zoomRatio);
        });

        // drag rotate
        function onDrag(e){
            cursor.deltaClientX = e.clientX - cursor.prevClientX;
            cursor.deltaClientY = e.clientY - cursor.prevClientY;
            cursor.prevClientX = e.clientX;
            cursor.prevClientY = e.clientY;
            normX = genFunNormaliser();
            normY = genFunNormaliser();
            if(spaceKey)
                dispatch(el,'rotate', normX(cursor.deltaClientX) * rotateRatio);
            else
                dispatch(el,'pan', {
                    deltaX: normX(cursor.deltaClientX) * panRatio,
                    deltaY: normY(cursor.deltaClientY) * panRatio,
                });
        }

        function onMouseDown(e){
            cursor.prevClientX = e.clientX;
            cursor.prevClientY = e.clientY;

            // when mouse down, register drag event
            var onMouseMove = function(e){
                onDrag(e);
            };
            el.addEventListener("mousemove", onMouseMove);

            // when mouse up / out, un-register drag event
            var onMouseOut = function(e){
                cursor.deltaClientX = 0;
                cursor.deltaClientY = 0;
                el.removeEventListener("mousemove", onMouseMove);
                el.removeEventListener("mouseout", onMouseOut);
                el.removeEventListener("mouseup", onMouseOut);
            };
            el.addEventListener("mouseup", onMouseOut );
            el.addEventListener("mouseout", onMouseOut);
        }
        el.addEventListener("mousedown", onMouseDown);
    }
    return {decorate: decorate};
});

