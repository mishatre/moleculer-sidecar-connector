
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("ServiceInfo", ServiceInfo) Then
		Cancel = True;
		Return;
	EndIf;   	
	Parameters.Property("Published", Published);
	
	LoadServiceData();
	
	If Published Then
		UpdatePublicationStatus();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	If Not Published Then
		AttachIdleHandler("UpdateServicePublicationInfoHandler", 0.1, True);
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateServicePublicationInfo(Command)
	UpdateServicePublicationInfoAtServer();
EndProcedure  

#EndRegion

#Region Private 

#Region IdleHandlers

&AtClient
Procedure UpdateServicePublicationInfoHandler()
	UpdateServicePublicationInfoAtServer();	
EndProcedure

#EndRegion

&AtServer
Procedure LoadServiceData()
			
	ServiceName     = ServiceInfo.Name;
	ServiceVersion  = ServiceInfo.Version;
	
	Actions.Clear();
	For Each KeyValue In ServiceInfo.Actions Do
		Action = KeyValue.Value;
		NewRow = Actions.Add();
		NewRow.Name        = Action.Name;
		NewRow.Description = Action.Description;
		NewRow.Params      = Action.Params;
	EndDo;
	
	Events.Clear();
	For Each KeyValue In ServiceInfo.Events Do
		Event = KeyValue.Value;
		NewRow = Events.Add();
		NewRow.Name        = Event.Name;
		NewRow.Description = Event.Description;
	EndDo;    
	
	ServiceRawSchema = mol_Helpers.ToJSONString(ServiceInfo.RawSchema, True);
	
EndProcedure

&AtServer
Procedure UpdateServicePublicationInfoAtServer()
	
	Published = False;	
	
	Response = mol_Transit.DiscoverNodes();
	If mol_Helpers.IsErrorResponse(Response) Then
		Return;
	Else	
		For Each Service In Response.Services Do
			If Service.Metadata.Get("$sidecarNodeID") <> "" Then
				Continue;
			EndIf; 
			
			If Service.Name <> ServiceName Or Service.Version <> ServiceVersion Then
				Continue;
			EndIf;
			
			Published = True;
			Break;
				
		EndDo;
	EndIf;
	
	UpdatePublicationStatus();
	
EndProcedure  

&AtServer
Procedure UpdatePublicationStatus()
	If Published Then
		PublicationStatus = GetSuccessString("Published");
	Else
		PublicationStatus = GetDefaultString("Not published");		
	EndIf;
EndProcedure

Function GetDefaultString(Text)
	Return New FormattedString(Text,,StyleColors.FieldTextColor,,Undefined);	
EndFunction

Function GetSuccessString(Text, Hyperlink = False)
	Return New FormattedString(
		New FormattedString(Text,,StyleColors.AccentColor,,Undefined),
		?(Hyperlink, New FormattedString("(show details)",,,,"Details"), "")
	);	
EndFunction

#EndRegion




