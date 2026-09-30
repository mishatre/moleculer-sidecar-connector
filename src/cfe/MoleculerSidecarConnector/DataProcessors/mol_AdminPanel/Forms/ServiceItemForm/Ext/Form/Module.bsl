////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Admin panel form that edits one service.

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
	
	Publications = Moleculer.GetPublications();
	
	For Each Publication In Publications Do
		
		Params = New Structure();       
		Params.Insert("publicationID", Publication.Id);
		Params.Insert("service"      , FullName);

		Opts = New Structure();
		If Publication.Connection <> Undefined Then
			Opts.Insert("connection", Publication.Connection);	
		EndIf;
		
		Result = mol_Broker.Call("$sidecar.updateService", Params, Opts);
	
	EndDo;	
	
EndProcedure

#EndRegion








