////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2026, M.Tregub
// SPDX-License-Identifier: MIT
// All rights reserved. This program and its accompanying materials are provided
// under the terms of the MIT License.
// The license text is available at:
// https://opensource.org/licenses/MIT
////////////////////////////////////////////////////////////////////////////////

// Admin panel main form.

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