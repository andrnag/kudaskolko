@CLASS
transactionlist

@auto[]
$data[^hash::create[]]

@create[hParams]
$hPage[$hParams.hPage]
$USERID(^hParams.USERID.int(0))

@printBreadScrumbs[]
<ul class="breadscrumbs">
$tParents[^dbo:getParentItems[$.iid[^form:p.int(0)]]]
^if(!$tParents && (^form:p.int(0) || ^form:ciid.int(0))){
<li><a href="^makeQueryString[
				$.groupid[$form:groupid]
				$.operday[$form:operday]
			]">Расходы и доходы</a></li>
}
^tParents.menu{
	^if(^tParents.line[] != ^tParents.count[]){
		<li><a href="^makeQueryString[
					$.groupid[$form:groupid]
					$.operday[$form:operday]
					^if($tParents.level != 0){
						$.p[$tParents.iid]
					}
				]">$tParents.name</a></li>
	}
}
</ul>


@anotherWayToMakeTrees[][locals]
^printBreadScrumbs[]
$iType(^form:type.int(0))
^if(^form:p.int(0)){
	$iType(^oSql.int{
		SELECT type 
		FROM nesting_data 
		WHERE iid = ^form:p.int(0) AND iid = pid
	}[$.limit(1)$.default(-1)])
}{
	$hPage.sTitle[Расходы и доходы ^oCalendar.printDateRange[]]
}

<div class="transactions">
^if($iType == 0 || $iType == $TransactionType:CHARGE){
<div id="charges">^printTransactionByType[
	$.type[$TransactionType:CHARGE]
	$.title[Расходы]
	$.title2[расходов]
]</div>
}
^if(($iType == 0 && !^form:ctid.int(0)) || $iType == $TransactionType:INCOME){
<div id="incomes">^printTransactionByType[
	$.type[$TransactionType:INCOME]
	$.title[Доходы]
	$.title2[доходов]
]</div>
}
</div>

@printTransactionByType[hParams][k;v]
$hParams[^hash::create[$hParams]]
$intMaxOperday(^dbo:getLastOperday[])
$intMaxOperday(^form:operday.int(0))
$tEntries[^dbo:getEntries[
	$.pid(^form:p.int(0))
	$.gid(^form:groupid.int(0))
	$.operday(^form:operday.int(0))
	$.startOperday($oCalendar.data.startOperday)
	$.endOperday($oCalendar.data.endOperday)
	$.detailed[$form:detailed]
	$.ctid[$form:ctid]
	$.ciid[$form:ciid]
	$.isExpanded[$form:expanded]
	$.type[$hParams.type]
]]

$entryName[$tEntries.name]
^if(!$tEntries){
	$entryName[^oSql.string{
		SELECT name
		FROM items
		WHERE 
		user_id = $USERID AND
 	^if(^form:ciid.int(^form:p.int(0))){
		iid = ^form:ciid.int(^form:p.int(0))
	}{
		type = $hParams.type
	}
	}[	$.limit(1)$.default[default]]]
}

$hGroups[^dbo:getGroupsForTransactions[
	$.startOperday($oCalendar.data.startOperday)
	$.endOperday($oCalendar.data.endOperday)
]]

$h[^hash::create[]]
$h.dRestQuantity(0)
$h.iTotalSum(0)
$h.iSum(0)

$hTransactions[^hash::create[]]
$hTransactions.0[^hash::create[]]

