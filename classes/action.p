@CLASS
action

@OPTIONS
locals

@create[hParams]
$self.hPage[$hParams.hPage]
$self.USERID(^hParams.USERID.int(0))

@action[sAction]
^makeHTML[;
^switch[$sAction]{

	^case[move_category]{
		^moveCategory[]
	}
	^case[rename_category]{
		^renameCategory[]
	}
	^case[change_transaction_details]{
		^changeTransactionDetails[]
	}
	^case[delete_transaction]{
		^deleteTransaction[]
	}
	^case[edit]{
		^if(^form:t.int(0)){
			^editTransaction[]
		}{
			^editCategory[]
		}
	}
	^case[DEFAULT]{
		Неизвестная операция $sAction
	}
}

]

@editTransaction[]
<div class="actions">
^moveCategory[]
^renameCategory[]
^changeTransactionDetails[]
^deleteTransaction[]
</div>

@editCategory[]
<div class="actions">
^moveCategory[]
^renameCategory[]
</div>

@changeTransactionDetails[]
^rem{
изменить только эту (просто поменять iid и перепроверить дубликаты)
изменить все транзакции с таким iid и создать алиас, сослаться на него в транзакциях
 (затем перепроверить дубликаты для всех транзакций с таким alias_id)

}
^if((^u:stringToDouble[$form:amount] && ^u:stringToDouble[$form:quantity]) && def $form:transactionDate){

	$d[^u:stringToDate[$form:transactionDate]]

	^oSql.void{
		UPDATE transactions
		SET
			amount = ^u:stringToDouble[$form:amount],
			quantity = ^u:stringToDouble[$form:quantity],
			tdate = '^d.sql-string[]',
			operday = ^u:getOperdayByDate[$d]
		WHERE tid = ^form:t.int(0) AND user_id = $self.USERID
	}
	^if(^form:ctid.int(0)){
	 	^oSql.void{
	 		UPDATE transactions
	 		SET
	 			tdate = '^d.sql-string[]',
				operday = ^u:getOperdayByDate[$d]
	 		WHERE
	 			user_id = $self.USERID
	 			AND
	 			(ctid = ^form:ctid.int(0)
	 			OR tid = ^form:ctid.int(0))
	 	}
 	}
#	^u:p[^goBack[]]
$response:location[^goBack[
$.operday[^u:getOperdayByDate[$d]]
^if(^form:ctid.int(0)){
	$.p[]
}
]]
#$iLevel(^oSql.int{SELECT level from nesting_data WHERE iid = $iItemID}[$.limit(1)$.default(0)])
#$iParent(^oSql.int{SELECT pid from items WHERE iid = $iItemID}[$.limit(1)$.default(0)])
#	$response:location[^goBack[$.parentid[$iParent]$.level[$iLevel]]]


}{
$tTransaction[^oSql.table{
SELECT t.amount, t.quantity, i.name, t.tdate, t.ctid
	FROM transactions t
	LEFT JOIN transactions cheque ON cheque.tid = t.ctid
	LEFT JOIN items i ON i.iid = cheque.iid
	WHERE t.tid = ^form:t.int(0)
	AND t.user_id = $self.USERID

	}]
^if(def $tTransaction){
<div class="action" id="actionEditTransactionDetails">
<h2>Изменить детали</h2>
	<form action="/" method="get">
^printGoBackFields[
	$.action[change_transaction_details]
	$.t[^form:t.int(0)]
	$.i[$form:i]
]

$sDate[^dtf:format[%e %h %Y;$tTransaction.tdate;$dtf:rr-locale]]
^if(^tTransaction.ctid.int(0)){
	<input type="hidden" name="ctid" value="^tTransaction.ctid.int(0)" />
}
<div>
<input type="text" name="quantity" value="$tTransaction.quantity" oldValue="$tTransaction.quantity" size="4"/> шт. на сумму 
<input type="text" name="amount"value="$tTransaction.amount" oldValue="$tTransaction.amount" size="10" id="IDTransactionAmount"/> рублей 
<input type="text" name="transactionDate" value="$sDate" size="15" id="IDTransactionDate" date="$sDate" oldValue="$sDate"/>


^if(def $tTransaction.name){^@$tTransaction.name}
<input type="submit" value="Изменить"/>
</div>

# ^dtf:format[%e %h%W;$tTransaction.tdate;$dtf:rr-locale]
# 	<h1>$tTransaction.name</h1>
# 	Сумма * количество для транзакции<br/>
# 	<input type="text" name="amount" value="$tTransaction.amount" /> * 
# 	<input type="text" name="quantity" value="$tTransaction.quantity" />
# 	<input type="submit" value="Изменить"/>
	</form>
</div>
}{
	Транзакция не найдена
}
}


