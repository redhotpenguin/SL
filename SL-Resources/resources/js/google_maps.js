/* FUNCTIONS
============================================= */
var bubbleNavigation = function() {
	
	$('#gbub_overview_button').click(function() {
		$('#gbub_neighbors_button').removeClass('selected');
		$(this).addClass('selected');
		$('#gbub_neighbors').css({'display': 'none'});
		$('#gbub_overview').css({'display': 'block'});		
	}); 
	
	$('#gbub_neighbors_button').click(function(){
		$('#gbub_overview_button').removeClass('selected');
		$(this).addClass('selected');
		$('#gbub_overview').css({'display': 'none'});
		$('#gbub_neighbors').css({'display': 'block'});		
	}); 
	
}






