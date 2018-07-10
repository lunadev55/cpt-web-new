//= require cable
//= require_self
//= require_tree .
//= require action_cable

this.App = {};

App.cable = ActionCable.createConsumer();  





App.orders = App.cable.subscriptions.create("OrdersChannel", {
  connected: function() {
    console.log("conected into websocket")
    $('.online-offline').html(" Online")
    $('.online-offline').css('color','green')
  },

  disconnected: function() {
    $('.online-offline').html(" Offline")
    $('.online-offline').css('color','red')
    // Called when the subscription has been terminated by the server
  },

  received: function(data) {
        // página de negociações
        if ($(".current_place").prop("place") == "business"){
          var table = $(`.${data.tipo}_table_${data.pair}`);
          if ((table != undefined) && (data.status == "executada")){
            updatePriceTables(data)
          } else {
            updateTable(table,data)
          }
          table_prices = $(`.${data.pair}_executed`)
          if ((table_prices != undefined) && data.executed_list != undefined){
            updateExecTable(table_prices,data);
          }
          $(`.ticker_index_price_${data.pair}`).html(data.last_price);
          if (data.percentage_24h != undefined ){
            if (data.percentage_24h == 0){
              color = "yellow" 
            } else if(data.percentage_24h > 0){
              color = "green"
            } else if(data.percentage_24h < 0){
              color = "red"
            }
            $(`.ticker_percentage_${data.pair}`).removeClass("yellow");
            $(`.ticker_percentage_${data.pair}`).removeClass("green");
            $(`.ticker_percentage_${data.pair}`).removeClass("red");
            $(`.ticker_percentage_${data.pair}`).addClass(color);
            $(`.ticker_percentage_${data.pair}`).html(`${data.percentage_24h}%`);
          }
          
        }
        // atualizar preço atual no slide de últimas operações
        if ((data.status == "executada") && ($(".current_place").prop("place") == "overview")){
          $(`.${data.pair}_${data.tipo}`).html(data.last_price); // atualizar preço de orden executada
          
        }
        
        
        
        // atualizar preço de última ordem no formulário de compra instantânea (caso o par executado seja o mesmo do par selecionado pelos usuários)
        if (($(".current_place").prop("place") == "overview")){
          elemento = $(  ".pair-control" )
          if (elemento.find(":selected").text() == "Selecione o par"){
              return;
          } else {
              update_instant_price(data.pair);
        }}
        
        
    // Called when there's incoming data on the websocket for this channel
  }
});

function update_instant_price(pair){
  
  a = elemento.find(":selected").text().replace(/ /,'')
  b = a.replace(/ /,'')
  if (b.replace("/","_") == pair){
  $('.actual_price_form').data("pair",b)
  if ($('#type').prop("value") == "buy"){
    tipo = "buy"
  } else {
    tipo = "sell"
  }
  
  $.ajax({
  url: "instant_buy_price/" + b + '/' + tipo,
  cache: false,
  type: "GET",
  success: function(response) {
      $(".actual_price_form").val(response);
      calc(response);
  },
  error: function(xhr) {
      
  }});}
  return
};

