
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
