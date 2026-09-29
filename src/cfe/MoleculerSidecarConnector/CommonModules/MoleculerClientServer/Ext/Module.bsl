
#Region Public

#Region Constructors

// Create opts object
//
// Returns:
//  Opts - Structure:
//  	* timeout          - Number, null  - Timeout of request in milliseconds.
//  	* retries          - Number, null  - Count of retry of request. 
//  	* fallbackResponse - Any, null     - Returns it, if the request has failed. 
//  	* nodeID           - String, null  - Target nodeID.   
//  	* meta             - Object {}     - Metadata of request.  
//  	* parentCtx        - Context, null - Parent Context instance.  
//  	* requestID        - String, null  - Request ID or Correlation ID.
Function NewOpts() Export

	Result = New Structure();            
	// timeout - Number, null - Timeout of request in milliseconds. 
	// If the request is timed out and you don’t define fallbackResponse, 
	// broker will throw a RequestTimeout error. To disable set 0. 
	// If it’s not defined, the requestTimeout value from broker options will be used.
	Result.Insert("timeout"         , null); 
	// retries - Number, null - Count of retry of request. If the request is timed out, 
	// broker will try to call again. To disable set 0. If it’s not defined, 
	// the retryPolicy.retries value from broker options will be used. 	
	Result.Insert("retries"         , null); 
	// fallbackResponse - Any, null - Returns it, if the request has failed.
	Result.Insert("fallbackResponse", null);     
	// nodeID - String, null - Target nodeID. If set, it will make a direct call to the specified node.
	Result.Insert("nodeID"          , null);                    
	// meta - Object {} - Metadata of request. Access it via ctx.meta in actions handlers.
	// It will be transferred & merged at nested calls, as well.
	Result.Insert("meta"            , New Map);   
	// parentCtx - Context, null - Parent Context instance. Use it to chain the calls.
	Result.Insert("parentCtx"       , null);
	// requestID - String, null - Request ID or Correlation ID. Use it for tracing.
	Result.Insert("requestID"       , null );
	// 15.0.0
	Result.Insert("stream"          , null );
	
	Return Result;

EndFunction 

Function NewMCallOpts() Export
	
	Result = NewOpts();
	Result.Insert("settled", false);
	
	Return Result;
	
EndFunction

Function NewActionDef(ActionName, Val Params = Undefined, Opts = Undefined) Export

	Result = New Structure();  
	Result.Insert("action" , ActionName);
	Result.Insert("params" , Params    );
	Result.Insert("options", Opts      );
	
	Return Result;
	
EndFunction

#EndRegion  



#EndRegion

#Region Internal

Function GetConfig() Export
	Return Moleculer.GetConfig();	
EndFunction

#EndRegion