^if(def $form:detailed){
	^tEntries.menu{^h.iSum.inc($tEntries.sum)}
} 
^h.iTotalSum.inc($h.iSum)
$h.iOffset(0)
$hTransactions.0.date[^oCalendar.printDateRange[]]
^if((^form:p.int(0) != 0 && ^form:p.int(0) == $tEntries.iid) || ^form:ciid.int(0) == 0){
	^if(!def $form:detailed){
		$h.iSum($tEntries.sum)
		^h.iTotalSum.inc($h.iSum)
		$h.dRestQuantity($tEntries.quantity)

	}

	$hTransactions.0.name[$entryName]
	$hTransactions.0.value[^u:formatValueByType($h.iSum;$hParams.type)]
# 	^if($tEntries.has_children == 1){
		$hTransactions.0.expandLink[^makeQueryString[
					$.groupid[$form:groupid]
					$.operday[$form:operday]
					$.p[$form:p]
# 					^if(^form:p.int(0)){
# 						$.type[$hParams.type]
# 					}
				]]
# 	}
# 	$hTransactions.0.date[^oCalendar.printDateRange[]]
	^if(!def $hPage.sTitle){
		$hPage.sTitle[$entryName ^oCalendar.printDateRange[]]
	}
	^if(!def $form:detailed){
		$h.iOffset(1)
		^tEntries.offset(1)
	}
}{
^if(^form:ciid.int(0) != 0){
	$hPage.sTitle[@ $entryName ^oCalendar.printDateRange[]]
	$hTransactions.0.name[<span>@</span>$entryName]
# 	$hTransactions.0.date[^u:getDateRange[^u:stringToDate[$tEntries.operday]]]
# 	$hTransactions.0.date[^u:formatOperday[$tEntries.operday]]
	$hTransactions.0.value[^u:formatValueByType($tEntries.sum;$hParams.type)]
	$h.iOffset(1)
	^tEntries.offset(1)

}{
	$hPage.sTitle[$hParams.title ^oCalendar.printDateRange[]]
	$hTransactions.0.name[$hParams.title]
# 	$hTransactions.0.date[^u:formatOperday[$tEntries.operday]]
	$hTransactions.0.expandLink[^makeQueryString[
				$.groupid[$form:groupid]
				$.operday[$form:operday]
				$.p[$form:p]
# 				$.type[$hParams.type]
			]]
}
$h.iTotalSum(^dbo:getTotalOut[
	$.startOperday($oCalendar.data.startOperday)
	$.endOperday($oCalendar.data.endOperday)
# 	$.pid($oCalendar.data.pid)
	$.ciid(^form:ciid.int(0))
])
# 	$hTransactions.0.value[^u:formatValue($h.iTotalSum)]
# 	$hTransactions.0.value[^u:formatValue($tEntries.sum)]
}

^for[i](1;^tEntries.count[]-$h.iOffset){
	$hTransactions.$i[^hash::create[]]
	$hCurrent[$hTransactions.$i]

	$hCurrent.tEntries[$tEntries.fields]
	$hCurrent.name[$tEntries.name]
	^if($tEntries.has_children == 0){
		
		$hCurrent.quantity[^u:formatQuantity[$tEntries.quantity]]
		$hCurrent.count_of_transactions[^u:formatQuantity[$tEntries.count_of_transactions]]
		^if(def $tEntries.extraname && $tEntries.count_of_transactions == 1 && def $form:detailed){
			$hCurrent.name[$tEntries.extraname]
		}

		^if(def $tEntries.tiname && ($tEntries.type & $TransactionType:CHEQUE) != $TransactionType:CHEQUE){
			$hCurrent.tiname[$tEntries.tiname]
			$hCurrent.ctid[$tEntries.ctid]
			$hCurrent.ciid[$tEntries.ciid]
		}
	}

$hCurrent.value[^u:formatValueByType($tEntries.sum;$hParams.type)]
$hCurrent.percent[^u:formatValue(100*$tEntries.sum/$h.iTotalSum)]

	^if($tEntries.has_children == 0 &&
		$tEntries.count_of_transactions == 1 &&
		def $hGroups.[$tEntries.tid]){
		$tGroupsForItem[$hGroups.[$tEntries.tid]]
		$hCurrent.groups[
			^tGroupsForItem.menu{<a href="/?groupid=$tGroupsForItem.gid">$tGroupsForItem.name</a>}
		]
	}
	^h.iSum.dec($tEntries.sum)
	^h.dRestQuantity.dec($tEntries.quantity)
	^tEntries.offset(1)
}

