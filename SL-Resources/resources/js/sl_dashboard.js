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
	
	//SUBMIT FORM DISABLE BUTTON
	$("#submit").click(function(){
	$("<input disabled='disabled' type='submit' value='Please Wait'>").insertBefore("#submit");
	$(this).hide();	
	}).submit(function(){
	$(this).attr("disabled", "disabled");
	});
	
});