@deleteTransaction[]

^if(def $form:delete_confirmed){
	^dbo:deleteTransaction[
		$.tid(^form:t.int(0))
		$.iid(^form:i.int(0))
		$.isDeleteCheque(^form:delete_cheque.int(0))
	]
	$response:location[^goBack[]]
}{
	$tCheckName[^oSql.table{
	SELECT CONCAT('@', i.name) AS name
		FROM transactions t 
		LEFT JOIN transactions ct ON t.ctid = ct.tid
		LEFT JOIN items i ON i.iid = ct.iid
		WHERE 
		t.tid = ^form:t.int(0)
		AND t.ctid != 0
		AND t.user_id = $self.USERID
	}[$.limit(1)]]

<div class="action" id="actionDeleteTransaction">	
	<form action="/" method="get">
^printGoBackFields[
	$.action[delete_transaction]
	$.delete_confirmed[true]
	$.t[^form:t.int(0)]
	$.i[^form:i.int(0)]
]
	<h2><span class="operamini">Удалить запись</span>
	<span id="IDDeleteConfirm" class="notoperamini">Удалить запись...</span>
# 	<span id="IDDeleteCancel" class="notoperamini">Нет, мы передумали</span>
	</h2>
	<div class="controls">
 		<input type="submit" value="Да, удалить"/>
 		^if($tCheckName){
	 		<input type="checkbox" id="IDDeleteCheque" name="delete_cheque" value="1"/><label for="IDDeleteCheque">Удалить весь чек $tCheckName.name</label>
 		}
	</div>
	</form>

</div>	
}

@renameCategory[]
# в первой версии будет простое техническое переименование 
# с запретом на совпадение с существующими категориями и без алиасов

^rem{
сделать аналогично изменению категории транзакции

1. Переименовать для всех (и создать алиас) = изменение категории транзакции
Переименовать все записи с названием "Оплата яндекс-деньгами"
2. Тупо переименовать (скорее техническая возможность)
}
$tValues[^oSql.table{
^if(^form:t.int(0)){
		SELECT
			i.name,
			COUNT(*) AS countOfEntries,
			i.type
		FROM transactions t
		LEFT JOIN items i ON t.iid = i.iid
		LEFT JOIN nesting_data nd ON nd.pid = i.iid
		WHERE
			t.iid = ^form:i.int(0)
			AND t.user_id = $self.USERID
		GROUP BY t.iid
}{
		SELECT 
			i.name,
			0 AS countOfEntries,
			i.type
		FROM items i
		WHERE 
			i.iid = ^form:i.int(0)
			AND i.user_id = $self.USERID
}
}[$.limit(1)]]

