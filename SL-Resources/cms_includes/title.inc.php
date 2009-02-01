<?php
$title = basename($_SERVER['SCRIPT_NAME'], '.php');

# TITLES FOR WIZARD STEPS
if($title == 'campaign_wizard1') {
$title = 'Campaign Creator (Step 1)';
};
if($title == 'campaign_wizard2') {
$title = 'Campaign Creator (Step 2)';
};
if($title == 'campaign_wizard3') {
$title = 'Campaign Creator (Step 3)';
};
if($title == 'campaign_wizard4') {
$title = 'Campaign Creator (Step 4)';
};



# TITLE FOR HOME PAGE
if($title == 'home') {
$title = 'Welcome to your account';
};

# FORMAT TEXT
$title = str_replace('_', ' ', $title);
$title = ucwords($title);
?>