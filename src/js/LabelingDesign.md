
2016-11-23: 打算继续写 shiori ，它可以成为个人浏览抓取关键字，并按时间绘制时间轴的软件。—— 这样可以辅助个人学习，比如读维基百科，看新闻的时候，能调出自己书签里相关的时间轴。

但是以上交互比较麻烦。先把当前的 labeling 分支处理一下，保存起来比较好。

DROP: 弄好之后另开分支，处理场景更新时，需要传入 Camera 的引用给 update Objects. 这看上去像是依赖倒置了，可能存在设计上的问题。

1. Label.coffe 中，使用传入的 Camera，和 renderer 来计算 label 在屏幕上的位置。自己以前也记录了“可能是坏的设计。
2. CameraControl 里面，根据 Camera 正投影/与否，更新 Camera 的宽高和投影矩阵。

这里的问题也许可以细分一下 UI 回环的层，分辨一下哪些部分提供哪些变量。来思考设计的改进。（吃东西去）



现在的对象层次是这样的：

    B:window
        |--- CameraControl
        |       |---- currentCam()
        |--- canvas
        |--- scene
        |--- renderer
        |--- bookmarkGroup // .event.loaded / visible
        |--- historyGroup // .event.loaded / visible / added

THREE.js 提供的，是(场景，场景外的 相机)=> 渲染到画面。

我需要更新的，是
* （读）用户输入，更新相机位置、缩放，旋转，平移，（用户输入是注册在 canvas 上的事件，使用了 Event 库）
* （窗口变化）更新相机缩放。（这里
* （数据更新）书签更新，更新场景，触发重绘（注册在　bookmark/historyGroup 上的事件）

—— 这里目前是，有变化，抛事件，做重绘。因为用户移动到某个地方之后，一次绘制后一般用户是在读，而不是像游戏不断在动（可以每帧对脏对象重绘）。数据多的时候，稍微有点卡都是可以的，还可以丢掉平移的中间部分，等平移完成以后，延时没有输入，才做一次重绘，包括重新计算标签的位置。

如果以后希望拖动数据点来放置到新位置（这越来越像 CAD 的UI 了。），可以从 div 的托放来获取数据，并在放下后，输入信息完成，点确定才重绘。（也是为了省力）

(…… 其实这事除了放在 浏览器里，也可以放在 linux 的 Compose 式的窗口管理器上。这是未来的事了，不知道会不会好做。)

目前，每次利用 render 里的 update 挂钩会重新计算所有标签位置，这里，缺标签位置计算的算法。另外，步骤还可以细分。有时候，大多数标签可以不动，只重算有变化的那个标签。

正确的做法，似乎是先实现功能：引起变化的事件——更新场景——更新相机——更新标签——重绘场景(three.js)——重绘标签(移除，修改，重插入）。（这是因为 标签不在场景里，是dom 里， canvas 上的独立一层。）

其中，计算标签在窗口平面上的位置，需要场景中物体位置，相机位置和缩放，canvas 位置和大小，这些所有的数据。而标签目前的实现是场景中的对象扩展 extend THREE.object3d。—— 实际上如果不是考虑未来可能在 3D 空间里放标签，标签总是面对镜头的话，它并不需要物体的 3d 位置，它需要物体的屏幕位置（由 three.js 在 render 时投影矩阵计算过一次，不知道是否开放给开发者获取？）DONE：待查。否则需要自己计算。发现 THREE.WebGLrenderer 上面有 ViewPort 属性，应用里用controller 更新它。

THREE.js 用 renderer.render ( scene, camera ) 来渲染。scene 和 camera 对 renderer 是无知的，包括 renderer 上面的 Viewport 信息。

所以，考虑标签，应该在 renderer.render 后，根据 renderer, scene, camera 三者来重新计算（更新事件后，三者都稳定下来时）。因为是独立一层，所以还应当考虑自己所在 窗口，超出边界会导致出现拖动条。

所以，设计上大致应该让 scene 暴露出 label 需要的信息。
让 camera 暴露出比例尺等信息。
最后让 LabelingRenderer 来遍历这些信息，计算出 Label 并且绘制到窗口中去。（注意不能导致窗口改变大小）。Label.js （ 根据 x,y 在 windows中绘制，不碰到窗口大小，实现独立的 标签算法，这个在地理信息相关有实现论文可参考。）

这样看来，是否把标签的文字内容，放到 THREE.js 的场景对象上去，是一个可以考虑的问题。放上去在当前显得比较简单，但是以后可能需要更换 3D 渲染器的话，就还得分开重写。而且，如果是 服务器——浏览器模型的话，会随着平移接受到新数据，直接放进 scene 会相当紧密。不知是否应该单独独立成一个数据对象在 scene 树之外，dom js 之中。

Object3D 的成员猜想应该是 顶点和边，材质等。这是 View 层的一个model， 而客户端数据应当独立与它存在，因为 数据点的属性不含3d 位置，是独立的。

这样需要设计客户端数据的结构。应该受想要表现的内容决定。…… 睡觉待续

睡好）google threejs labeling 给出 https://bocoup.com/weblog/learning-three-js-with-real-world-challenges-that-have-already-been-solved 这个例子。

BUG: 同样陷入迷思的还有 HUD，镜头上的标尺。现在的标尺，是在镜头移动和缩放的时候，重新计算而得到的。有精确度和延迟。——问题可能是，标尺并没有被当作场景中的对象来做，而是手动在做这些计算。 —— 如果要在镜头上加标尺，其实可以的做法是，使用 THREE.js 的 Sprite 对象（总是朝向镜头，我之前不知道有这个类可用），把sprite 总是移动到镜头前。——至于标尺刻度的缩放问题，其实如果不把标尺放在镜头前（镜头前的其实应该叫做比例尺），根据数据范围选择百分比合适的标尺，替换场景中的固定标尺物体就可以了（它按照 three.js  是自然缩放的）

TODO: 重写 ruler 类，可以把它改成 grid，放入场景。

应该分开考虑 shiori 的 3D 和 2D 视图，threejs 是用来做 3D 窗口的，浏览器本身就是 2D 的。如果用 2D 的时间轴，其实用不到 3D库。

可能需要查一下 three.js 的 API。

数据，标签，标尺。

DONE:
1)先不动结构，先把Label 显示上去。保存分支。

