////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Moleculer error classes and the ambient error stack.

#Region Public

#Region PredefinedErrors 

Function CustomError(Type, Message = "", Data = Undefined, ErrorInfo = Undefined) Export

     // One concept had two spellings. Normalise before the chain so the taxonomy keeps one row per meaning
     // instead of two identical branches; the call sites still using the short name are listed in the
     // protocol document.
     If Type = "ServiceSchema" Then
             Type = "ServiceSchemaError";
     EndIf;

      Error = Undefined;
	
	If False Then
		
	ElsIf Type = "TypeError" Then
		Error = TypeError(Message, Data, ErrorInfo);
	ElsIf Type = "ServiceNotFound" Then
		Error = ServiceNotFound(Message, Data, ErrorInfo);
	ElsIf Type = "ServiceNotAvailable" Then
		Error = ServiceNotAvailable(Message, Data, ErrorInfo);
	ElsIf Type = "RequestTimeout" Then
		Error = RequestTimeout(Message, Data, ErrorInfo);
	ElsIf Type = "RequestSkipped" Then
		Error = RequestSkipped(Message, Data, ErrorInfo);
	ElsIf Type = "RequestRejected" Then
		Error = RequestRejected(Message, Data, ErrorInfo);
	ElsIf Type = "ValidationError" Then
		Error = ValidationError(Message, Data, ErrorInfo);
	ElsIf Type = "MaxCallLevel" Then
		Error = MaxCallLevel(Message, Data, ErrorInfo);
	ElsIf Type = "ServiceSchemaError" Then
		Error = ServiceSchemaError(Message, Data, ErrorInfo);
	ElsIf Type = "InvalidPacketData" Then
		Error = InvalidPacketData(Message, Data, ErrorInfo);
    ElsIf Type = "InvalidArgument" Then
            Error = InvalidArgumentError(Message, Data, ErrorInfo);
    ElsIf Type = "NotFoundError" Then
            Error = NotFoundError(Message, Data, ErrorInfo);
    ElsIf Type = "AccessKeyRequired" Then
            Error = AccessKeyRequiredError(Message, Data, ErrorInfo);
    ElsIf Type = "SecretKeyRequired" Then
            Error = SecretKeyRequiredError(Message, Data, ErrorInfo);
    ElsIf Type = "ExpiresParam" Then
            Error = ExpiresParamError(Message, Data, ErrorInfo);
    ElsIf Type = "Error" Then
            // The connector's own guards use this name for "the caller asked for something the connector
            // refuses". It is a documented row rather than a silent fallback, and it keeps the shape those
            // call sites already produced. Retyping them to "InvalidArgument" is recorded as a follow-up.
            Error = Error("GENERIC_ERROR", 500, "MoleculerError", Message, Data, ErrorInfo);
    Else
            // An unknown type is a mistake in the connector, not a runtime condition, and answering with a
            // generic error only hid it: eleven of thirty call sites silently degraded that way. Raising
            // loudly names the offending type so the call site is findable from the message alone.
            UnknownType = StrTemplate("Unknown error type ""%1""", Type);
            RaiseError(ClientError("UNKNOWN_ERROR_TYPE", 400, UnknownType, Data, ErrorInfo));
    EndIf;

	Return Error;
	
EndFunction

Function TypeError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ClientError("TYPE_ERROR", , Message, Data, ErrorInfo); 
EndFunction

#Region Moleculer