# $sCurrentName[^string:sql{SELECT i.name FROM items i WHERE i.iid = ^form:i.int(0)}[$.limit[1]]]
$self.hPage.sTitle[$tValues.name]
^if(def $form:newCategoryName && ^form:newCategoryName.trim[] ne ""){
^rem{
	
	if all update name, createalias
	if only
	if(forall){
		if(newcategory in this parent exist){
			update iid
			update aliasId

			если категория уже алиас, брать ее родителя
			подарок -> подарки
			подарок2 -> подарок -> подарки
		}{
			create new category
			update iid 
			update aliasid
		}
	}{
	
	}
}


#	$iItemID(^createItemAndReturnIfNotExist[^form:path.trim[]])
	$iid(^form:i.int(0))
	^if(^form:newCategoryName.trim[] ne $tValues.name){
		$tNewCategory[^oSql.table{
			SELECT
				i.iid,
				i.pid
			FROM nesting_data current
				LEFT JOIN nesting_data parents ON parents.iid = current.pid
				LEFT JOIN nesting_data siblings ON siblings.pid = parents.iid
				LEFT JOIN items i ON siblings.iid = i.iid					
			WHERE 
				current.user_id = $self.USERID AND
# 				где текущая категория
				current.iid = ^form:i.int(0) AND
# 				Искомое название
				i.name = '^form:newCategoryName.trim[]' AND
# 				исключить текущую категорию из результатов
				siblings.iid <> current.iid AND
# 				использовать только первого родителя
				parents.iid = parents.pid	AND
				parents.level = current.level-1 AND
# 				вывести братьев и первого родителя
				(current.level = siblings.level OR siblings.level = parents.level )

			}[$.limit(1)]]

# 	$newNameID(^oSql.int{SELECT iid FROM items WHERE name = '^form:newCategoryName.trim[]'}[$.limit(1)$.default(0)])
		^if($tNewCategory){
			^if(!^form:t.int(0) || ^form:createAlias.int(0)){
# временно отключаем алиасы до уточнения как с ними работать 
#(переименовали категорию, создали алиас, затем эту категорию еще раз переименовали - 
# алиас остался работать на старый вариант категории)				
# 				^oSql.void{
# 					UPDATE items SET alias_id = $newNameID WHERE iid = ^form:i.int(0)
# 				}

# временно просто сливаем категории
				^oSql.void{
					UPDATE transactions
					SET ^rem{alias_id = iid,}
					iid = $tNewCategory.iid
					WHERE iid = ^form:i.int(0)
					AND user_id = $self.USERID
				}

				$tMovedCategories[^oSql.table{
					SELECT iid FROM items
					WHERE pid = ^form:i.int(0)
					AND user_id = $self.USERID
					}]
				^if($tMovedCategories){
					^oSql.void{
						UPDATE items
						SET ^rem{alias_id = iid,}
						pid = $tNewCategory.iid
						WHERE pid = ^form:i.int(0)
						AND user_id = $self.USERID
					}
					^dbo:rebuildNestingDataLocal[
						$.iid[$tMovedCategories]
						$.pid($tNewCategory.iid)
					]
				}
				^dbo:deleteItem[$.iid(^form:i.int(0))]
			}{
				^oSql.void{
					UPDATE transactions
					SET iid = $tNewCategory.iid
					WHERE tid = ^form:t.int(0)
					AND user_id = $self.USERID
				}
			}
			$iid($tNewCategory.iid)
		}{
			^if(^form:createAlias.int(0)){
				^oSql.void{
					UPDATE items 
					SET name = '^u:capitalizeString[^form:newCategoryName.trim[]]' 
					WHERE iid = ^form:i.int(0)
					AND user_id = $self.USERID
				}
			}{

				$hItem[^dbo:createItem[
					$.name[^u:capitalizeString[^form:newCategoryName.trim[]]]
					$.iid(^form:i.int(0))
				]]
				^oSql.void{
					UPDATE transactions
					SET iid = $hItem.tValues.iid
					WHERE tid = ^form:t.int(0)
					AND user_id = $self.USERID
				}
				$iid($hItem.tValues.iid)
			}


		}
	}
	$response:location[^goBack[$.i($iid)$.p($iid)]]

}{
<div id="actionRename" class="action">
# ^printBreadScrumbs(^form:i.int(0))

<form action="/" method="get">
^printGoBackFields[
	$.action[rename_category]
	$.i[$form:i]
	$.t[$form:t]
	$.expanded(1)
	$.detailed[]
]

$value(^if((def $tValues.countOfEntries && $tValues.countOfEntries > 1) 
	|| 
	($tValues.type & $TransactionType:CHARGE == $TransactionType:CHARGE)
	|| 
	($tValues.type & $TransactionType:INCOME == $TransactionType:INCOME) ){0}{1})

<h2>Переименовать 
^if(def $tValues.countOfEntries && $tValues.countOfEntries > 1){
	<span class="operamini"><input type="checkbox" id="IDCreateAlias" name="createAlias" value="$value" ^if($value){checked="checked"}><label for="IDCreateAlias">все записи с таким именем</label></span>
	<span class="notoperamini" id="IDCreateAliasSpan">только эту запись</span>
}{
	<input type="hidden" id="IDCreateAlias" name="createAlias" value="$value"/>
}
</h2>
# <h1 class="categoryName"><span>$sCurrentName</span></h1>
<div class="controls">
<input type="text" name="newCategoryName" size="50" id="IDNewCategoryName" value="$tValues.name" oldValue="$tValues.name"/> <input type="submit" value="Переименовать"/>
# <div><input type="hidden" id="IDCreateAlias"  name="createAlias" value="1">
# <label for="IDCreateAlias">Переименовать все записи с таким именем</label></div>

# <div><input type="checkbox" id="IDCreateAlias" name="createAlias" value="1"><label for="IDCreateAlias">Автоматически переименовывать новые записи</label></div>

# <div><span id="IDRenameOnlyEntry" class="active"><u>эту запись</u></span> или <span id="IDRenameAllEntries"><u>все записи с таким именем (123)</u></span></div>
</div>

</form>

</div>
}

