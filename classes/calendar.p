@CLASS
calendar

@USE
transaction/TransactionType.p

@auto[]
$data[^hash::create[]]

@create[hParams][currentDate;hOperdays;hParams;dtFMonday;dtFSunday]
$data.dtNow[^u:getJustDate[^date::now[]]]
$hParams[^hash::create[$hParams]]
$USERID(^hParams.USERID.int(0))
# $currentDate[^date::now[]]
# $data.currentDate[^date::create($data.dtNow.year;$data.dtNow.month;$data.dtNow.day)]
$data.currentDate[^date::create[$data.dtNow]]
$hOperdays[^getDateFromComplexOperday[$form:operday;$data.currentDate]]
#^if(def $form:operday){
	$data.currentDate[$hOperdays.0]

	$dtFMonday[$hOperdays.1]
#	^u:p[$dtFMonday]
	$dtFSunday[$hOperdays.2]
#}


$data.startDate[^if(def $dtFMonday){$dtFMonday}{$data.currentDate}]
$data.endDate[^if(def $dtFSunday){$dtFSunday}{$data.currentDate}]

$data.currentOperday[^u:getOperdayByDate[$data.currentDate]]
$data.startOperday[^u:getOperdayByDate[$data.startDate]]
$data.endOperday[^u:getOperdayByDate[$data.endDate]]
$data.pid(^form:p.int(0))
$data.gid(^form:groupid.int(0))
$data.ciid(^form:ciid.int(0))
$data.isDetailed(^form:detailed.int(0))

@isMonthSelected[]
$result(false)


@monthSelector[][dtMonth;dFirstDate;dLastDate;tMonths]
$hMonths[^hash::create[]]
$iMonthCount(7)
$dFirstDate[]
$dLastDate[]
$hFirstDay[
	$.0[^u:getFirstDay[$data.currentDate]]
]
$currentFirstDay[^u:getFirstDay[$data.currentDate]]
$currentFirstDay[^u:getFirstDay[$data.currentDate]]
$isPastDate($data.currentDate < $data.dtNow)
$iPastDiff(^u:getFirstDay[$data.dtNow] - ^u:getFirstDay[$data.currentDate])
$isDateNowShown(!$isPastDate)
^for[i](1;$iMonthCount){
	$date[^u:getFirstDay[$data.currentDate]]
 
# Текущий месяц - средний
#	^date.roll[month](( ($iMonthCount - 1)/2 - $i + 1 ) * -1)


^if($iPastDiff > (31 * 2) ){
# Текущий месяц - средний
	^date.roll[month](( ($iMonthCount - 1)/2 - $i + 1 ) * -1)
}{
	^if($iPastDiff > 31){
# Текущий месяц - третий с конца
		^date.roll[month]( $i - $iMonthCount + 2)
	}{
# Текущий месяц - предпоследний
		^date.roll[month]( $i - $iMonthCount + 1)
	}
}

^if($date == $data.dtNow){
	$isDateNowShown(true)
}

^rem{
1 -5 
2 -4
3 -3
4 -2
5 -1
6 0
7 +1

i - iMountCount + 1

1-7+1 =-6+1 = -5

}
 	^if($i == 1){
 		$dFirstDate[^date::create($date)]
 	}
 	^if($i == $iMonthCount){
		$dLastDate[^u:getLastDay[$date]]
 	}
 	$key[${date.year}^date.month.format[%02d]]
 	$hMonths.$key[$date]
	^if($date.year == 2037 && $date.month == 12){
		$dLastDate[^u:getLastDay[$date]]
		^break[]
	}
}

^if(!$isDateNowShown){
	$dtNowFirstDay[^u:getFirstDay[$data.dtNow]]
 	$hMonths.[${dtNowFirstDay.year}^dtNowFirstDay.month.format[%02d]][$dtNowFirstDay]
}

