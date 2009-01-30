
<div class="paper_box">
	<div class="paper_box_inner">
	
			<h2 class="form_header">Add A Router</h2>
			<form class="form" action="cms_network.php" method="post">
				<ul>
					<li class="one_third">
						<label for="router_name">Give your router a name</label>
						<input type="text" name="router_name" value="" />
					</li>
					<li class="one_third ">
						<label class="left" for="mac_address">MAC address</label>
						<a class="right hint" href="#">what's this?</a>
						<input class="clear" type="text" name="mac_address" value="" />
						<label class="tip">example: 00:16:a3:78:32:60</label>
					</li>
					<li class="one_third ">
						<label class="left" for="ad_campaign">Advertisement Campaign</label>
						<a class="right hint" href="#">what's this?</a>
						<select name="ad_campaign" class="clear">
							<option value="Silver Lining (default)">Silver Lining (default)</option>
							<option value="Bling Bling">Bling Bling</option>
						</select>
					</li>		
				</ul>
				<div class="submit_form">
					<span class="standard_button_large left"><input type="submit" value="Add Router" name="submit" /></span>
					<em>or <a href="cms_network.php">Cancel</a></em>
					<div class="clear"></div>
				</div>
			</form>
			
			
	</div>
</div>
<div class="paperbox_footer margin_20_b">
	<div class="pb_left"></div>
	<div class="pb_center"></div>
	<div class="pb_right"></div>
</div>	