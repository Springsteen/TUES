$(document).ready(function (){
	var data = {
		title : "Cleaning Supplies",
		supplies : 
			['Embedded',
			'JS',
			'is',
			'so',
			'cool',
			'and',
			'I',
			'like',
			'writing',
			'it'
			]
	};
	
	$("#content_btn").on("click", function(){
		var html = new EJS({url: 'template1.ejs'}).render(data);
		var main = document.getElementById("content").innerHTML = html;
	});

	$("#err_btn").on("click", function(){
		var html = new EJS({url: 'template2.ejs'}).render(data);
	});

});