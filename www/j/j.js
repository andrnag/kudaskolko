var transactionValueComplete = '';

$(function() {

		function makeTextareaData(val){
			var result = new Object;
			var oldCaretPos = $( "#transactions" ).prop("selectionStart");
			var oldValue = $( "#transactions" ).val();
			var startLinePos = oldValue.lastIndexOf("\n", oldCaretPos - 1);
			var beforeCurrentLinePos =  startLinePos == -1 ? 0 : startLinePos + 1;
			result.before = oldValue.substring(0, beforeCurrentLinePos)
			result.after = oldValue.substring(oldCaretPos, oldValue.length);
			result.newCaretPos = beforeCurrentLinePos + val.length
			result.val = val;
			return result;
		}

		function setCursorAt(position){
			document.getElementById("transactions").setSelectionRange(position, position);
		}

		function markAsNotListed(id){
			$.ajax({
					type: "GET",
					url: "/?action=hidefromlist&ajax=1",
					datatype: "html",
					cache: false,
					data: {iid: id}
				}).done(function( html ) {
					
					// $("#IDAjaxPreview .dataContainer").html(html);
					// $("#IDAjaxPreview").removeClass("hidden");
					// controlsPreview.attr("disabled",true);
					// hasAjaxPreviewFormatError = $("#IDAjaxPreview .dataContainer .grid").hasClass("hasError");
					// if(hasAjaxPreviewFormatError){
					// 	controlsSubmit.attr("disabled",true);
					// 	$("#IDAjaxPreview").effect("shake", { times:2, distance:10 }, 100);
					// }
				}).fail(function(jqXHR, textStatus) {
				});
		}

		function split( val ) {
			return val.trim().split( /\n/ );
		}
		function extractLast( term ) {
			return split( term ).pop();
		}
		function extractCurrent( val ) {
			var caretPos = $( "#transactions" ).prop("selectionStart");
			var startLinePos = val.lastIndexOf("\n", caretPos-1);
			return val.substring((startLinePos == -1 ? 0 : startLinePos + 1), caretPos);
		}
		var cache = {},
			lastXhr;
		$( "#transactions" )
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
				if ( event.keyCode === $.ui.keyCode.TAB &&
						$( this ).data( "autocomplete" ).menu.active ) {
					event.preventDefault();
				}
			})
			.autocomplete({
				delay: 300,
				minLength: 1,
				autoFocus: false,
				position: { my : "left top", at: "left bottom" },
				// source: function( request, response ) {
				// 	// delegate back to autocomplete, but extract the last term
				// 	response( $.ui.autocomplete.filter(
				// 		availableTags, extractLast( request.term ) ) );
				// },

				source: function( request, response ) {
					var term = extractCurrent( $( "#transactions" ).val() );
					if ( term in cache ) {
						response( cache[ term ] );
						return;
					}
					$.getJSON( "/?action=json",
						{ term: term},
						function( data, status, xhr ) {
							cache[ term ] = data;
							response( data );
						});
				},

				// source: function( request, response ) {
				// 	$.getJSON( "/?action=json", {
				// 		term: extractLast( request.term )
				// 	}, response );

				// },
				focus: function() {
					// prevent value inserted on focus
					return false;
				},
				change: function( event, ui) {
					// preve event, uint value inserted on focus
					return false;
				},
				close: function( event, ui) {
					// if(ui.item.label != ''){
						// $( this ).autocomplete( "close");
						// $(this).autocomplete( "search", "Шоколад" );
					// }
					return false;
				},

				select: function( event, ui ) {
					// if(ui.item.label != ''){
					// 	return false;
					// }
					var result = makeTextareaData(ui.item.value + " " + (ui.item.with_price == 1 ? "\n" : ""));
					this.value = result.before + result.val + result.after;
					setCursorAt(result.newCaretPos);
					if (ui.item.label && ui.item.label != 'undefined' && ui.item.value != ui.item.label) {
						ajaxPreview();
					} else if (ui.item.with_price && ui.item.with_price == 1) {
						ajaxPreview();
					}
					return false;
				}
		})
		if($( "#transactions" ) && $( "#transactions" ).data( "ui-autocomplete" )) {
			$( "#transactions" ).data( "ui-autocomplete" )._renderItem = function( ul, item ) {
				var t = extractCurrent( $( "#transactions" ).val() );
				var splitted = t.split( /\s+/ );
				var result = "";
				for (var i = splitted.length - 1; i >= 0; i--) {
						result += "|";
					result += $.ui.autocomplete.escapeRegex(splitted[i]);
				};

				var matcher = new RegExp("(\\s+|^|@|\\$|\\(|\\-)(" + $.ui.autocomplete.escapeRegex(t) + result+")", "ig" );
						
				if(item.iid && item.iid != 'undefined'){
					var $anchor = $( "<div ><u>Все записи</u></div>" )
						.addClass("search-link")
						// .attr("href", '/?iid=' + item.iid )
						.hover(function(e){
							$(this).parent().addClass("hover-search");
						},function(e){
							$(this).parent().removeClass("hover-search");
						}).click(function(e){
							var result = makeTextareaData("");
							if(!result.before && !result.after){
								$("#transactions").val('');
								$.cookie("draft", null);
							}
							window.location.href = '/?p=' + item.iid;
								return false;
					 });
					var $anchor2 = $( "<div ><u>1</u></div>" )
						.attr("href", '/?iid=' + item.iid )
						.hover(function(e){
						})
						.click(function(e){
						return false;
					 });

				 	var resultValue = item.value;
					if (item.label && item.label != 'undefined') {
						resultValue = item.label;
					} 
					resultValue = resultValue.replace(matcher, "$1<i>$2</i>");
					return $( "<li>" )
					.append( $( "<a>" )
						.append($anchor)
						.append("<div class='value'>" + resultValue + "</div>")
						// .append($anchor2)
						 )
					.appendTo( ul );
				} else {
				 	var resultValue = item.value;
					if (item.label && item.label != 'undefined') {
						resultValue = item.label;
					} 
					resultValue = resultValue.replace(matcher, "$1<i>$2</i>");

					return $( "<li>" )
					.append( "<a><div class='value'>" + resultValue + "</div></a>" )
					.appendTo( ul );
				}

    		};
    	}
	});


