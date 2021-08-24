({

    doInit : function(component, event, helper) {
        var flow = component.find("flowData");
        var inputVariables = [{ name : "Idea_Id", type : "String", value: component.get("v.recordId")}];
        flow.startFlow("Vote_Save", inputVariables);
    },
    handleUpvote : function(component, event, helper) {

        component.set("v.isSpinner",true);
        component.set("v.Upvoted", true);
        component.set("v.Downvoted", false);
        
        var flow = component.find("flowData");
        var inputVariables = [
            { name : "Idea_Id", type : "String", value: component.get("v.recordId")},
            { name : "Vote_Type", type : "String", value: "up" }                       
        ];
        flow.startFlow("Vote_Save", inputVariables);
        var cmpTarget = component.find('flowData');
        $A.util.addClass(cmpTarget, 'changeMe');
        component.set("v.isSpinner",false);
    },
    
   
    // Downvote
    handleDownvote : function(component, event, helper) {
                        
        component.set("v.isSpinner",true);
        component.set("v.Upvoted", false);
        component.set("v.Downvoted", true);
        
        var flow = component.find("flowData");
        var inputVariables = [
            { name : "Idea_Id", type : "String", value: component.get("v.recordId")},
            { name : "Vote_Type", type : "String", value: "down" }                       
        ];
        flow.startFlow("Vote_Save", inputVariables);
        var cmpTarget = component.find('flowData');
        $A.util.addClass(cmpTarget, 'changeMe');
        component.set("v.isSpinner",false);
    },
    
    statusChange : function (cmp, event) {
        console.log(event.getParam('status'));
        if (event.getParam('status') === "FINISHED_SCREEN") {
            
            var outputVariables = event.getParam("outputVariables");
            var outputVar;
            for(var i = 0; i < outputVariables.length; i++) {
                outputVar = outputVariables[i];
                //alert("outputVar Value: "+outputVar.value);
                if (outputVar.value == "Up"){
                    cmp.set("v.Upvoted", true);
                    cmp.set("v.Downvoted", false);
                }
                else if (outputVar.value == "Down")
                {
                    cmp.set("v.Upvoted", false);
                    cmp.set("v.Downvoted", true);
                }
            }
            var cmpTarget = cmp.find('flowData');
            $A.util.addClass(cmpTarget, 'changeMe');
            $A.get('e.force:refreshView').fire();  
        }
    }

})