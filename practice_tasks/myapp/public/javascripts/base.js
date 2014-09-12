$(document).ready(function(){
	$( ".field" ).keyup(function() {
		$(this).css({'border-color' : 'red'});
	});
});

$(document).on('click', '.ajax', function(){
    $(this).val("");
});

$(document).on('keyup', '#ajax_types', function(){
    var input = $(this).val();
    $.getJSON(
        "/get_types", 
        {input : input},
        function(result){
            // result = JSON.parse(result);
            console.log(result);
        }
    );
});