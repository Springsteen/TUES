$(document).ready(function(){
	$( ".field" ).change(function() {
		$(this).css({'border-color' : 'red'});
	});
	// $(".table-bordered").on("click", ".field", function (){
	// 		var id = $(this).attr("id");
	// 		console.log(id + "is clicked on");
	// 		var v = $(this).text();
	// 		console.log(v + "is the element text");
	// 		$(this).html('<input value=' + v + ' name=' + id + '>');
	// 		$(this).removeClass("field").addClass("active_field");
	// });
});