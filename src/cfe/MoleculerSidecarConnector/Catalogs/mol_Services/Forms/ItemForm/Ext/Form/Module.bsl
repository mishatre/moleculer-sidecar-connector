
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	//EditorParameters = CodeEditor.NewInitParameters();
	//EditorParameters.ИмяЭлементаДляРазмещения = "GroupParams";
	//EditorParameters.ПутьКДанным              = "Params";
	//EditorParameters.ПодменятьПриЗагрузке     = True;
	//EditorParameters.LanguageMode             = "json";	
	//CodeEditor.Initialize(ThisObject, EditorParameters);
		
EndProcedure 

&AtClient
Procedure OnOpen(Cancel)
	
	//CodeEditorClient.OnOpen(ThisObject);	
	
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


