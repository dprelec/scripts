// ==UserScript==
// @name           AbeBooks Croatia Shipping Rates
// @namespace      www.google.com
// @description    Show shipping rates for Croatia
// @include        http://www.abebooks.com/servlet/SearchResults*
// @require        http://ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js
// @author         darko.prelec@gmail.com
// ==/UserScript==

/* dprelec, 2011-2015 */

/* CHANGELOG:

 2015-08-09: fixed finding price parent in main()

 */

function LoadShippingRates ($, country) {

  function ship_rates_url (id) {
    return 'http://www.abebooks.com/servlet/ShipRates?vid=' + id + '&cntry=' + country.code;
  }

  function extract_price (price) {
    price = price.replace('US', '');
    price = price.replace(/\$/, '');
    price = parseFloat(price, 10);
    return price;
  }

  function format_price (price) {
    price = '' + (price * 100);
    var h = 0, t = 0;
    if (price.match(/(\d+)(\d\d)/)) {
      h = RegExp.$1;
      t = RegExp.$2;
    }
    return h+'.'+t;
  }

  function total_price (price, shipment) {
    return format_price(extract_price(price) + extract_price(shipment));
  }

  function extract_ship_rate (res) {
    var table = $(res).find('table.data');
    var price_tr = $(table).find('tr:eq(1)');
    var price_td = $(price_tr).find('td:eq(1)');
    var price_txt = $(price_td).html();
    return price_txt;
  }

  function main () {
    $('div.result-pricing p.m-sm-t a.small').each(
      function () {
        var parent = $(this).parent('p.m-sm-t').parent('div.result-pricing');
        var href = $(this).attr('href');
        var price = $(parent).find('div.item-price span.price').html();     
        if (href.match(/ShipRates.*vid=(\d+)/)) {
          var id = RegExp.$1;
          var url = ship_rates_url(id);
          var append_price = function (res) {
            var rate = extract_ship_rate(res);
            var total = total_price(price, rate);
            var conv = format_price(total * country.currency);
            var elem = $('<div/>')
            .attr('id', 'price_'+id)
            .css('padding-top', '5px')
            .html(
              '<b>'+country.name+' rate:</b> <span class=price>' + rate + '</span>'  
              +'<br><b>Total:</b> <span class=price>US$ ' + total + ' (' + conv + 'KN)' + '</span>'
            );
            $(parent).append(elem);
          };
          $.get(url).done(append_price);
        }
      }
    );
  }

  main();

}

// user-configurable parts
var country = {
  code : 'HRV',
  name : 'Croatia',
  currency: '6.68'
};

LoadShippingRates(jQuery, country);

