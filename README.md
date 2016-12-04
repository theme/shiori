shiori
======

bookmark arranger

TODO
====

- [x] lock vertical panning.
- [ ] Use all visible Y span. (as hour / day / week / year)
- [x] fix grid.
- [ ] prevent label overflow caused scroll bar.
- [x] move history and bookmarks toggle to Dat.gui.
- [ ] fix history and bookmarks toggle on / off .
- [x] add label on / off .

## Design - Use all visible Y span.

At first I though that

* Event on time line is set, static.
* We view event through camera with different zoom level, from different angle.

But when I want to fully utilize the Y axis space on screen to distribute labels of event point, the problem appears:

* A. I am able to adjust Camera.frustum.left/right to change X range, but all the object will be squeezed.
* B. May be I will want to scale seperately x and y axis, e.g. Y screen range as : hour / day / week / month / year ...

A is a quite naive scaling on the x axis, infact, it will make more sense if no y axis is considered, it's only a time line scale.
As long as you consider span event points onto y direction, the most zoom level is a day, because then the y range will convey some "sun rise and set" information, together with bookmarks, this give more intuitive understand of "what I read in that day / week / month".

`It's interesting that all the day / week / month notion still plays such role in this little application design.`

Design Choice :> use Y range as hour / day / week / month / year

## Implement - use Y range as hour / day / week / month / year

Because Y axis unit change, object in the scene will relocate on unit change.

* When X range is more than 1 min, change Y range to 60 second
* When X range is more than 1 hour, change Y range to 60 min
* When X range is more than 1 day, change Y range to 24 hour (unit 1 hour)
* When X range is more than 1 week, change Y range to 7 day,
* When X range is more than 1 month, change Y range to 1 week,
* When X range is more than 1 year, change Y range to 24 month,
* When X range is more than 1 decade, change Y range to 20 year,
* When X range is more than 1 century, change Y range to 100 year,
* When X range is more than 10 century, change Y range to 1000 year,
* When X range is more than 50 century, change Y range to 1000 year.

X range is set on camera.  camera.left = 0.5 * client area width. ( camera.zoom is calculated with lookAt( min, max) )

On zoom, check X range

    xrage = (camera.right - camera.left) / camera.zoom

current data point is put into scene with code in `bookmark.coffee`: ( change needed )

    24     # contents
    25     msInHour = 1000 * 3600
    26     msInDay = msInHour * 24

    177         p.translateX p.atime/msInHour
    178         p.translateY (12 - ((p.atime % msInDay)/msInHour))

where p.atime is milliseconds since epoch(Jan 1, 1970) [][https://developer.chrome.com/extensions/bookmarks#type-BookmarkTreeNode]

pseudo code will be like

    if ( xrange < MIN ) {

    } else if ( xrange < HOUR ) {

    } else if ...

where MIN, HOUR is minute, hour in milliseconds.


With the help of [moment.js :: duaration][http://momentjs.com/docs/#/durations/] we can add defined `duration` and use it like

    years   y
    months  M
    weeks   w
    days    d
    hours   h
    minutes     m
    seconds     s
    milliseconds    ms

    moment.duration(1.5, 'seconds').asMilliseconds(); // 1500

    MIN = moment.duration(1, 'minutes').asMilliseconds(); // define

### precision problem

    >>> a = 50 * 100 * 365 * 24 * 3600 * 1000
    >>> 1366.0 / a
    8.663115169964485e-12

means a 1366 x 768 laptop computer's screen width will cause three.js to render with pricison of e-12 level when we view a xrange of 50 centuries.

three.js [WebGLRenderer][https://threejs.org/docs/?q=render#Reference/Renderers/WebGLRenderer] has a precision property

    precision — Shader precision. Can be "highp", "mediump" or "lowp". Defaults to "highp" if supported by the device.

if I let DataPoint.x = atime ( in milliseconds ), and zoom ... seems no problem.  (just some minor fix to control widget range.)

### change DataPoints position before every render.

We can adjust DataPoint's position before each render, before rendering.

Calculating position needs:

* WebPage.atime ( will be used as `DataPoint.date` )
* camera ( zoom, position, left, right ), calculates current visible xrange, further determines current `y-scale` of { minute, hour, day, week, month, year ...}
* renderer ( browser client area: width, height ), with camera zoom, calculates `DataPoint.position.y`

Naming the algorithm method `DataGroup.layoutY( points, camera, renderer )` 

Utilize `moment().startOf('year');` 

## Labeling 

I used `Labeling` to mean the Labeling algorithm.  Because there is no `LabelLayer` object, this confused myself: where should I put all labels visibility status ? into `Model` or `Labeling`.  Thinking `Labeling` as an algorithm "object" is not right, algorithm should be thought as a process, a method of some object (as in OOP).

So add `LabelLayer` class.  ( Inherit `EventEmitter`. )


## Grid

Grid is useful.

DONE bug: `GridGroup` is used to move Grid to unit time moment, but it seems points to every _half_ unit ?  ( This is ... very frustrating... OTL )
FIX bug: ^ This is caused by the `GridHelper( size, division )` implementation, where `size` is double range.

