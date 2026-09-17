  
#Region FormEventHandlers  
  
&AtClient
Procedure OnOpen(Cancel)
	Cancel = True;
	ShowMessageBox(
		, 
		NStr("
		|ru = 'Обработка не предназначена для непосредственного использования.'
		|en = 'Data processor is not designed for direct usage'")
	);
EndProcedure

#EndRegion