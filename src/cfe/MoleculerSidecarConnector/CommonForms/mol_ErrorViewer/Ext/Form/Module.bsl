
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("Error") Then
		Cancel = True;
		Return;
	EndIf;     
	
	LoadMoleculerError(Parameters.Error); 
	
EndProcedure     

&AtServer
Procedure LoadMoleculerError(Error)
	
	ErrorCode = Error.Code;
	If Error.Property("Type") Then
		ErrorType = Error.Type; 
	EndIf;
	If Error.Property("Message") Then
		ErrorMessage = Error.Message;
	EndIf;
	
	If Error.Property("Data") And Error.Data <> Undefined Then
		ErrorData = mol_Helpers.ToJSONString(Error.Data, True);
		Items.GroupData.Visible = True;
	EndIf;                                                         
	
	If Error.Property("Stack") And Error.Stack <> Undefined Then
		LoadErrorStack(Error.Stack);
		Items.GroupStackTrace.Visible = True;
	EndIf;
	                                                             
EndProcedure

&AtServer
Procedure LoadErrorStack(Stack)

	ErrorStackTrace = StrReplace(Stack, "\n", Chars.CR);
	
EndProcedure
 
 
