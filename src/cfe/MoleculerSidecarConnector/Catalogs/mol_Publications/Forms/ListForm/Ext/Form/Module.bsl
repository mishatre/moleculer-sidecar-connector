
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	AttachIdleHandler("UpdatePublicationsStatusInfo", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RegisterPublications(Command)
	RegisterPublicationsAtServer()	
EndProcedure

&AtClient
Procedure UnregisterPublications(Command)
	UnregisterPublicationsAtServer();
EndProcedure

#EndRegion 

#Region Private 

#Region IdleHandlers

&AtClient
Procedure UpdatePublicationsStatusInfo() Export
		
EndProcedure

#EndRegion

&AtServer
Procedure RegisterPublicationsAtServer()
	
	mol_Broker.RegisterPublications();
	
EndProcedure

&AtServer
Procedure UnregisterPublicationsAtServer()
	
	mol_Broker.UnregisterPublications();
	
EndProcedure

#EndRegion