@printBreadScrumbs[iid]
<ul class="breadscrumbs inaction">
$tParents[^dbo:getParentItems[$.iid($iid)]]
# ^if(!$tParents && (^form:type.int(0) && !^form:p.int(0))){
# <li><a href="^makeQueryString[
# 				$.groupid[$form:groupid]
# 				$.operday[$form:operday]
# 				^if(!^form:p.int(0)){
# 					$.expanded[$form:expanded]
# 					$.detailed[$form:detailed]
# 				}
# 			]">Расходы и доходы</a></li>
# }
^tParents.menu{
^if(^tParents.line[] == ^tParents.count[]){
	
# ^if((^form:expanded.int(0) || ^form:detailed.int(0)) && ^form:p.int(0) == $tParents.iid){
<li><a href="^makeQueryString[
				$.groupid[$form:groupid]
				$.operday[$form:operday]
				^if($tParents.level != 0){
					$.p[$tParents.iid]
# 					$.type[$form:type]
				}
# 				^if($tParents.iid == ^form:p.int(0)){
# 					$.expanded[$form:expanded]
# 					$.detailed[$form:detailed]
					$.expanded[1]
# 				}
			]">$tParents.name</a></li>
# }{
# 	<li>$tParents.name</li>
# }


}{

	<li><a href="^makeQueryString[
				$.groupid[$form:groupid]
				$.operday[$form:operday]
				^if($tParents.level != 0){
					$.p[$tParents.iid]
# 					$.type[$form:type]
				}
# 				^if(!^form:p.int(0) || $tParents.iid == ^form:p.int(0)){
					$.expanded[$form:expanded]
# 					$.detailed[$form:detailed]
# 				}
			]">$tParents.name</a></li>
#^if(^tParents.line[] < (^tParents.count[]-1)){→}
}
}
</ul>



@moveCategory[]

