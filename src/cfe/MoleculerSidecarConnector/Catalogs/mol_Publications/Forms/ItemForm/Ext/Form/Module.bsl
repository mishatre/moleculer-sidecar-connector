////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Publication item form: edits one published service.

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Object.User) Then 
		InfoBaseUser = InfoBaseUsers.FindByUUID(Object.User);
		If InfoBaseUser <> Undefined Then
			User = InfoBaseUser.Name;		     
		EndIf;
	EndIf;
	
	ManageForm(ThisForm);
	
EndProcedure 

&AtClient
Procedure OnOpen(Cancel)
	
	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UserStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	Params = New Structure();
	If ValueIsFilled(Object.User) Then
		Params.Insert("SelectedUser", Object.User);
	EndIf;
		
	OpenForm(
		"CommonForm.mol_UserSelection", 
		Params, 
		Item,
	);
	
EndProcedure

&AtClient
Procedure UserChoiceProcessing(Item, SelectedValue, AdditionalData, StandardProcessing)
	Object.User   = SelectedValue.Value;
	SelectedValue = SelectedValue.Presentation;
EndProcedure

&AtClient
Procedure AuthTypeOnChange(Item)
	ManageForm(ThisForm);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TestConnection(Command)
	TestConnectionAtServer();
EndProcedure  

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ManageForm(Form)
	
	Items  = Form.Items;
	Object = Form.Object;
	
	AuthType  = Object.AuthType;
	AuthTypes = Moleculer.AuthTypes();
	If AuthType = AuthTypes.UsingPassword Then
		Items.GroupAuthTypeUsingPassword   .Visible = True;
		Items.GroupAuthTypeUsingAccessToken.Visible = False;
	ElsIf AuthType = AuthTypes.UsingAccessToken Then
		Items.GroupAuthTypeUsingPassword   .Visible = False;
		Items.GroupAuthTypeUsingAccessToken.Visible = True;
	Else 
		Items.GroupAuthTypeUsingPassword   .Visible = False;
		Items.GroupAuthTypeUsingAccessToken.Visible = False;
	EndIf;
		
EndProcedure 

&AtServer
Procedure TestConnectionAtServer()
	
	ValidatingCode = New UUID();
	Constants.mol_TestConnection.Set(ValidatingCode);
	
	Config = Moleculer.GetConfig();
	
	AuthType  = Object.AuthType;
	AuthTypes = Moleculer.AuthTypes();
	
	TestParams = Moleculer.NewPublicationParams();
	TestParams.Id       = String(Object.Ref);
	TestParams.Endpoint = Object.Endpoint;
	TestParams.Port     = Object.Port;
	TestParams.UseSSL   = Object.UseSSL;
	TestParams.Path     = Object.Path;
	TestParams.Auth     = Moleculer.NewPublicationAuthParams(AuthType);
		
	If AuthType = AuthTypes.UsingAccessToken Then			
		TestParams.Auth.Token = mol_Helpers.GenereteAccessToken(
			Object.Password, 
			User, 
			Config.Name
		);
	ElsIf AuthType = AuthTypes.UsingPassword Then		
		TestParams.Auth.Username = User;
		TestParams.Auth.Password = Object.Password;
	EndIf;    
	
	If ValueIsFilled(Object.Connection) Then   
		ConnectionParams = Moleculer.NewConnectionParams();
		ConnectionParams.Id        = New UUID();
		ConnectionParams.Type      = "HTTP";
		ConnectionParams.Endpoint  = Object.Connection.Endpoint;
		ConnectionParams.Port      = Object.Connection.Port;
		ConnectionParams.UseSSL    = Object.Connection.UseSSL;
		ConnectionParams.AccessKey = Object.Connection.AccessKey;
		ConnectionParams.SecretKey = Object.Connection.SecretKey;
		ConnectionParams.Timeout   = Object.Connection.Timeout;
		TestParams.Connection = ConnectionParams; 
	EndIf;      
	
	Try
		ReceivedCode = mol_Broker.GetPublicationValidationCode(TestParams);
		
		Message = "";
		If ReceivedCode = String(ValidatingCode) Then
			Message = "IDENTICAL CODES";		
		Else
			Message = "DIFFERENT CODES";
		EndIf;
		
		Status = StrTemplate("Testing connection: 
		|Expected code: %1
		|Received code: %2
		|%3", ValidatingCode, ReceivedCode, Message);
	Except                 
		Error = mol_Errors.GetCurrentError();
		If Error = Undefined Then
			Error = mol_Errors.FromErrorInfo(ErrorInfo());
		EndIf;
		Status = mol_Errors.ToString(Error);
	EndTry	
	
EndProcedure

#EndRegion