function updateExecTable(table,data){
  var arrayLength = data.executed_list.length;
  var content = '';
  var currency1 = data.pair.split("_")[0];
  var currency2 = data.pair.split("_")[1];
  content += `<tr>`;
  content += `<th colspan="2" class="text-center">Ordens executadas (${data.pair.replace("_","/")})</th></tr><tr class="active">`;
  content += `<th class="small_lines">Preço</th><th class="small_lines">Volume</th></tr>`;
  for (var i = 0; i < arrayLength; i++) {
    content += '<tr>';
    content += `<td class="small_lines">${data.executed_list[i].price} ${currency1} </td>`;
    content += `<td class="small_lines">${data.executed_list[i].amount} ${currency2} </td>`;
    content += '</tr>';
  }
  table.html(content);
  
}
function updatePriceTables(data){
    if (data.tipo == "buy"){
      var string = "venda"
      var currency1 = data.pair.split("_")[0]
      var currency2 = data.pair.split("_")[1]
      var opposite = "sell"
    }else{
      string = "compra"
      currency1 = data.pair.split("_")[1]
      currency2 = data.pair.split("_")[0]
      opposite = "buy"
    }
    
    var table = $(`.${data.tipo}_table_${data.pair}`);
    var table_opposite = $(`.${opposite}_table_${data.pair}`);
    var table_content = mountTableContent(string,data,data.orders.length,currency1,currency2,data.tipo,data.orders);
    var table_opposite_content = mountTableContent(string,data,data.opposite_orders.length,currency1,currency2,opposite,data.opposite_orders);
    table.html(table_content);
    table_opposite.html(table_opposite_content);
}
function mountTableContent(string,data,arrayLength,currency1,currency2,type,orders){
  var content = ''
  content += `<tr class="active">`
  if (type == "buy"){
    content += '<th class="small_lines">Volume</th><th class="small_lines">Preço</th></tr>'
    for (var i = 0; i < arrayLength; i++) {
      content += '<tr>';
      content += `<td class="small_lines">${orders[i].amount} ${currency1}</td>`;
      content += `<td class="small_lines">${orders[i].price} ${currency2}</td>`;
      content += '</tr>';
    }
  } else {
    content += '<th class="small_lines">Preço</th><th class="small_lines">Volume</th></tr>'
    for (var i = 0; i < arrayLength; i++) {
      content += '<tr>';
      content += `<td class="small_lines">${orders[i].price} ${currency1}</td>`;
      content += `<td class="small_lines">${orders[i].amount} ${currency2}</td>`;
      content += '</tr>';
    }
  }
  return content
}
function calc(price){
    var a = elemento.find(":selected").text().replace(/ /,'')
    var b = a.replace(/ /,'')
    if (price == "Não disponível."){
      $('.instant_submit').prop("disabled",true)
    }else {
      $('.instant_submit').prop("disabled",false)
    }
    element = $(".amount_input")
    element.val((element.val()).replace(/^\./, ""));
    element.val((element.val()).replace(',','.'));
    element.val((element.val()).replace(/[^0-9\,.]/g,''));
    quantity = parseFloat($( ".amount_input" ).val().replace(",","."));
    price = parseFloat($(".actual_price_form").val().replace(",",".").split(" ")[0]);
    pair = b.split("/");
    currency1 = pair[0];
    currency2 = pair[1];
    
    if ($('#type').prop("value") == "buy"){
      discount = (quantity * 0.005).toFixed(8);
      receive = (quantity - discount).toFixed(8);
      total = (price * quantity).toFixed(8);
      
      $(".receber_instant").html(receive + " " + currency1);
      $(".total_instant").html(total + " " + currency2);
    }else{
      total = (price * quantity).toFixed(8);
      discount = (total * 0.005).toFixed(8);
      receive = (total - discount).toFixed(8);
      
      $(".receber_instant").html(receive + " " + currency2);
      $(".total_instant").html(total + " " + currency2);
    }

}
function updateTable(table,data){
    var arrayLength = data.orders.length;
    if (data.tipo == "buy"){
      var string = "compra"
      var currency1 = data.pair.split("_")[0]
      var currency2 = data.pair.split("_")[1]
    }else{
      string = "venda"
      currency1 = data.pair.split("_")[1]
      currency2 = data.pair.split("_")[0]
    }
    var content = ''
    content += `<tr>`
    content += `<th colspan="2" class="text-center">Ordens de ${string}</th></tr><tr class="active">`
    if (data.tipo == "buy"){
      content += '<th class="small_lines">Volume</th><th class="small_lines">Preço</th></tr>'
      for (var i = 0; i < arrayLength; i++) {
        content += '<tr>';
        content += `<td class="small_lines">${data.orders[i].amount} ${currency1}</td>`;
        content += `<td class="small_lines">${data.orders[i].price} ${currency2}</td>`;
        content += '</tr>';
      }
    } else {
      content += '<th class="small_lines">Preço</th><th class="small_lines">Volume</th></tr>'
      for (var i = 0; i < arrayLength; i++) {
        content += '<tr>';
        content += `<td class="small_lines">${data.orders[i].price} ${currency1}</td>`;
        content += `<td class="small_lines">${data.orders[i].amount} ${currency2}</td>`;
        content += '</tr>';
      }
    }
    
    table.html(content);
}