/*
AUTHOR: SILVER LINING NETWORKS INC.
NAME: SIMPLE VALIDATION
VERSION: 1.0 12/25/2008
COPYRIGHT: SILVER LINING NETWORKS INC. 
*/


// GENERAL SCRIPTS -------------------------------------------------------------
function insertAfter(newElement, targetElement) {
	var parent = targetElement.parentNode;
	if (parent.lastChild == targetElement) {
		parent.appendChild(newElement);
	} else {
		parent.insertBefore(newElement, targetElement.nextSibling);
	}
}




//FORM HELPER SCRIPTS ------------------------------------------------------------

//RESET FIELDS
function resetFields(whichform) {
	for(var i=0; i<whichform.elements.length; i++) {
		var element = whichform.elements[i];
		if (element.type == "submit" ) continue;
		if(!element.defaultValue) continue;
		element.onfocus = function() {
			if(this.value == this.defaultValue) {
				this.value = "";
			}
		}
		element.onblur = function() {
			if(this.value =="") {
			this.value = this.defaultValue;
			}
		}
	}
}


// SUBMIT ONCE FUNCTION ===========================//
function submitOnce(whichform) {
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
	
	submit_button.setAttribute("disabled", "disabled");
	submit_button.setAttribute("value", "Thank You");
	submit_button.parentNode.setAttribute("id", "disabled");
	formlist.appendChild(list_item);
}


// CHECK FOR FORM COMPLETION ===========================//
function submitValidation(whichform) {
	for(var i=0; i<whichform.elements.length; i++) {
	
		var element = whichform.elements[i];
		if(element.className.indexOf("required") != -1) {
			if(!isFilled(element)) {
				element.style.border = "3px solid #F00";
				alert("Please fill in the the required fields.");
				element.style.border = "3px solid #F00";
				return false;
			}
		}
		
		if(element.className.indexOf("email") != -1) {
			if(!isEmail(element)) {
				alert("the "+element.name+" field must be a valid email address.");
				return false;
			}
		}
	}
	return true;
}



//FORM VALIDATION SCRIPTS ---------------------------------------------------------

// IS THE FIELD FILLED?
function isFilled(field) {
	if(field.value.length < 1 || field.value == field.defaultValue ) {
		return false;
	} else {
		return true;
	}
}

//IS EMAIL CORRECT?
function isEmail(field) {
	if(field.value.indexOf("@") == -1 || field.value.indexOf(".") == -1 ||  field.value == field.defaultValue) {
		return false;
	} else {
		return true;
	}
} 

//IS CREDIT CARD CORRECT?
function isCreditCard(field) {
	if(field.value.length < 16 || field.value.length > 16  ||  field.value == field.defaultValue) {
		return false;
	} else {
		return true;
	}
}



function validateForm(whichform) {
	//var whichform = document.getElementById(whichform);

	for(var i=0; i<whichform.elements.length; i++) {
		var element = whichform.elements[i];
		
		// VALIDATE REQUIRED ####################################
				if(element.className.indexOf("required") != -1) {
				//create a message box
				var messagebox = document.createElement("div");
				messagebox.setAttribute("id", "message_"+element.id);
				insertAfter(messagebox, element);
				
				//CHECK ONBLUR
				element.onblur = function() {
					var notice = document.getElementById("message_"+this.id);
					if(!isFilled(this)) {
						notice.innerHTML = "<p class='invalid'>required</p>";
						return false;
					} else {
						notice.innerHTML = "<p class='valid'>thank you</p>";
						}
					}
				}
		// END		
		
		
		
		// VALIDATE EMAIL ####################################
				if(element.className.indexOf("email") != -1) {
				var messagebox = document.createElement("div");
				messagebox.setAttribute("id", "message_"+element.id);
				insertAfter(messagebox, element);		
				
					element.onblur = function() {
					var notice = document.getElementById("message_"+this.id);
					if(!isEmail(this)) {
						notice.innerHTML = "<p class='invalid'>must be a valid email</p>";
						return false;
					} else {
						notice.innerHTML = "<p class='valid'>thank you</p>";
					
					}
					
					}
				}
		// END
		
		
		// VALIDATE CREDIT CARD ####################################
				if(element.className.indexOf("creditcard") != -1) {
				var messagebox = document.createElement("div");
				messagebox.setAttribute("id", "message_"+element.id);
				insertAfter(messagebox, element);		
				
					element.onblur = function() {
					var notice = document.getElementById("message_"+this.id);
					if(!isCreditCard(this) || isNaN(this.value)) {
						notice.innerHTML = "<p class='invalid'>must be 16 numbers</p>";
						return false;
					} else {
						notice.innerHTML = "<p class='valid'>thank you</p>";
					
					}
					
					}
				}
		// END	
		
			

		// NUMBERS ONLY ####################################
				if(element.className.indexOf("numbers_only") != -1) {
				var messagebox = document.createElement("div");
				messagebox.setAttribute("id", "message_"+element.id);
				insertAfter(messagebox, element);		
				
					element.onblur = function() {
					var notice = document.getElementById("message_"+this.id);
					if(!isFilled(this) || isNaN(this.value)) {
						notice.innerHTML = "<p class='invalid'>numbers only</p>";
						return false;
					} else {
						notice.innerHTML = "<p class='valid'>thank you</p>";
					
					}
					
					}
				}
		// END		

		
	}
}



function prepareForms(formid){
  for (var i=0; i<document.forms.length; i++) {
  		if(!document.getElementById(formid)) return false;
		var thisform = document.getElementById(formid);
		resetFields(thisform);
		validateForm(thisform);
		
		thisform.onsubmit = function() {
			if(submitValidation(this) == true) {
				submitOnce(this);
			} else {
				return false;
			}
			
		}
	}
}











window.onload = function() {
	prepareForms("sl_payment");
}


