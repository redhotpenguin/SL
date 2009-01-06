<!-- CARD TYPE -->
<dt><label for="card_type">Card Type</label></dt>
<dd>
	<span class="half">
		<select class="left" id="card_type">
			<option value="cardtype" selected="selected">Select a card type</option>
			<option value="visa">Visa</option>
			<option value="mastercard">MasterCard</option>
			<option value="amex">American Express</option>
		</select>
	</span>
	<img class="left" src="/resources/images/icons/creditcards.png" alt="creditcards"/>
	<div class="clear"></div>
</dd>


<!-- CARD NUMBER -->
<dt><label for="card_number">Card Number</label></dt>
<dd>
	<span class="half">
		<input maxlength="16" class="creditcard" type="text" id="card_number" value="################"/>
		<label for="card_number">numbers only, no spaces</label>
	</span>
	<span class="quarter">
		<input maxlength="4" class="numbers_only" type="text" id="cvc" value="###" />
		<label for="cvc"><a href="#">CVC</a></label>
	</span>
	<div class="clear"></div>
</dd>


<!-- EXPIRATION DATE -->
<dt><label for="month">Expiration Date</label></dt>
<dd class="large_margin">
	<!-- MONTH -->
	<span class="quarter">
		<select id="month">
			<option value="january">01</option>
			<option value="february">02</option>
			<option value="march">03</option>
			<option value="april">04</option>
			<option value="may">05</option>
			<option value="june">06</option>
			<option value="july">07</option>
			<option value="august">08</option>
			<option value="september">09</option>
			<option value="october">10</option>
			<option value="november">11</option>
			<option value="december">12</option>
		</select>
		<label for="month">Month</label>
	</span>
	
	<!-- YEAR -->
	<span class="quarter">
		<select id="year">
			<option value="2008">2008</option>
			<option value="2009">2009</option>
			<option value="2010">2010</option>
			<option value="2011">2011</option>
			<option value="2012">2012</option>
			<option value="2013">2013</option>
			<option value="2014">2014</option>
			<option value="2015">2015</option>
			<option value="2016">2016</option>
			<option value="2017">2017</option>
			<option value="2018">2018</option>
			<option value="2019">2019</option>
			<option value="2020">2020</option>
			<option value="2021">2021</option>
			<option value="2022">2022</option>
			<option value="2023">2023</option>
			<option value="2024">2024</option>
			<option value="2025">2025</option>
			<option value="2026">2026</option>
		</select>
		<label for="year">year</label>
	</span>					
	<div class="clear"></div>
</dd>