# $dFirstDate[^date::create($data.currentDate.year;$data.currentDate.month;1)]
# ^dFirstDate.roll[month](-2)
# $dLastDate[^date::create($data.currentDate.year;$data.currentDate.month;^date:last-day($data.currentDate.year;$data.currentDate.month))]
# ^dLastDate.roll[month](2)
# # '^dFirstDate.sql-string[]' ~ '^dLastDate.sql-string[]'
# <br/>
# # $sCurrentDate[^data.currentDate.sql-string[]]
$hMonthsSum[^oSql.table{
	/* Суммы по месяцам */
SELECT 
# IFNULL(nd.type,^form:type.int(1)) AS type,
nd.type AS type,

SUBSTRING(t.operday,1,6) ym,SUM(t.amount) sum 
FROM transactions t
# ^if($data.pid){
	LEFT JOIN nesting_data nd ON nd.iid = t.iid
# }
^if($data.ciid){
	LEFT JOIN transactions cheque ON cheque.tid = t.ctid

}
#  	LEFT JOIN items i ON nd.pid = i.iid
WHERE
	t.is_displayed = 1
	AND t.user_id = $USERID
	AND 
	(
		(t.operday >= ^u:getOperdayByDate[$dFirstDate]
	AND t.operday <= ^u:getOperdayByDate[$dLastDate])
	^if(!$isDateNowShown){
		OR
		(
			t.operday >= ^u:getOperdayByDate[^u:getFirstDay[$data.dtNow]]
		AND t.operday <= ^u:getOperdayByDate[^u:getLastDay[$data.dtNow]]
		)
	}
	)
	^if($data.pid){
		AND nd.pid = $data.pid
	}{
		^if($data.ciid){
			AND cheque.iid = $data.ciid
		}
# 		^if(^form:type.int(0)){
# 			AND nd.type = ^form:type.int(0)
# 		}
		AND nd.iid = nd.pid
	}
GROUP BY ym,nd.type
}
#[$.type[table]]
]
$hMonthsSum[^hMonthsSum.hash{${hMonthsSum.type}${hMonthsSum.ym}}[$.type[hash]]]
<div 
class="months^if(!(^form:p.int(0) || ^form:ciid.int(0))){ pm 
	^if(def $cookie:barstate){$cookie:barstate}{ m p}}">
