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


    // readonly for determining fields
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

    //find all form with class jqtransform and apply the plugin
    $("form.form").jqTransform();	

    // clear checkboxes for twitter or text message radio selection
    $("#twitter").change(updateZones);
    $("#text").change(updateZones);

    $("INPUT[type='checkbox']").click(
            function()
             {
                 if ($('#iab').attr('checked', false)) {
                         $('#iab').attr('checked', true);
                     }
              }
    )


    function updateIab() {

        if ($("#iab").attr('checked', false) ) {
            $("#iab").attr('checked', true);
        }
    }
    
   function updateZones() {
       adzones=document.getElementsByName('ad_zone');
       for (var i=0;i<adzones.length-1;i++) {
           adzones[i].checked=false;
       }	
   }

});
