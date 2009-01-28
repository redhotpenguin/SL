<?php include('cms_includes/header.inc'); ?>
<?php include('cms_includes/masthead.inc'); ?>

<div id="wrap">
	<div id="content">
		<div id="content-layout">
			<div id="content-primary-wrap">
			<div id="content-primary">
			

				<?php include('cms_includes/campaign_step1.inc.php');?>
				
				<table class="router_table">
					<thead>
						<tr>
							<th class="status">status</th>
							<th class="router_name">router name</th>
							<th class="mac_address">Mac address</th>
							<th class="delete">delete</th>
						</tr>
					</thead>
					<tbody>
						<tr>
							<td class="status"><strong class="active">active</strong></td>
							<td class="router_name"><a href="#">Starbucks Coffee Router</a><br/><em>Coffee Ad Campaign</em></td>
							<td class="mac_address">00:16:b6:28:84:d8</td>
							<td class="delete">delete</td>
						</tr>
						<tr>
							<td class="status"><strong class="inactive">inactive</strong></td>
							<td class="router_name"><a href="#">Pete's Coffee Router</a><br/><em>Coffee Ad Campaign</em></td>
							<td class="mac_address">00:16:b6:28:84:d8</td>
							<td class="delete">delete</td>
						</tr>
					</tbody>
				</table>
				
					
			</div><!-- End primary content -->
			</div><!-- End primary content wrap -->
			
			<div id="content-secondary">
				<a class="add_button" href="#">Add a router</a>
				<p>
					Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor
					incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis 
					nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. 
					Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore 
					eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, 
					sunt in culpa qui officia deserunt mollit anim id est laborum.
				</p>
				
				
			</div><!-- End secondary content -->
			<div class="clear"></div>
		</div>
	</div>
</div>



<?php include('cms_includes/footer.inc'); ?>