$hSums[
	$.1[
		$.dTotalSum(0)
		$.dMinSum(0)
		$.dMaxSum(0)
		$.dLastSum(0)
	]
	$.2[
		$.dTotalSum(0)
		$.dMinSum(0)
		$.dMaxSum(0)
		$.dLastSum(0)
	]
]
$dTotalSum(0)
$dMinSum(0)
$dMaxSum(0)
^hMonths.foreach[k;v]{
# 	^dTotalSum.inc($hMonthsSum.[1$k].sum)
	$dMaxSum(^u:max($dMaxSum;$hMonthsSum.[1$k].sum))
	$dMaxSum(^u:max($dMaxSum;$hMonthsSum.[2$k].sum))

	$hSums.1.dMaxSum(^u:max($hSums.1.dMaxSum;$hMonthsSum.[1$k].sum))
	$hSums.2.dMaxSum(^u:max($hSums.2.dMaxSum;$hMonthsSum.[2$k].sum))
}
$dTotalSum($dMaxSum)
$hSums.1.dTotalSum($hSums.1.dMaxSum)
$hSums.2.dTotalSum($hSums.2.dMaxSum)
$dLastSum(0)
$iYear(0)
$isActiveMonth(false)
$dtPreviousDate[]
^hMonths.foreach[k;v]{

^if(def $dtPreviousDate && $v - $dtPreviousDate > 32){
		<div class="month">
 			<div class="bar-container empty">
#		<div class="bard" style="height: 0"></div>
 		</div>
		<div class="date nodata"><span>...</span></div>
	</div>
}

^if($iYear != $v.year){
	$iYear($v.year)
	<div class="month year">
 			<div class="bar-container empty">
#		<div class="bard" style="height: 0"></div>
 		</div>
		<div class="date nodata"><span>$iYear</span></div>
	</div>
}
# @getLink[date][dtFirstDay;dtLastDay;isActive;sDate;sOperdayForMonth]
$dtFirstDay[^u:getFirstDay[$v]]
$dtLastDay[^u:getLastDay[$v]]

$isActive(false)
^if($data.startDate && $data.endDate){
	^if( ($data.startDate >= $dtFirstDay && $data.endDate <= $dtLastDay) ||
		($data.startDate >= $dtFirstDay && $data.currentDate <= $dtLastDay) || 
		($data.currentDate >= $dtFirstDay && $data.endDate <= $dtLastDay)
		){$isActive(true)}
}{
	^if($data.currentDate >= $dtFirstDay && $data.currentDate <= $dtLastDay){$isActive(true)}
}

$sDate[^dtf:format[%h;$v]]

	<div class="month^if($isActive){ active}^if(!def $hMonthsSum.[1$k].sum && !def $hMonthsSum.[2$k].sum){ empty}">

		<div class="bar-container ^if($hMonthsSum.[1$k].sum + $hMonthsSum.[2$k].sum == 0){ empty}">
#		^if(def $sFullSumm){ title="$sFullSumm"}>

		^printBars[$hMonthsSum.[1$k].sum;$hSums.1.dTotalSum;minus one;$TransactionType:CHARGE;0]
		^printBars[$hMonthsSum.[2$k].sum;$dTotalSum;plus both;$TransactionType:INCOME;^if($data.ciid != 0){0}]
		^printBars[$hMonthsSum.[2$k].sum;$hSums.2.dTotalSum;plus one;$TransactionType:INCOME;0]
		^printBars[$hMonthsSum.[1$k].sum;$dTotalSum;minus both;$TransactionType:CHARGE;^if($data.ciid != 0){0}]
# 		$sSum[^u:formatValue($hMonthsSum.[$k].sum;true)]
# 		^if(!^data.pid.int(0)){
# 			$sFullSumm[$sSum]
# 			$sSum[^u:formatValueByDivision($hMonthsSum.[$k].sum;1000;true)]
# 		} 
# 		$dDelta(0)
# 		^if(def $hMonthsSum.[$k].sum && $dLastSum != 0){
# 			$dDelta($hMonthsSum.[$k].sum - $dLastSum)
# 		}
# 		$dLastSum($hMonthsSum.[$k].sum)
# # 		<div class="bar-average" style="height: ^math:round(100 *($dTotalSum/$iMonthCount) / $dTotalSum)%"></div>

# 		^if(def $hMonthsSum.[$k].sum){
# 			$iHeight(^if($dTotalSum > 0;(^math:round(100 *$hMonthsSum.[$k].sum / $dTotalSum)-1);0))
# 			<div class="bar" style="height: ${iHeight}%">
# 			<span>$sSum^if($dDelta){<i class="delta"> ^if($dDelta > 0){+}^u:formatValue($dDelta;true)</i>}</span>
# 			</div>
# 		}{
# 			<div class="bar"></div>
# 		}


		</div>

	$sOperdayForMonth[^u:getOperdayByDate[$dtFirstDay]-^u:getOperdayByDate[$dtFirstDay]-^u:getOperdayByDate[$dtLastDay]]
	^if($form:operday eq $sOperdayForMonth){
		$isActiveMonth(true)
		<div class="date active"><span>$sDate</span></div>

	}{
# 		^if($hMonthsSum.[$k].sum != 0){
	<a class="date^if($isActive){ active}^if(!def $hMonthsSum.[1$k].sum && !def $hMonthsSum.[2$k].sum){ nodata}"
	href="?operday=$sOperdayForMonth^getURI[]"><span>$sDate</span></a>
# 	}{
# 		<div class="date nodata"><span>$sDate</span></div>
# 	}
	}

# 		<a class="date" href="?operday=^getFullOperdayForMonth[$v]^getURI[]">^dtf:format[%h;$v]</a>

		
# 		<div class="amount">$sSum</div>
	</div>

	$dtPreviousDate[$v]
}

^if(def $request:query && ($data.dtNow != $data.currentDate || $data.startDate != $data.endDate)){
<div class="month today">
		<div class="bar-container empty"></div>
	<a class="date" href="/"><span>Сегодня</span></a>
</div>
}
#<div class="clear"></div>


</div>
#<div class="clear"></div>

^weekSelector($isActiveMonth)

@isNotToday[]
$result(def $request:query && ($data.dtNow != $data.currentDate || $data.startDate != $data.endDate))

