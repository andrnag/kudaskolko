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

(?:(-)\s*)? # 1 isSubTransaction

(?:(^getDatePattern[])\s+)? # 1.5 sDate

# (q)? # 1.5 sDate
(?:([@\^$])\s*)? # 1.6 isChequeOrAccount1
(.+?) # 2 sName
#
(?:(?:\s+
	([\d\.,]+) # 3 dChequeAmount
	)?+\s*
	(\:) # 4 isCheque
	\s*^$
)?

(?:\s+(?:(?:

# вариант Молоко 300*2, Молоко 200, Молоко 200/3

	(?:([-\+=])?([\d\.,]+|\([ \*\+\d\.,-]+\))) # 4.5 type 5 sAmount || sPrice || quantity || expression

	(?:
		\s*
		([\\/]|\*) # 6 sAmountOrPrice ( \/ - amount, * - price)
		\s*

		(?:
			([\d\.,]+)?  # 7 dQuantity || || sPrice || quantity
		)
	\s*)?
	|
# вариант Молоко 2 по 300, 3 за 100
	(?:
		([\d\.,]+)  # 10 dQuantity2
	)
	\s*
	(\x{043f}\x{043e}|\x{0437}\x{0430}) # 12 sAmountOrPrice2 (sAmount2)( по - price, за - amount)
	\s*
	(?:([-\+=])?([\d\.,]+)) # 13 type2 14 sAmount3 || sPrice

)\s*))?
		^$][gmxi]]

@parseTransaction[sTransaction;pattern][locals]
$hResult[^hash::create[]]

$tTransaction[^sTransaction.match[$pattern]]

^rem{ последовательность ключей соответствует последовательности полей в шаблоне match }
$hStr[
	$.isSubTransaction(1)
	$.sDate(1)
	$.isChequeOrAccount1(1)
	$.sName(1)
	$.dChequeAmount(1)
	$.isCheque(1)
	$.type(1)
	$.sAmount(1)
	$.sAmountOrPrice(1)
	$.dQuantity(1)
	$.dQuantity2(1)
	$.sAmountOrPrice2(1)
	$.type2(1)
	$.sAmountOrsPrice2(1)
]
$h[^hash::create[]]
$i(1)

^hStr.foreach[hk;hv]{
	$h.[$hk][$tTransaction.$i]
	^i.inc[]
}

$hResult.sName[^u:capitalizeString[^h.sName.left(255)]]
^if(def $h.sAmountOrPrice2){
	$h.dQuantity[$h.dQuantity2]
	$h.type[$h.type2]
	$h.sAmount[$h.sAmountOrsPrice2]
	^if($h.sAmountOrPrice2 eq 'по'){
		$h.sAmountOrPrice[*]
	}
}

$hResult.sAmount[$h.sAmount]
^if(def $hResult.sAmount){
	^if(^hResult.sAmount.left(1) eq "(" && ^hResult.sAmount.right(1) eq ")"){
		$hResult.sAmount[^hResult.sAmount.trim[both;^(^)]]
		$hResult.sAmount[^hResult.sAmount.replace[-;+-]]
		$tSplittedSum[^hResult.sAmount.split[+]]
		$hResult.dQuantity(0)
		$hResult.dAmount(0)
		
		^tSplittedSum.menu{
			$tSplittedMultiple[^tSplittedSum.piece.split[*;h]]
			$dCurrentQuantity(^u:stringToDouble[$tSplittedMultiple.1](1))
			$dCurrentAmount(^u:stringToDouble[$tSplittedMultiple.0](0) * $dCurrentQuantity)
			^hResult.dAmount.inc($dCurrentAmount)
			^if($dCurrentAmount > 0){
				^hResult.dQuantity.inc($dCurrentQuantity)
			}
		}
		^if( !($hResult.dQuantity > 0) ){
			$hResult.dQuantity(1)
		}
	}{
		$hResult.dQuantity(^u:stringToDouble[$h.dQuantity](1))
		$hResult.dAmount(^u:stringToDouble[$hResult.sAmount])
		^if($hResult.dQuantity != 0 && $h.sAmountOrPrice eq "*"){
			$hResult.dAmount($hResult.dAmount * $hResult.dQuantity)
		}
	}


	$hResult.dAmountWithoutDisc($hResult.dAmount)

	$hResult.iType(^calculateTransactionType[$h.type;$h.isChequeOrAccount1])

}

$hResult.isSubTransaction(def $h.isSubTransaction && def $hResult.dAmount)
^if((!def $hResult.sAmount && def $h.isCheque) || $h.isChequeOrAccount1 eq "@"){
	^if(def $h.dChequeAmount){
		$hResult.dChequeAmount(^u:stringToDouble[$h.dChequeAmount])
	}
	^if(def $h.sAmount){
		$hResult.dChequeAmount(^u:stringToDouble[$h.sAmount])
	}
	$hResult.isCheque(true)
	$hResult.sChequeName[$hResult.sName]
	$hResult.sName[]
}
^if(def $h.sDate){
	$hResult.dtTransDate[^u:stringToDate[$h.sDate]]
}
$result[$hResult]


@calculateTransactionType[sType;sIsCheckOrAccount]
^if($sIsCheckOrAccount eq "^$"){
	$result(
	^switch[$sType]{
		^case[+]($TransactionType:INCOME | $TransactionType:ACCOUNT)
		^case[-]($TransactionType:CHARGE | $TransactionType:ACCOUNT)
		^case[=]($TransactionType:STATEMENT | $TransactionType:ACCOUNT)
		^case[DEFAULT]($TransactionType:INCOME | $TransactionType:ACCOUNT)
	})
}{
	^if(def $sType){
		$result(
		^switch[$sType]{
			^case[+]($TransactionType:INCOME)
			^case[-]($TransactionType:CHARGE)
		})
	}
}