^if(^tEntries.count[] == 0){
# 	$hTransactions.0.name[^if(def $entryName){$entryName}{$hParams.title}]
# 	$hTransactions.1[^hash::create[]]
# 	$hTransactions.1.name[Нет $hParams.title2]
# 	$hTransactions.1.no_entries[nodata]
$hTransactions.0.no_entries[nodata]
}
^if($h.iSum > 0.01){
	$iLast(^hTransactions._count[])
	$hTransactions.$iLast[^hash::create[]]
	$hCurrent[$hTransactions.$iLast]
	$hCurrent.isRest(true)
	$hCurrent.name[Прочее в категории $hTransactions.0.name]
	$hCurrent.quantity[$h.dRestQuantity]
	$hCurrent.value[^u:formatValueByType($h.iSum;$hParams.type)]
	$hCurrent.percent[^u:formatValue(100*$h.iSum/$h.iTotalSum)]

}

^printTransactions[$hTransactions;$hParams]

@printTransactions[hTransactions;hParams]
$hTransactions[^hash::create[$hTransactions]]
$hParams[^hash::create[$hParams]]
^rem{
# 	$.name
# 	$.quantity
# 	$.amount
# 	$.amountPercent
# 	$.tid
# 	$.iid
# 	$.hasChildren
# 	$.iCountOfTransactions
# 	$.date

}
<table class="grid" cellspacing="0" cellpadding="0" border="0">


# проверяем наличие "свернутых" элементов
$hasCollapsedItems(false)
^hTransactions.foreach[k;v]{
	^if($k == 0){
		^continue[]
	}
	$hasCollapsedItems($v.tEntries.count_of_transactions > 1 || $v.tEntries.has_children || $v.isRest)
	^if($hasCollapsedItems){
		^break[]
	}
}
# ^u:p[^if($hasCollapsedItems){t}{f}]
$lastOperday[]
^hTransactions.foreach[k;v]{
	^if($k == 0){
		<tr class="$hTransactions.0.no_entries">
			<td class="name">
			<h2>^if(^form:expanded.int(0) == 1){
			<a class="expander" href="/$hTransactions.0.expandLink" title="Свернуть все обратно">&minus^;</a>
		}{
			^if($hasCollapsedItems && !^form:ctid.int(0)){
				<a class="expander" href="/$hTransactions.0.expandLink&expanded=1^if(!^form:p.int(0)){&type=$hParams.type}" title="Развернуть категории">+</a>
			}

		} $v.name <span>$v.date</span>
# 	^if(def $hTransactions.0.expandLink && !^form:detailed.int(0) && !def $hTransactions.1.no_entries){
# 		^if(^form:expanded.int(0) == 1){
# 			<a class="expander" href="/$hTransactions.0.expandLink" title="Свернуть все обратно">&minus^;</a>
# 		}{
# 			^if($hasCollapsedItems){
# 				<a class="expander" href="/$hTransactions.0.expandLink&expanded=1" title="Развернуть категории">+</a>
# 			}

# 		}
# 		}
		</h2>
			</td>
			<td class="quantity"><h2>$v.quantity</h2></td>
			<td class="value"><h2>$v.value</h2></td>
# 			<td class="groups"></td>
			<td class="actions"></td>
		</tr>
	}{
		^if(^form:ciid.int(0) && $oCalendar.data.startDate != $oCalendar.data.endDate){
			^if($lastOperday ne $v.tEntries.operday){
	<tr class="chequedate^if(!def $lastOperday){ first}">
			<td class="name"><a class="dt" href="^makeQueryString[
					$.p[$form:p]
				$.ciid[$form:ciid]
					$.operday[$v.tEntries.operday]
				]"><span>^u:formatOperday[$v.tEntries.operday]</span></a></td>
				<td class="quantity"></td>
				<td class="value"></td>
# 			<td class="groups"></td>
				<td class="actions"></td>
			</tr>
			}
			$lastOperday[$v.tEntries.operday]
		}

		$sLink[]
		$sQuantityLink[]
		$sDate[]
 		^if($v.tEntries.has_children || $v.tEntries.count_of_transactions > 1){
			$_sLink[^makeQueryString[
				$.p[$v.tEntries.iid]
# 				$.type[$hParams.type]
				$.groupid[$form:groupid]
				$.operday[$form:operday]
			]]
			^if($v.tEntries.has_children){
				$sLink[$_sLink]
			}{
			^if($v.tEntries.count_of_transactions > 1){
# 				$sQuantityLink[$_sLink]
				$sQuantityLink[$_sLink&detailed=1]
			}
		}
 		}
		^if(!$v.tEntries.has_children && 
			$v.tEntries.count_of_transactions == 1 &&
			!^form:ciid.int(0) && 
			($oCalendar.data.startDate != $oCalendar.data.endDate) &&
			!$v.isRest &&
			!def $v.no_entries){

			$sDate[<a class="dt" href="^makeQueryString[
				$.p[$form:p]
# 				$.type[$hParams.type]
				$.operday[$v.tEntries.operday]
			]"><span>^u:formatOperday[$v.tEntries.operday]</span></a>]

		}
		^if(def $v.tEntries.parentname){
			$sDate[^if(def $sDate){$sDate }<span class="category">
			<a href="^makeQueryString[
				^if(!^v.tEntries.is_parent_root.int(0)){
					$.p[$v.tEntries.parent_id]
				}
				$.groupid[$form:groupid]
# 				$.type[$hParams.type]
				$.operday[^if(def $form:operday){$form:operday}{$v.tEntries.operday}]
			]">
			<span>$v.tEntries.parentname</span></a></span>]
		}
		^if(def $v.tiname && !^form:ciid.int(0) &&
			!$v.tEntries.has_children && 
			$v.tEntries.count_of_transactions == 1){
			$sDate[^if(def $sDate){$sDate }<span class="cheque"><a href="^makeQueryString[
# 				$.ctid[$v.ctid]
				$.ciid[$v.ciid]
# 				$.type[$hParams.type]
				$.operday[$form:operday]
			]"><span>$v.tiname</span></a>
			</span>]
		}

		<tr class="$v.no_entries^if($v.isRest){ rest}">
		^if(def $sDate){
			$sDate[<div class="date">$sDate</div>]
		}

			<td class="name">
				^if(def $sLink){
					<a href="$sLink"><span>$v.name</span></a>
				}{
					<div class="outer">
					<span>$v.name</span>^if($v.isRest && !^form:expanded.int(0)){ <a class="expander_plain" href="/$hTransactions.0.expandLink&expanded=1^if(!^form:p.int(0)){&type=$hParams.type}" title="Развернуть категории">+</a>}
					$sDate
					</div>
				}


			</td>
			<td class="quantity">^if($v.quantity ne 1 || def $sQuantityLink){$v.quantity}^if(def $sQuantityLink){ (<a href="$sQuantityLink">$v.tEntries.count_of_transactions</a>)}</td>
			<td class="value" title="$v.percent%">
			^if($v.isRest){<span class="a-replacer">
			<div class="bg" style="background-size: $v.percent% 100%"><span>$v.value</span></div></span>}{
			^actions[$v.tEntries;<div class="bg" style="background-size: $v.percent% 100%"><span>$v.value</span></div>]}
