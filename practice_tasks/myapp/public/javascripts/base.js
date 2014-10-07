$(document).ready(function(){
	$( ".field" ).keyup(function() {
		$(this).css({'border-color' : 'red'});
	});
});

$(document).on('click', '.ajax', function(){
    $(this).val("");
});

var currentInterval;

$(document).on('keyup', '.ajax', function(){
    var input = $(this).val();
    var searchBoxId = $(this).attr("id");
    var referedTable = searchBoxId.replace("ajax_", "");
    var currentType = $("#form_for").attr("name");
    if (currentInterval) {
        clearInterval(currentInterval);
    }
    currentInterval = setInterval(    
        $.getJSON(
            "/ajax_search", 
            {input : input, table: referedTable, current_type: currentType},
            function(response){
                if(response){
                    if(response.hasOwnProperty("select_tag_info")){
                        if(response["select_tag_info"].hasOwnProperty("name")){
                            var selectBoxName = response["select_tag_info"]["name"]; 
                        }
                        if(response["select_tag_info"].hasOwnProperty("id")){
                            var selectBoxId = response["select_tag_info"]["id"];
                        }
                    }
                    var selectBoxExists = document.getElementById(selectBoxId);
                    if (selectBoxExists == null){
                        $("<select id=\"" + selectBoxId + "\" name=\"" + selectBoxName + "\"></select>").insertAfter("#" + searchBoxId);
                    }else{
                        $("#" + selectBoxId).remove();
                        $("<select id=\"" + selectBoxId + "\" name=\"" + selectBoxName + "\"></select>").insertAfter("#" + searchBoxId);
                    }
                    for (var id in response) {
                        if(response.hasOwnProperty(id)){
                            if(id != "select_tag_info"){
                                var option = "<option value=\"";
                                for (var property in response[id]){
                                    if(response[id].hasOwnProperty(property)){
                                        if(property != "id"){
                                            option += response[id][property];
                                            $("#" + selectBoxId).append(option + "\" >" + response[id][property] + "</option>");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        )
    ,3000);
});