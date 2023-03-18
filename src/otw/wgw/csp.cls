Class otw.wgw.csp Extends %Persistent
{

Property iWebgateway As %String(MAXLEN = 9999) [ SqlColumnNumber = 2 ];

Property localTime As %String(MAXLEN = 9999);

Property cspConnectionNo As %Integer [ SqlColumnNumber = 4 ];

Property cspPage As %String(MAXLEN = 9999) [ SqlColumnNumber = 10 ];

Property cspRemoteAddr As %String(MAXLEN = 9999) [ SqlColumnNumber = 9 ];

Property cspRequestId As %String(MAXLEN = 9999) [ SqlColumnNumber = 7 ];

Property cspServer As %String(MAXLEN = 999) [ SqlColumnNumber = 5 ];

Property cspServerPid As %Integer [ SqlColumnNumber = 6 ];

Property cspSessionId As %String(MAXLEN = 9999) [ SqlColumnNumber = 8 ];

Property details As %String(MAXLEN = 9999) [ SqlColumnNumber = 12 ];

Property wgEvent As %String(MAXLEN = 9999);

Property wgLevel As %String;

Property wgLogLevel As %Integer;

Property wgText As %String(MAXLEN = 9999) [ SqlColumnNumber = 11 ];

Property wgWhen As %String [ SqlColumnNumber = 3 ];

Property zFilename As %String(MAXLEN = 9999);

Method CalcFilename() As %String
{
	Set tVal = ""
	If (..wgEvent = "WebGateway.ProcessRequest") {
		If (..wgText = "HTTP Request") {
			Set tDetails = ..details
			If (tDetails [ "?FILENAME=") {
				Set temp = $Piece(tDetails,"?FILENAME=",2)
				Set tVal = $Piece(temp," ",1)
			}
		}
		If (..wgText = "HTTP Response") {
			Set tDetails = ..details
			If (tDetails [ "FILENAME=") {
				Set temp = $Piece(tDetails,"FILENAME=",2)
				Set tVal = $Piece(temp,"\",1)
			}
		}
	}
	Set ..zFilename = tVal
	Quit tVal
}

ClassMethod ImportLine(pLine As %String = "", pWebgateway As %String, ByRef pFilter, pImport = 1) As %Status
{
	Set pLog = ##class(otw.wgw.csp).%New()
	Set pLog.iWebgateway = $Get(pWebgateway)
	Set q = """"
	Set tSC = $$$OK
	If (pLine ? 1"local-time=".E) {
		Set temp = $Piece(pLine,"local-time=",2)
		Set tVal = $Piece(temp,q,2)
		Set pLog.localTime = tVal
	}
	If (pLine ? .E.1" csp-connection-no=".E) {
		Set temp = $Piece(pLine," csp-connection-no=",2)
		Set tVal = $Piece(temp," ",1)
		Set pLog.cspConnectionNo = tVal
	}
	If (pLine ? .E.1" csp-page=".E) {
		Set temp = $Piece(pLine," csp-page=",2)
		Set tVal = $Piece(temp,q,2)
		Set pLog.cspPage = tVal
	}
	If (pLine ? .E.1" csp-remote-addr=".E) {
		Set temp = $Piece(pLine," csp-remote-addr=",2)
		Set tVal = $Piece(temp," ",1)
		Set pLog.cspRemoteAddr = tVal
	}
	If (pLine ? .E.1" csp-request-id=".E) {
		Set temp = $Piece(pLine," csp-request-id=",2)
		Set tVal = $Piece(temp," ",1)
		Set pLog.cspRequestId = tVal
	}
	If (pLine ? .E.1" csp-server=".E) {
		Set temp = $Piece(pLine," csp-server=",2)
		Set tVal = $Piece(temp,q,2)
		Set pLog.cspServer = tVal
	}
	If (pLine ? .E.1" csp-server-pid=".E) {
		Set temp = $Piece(pLine," csp-server-pid=",2)
		Set tVal = $Piece(temp," ",1)
		Set pLog.cspServerPid = tVal
	}
	If (pLine ? .E.1" csp-session-id=".E) {
		Set temp = $Piece(pLine," csp-session-id=",2)
		Set tVal = $Piece(temp," ",1)
		Set pLog.cspSessionId = tVal
	}
	If (pLine ? .E.1" details=".E) {
		Set temp = $Piece(pLine," details=",2)
		Set tVal = $Piece(temp,q,2)
		Set pLog.details = tVal
	}

	If (pLine ? .E.1" event=".E) {
		Set temp = $Piece(pLine," event=",2)
		Set tVal = $Piece(temp," ",1)
		Set pLog.wgEvent = tVal
	}
	If (pLine ? .E.1" level=".E) {
		Set temp = $Piece(pLine," level=",2)
		Set tVal = $Piece(temp," ",1)
		Set pLog.wgLevel = tVal
	}
	If (pLine ? .E.1" text=".E) {
		Set temp = $Piece(pLine," text=",2)
		Set tVal = $Piece(temp,q,2)
		Set pLog.wgText = tVal
	}
	If (pLine ? .E.1"wg-log-level=".E) {
		Set temp = $Piece(pLine,"wg-log-level=",2)
		Set tVal = $Piece(temp," ",1)
		Set pLog.wgLogLevel = tVal
	}
	If (pLine ? .E.1"when=".E) {
		Set temp = $Piece(pLine,"when=",2)
		Set tVal = $Piece(temp,q,2)
		Set pLog.wgWhen = tVal
	}
	If pImport {
		Set tFilename = pLog.CalcFilename()
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
		Set pFile = mgrDir_"/csplog/CSP.log"
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
			Set tWebgateway = ##class(otw.wgw.import).getWebgatewayFromFilePath(pFile)
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
