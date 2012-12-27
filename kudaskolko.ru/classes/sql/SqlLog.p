﻿###########################################################################
# $Id: SqlLog.p,v 2.3 2007/10/16 13:11:29 misha Exp $
###########################################################################


@CLASS
SqlLog



###########################################################################
@auto[]
$sClassName[SqlLog]
#end @auto[]



###########################################################################
@create[oSql]
^if(!def $oSql){
	^throw[$sClassName;^$oSql must be specified.]
}
^if(!($oSql is "Sql")){
	^throw[$sClassName;Unknown type for ^$oSql.]
}
$self.oSql[$oSql]
$self.oSqlInfo[$oSql.oSqlInfo]
#end @create[]



###########################################################################
@log[hParam][sFileName;sLog]
$hParam[^hash::create[$hParam]]
$sFileName[^if(def $hParam.sFile){$hParam.sFile}{$hParam.file}]
^if($oSqlInfo.hQuery && def $sFileName){
	$sLog[^taint[as-is][^self.print[$hParam]]]
	^if(def $sLog){
		^if($hParam.bAll){
			^sLog.save[$sFileName]
		}{
			^sLog.save[append;$sFileName]
		}
	}
}
$result[]
#end @log[]



###########################################################################
@print[hParam][hLimit;sProblemQueries;bTooManyQueries;iNum]
$result[]
$hParam[^hash::create[$hParam]]
^if($oSqlInfo.hQuery){
	$hLimit[
		$.iQueries(^hParam.iQueriesLimit.int(0))
		$.iTime(^hParam.iQueryTimeLimit.int(0))
		$.iRows(^hParam.iQueryRowsLimit.int(3000))
	]
	^self._analizeQueries[$hLimit;$hParam]
	
	$bTooManyQueries($hLimit.iQueries && $oSqlInfo.hStat.TOTAL.iCount > $hLimit.iQueries)
	$sProblemQueries[^for[iNum](1;$oSqlInfo.hStat.TOTAL.iCount){^if(def $oSqlInfo.hQuery.$iNum && ($hParam.bAll || $oSqlInfo.hQuery.[$iNum].hExceed.bAny || ($bTooManyQueries && $hParam.bExpandExceededQueriesToLog))){^_printQueryInfo[$oSqlInfo.hQuery.$iNum;$hLimit]}}]
	
	^if($hParam.bAll || def $sProblemQueries){
		$result[^self._printLogRecord[$sProblemQueries;$hLimit;$hParam]]
	}
}
#end @print[]



###########################################################################
@_printLogRecord[sBody;hLimit;hParam][hDivider]
$hDivider[^self._getDividers[]]
^oSqlInfo.tType.sort($oSqlInfo.hStat.[$oSqlInfo.tType.name].iCount)[desc]

$result[^taint[as-is][^if(!$hParam.bAll){$hDivider.sHead
}TIME: ^oSql.dtNow.sql-string[], METHOD: $env:REQUEST_METHOD, URL: http://${env:SERVER_NAME}$request:uri
LIMITS: Max queries count: $hLimit.iQueries, Max query rows: $hLimit.iRows, Max query time: $hLimit.iTime ms
Connections: $oSqlInfo.iConnectionsCount

^oSqlInfo.tType.menu{^self._printLine[$oSqlInfo.tType.name]}[
]
$hDivider.sQuery
^self._printLine[TOTAL]^if($hLimit.iQueries && $oSqlInfo.hStat.TOTAL.iCount > $hLimit.iQueries){ [queries limit exceeded]}^if(def $sBody){

$sBody}

]]
#end @_printLogRecord[]



###########################################################################
@_getDividers[][i;result]
$result[
	$.sHead[^for[i](1;50){=}]
	$.sQuery[^for[i](1;50){-}]
]
#end @_getDividers[]



###########################################################################
@_printQueryInfo[hQueryInfo;hLimit]
$result[TYPE: $hQueryInfo.hOption.sType^if($hQueryInfo.hStat){
INFO: ^self._printStat[$hQueryInfo.hStat]^if($hQueryInfo.hExceed.bTime){ [time limit exceeded]}}^switch[$hQueryInfo.hOption.sType]{
	^case[table;hash]{^#0AROWS: $hQueryInfo.iRowsCount^if($hQueryInfo.hExceed.bRows){ [rows limit exceeded]}}
	^case[int;double;file]{^#0ARESULT: $hQueryInfo.sResult}
	^case[string]{^#0ARESULT: '$hQueryInfo.sResult'}
	^case[void]{}
}^if(def $hQueryInfo.hOption.hSql){^#0AOPTIONS: ^self._printOptions[$hQueryInfo.hOption.hSql]}
QUERY:
^self._normalize[$hQueryInfo.hOption.sQuery]^if(def $hQueryInfo.sDetails){^#0A$hQueryInfo.sDetails}


]
#end @_printQueryInfo[]



###########################################################################
@_printOptions[hOption][sKey;uValue]
$result[^hOption.foreach[sKey;uValue]{^$.$sKey^try{^if($uValue is "int" || $uValue is "double"){^($uValue^)}{^if($uValue is "string"){^[$uValue^]}{[unexpected type]}}}{^if(!^exception.comment.pos[junction]){$exception.handled(1)^{junction^}}}}[ ]]
#end @_printOptions[]



###########################################################################
@_printLine[sName][result]
$result[^if($oSqlInfo.hStat.[$sName].iCount){$sName		$oSqlInfo.hStat.[$sName].iCount^if($oSql.bDebug){		[^self._printStat[$oSqlInfo.hStat.[$sName]]]}}]
#end @_printLine[]



###########################################################################
@_printStat[hStat][result]
$result[$hStat.dTime ms/$hStat.iMemoryKB KB/$hStat.iMemoryBlock blocks]
#end @_printStat[]



###########################################################################
@_normalize[sQuery][result]
$result[$sQuery]
^if(def $result){
	$result[^result.match[\s+][g]{ }]
	$result[^result.match[\s(?=,)][g]{}]
	$result[^result.trim[]]
}
#end @_normalize[]



###########################################################################
@_analizeQueries[hLimit;hParam][tList;iNum;hQueryInfo]
$tList[^table::create{iNum}]
^oSqlInfo.hQuery.foreach[iNum;hQueryInfo]{
	^if(!$hQueryInfo.hExceed){
		$hQueryInfo.hExceed[^self._getExceedes[$hQueryInfo;$hLimit]]
		^if($hParam.bAll || $hQueryInfo.hExceed.bAny){
			^tList.append{$iNum}
		}
	}
}
^if($tList){
	^oSql.server{
		^tList.menu{
			$oSqlInfo.hQuery.[$tList.iNum].sDetails[^oSql.getQueryDetail[$oSqlInfo.hQuery.[$tList.iNum].hOption.sType;$oSqlInfo.hQuery.[$tList.iNum].hOption.sQuery;$oSqlInfo.hQuery.[$tList.iNum].hOption.hSql]]
		}
	}
	^oSqlInfo.storeConnectionInfo(-1)
}
$result[]
#end @_analizeQueries[]



###########################################################################
@_getExceedes[hQueryInfo;hLimit][bTime;bRows]
$bTime($hLimit.iTime && $hQueryInfo.hStat && $hQueryInfo.hStat.dTime >= $hLimit.iTime)
$bRows($hLimit.iRows && $hQueryInfo.iRowsCount >= $hLimit.iRows)
$result[
	$.bTime($bTime)
	$.bRows($bRows)

	$.bAny($bTime || $bRows)
]
#end @_getExceedes[]





