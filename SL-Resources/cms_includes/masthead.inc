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
		    <li <?php if($currentPage == 'cms_settings.php') {echo 'class="selected"';} ?>><a href="cms_settings.php">Settings</a></li>
		    <li <?php if($currentPage == 'cms_stats.php') {echo 'class="selected"';} ?>><a href="cms_stats.php">Statistics</a></li>
		    <li <?php if($currentPage == 'cms_campaigns.php') {echo 'class="selected"';} ?>><a href="cms_campaigns.php">Campaigns</a></li>
		    <li <?php if($currentPage == 'cms_network.php' || $currentPage == 'cms_add_router.php') {echo 'class="selected"';} ?>><a href="cms_network.php">My Network</a></li>
		    <li <?php if($currentPage == 'cms_index.php') {echo 'class="selected"';} ?>><a href="cms_index.php">Dashboard</a></li>
		</ul>
		<div class="clear"></div>
	</div>
</div>


<div id="breadcrumb">  
<ul>
<?php if($currentPage == 'cms_network.php') {echo('<li><a href="cms_network.php">All Routers</a></li>');	}?>
<?php if($currentPage == 'cms_add_router.php') {echo('<li><a href="cms_network.php">All Routers</a></li>	<li class="selected"><a href="#">Add Router</a></li>');	}?>
  </ul>
<div class="clear"></div>
</div>