$(function() {

		function split( val ) {
			return val.split( /,\s*/ );
		}
		function extractLast( term ) {
			return split( term ).pop();
		}
		var cache = {},
			lastXhr;
		$( "#IDNewCategory" )
			// don't navigate away from the field on tab when selecting an item
			.bind( "keydown", function( event ) {
				if ( event.keyCode === $.ui.keyCode.TAB &&
						$( this ).data( "autocomplete" ).menu.active ) {
					event.preventDefault();
				}
			})
			.autocomplete({
				delay: 300,
				minLength: 2,
				autoFocus: false,
				position: { my : "left top", at: "left bottom" },

				source: function( request, response ) {
					$.getJSON( "/?action=json&move=true", {
						term: extractLast( request.term )
					}, response );

				},
				focus: function() {
					// prevent value inserted on focus
					return false;
				},
				change: function( event, ui) {
					// preve event, uint value inserted on focus
					return false;
				},

				select: function( event, ui ) {
					var terms = split( this.value );
					// remove the current input
					terms.pop();
					// add the selected item
					// terms.push( ui.item.value + ", ");
					terms.push( ui.item.value);
					// add placeholder to get the comma-and-space at the end
					// terms.push( "" );
					this.value = terms.join( ", " );
					enableDisableControlAll($('#IDNewCategory'),$("#actionMove input[type='submit']"),'');
					enableDisableControlAll($('#IDNewCategory'),$("#actionMove input[type='submit']"), $('#IDNewCategoryName').attr('oldValue'));

					return false;
				}
			});

			if($( "#IDNewCategory" ) && $( "#IDNewCategory" ).data( "ui-autocomplete" )) {
				$( "#IDNewCategory" ).data( "ui-autocomplete" )._renderItem = function( ul, item ) {
					return $( "<li>" )
						.append( $( "<a>" ).text( item.value ) )
						.appendTo( ul );
				}
			}
	});

