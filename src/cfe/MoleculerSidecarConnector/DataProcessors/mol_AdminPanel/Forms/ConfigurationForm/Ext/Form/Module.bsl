	  
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Standalone = Moleculer.IsStandalone();
	
	ManageForm(ThisForm);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FormItemOnChange(Item)
	OnAttributeChange(Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OpenConnections(Command)
	OpenForm(
		"Catalog.mol_Connections.ListForm", 
		Undefined, 
		ThisForm
	);
EndProcedure

&AtClient
Procedure OpenPublications(Command)
	OpenForm(
		"Catalog.mol_Publications.ListForm", 
		Undefined, 
		ThisForm
	);
EndProcedure

&AtClient
Procedure OpenDynamicServices(Command)
	OpenForm(
		"Catalog.mol_Services.ListForm", 
		Undefined, 
		ThisForm
	);
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ManageForm(Form, DataPath = "")
	
	Items        = Form.Items;
	ConstantsSet = Form.ConstantsSet;
	
	If DataPath = "ConstantsSet.mol_UseProxy" Or DataPath = "" Then
		Items.GroupUseProxy.Enabled = ConstantsSet.mol_UseProxy;	
	EndIf;
	
	If DataPath = "ConstantsSet.mol_PublishServices" Or DataPath = "" Then
		PublicationEnabled = ConstantsSet.mol_PublishServices;
		Items.ConstantsSetmol_Namespace.Enabled = PublicationEnabled;
		Items.OpenPublications         .Enabled = PublicationEnabled;
		Items.GroupDynamicServices     .Enabled = PublicationEnabled;
	EndIf;    
		
	If DataPath = "ConstantsSet.mol_UseDynamicServices" Or DataPath = "" Then
		Items.OpenDynamicServices.Enabled = Not Form.Standalone And ConstantsSet.mol_UseDynamicServices;
	EndIf;
	
EndProcedure 

#Region Attributes

&AtClient
Procedure OnAttributeChange(Item, UpdateInterface = True)
	
	ConstantName = OnAttributeChangeAtServer(Item.Name);
	RefreshReusableValues();
	
	//If UpdateInterface Then
	//	AttachIdleHandler("UpdateAppInterface", 2, True);	
	//EndIf;                                               
	//
	//SetVisibilityOnClient(ConstantName);
	
	If ConstantName <> "" Then
		Notify("Write_ConstantsSet", New Structure, ConstantName);
	EndIf;
	
EndProcedure

&AtServer
Function OnAttributeChangeAtServer(ElementName)

    DataPathAttribute = Items[ElementName].DataPath;
	ConstantName = SaveAttributeValue(DataPathAttribute);
	ManageForm(ThisForm, DataPathAttribute);
	RefreshReusableValues();
	
	Return ConstantName;
		
EndFunction

&AtServer
Function SaveAttributeValue(DataPathAttribute)
	
	If DataPathAttribute = "" Then
		Return "";
	EndIf;
	
	NameParts = StrSplit(DataPathAttribute, ".");
	
	If NameParts.Count() = 2 Then
		ConstantName  = NameParts[1];
		ConstantValue = ConstantsSet[ConstantName];
	ElsIf NameParts.Count() = 1 And Lower(Left(DataPathAttribute, 8)) = Lower("Constant") Then
		ConstantName  = Mid(DataPathAttribute, 9);
		ConstantValue = ConstantsSet[ConstantName];          
	Else
		Return "";
	EndIf;        
	
	If Constants[ConstantName].Get() <> ConstantValue Then
		Constants[ConstantName].Set(ConstantValue);
	EndIf;
	
	Return ConstantName;
	
EndFunction

#EndRegion

#EndRegion







