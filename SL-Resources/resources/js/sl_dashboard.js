this.imagePreview = function(){	
	/* CONFIG */
		
		xOffset = 10;
		yOffset = 30;
		
		// these 2 variable determine popup's distance from the cursor
		// you might want to adjust to get the right result
		
	/* END CONFIG */
	$("a.preview").hover(function(e){
		this.t = this.title;
		this.title = "";	
		var c = (this.t != "") ? "<br/>" + this.t : "";
		$("body").append("<p id='preview'><img src='"+ this.rel +"' alt='Image preview' />"+ c +"</p>");								 
		$("#preview")
			.css("top",(e.pageY - xOffset) + "px")
			.css("left",(e.pageX + yOffset) + "px")
			.fadeIn("fast");						
    },
	function(){
		this.title = this.t;	
		$("#preview").remove();
    });	
	$("a.preview").mousemove(function(e){
		$("#preview")
			.css("top",(e.pageY - xOffset) + "px")
			.css("left",(e.pageX + yOffset) + "px");
	});			
};


function graphSlider() {
	if(!$('#graph-traffic-users') || !$('#graph-checkin-memory') ) return;
	
	
	//Container Vars
	var device = $('#device-settings'); 
	var traffic = $('#graph-traffic-users'); 
	var mesh = $('#graph-mesh-stats'); 
	var hasMesh = false;
	var memory = $('#graph-checkin-memory'); 
	if(mesh.length > 0) {
		hasMesh = true; 
	}
	
	
	//Link Vars
	var deviceNav = $('#graph-settings-nav'); 
	var trafficNav = $('#graph-traffic-nav'); 
	var meshNav = $('#graph-mesh-nav'); 
	if(hasMesh == false) {
		meshNav.parent().hide(); 
	}
	var memoryNav = $('#graph-memory-nav'); 
	var list = $('.link-nav li a'); 
	
	//Add Events
	deviceNav.click(function() {
		list.removeClass('selected'); 
		$(this).addClass('selected'); 
		device.show(); 
		traffic.hide(); 
		if(hasMesh) mesh.hide(); 
		memory.hide(); 
		return false; 
	}); 
	meshNav.click(function() {
		list.removeClass('selected'); 
		$(this).addClass('selected'); 
		device.hide(); 
		traffic.hide(); 
		if(hasMesh) mesh.show(); 
		memory.hide(); 
		return false; 
	}); 
	trafficNav.click(function() {
		list.removeClass('selected'); 
		$(this).addClass('selected'); 
		device.hide(); 
		traffic.show(); 
		if(hasMesh) mesh.hide(); 
		memory.hide(); 
		return false; 
	}); 
	memoryNav.click(function() {
		list.removeClass('selected'); 
		$(this).addClass('selected'); 
		device.hide(); 
		traffic.hide(); 
		if(hasMesh) mesh.hide(); 
		memory.show(); 
		return false; 
	}); 
}; 


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


    // readonly for deterin fields
    function setDeviceForm() {

        var device = $("#device").val();
        if ( device == 'mr3201a' || !device ) {

            $("#name").attr("readonly", true);
            $("#device").attr("readonly", true);
            $("#macaddr").attr("readonly", true);
            $("#notes").attr("readonly", true);
            $("#wrt54gl").css("display","none");

        } else if (device == 'wrt54gl' ) {

            $("#device").attr("readonly", false);
            $("#name").attr("readonly", false);
            $("#macaddr").attr("readonly", false);
            $("#notes").attr("readonly", false);
            $("#wrt54gl").css("display","block");

        }
    }

    // Change router edit page based on device
    $("#device").change(setDeviceForm);
    setDeviceForm();


	//CODE FOR HIDING OR SHOWING BANNER IMAGE LINK OR INVOCATION CODE
    if ($("input[name='zone_type']:checked").val() == 'banner') {
    	$('#code').hide();
    	$('.banner').show();
    } else if ($("input[name='zone_type']:checked").val() == 'code') {
    	$('.banner').hide();
    	$('#code').show();
    };
	//Check again when value changes
	$("input[name='zone_type']").change(function(){
    if ($("input[name='zone_type']:checked").val() == 'banner') {
    	$('#code').hide();
    	$('.banner').show();
    } else if ($("input[name='zone_type']:checked").val() == 'code') {
    	$('.banner').hide();
    	$('#code').show();
    };
	});

    //find all form with class jqtransform and apply the plugin
    $(".form").jqTransform();	

	//Hover image 
	imagePreview();
	graphSlider(); 
	
});