function setRowsHeight(textarea, rows){
	// textarea.animate({
	// 	height: (rows * 1.2 + 1.2) + 'em'
	// }, 800 );
	// textarea.attr("rows",rows);
	// var height = (rows * 1.2 + 1.2) + 'em'
	textarea.css('height', (rows * 1.2 + 1.3) + 'em');
}


function setRows(textarea, isEmpty, isFocus){
	if(textarea.length <= 0)
		return;
	if(isEmpty && !isFocus){
		setRowsHeight(textarea, 1);
	} else {
		var newLineCount = textarea.val().split("\n").length;
		if(newLineCount <= 4) {
			setRowsHeight(textarea, 5);
		}
		else if(newLineCount > 4 && newLineCount <= 9) {
			setRowsHeight(textarea, 10);
		}
		else if(newLineCount > 9) {
			setRowsHeight(textarea, 15);
			textarea.css('overflow','auto');
		}
	}

}

function showHideControls(textarea){
	showHideControlsAll(textarea, (textarea.val() == '' && !textarea.val().trim()), textarea.is(":focus"));
}

function showHideControlsAll(textarea, isEmpty, isFocus){
	// var isEmpty = textarea.val() == '';
	// var isFocus = textarea.is(":focus");

	if(isEmpty){
		$("#controls input").attr("disabled",true);
		if(!isFocus){
			taContainerID.addClass("inactive")
			.removeClass("active");
		} else {
			taContainerID.addClass("active")
			.removeClass("inactive");
		}
	} else {
		taContainerID.addClass("active")
		.removeClass("inactive");
		// $("#controls input").attr("disabled",false);
		// $("#controls .submit").attr("disabled",false);
	}
	setRows(textarea, isEmpty, isFocus);

}



var doubleHover = function(selector, hoverClass) {
	$(document).on('mouseover mouseout', selector, function(e) {
		$(selector).filter('[href="' + $(this).attr('href') + '"]')
		.toggleClass(hoverClass, e.type == 'mouseover');
	});
}


function isEmptyNotChanged(input) {
	var inputVal = input.val();
	var isEmpty = inputVal == '';
	var isNotModified = inputVal == input.attr('oldValue');
	if(isEmpty || isNotModified)
		return true;
	else
		return false;
}

function enableDisableControl2(control,isDisabled) {
	control.attr("disabled",isDisabled);
}

function enableDisableControl(input,control,originValue) {
	var inputVal = ((input.val() && input.val() != 'undefined') ? input.val().trim() : '');
	var originVal = ((originVal && originVal != 'undefined') ? originVal.trim() : '');
	var isEmpty = inputVal == '';
	var isNotModified = inputVal == originVal;
	if(isEmpty || isNotModified)
		control.attr("disabled",true);
	else
		control.attr("disabled",false);
}

function enableDisableControlAll(input,control,originValue) {
	enableDisableControl(input,control,originValue);
	input.keyup(function(){
		enableDisableControl(input,control,originValue);
	});
	input.change(function(){
		enableDisableControl(input,control,originValue);
	});
}

var transactionsValue = '';
var hasAjaxPreviewHTTPError = false;
var hasAjaxPreviewFormatError = false;
var previewTimer;
var saveDraftTimer;

