({
	closeQA : function(component, event, helper) 
	{
		console.log('closeQA');
		$A.get("e.force:closeQuickAction").fire();
	}
})