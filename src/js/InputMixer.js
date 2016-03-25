// navigation input events
// on a DOM element (that has: wheel, mousedown, mousemove)
define(function(){
    var zoomRatio = 0.01;
    var rotateRatio = 0.1;
    var panRatio = 0.1;
    var cursor = {};

    function decorate(el){
        // helper
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
            dispatch(el, 'zoom', e.deltaY * zoomRatio);
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