function ajaxPreview(text){
	clearTimeout(previewTimer);
	var value;
	if (text == null)
		value = transactionsID.val().trim();
	else
		value = text.trim();
	if(value == '') {
		transactionsValue = '';
		$("#IDAjaxPreview").addClass("hidden");
		$("#IDAjaxPreview .dataContainer").html("");
		return;
	}
	var re = new RegExp(".?\\.$", "ig" );
	var isSingleLine = (value.split("\n").length == 1) 
	&& re.test($.ui.autocomplete.escapeRegex(value))
	;
	if (value == transactionsValue && !hasAjaxPreviewHTTPError){
		controlsPreview.attr("disabled",true);
		if(hasAjaxPreviewFormatError)
			controlsSubmit.attr("disabled",true);
		return;
	}
	transactionsValue = value;
	$.cookie("draft", value, { expires : 90 });
	var ajaxUrl = "/?action=out&preview=1&ajax=1&anonymous=1";
	if (isSingleLine) {
		ajaxUrl = "/?action=searchtransactions"
	}
	$.ajax({
		type: "POST",
		url: ajaxUrl,
		datatype: "html",
		cache: true,
		data: {transactions: value}
		// ,beforeSend: function(){
		// 	$("#IDAjaxPreview").removeClass("hidden");
		// 	$("#IDAjaxPreview .dataContainer").html("..."); 
		// }
	}).done(function( html ) {
		if (isSingleLine) {
			controlsSubmit.attr("disabled",true);
			$.cookie("draft", null);
		}
		hasAjaxPreviewHTTPError = false;
		$("#IDAjaxPreview .dataContainer").html(html);
		$("#IDAjaxPreview").removeClass("hidden");
		controlsPreview.attr("disabled",true);
		hasAjaxPreviewFormatError = $("#IDAjaxPreview .dataContainer .grid").hasClass("hasError");
		
		controlsSubmit.attr("disabled", hasAjaxPreviewFormatError);
		if (hasAjaxPreviewFormatError){
			$("#IDAjaxPreview").effect("shake", { times:2, distance:10 }, 100);
		}
	}).fail(function(jqXHR, textStatus) {
		hasAjaxPreviewHTTPError = true;
		$("#IDAjaxPreview .dataContainer").html("Ошибка подключения к серверу, попробуйте повторить ("+textStatus+")");
		$("#IDAjaxPreview").removeClass("hidden");
		controlsPreview.attr("disabled",false);
	});

}

var transactionsID;
var taContainerID;
var controlsSubmit;
var controlsPreview;


