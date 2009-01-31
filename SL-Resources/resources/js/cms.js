$(document).ready(function(){
	$('.innerform').hide();
	$('.add_link').click(function() {
		$('.innerform').show('slow');
		$(this).hide();
	});
	$('.cancel_ad').click(function(){
		$('.innerform').hide();
		$('.add_link').show();
		return false;
	});


});