…… labeling 分支上未保存的两个文件是 Labeling （算法模块，可以算是 app 的 controller 的子模块），和 DataGroupLabeling（数据群的辅助算法，可以算是场景中的 meta data 对象，便于分块管理，也是算法模块的子块，向算法提供接口 <LabelAble>）

在给数据群加标签的时候，可以每次重绘遍历所有数据点，然后给同类的，可以加标签的加标签。——为了减轻负担（数据点总是属于某个组，这个组一直存在，不需要每次都从所有点去计算分组），所以给组配备一个标签算法，叫做 DataGroupLabeling，遇到 DataGroup ，就 新建 DataGroupLabeling 对象（具体的对 DataGroup 加标签的算法）。
——这里可能有更直白一点的设计模式。Strategy ?  https://www.google.com/?#newwindow=1&safe=off&q=Data+set+and+algorithm+design+pattern 

首先，duck type 的语言可能并不应用策略模式。其次，Labeling 是一个操作，不是一个算法，某些对象可不可以加 Label ，可以用直接在上面检测是否有 label 方法，有就调用。

比如，可以直接扫描已经注册的 Label 对象，脏的，就调用它的 update 方法。

有了事件驱动的框架之后。本来，JS 就是作为静态文档上的动态语言而存在的。放好数据类型，变动是少数情况。这些情况以事件抛出，由脚本处理。所以在设计上，因为不是一个每帧重绘的应用。所以可以尽量放入静态物体，在变化时抛出事件，视情况重绘。

…… 更进一步，因为用户交互输入总是改变某个点的属性，所以，这是一个双向绑定 。但和 angular 的视图端绑定不同，这是跨越了 MVC 三层的。用户改 view，controller 监听到，修改模型数据。模型数据变动，controller 监听到，更新 view。如果进一步连接就会形成死循环。从 UI 的 U 型流动来看，断开的地方在用户。

这么说来，应该给需要标签的物体添加一个标签子对象。重绘时，在画面内，并且没有隐藏的，就绘制标签到标签层。

如何判断在画面内？https://threejs.org/docs/index.html?q=fru#Reference/Math/Frustum 就是用来做这个事情的。three.js 本身可能用了这个来确定某个顶点是否在视锥内部。实例代码在 http://stackoverflow.com/questions/10858599/how-to-determine-if-plane-is-in-three-js-camera-frustum#

    camera.updateMatrix(); // make sure camera's local matrix is updated
    camera.updateMatrixWorld(); // make sure camera's world matrix is updated
    camera.matrixWorldInverse.getInverse( camera.matrixWorld );

    plane.updateMatrix(); // make sure plane's local matrix is updated
    plane.updateMatrixWorld(); // make sure plane's world matrix is updated

    var frustum = new THREE.Frustum();
    frustum.setFromMatrix( new THREE.Matrix4().multiply( camera.projectionMatrix, camera.matrixWorldInverse ) );
    alert( frustum.contains( plane ) );





但是单独为了标签再判断一遍有点重了……， 有没有回调可以获得目前在视锥内的顶点之类，毕竟已经判断过一遍了……

https://threejs.org/docs/index.html#Reference/Core/BufferAttribute 可以看到 THREE.js 让你可以用它内部一些对象来存储自己的数据，相当的开放。所以这里我需要去学习一下 three.js 的主要结构和对象方法。

