<?php include('cms_includes/header.inc'); ?>
<?php include('cms_includes/masthead.inc'); ?>

<div id="wrap">
	<div id="content">
		<div id="content-layout">
			<div id="content-primary-wrap">
			<div id="content-primary">
			
			<?php include('cms_includes/router_table.inc.php');?>
				
					
			</div><!-- End primary content -->
			</div><!-- End primary content wrap -->
			
			<div id="content-secondary">
				<a class="add_button" href="cms_add_router.php">Add a router</a>
				<p>
					<strong>Tip:</strong> once you have finished activating your router you can <a href="#">setup an Ad Campaign</a> in the 
					<a href="cms_campaigns.php">Campaign</a> section of your account. 
				</p>
				
				
			</div><!-- End secondary content -->
			<div class="clear"></div>
		</div>
	</div>
</div>



<?php include('cms_includes/footer.inc'); ?>
