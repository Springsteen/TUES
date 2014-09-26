$(document).ready(function(){

    var source = $("#template_1").html();
    var template = Handlebars.compile(source);

    var content = {title: "Handlebars test title", body: "Handlebars test body"};
    var html = template(content);

    $("#get_template_1").on("click", function(){
        $("#template_1_div").remove();
        $("#content").append(html);
    });

});