@printBars[iMonthSum;dTotalSum;sClass;iType;isOnlyKilos][iHeight;sSum;dDelta;dLastSum]
$sSum[^u:formatValueByType($iMonthSum;$iType;true)]
^if(!^data.pid.int(0) && ^isOnlyKilos.int(1)){
# 	$sFullSumm[$sSum]
	^if($iType == $TransactionType:CHARGE){
		$sSum[^u:formatValueByDivision($iMonthSum;1000;true)]
		^if($iMonthSum < 1000){
			$sSum[^u:formatValueWithoutCeiling(^u:ceiling($iMonthSum/1000;3))]
		}
	}{
		$sSum[^u:formatValueByDivisionFloor($iMonthSum;1000;true)]
		^if($iMonthSum < 1000){
			$sSum[^u:formatValueWithoutCeiling(^u:floor($iMonthSum/1000;3))]
		}
	}
}
^if(def $iMonthSum){
	$iHeight(^if($dTotalSum > 0;^u:max(^math:round(100 * $iMonthSum / $dTotalSum) - 1;0);0))
	^if(def $form:log){
		$iHeight(^if($dTotalSum > 0;^math:round(100 *^math:log($iMonthSum) / ^math:log($dTotalSum));0))
	}
	<div class="bar $sClass" style="height: ${iHeight}%">
 	<span>$sSum
# 	^if($dDelta){<i class="delta"> ^if($dDelta > 0){+}^u:formatValue($dDelta;true)</i>}
 	</span>
	</div>
}{
# 	<div class="bar"></div>
}


@getFullOperdayForMonth[dtDate]
$result[^u:getOperdayByDate[^date::create($dtDate.year;$dtDate.month;1)]-^u:getOperdayByDate[^date::create($dtDate.year;$dtDate.month;1)]-^u:getOperdayByDate[^date::create($dtDate.year;$dtDate.month;^date:last-day($dtDate.year;$dtDate.month))]]

@getDateFromComplexOperday[sOperday;defaultDate]
$tOperdays[^sOperday.split[-;h]]
#$dtMonday[^u:stringToDate[$sOperday.1]]
#$dtSunday[^u:stringToDate[$sOperday.2]]

#^if(def $tOperdays.2 && def $tOperdays.3){
#	$result[^u:stringToDate[$tOperdays.2]]
#}{
$result[
	$.0[^u:stringToDate[$tOperdays.0;$defaultDate]]
	
	^if(def $tOperdays.1){
		$.1[^u:stringToDate[$tOperdays.1;$defaultDate]]
	}
	^if(def $tOperdays.2){
		$.2[^u:stringToDate[$tOperdays.2;$defaultDate]]
	}
]

@printDateRange[]
^u:getDateRange[$data.startDate;$data.endDate;$data.currentDate]

@showCalendar[][dtNow]
<div class="calendar">
^monthSelector[]
# <div class="clear"></div>
</div>

@getURI[][sResult]
$sResult[]
^if($data.pid){$sResult[&p=$data.pid]}
^if($data.ciid){$sResult[&ciid=$data.ciid]}
$result[$sResult]

@weekSelector[isDefault][isActive;nextDateIsCurrent]
$tCalendar[^table::create{week	monday	sunday}]

$tCal[^date:calendar[rus]($data.currentDate.year;$data.currentDate.month)]
^tCal.menu{
	^if(def $tCal.0){
		$dtMonday[^date::create($data.currentDate.year;$data.currentDate.month;$tCal.0)]
	}
	^if(def $tCal.6){
		$dtSunday[^date::create($data.currentDate.year;$data.currentDate.month;$tCal.6)]
	}
	^if(^tCal.line[] == 1 && !def $dtMonday){
		$dtMonday[^date::create($dtSunday-6)]		
	}
	^if(^tCal.line[] == ^tCal.count[] && !def $dtSunday){
		$dtSunday[^date::create($dtMonday+6)]
	}
	^if(def $dtSunday && def $dtMonday){
		^tCalendar.append{$tCal.week	^dtMonday.sql-string[]	^dtSunday.sql-string[]}
	}
	$dtSunday[]
	$dtMonday[]
}

