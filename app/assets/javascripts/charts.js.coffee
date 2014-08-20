# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
`
var symbol = gon.symbol
var name = gon.name
// MAS data field order: date[, time], open, high, low, close, volume
var mas_data = gon.data
var error = gon.error
DATE = 0
MAS_OPEN = 1; MAS_HIGH = 2; MAS_LOW = 3; MAS_CLOSE = 4; MAS_VOLUME = 5
GOOG_LOW = 1; GOOG_OPEN = 2; GOOG_CLOSE = 3; GOOG_HIGH = 4; GOOG_TIP = 5
google.load("visualization", "1", {packages:["corechart"]});
google.setOnLoadCallback(drawChart);
function drawChart() {
  var tradable_data = google.visualization.arrayToDataTable(
    google_data(mas_data), true)

/*
 tradable_data = google.visualization.arrayToDataTable([
//      mas_data[0][0], parseFloat(mas_data[0][3]), parseFloat(mas_data[0][1]),
//        parseFloat(mas_data[0][4]), parseFloat(mas_data[0][2])
      [mas_data[0][0], parseFloat(mas_data[0][MAS_LOW]),
      parseFloat(mas_data[0][1]),
      parseFloat(mas_data[0][MAS_CLOSE]), parseFloat(mas_data[0][MAS_HIGH])],
//      ['Mon', 30.5, 35.25, 43.75, 78.0000000000000000001],
      ['Tue', 31, 38, 55, 66],
      ['Wed', 50, 55, 77, 80],
      ['Thu', 77, 77, 66, 50],
      ['Fri', 68, 66, 22, 15]
      // Treat first row as data as well.
    ], true);
*/
  var options = {
    legend: 'none',
    candlestick: {
      fallingColor: { fill: 'red', stroke: 'red' },
      risingColor: { fill: 'green', stroke: 'green' },
    }
  }
//  var options = {
//title: name + ' Performance',
//       hAxis: {title: 'Year', titleTextStyle: {color: 'red'}}
//  };

  var chart = new google.visualization.CandlestickChart(
    document.getElementById('chart_div'));
  chart.draw(tradable_data, options);
}

// data in the formats/order expected by google charts i.e., convert:
// date[, time], open, high, low, close, volume
//   to:
// date,         low, open, close, high
function google_data(data) {
  var result = new Array(data.length)
  for (var i = 0; i < data.length; ++i) {
//var goog_last = 5
    var goog_last = 4
    var row = new Array(goog_last + 1)
    // NOTE: Need to deal with the time field when intraday data is
    // implemented.
    row[DATE] = data[i][DATE]
    row[GOOG_LOW] = parseFloat(data[i][MAS_LOW])
    row[GOOG_OPEN] = parseFloat(data[i][MAS_OPEN])
    row[GOOG_CLOSE] = parseFloat(data[i][MAS_CLOSE])
    row[GOOG_HIGH] = parseFloat(data[i][MAS_HIGH])
    // (Put volume in tool-tip slot.)
//    row[GOOG_TIP] = data[i][MAS_VOLUME]
    result[i] = row
  }
//console.log("size of result: " + result.length)
  return result
}
`
