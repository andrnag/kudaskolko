@CLASS
TransactionParser

@USE
../common/array.p

@getDatePattern[]
# Даты в "разговорном" формате
(?>
# пока не поддерживаем запись на "прошлый понедельник" и подобное	
#	(?:(?:прошл(?:ое|ый|ая)\s+)?(?>воскресенье|понедельник|вторник))|
	позавчера|вчера|сегодня|завтра|послезавтра
)
|
# даты в формате 31 мая/31 мая 10/31 мая 2010 
(?:(?:(?:[12][0-9]|3[012]|0?[123456789])\s*)
(?>января|февраля|марта|апреля|мая|июня|июля|августа|сентября|октября|ноября|декабря)
(?:\s*\d\d(?:\d\d)?)?)
|
# даты в формате ГГГГММДД
(?:\d\d\d\d\d\d\d\d)
|
# даты в формате 31.05/31.05.14/31.05.2014/1.5.14/
(?:(?:[12][0-9]|3[012]|0?[123456789])\.(?:0?[123456789]|1[012])(?:\.\d\d(?:\d\d)?)?)


@parseTransactionList[sTransactions][locals]
# returns hash of transactions
$hResult[^hash::create[]]
$aTransactions[^array::new[]]
$tTransactions[^sTransactions.match[

^^[ \t]* # лишние символы
(\x23)? # возможность закомментировать строку знаком #
(
	(?:(^getDatePattern[])\s*)
	|
	(.*?))
^$][gmxi]]

$oBaseTransaction[]
$dtTransDate[^u:getJustDate[^date::now[]]]
$hTransaction[^hash::create[]]
$patternParseTransactionPattern[^getParseTransactionPattern[]]
^tTransactions.menu{
^if(!def $tTransactions.2 && !def $tTransactions.1){
	$hTransaction.isEmpty(true)
}{
	^if(def $tTransactions.3){
		$dtTransDate[^u:stringToDate[$tTransactions.3]]
		$hTransaction.isEmpty(true)
	}{
		$hTransaction.dtTransDate[$dtTransDate]

		^hTransaction.add[^parseTransaction[$tTransactions.2;$patternParseTransactionPattern]]
	}
}
^if(!def $tTransactions.1){
	^aTransactions.add[^hash::create[$hTransaction]]
	$hTransaction[^hash::create[]]
}
}

$result[^aTransactions.getHash[]]


@getParseTransactionPattern[]
$result[^regex::create[
^^\s*

(?:(^getDatePattern[])\s+)? # 1 sDate

(?:(-)\s*)? # 2 isSubTransaction
(?:(@)\s*)? # 3 isCheque
(?:(\^$)\s*)? # 4 isAccount

(.+?) # 5 sName

(?:\s+

	(?:([-\+])\s*)? # 6 sChargeOrIncome

	(?:
		# с жестким =, после которого можно использовать пробелы между знаками
		(?:
			(?:(=)\s*) # 7 isSubtotal
			([\d\.,\*\\/\+\-\s]+) # 8 sSumExpressionToEvaluate
		)
	|
		# без суммирования
		(?:
			([\d\.,]+) # 9 sumOrPrice
			(?:\s*
				(?:
				[\\/]\s*([\d\.,]+) # 10 /perQuantity
				|
				\*\s*([\d\.,]+) # 11 *forQuantity
				)
			)?
		)
	|
		# с неразрывным суммированием
		(?:
			([\d\.,\*\\/\+\-]+) # 12 sSumExpressionWithoutSpacesToEvaluate
		)
	)
)?\s*
^$][gmxi]]

@parseTransaction[sTransaction;pattern][locals]
$hResult[^hash::create[]]

$tTransaction[^sTransaction.match[$pattern]]

^rem{ последовательность ключей соответствует последовательности полей в шаблоне match }
$hStr[
	$.sDate(1)
	$.isSubTransaction(1)
	$.isCheque(1)
	$.isAccount(1)
	$.sName(1)
	$.sChargeOrIncome(1)
	$.isSubtotal(1)
	$.sSumExpressionToEvaluate(1)
	$.sumOrPrice(1)
	$.perQuantity(1)
	$.forQuantity(1)
	$.sSumExpressionWithoutSpacesToEvaluate(1)
]
$h[^hash::create[]]
$i(1)

