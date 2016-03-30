// navigation input events
// on a DOM element (that has: wheel, mousedown, mousemove)
//
// # DONE: Normalise input amount to [-1,1]
// # but there are some other questions:
// # 1.touch move is normalised using the same factor with mouse drag
// # 2.browser emulate mousemove from touch move, but they have different input scale
//
// To address these:
// 1. distinguish mouse and touch , use different normaliser for them, or
// 2 noticing : drag adapt is not good when we want to drag fast some times, and after that we still can drag slow / fast.
//
// ... what we want really is:
// 1. normalise zoom event value amount into [-1,1]. Distinguish mouse and touchpad input is needed, because they have different scale.
// 2. do nothing to drag event amount, because it's in pixel, mouse and touchpad input are already in same scale.

function genFunNormaliser (){
    return function () {
        var max = 0;
        return function (v){
            abs = Math.abs(v);
            if (abs > max) { max = abs; }
            console.log(max);
            return 1.0 * v / max;
        }
    }();
}

define(function(){
    var zoomRatio = 1;
    var rotateRatio = 1;
    var panRatio = 1;
    var cursor = {};
    var normWheelY = genFunNormaliser();

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
            dispatch(el, 'zoom', normWheelY(e.deltaY) * zoomRatio);
        });

        // drag rotate
        function onDrag(e){
            cursor.deltaClientX = e.clientX - cursor.prevClientX;
            cursor.deltaClientY = e.clientY - cursor.prevClientY;
            cursor.prevClientX = e.clientX;
            cursor.prevClientY = e.clientY;
            if(spaceKey)
                dispatch(el,'rotate', cursor.deltaClientX * rotateRatio);
            else
                dispatch(el,'pan', {
                    deltaX: cursor.deltaClientX * panRatio,
                    deltaY: cursor.deltaClientY * panRatio,
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

