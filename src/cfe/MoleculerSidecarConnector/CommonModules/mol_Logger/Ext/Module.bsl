
#Region Public

Procedure Debug(EventName, Message, Data = Undefined, Meta = Undefined) Export
	
	WriteLogEventSystem(
		EventName,
		EventLogLevel.Note,
		Meta,
		Data,
		Message
	);
	
EndProcedure

Procedure Error(EventName, Message, Data = Undefined, Meta = Undefined) Export 
		
	WriteLogEventSystem(
		EventName,
		EventLogLevel.Error,
		Meta,
		Data,
		Message
	);
	
EndProcedure

Procedure Warn(EventName, Message, Data = Undefined, Meta = Undefined) Export 
		
	WriteLogEventSystem(
		EventName,
		EventLogLevel.Warning,
		Meta,
		Data,
		Message
	);
	
EndProcedure      

Procedure Info(EventName, Message, Data = Undefined, Meta = Undefined) Export 
	
	WriteLogEventSystem(
		EventName,
		EventLogLevel.Information,
		Meta,
		Data,
		Message
	);
	
EndProcedure  

#EndRegion

#Region Protected

#Region Enums

Function LogLevels() Export

	Result = New Structure();
	Result.Insert("Debug");
	Result.Insert("Error");
	Result.Insert("Warn");
	Result.Insert("Info");
	
	If Not Moleculer.IsStandalone() Then
		Result.Debug = PredefinedValue("Enum.mol_LogLevel.Debug");
		Result.Error = PredefinedValue("Enum.mol_LogLevel.Error");
		Result.Warn  = PredefinedValue("Enum.mol_LogLevel.Warn");
		Result.Info  = PredefinedValue("Enum.mol_LogLevel.Info");	
	Else
		Result.Debug = EventLogLevel.Note;
		Result.Error = EventLogLevel.Error;
		Result.Warn  = EventLogLevel.Warning;
		Result.Info  = EventLogLevel.Information;
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
  
#EndRegion

#Region Private

Function This()
	Return mol_Logger;	
EndFunction

Function ThisMetadata()
	Return Metadata.CommonModules.mol_Logger;	
EndFunction

Procedure WriteLogEventSystem(EventName, LogLevel, Meta = Undefined, Val Data, Message)

	#If MobileAppServer Then
		Return;
	#EndIf
	
	LoggingLevel = Moleculer.GetConfig().LogLevel;
	If LoggingLevel = LogLevels().Error Then
		// Allow only error logs
		If LogLevel <> EventLogLevel.Error Then
			Return;
		EndIf;
	ElsIf LoggingLevel = LogLevels().Warn Then
		// Allow only warn and error logs
		If LogLevel = EventLogLevel.Note Or LogLevel = EventLogLevel.Information Then
			Return;
		EndIf;	
	ElsIf LoggingLevel = LogLevels().Info Then
		// Allow all except debug
		If LogLevel = EventLogLevel.Note Then
			Return;
		EndIf;
	ElsIf LoggingLevel = LogLevels().Debug Then
		// Allow all logs	
	EndIf;
	
	//If LogLevel = EventLogLevel.Note And Not ОбщегоНазначения.РежимОтладки() Then
	//	Return;
	//EndIf;   
	
	If Meta = Undefined Then
		StackTrace = mol_Errors.GenerateStackTrace(, ThisMetadata().FullName());
		If StackTrace[0].Object <> "DynamicEvaluation" Then
			Meta = Metadata.FindByFullName(StackTrace[0].Object)
		EndIf;
	EndIf;
	
	If mol_Helpers.IsObject(Data) Then
		Data = mol_Helpers.ToJSONString(Data, True);
	EndIf;

	WriteLogEvent(
		EventName,
		LogLevel,
		Meta,
		Data,
		Message
	);
	
EndProcedure      

#EndRegion