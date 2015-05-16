@CLASS
autocomplete

@OPTIONS
locals

@returnCategories[][locals]
$isMove(def $form:move)
$sOriginalInput[^form:term.lower[]]
$sInput[$sOriginalInput]
$sFirst[^sInput.left(1)]
$isCheque($sFirst eq "@" || $sFirst eq "^"")
$isSubItem($sFirst eq "-")
$sInput[^trimPrefixes[$sInput]]

^if(def $sInput){
	$tResult[^table::create{value	label	iid	with_price}]
	$sChangedInput[^changeKeyboard[$sInput]]

	^if(!$isMove){
		^addFuzzyDates[$tResult;$sFirst;$sInput;$sChangedInput]
		^addDates[$tResult;$sInput]
		^addPopularGoodsForPrices[$tResult;$sInput]
	}
	
	$tResultFromDB[^getEntries[$isSubItem;$isCheque;$sInput;$sChangedInput]]

	^if($tResultFromDB){

		$isFirstEntryFullTyped(^sOriginalInput.trim[] eq ^tResultFromDB.value.lower[])
		^if(!$isFirstEntryFullTyped){
			^tResult.join[$tResultFromDB;$.limit(1)]
		}

		^if(!$isMove){
			$sTrimmedFirstEntry[^trimPrefixes[$tResultFromDB.value]]

			^if(^tResultFromDB.count[] == 1 || ^u:isEqualIgnoreCase[$sTrimmedFirstEntry;^sInput.trim[]]
				|| ^u:isEqualIgnoreCase[$sTrimmedFirstEntry;^sChangedInput.trim[]]){
				^if(^tResultFromDB.value.left(1) eq ^@){
					^tResult.join[^getChecks[$tResultFromDB.iid]]
				}{
					^tResult.join[^getTopPrices[$isSubItem;$tResultFromDB.iid]]
					^tResult.append{$tResultFromDB.value .	$tResultFromDB.value — Найти записи		}
				}
			}
		}
		^tResult.join[$tResultFromDB;$.offset(1)]
	}
	$result[^json:string[$tResult;$.table[object]]]
}{
	$result[^json:string[^table::create{};$.table[object]]]
}


@getEntries[isSubItem;isCheque;sInput;sChangedInput]
$result[^oSql.table{
	SELECT

	^if($isSubItem){
		CONCAT('- ',i.name)
	}{
		CONCAT(IF(t.type & $TransactionType:CHEQUE <> 0,'@',''), i.name)
	} AS value,
	i.iid

	FROM items i
	LEFT JOIN transactions t ON i.iid = t.iid
	
	WHERE
	i.user_id = $dbo:USERID AND
	i.is_auto_generated = 0 AND
	^if($isCheque){
		t.type & $TransactionType:CHEQUE = $TransactionType:CHEQUE
		AND
	}
	(
		(
			^splitInput[$sInput;i.name]
		)
		^if($sChangedInput ne $sInput){
			OR
			(
				^splitInput[$sChangedInput;i.name]
			)
		}
	)
	GROUP BY i.name
	ORDER BY
	i.type DESC,
	ABS(STRCMP(i.name,"$sInput")),
	ABS(STRCMP(LEFT(i.name, CHAR_LENGTH("$sInput")),"$sInput")),
	COUNT(t.tid) DESC,t.operday DESC,i.name
	}[$.limit(20)]
]

@getChecks[iid]
^oSql.void{SET SESSION group_concat_max_len = 1000000}
$result[^oSql.table{
	SELECT
	CONCAT('@', cti.name, ' — Повторить чек') AS label,
	CONCAT('@', cti.name,  '\n', 
		GROUP_CONCAT(CONCAT(ti.name, ' ',

		 IF(t.quantity = 1, t.amount, ROUND(t.amount/t.quantity, 2)), ' * ') SEPARATOR '\n')) AS value
	FROM transactions t 
	LEFT JOIN transactions ct ON ct.tid = t.ctid
	LEFT JOIN items ti ON ti.iid = t.iid
	LEFT JOIN items cti ON cti.iid = ct.iid
	WHERE
	ct.iid = $iid
	AND ct.type = 65
	GROUP BY t.ctid
	ORDER BY t.operday DESC
	}[$.limit(1)]
]

@addPopularGoodsForPrices[tResult;sInput]
$tParts[^sInput.match[^^\s*(\d+)\s*(?:\*\s*(\d+)\s*)?^$][gmxi]]
^if(def $tParts.1 && ^tParts.1.int(0) != 0){
	$tPopularPrices[^oSql.table{
		SELECT
		CONCAT(
			i.name,
			' ',
			^if(def $tParts.2){
				'$tParts.1',
				' * ',
				'$tParts.2'
			}{
				IF(t.quantity = 1,
					'$tParts.1',
					CONCAT(
						ROUND(t.amount/t.quantity,
							IF(ROUND(t.amount/t.quantity, 0) = t.amount/t.quantity, 0, 2))
						, ' * ', t.quantity)
				)
			}
		) AS value,
		COUNT(t.amount) as cnt,
		i.iid,
		1 AS with_price
		FROM items i
		LEFT JOIN transactions t ON i.iid = t.iid 
		WHERE 
		i.user_id = $dbo:USERID
		AND i.is_auto_generated = 0
		AND t.amount = ^tParts.1.int(0)
		AND t.tdate > DATE_SUB(NOW(), INTERVAL 4 MONTH)
		GROUP BY i.iid, t.quantity
		ORDER BY cnt desc
		}[$.limit(5)]
	]
	^if($tPopularPrices){
		^tResult.join[$tPopularPrices]
	}
}


@getTopPrices[isSubItem;iid]
$result[^oSql.table{
	SELECT
	CONCAT(
		^if($isSubItem){'- ',}
		i.name,
		' ',
		IF(t.quantity = 1,
			t.amount,
			CONCAT(
					ROUND(t.amount/t.quantity,
						IF(ROUND(t.amount/t.quantity, 0) = t.amount/t.quantity, 0, 2))
				, ' * ', t.quantity)
		)
	) AS value,
	COUNT(t.amount) as cnt,
	i.iid,
	1 AS with_price
	FROM items i
	LEFT JOIN transactions t ON i.iid = t.iid 
	WHERE 
	i.user_id = $dbo:USERID
	AND i.iid = $iid
	AND i.is_auto_generated = 0
	AND t.tdate > DATE_SUB(NOW(),INTERVAL 6 MONTH)
	AND amount <> 0
	GROUP BY t.amount
	ORDER BY cnt desc
	}[$.limit(3)]
]


@addFuzzyDates[tResult;sFirst;sInput;sChangedInput]
$sDatesFirstChars[свпз]
^if(^u:contains[$sDatesFirstChars;$sFirst]){
	^tResult.join[^getFuzzyDatesByFirst[$sInput]]
}{
	^if(^u:contains[$sDatesFirstChars;^sChangedInput.left(1)]){
		^tResult.join[^getFuzzyDatesByFirst[$sChangedInput]]
	}
}

@addDates[tResult;sInput]
$tSplitted[^sInput.split[ ;h]]
^if(def $tSplitted.0){
	$day(^tSplitted.0.int(-1))
	^if($day >= 1 && $day <= 32){
		^if(def $tSplitted.1){
			$months[^getMonthsByFirstCharacters[$tSplitted.1]]
			^if(^months.count[] == 0){
				^months.join[^getMonthsByFirstCharacters[^changeKeyboard[$tSplitted.1]]]
			}
			^months.menu{
				^tResult.append{$day $months.value}
			}
		}{
			^tResult.append{$day ^dtf:format[%h;^date::now[];$dtf:rr-locale]}
		}
	}
}



@splitInput[sInput;sFieldName]
$tSplitted[^sInput.split[ ]]

^if(^tSplitted.count[] == 1){
	$result[
		(
		$sFieldName = '^sInput.trim[]'
		OR $sFieldName like '$sInput%'
		OR $sFieldName like '% $sInput%'
		OR $sFieldName like '%-$sInput%'
		OR $sFieldName like '%($sInput%'
		)
	]

}{
	$tReSplitted[^table::create{piece}]
	$sTemp[]
	^tSplitted.menu{
		^if(^tSplitted.line[] == 1){
			$sTemp[$tSplitted.piece]
		}{
			^if(^tSplitted.piece.int(0)){
				$sTemp[$sTemp $tSplitted.piece]
			}{
				^tReSplitted.append{$sTemp}
				$sTemp[$tSplitted.piece]
			}
		}
	}
	^tReSplitted.append{$sTemp}
	$result[
		^tReSplitted.menu{
			(
			$sFieldName like '$tReSplitted.piece%'
			OR $sFieldName like '% $tReSplitted.piece%'
			OR $sFieldName like '%-$tReSplitted.piece%'
			OR $sFieldName like '%($tReSplitted.piece%'
			)
		}[AND]
	]
	
}

@changeKeyboard[sTranslit]
$result[^sTranslit.replace[^table::create{from	to
q	й
w	ц
e	у
r	к
t	е
y	н
u	г
i	ш
o	щ
p	з
^[	х
^]	ъ
a	ф
s	ы
d	в
f	а
g	п
h	р
j	о
k	л
l	д
^;	ж
'	э
z	я
x	ч
c	с
v	м
b	и
n	т
m	ь
,	б
.	ю
`	ё
}]]

@selectFrom[sFirst;months]
$result[^months.select(^months.value.left(^sFirst.length[]) eq ^sFirst.lower[])]

@getMonthsByFirstCharacters[sFirst]
$result[^selectFrom[$sFirst;^table::create{value
августа
апреля
декабря
июля
июня
марта
мая
ноября
октября
сентября
февраля
января}]]

@getFuzzyDatesByFirst[sFirst]
$result[^selectFrom[$sFirst;^table::create{value
вчера
позавчера
сегодня
завтра
послезавтра}]]

@trimPrefixes[sInput]
$result[^sInput.trim[left;^@ -]]
