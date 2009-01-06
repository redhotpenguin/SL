window.onload = submitOnce();

function submitOnce() {
	 if(!document.getElementById) return false;
	 if(!document.getElementById("submit")) return false;
	 
	 var submit_button = document.getElementById("submit");
	 
	 document.forms.onsubmit = function() {
	 	submit_button.setAttribute("disabled", "disabled");
	 	alert("booga")
	 }

}