Function ServiceNotFound(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return RetryableError("SERVICE_NOT_FOUND", 404, Message, Data, ErrorInfo);
EndFunction

Function ServiceNotAvailable(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return RetryableError("SERVICE_NOT_AVAILABLE", 404, Message, Data, ErrorInfo);
EndFunction

Function RequestTimeout(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ServerError("REQUEST_TIMEOUT", 504, Message, Data, ErrorInfo);
EndFunction

Function RequestSkipped(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("REQUEST_SKIPPED", 514, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function RequestRejected(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ServerError("REQUEST_REJECTED", 503, Message, Data, ErrorInfo);
EndFunction

Function ValidationError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return ClientError("VALIDATION_ERROR", 422, Message, Data, ErrorInfo);
EndFunction

Function MaxCallLevel(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("MAX_CALL_LEVEL", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function ServiceSchemaError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("SERVICE_SCHEMA_ERROR", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function InvalidPacketData(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("INVALID_PACKET_DATA", 500, "MoleculerError", Message, Data, ErrorInfo);
EndFunction

Function NotFoundError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	// A client asked for something that is not there. The message says what, and the code says 404 so a
	// caller does not have to read the text to find out.
	Return ClientError("NOT_FOUND", 404, Message, Data, ErrorInfo);
EndFunction

#EndRegion 

#Region Minio

Function InvalidArgumentError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("InvalidArgument", 400, "ValidationError", Message, Data, ErrorInfo);	
EndFunction

Function InvalidObjectNameError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("InvalidObjectName", 400, "ValidationError", Message, Data, ErrorInfo);	
EndFunction

Function InvalidPrefixError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("InvalidPrefix", 400, "ValidationError", Message, Data, ErrorInfo);	
EndFunction

Function AnonymousRequestError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("AnonymousRequest", 403, "Error", Message, Data, ErrorInfo);	
EndFunction

Function InvalidEndpointError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("InvalidEndpoint", 400, "ValidationError", Message, Data, ErrorInfo);	
EndFunction

Function InvalidBucketNameError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("InvalidBucketName", 400, "ValidationError", Message, Data, ErrorInfo);	
EndFunction 

Function AccessKeyRequiredError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("AccessKeyRequired", 401, "Error", Message, Data, ErrorInfo);	
EndFunction

Function SecretKeyRequiredError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("SecretKeyRequired", 401, "Error", Message, Data, ErrorInfo);	
EndFunction 

Function InvalidXMLError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("InvalidXML", 400, "ParseXMLError", Message, Data, ErrorInfo);	
EndFunction

Function ExpiresParamError(Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("ExpiresParamError", 403, "ValidationError", Message, Data, ErrorInfo);	
EndFunction

Function S3Error(Code, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error("", Code, "S3Error", Message, Data, ErrorInfo);
EndFunction

#EndRegion

#EndRegion    

Procedure RaiseTypeError(Name, Value, Type, 
	Type1 = Undefined, Type2 = Undefined, Type3 = Undefined, 
	Type4 = Undefined, Type5 = Undefined, Type6 = Undefined) Export
	
	Types = New Array();
	Types.Add(Type); 
	If Type1 <> Undefined Then
		Types.Add(Type1);	
	EndIf;
	If Type2 <> Undefined Then
		Types.Add(Type2);	
	EndIf;
	If Type3 <> Undefined Then
		Types.Add(Type3);	
	EndIf;
	If Type4 <> Undefined Then
		Types.Add(Type4);	
	EndIf; 
	If Type5 <> Undefined Then
		Types.Add(Type5);	
	EndIf;
	If Type6 <> Undefined Then
		Types.Add(Type6);	
	EndIf;
	
	Template = NStr("
	|	ru = '%1 должна иметь тип %2. Передан тип: ""%3""';
	|	en = '%1 should be of type %2. Actual: ""%3""';");
	
	Message = StrTemplate(Template, 
		Name,
		"""" + StrConcat(Types, """,""") + """",
		TypeOf(Value)            
	);
	
	RaiseCustomError("TypeError", Message);
	
EndProcedure

Procedure RaiseCustomError(Type, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	
	Error = CustomError(Type, Message, Data, ErrorInfo); 
	
	RaiseError(Error);
	
EndProcedure 

Procedure RaiseError(Error = Undefined, GenerateStack = False) Export
	
	If TypeOf(Error) = Type("ErrorInfo") Then
		Error = FromErrorInfo(Error);
	EndIf;     
	
	If Error.Stack = Undefined Then
		AppendErrorInfo(Error, GenerateErrorStack(Undefined, Error.Name, Error.Message));
	EndIf;
	
	mol_Helpers.PushToStack(ThisMetadata().Name, Error);
	
	Message  = StrTemplate("%1: %2", Error.Name, Error.Message);
	Category = ErrorCategory.ExternalDataSourceError;
	Code     = StrTemplate("%1: %2", Error.Type, Error.Code);
	Data     = ?(Error.ErrorInfo = Undefined, 
		WrapExternalStack(Error.Stack), 
		mol_Helpers.ToJSONString(Error.Data)
	);
	
	Raise (Message, Category, Code, Data, Error.ErrorInfo);
	
EndProcedure

Function FromErrorInfo(ErrorInfo) Export
	
	If TypeOf(ErrorInfo) <> Type("ErrorInfo") Then   
		RaiseTypeError("ErrorInfo", ErrorInfo, Type("ErrorInfo"));
	EndIf;
	
	If Not ValueIsFilled(ErrorInfo.SourceLine) Then
		RaiseError(NoExceptionError());
	EndIf;         
	
	Name        = "Error";
	Description = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	Category    = ErrorProcessing.ErrorCategoryForUser(ErrorInfo);
	Type        = GetErrorTypeFromErrorInfo(ErrorInfo);
	Data        = ErrorInfo.AdditionalInformation;
	
	If Category = ErrorCategory.NetworkError Then
		Return RetryableError(Type, 503, Description, Data, ErrorInfo);	
	ElsIf Category = ErrorCategory.ExceptionRaisedFromScript Then
		Name = "ExceptionRaisedFromScript";
	ElsIf Category = ErrorCategory.AccessViolation Then       
		Name = "AccessViolation";
	ElsIf Category = ErrorCategory.InvalidPassword Then    
		Name = "InvalidPassword";
	ElsIf Category = ErrorCategory.NoPermissionToUseFunctionality Then      
		Name = "NoPermissionToUseFunctionality";
	ElsIf Category = ErrorCategory.ExternalDataSourceError Then                                      
		Name = "ExternalDataSourceError";
	ElsIf Category = ErrorCategory.LocalFileAccessError Then                                         
		Name = "LocalFileAccessError";
	ElsIf Category = ErrorCategory.ConfigurationError Then                                           
		Name = "ConfigurationError";
	ElsIf Category = ErrorCategory.DatabaseCopyError Then                                            
		Name = "DatabaseCopyError";
	ElsIf Category = ErrorCategory.DataCompositionSettingsError Then                                 
		Name = "DataCompositionSettingsError";
	ElsIf Category = ErrorCategory.GotoURLError Then                                                 
		Name = "GotoURLError";
	ElsIf Category = ErrorCategory.FullTextSearchError Then                                          
		Name = "FullTextSearchError";
	ElsIf Category = ErrorCategory.DocumentConversionError Then                                      
		Name = "DocumentConversionError";
	ElsIf Category = ErrorCategory.SignatureVerificationError Then                                   
		Name = "SignatureVerificationError";
	ElsIf Category = ErrorCategory.PrinterError Then                                                 
		Name = "PrinterError";
	ElsIf Category = ErrorCategory.SpeechProcessingError Then                                        
		Name = "SpeechProcessingError";
	ElsIf Category = ErrorCategory.SessionError Then                                                 
		Name = "SessionError";
	ElsIf Category = ErrorCategory.CollaborationSystemError Then                                     
		Name = "CollaborationSystemError";
	ElsIf Category = ErrorCategory.MultimediaToolsError Then                                         
		Name = "MultimediaToolsError";
	ElsIf Category = ErrorCategory.DatabaseTablespaceError Then                                      
		Name = "DatabaseTablespaceError";
	ElsIf Category = ErrorCategory.StoredDataError Then                                              
		Name = "StoredDataError";
	ElsIf Category = ErrorCategory.OtherError Then                                                   
		Name = "OtherError";
	EndIf;
	
	// A platform error is converted from what the platform reported, not from a type a caller named, so it
	// is built directly instead of going through the caller-type dispatcher. The dispatcher refuses names it
	// does not know, and the category names below are not part of the caller-facing taxonomy.
	Error = Error(Type, 500, Name, Description, Data, ErrorInfo);
	Error.Name = Name;
	
	Return Error;
	
EndFunction

Function ToString(Error) Export
	
	Return StrTemplate("%1
	|%2:%3
	|
	|%4", Error.Message, Error.Type, Error.Code, Error.Stack);
	
EndFunction

#EndRegion

#Region Protected

Function GetCurrentError() Export
	Return mol_Helpers.LastFromStack(ThisMetadata().Name);	
EndFunction

// Removes the ambient error the last RaiseError published. The push exists so the Except that handles
// the exception can read the structured error back, and no pop can run between that push and that read
// because the read happens while the exception is being handled. The pop therefore belongs to the
// operation boundary that runs after it, which is mol_ContextFactory.Handler.
Procedure PopCurrentError() Export
	
	mol_Helpers.PopFromStack(ThisMetadata().Name);	
	
EndProcedure

Function GenerateStackTrace(OffsetIndex = Undefined, OffsetModule = Undefined) Export
	
	If OffsetIndex = Undefined And OffsetModule = Undefined Then
		Raise "OffsetIndex or OffsetModule must be provided";
	ElsIf OffsetIndex <> Undefined And OffsetModule <> Undefined Then
		Raise "Only either OffsetIndex or OffsetModule should be provided";
	EndIf;
	
	ErrorInfo  = GenerateErrorInfo();
	StackTrace = ParseErrorStackTrace(ErrorInfo);	

	Result = New Array();
	
	Index = 0;
	If OffsetModule <> Undefined Then
		Skip = True;
		While Skip Or StackTrace.Stack[Index].Object = OffsetModule Do
			If StackTrace.Stack[Index].Object = OffsetModule Then
				Skip = False;
			EndIf;
			Index = Index + 1;
			If Index = StackTrace.Stack.UBound() Then
				Index = -1;
				Break;
			EndIf;
		EndDo;
		If Index = -1 Then
			Raise "OffsetModule - " + OffsetModule + " not found";
		EndIf;
	ElsIf OffsetIndex <> Undefined Then
		If OffsetIndex >= StackTrace.Stack.Count() Then
			Raise "OffsetIndex - " + OffsetIndex + " is larger than stack trace - " + StackTrace.Stack.Count();
		EndIf;
	EndIf;
	
	For Index = Index To StackTrace.Stack.UBound() Do
		Result.Add(StackTrace.Stack[Index]);	
	EndDo;
	
	Return Result;
	
EndFunction 

Function RegenerateError(Error) Export
	
	Return Error(
		mol_Helpers.Get(Error, "Type"   ), 
		mol_Helpers.Get(Error, "Code"   ), 
		mol_Helpers.Get(Error, "Name"   ), 
		mol_Helpers.Get(Error, "Message"), 
		mol_Helpers.Get(Error, "Data"   ), 
		mol_Helpers.Get(Error, "Stack"  )
	);
	
EndFunction

#Region Moleculer

Function ClientError(Type, Code = 400, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error(Type, Code, "MoleculerClientError", Message, Data, ErrorInfo);
EndFunction

Function ServerError(Type, Code = 500, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error(Type, Code, "MoleculerServerError", Message, Data, ErrorInfo);
EndFunction

Function RetryableError(Type, Code = 500, Message = "", Data = Undefined, ErrorInfo = Undefined) Export
	Return Error(Type, Code, "MoleculerRetryableError", Message, Data, ErrorInfo);
EndFunction

#EndRegion 

Function Error(Type, Code = 500, Name = "MoleculerError", Message = "", Data = Undefined, StackOrErrorInfo = Undefined)

	Result = NewError();
	Result.Name    = Name;
	Result.Message = Message;
	Result.Code    = Code;
	Result.Type    = Type;
	Result.Data    = Data;
	
	AppendErrorInfo(Result, StackOrErrorInfo);
	
	Return Result;

EndFunction

#EndRegion

#Region Private

Function This()
	Return mol_Errors;	
EndFunction

Function ThisMetadata()
	Return Metadata.CommonModules.mol_Errors;	
EndFunction

#Region Constructors

Function NewError()
	
	Result = New Structure();
	Result.Insert("name"     );
	Result.Insert("type"     );
	Result.Insert("message"  );
	Result.Insert("code"     );
	Result.Insert("data"     );
	Result.Insert("stack"    );
	Result.Insert("errorInfo");
	
	Return Result;
	
EndFunction

Function NewErrorStackTrace()

	Result = New Structure();
	Result.Insert("Error");              
	// String
	Result.Insert("ErrorTypes", New Array());
	// NewStackTraceRow()
	Result.Insert("Stack"     , New Array());
	
	Return Result;	
	
EndFunction

Function NewStackTraceRow()

	Result = New Structure();
	Result.Insert("Raw");
	Result.Insert("Type");
	Result.Insert("Object");
	Result.Insert("ObjectType");
	Result.Insert("LineNumber");
	Result.Insert("Code");
	Result.Insert("Metadata");
	
	Return Result;
	
EndFunction

#EndRegion

Function GenerateErrorStack(ErrorInfo = Undefined, Name, Message)
	
	If ErrorInfo <> Undefined Then
		Return ErrorProcessing.DetailErrorDescription(ErrorInfo);
	EndIf;
	
	StackTrace = GenerateStackTrace(, ThisMetadata().FullName());
	
	NewStack = New Array();
	NewStack.Add(StrTemplate("%1: %2", Name, Message));
	For Each TraceRow In StackTrace Do 
		NewStack.Add(TraceRow.Raw);
	EndDo;
	
	Return StrConcat(NewStack, Chars.LF);
	
EndFunction

Function GenerateErrorInfo()
	
	Try
		Raise "";
	Except
		Return ErrorInfo();
	EndTry;
	
EndFunction

Function ParseErrorStackTrace(ErrorInfo)

	DetailDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);	
	
	Result = NewErrorStackTrace();

	Rows = StrSplit(DetailDescription, Chars.LF);
	FirstRow = True;
	LastRow  = False;
	For Each Row In Rows Do
		If FirstRow Then
			FirstRow = False;
			Result.Error = Row;
			Continue;
		ElsIf IsBlankString(Row) Then
			LastRow = True;
			Continue;
		ElsIf LastRow Then	
			ErrorTypes = StrSplit(Mid(Row, 2, StrLen(Row) - 2), ",");
			For Each Type In ErrorTypes Do
				Result.ErrorTypes.Add(TrimAll(Type));	
			EndDo;                                   
			Break;
		EndIf;  
		
		NewRow = NewStackTraceRow();
		NewRow.Raw = Row;
		
		Parts = StrSplit(Row, ":");
		ModuleInfo = Mid(Parts[0], 2, StrLen(Parts[0]) - 2);
		NewRow.Code = Parts[1];
		
		Parts = StrSplit(ModuleInfo, " ");
		NewRow.Type = ?(Parts.Count() = 2, Parts[0], "Infobase");
		ObjectInfo = Parts[Parts.UBound()];
		
		LineInfoPos = StrFind(ObjectInfo, "(");
		NewRow.LineNumber = Mid(ObjectInfo, LineInfoPos + 1, StrLen(ObjectInfo) - LineInfoPos - 1);
		If LineInfoPos = 1 Then
			NewRow.Object = "DynamicEvaluation";
		Else
			Parts = StrSplit(Left(ObjectInfo, LineInfoPos - 1), ".");
			// I beleive it is incorrect. Object type goes after module name, not last item
			NewRow.ObjectType = Parts[Parts.UBound()];
			Parts.Delete(Parts.UBound());
			NewRow.Object = StrConcat(Parts, ".");
		EndIf;	
			
		Result.Stack.Add(NewRow);	
		
	EndDo; 
	
	Return Result;
	
EndFunction

Function GetErrorTypeFromErrorInfo(ErrorInfo)
	
	BriefDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);	
	TextParts        = StrSplit(BriefDescription, ":");
	
	If TextParts.Count() <= 1 Then
		Return "UNKNOWN";
	EndIf;
	
	ErrorMessage = TrimAll(TextParts[1]);
	If ErrorMessage = "Превышено время ожидания" Or ErrorMessage = "Превышен таймаут" Then
		Return "REQUEST_TIMEOUT";
	ElsIf ErrorMessage = "Не могу установить соединение" Then
		Return "CONNECTION_ERROR";
	ElsIf ErrorMessage = "Server returned nothing (no headers, no data)" Then
		Return "EMPTY_RESPONSE";
	EndIf;
	
	Return "UNKNOWN";
	
EndFunction 

Function WrapExternalStack(Stack)
	
	Result = New Array();
	
	Result.Add("----EXTERNAL_STACK----");
	Lines = StrSplit(Stack, Chars.LF);
	For Each Line In Lines Do
		Result.Add(Chars.Tab + Line);	
	EndDo;
	Result.Add("----EXTERNAL_STACK----");
	
	Return StrConcat(Result, Chars.LF);
	
EndFunction

Function NoExceptionError(Data = Undefined)
	Return ClientError("NO_EXCEPTION_ERROR", 400, "Function called outside except block", Data);
EndFunction

Procedure AppendErrorInfo(Error, StackOrErrorInfo)
	
	If mol_Helpers.IsString(StackOrErrorInfo) Then
		Error.Stack = StackOrErrorInfo;	
	ElsIf TypeOf(StackOrErrorInfo) = Type("ErrorInfo") Then     
		Error.ErrorInfo = StackOrErrorInfo;
		Error.Stack     = GenerateErrorStack(StackOrErrorInfo, Error.Name, Error.Message);
	EndIf;
	
EndProcedure

#EndRegion
