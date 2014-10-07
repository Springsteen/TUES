$(document).ready(function () {

    $("#1").on("click", function(){
        var input = [];
        for (var i = 0; i < 100000; i++) {
            input.push(i);
        };

        var start = new Date().getTime();
        // console.log(start);
        var template = $("#test1").html();
        var html = Mustache.to_html(template, input);

        var end = new Date().getTime();
        // console.log(end);

        // console.log();

        $("#content").html("runtime in mileseconds => " + (end-start));
    });

});