^if(def $form:path){

^if(!(^form:expanded.int(0) || ^form:detailed.int(0))){	
	$tParent[^oSql.table{
		SELECT
			current.name currentname,
			parent.name parentname,
			parent.iid parent_id,
			parent_nd.type parent_type,
			IFNULL(parent.type,0) is_root
		FROM items current
		LEFT JOIN items parent ON parent.iid = current.pid
		LEFT JOIN nesting_data parent_nd ON parent_nd.iid = parent.iid 
		WHERE current.iid = ^form:i.int(0) AND parent_nd.iid = parent_nd.pid
		AND current.user_id = $self.USERID
	}]
}
	<div class="action" id="actionMove">


	$cookie:lastcategory[$form:path]
	$tPath[^form:path.split[,;;p]]
$iFinalItemID(0)
^if($tPath > 1){
	$iFinalItemID(0)
	^tPath.menu{
		^if(def ^tPath.p.trim[]){
			^if(^tPath.line[] == 1){
				$hItem[^dbo:createItem[$.name[^u:capitalizeString[^tPath.p.trim[]]]]]
			}{
				$hItem[^dbo:createItem[$.name[^u:capitalizeString[^tPath.p.trim[]]]$.pid[$iFinalItemID]]]

			}

			$iFinalItemID($hItem.tValues.iid)
		}
	}
}{
	$hItem[^dbo:createItem[$.name[^u:capitalizeString[^form:path.trim[]]]$.iid[^form:i.int(0)]]]
	$iFinalItemID($hItem.tValues.iid)
}

	$tExistIid(^oSql.int{
		SELECT i.iid FROM items i
		LEFT JOIN items i2 ON i2.name = i.name
		WHERE
		i.user_id = $self.USERID
		AND i.pid = $hItem.tValues.pid
		AND i2.iid = ^form:i.int(0)
		AND i.iid <> i2.iid
		}[$.limit(1)
		$.default(0)])
	^if($tExistIid != 0){
		$iFinalItemID($tExistIid)
		^oSql.void{
			UPDATE transactions SET iid = $iFinalItemID 
			WHERE iid = ^form:i.int(0)
			AND user_id = $self.USERID
		}

		^dbo:deleteItem[$.iid(^form:i.int(0))]

	}{
		^dbo:moveCategory[
			$.iid(^form:i.int(0))
			$.pid($iFinalItemID)
		]
	}

$response:location[^goBack[
^if(!(^form:expanded.int(0) || ^form:detailed.int(0))){
	^if(!^tParent.is_root.int(0)){

		$.p[$tParent.parent_id]
# 		$.type[$tParent.parent_type]
	}
}

]]

# $iLevel(^oSql.int{SELECT level from nesting_data WHERE iid = ^form:i.int(0)}[$.limit(1)$.default(0)])
#	$response:location[^goBack[]]
# 	<a href="^goBack[	$.type(^oSql.int{SELECT i.type 
# 		FROM items i
# 		LEFT JOIN nesting_data nd ON nd.pid = i.iid
# 		WHERE nd.iid = $iFinalItemID AND i.type IS NOT NULL AND i.user_id = $self.USERID})]">перейти к новому  назад</a>
#	$response:location[^goBack[$.parentid[$hItem.tValues.iid]$.level[$iLevel]]]
# <div class="back"><- <a href="">Расходы</a></div>
# <div class=""><b>Чай зеленый</b> теперь в категории <a href="">Чай</a> -></div>

# 	переместить туда же следующие записи:
# 	<ul>
# 		<li>Вернуться в Расходы</li>
# 		<li>Перейти в Доходы, Новая категория</li>
# 		<li>Переместить в категорию Новая категория следующие записи:
# 			<ul>
# 				<li><input type="checkbox" id="id1"/><label for="id1">Картошка соленая</label></li>
# 				<li><input type="checkbox" id="id2"/><label for="id2">Молоко топленое</label></li>
# 				<li><input type="checkbox" id="id3"/><label for="id3">Сгущенка вареная</label></li>
# 			</ul>
# 		</li>
# 	</ul>
}{
	^printBreadScrumbs(^form:i.int(0))
	<div class="action" id="actionMove">
	<form action="/" method="get">
^printGoBackFields[
	$.action[move_category]
	$.i[$form:i]

]
# <h2><span></span></h2>
# <button>Переместить в категорию <b>Зарплата</b></button>
	<h2>Переместить в категорию</h2>
#	^getPath(^form:itemid.int(0))
#	<input type="text" name="path" value="^getPath(^form:itemid.int(0))" />
	<input type="text" name="path" id="IDNewCategory" size="50" value="$cookie:lastcategory" /> <input type="submit" value="Переместить →"/>
	</form>
}
</div>


@getPath[iItemID]
$tParents[^dbo:getParentItems[$.iid($iItemID)]]
$result[^tParents.menu{$tParents.name}[/]]


@getGoBackFields[]
$result[
$.p[$form:p]
$.operday[$form:operday]
	$.type[$form:type]
	$.expanded[$form:expanded]
	$.detailed[$form:detailed]
	$.ciid[$form:ciid]
]



@makeQueryString[hUrlParts]
$hUrlParts[^hash::create[$hUrlParts]]
$sResult[^hUrlParts.foreach[k;v]{^if(def $v){$k=$v}{^if($k eq operday){$k=$oCalendar.data.currentOperday}}}[&]]
^if(def $sResult){
	$result[?$sResult]
}{
	$result[]	
}

@goBack[hFields]
$hResult[^getGoBackFields[]]
# $hInput[^hash::create[$hFields]]
^hResult.add[^hash::create[$hFields]]
# $sResult[^hResult.foreach[k;v]{$k=$v}[&]]
$sResult[^makeQueryString[$hResult]]
^if(def $sResult){
	$result[$MAIN:MONEY.SERVER_HOST/$sResult]
}{
	$result[$MAIN:MONEY.SERVER_HOST/]
}

@printGoBackFields[hFields]
$hResult[^getGoBackFields[]]
$hInput[^hash::create[$hFields]]
^hResult.add[$hInput]
^hResult.foreach[k;v]{
	^if(def $v){
		<input type="hidden" name="$k" value="$v"/>
	}
}
