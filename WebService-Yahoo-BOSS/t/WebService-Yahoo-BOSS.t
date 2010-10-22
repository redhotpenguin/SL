#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;
BEGIN { use_ok('WebService::Yahoo::BOSS') }
BEGIN { use_ok('WebService::Yahoo::BOSS::ResultSet') }

can_ok( 'WebService::Yahoo::BOSS', qw( Web ) );

SKIP: {
    skip "ENV{YAHOO_APPID} not defined", 2, unless $ENV{YAHOO_APPID};

    my $boss = WebService::Yahoo::BOSS->new( appid => $ENV{YAHOO_APPID} );
    isa_ok( $boss, 'WebService::Yahoo::BOSS' );
    my $search = $boss->Web( query => 'sushi' );
    isa_ok( $search->[0], 'WebService::Yahoo::BOSS::Result' );
}

my $data = do { local $/; <DATA> };

my $rs = WebService::Yahoo::BOSS::ResultSet->parse($data);

cmp_ok($rs->totalhits, '==', '48257993');

my $results = $rs->results;
cmp_ok(scalar(@{$results}), '==', 5);

__DATA__
<?xml version="1.0"?>
<ysearchresponse xmlns="http://www.inktomi.com/" responsecode="200">
  <nextpage><![CDATA[/ysearch/web/v1/pizza?format=xml&filter=-porn&count=10&appid=QX5YVFjV34Ek3Tum61umwPyWkMR5p1sOWDrb4AI3_8DO5viUsyMC2E6nNOXzAc03&view=keyterms&start=10]]></nextpage>
  <resultset_web count="10" start="0" totalhits="48257993" deephits="317000000">
    <result>
      <abstract><![CDATA[Official site for Pizz Hut provides online ordering for dine-in and delivery, a <b>Pizza</b> Hut store finder, coupons, and menu.]]></abstract>
      <clickurl>http://lrd.yahooapis.com/_ylc=X3oDMTU4cTY1OWZlBF9TAzIwMjMxNTI3MDIEYXBwaWQDUVg1WVZGalYzNEVrM1R1bTYxdW13UHlXa01SNXAxc09XRHJiNEFJM184RE81dmlVc3lNQzJFNm5OT1h6QWMwMwRjbGllbnQDYm9zcwRzZXJ2aWNlA0JPU1MEc2xrA3RpdGxlBHNyY3B2aWQDSFE2R05VZ2VBdTBxMjBQaWtMWFFTaGl5Uld0VEtFeTdkOUFBQWVVbQ--/SIG=10t5eod6j/**http%3A//www.pizzahut.com/</clickurl>
      <date>2010/10/15</date>
      <dispurl><![CDATA[www.<b>pizzahut.com</b>]]></dispurl>
      <keyterms>
        <terms>
          <term>Pizza Hut</term>
          <term>pizza</term>
          <term>WingStreet</term>
          <term>buffalo wings</term>
          <term>pizza hut coupons</term>
          <term>Facebook</term>
          <term>Twitter</term>
          <term>Your Door</term>
          <term>Portions</term>
          <term>Patents</term>
          <term>order pizza</term>
          <term>pizza delivery</term>
          <term>pizza coupons</term>
          <term>sides</term>
          <term>Pizza Hut name</term>
          <term>PEPSI MAX</term>
          <term>Pepsi Globe</term>
          <term>hot pizza</term>
          <term>promotions</term>
          <term>logos</term></terms></keyterms>
      <size>26009</size>
      <title><![CDATA[<b>Pizza</b> Hut]]></title>
      <url>http://www.pizzahut.com/</url></result>
    <result>
      <abstract><![CDATA[Official site of Domino's <b>Pizza</b> delivery chain, which offers thin crust, deep dish, and hand tossed <b>pizzas</b> with a variety of side items and beverages. <b>...</b>]]></abstract>
      <clickurl>http://lrd.yahooapis.com/_ylc=X3oDMTU4cTY1OWZlBF9TAzIwMjMxNTI3MDIEYXBwaWQDUVg1WVZGalYzNEVrM1R1bTYxdW13UHlXa01SNXAxc09XRHJiNEFJM184RE81dmlVc3lNQzJFNm5OT1h6QWMwMwRjbGllbnQDYm9zcwRzZXJ2aWNlA0JPU1MEc2xrA3RpdGxlBHNyY3B2aWQDSFE2R05VZ2VBdTBxMjBQaWtMWFFTaGl5Uld0VEtFeTdkOUFBQWVVbQ--/SIG=10s06148e/**http%3A//www.dominos.com/</clickurl>
      <date>2010/10/16</date>
      <dispurl><![CDATA[www.<b>dominos.com</b>]]></dispurl>
      <keyterms>
        <terms>
          <term>coupon</term>
          <term>pizza</term>
          <term>Domino's Pizza</term>
          <term>dominos</term>
          <term>price</term>
          <term>At This Time</term>
          <term>carryout</term>
          <term>order pizza</term>
          <term>driver</term>
          <term>crust</term>
          <term>pizza coupons</term>
          <term>dominos pizza</term>
          <term>dominos pizza menu</term>
          <term>order online</term>
          <term>dominoes pizza</term>
          <term>store</term>
          <term>Lunch Deal</term>
          <term>Topping</term>
          <term>IP</term>
          <term>Holder</term></terms></keyterms>
      <size>23152</size>
      <title><![CDATA[Domino's <b>Pizza</b>]]></title>
      <url>http://www.dominos.com/</url></result>
      <result>
      <abstract><![CDATA[<b>Pizza</b> varieties. New York-style <b>pizza</b>. Sicilian <b>pizza</b> · Tomato pie. Greek <b>pizza</b>. Chicago <b>...</b> Detroiit-style <b>pizza</b>. Similar dishes. Grilled <b>pizza</b> · Deep-fried <b>pizza</b> <b>...</b>]]></abstract>
      <clickurl>http://lrd.yahooapis.com/_ylc=X3oDMTU4cTY1OWZlBF9TAzIwMjMxNTI3MDIEYXBwaWQDUVg1WVZGalYzNEVrM1R1bTYxdW13UHlXa01SNXAxc09XRHJiNEFJM184RE81dmlVc3lNQzJFNm5OT1h6QWMwMwRjbGllbnQDYm9zcwRzZXJ2aWNlA0JPU1MEc2xrA3RpdGxlBHNyY3B2aWQDSFE2R05VZ2VBdTBxMjBQaWtMWFFTaGl5Uld0VEtFeTdkOUFBQWVVbQ--/SIG=117l9m87a/**http%3A//en.wikipedia.org/wiki/Pizza</clickurl>
      <date>2010/10/05</date>
      <dispurl><![CDATA[<b>en.wikipedia.org</b>/wiki/<b>Pizza</b>]]></dispurl>
      <keyterms>
        <terms>
          <term>pizza</term>
          <term>toppings</term>
          <term>mozzarella</term>
          <term>crust</term>
          <term>cheese</term>
          <term>ingredients</term>
          <term>04-02</term>
          <term>dishes</term>
          <term>tomato</term>
          <term>pizzerias</term>
          <term>tomato sauce</term>
          <term>Neapolitan</term>
          <term>Italian</term>
          <term>the Italian</term>
          <term>dough</term>
          <term>basil</term>
          <term>varieties</term>
          <term>optional toppings</term>
          <term>bread</term>
          <term>mozzarella cheese</term></terms></keyterms>
      <size>122240</size>
      <title><![CDATA[<b>Pizza</b> - Wikipedia, the free encyclopedia]]></title>
      <url>http://en.wikipedia.org/wiki/Pizza</url></result>
    <result>
      <abstract><![CDATA[<b>pizza</b> n. A baked pie of Italian origin consisting of a shallow breadlike crust covered with toppings such as seasoned tomato sauce, cheese, sausage,]]></abstract>
      <clickurl>http://lrd.yahooapis.com/_ylc=X3oDMTU4cTY1OWZlBF9TAzIwMjMxNTI3MDIEYXBwaWQDUVg1WVZGalYzNEVrM1R1bTYxdW13UHlXa01SNXAxc09XRHJiNEFJM184RE81dmlVc3lNQzJFNm5OT1h6QWMwMwRjbGllbnQDYm9zcwRzZXJ2aWNlA0JPU1MEc2xrA3RpdGxlBHNyY3B2aWQDSFE2R05VZ2VBdTBxMjBQaWtMWFFTaGl5Uld0VEtFeTdkOUFBQWVVbQ--/SIG=117qhsiqu/**http%3A//www.answers.com/topic/pizza</clickurl>
      <date>2010/10/04</date>
      <dispurl><![CDATA[www.<b>answers.com</b>/topic/<b>pizza</b>]]></dispurl>
      <keyterms>
        <terms>
          <term>pizza</term>
          <term>toppings</term>
          <term>dough</term>
          <term>cheese</term>
          <term>pizzeria</term>
          <term>pie</term>
          <term>dish</term>
          <term>ingredients</term>
          <term>Neapolitan</term>
          <term>Italy</term>
          <term>tomato sauce</term>
          <term>mozzarella</term>
          <term>crust</term>
          <term>bread</term>
          <term>tomato</term>
          <term>Food</term>
          <term>flour</term>
          <term>Italian</term>
          <term>United States</term>
          <term>tomatoes</term></terms></keyterms>
      <size>251820</size>
      <title><![CDATA[<b>pizza</b>: Definition from Answers.com]]></title>
      <url>http://www.answers.com/topic/pizza</url></result>
    <result>
      <abstract><![CDATA[<b>Pizza</b>.com is the #1 <b>pizza</b> portal, giving consumers new tools to find a favorite pizzeria, order <b>pizza</b> online for pickup or delivery, and discover <b>pizza</b> coupons.]]></abstract>
      <clickurl>http://lrd.yahooapis.com/_ylc=X3oDMTU4cTY1OWZlBF9TAzIwMjMxNTI3MDIEYXBwaWQDUVg1WVZGalYzNEVrM1R1bTYxdW13UHlXa01SNXAxc09XRHJiNEFJM184RE81dmlVc3lNQzJFNm5OT1h6QWMwMwRjbGllbnQDYm9zcwRzZXJ2aWNlA0JPU1MEc2xrA3RpdGxlBHNyY3B2aWQDSFE2R05VZ2VBdTBxMjBQaWtMWFFTaGl5Uld0VEtFeTdkOUFBQWVVbQ--/SIG=10qroeair/**http%3A//www.pizza.com/</clickurl>
      <date>2010/10/05</date>
      <dispurl><![CDATA[www.<b>pizza.com</b>]]></dispurl>
      <keyterms>
        <terms>
          <term>Pizzerias</term>
          <term>Pizza</term>
          <term>Order Pizza</term>
          <term>pizza coupons</term>
          <term>pizza portal</term>
          <term>consumers</term>
          <term>new tools</term>
          <term>pickup</term>
          <term>Games</term>
          <term>Pizza News</term>
          <term>Pizza Business</term>
          <term>Search</term>
          <term>Fun Facts</term></terms></keyterms>
      <size>6383</size>
      <title><![CDATA[<b>Pizza</b>.com - Order <b>Pizza</b> Online, <b>Pizza</b> Coupons, Find Pizzerias]]></title>
      <url>http://www.pizzahut.com/Pasta.aspx</url></result></resultset_web></ysearchresponse>
