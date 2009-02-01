<div id="header">
	<div id="masthead">
		<h1><span></span>Silver Lining Networks</h1>
		<!-- NAVIGATION -->
		
		<ul class="one_sixth right topnav">
		    <li class="help"><a href="#">Help</a></li>
		    <li><a href="#">Logout</a></li>
		</ul>
	
	<div class="clear"></div>
	</div>
	<!-- END -->

	
	<?php $currentPage = basename($_SERVER['SCRIPT_NAME']) ?>
	<div id="navigation">  
		<ul>
		    <li <?php if($currentPage == 'settings.php') {echo 'class="selected"';} ?>><a href="settings.php">Settings</a></li>
		    <li <?php if($currentPage == 'statistics.php') {echo 'class="selected"';} ?>><a href="statistics.php">Statistics</a></li>
		    <li <?php if($currentPage == 'campaigns.php' || $currentPage == 'campaign_wizard1.php' || $currentPage == 'campaign_wizard2.php') {echo 'class="selected"';} ?>><a href="campaigns.php">Campaigns</a></li>
		    <li <?php if($currentPage == 'network.php' || $currentPage == 'add_router.php') {echo 'class="selected"';} ?>><a href="network.php">My Network</a></li>
		    <li <?php if($currentPage == 'home.php') {echo 'class="selected"';} ?>><a href="home.php">Dashboard</a></li>
		</ul>
		<div class="clear"></div>
	</div>
</div>


<div id="breadcrumb">  
<ul>
<?php if($currentPage == 'network.php') {echo('<li><a href="network.php">All Routers</a></li>');	}?>
<?php if($currentPage == 'add_router.php') {echo('<li><a href="network.php">All Routers</a></li>	<li class="selected"><a href="#">Add Router</a></li>');	}?>
<?php 
# WIZARD BREAD CRUMB TRAIL
if($currentPage == 'campaign_wizard1.php') {echo('<li><a href="campaigns.php">Campaigns</a></li>	<li class="selected"><a href="#">Campaign Creator (STEP 1)</a></li>');}	
if($currentPage == 'campaign_wizard2.php') {echo('<li><a href="campaigns.php">Campaigns</a></li>	<li><a href="campaign_wizard1.php">Campaign Creator (STEP 1)</a></li><li class="selected"><a href="#">(STEP 2)</a></li>');}
if($currentPage == 'campaign_wizard3.php') {echo('
		<li><a href="campaigns.php">Campaigns</a></li>	
		<li><a href="campaign_wizard1.php">Campaign Creator (STEP 1)</a></li>
		<li><a href="campaign_wizard2.php">(STEP 2)</a></li>
		<li class="selected"><a href="#">(STEP 3)</a></li>
	');}

?>

  </ul>
<div class="clear"></div>
</div>

