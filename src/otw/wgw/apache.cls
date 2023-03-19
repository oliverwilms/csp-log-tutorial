Class otw.wgw.apache Extends %Persistent
{

Property iWebgateway As %String(MAXLEN = 9999) [ SqlColumnNumber = 2 ];

Property LogDate As %Date;

Property LogTime As %Time;

Property Text As %String(MAXLEN = 999999);

Property P1 As %String(MAXLEN = 9999);

Property P2 As %String(MAXLEN = 9999);

Property P3 As %String(MAXLEN = 9999);

Property P4 As %String(MAXLEN = 9999);

Property P5 As %String(MAXLEN = 9999);

Property P6 As %String(MAXLEN = 9999);

Property P7 As %String(MAXLEN = 9999);

Property P8 As %String(MAXLEN = 9999);

Property P9 As %String(MAXLEN = 9999);

Property zFilename As %String(MAXLEN = 9999);

Method CalcDateTime() As %String
{
	Set tVal = ""
	Set tDetails = ..P4
	Set tFirst = $Extract(tDetails,1)
	If (tFirst = "[") Set tDetails = $Extract(tDetails,2,*)
	If (tDetails ? 1.2N1"/"1.3A1"/"1.4N1":".E) {
		Set tDate = $Piece(tDetails,":",1)
		Try {
			Set tDateH = $ZDateH($Translate(tDate,"/"," "),8)
			Set ..LogDate = tDateH
			Set temp = $Piece(tDetails,":",2,*)
			If (temp ? 1.2N1":"1.2N1":"1.2N.E) {
				Set tTime = $Piece(temp," ",1)
				Set tTimeH = $ZTimeH(tTime)
				Set ..LogTime = tTimeH
			}
		} Catch {}
	}
	Quit tVal
}

Method CalcFilename() As %String
{
	Set tVal = ""
	Set tDetails = ..P5
	If (tDetails [ "?FILENAME=") {
		Set temp = $Piece(tDetails,"?FILENAME=",2)
		Set tVal = $Piece(temp," ",1)
	}
	Set ..zFilename = tVal
	Quit tVal
}

ClassMethod ExtractFromText(pText As %String = "", ByRef pFrom As %Integer = 1) As %String
{
	Set q = """"
	Set tDelim = " "
	Set tFirst = $Extract(pText,pFrom)
	Set tPiece = 1
	If (tFirst = q) {
		Set tDelim = q
		//Set tPiece = 1
		Set pFrom = pFrom + 1  // skip leading quote
	}
	If (tFirst = "[") {
		Set tDelim = "]"
		Set pFrom = pFrom + 1  // skip leading [
	}
	Set temp = $Extract(pText,pFrom,*)
	Set tVal = $Piece(temp,tDelim,tPiece)
	If (tDelim = " ") {
		Set pFrom = pFrom + $Length(tVal) + 1  // one for next space
	}
	If (tDelim '= " ") {
		Set pFrom = pFrom + $Length(tVal) + 2  // two for delim plus next space
	}
	Quit tVal
}

ClassMethod ImportLine(pLine As %String = "", pWebgateway As %String, ByRef pFilter, pImport = 1) As %Status
{
	Set tSC = $$$OK
	Set pMaxDateH = $Get(pFilter("pMaxDateH"),-1)
	Set pMinDateH = $Get(pFilter("pMinDateH"),0)
	Set pLogDate = ""
	Set pLogText = pLine
	If (pMaxDateH > -1) {
		If ($Get(pLogDateH) > pMaxDateH) Set pSkip = 1
		If ($get(pLogDateH) = pMaxDateH) {
			Set pMaxTime = $Get(pFilter("pMaxTime"),"24")
			If ..TimesCompareIsBefore(pMaxTime,$Get(pLogTime)) Set pSkip = 1
		}
	}
	If (pMinDateH > 0) {
		If ($Get(pLogDateH) < pMinDateH) Set pSkip = 1
		If ($Get(pLogDateH) = pMinDateH) {
			Set pMinTime = $Get(pFilter("pMinTime"),"")
			If ..TimesCompareIsBefore($Get(pLogTime),pMinTime) Set pSkip = 1
		}
	}
	If ($Get(pSkip)) { Quit 0 }
	Set pLog = ..%New()
	Set pLog.iWebgateway = $Get(pWebgateway)
	If ($Get(pLogDateH) '= "") Set pLog.LogDate = pLogDateH
	//If ($Get(pLogTimeH) '= "") Set pLog.LogTime = pLogTimeH
	If ($Get(pLogTime) '= "") Set pLog.LogTime = pLogTime
	If ($Get(pLogText) '= "") Set pLog.Text = pLogText

	Set pLength = $Length(pLine)
	Set pFrom = 1
	For ii = 1:1 {
		Set pNext = ..ExtractFromText(pLine,.pFrom)
		If (ii = 1) Set pLog.P1 = pNext
		If (ii = 2) Set pLog.P2 = pNext
		If (ii = 3) Set pLog.P3 = pNext
		If (ii = 4) Set pLog.P4 = pNext
		If (ii = 5) Set pLog.P5 = pNext
		If (ii = 6) Set pLog.P6 = pNext
		If (ii = 7) Set pLog.P7 = pNext
		If (ii = 8) Set pLog.P8 = pNext
		If (ii = 9) Set pLog.P9 = pNext
		If (pFrom > pLength) { Quit }
		If (pLength < ii) { Quit }
	}

	
	If pImport {
		Set x = pLog.CalcDateTime()
		Set x = pLog.CalcFilename()
		Set tSC = pLog.%Save()
	}
	If $$$ISERR(tSC) {
		Set x = $System.Status.GetErrorText(tSC)
		Set ^TESTlog($I(^TESTlog)) = x
	}
	Quit tSC
}

ClassMethod ImportMessages(pFile As %String, ByRef pLines, ByRef pFilter = -1, pImport = 11, pDebug = 0) As %Status
{
	If pDebug {
		Write "Import Messages begins at ",$ZDATETIME($HOROLOG),!
	}
	Set tSC = $$$OK
	If (pImport > 2) {
		Set tSC = ..%DeleteExtent()
	}
	If $$$ISERR(tSC) {
		Set x = $System.Status.GetErrorText(tSC)
		If pDebug Write x,!
		Set ^TESTlog($I(^TESTlog)) = x
	}
	If ($Get(pFile) = "") {
		Set mgrDir = $ZU(12)
		Set pFile = mgrDir_"/csplog/access.log"
	}
	Set tSC = ..ReadLogLines(pFile,.pLines,.pFilter,pImport)
	If $$$ISERR(tSC) {
		Set x = $System.Status.GetErrorText(tSC)
		If pDebug Write x,!
		Set ^TESTlog($I(^TESTlog)) = x
	}
	If pDebug {
		Write "Import Messages ends at ",$ZDATETIME($HOROLOG),!
	}
	Quit tSC
}

ClassMethod ReadLogLines(pFile As %String, ByRef pLines, ByRef pFilter = 10, pImport = 1, pDebug = 0) As %String
{
	Write:pDebug "ReadLogLines",!
	If ($Get(pFile) = "") {
		Set mgrDir = $ZU(12)
		Set pFile = mgrDir_"messages.log"
	}
	Set tAlert = ""
	If (pFile [ "alert") Set tAlert = 1
	If (pFile [ "message") Set tAlert = 0
	If ($Get(pFile) = "") Quit ""
	Write:pDebug pFile,!
	Set pLines = 0
	Set pMaxLines = $Get(pFilter("pMaxLines"),pFilter)
	Set pMaxDT = $Get(pFilter("iToPeriod"),"")
	If (pMaxDT ? 1.4N1"-"1.2N1"-"1.2N1"T".E) {
		Set pMaxDate = $Piece(pMaxDT,"T",1)
		Set pMaxDateH = $ZDateH(pMaxDate,8)
		Set pMaxTime = $Piece(pMaxDT,"T",2)
		Set pFilter("pMaxDateH") = pMaxDateH
		Set pFilter("pMaxTime") = pMaxTime
	}
	Set pMinDT = $Get(pFilter("iFromPeriod"),"")
	If (pMinDT ? 1.4N1"-"1.2N1"-"1.2N1"T".E) {
		Set pMinDate = $Piece(pMinDT,"T",1)
		Set pMinDateH = $ZDateH(pMinDate,8)
		Set pMinTime = $Piece(pMinDT,"T",2)
		Set pFilter("pMinDateH") = pMinDateH
		Set pFilter("pMinTime") = pMinTime
	}
	Set tReturn = ""
	Set timeout = 2
	Try {
		Open pFile:("R"):timeout  // read
		If $test {
			Write:pDebug "Open",!
			Use pFile
			Set pos = $ZPOS
			Set pos = $ZSEEK(0,0)
			Try {
				Set tWebgateway = ##class(otw.wgw.import).getWebgatewayFromFilePath(pFile)
			} Catch { Set tWebgateway = "" }
			For {
				Set pos = $ZPOS
				Read tText
				Set:pDebug ^DEBUG($I(DEBUG))=$GET(tText)
				Set tSC = ..ImportLine(tText,tWebgateway,.pFilter,pImport)  // ImportLines applies pFilter
				If $$$ISOK(tSC) Set pLines($I(pLines)) = tText
				If (pMaxLines < 0) { Continue }
				If (pLines >= pMaxLines) { Quit }
			}
			Close pFile
		}
	}
	Catch exception {
		If exception.%IsA("%Exception.SystemException") {
			Do BACK^%ETN // Log error in error log
		} Else {
			Throw exception // We will just throw these to outer error handler
		}
		Close pFile
	}
	//Use 0
	Quit $$$OK
}

ClassMethod TimesCompareIsBefore(pTime1 As %String = "", pTime2 As %String = "") As %Boolean
{
	Set x = (pTime2 ] pTime1)
	Quit x
}


}
