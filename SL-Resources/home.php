<?php include('cms_includes/header.inc.php'); ?>
<?php include('cms_includes/masthead.inc.php'); ?>

<div id="wrap">
	<div id="content">
		<div id="content-layout">
			<div id="content-primary-wrap">
			<div id="content-primary">
			
			<?php include('cms_includes/notification.inc.php'); ?>
			
				
			
			<?php include('cms_includes/activity_table.inc.php'); ?>
				
					
			</div><!-- End primary content -->
			</div><!-- End primary content wrap -->
			
			<div id="content-secondary">
				
				<ul>
					<li><a class="icon_add" href="add_router.php">Add a router</a></li>
					<li><a class="icon_wand" href="campaign_wizard1.php">Create an ad campaign</a></li>
					<li><a class="icon_stats" href="statistics.php">View network statistics</a></li>
					<li><a class="icon_money" href="settings.php">View sales and ad revenue</a></li>
				</ul>
				
				
			</div><!-- End secondary content -->
			<div class="clear"></div>
		</div>
	</div>
</div>



<?php include('cms_includes/footer.inc.php'); ?>