# 			<div class="date">^actions[$v.tEntries;Изменить;class="dt"]</div>
# 			<div style="background-size: $v.percent% 100%">$v.value</div>
			</td>
# 			<td class="groups"></td>→
			<td class="actions">^if(!def $v.no_entries && !$v.isRest){^actions[$v.tEntries; ]}</td>
		</tr>
	}
}
</table>


@makeQueryString[hUrlParts][sResult;hUrlParts;k;v]
$hUrlParts[^hash::create[$hUrlParts]]
$sResult[^hUrlParts.foreach[k;v]{^if(def $v){$k=$v}{^if($k eq operday){$k=$oCalendar.data.currentOperday}}}[&]]
^if(def $sResult){
	$result[?$sResult]
}{
	$result[]	
}

@actions[tEntries;sValue;sClass][sUrl]
$sUrl[^makeQueryString[
	$.action[edit]
	^if($tEntries.has_children == 0 && $tEntries.count_of_transactions == 1){
		$.t[$tEntries.tid]
	}
	$.operday[$form:operday]
	$.i[$tEntries.iid]
	$.expanded[$form:expanded]
	$.detailed[$form:detailed]
	$.p[$form:p]
	$.type[$form:type]
# 	$.ctid[$form:ctid]
	$.ciid[$form:ciid]
]]

<a href="$sUrl" class="$sClass">$sValue</a>




