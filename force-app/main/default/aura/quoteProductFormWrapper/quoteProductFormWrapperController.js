({
    doInit: function (cmp) {
        console.log('doInit');
        cmp.set("v.id", null);
        cmp.set("v.parentId", null);
        cmp.set("v.scopeOfSupply", null);
        var recordId = cmp.get("v.recordId");
        if (!recordId) {
            var pageRef = cmp.get("v.pageReference");
            recordId = pageRef.state.c__recordId;            
            if (recordId) {
                cmp.set("v.id", recordId);
            }
            else {
                var parentId = pageRef.state.c__parentId;
                cmp.set("v.parentId", parentId);
            }
            var scopeOfSupply = pageRef.state.c__scopeOfSupply;
            cmp.set("v.scopeOfSupply", scopeOfSupply);
        }
        else {
            cmp.set("v.id", recordId);
        }
        cmp.set("v.body", []);
        if (recordId) {
            $A.createComponent(
                "forceChatter:publisher",
                {
                    "context": "RECORD",
                    "recordId": recordId
                },
                function(recordPublisher){
                    //Add the new button to the body array
                    if (cmp.isValid()) {
                        var body = cmp.get("v.body");
                        body.push(recordPublisher);
                        cmp.set("v.body", body);
                        let recordId = cmp.get("v.id");
                        $A.createComponent(
                            "forceChatter:feed",
                            {
                                "type": "Record",
                                "subjectId": recordId
                            },
                            function(recordFeed){
                                //Add the new button to the body array
                                if (cmp.isValid()) {
                                    var body = cmp.get("v.body");
                                    body.push(recordFeed);
                                    cmp.set("v.body", body);
                                }
                            }
                        );                           
                    }
                }
            );
        }    
        //console.log("recordId: " + cmp.get("v.recordId"));
    }
})