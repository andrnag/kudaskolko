@CLASS
TransactionPreview

@previewTransaction[hTransactions;hNotValid]
$hTransactions[^hash::create[$hTransactions]]
^if($hTransactions && !(^hTransactions._count[] == 1 && $hTransactions.0.isEmpty)){

	$hNotValid[^hash::create[$hNotValid]]
	<table class="grid preview ^if($hNotValid){hasError}" cellpadding="0" cellspacing="0">

	$dtCurrentTransDate[]
	$iShopTransaction[]


	$dCountOfTransactions(0)
	$dCountOfDates(0)
	$dTotalSum(0)
	$isPartial(false)
	^hTransactions.foreach[k;v]{
		
# <hr/>	^v.foreach[kk;vv]{
# 		^if(def $vv){
# 			$kk = 
# 			^if($vv is string || $vv is double ||$vv is int){
# 				$vv
# 			}
# 			^if($vv is bool){
# 				^if($vv){YES}{NO}
# 			}<br/>
# 		}
# 	}

		^if($v.isEmpty || ($v.isCheque && def $iShopTransaction)){
			^previewChequeFooter[]
			$iShopTransaction[]
			$isPartial(false)
			^if($v.isEmpty){
				^continue[]
			}
		}{
			$iShopTransaction[$v.iShopTransaction]
		}
		^if(def $v.dtTransDate && !(def $dtCurrentTransDate && $dtCurrentTransDate == $v.dtTransDate)){
			^dCountOfDates.inc[]
			$dtCurrentTransDate[$v.dtTransDate]
			^if($dCountOfDates > 1){
				<tr class="spacer">
					<td></td>
					<td></td>
					<td></td>
					<td></td>
				</tr>
			}
			<tr class="date">
			^if(def $v.iFoundByIID){
				<td class="name"><h2>
				<span><a href="/?operday=^u:getOperdayByDate[$v.dtTransDate]&p=${v.iFoundByIID}&expanded=1"
				>^u:getDateRange[$v.dtTransDate]</a></span>
				</h2></td>
			}{
				<td class="name"><h2><span>^u:getDateRange[$v.dtTransDate]</span></h2></td>
			}
			<td></td>
			<td></td>
			<td></td>
			</tr>
		}
		^if(^hNotValid.contains[$k]){
			<tr class="error">
			<td class="name">^if(def $v.sName){$v.sName}{^@$v.sChequeName}
			<span class="errorDescription">$hNotValid.$k</span></td>
			<td class="quantity"></td>
			<td class="oldvalue"></td>
			<td class="value"></td>
			</tr>
		}{
			^if($v.isCheque && def $v.sChequeName){
				<tr class="spacer">
					<td></td>
					<td></td>
					<td></td>
					<td></td>
				</tr>
	$isPartial(false)
	$dTotalByChequeWithDisc(^if(def $v.dChequeAmount){$v.dChequeAmount}{$v.dPositionSum})
	$dTotalByChequeWithoutDisc[]
	^if(def $v.dChequeAmount && $v.dChequeAmount != $v.dPositionSum){
		$isPartial($v.dChequeAmount > $v.dPositionSum)
		$dTotalByChequeWithoutDisc(^eval(^math:abs($v.dPositionSum - $v.dChequeAmount)))
	}
			<tr class="chequeheader ^if($isPartial){partial}">
			<td class="name"><h2><span>^@</span>$v.sChequeName</h2></td>
			<td></td>
			<td class="oldvalue">^if(def $dTotalByChequeWithoutDisc){
				<div class="wodisc"><span>^u:formatValueWithoutCeiling($v.dPositionSum)</span></div>
			}</td>
			<td class="value"><div class="wdisc">
			^u:formatValueWithoutCeiling($dTotalByChequeWithDisc)
			</div>
			</td>
			</tr>
			}{
				$sClassName[]
				^if($v.iType & $TransactionType:CHARGE == $TransactionType:CHARGE){
					$sClassName[$sClassName charge]
				} 
				^if($v.iType & $TransactionType:INCOME == $TransactionType:INCOME){
					$sClassName[$sClassName income]
				} 
				^if(def $iShopTransaction){
					$sClassName[$sClassName chequepos ^if($isPartial){partial}]
				}
				^if($v.isResultOfSubTransactions){
					$sClassName[$sClassName resultofsubtransactions]
				}
				^if($v.isSubTransaction){
					$sClassName[$sClassName subtransaction]
				}
				<tr class="$sClassName">
		
				<td class="name">^if($v.isSubTransaction){&minus^; }$v.sName</td>
				<td class="quantity">^if($v.dQuantity != 1){^u:formatQuantity($v.dQuantity)}</td>
				<td class="oldvalue">
				^if($v.dAmountWithoutDisc != $v.dAmount){
					<div class="wodisc"><span>^u:formatValueWithoutCeiling($v.dAmountWithoutDisc)</span></div>
					}</td>
				<td class="value"><div class="wdisc">^u:formatValueWithoutCeiling($v.dAmount)</div></td>

				</tr>

				^dTotalSum.inc($v.dAmount)
				^dCountOfTransactions.inc[]
			}
		}

	}
	^previewChequeFooter[]

	^if($dCountOfTransactions > 1){
		<tr class="spacer">
			<td></td>
			<td></td>
			<td></td>
			<td></td>
		</tr>
		<tr class="total">
			<td class="name">Итого</td>
			<td></td>
			<td></td>
			<td class="value">^u:formatValueWithoutCeiling($dTotalSum)</td>
		</tr>
	}{
		<tr class="spacer">
			<td></td>
			<td></td>
			<td></td>
			<td></td>
		</tr>
	}


	</table>
	
}

@previewChequeFooter[]
^if(def $caller.iShopTransaction){

$dChequeAmount[$caller.hTransactions.[$caller.iShopTransaction].dChequeAmount]
$dPositionSum[$caller.hTransactions.[$caller.iShopTransaction].dPositionSum]
	^if(def $dChequeAmount && $dChequeAmount != $dPositionSum){
		<tr class="chequefooter ^if($dChequeAmount > $dPositionSum){partial}">
			<td class="name">^if($dChequeAmount > $dPositionSum){Наценка}{Скидка}</td>
			<td></td><td></td>
			<td class="value">^u:formatValueWithoutCeiling(^math:abs($dPositionSum - $dChequeAmount))</td>
		</tr>
	}
# 	<tr class="chequefooter last">
# 		<td class="name">Итого по чеку</td>
# 		<td></td><td></td>
# 		<td class="value">^u:formatValueWithoutCeiling(^if(def $dChequeAmount){$dChequeAmount}{$dPositionSum})</td>
# 	</tr>
	<tr class="chequefooter last">
		<td class="name"></td>
		<td></td>
		<td class="value"></td>
		<td class="value"></td>
	</tr>

	<tr class="spacer">
		<td></td>
		<td></td>
		<td></td>
		<td></td>
	</tr>
}