////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Client-side helpers for the embedded code editor element.

#Region Public				   
				   	
#Region EventHandlers

Async Procedure OnOpen(Form) Export
	
	FormParameters = Form[CodeEditorClientServer.FormParameterAttributeName()];
	
	If Not FormParameters.IsFileExtLoaded Then
		FormParameters.IsFileExtLoaded = Await LoadFileSystemExtension();
		If Not FormParameters.IsFileExtLoaded Then  
			Return;
		EndIf;   
	EndIf;
	
	If Not FormParameters.IsSourceFilesLoaded Then
		Await LoadEditorSourceFiles(FormParameters);
	EndIf;  
	
	FilePath = Await CopyFileAsync(
		FormParameters.SourceFilesCatalog + "index.html", 
		GenerateIndexFilePath(FormParameters.SourceFilesCatalog)
	);
	
	For Each KeyValue In FormParameters.Editors Do
		Form[KeyValue.Value.HTMLAttributeName] = FilePath; 
	EndDo;           
	
EndProcedure

Procedure OnLoaded(Form, Element) Export
	
	FormParameters = Form[CodeEditorClientServer.FormParameterAttributeName()];
	
	If Not FormParameters.IsSourceFilesLoaded Then
		Return;
	EndIf; 
	
	Editor = FindEditorByEditorElement(Form, Element);
	If Editor = Undefined Then
		Raise "Unknown editor form element - " + Element.Name;
	EndIf;
	
	Editor.IsLoaded = True; 
	
	InitEditorView(Form, Editor);
	//АктивироватьДополнительныеФункции();	
		
EndProcedure

Procedure OnAfterLoaded(Form) Export
	
	FormParameters = Form[CodeEditorClientServer.FormParameterAttributeName()];
	
	For Each KeyValue In FormParameters.Editors Do 
		
		Editor = KeyValue.Value;	
		EditorView = GetEditorView(Form, Editor);
		
		Text = GetFormAttributeByDataPath(Form, Editor.DataPath);
		
		EditorView.setLanguageMode(Editor.LanguageMode);
		SetEditorText(EditorView, Text, Undefined, False);
		EditorView.setOriginalText(Text);
		
		ClearMetadata(EditorView, Form);	 
				
		Element = GetEditorElement(Form, Editor);
		Element.ReadOnly = False;		
		
		If Editor.UseSubstituteEditor Then  
			//РедакторКодаВызовСервера.УдалитьПодменяемыйЭлемент(Форма, ПараметрыРедактора.ИмяПодменяемогоЭлемента);			
			SubstituteEditorElement = GetSubstituteEditorElement(Form, Editor);	
			SubstituteEditorElement.Visible = False;
			
			Element.BorderColor = New Color(255, 255, 255);
		
			Element.Height = 10;
			Element.Width  = 50; 
			
			Element.VerticalStretch   = True;
			Element.HorizontalStretch = True;
			
		EndIf;
		
	EndDo;
	
	Form.ReadOnly = False;
	Form.Modified = False;
	
EndProcedure

Procedure OnClick(Form, Element, EventData, StandardProcessing) Export

	If Form.ReadOnly Then  
		Return;
	EndIf;  
	
	Event = EventData.Event.eventData1C;
	If Event = Undefined Then
		Return;
	EndIf;
	
	EventName = Event.event;
	
	If EventName = "EVENT_QUERY_CONSTRUCT" Then	
		EditorView = GetEditorViewByElement(Form, Element);	
		ВызватьКонструкторЗапроса(EditorView, Event.params);
	ElsIf EventName = "EVENT_FORMAT_CONSTRUCT" Then  
		EditorView = GetEditorViewByElement(Form, Element);
		ВызватьКонструкторФорматнойСтроки(EditorView, Event.params);
	ElsIf EventName = "EVENT_GET_METADATA" Then
		//ОбработкаСобытияПолученияМетаданных(Событие.params);
	ElsIf EventName = "EVENT_CONTENT_CHANGED" Then    
		Form.Modified = True;
		
		Editor     = FindEditorByEditorElement(Form, Element);
		EditorView = GetEditorViewByElement   (Form, Element);
		
		SetFormAttributeByDataPath(Form, Editor.DataPath, EditorView.getText());		
		
	ElsIf EventName = "EVENT_ON_LINK_CLICK" Then
		If 0 < StrFind(Event.params.href, "e1cib") Then
			//ПерейтиПоНавигационнойСсылке(Событие.params.href);
		EndIf;
	ElsIf EventName = "EVENT_GET_VARIABLE_DATA" Then
		//ОбработкаСобытияПолученияПеременной(Событие.params);
	EndIf;	
	
EndProcedure

#EndRegion

Procedure ClearMetadata(EditorView, Form, Object = Undefined)
	
	FormParameters = Form[CodeEditorClientServer.FormParameterAttributeName()];
	
	EditorView.clearMetadata();
	
	//MetadataCollection = GetFromTempStorage(FormParameters.АдресОбщихМодулей);
	//
	//If MetadataCollection <> Undefined Then
	//	Result = EditorView.updateMetadata(MetadataCollection, "commonModules.items");
	//	//ЗагрузитьГлобальныеМодули();
	//EndIf;	
	