^hStr.foreach[hk;hv]{
	$h.[$hk][$tTransaction.$i]
	^i.inc[]
}

^if(def $h.sDate){
	$hResult.dtTransDate[^u:stringToDate[$h.sDate]]
}

$hResult.sName[^u:capitalizeString[^h.sName.left(255)]]
$hResult.dQuantity(1)
$hResult.iType(^calculateTransactionType[$h.sChargeOrIncome](def $h.isAccount;def $h.isSubtotal))

^if(def $h.sumOrPrice){
	$hResult.dAmount(^u:stringToDouble[$h.sumOrPrice])

	^if(def $h.perQuantity){
		$hResult.dQuantity(^u:stringToDouble[$h.perQuantity](1))
	}

	^if(def $h.forQuantity){
		$hResult.dQuantity(^u:stringToDouble[$h.forQuantity](1))
		$hResult.dAmount($hResult.dAmount * $hResult.dQuantity)
	}
}

$sExpression[]

^if(def $h.sSumExpressionToEvaluate){
	$sExpression[$h.sSumExpressionToEvaluate]
}

^if(def $h.sSumExpressionWithoutSpacesToEvaluate){
	$sExpression[$h.sSumExpressionWithoutSpacesToEvaluate]
}


^if(def $sExpression){
	$sExpression[^sExpression.replace[\;/]]
	$sExpression[^sExpression.replace[-;+-]]
	$tSplittedSum[^sExpression.split[+]]
	$hResult.dQuantity(0)
	$hResult.dAmount(0)

	^tSplittedSum.menu{
		^if(^u:contains[$tSplittedSum.piece;*]){
			$tSplittedMultiple[^tSplittedSum.piece.split[*;h]]
			$dCurrentQuantity(^u:stringToDouble[$tSplittedMultiple.1](1))
			$dCurrentAmount(^u:stringToDouble[$tSplittedMultiple.0](0) * $dCurrentQuantity)

		}{
			^if(^u:contains[$tSplittedSum.piece;/]){
				$tSplittedDivision[^tSplittedSum.piece.split[/;h]]
				$dCurrentQuantity(^u:stringToDouble[$tSplittedDivision.1](1))
				$dCurrentAmount(^u:stringToDouble[$tSplittedDivision.0](0))
			}{
				$dCurrentQuantity(1)
				$dCurrentAmount(^u:stringToDouble[$tSplittedSum.piece](0))
			}
		}
		^hResult.dAmount.inc($dCurrentAmount)
		^if($dCurrentAmount > 0){
			^hResult.dQuantity.inc($dCurrentQuantity)
		}
	}
}
^if($hResult.dQuantity <= 0){
	$hResult.dQuantity(1)
}
$hResult.dAmountWithoutDisc($hResult.dAmount)

$hResult.isSubTransaction(def $h.isSubTransaction && def $hResult.dAmount)
^if(def $h.isCheque){
	^if(def $hResult.dAmount){
		$hResult.dChequeAmount($hResult.dAmount)
	}
	$hResult.isCheque(true)
	$hResult.sChequeName[$hResult.sName]
	$hResult.sName[]
}

$result[$hResult]


@calculateTransactionType[sChargeOrIncome;isAccount;isSubtotal]
^if($isAccount){
	^if($isSubtotal){
		$result($TransactionType:STATEMENT | $TransactionType:ACCOUNT)
	}{
		$result(
		^switch[$sChargeOrIncome]{
			^case[+]($TransactionType:INCOME | $TransactionType:ACCOUNT)
			^case[-]($TransactionType:CHARGE | $TransactionType:ACCOUNT)
			^case[DEFAULT]($TransactionType:INCOME | $TransactionType:ACCOUNT)
		})
	}
}{
	^if(def $sChargeOrIncome){
		$result(
		^switch[$sChargeOrIncome]{
			^case[+]($TransactionType:INCOME)
			^case[-]($TransactionType:CHARGE)
		})
	}
}