$(document).ready(function(){

	transactionsID = $("#transactions");
	taContainerID = $("#ta-container");
	controlsPreview = $("#controls .preview");
	controlsSubmit = $("#controls .submit");
	accounts = $("#accounts");

$(function() {
	$( "#IDTransactionDate" ).datepicker({
		showOtherMonths: true,
		selectOtherMonths: true,
		showButtonPanel: true,
		autoSize: true,
		firstDay: 1,
		currentText: "Сегодня",
		closeText: "Закрыть",
		dateFormat: "d M yy",
		nextText: "Следующий",
		prevText: "Предыдущий",
		minDate: new Date(1971, 1 - 1, 1),
		maxDate: new Date(2037, 12 - 1, 31),
		dayNamesMin: ["вс", "пн", "вт", "ср", "чт", "пт", "сб"],
		monthNames: [ "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль","Август", 
		"Сентябрь", "Октябрь", "Ноябрь", "Декабрь" ],
		monthNamesShort: [ "января", "февраля", "марта", "апреля", "мая", "июня", "июля","августа", 
		"сентября", "октября", "ноября", "декабря" ]
	});
	$( "#IDTransactionDate" ).datepicker( "setDate", $( "#IDTransactionDate" ).attr("date") );
});

	doubleHover('.grid .value a, .grid .actions a','hover');

	if(taContainerID.hasClass('activated')){
		transactionsID.focus();
	}
	// },100);
	showHideControls(transactionsID);

	/* Делаем по таймауту, потому что Опера при нажатии кнопки "Назад"
		может не успеть считать значение из поля,
		в результате при непустом поле не будут показаны контролы&transactions=Vodka%20133
	 */
	setTimeout(function(){
		showHideControls(transactionsID);
	},100);

	/* скрытие пустой формы, если кликают в другие места*/
	$(document).click(function(e){

		if(!$(e.target).is('#ta-container .form *')
			/* только если форма активна */
			&& taContainerID.hasClass('active')
			/* только если подсказка свернута */
			&& !$('#howto2').hasClass('expanded')) {

			if(transactionsID.val() == $("#operday").val() + '\n'){
				transactionsID.val('');
			}

			// setTimeout(function(){
			showHideControls(transactionsID);
			// }, 100);
		}
	});

// 	$("#ta-container *").click(function(e){
//		e.stopPropagation();
// 	});


	transactionsID.focus(function(){

		// без нулевого таймаута или без явного указания, Хром не понимает, что поле получило фокус
		setTimeout(function(){ 
			showHideControls(transactionsID);
		}, 0);

		// showHideControlsAll(transactionsID, transactionsID.val() == '', true);

		// без нулевого таймаута или без явного указания, Хром выставляет курсор в место, 
		// куда ткнул пользователь (а посколько поле пустое и показывается в виде одной строки,
		// то фокус курсор попадает в первую строку с названием месяца)
		setTimeout(function(){
			if(transactionsID.val() == '' && $("#operday").length > 0){
				transactionsID.val($("#operday").val() + '\n');
			}
		}, 50);
	});

	controlsSubmit.mouseover(function(event){
		ajaxPreview();
	});

	controlsPreview.click(function(event){
		event.preventDefault();
		ajaxPreview();
	});

	transactionsID.keyup(function(event){
		var isEmpty = !$(this).val().trim();// == '';
		controlsSubmit.val("Записать расходы и доходы");

		if(isEmpty) {
			ajaxPreview();
		}
		setRows(transactionsID,isEmpty,true);
		var keyCode = (event.which ? event.which : event.keyCode);  
		if (keyCode == 13 &&
			!isEmpty &&
			// $(this).val().trim() != "" &&
			// $(this).val().substr(-1) == "\n"
			$(this).val().substr(-1) != " "
			){
			// alert('"'+$(this).val().trim()+'"');
			// alert('"'+($(this).val().substr(-1)=="\n"?"Y":"N")+'"');
			// && $(this).val().trim() != "" && $(this).val().substr(-1) === 13
			ajaxPreview();
		}

	});


	transactionsID.keydown(function(event){
		var keyCode = (event.which ? event.which : event.keyCode);
		if (event.ctrlKey) {
			controlsSubmit.val("Ctrl + Enter");
			ajaxPreview();
		}
		if ((keyCode === 10 || keyCode == 13 && event.ctrlKey) && !controlsSubmit.attr("disabled")
		  ) {
			$("#formTransactions").submit();
		}
	});



	transactionsID.bind("input", function(){
		clearTimeout(previewTimer);
		clearTimeout(saveDraftTimer);
		if($(this).val().trim()){
			controlsPreview.attr("disabled",false);
			controlsSubmit.attr("disabled",false);
			saveDraftTimer = setTimeout(function() {
				$.cookie("draft", transactionsID.val().trim(), { expires : 90 });
			}, 200); 
			previewTimer = setTimeout(function() {
				ajaxPreview();
			}, 2000);

		} else {
			$.cookie("draft", null);
			controlsPreview.attr("disabled",true);
			controlsSubmit.attr("disabled",true);
		}
	});

	transactionsID.bind('paste', function(e) {
		setTimeout(function() {
			ajaxPreview();
		}, 10);
	});

	// if($("#IDNewCategory").val()=='')
	// 	$("#actionMove input[type='submit']").attr("disabled","disabled");

	// $("#IDNewCategory").keyup(function(){
	// 	var isEmpty = $(this).val() != '';
	// 	if(isEmpty)
	// 		$("#actionMove input[type='submit']").removeAttr("disabled");
	// 	else
	// 		$("#actionMove input[type='submit']").attr("disabled","disabled");
	// });

	enableDisableControlAll($('#IDNewCategory'),$("#actionMove input[type='submit']"),'');
	enableDisableControlAll($('#IDNewCategory'),$("#actionMove input[type='submit']"), $('#IDNewCategoryName').attr('oldValue'));

	enableDisableControlAll($('#IDNewCategoryName'),
		$("#actionRename input[type='submit']"),
		$('#IDNewCategoryName').attr('oldValue'));

	enableDisableControlAll($('#IDNewCategoryName'),
		$("#actionRename input[type='submit']"),
		$('#IDNewCategoryName').attr('oldValue'));


// enableDisableControl2($('#actionEditTransactionDetails input[type="submit"]'),
// 	isEmptyNotChanged($("#actionEditTransactionDetails input[name='transactionDate']")) &&
// isEmptyNotChanged($("#actionEditTransactionDetails input[name='quantity']")) &&
// isEmptyNotChanged($("#actionEditTransactionDetails input[name='amount']"))
// 	)

// 	$("#actionEditTransactionDetails input[name='transactionDate']").keyup(function(){
// 		enableDisableControl2($('#actionEditTransactionDetails input[type="submit"]'),
// 			isEmptyNotChanged($("#actionEditTransactionDetails input[name='transactionDate']")) &&
// 		isEmptyNotChanged($("#actionEditTransactionDetails input[name='quantity']")) &&
// 		isEmptyNotChanged($("#actionEditTransactionDetails input[name='amount']"))
// 			)
// 	});
// 	$("#actionEditTransactionDetails input[name='quantity']").keyup(function(){
// 		enableDisableControl2($('#actionEditTransactionDetails input[type="submit"]'),
// 			isEmptyNotChanged($("#actionEditTransactionDetails input[name='transactionDate']")) &&
// 		isEmptyNotChanged($("#actionEditTransactionDetails input[name='quantity']")) &&
// 		isEmptyNotChanged($("#actionEditTransactionDetails input[name='amount']"))
// 			)
// 	});
// 	$("#actionEditTransactionDetails input[name='amount']").keyup(function(){
// 		enableDisableControl2($('#actionEditTransactionDetails input[type="submit"]'),
// 			isEmptyNotChanged($("#actionEditTransactionDetails input[name='transactionDate']")) &&
// 		isEmptyNotChanged($("#actionEditTransactionDetails input[name='quantity']")) &&
// 		isEmptyNotChanged($("#actionEditTransactionDetails input[name='amount']"))
// 			)
// 	});

	// $('#datepicker').datepicker();

	$("#formTransactions").submit(function(){
		setTimeout(function(){
			$("input.submit").attr("disabled",true);
		}, 0);
		setTimeout(function(){
			$("input.submit").attr("disabled",false);
		}, 1000);

	});

	$(".months.pm .bar-container").click(function(e){
		if($(".months.pm").find(".bar.plus").length == 0 && $(".months.pm").find(".bar.minus").length == 0)
			return;

		if( ($(".months").hasClass("p") && $(".months").hasClass("m")) ||
			(!$(".months").hasClass("p") && !$(".months").hasClass("m"))){
			$(".months").removeClass("p");
			$(".months").addClass("m");
			$.cookie("barstate", "m", { expires : 90 });
		} else{
			if($(".months").hasClass("m")){
				$(".months").removeClass("m");
				$(".months").addClass("p");
				$.cookie("barstate", "p", { expires : 90 });
			} else{
				$(".months").addClass("m");
				$.cookie("barstate", "m p", { expires : 90 });
			}
		}
	});


	// $('.main, .reserve, .total').click(function() {                             
	// 	this.className = {
	// 		main : 'reserve', reserve: 'total', total: 'main'
	// 	}[this.className];
	// });

	accounts.click(function(e){

		var main = "main";
		var reserve = "reserve";
		var total = "total";

		if(accounts.hasClass(main)){
			accounts.removeClass(main).addClass(reserve);
		} else {
			if(accounts.hasClass(reserve)){
				accounts.removeClass(reserve).addClass(total);
			} else {
				accounts.removeClass(total).addClass(main);
			}	
		}
		
	});
	

	$("#IDCreateAliasSpan").click(function(e){
		if($("#IDCreateAlias").val() == 1){
			$("#IDCreateAlias").val(0);
			$("#IDCreateAlias").attr("checked",false);
			$("#IDCreateAliasSpan").text("только эту запись");
		} else {
			$("#IDCreateAlias").val(1);
			$("#IDCreateAlias").attr("checked",true);
			$("#IDCreateAliasSpan").text("все записи с таким именем");
		}
	});

	 $("#IDDeleteConfirm").click(function(e){
	 	$("#actionDeleteTransaction").toggleClass("confirm");
		if($("#actionDeleteTransaction").hasClass("confirm")){
			$("#IDDeleteConfirm").text("Нет, мы передумали");
		} else {
			$("#IDDeleteConfirm").text("Удалить запись...");
		}
	});

	$("#howto2 span, #howto2 span i").click(function(event){
		event.preventDefault();

		$("#howto2").toggleClass("expanded");
		if($("#howto2").hasClass("expanded")){
			// $("#howto2 span").text("Скрыть описание");
			$("#howto2 pre").show();
		} else {
			// $("#howto2 span").text("?");
			$("#howto2 pre").hide();
		}

	});
var transactionBeforeExample = '';
var isExamplesUsed = false;
 $("#examples ul li").click(function(event){
 	if(!isExamplesUsed && $("#transactions").val() != ''){
 		transactionBeforeExample = $("#transactions").val();
 		isExamplesUsed = true;
 		// $("#howto2").append("<span>Вернуть содержимое</span>");
 		// $("#howto2 span")
 		// .click(function(event){
 		// 	$("#transactions").val(transactionBeforeExample);
 		// 	ajaxPreview();
 		// 	isExamplesUsed = false;
 		// 	$(this).remove();
 		// });
 	}
		event.preventDefault();
		$("#transactions").val($("#transactions").val() + "\n# пример\n"+
			$(this).children("div").text());
		$("#transactions").focus();

		ajaxPreview();
		// ajaxPreview($(this).children("div").text());
		 $("#examples ul li").removeClass("active");
		$(this).addClass("active");
	});

$('ul.tabs').each(function(){
    // For each set of tabs, we want to keep track of
    // which tab is active and it's associated content
    var $active, $content, $links = $(this).find('a');

    // If the location.hash matches one of the links, use that as the active tab.
    // If no match is found, use the first link as the initial active tab.
    $active = $($links.filter('[href="'+location.hash+'"]')[0] || $links[0]);
    $active.addClass('active');
    $content = $($active.attr('href'));

    // Hide the remaining content
    $links.not($active).each(function () {
        $($(this).attr('href')).hide();
    });

    // Bind the click event handler
    $(this).on('click', 'a', function(e){
        // Make the old tab inactive.
        $active.removeClass('active');
        $content.hide();

        // Update the variables with the new link and content
        $active = $(this);
        $content = $($(this).attr('href'));

        // Make the tab active.
        $active.addClass('active');
        $content.show();

        // Prevent the anchor's default click action
        e.preventDefault();
    });
});

//  $("#browser a").click(function(event){
// 		event.preventDefault();
// //	$("#searchURLProject").text($("#idJPRJTS").val());
// 	$("#searchURLProject").css("display","block");
// 	$("#searchURLProject input").select();
// 	$(this).css("display","none");
// 	});
//  $("#browser input").click(function(event){

// 	$(this).select();
// 	});

//  $("a.trigger").click(function(event){
// 		event.preventDefault();
// 		$("#hideExamples").toggleClass('hidden');
// 		$("#showExamples").toggleClass('hidden');
// 		$(".listofexamples").toggleClass('hidden');
// 		if($("#hideExamples").hasClass('hidden'))
// 	{
// 			$.cookie("jhideexamples", 1, { expires : 90 });
// 			// $("#idJQRY").val("");
// 			// var jprj = $.cookie('jproject');
// 			// if(jprj && jprj!="" && jprj!="null")
// 			// 	$("#idJPRJTS").val(jprj);
// 			// else
// 			// 	$("#idJPRJTS").val("SR");
// 	}
// 		else{
// 			$.cookie("jhideexamples", null);
// }
// 	});




});