EndProcedure

#EndRegion      
                        
#Region Private  

#Region SourceFiles

Function GenerateIndexFilePath(Path)	
	Return Path + Format(CurrentUniversalDateInMilliseconds(), "ЧГ=0") + ".html";	
EndFunction

Async Function LoadEditorSourceFiles(FormParameters) 
	
	Version = FormParameters.Version;
	
	TempFilesDir   = Await TempFilesDirAsync(); 
	SourceFilesDir = TempFilesDir + "bsl_console" + GetClientPathSeparator();
	
	Await CreateDirectoryAsync(SourceFilesDir); 
	Exists  = Await FileExists(SourceFilesDir);
	If Not Exists Then              
		ShowError("Не удалось создать каталог для исходников", True);
		Return False;
	EndIf;
	
	VersionFileExists = Await FileExists(SourceFilesDir + Version + ".ver");
	IndexFileExists   = Await FileExists(SourceFilesDir + "index.html");

	Если Не VersionFileExists Или IndexFileExists Тогда 
		
		Await DeleteFilesAsync(SourceFilesDir, "*.*");
		
		TemplateData = GetFromTempStorage(FormParameters.EditorTemplateAddress);
		Await TemplateData.WriteAsync(SourceFilesDir + "bsl_console.zip");
		
		Try                              
			
			Reader = New ZipFileReader(SourceFilesDir + "bsl_console.zip");
			Reader.ExtractAll(SourceFilesDir);
			Writer = New TextWriter(SourceFilesDir + Version + ".ver");
			Writer.WriteLine(CurrentDate());
			Writer.Close();
						
		Except
			ShowError("Не удалось извлечь исходники" + Chars.LS + ErrorDescription(), True); 
			Return False;
		EndTry;   
		
	EndIf; 
	
	FormParameters.SourceFilesCatalog  = SourceFilesDir;
	FormParameters.IsSourceFilesLoaded = True;
		
	Return True;
	
EndFunction

#EndRegion 

#Region EditorGetters

Function FindEditorByEditorElement(Form, Element)
	
	FormParameters = Form[CodeEditorClientServer.FormParameterAttributeName()];

	For Each KeyValue In FormParameters.Editors Do
		Editor = KeyValue.Value;
		If Editor.EditorElementName = Element.Name Then
			Return Editor;
		EndIf;
	EndDo; 
	
	Return Undefined;
	
EndFunction

Function GetEditorElement(Form, Editor)
	
	Return Form.Items[Editor.EditorElementName];
	
EndFunction

Function GetSubstituteEditorElement(Form, Editor)
	
	Return Form.Items[Editor.SubstituteEditorName];
	
EndFunction

Function GetEditorView(Form, Editor)
	
	Return GetEditorElement(Form, Editor).Document.defaultView;
	
EndFunction

Function GetEditorViewByElement(Form, Element)
	
	Return Element.Document.defaultView;
	
EndFunction

#EndRegion

Procedure InitEditorView(Form, Editor)
	
	Info = New SystemInfo();
	
	EditorView = GetEditorView(Form, Editor);
	                      
	EditorView.init(Info.AppVersion);
	EditorView.setOption("autoResizeEditorLayout"   , True);
	EditorView.setOption("renderQueryDelimiters"    , True);
	EditorView.setOption("generateModificationEvent", True);
	EditorView.hideScrollX();
	EditorView.hideScrollY();
	
	Form.AttachIdleHandler("Attachable_CodeEditorOnAfterLoaded", 1, True);
	
EndProcedure

Procedure SetEditorText(EditorView, Text, Position, УчитыватьОтступПервойСтроки)
	
	EditorView.setText(Text, Position, УчитыватьОтступПервойСтроки);
	
EndProcedure

#Region Files

Function GetFormAttributeByDataPath(Form, DataPath)
	
	PathParts = StrSplit(DataPath, ".");
	
	Object   = Form;
	LastPart = PathParts[PathParts.Count() - 1];
	
	For Index = 0 To PathParts.Count() - 2 Do
		Object = Object[PathParts[Index]];
	EndDo;
	
	Return Object[LastPart];
	
EndFunction

Procedure SetFormAttributeByDataPath(Form, DataPath, Value, OnlyIfNotFilled = False)
	
	PathParts = StrSplit(DataPath, ".");
	
	Object   = Form;
	LastPart = PathParts[PathParts.Count() - 1];
	
	For Index = 0 To PathParts.Count() - 2 Do
		Object = Object[PathParts[Index]];
	EndDo;
	
	If Not OnlyIfNotFilled Or Not ValueIsFilled(Object[LastPart]) Then
		Object[LastPart] = Value;
	EndIf;
	
EndProcedure

#EndRegion

#Region Files

Async Function LoadFileSystemExtension()
	                                      
	Result = Await AttachFileSystemExtensionAsync();
	
	Return Result;
	
EndFunction

