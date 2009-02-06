<?php include('cms_includes/header.inc.php'); ?>
<?php include('cms_includes/masthead.inc.php'); ?>

<div id="wrap">
	<div id="content">
		<div id="content-layout">
			<div id="content-primary-wrap">
			<div id="content-primary">
			

				
			<?php @ include('cms_includes/campaign_step3.inc.php');?>
				
					
			</div><!-- End primary content -->
			</div><!-- End primary content wrap -->
			
			<div id="content-secondary">
				<h2>How layouts work</h2>
				<dl>
					<dt>Select</dt>
					<dd>Selects the ad zone layout you want to use</dd>
					<dt>Layout</dt>
					<dd>Displays information about the layout with a picture to represent the layout. It show the dimensions and a link to preview what a live Ad Zone with this layout would look like</dd>
					<dt>Advertisement</dt>
					<dd>Select the one of the advertisements you created in step 2. Only the advertisements with the proper dimensions will be displayed in the drop-down menu for each layout.</dd>
					<dt>Position</dt>
					<dd>Some layouts have additional options such as "floating". When "floating" is checked the Ad will stay on top of the web page even when the user scrolls down the page.</dd>
				</dl>
				<h2>What order will these layouts appear?</h2>
				<p>
					If you select more than one Ad Zone Layout we randomly choose a layout each time a user visits a new web page.
				</p>
				
			</div><!-- End secondary content -->
			<div class="clear"></div>
		</div>
	</div>
</div>



<?php include('cms_includes/footer.inc.php'); ?>