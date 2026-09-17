
#Region Protected

Function GetVersionedFullName(Name, Val Version = Undefined) Export
	If Version = Undefined Then
		Return Name;
	EndIf;
	Return StrTemplate("%1.%2",
		?(IsNumber(Version) OR CanBeNumber(Version), "v" + Format(Version, "NG="), Version),
		Name
	);
EndFunction 

#Region Validation

Function IsObject(Value) Export
	Return IsStructure(Value) Or IsMap(Value);
EndFunction

Function IsStructure(Value) Export
	Return TypeOf(Value) = Type("Structure");
EndFunction

Function IsMap(Value) Export
	Return TypeOf(Value) = Type("Map")	
EndFunction

Function IsString(Value) Export
	Return TypeOf(Value) = Type("String")
EndFunction

Function IsNumber(Value) Export
	Return TypeOf(Value) = Type("Number")	
EndFunction

Function IsBinaryData(Value) Export
	Return TypeOf(Value) = Type("BinaryData")	
EndFunction

Function IsValidDate(Value) Export
	Return TypeOf(Value) = Type("Date")	
EndFunction 

Function IsArray(Value) Export
	Return TypeOf(Value) = Type("Array")	
EndFunction

Function IsStream(Value) Export
	Return False 
		Or TypeOf(Value) = Type("Stream")
		Or TypeOf(Value) = Type("FileStream")
		Or TypeOf(Value) = Type("MemoryStream");	
EndFunction

Function CanBeNumber(Val Value) Export
	Try        
		Value = Number(Value);
		Return True;
	Except
		Return False;
	EndTry;
EndFunction

#EndRegion

#EndRegion