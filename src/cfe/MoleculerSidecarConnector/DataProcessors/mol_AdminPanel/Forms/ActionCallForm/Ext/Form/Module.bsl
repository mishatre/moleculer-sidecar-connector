////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Admin panel form that calls a single Moleculer action.

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Action = Parameters.Action;
	
	EditorParameters = CodeEditor.NewInitParameters();
	EditorParameters.PlacementGroupName   = "GroupActionParametersTextEditor";
	EditorParameters.DataPath             = "ActionParameters";
	EditorParameters.UseSubstituteEditor  = True;
	EditorParameters.SubstituteEditorName = "ActionParameters";
    EditorParameters.LanguageMode         = "json";	
	CodeEditor.Initialize(ThisObject, EditorParameters);
	
	EditorParameters = CodeEditor.NewInitParameters();
	EditorParameters.PlacementGroupName   = "GroupResponseTextEditor";
	EditorParameters.DataPath             = "ResponseText";
	EditorParameters.UseSubstituteEditor  = True;
	EditorParameters.SubstituteEditorName = "ResponseText";
	EditorParameters.LanguageMode         = "json";	
	CodeEditor.Initialize(ThisObject, EditorParameters);
	
	ManageForm(ThisForm);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CodeEditorClient.OnOpen(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CallAction(Command)
	CallActionAtServer();
EndProcedure  

&AtClient
Procedure Copy(Command)
	// Вставить содержимое обработчика.
EndProcedure

&AtClient
Procedure ToggleAdvancedOptions(Command)
	ShowAdvancedOptions = Not ShowAdvancedOptions;
	ManageForm(ThisForm);
EndProcedure

#EndRegion 

#Region FormHeaderItemsEventHandlers

#Region Attachable

#Region CodeEditorEventHandlers  

&AtClient
Procedure Attachable_CodeEditorOnReady(Element) 
	
	CodeEditorClient.OnLoaded(ThisObject, Element);
		
EndProcedure

&AtClient
Procedure Attachable_CodeEditorOnAfterLoaded() Export   
	
	CodeEditorClient.OnAfterLoaded(ThisObject); 
				
EndProcedure

&AtClient
Procedure Attachable_CodeEditorOnClick(Element, EventData, StandardProcessing)
	
	CodeEditorClient.OnClick(ThisObject, Element, EventData, StandardProcessing);
	
EndProcedure  

#EndRegion  

#EndRegion

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ManageForm(Form)
	
	Items  = Form.Items;
	Object = Form.Object;
	
	Items.GroupAdvancedOptions.Visible = Form.ShowAdvancedOptions;		
	
EndProcedure

&AtServer
Procedure CallActionAtServer()
	
	Params = ParseActionParameters();
	
	Options = New Structure();
	
	If ValueIsFilled(NodeID) Then
		Options.Insert("nodeID", NodeID);	
	EndIf;   
	// Metadata?
	If ValueIsFilled(RequestID) Then
		Options.Insert("requestID", RequestID);	
	EndIf;
	If Timeout <> 0 Then
		Options.Insert("timeout", Timeout);
	EndIf;
	
	Response = Moleculer.Call(Action, Params, Options); 	
	
	ResponseText = mol_Helpers.ToJSONString(Response);
	
	ManageForm(ThisForm);
	
EndProcedure

&AtServer
Function ParseActionParameters()  
	
	Return mol_Helpers.FromJSONString(ActionParameters);
	
EndFunction

#EndRegion  