果然又发现了更好用的 Layers 对象（而且是 core 部分对象）。可以把标签对象标记到一层可见或不可见的layer上了。（具体用法待实验）
https://threejs.org/docs/index.html#Reference/Core/Layers

因为 THREE.js 里有自定义对象，所以事件处理部分实际上实现了浏览器 host 对象的属性，实际功能上算是一个微型浏览器了。（这是一个“界面递归自举”的例子）

所以标签对象可以通过场景里的 object3D 来实现了。自带 on/ off 方法。
分组则可以 Box3D.setFromObject(o) ，此方法会考虑 o 的所有子物体。




综上所述，如下重新实现 Label 的显示：
    1. 每个放入场景的 数据点，有一个 label 子物体，它的 layers 默认会激活到 LABEL_OFF(1) 层。lable 是从 LabelSet 类的方法 getLabel 得到（得到的 Label 会向LabelSet 类注册一下自己）。
    2. 当想要3D场景中显示一个 object （例如 DataPoint ）的标签时，遍历其子物体，如果是 Label 类型，就设置其 layers 到 LABEL_ON(0) ——这里使用常数，以后也可以指定到不是 默认显示层的其它层去。 当想要在DOM 中单独一层显示某个标签时，接口是isVisible，实现是基于 layer 是否在 LABEL_ON。
    3. 在 HTML 层绘制标签。（不采用这里的3步实现，原因见后文）
        * 首先从 DOM 中取下 div Label，避免每个 子 div 标签引起dom 重绘。 
        * 遍历 Label 中注册的标签，使用 Frustum Culling + Camera 为输入信息，对在像锥内部的 Label ，通过 投影矩阵和 canvas 位置，计算其 DOM 内坐标，根据内容计算右宽度，超出窗口范围的，不做绘制。新建 DOM div ，加入到DOM。
        * 把 div label 重新插入回 body 的 label_contianer div。
    3 的改进：因为 three.js 有许多回调钩子比如：

         .onBeforeRender
         An optional callback that is executed immediately before the Object3D is rendered. This function is called with the following parameters: renderer, scene, camera, geometry, material, group. 

        .onAfterRender
        An optional callback that is executed immediately after the Object3D is rendered. This function is called with the following parameters: renderer, scene, camera, geometry, material, group. 

    所以，不在范围内的物体的不会被 render，(DONE确认不触发回调)自然就不用计算其标签。这样，上面的 3 就可以简单的实现为：
    * 重绘前，取下/标记 DOM 中的 labelroot， 清除其中所有标签
    * render scene (钩子中重建标签)
    * 把 labelroot 放回 DOM
    之前，维护 LabelSet 的目的首先是为了可以仅对在屏幕上的标签做临时开关，其次是允许标签算法对在屏幕上的标签做统筹。然而显示与否用 label-containter div 的 visibility = hidden; 就可以做成一个开关。单个数据点的消失，直接触发重绘（让挂钩处理）。
    统筹算法则可以通过钩子回调去记录当前帧被渲染的场景对象，然后在render 后运行一次算法。

Object3D.visible exists, so no need to use layer for implementing visibility.

https://github.com/mrdoob/three.js/pull/10093 有一些关于这两个钩子的讨论。
我觉得只要避免挂太重的东西，这是可以用的。

? `onBeforeRender` 居然无效？ 用 Cube / Line 测试发现被调用了，这似乎说明，不含有Geometry，Object3D 就不会被render。

查看 threejs 源码发现，scene 中的对象经过 project，分为实心和透明两个列表分别render，render中调用这两个回调。project 步骤里，只有 visible 的，并且是 Mesh, Line, Points 之一的，才会被 pushRenderItem，进而被 render。

... So shall I let Label inherits THREE.Points ? Try, worked. No needs for .geometry ( threre are defaults ).



遇到一个 coffee script's corner case:
        
    # intend: if this.div is not defined, then call this.makeDOMdiv
    if not @div? then @makeDOMdiv

    # but coffee script compile it to `if (_this.div == null )`
    # because the compiler determined that item was defined in your code.
    # http://stackoverflow.com/questions/9929306/coffeescript-undefined
    #

but in my case, @div may not be defined

    # should be @?div



= Two different Labeling Design
1. "Paste" label on to DataPoint, make `Label` a child object, hook `Label::updateDivPos` to objec3d's call back `onAfterRender`.
2. Separate label from data points.  Let three.js render scene, after that, do labeling algorithm. ( This will need a clear ADT=Abstract Data Type be designed firstly)

TODO: a patch to 1, hook `need Lable` to `WebPage extends DataPoint`, then do a labeling algorithm on them. ( assume `WebPage` as ADT )