Async Function FileExists(FilePath)

	File = New File(FilePath);
	Return Await File.ExistsAsync();	

EndFunction

#EndRegion

Async Procedure ShowError(Text, CloseConsole)
	
	Await DoMessageBoxAsync(Text);	
	
	If CloseConsole Then
		//Ждать ЗакрытьКонсоль(Истина);
	EndIf;
	
EndProcedure

#Область КонструкторЗапросов

&НаКлиенте
Асинх Функция ОткрытьКонструкторЗапроса(EditorView, Текст, ДопПараметры)
	
	Конструктор = Новый КонструкторЗапроса();
	
	Если ЗначениеЗаполнено(Текст) Тогда
		Попытка
			Конструктор.Текст = Текст;
		Исключение
			Инфо = ИнформацияОбОшибке();
			ПоказатьПредупреждение(, "Ошибка в тексте запроса:" + Символы.ПС + Инфо.Причина.Описание);
			Возврат Ложь;
		КонецПопытки;
	КонецЕсли;
	
	Текст = Ждать Конструктор.ОткрытьАсинх();  
	
	Если Текст = Неопределено Тогда
		Возврат Ложь;
	КонецЕсли;
		
	Если Не EditorView.queryMode Тогда
		Текст = СтрЗаменить(Текст, Символы.ПС, Символы.ПС + "|");
		Текст = СтрЗаменить(Текст, """", """""");
		Текст = """" + Текст + """";
	КонецЕсли;
	
	SetEditorText(EditorView, Текст, ДопПараметры, Истина);
	
КонецФункции

&НаКлиенте
Функция ПодготовитьТекстЗапроса(Текст)
	
	ТекстЗапроса = СтрЗаменить(Текст, "|", "");
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, """""", "$");	
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, """", "");	
	ТекстЗапроса = СтрЗаменить(ТекстЗапроса, "$", """");
	
	Возврат ТекстЗапроса;
	
КонецФункции

&НаКлиенте
Асинх Процедура ВызватьКонструкторЗапроса(EditorView, ПараметрыЗапроса)
	
	ТекстЗапроса = "";
	ДопПараметры = Неопределено;
	
	Если ПараметрыЗапроса = Неопределено Тогда
		ТекстВопроса = "Не найден текст запроса." + Символы.ПС + "Создать новый запрос?";
		Ответ = Ждать ВопросАсинх(ТекстВопроса, РежимДиалогаВопрос.ДаНет); 
		Если Ответ = КодВозвратаДиалога.Нет Тогда
			Возврат;
		КонецЕсли;
	Иначе
		ТекстЗапроса = ПодготовитьТекстЗапроса(ПараметрыЗапроса.text);
		ДопПараметры = ПараметрыЗапроса.range;
	КонецЕсли;

	Ждать ОткрытьКонструкторЗапроса(EditorView, ТекстЗапроса, ДопПараметры);	
	
КонецПроцедуры

#КонецОбласти

#Область КонструкторФорматнойСтроки

&НаКлиенте
Асинх Процедура ОткрытьКонструкторФорматнойСтроки(EditorView, ФорматнаяСтрока, ДопПараметры)
	
	Конструктор = Новый КонструкторФорматнойСтроки();
	Попытка			
		Конструктор.Текст = ФорматнаяСтрока;
	Исключение
		Инфо = ИнформацияОбОшибке();
		ПоказатьПредупреждение(, "Ошибка в тексте форматной строки:" + Символы.ПС + Инфо.Причина.Описание);
		Возврат;
	КонецПопытки;
	
	ФорматнаяСтрока = Ждать Конструктор.ОткрытьАсинх();
	Если ФорматнаяСтрока = Неопределено Тогда	
		Возврат;
	КонецЕсли;

	ФорматнаяСтрока = СтрЗаменить(ФорматнаяСтрока, "'", "");
	ФорматнаяСтрока = """" + ФорматнаяСтрока + """";
	SetEditorText(EditorView, ФорматнаяСтрока, ДопПараметры, Ложь);	
	
КонецПроцедуры

&НаКлиенте
Асинх Процедура ВызватьКонструкторФорматнойСтроки(EditorView, ПараметрыСтроки)
	
	Текст        = "";
	ДопПараметры = Неопределено;
	
	Если ПараметрыСтроки = Неопределено Тогда
		ТекстВопроса = "Форматная строка не найдена." + Символы.ПС + "Создать новую форматную строку?";
		Ответ = Ждать ВопросАсинх(ТекстВопроса, РежимДиалогаВопрос.ДаНет);
		Если Ответ = КодВозвратаДиалога.Нет Тогда	
			Возврат;
		КонецЕсли;
	Иначе
		Текст        = СтрЗаменить(СтрЗаменить(ПараметрыСтроки.text, "|", ""), """", "");
		ДопПараметры = ПараметрыСтроки.range;	
	КонецЕсли;      
	
	ОткрытьКонструкторФорматнойСтроки(EditorView, Текст, ДопПараметры);
	
КонецПроцедуры

#КонецОбласти

#EndRegion

