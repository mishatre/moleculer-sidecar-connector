
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Params = New Structure();
	Params.Insert("withServices", True);
	Response = Moleculer.Call("$node.list", Params);
	
EndProcedure
