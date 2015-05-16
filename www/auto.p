
@auto[]
^use[/../classes/utils.p]
$hRusageStat[^hash::create[]]
$MAIN:CLASS_PATH[sql]
$dtNow[^date::now[]]
$hPage[^hash::create[]]
$oSql[]
$oAuth[]
$USERID[]
$oCalendar[]
$oTransactions[]
$oAction[]
$MONEY[
	$.SERVER_HOST[http://$env:SERVER_NAME]
]
$isOperaMiniBrowser(^u:contains[$env:HTTP_USER_AGENT;Opera Mini] || 
	^u:contains[$env:HTTP_USER_AGENT;NokiaC3-0])
$isIEMobileBrowser(^u:contains[$env:HTTP_USER_AGENT;IEMobile])

@initAuthDBObjects[]
^rusage[initAuthDBObjects]
^use[/../classes/sql/MySqlComp.p]
^use[/../classes/auth2.p]
$oSql[^MySqlComp::create[$SQL.connect-string;
	$.bDebug($IS_LOCAL && 1)
	$.sCacheDir[/../data/sql_cache]
	^rem{ *** описание всех опций вы можете посмотреть в Sql.p перед конструктором create *** }
]]
$oAuth[^auth2::init[$cookie:CLASS;$form:fields;
$.csql[$oSql]
	$.is_groups_disabled(1)
	$.is_delay_groups(1)
]]
^if(def $form:[auth.logout] || (def $form:[auth.logon] && $oAuth.is_logon) 

	|| (def $form:action && $form:action eq signup && $oAuth.is_logon)){
	^rem{ *** при logon/logout делаем external redirect на себя *** }
	$response:location[http://${env:SERVER_NAME}^request:uri.match[\?.*][]{}?rand^math:random(100)]
}
$USERID($oAuth.user.id)
$dbo:oSql[$oSql]
$dbo:USERID($USERID)
$dbo:IS_LOCAL($IS_LOCAL)
^rusage[initAuthDBObjects]

@initObjects[]
^rusage[initObjects]
^use[/../classes/dbo.p]
^use[/../classes/common/dtf.p]
^use[/../classes/calendar.p]
^use[/../classes/action.p]
^use[/../classes/transaction/transaction.p]
^use[/../classes/transaction/transactionlist.p]
^use[/../classes/common/array.p]

$oCalendar[^calendar::create[$.USERID($USERID)]]
$oTransactions[^transactionlist::create[$.hPage[$hPage]$.USERID($USERID)]]
$oAction[^action::create[$.hPage[$hPage]$.USERID($USERID)]]

$calendar:oSql[$oSql]
$action:oSql[$oSql]
$transactionlist:oSql[$oSql]
$transactionlist:oCalendar[$oCalendar]
$transaction:oCalendar[$oCalendar]
^rusage[initObjects]

@postprocess[sBody][oSqlLog]
$result[$sBody]
^if($IS_LOCAL){
	^if($oSql is "Sql"){
		^use[../classes/sql/SqlLog.p]
		$oSqlLog[^SqlLog::create[$oSql]]
		^oSqlLog.log[
			$.iQueryTimeLimit(1)
			$.iQueriesLimit(1)
			$.iQueryRowsLimit(1)
#		$.bExpandExceededQueriesToLog(1)
			^if("debug" eq "debug" && def $form:mode && ^form:tables.mode.locate[field;debug]){
				^rem{ *** если обратились с ?mode=debug то получаем и сохраняем информацию обо всех sql запросах на странице *** }
				$.sFile[/../data/sql.txt]
				$.bAll(1)
			}{
				^rem{ *** а по умолчанию в другой лог-файл пишем только информацию о проблемных страницах *** }
				$.sFile[/../data/sqlnew.log]
			}
		]
	}
}


@makeHTML[sTitle;sBody]
<!DOCTYPE html>
<html><head><meta http-equiv="Content-Type" content="text/html^; charset=UTF-8">
<link rel="shortcut icon" href="/favicon.ico" />
<title>^if(def $hPage.sTitle){$hPage.sTitle | }Куда сколько</title>
<link rel="stylesheet" type="text/css" href="/c/main.css">
^if($isIEMobileBrowser){
	<meta name="viewport" content="width=device-width,maximum-scale=1,initial-scale=1,user-scalable=0" />
<meta name="mobileoptimized" content="0" />
}
^if(!$isOperaMiniBrowser){
	<link rel="stylesheet" type="text/css" href="/c/custom-theme/jquery-ui-1.8.22.custom.css"/>
	<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
	<script>window.jQuery || document.write('<script src="/j/jquery-1.8.3.min.js"><\/script>')</script>
	<script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.9.2/jquery-ui.min.js"></script>
	<script>window.jQuery.ui || document.write('<script src="/j/jquery-ui-1.9.2.min.js"><\/script>')</script>
	<script type="text/javascript" src="/j/jquery.cookie.js"></script>
	<script type="text/javascript" src="/j/j.js"></script>
}
</head>

<body class="^if($isOperaMiniBrowser){operamini }^if($isIEMobileBrowser && false){iemobile }^if($IS_LOCAL){beta}">^test[]
# <div id="container">
<div class="header">
# ^oCalendar.isNotToday[]
^if(def $form:fields){
	<a href="/" class="home"><u>Куда сколько</u></a>
}{
	<span class="home">Куда сколько</span>
}
^if($oAuth.is_logon){
	^use[/../classes/transaction/transaction.p]
	^transaction:printAccounts[]}
# <span><u>Куда сколько</u></span>
^if($oAuth.is_logon){<span class="user">$oAuth.user.name ^oAuth.htmlFormLogout[]</span>}{

}
</div>
<div class="body">$sBody</div>
# </div>
# ^counter[]
</body>
</html>

@counter[]
^if($env:SERVER_NAME eq 'kudaskolko.ru'){
	^rem{ код счетчика для kudaskolko.ru }	
	<!-- Yandex.Metrika counter --><script type="text/javascript">^(function ^(d, w, c^) ^{ ^(w^[c^] = w^[c^] || ^[^]^).push^(function^(^) ^{ try ^{ w.yaCounter19035334 = new Ya.Metrika^(^{id:19035334, clickmap:true, trackLinks:true, ut:"noindex"^}^)^; ^} catch^(e^) ^{ ^} ^}^)^; var n = d.getElementsByTagName^("script"^)^[0^], s = d.createElement^("script"^), f = function ^(^) ^{ n.parentNode.insertBefore^(s, n^)^; ^}^; s.type = "text/javascript"^; s.async = true^; s.src = ^(d.location.protocol == "https:" ? "https:" : "http:"^) + "//mc.yandex.ru/metrika/watch.js"^; if ^(w.opera == "^[object Opera^]"^) ^{ d.addEventListener^("DOMContentLoaded", f, false^)^; ^} else ^{ f^(^)^; ^} ^}^)^(document, window, "yandex_metrika_callbacks"^)^;</script><noscript><div><img src="//mc.yandex.ru/watch/19035334?ut=noindex" style="position:absolute^; left:-9999px^;" alt="" /></div></noscript><!-- /Yandex.Metrika counter -->
}


@test[]
# ^u:getFuzzyString[Сок апельсиновый Valio два в одном]<br/>
# ^u:getFuzzyString[Сок апельсиновый Valio]<br/>
# ^u:getFuzzyString[Сок апельсиновый]<br/>
# ^u:getFuzzyString[Сок апельсиновый Valio при eoi овагр pqok гуагр feuhgu gghbdtn]<br/>

@mainLauncher[]
^rusage[main]
^if(^form:anonymous.int(0)){
	^anonymousLauncher[]
}{
	^namedLauncher[]
}
^rusage[main]


@anonymousLauncher[]
^rem{ используется для ускорения ajax-запросов, не требующих работы с бд и авторизации }
^switch[$form:action]{
	^case[out]{
		^use[/../classes/transaction/transaction.p]
		^transaction:processMoneyOut[
			$.sData[$form:transactions]
			$.isPreview(def $form:preview)
			$.sReturnURL[$MONEY.SERVER_HOST]
		]
	}
}


@namedLauncher[]
^initAuthDBObjects[]
^oSql.server{
	^if(!$oAuth.is_logon){
		^if(def $form:action && $form:action eq 'signup'){
			$hPage.sTitle[Регистрация]
			^makeHTML[test][
				^oAuth.htmlFormRegister[
					$.target_url[/?action=signup]
				]
			]
		}{
			^makeHTML[test][
			$hPage.sTitle[]
				^oAuth.htmlFormLogon[
# 					$.action_name[Войти 2]
					$.target_url[/]
				]
			]
		}
	}{
		^if(def $form:action){
			^processing[]
		}{
			^initObjects[]
			^makeHTML[test][
			<div id="top">
				^transaction:htmlMoneyOutForm[$cookie:draft]
			</div>
				^oCalendar.showCalendar[]
				^oTransactions.anotherWayToMakeTrees[]
			]
		}

	}
}

@processing[]
^if($form:action eq json){
	^use[../classes/autocomplete.p]
	$autocomplete:oSql[$oSql]
	^rusage[returnCategories]
	^autocomplete:returnCategories[]
	^rusage[returnCategories]
}{
	^initObjects[]
	^switch[$form:action]{
		^case[out]{
			^transaction:processMoneyOut[
				$.sData[$form:transactions]
				$.isPreview(def $form:preview)
				$.sReturnURL[$MONEY.SERVER_HOST]
			]
		}
		^case[searchtransactions]{
				$transaction:oSql[$oSql]
			^transaction:searchTransactions[
				$.sData[$form:transactions]
			]
		}
		^case[rebuild]{
			^dbo:rebuildNestingData[]
		}
		^case[DEFAULT]{
			^oAction.action[$form:action]
		}
	}
}

@rusage[comment][v;now;prefix;message;line;usec]
^if($IS_LOCAL){
	$v[$status:rusage]

	^if(^hRusageStat.contains[$comment]){
		$hRusageStat.[$comment].afterSec($v.tv_sec)
		$hRusageStat.[$comment].afterMSec($v.tv_usec)

		$hRusageStat.[$comment].totalSec(
			$hRusageStat.[$comment].afterSec - $hRusageStat.[$comment].beforeSec
			)
		$hRusageStat.[$comment].totalMSec(
			$hRusageStat.[$comment].afterMSec - $hRusageStat.[$comment].beforeMSec
			)

		$now[^date::now[]]
		$usec(^v.tv_usec.double[]) 
		$prefix[[^now.sql-string[].^usec.format[%06.0f]]	$env:REMOTE_ADDR	$comment] 
		$message[^eval(($hRusageStat.[$comment].totalSec*1000000 + $hRusageStat.[$comment].totalMSec)/1000)	$request:uri]
		$line[$prefix	$message^#0A]
		^line.save[append;../plogs/rusage.log]

	}{
		^hRusageStat.add[
			$.[$comment][^hash::create[]]
		]
		$hRusageStat.[$comment].beforeSec($v.tv_sec)
		$hRusageStat.[$comment].beforeMSec($v.tv_usec)
	}

}
$result[]

@log[sLogData][locals]
^if($IS_LOCAL){
$message[$sLogData]


$now[^date::now[]]
$prefix[[^now.sql-string[]]]
# $message[]
# $message[^if(def $exception.file){${exception.file}:${exception.source}^(${exception.lineno}:$exception.colno^): }{${exception.source}}]
# $message[${message}${exception.comment}^if(def $exception.type){ ^($exception.type^)}]
# # ^if($stack){
# # 	$message[$message^stack.menu{
# # 	at ${stack.file}:$stack.name^(${stack.lineno}:$stack.colno^)}]
# # }
# $message[$message
# ^$env^:REMOTE_ADDR^[$env:REMOTE_ADDR^]]
# $message[$message
# ^$env^:HTTP_USER_AGENT^[$env:HTTP_USER_AGENT^]]
# $message[$message
# ^$request^:uri^[$request:uri^]]
# ^if(def $env:HTTP_REFERER){
# 	$message[$message
# ^$env^:HTTP_REFERER^[$env:HTTP_REFERER^]]
# }
# ^if($form:fields){
# 	$message[$message^form:fields.foreach[k;v]{
# ^$form:$k^[$v^]}]
# }
# ^if($cookie:fields){
# 	$message[$message^cookie:fields.foreach[k;v]{
# ^$cookie:$k^[^if($v is string){$v}{^if($v is hash){^v.foreach[k2;v2]{$k2=$v2}[,]}}^]}]
# }

$line[$prefix $message
----------------------------------------------------------------------------
]
#^#0A]
^line.save[append;/../plogs/parser_${now.year}^now.month.format[%02d].log]

}