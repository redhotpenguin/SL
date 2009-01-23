function silverLiningClose() {
	var container = document.getElementById("silver_lining_floating_horizontal");
	var body_element = document.getElementsByTagName("body")[0];
	var html_element = document.getElementsByTagName("html")[0];
	var nopadding = "padding-bottom: 0px !important;"; 
	var hideitem = "display:none;";
	html_element.style.cssText = nopadding;
	body_element.style.cssText = nopadding;
	container.style.cssText = hideitem;
};

