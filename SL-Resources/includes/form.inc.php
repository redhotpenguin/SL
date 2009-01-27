<h2 class="form_header">Add A Router</h2>
<form class="form" action="" method="post">
	<ul>
		<li class="one_third">
			<label for="router_name">Create a name <strong>*</strong></label>
			<input type="text" name="router_name" value="" />
		</li>
		<li class="one_third ">
			<label class="left" for="mac_address">MAC address <strong>*</strong></label>
			<a class="right hint" href="#">what's this?</a>
			<input class="clear" type="text" name="mac_address" value="" />
			<label class="tip">example: 00:16:a3:78:32:60</label>
		</li>
		<li class="one_third ">
			<label class="left" for="ad_campaign">Advertisement Campaign <strong>*</strong></label>
			<a class="right hint" href="#">what's this?</a>
			<select name="ad_campaign" class="clear">
				<option value="Silver Lining (default)">Silver Lining (default)</option>
				<option value="Bling Bling">Bling Bling</option>
			</select>
		</li>		
	</ul>
	<div class="submit_form">
		<input type="submit" value="Add Router" name="submit" />
		<span>or</span>
		<a href="#">Cancel</a>
	</div>
</form>