//First Name
var first_name = new LiveValidation('first_name');
first_name.add( Validate.Presence );

//Last Name
var last_name = new LiveValidation('last_name');
last_name.add( Validate.Presence );

//E-mail
var email = new LiveValidation('email');
email.add( Validate.Presence );
email.add( Validate.Email );

//Credit Card
var card_number = new LiveValidation('card_number');
card_number.add( Validate.Presence );
card_number.add( Validate.Numericality );

//CVC
var cvc = new LiveValidation('cvc');
cvc.add( Validate.Presence );
cvc.add( Validate.Numericality );

//Billing Address
var street = new LiveValidation('street');
street.add( Validate.Presence );

//City
var city = new LiveValidation('city');
city.add( Validate.Presence );

//ZIP
var zip = new LiveValidation('zip');
zip.add( Validate.Presence );
zip.add( Validate.Numericality );

// ACCEPT AGREEMENT
var agreement = new LiveValidation('terms');
agreement.add(Validate.Acceptance);



// SUBMIT ONCE FUNCTION
function submitOnce() {
	if(!document.getElementById) return false;
	if(!document.getElementById("submit")) return false;
	var submit_button = document.getElementById("submit");
	
	//Create Loading Image
	var loader = document.createElement("img"); 
	loader.setAttribute("alt", "processing");
	loader.setAttribute("src", "resources/images/icons/spinner.gif")
	
	// GRAB LIST 
	if(!document.getElementById("form_list")) return false;
	var formlist = document.getElementById("form_list");
	var list_item = document.createElement("dd");
	
	//CREATE MESSAGE
	var message = document.createElement("p");
	var messagetext = document.createTextNode("Processing, Please Wait...");
	message.appendChild(messagetext);
	
	// Get form
	if(!document.getElementById("sl_payment")) return false;
	var formbox = document.getElementById("sl_payment");
	
	//Append to list item
	list_item.appendChild(loader);
	list_item.appendChild(message)
	
	
	formbox.onsubmit = function() {
		submit_button.setAttribute("disabled", "disabled");
		submit_button.setAttribute("value", "Thank You");
		submit_button.className = "disabled";
		formlist.appendChild(list_item);
	}

}



window.onload = submitOnce;

















