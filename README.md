shiori
======

bookmark arranger

TODO
====

- [x] lock vertical panning. 
- [ ] Use all visible Y span. (as hour / day / week / year)
- [ ] fix grid.
- [ ] prevent label overflow caused scroll bar.
- [x] move history and bookmarks toggle to Dat.gui.

Design
======

## Use all visible Y span.

At first I though that
    * Event on time line is set, static.
    * We view event through camera with different zoom level, from different angle.

But when I want to fully utilize the Y axis space on screen to distribute labels of event point, the problem appears:
    * A. I am able to adjust Camera.frustum.left/right to change X range, but all the object will be squeezed.
    * B. May be I will want to scale seperately x and y axis, e.g. Y screen range as : hour / day / week / month / year ...

A is a quite naive scaling on the x axis, infact, it will make more sense if no y axis is considered, it's only a time line scale.
As long as you consider span event points onto y direction, the most zoom level is a day, because then the y range will convey some "sun rise and set" information, together with bookmarks, this give more intuitive understand of "what I read in that day / week / month".

`It's interesting that all the day / week / month notion still plays such role in this little application design.`

Design Choice :> use Y range as hour / day / week / year