$mondayOperday[^u:getOperdayByDate[^date::create[$tCalendar.monday]]]
^tCalendar.offset(-1)
$sundayOperday[^u:getOperdayByDate[^date::create[$tCalendar.sunday]]]

$tWeeks[^oSql.table{
SELECT
	WEEK(t.tdate, 3) w,
	BIT_OR(POW(2,(IF(DAYOFWEEK(t.tdate)=1,8,DAYOFWEEK(t.tdate))-1))) AS weekdays,
	MIN(t.tdate) mindate,
	MAX(t.tdate) maxdate,
	SUM(t.amount) sum,
	nd.type
FROM transactions t
	LEFT JOIN nesting_data nd ON nd.iid = t.iid
	LEFT JOIN items i ON nd.pid = i.iid
	^if($data.ciid){
		LEFT JOIN transactions cheque ON cheque.tid = t.ctid
	}
WHERE	
	^if($data.pid){
		nd.pid = $data.pid
	}{
		(i.type = $TransactionType:CHARGE OR i.type = $TransactionType:INCOME)
	}
	AND t.is_displayed = 1
	AND t.user_id = $USERID
	AND t.operday >= $mondayOperday 
	AND t.operday <= $sundayOperday
	^if($data.ciid){
		AND cheque.iid = $data.ciid
	}
GROUP BY w, nd.type
}]

$hWeeks[^tWeeks.hash{${tWeeks.type}${tWeeks.w}}[$.type[hash]]]

#^hWeeks.foreach[k;v]{$k $v.sum}[-]
<div class="weeks">
$nextDateIsCurrent(true)
#<div class="week last"><a class="date" href="?operday="><span>←</span></a></div>
^tCalendar.menu{
#	<div class="week">
	$dtMonday[^date::create[$tCalendar.monday]]
	$dtSunday[^date::create[$tCalendar.sunday]]
	$isActive(false)
	^if($data.startDate && $data.endDate){
		^if($data.startDate >= $dtMonday && $data.endDate <= $dtSunday){$isActive(true)}
	}{
		^if($data.currentDate >= $dtMonday && $data.currentDate <= $dtSunday){$isActive(true)}
	}

	^if(!($dtMonday.month == $data.currentDate.month && $dtMonday.year == $data.currentDate.year) ||
			!($dtSunday.month == $data.currentDate.month && $dtSunday.year == $data.currentDate.year)
	){
		$sDate[^dtf:format[%e %h;$dtMonday;$dtf:rr-locale]–^dtf:format[%e %h;$dtSunday;$dtf:rr-locale]]
		$nextDateIsCurrent(true)
	}{
		^if($nextDateIsCurrent){
# 				$sDate[${dtMonday.day}–^dtf:format[%e %h;$dtSunday;$dtf:rr-locale]]
		$sDate[${dtMonday.day}–${dtSunday.day}]
				$nextDateIsCurrent(false)
		}{
			$sDate[${dtMonday.day}–${dtSunday.day}]
		}
	}
	$sOperdayForWeek[^u:getOperdayByDate[^date::create($data.currentDate.year;$data.currentDate.month;1)]-^u:getOperdayByDate[$dtMonday]-^u:getOperdayByDate[$dtSunday]]
	^if($form:operday eq $sOperdayForWeek){
#		<div class="date active"><span>$sDate</span></div>
	}{
	^if($hWeeks.[$TransactionType:CHARGE^tCalendar.week.int(-1)].sum || $hWeeks.[$TransactionType:INCOME^tCalendar.week.int(-1)].sum){
	$st[^data.currentDate.sql-string[] >= ^dtMonday.sql-string[] && ^data.currentDate.sql-string[] <= ^dtSunday.sql-string[]]
	^if(!$isActive){
	<div class="week^if($isDefault){ default}">
		<a ^rem{title="$st" }class="date^if($isActive){ active}"
	href="?operday=$sOperdayForWeek^getURI[]"><span>$sDate</span></a>
		<div class="amount">^u:formatValue[$hWeeks.[$TransactionType:CHARGE^tCalendar.week.int(-1)].sum](true)</div>
	</div>
	}

# 	<div class="week">
# 		<a ^rem{title="$st" }class="date^if($isActive){ active}"
# 	href="?operday=$sOperdayForWeek^getURI[]"><span>$sDate</span></a>
# 		<div class="amount">^u:formatValue[$hWeeks.[^tCalendar.week.int(-1)].sum](true)</div>
# 	</div>
	}{
		^if(!$isActive){
		<div class="week^if($isDefault){ default}">
	<div class="date nodata"><span>$sDate</span></div>
	<div class="amount">^u:formatValue[$hWeeks.[$TransactionType:CHARGE^tCalendar.week.int(-1)].sum](true)</div>
	</div>
}
	}
	}
	
#</div>
^if($isActive){
	<div class="week extended">
	<div class="date^if($form:operday eq $sOperdayForWeek){ active}^if(!$hWeeks.[$TransactionType:CHARGE^tCalendar.week.int(-1)].sum && !$hWeeks.[$TransactionType:INCOME^tCalendar.week.int(-1)].sum){ nodata}">
	^daySelector[$dtMonday;$dtSunday;
	^eval($hWeeks.[$TransactionType:CHARGE^tCalendar.week.int(-1)].weekdays | $hWeeks.[$TransactionType:INCOME^tCalendar.week.int(-1)].weekdays)

	]</div>
# 	<div class="clear"></div>
	<div class="amount">^u:formatValue[$hWeeks.[$TransactionType:CHARGE^tCalendar.week.int(-1)].sum](true)</div>
	</div>
}
}

