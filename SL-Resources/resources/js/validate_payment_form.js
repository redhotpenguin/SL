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