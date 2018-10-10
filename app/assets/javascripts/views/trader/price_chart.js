function generateChartData() {
    var par = $("#chartdiv").data("pair");
  $.ajax({
        url: "trader/orders_history/" + par,
        cache: false,
        type: "GET",
        data: {
            date_inicio: $("#chart_inicio").val(),
            date_fim: $("#chart_fim").val(),
        },
        success: function(response) {
          result = parseResponseData(response);
          plotChart(result)
        },
        error: function(xhr) {
          
        }});
}

$("#chart_inicio").change(function(){
    generateChartData()
})

$("#chart_fim").change(function(){
    generateChartData()
})

function parseResponseData(response){
  var chartData = [];
  parsed = (JSON.parse(response))
  var length = parsed["length"]
  var interval = new Date(parsed[0]["created_at"])
  var i = 0;
  var high = 0
  var low = 0
  var volume = 0
  var open = true
  var clone = true
  var openValue = 0
  var lote = []
  for (let e of parsed){
      if (open){
        openValue = e["price"]
        open = false
      }
      if (parseFloat(e["price"]) >= high) {
        high = e["price"]
      } 
      
      if (parseFloat(e["price"]) <= low ) {
        low = e["price"]
      } 
      
      if (low == 0){
        low = e["price"]
      }
      
      volume = volume + e["amount"]
      if (new Date(e["created_at"]) >= interval){
        
          chartData[ i ] = ( {
            "date": new Date(e["created_at"]).toISOString(),
            "open": openValue,
            "close": e["price"],
            "high": high,
            "low": low,
            "volume": volume
          } );
          i++
          open = true
          low = 0
          high = 0
          interval = new Date(e["created_at"])
          interval.setMinutes(interval.getMinutes() + 10)
          lote = []
        } else {
          lote.concat(e)
        }
        
      }
  return chartData;
}


generateChartData();
function plotChart(chartData){
    var par = $("#chartdiv").data("pair");
    var cur2 = par.split("_")[1]
  var chart = AmCharts.makeChart( "chartdiv", {
  "type": "serial",
  "theme": "white",
  "dataDateFormat":"YYYY-MM-DDTHH:mm:ss.sssZ",
  "color":"white",
  "connect":false,
  "valueAxes": [ {
    "position": "left"
  } ],
  "graphs": [ {
    "id": "g1",
    "balloonText": `Aberto:<b>[[open]] ${cur2}</b><br>Baixo:<b>[[low]] ${cur2}</b><br>Alto:<b>[[high]] ${cur2}</b><br>Fechado:<b>[[close]] ${cur2}</b><br>`,
    "closeField": "close",
    "fillColors": "#ffffff",
    "highField": "high",
    "proCandlesticks": true,
    "lineColor": "#ffffff",
    "lowField": "low",
    "fillAlphas": 1,
    "negativeFillColors": "#ffffff",
    "negativeLineColor": "#ffffff",
    "openField": "open",
    "title": "Preço:",
    "type": "candlestick",
    "valueField": "close"
  } ],
  "chartScrollbar": {
    "graph": "g1",
    "graphType": "line",
    "scrollbarHeight": 15,
    "dragIconHeight": 18
  },
  "chartCursor": {
    "valueLineEnabled": true,
    "valueLineBalloonEnabled": true
  },
  "categoryField": "date",
  "categoryAxis": {
    "parseDates": true,
    "minPeriod": "ss",
    "dashLength": 0.1,
    "minorGridEnabled": true,
    "groupToPeriods": "ss"
  },
  "dataProvider": chartData });
chart.addListener( "rendered", zoomChart );
zoomChart;

  function zoomChart() {
    startZoom = new Date(chart.endDate.getDay());
    startZoom.setDate(-1);
    // different zoom methods can be used - zoomToIndexes, zoomToDates, zoomToCategoryValues
    chart.zoomToDates( startZoom, chart.endDate );
    $("[title='JavaScript charts']").remove()
  }
}
// this method is called when chart is first inited as we listen for "dataUpdated" event
