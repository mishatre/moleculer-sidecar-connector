////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// In-memory reusable-value cache with change tracking.

#Region Protected 

Function GetConfig() Export
	Return Moleculer.GetConfig(True);	
EndFunction 

Function GetConnections() Export
	Return Moleculer.GetConnections(True);	
EndFunction

Function GetPublications() Export
	Return Moleculer.GetPublications(True);	
EndFunction

Function GetServiceModules(ModulePrefix) Export
	Return Moleculer.GetServiceModules(True, ModulePrefix);	
EndFunction

Function GetServices() Export
	Return Moleculer.GetServices(True);	
EndFunction

#Region HTTPConnection

Function GetHTTPConnectionCache() Export
	Return New Map();	
EndFunction

#EndRegion   

#Region Crypto

Function GetAlignmentBuffer(BlockSize, Value) Export

	AlignmentBuffer = New BinaryDataBuffer(BlockSize);
	For Index = 0 To BlockSize - 1 Do
		AlignmentBuffer.Set(Index, Value);
	EndDo; 
	
	Return AlignmentBuffer;
	
EndFunction

#EndRegion

#Region Regex

Function GetRegexCache(Pattern) Export

	If StrStartsWith(Pattern, "$") Then
		Pattern = "\\" + Pattern;
	EndIf;
	
	Pattern = StrReplace(Pattern, "?", ".");
	Pattern = StrReplace(Pattern, "**", "§§§");
	Pattern = StrReplace(Pattern, "*", "[^\\.]*");
	Pattern = StrReplace(Pattern, "§§§", ".*");

	Pattern = "^" + Pattern + "$";
	
	Return Pattern;
	
EndFunction

#EndRegion

#Region BSPIntegration

Function BSPVersion() Export      
	
	SetPrivilegedMode(True);
	
	If True
		И Metadata.InformationRegisters.Find("ВерсииПодсистем") <> Undefined 
		И AccessRight("Read", Metadata.InformationRegisters["ВерсииПодсистем"])
	Then
		Query = New Query(
		"SELECT
		|	Elements.Версия AS Version
		|FROM
		|	InformationRegister.ВерсииПодсистем КАК Elements
		|WHERE
		|	Elements.ИмяПодсистемы = &Subsystem");
		Query.SetParameter("Subsystem", "СтандартныеПодсистемы");
		
		Table = Query.Execute().Unload();
		If Table.Count() > 0 Then
			Return Table[0].Version;
		EndIf; 
	EndIf;     
	
	Return Undefined;
	
EndFunction

Function BSPVersionAsNumber() Export 
	
	Version = mol_Reuse.BSPVersion();
	If Not ValueIsFilled(Version) Then
		Return 0;
	EndIf;
			
	Parts = StrSplit(Version, ".");
	Return Number(Parts[0]) * 100 + Number(Parts[1]);

EndFunction 

#EndRegion

#EndRegion