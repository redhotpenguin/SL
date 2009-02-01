$(document).ready(function(){
	$('.innerform').hide();
	$('.add_link').click(function() {
		$('.innerform').slideDown("slow");;
		$(this).hide();
	});
	$('.cancel_ad').click(function(){
		$('.innerform').slideUp("fast");;
		$('.add_link').show();
		return false;
	});


});