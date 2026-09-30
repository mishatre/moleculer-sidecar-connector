////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Server-side helpers for the embedded code editor.

#Region Public

Procedure Initialize(Form, AdditionalParams = Undefined) Export
	
	Parameters = NewInitParameters();
	Parameters.LanguageMode = "bsl";
	
	If TypeOf(AdditionalParams) = Type("Structure") Then
		FillPropertyValues(Parameters, AdditionalParams);
	EndIf;
	
	FormParameters = InitializeFormObjects(Form, Parameters);
	
	If FormParameters.IsSourceFilesLoaded Then 
		Return;
	EndIf;             
	
	EditorBinaryData = GetCommonTemplate("CodeEditor");
	
	FormParameters.EditorTemplateAddress = PutToTempStorage(EditorBinaryData, New UUID());
	FormParameters.Version               = "20221014";

	// 1C Syntax info
	
	//CommonModulesCollection = GetCommonModuleCollection();
	//ЗаполнитьИменаОбщихМодулей(CommonModulesCollection);
	
	//Parameters.АдресОбщихМодулей = СохранитьОбщиеМодулиВХранилище(CommonModulesCollection); 	
	
EndProcedure

#Region Constructors

Function NewInitParameters() Export
	
	Result = New Structure();
	Result.Insert("PlacementGroupName"  , "");
	Result.Insert("CommandBarName"      , "");
	Result.Insert("DataPath"            , "");
	Result.Insert("EditorElementName"   , "");
	
	Result.Insert("UseSubstituteEditor" , False);
	Result.Insert("SubstituteEditorName", "");
	Result.Insert("LanguageMode"        , "");
	
	Result.Insert("HTMLAttributeName"   , "");	
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion 

#Region Private                              

Function InitializeFormObjects(Form, Parameters)
	
	AttributeName = CodeEditorClientServer.FormParameterAttributeName();
	
	PlacementGroupName = Parameters.PlacementGroupName;
	CommandBarName     = Parameters.CommandBarName;
	
	UseSubstituteEditor = Parameters.UseSubstituteEditor;
	
	FormParametersInitialized = Ложь;
	Attributes = Form.GetAttributes();
	For Each Attribute In Attributes Do
		If Attribute.Name = AttributeName Then
			FormParametersInitialized = True;
			Break;	
		EndIf;
	EndDo;
	
	If Not FormParametersInitialized Then
		NewAttribute = New FormAttribute(AttributeName, New TypeDescription());
		AddingAttributes = New Array();                                                                  
		AddingAttributes.Add(NewAttribute);
		Form.ChangeAttributes(AddingAttributes);   	
		Form[AttributeName] = NewFormParameters();
	EndIf;
	
	EditorParams = NewEditorParameters();               
	EditorParams.Id                   = StrReplace(String(New UUID()), "-", "");
	EditorParams.IsLoaded             = False;
	EditorParams.DataPath             = Parameters.DataPath;
	EditorParams.LanguageMode         = Parameters.LanguageMode;
	EditorParams.UseSubstituteEditor  = Parameters.UseSubstituteEditor;      
	
	If Parameters.HTMLAttributeName = "" Then
		EditorParams.HTMLAttributeName = "HTML_" + EditorParams.Id;
	Else
		EditorParams.HTMLAttributeName = Parameters.HTMLAttributeName;	
	EndIf;
	
	AddingAttributes = New Array();
	AddingAttributes.Add(
		New FormAttribute(EditorParams.HTMLAttributeName, New TypeDescription("String"))
	); 
	Form.ChangeAttributes(AddingAttributes);
	
	PlacementElement = ?(PlacementGroupName = "", Undefined, Form.Items[PlacementGroupName]);
	
	If UseSubstituteEditor Then
		
		If Parameters.SubstituteEditorName = "" Then
			EditorParams.SubstituteEditorName = "TextDocumentField_" + EditorParams.Id;
		Else
			EditorParams.SubstituteEditorName = Parameters.SubstituteEditorName;	
		EndIf;
		
		FoundElement = Form.Items.Find(EditorParams.SubstituteEditorName);
		If FoundElement <> Undefined Then
			// Validate?
		Else	
			NewElement = Form.Items.Add(EditorParams.SubstituteEditorName, Type("FormField"), PlacementElement);
			NewElement.Type          = FormFieldType.TextDocumentField;	
			NewElement.DataPath      = Parameters.DataPath;                             
			NewElement.TitleLocation = FormItemTitleLocation.None;  
			NewElement.ReadOnly      = True;
		EndIf;
		
	EndIf;
	
	If Parameters.EditorElementName = "" Then
		EditorParams.EditorElementName = "HTMLDocumentField_" + EditorParams.Id;
	Else     
		EditorParams.EditorElementName = Parameters.EditorElementName;
	EndIf;

	FoundElement = Form.Items.Find(EditorParams.EditorElementName);
	If FoundElement <> Undefined Then
		// Validate?
	Else
	
		NewElement = Form.Items.Add(EditorParams.EditorElementName, Type("FormField"), PlacementElement);
		NewElement.Type          = FormFieldType.HTMLDocumentField;	
		NewElement.DataPath      = EditorParams.HTMLAttributeName;                             
		NewElement.TitleLocation = FormItemTitleLocation.None;  
		NewElement.ReadOnly      = True;   
		NewElement.BorderColor   = New Color(255, 255, 255);
		
		NewElement.Height = 1;
		NewElement.Width  = 1; 
		
		NewElement.VerticalStretch   = False;
		NewElement.HorizontalStretch = False;
		
		NewElement.SetAction("DocumentComplete", "Attachable_CodeEditorOnReady");
		NewElement.SetAction("OnClick"         , "Attachable_CodeEditorOnClick");
		
	EndIf;
	
	Form[AttributeName].Editors.Insert(EditorParams.Id, EditorParams);
	
	Return Form[AttributeName];
	
