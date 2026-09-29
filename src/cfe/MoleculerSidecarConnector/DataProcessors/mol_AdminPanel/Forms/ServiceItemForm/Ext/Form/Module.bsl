
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("Specification") Then
		Cancel = True;
		Return;
	EndIf;
	
	Specification = Parameters.Specification;
	
	Name     = Specification.Name;
	FullName = Specification.FullName;
	Version  = Specification.Version;
	
	For Each KeyValue In Specification.Actions Do
		NewRow = Actions.Add();
		NewRow.Name = KeyValue.Key;
	EndDo;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateServiceRegistration(Command)
	UpdateServiceRegistrationAtServer();
EndProcedure

#EndRegion

#Region FormActions

&AtClient
Procedure ActionsSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;     
	
	Params = New Structure();                           
	Params.Insert("Action", Actions[SelectedRow].Name);
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.ActionCallForm", 
		Params, 
		Item,
	);
	
EndProcedure

#EndRegion

#Region Private 

&AtServer
Procedure UpdateServiceRegistrationAtServer()
	
	Publications = mol_Broker.GetActivePublications();
	
	For Each Publication In Publications Do
		
		Params = New Structure();       
		Params.Insert("publicationID", Publication.Info.Id);
		Params.Insert("service"      , FullName);

		Opts = New Structure();
		If Publication.Connection <> Undefined Then
			Opts.Insert("connection", Publication.Connection);	
		EndIf;
		
		Result = mol_Broker.Call("$sidecar.updateService", Params, Opts);
	
	EndDo;	
	
EndProcedure

#EndRegion








