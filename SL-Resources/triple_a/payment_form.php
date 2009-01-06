<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link rel="stylesheet" type="text/css" href="resources/css/triple_a.css" />
  <!--[if IE 6]><link rel="stylesheet" type="text/css" href="resources/css/triple_a_ie6.css" /><![endif]--> 
 <!--[if IE 7]><link rel="stylesheet" type="text/css" href="resources/css/triple_a_ie7.css" /><![endif]-->   
  
  <script src="resources/js/simple_validation.js" type="text/javascript"></script>
  <title>Checkout: Payment Page - Silver Lining Networks</title>
</head>
<body id="sln">


<!-- TOP SECTION START #################### -->
	<div id="section_one">
		<div class="center">
			<!-- CHOOSE WIFI COPY ************************ --> 
			<div class="two_thirds left padding_top">
				<h2>Purchase WiFi Internet Access</h2>
				<p>
					<strong>You're almost there.</strong>  
					Please fill out the form below to purchase ad free high speed WiFi service.  
				 </p>
			</div>
						
			<!-- LOGO --> 
			<div class="one_third right">
				<?php include "form/silverlining_logo.php" ?> 
			</div>

			
			<div class="clear"></div>
		</div>
	</div>
<!-- TOP SECTION END -->
	
	
<!-- BODY SECTION START ######################################### -->
<?php include "form/bodywrapper_top.php"?> 


	<!-- MAIN COLUMN ######## -->
	<?php include "form/paperbox_top.php" ?> 
	
		<h2 class="header">Takes less than a minute</h2>
		
		<!-- PAYMENT FORM -->
		<form id="sl_payment" action="" method="post">
			<dl id="form_list">
				<dd class="subtle"><em>All fields required</em></dd>
				<?php include "form/plan.php" ?> 
				<?php include "form/user_info.php" ?> 
				<?php include "form/creditcard.php" ?> 
				<?php include "form/address.php" ?> 
				<!-- <?php include "form/agreement.php" ?> -->  
				<?php include "form/submit_button.php" ?> 									
			</dl>
		</form>
						
	<?php include "form/paperbox_bottom.php"?> 
	<!-- END MAIN COLUMN -->



	
	<!-- SIDE COLUMN ##### -->
	<div class="one_third left">
		<?php include "form/sidebar.php" ?> 
	</div>
	<!-- END SIDE COLUMN ##### -->
	
	
	
<?php include "form/bodywrapper_bottom.php"?> 		
<!-- END BODY SECTION ######################################### -->


<!-- PLEDGE -->
<?php include "form/our_pledge.php" ?> 
<?php include "form/coupon.php" ?>

</body>
</html>