EndFunction 

Function GetCommonModuleCollection()
	
	Result = New Structure();
	Result.Insert("Общие"     , New Structure());
	Result.Insert("Глобальные", New Structure());
	
	For Each CommonModule In Metadata.CommonModules Do
		CollectionName = ?(CommonModule.Global, "Глобальные", "Общие");
		Result[CollectionName].Insert(CommonModule.Name, New Structure());
	EndDo;
		
	Return Result;
	
EndFunction  

//Function СохранитьОбщиеМодулиВХранилище(КоллекцияОбщихМодулей)
//	
//	ЗаписьJSON = Новый ЗаписьJSON();
//	ЗаписьJSON.УстановитьСтроку();
//	Попытка
//	   ЗаписатьJSON(ЗаписьJSON, КоллекцияОбщихМодулей.Общие);
//	Исключение
//	   ВызватьИсключение("Не удалось сохранить коллекцию метаданных:" + Символы.ПС + ОписаниеОшибки());
//	КонецПопытки;
//	
//	Возврат ПоместитьВоВременноеХранилище(ЗаписьJSON.Закрыть(), Новый УникальныйИдентификатор());
//	
//EndFunction

//Procedure FillCommonModuleNames(КоллекцияОбщихМодулей)
//	
//	// Соответствие между именем общего неглобального модуля в нижнем регистре
//	// и именем модуля, как оно задано в конфигураторе для правильной загрузки
//	// текстов общих модулей
//	ОбщиеМодули = Новый Соответствие();
//	
//	Для Каждого Обход Из КоллекцияОбщихМодулей.Общие Цикл
//		ОбщиеМодули.Вставить(НРег(Обход.Ключ), Обход.Ключ);
//	КонецЦикла;
//	
//	ИменаОбщихМодулей = Новый ФиксированноеСоответствие(ОбщиеМодули);
//	
//	// Именя глобальных модулей для загрузки текстов
//	Модули = Новый Массив();
//	
//	Для Каждого Обход Из КоллекцияОбщихМодулей.Глобальные Цикл
//		Модули.Добавить(Обход.Ключ);
//	КонецЦикла;
//	
//	ГлобальныйМодули = Новый ФиксированныйМассив(Модули);
//	
//EndProcedure

#Region Constructors

Function NewFormParameters()
	
	Result = New Structure();   
	
	Result.Insert("Editors"              , New Map());
	Result.Insert("IsSourceFilesLoaded"  , False);
	Result.Insert("SourceFilesCatalog"   , False);
	Result.Insert("EditorTemplateAddress", ""  );
	Result.Insert("Version"              , ""  );
	Result.Insert("IsFileExtLoaded"      , False);
	
	Return Result;
	
EndFunction 

Function NewEditorParameters()

	Result = New Structure();   
	
	Result.Insert("Id");
	Result.Insert("IsLoaded");
	Result.Insert("DataPath");
	Result.Insert("LanguageMode");         
	Result.Insert("EditorElementName");
	Result.Insert("UseSubstituteEditor");
	Result.Insert("SubstituteEditorName"); 
	
	Result.Insert("HTMLAttributeName");
	
	Return Result;
	
EndFunction


#EndRegion

#EndRegion