</div>
#<div class="clear"></div>


@daySelector[dtMonday;dtSunday;weekdays][tWeek;hDays;nextDateIsCurrent]
$tWeek[^date:calendar[rus]($dtMonday.year;$dtMonday.month;$dtMonday.day)]
$dtCurrent_[^date::create[$dtMonday]]
$nextDateIsCurrent(true)
^tWeek.menu{
	^dtCurrent_.roll[day](^tWeek.line[] > 1)
	$currentOperday[^u:getOperdayByDate[$dtCurrent_]]
	$isActive[^if($data.currentDate == $dtCurrent_){active}]
	$isWeekend(^tWeek.line[] == 6 || ^tWeek.line[] == 7)
	$value[^eval($tWeek.day)]
	^if($dtCurrent_.month != $dtMonday.month && $nextDateIsCurrent){
		$nextDateIsCurrent(false)
# 		$lastMonth($dtCurrent_.month)
# 		$value[${value}.^dtCurrent_.month.format[%02d]]
		$value[${value} ^dtf:format[%h;$dtCurrent_;$dtf:rr-locale]]
# 		$nextDateIsCurrent(true)
	}
	^if($dtCurrent_.month == $dtMonday.month && $dtCurrent_.month != $dtSunday.month && ^tWeek.line[] == 1){
# 		$value[${value}.^dtCurrent_.month.format[%02d]]
		$value[${value} ^dtf:format[%h;$dtCurrent_;$dtf:rr-locale]]
	}
# 	$value[^eval($tWeek.day)^if($dtCurrent_.month != $dtMonday.month){.^dtf:format[%m;$dtCurrent_;$dtf:rr-locale]}]
	$sValue[<span^if($isWeekend){ class="weekend"}>$value</span>]
		
	^if($form:operday eq $currentOperday || (!def $form:operday && def $isActive)){
		<span class="day active">$sValue</span>
	}{
		^if(^math:pow(2;^tWeek.line[]) & $weekdays){
			<a title="" class="day $isActive" href="?operday=$currentOperday^getURI[]">$sValue</a>
		}{
			<span class="nodata day">$sValue</span>
		}
	}
}

@printCurrentCheque[]
$result[^if($data.ciid){^oSql.string{SELECT CONCAT('^@',name) FROM items WHERE iid = $data.ciid}[$.default[]$.limit(1)]}]

@printCurrentDate[][usedDate]
$usedDate[$data.currentDate]
^if($data.currentDate != $data.startDate){
	$usedDate[$data.startDate]
}
$result[^dtf:format[%e %h^if($usedDate.year != $data.dtNow.year){ %Y};$usedDate;$dtf:rr-locale] ^printCurrentCheque[]]

@isToday[]
$result($data.dtNow == $data.currentDate)