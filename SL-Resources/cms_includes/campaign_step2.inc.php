<div class="paper_box">
	<div class="paper_box_inner">

			<h2 class="form_header">Create a Campaign - Advertisements <em>(step 2 of 4)</em></h2>
			<form class="form" action="campaign_wizard2.php" method="post">
					<table class="router_table">
							<thead>
								<tr>
									<th class="router_name">advertisement name</th>
									<th class="mac_address">preview</th>
									<th class="delete">delete</th>
								</tr>
							</thead>
							<tbody>
								<tr>
									<td class="router_name"><a href="#">Coke is it!</a><br/><em>size: 600x80px</em></td>
									<td class="mac_address"><a href="#">Preview ad</a></td>
									<td class="delete"><a href="#">delete</a></td>
								</tr>
								<tr>
									<td class="router_name"><a href="#">Match.com Singles</a><br/><em>120x500px</em></td>
									<td class="mac_address"><a href="#">Preview ad</a></td>
									<td class="delete"><a href="#">delete</a></td>
								</tr>				
						</table>			
				<ul>
					<li class="one_third innerform">
							<div class="row">
								<label for="ad_name">Advertisement Name <strong>*</strong></label>
								<input type="text" name="ad_name" value="" />
							</div>
							<div class="row">
								<label for="invocation" class="left">Invocation Code <strong>*</strong></label>
								<a class="hint right" href="#">what's this?</a>
								<textarea class="clear" id="invocation" name="invocation" rows="3" cols="20"></textarea>
							</div>
							<div class="row">
								<label class="left" for="ad_size">Dimensions <strong>*</strong></label>
								<a class="right hint" href="#">what's this?</a>
								<select name="ad_size" class="clear">
									<option value="fullbanner">468px by 60px (full banner)</option>
									<option value="leaderboard">728px by 90px (leaderboard)</option>
								</select>
								<label class="tip" for="ad_size">(height by width) must match ad size</label>
							</div>
							<div>
								<span class="standard_button left"><input type="submit" value="Add Advertisement" name="add_advertisement" /></span>
								<em>or <a  class="cancel_ad red_link" href="campaign_wizard1.php">Cancel</a></em>
								<div class="clear"></div>
							</div>
					</li>	
					<li class="one_third">
						<a class="add_link" href="#">Add another advertisement</a>
					</li>		
				</ul>
				<div class="submit_form">
					<span class="standard_button_large left"><a href="campaign_wizard3.php">Next Step</a></span>
					<em>or <a href="campaign_wizard1.php">Go Back</a></em>
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