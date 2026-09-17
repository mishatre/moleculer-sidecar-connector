
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ManageForm(ThisForm);
	
EndProcedure 

#EndRegion

#Region FormHeaderItemsEventHandlers

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TestConnection(Command)
	TestConnectionAtServer();
EndProcedure  

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure ManageForm(Form)
	
	Items  = Form.Items;
	Object = Form.Object;
	
EndProcedure 

&AtServer
Procedure TestConnectionAtServer()
	
	TestParams = Moleculer.NewConnectionParams();		
	TestParams.Id        = New UUID();
	TestParams.Type      = "HTTP";
	TestParams.Endpoint  = Object.Endpoint;
	TestParams.Port      = Object.Port;
	TestParams.UseSSL    = Object.UseSSL;
	TestParams.AccessKey = Object.AccessKey;
	TestParams.SecretKey = Object.SecretKey;
	TestParams.Timeout   = Object.Timeout;
	
	Try
		Response = mol_Broker.GetSidecarNodeServices(TestParams);
	   	Status   = mol_Helpers.ToJSONString(Response, True);
	Except 
		Error = mol_Errors.GetCurrentError();
		If Error = Undefined Then
			Error = mol_Errors.FromErrorInfo(ErrorInfo());
		EndIf;
		Status = mol_Errors.ToString(Error);
	EndTry;
	
EndProcedure

#EndRegion

