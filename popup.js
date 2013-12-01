$(document).ready(function(){
    // style
    $(".menuitem").hover(
        function() { $(this).addClass("Hover");},
        function() { $(this).removeClass("Hover");}
    );

    // function
    $("#open_arranger").click(function(){
        window.open('arranger.html');
    });
    $("#add_new").click(function(){
    });

});
