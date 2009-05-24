$(document).ready(function(){
	//NAVIGATION HOVER BUTTONS
	$('#navigation li').hover(function(){
		$(this).addClass('active');
	}, function(){
		$(this).removeClass('active');
	});
	
	$('#navigation li').click(function(){
		$(this).siblings().removeClass('selected');
		$(this).addClass('selected');
	});
	
});