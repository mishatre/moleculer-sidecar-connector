////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// User selection form used by the connector forms.

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ChoiceMode = True;
	ThisForm.CloseOnChoice = True;	
	LoadUsers();
	
EndProcedure

&AtServer
Procedure LoadUsers()                 
	
	UsersList.Clear();
	
	Users = InfoBaseUsers.GetUsers(); 
	For Each User In Users Do         
		#If Server And Not Server Then
			User = InfoBaseUsers.FindByUUID();
		#EndIf                        
		
		UsersList.Add(User.UUID, User.Name);		
		
	EndDo;
	
	
EndProcedure

&AtClient
Procedure UsersSelection(Item, SelectedRow, Field, StandardProcessing)  
	NotifyChoice(UsersList[SelectedRow]);
EndProcedure
