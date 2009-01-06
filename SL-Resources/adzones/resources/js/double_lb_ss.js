function silverLiningClose() {
var container = document.getElementById('silver_lining_ad_horizontal');
var skyscraper = document.getElementById("silver_lining_double_ad_lb");
var webpage = document.getElementById('silver_lining_skyscraper_webpage');
var nopadding = "margin-left: 0px !important"
var hideitem = "display:none;";
var topzero = "top:0; display:none;";

container.style.cssText = hideitem;
skyscraper.style.cssText = topzero;
webpage.style.cssText = nopadding;
};