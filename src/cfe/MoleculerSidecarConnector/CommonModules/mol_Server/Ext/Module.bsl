////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Server-side transport entry point for inbound Moleculer requests.

#Region Protected
  
Function OnStart(LaunchParameter) Export

	Result = False;
	
	If Moleculer.IsStandalone() Then
		Return Result;
	EndIf;
	
	Config = MoleculerClientServer.GetConfig();
	
	If True
		AND AccessRight("Administration", Metadata) 
		AND InfoBaseUsers.GetUsers().Count() > 0
		AND Find(LaunchParameter, Config.LaunchParameters.SkipRolesCheck) = 0 
	Then   
		SetPrivilegedMode(True);
		
		AddRoles = False;
		If Find(LaunchParameter, Config.LaunchParameters.Enable) > 0 Then
			AddRoles = True;
		ElsIf Not IsInRole(Config.ExtAdminRole) Then  
			AddRoles = True; 
		EndIf;
		
		If AddRoles Then
			AddExtensionRolesToCurrentUser();
			Result = True;
		EndIf; 
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion
                    
#Region Private

Procedure AddExtensionRolesToCurrentUser() 
	
	Config = MoleculerClientServer.GetConfig();
	
	If mol_Reuse.BSPVersionAsNumber() >= 300 And Metadata.Catalogs.Find("ПрофилиГруппДоступа") <> Undefined Then
		AddBSPRolesToCurrentUser(Config);
	EndIf;    
	
	UserName    = UserName();
	CurrentUser = InfoBaseUsers.FindByName(UserName);
	MetadataRoleObject = Metadata.Roles.Find(Config.ExtAdminRole);
	If False
		Or CurrentUser.Roles.Contains(MetadataRoleObject)
		Or Not ValueIsFilled(UserName) 
		Or Not AccessRight("Administration", Metadata) 
	Then
		Return;
	EndIf;       
	
	CurrentUser.Roles.Add(MetadataRoleObject);
	 
	//Текст = "Восстановлены роли ИР текущего пользователя.";
	//Если ирКэш.НомерВерсииБСПЛкс() >= 300 Тогда
	//	Текст = Текст + " Рекомендуется установить расширение https://devtool1c.ucoz.ru/load/osnovnye/zashhita_rolej_rasshirenij_bsp_3_1_0/1-1-0-25";
	//КонецЕсли;
	
	CurrentUser.Write();  

EndProcedure 

Procedure AddBSPRolesToCurrentUser(Config) 
	
	SetPrivilegedMode(True);
	
	UUID = New UUID(Config.UUID); 
	
	AccessGroupProfilesManager = Catalogs["ПрофилиГруппДоступа"]; //@skip-check unknown-method-property
	
	Reference = AccessGroupProfilesManager.GetRef(UUID); 
	Object    = Reference.GetObject();
	If Object = Undefined Then
		Object = AccessGroupProfilesManager.CreateItem();
		Object.SetNewObjectRef(Reference);
		Object.Description = StrTemplate("%1 (системная, не изменять)", Config.Caption);
	EndIf;  
	
	MetadataRoleObject = Metadata.Roles.Find(Config.ExtAdminRole);
	RoleReference  = Eval("ОбщегоНазначения.ИдентификаторОбъектаМетаданных(MetadataRoleObject)");
	If Object["Роли"].Find(RoleReference) = Undefined Then
		NewRole = Object["Роли"].Add();
		NewRole["Роль"] = RoleReference;
	EndIf;        
	
	If Object.Modified() Then
		Object.Write();
	EndIf; 
	
	ProfileRef = Reference;
	
	AccessGroupsManager = Catalogs["ГруппыДоступа"]; //@skip-check unknown-method-property 
	
	Reference = AccessGroupsManager.GetRef(UUID); 
	Object    = Reference.GetObject();
	If Object = Undefined Then
		Object = AccessGroupsManager.CreateItem();       
		Object.SetNewObjectRef(Reference);
		Object.Description = StrTemplate("%1 (профиль не изменять)", Config.Caption);
	EndIf;  
	
	If Object["Профиль"] <> ProfileRef Then
		Object["Профиль"] = ProfileRef;
	EndIf;     

	CurrentUser = SessionParameters["ТекущийПользователь"];
	
	If Object["Пользователи"].Find(CurrentUser) = Undefined Then
		NewRow = Object["Пользователи"].Add();
		NewRow["Пользователь"] = CurrentUser;
	EndIf;        
	
	If Object.Modified() Then
		Object.Write();
	EndIf;  

EndProcedure

#EndRegion
