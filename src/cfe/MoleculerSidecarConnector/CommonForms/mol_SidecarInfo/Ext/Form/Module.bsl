////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Shows sidecar connection and version information.

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Property("SidecarInfo") Then
		Raise "No info";		
	Else
		SidecarInfo = Parameters.SidecarInfo;
	EndIf;
	
	LoadSidecarInfo();	
	
EndProcedure          

&AtServer
Procedure LoadSidecarInfo()
	
	SidecarName    = SidecarInfo.Name;
	SidecarVersion = SidecarInfo.Version;
	SidecarAvailable  = SidecarInfo.Available;

	For Each KeyValue In SidecarInfo.Metadata Do
		
		If KeyValue.Key = "$description" Then
			SidecarMetadataDescription = KeyValue.Value;
		ElsIf KeyValue.Key = "$category" Then
			SidecarMetadataCategory = KeyValue.Value;
		ElsIf KeyValue.Key = "$official" Then
			SidecarMetadataOfficial = KeyValue.Value;
		EndIf;
		
	EndDo;
	
EndProcedure
