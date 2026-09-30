////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Admin panel form that lists the connector's services.

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	LoadServiceList();
	LoadServiceRegistrationInfo();

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

                   
#EndRegion 

&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)   
	
	StandardProcessing = False;     
	
	Params = New Structure();                           
	Params.Insert("Specification", List[SelectedRow].Specification);
	OpenForm(
		"DataProcessor.mol_AdminPanel.Form.ServiceItemForm", 
		Params, 
		Item,
	);
	
EndProcedure

#Region Private  

&AtServer
Procedure LoadServiceList()
	
	Services = Moleculer.GetServices();
	For Each ServiceRow In Services Do
		
		NewRow = List.Add(); 
		NewRow.Name        = ServiceRow.Name;
		NewRow.Description = ServiceRow.Description;
		NewRow.Version     = "Version: " + ServiceRow.Version;
		NewRow.Actions     = "Actions: " + ServiceRow.Actions.Count();
		NewRow.Events      = "Events: "  + ServiceRow.Events.Count();
		NewRow.Schema      = ServiceRow.Schema; 
		
		IsDynamic = ServiceRow.Metadata.Get("$dynamic");
		NewRow.Type        = ?(IsDynamic, "dynamic", "build-in");		
	EndDo;		
	
EndProcedure

&AtServer
Procedure LoadServiceRegistrationInfo()

	RegistrationInfo = mol_Broker.GetSidecarNodeServices();
	For Each ServiceInfo In RegistrationInfo Do  
		Filter = New Structure();
		Filter.Insert("FullName", ServiceInfo.FullName);
		FoundRows = List.FindRows(Filter);
		If FoundRows.Count() = 0 Then
			Continue;
		EndIf;
		
		Item = FoundRows[0];
		Item.Icon = 1;
				
	EndDo;
	
EndProcedure

#Region IdleHandlers      


#EndRegion

#EndRegion


