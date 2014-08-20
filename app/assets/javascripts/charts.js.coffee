# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
`
var symbol = gon.symbol
var name = gon.name
var mas_data = gon.data
var error = gon.error
DATE = 0
// MAS data field order:    date[, time], open, high, low  , close, volume
// Google data field order: date[time]  , low , open, close, high
MAS_OPEN = 1; MAS_HIGH  = 2; MAS_LOW    = 3; MAS_CLOSE = 4; MAS_VOLUME = 5
GOOG_LOW = 1; GOOG_OPEN = 2; GOOG_CLOSE = 3; GOOG_HIGH = 4; GOOG_TIP   = 5
google.load("visualization", "1", {packages:["corechart"]});
google.setOnLoadCallback(drawChart);
function drawChart() {
  var tradable_data = google.visualization.arrayToDataTable(
    google_data(mas_data), true)

  var options = {
    legend: 'none',
    candlestick: {
      fallingColor: { fill: 'red', stroke: 'red' },
      risingColor: { fill: 'green', stroke: 'green' },
    }
  }

  var chart = new google.visualization.CandlestickChart(
    document.getElementById('chart_div'));
  chart.draw(tradable_data, options);
}

// data in the formats/order expected by google charts i.e., convert:
function google_data(data) {
  var result = new Array(data.length)
  for (var i = 0; i < data.length; ++i) {
    var goog_last = 4
    var row = new Array(goog_last + 1)
    // NOTE: Need to deal with the time field when intraday data is
    // implemented.
    row[DATE] = data[i][DATE]
    row[GOOG_LOW] = parseFloat(data[i][MAS_LOW])
    row[GOOG_OPEN] = parseFloat(data[i][MAS_OPEN])
    row[GOOG_CLOSE] = parseFloat(data[i][MAS_CLOSE])
    row[GOOG_HIGH] = parseFloat(data[i][MAS_HIGH])
    result[i] = row
  }
//console.log("size of result: " + result.length)
  return result
}
`
