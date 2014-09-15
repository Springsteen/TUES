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
        function(response){
            if(response){
                var selectBoxExists = document.getElementById("type_select");
                if (selectBoxExists == null){
                    $("<select id=\"type_select\" name=\"model_type_id\"></select>").insertAfter("#ajax_types");
                }else{
                    $("#type_select").remove();
                    $("<select id=\"type_select\" name=\"model_type_id\"></select>").insertAfter("#ajax_types");
                }
                for (var id in response) {
                    if(response.hasOwnProperty(id)){
                        var option = "<option value=\"";
                        for (var property in response[id]){
                            if(response[id].hasOwnProperty(property)){
                                if(property != "id"){
                                    option += response[id][property];
                                    console.log(option + "\" ></option>");
                                    $("#type_select").append(option + "\" >" + response[id][property] + "</option>");
                                }
                            }
                        }
                    }
                }
            }
        }
    );
});