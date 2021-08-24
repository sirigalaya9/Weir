import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecordCreateDefaults } from 'lightning/uiRecordApi';
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMasterData from '@salesforce/apex/QuoteProductFormController.getMasterData';
import { reduceErrors } from 'c/utils';

export default class QuoteProductWizard extends NavigationMixin(LightningElement) {
    @api scopeOfSupply;
    objectApiName = 'Pump__c';
    recordTypeId;    
    recordDefaults;
    layout;
    _recordId;
    _parentId;
    form;
    close;
    master;    
    showSpinner = true;    
    isLoading = false;   
    showForm = false;     
    activeTab;

    //Can also use getRecordUi but after record is created (using recordId)
    @wire(getRecordCreateDefaults, { objectApiName: '$objectApiName', recordTypeId: '$recordTypeId' })
    getWiredRecordCreateDefaults({ data, error }) {
        if (data) {
            console.log('getWiredRecordCreateDefaults');
            console.log(data);
            this.recordDefaults = data;
            if (this.recordTypeId) //Only show layout if record type is selected
            {
                this.layout = {};
                this.layout.sections = [];
                data.layout.sections.forEach(item => {
                    if (item.heading !== 'Fields') //Don't show first section from page layout (normally named 'Fields')
                    {
                        let itemClone = JSON.parse(JSON.stringify(item)); //Clone hack because Cannot add property value, object is not extensible
                        this.layout.sections.push(itemClone);                        
                        if (this.form)
                        {
                            itemClone.layoutRows.forEach(layoutRow => {
                                layoutRow.layoutItems.forEach(layoutItem => {
                                    layoutItem.layoutComponents.forEach(layoutComponent => {
                                        if (this.form.fields[layoutComponent.apiName])
                                            layoutComponent.value = this.form.fields[layoutComponent.apiName].value;
                                    });
                                });                            
                            });
                        }
                    }
                });
                if (this.form) //fields already rendered load values
                {
                    this.template.querySelectorAll("[data-field]").forEach(item => {
                        let fieldApiName = item.getAttribute('data-field');
                        console.log(fieldApiName);
                        item.value = this.form.fields[fieldApiName].value;
                    });                
                }
                this.renderFormData();
            }
        }
        if (error) {
            console.log(error);
        }
    }

    get recordTypeOptions() {
        let recordTypeOptions = [];
        if (this.recordDefaults && this.recordDefaults.objectInfos[this.objectApiName])
        {
            let recordTypeInfos = this.recordDefaults.objectInfos[this.objectApiName].recordTypeInfos;            
            Object.entries(recordTypeInfos).forEach(item => {     
                let recordTypeId = item[0];
                if (recordTypeId !== '012000000000000AAA') //Don't include "Master" RT
                {
                    let recordTypeInfo = item[1];
                    let option = {label: recordTypeInfo.name, value: recordTypeInfo.recordTypeId};
                    recordTypeOptions.push(option);
                }
            });
        }
        return recordTypeOptions;
    }    

    handleRecordTypeChange(event) {
        console.log('handleRecordTypeChange: ' + event.target.value);
        this.recordTypeId = event.target.value;        
    }

    @api
    set recordId(val) {        
        console.log('recordId: ' + val);
        this._recordId = val;        
        if (!val) { //Reset form if no record id
            this.reset();
        }
        else {
            this.showForm = true;
            this.isLoading = true;
        }
    }

    get recordId() {
        return this._recordId;
    }

    @api
    set parentId(val) {
        console.log('parentId: ' + val);
        this._parentId = val;
        this.reset();
    }

    get parentId() {
        return this._parentId;
    }

    reset() {
        console.log('reset');
        this.recordTypeId = null;
        this.template.querySelectorAll("[data-field]").forEach(item => {
            item.value = null;
        });
        this.template.querySelectorAll("[data-default]").forEach(item => {
            item.className = 'slds-show';            
        });
        this.template.querySelectorAll("[data-changed]").forEach(item => {
            item.className = 'slds-hide';            
        });   
    }

    get bomCode() {
        //console.log('get bomCode');
        let type = '';
        let size = '';
        let bearing = '';
        let buildCode = '';
        this.isLoading; //Just to trigger on load
        let bomCode = '';
        if (this.recordTypeOptions)
        {
            if (this.template.querySelector("[data-rt-field='RecordTypeId']") && this.template.querySelector("[data-rt-field='RecordTypeId']").value)
            {
                type = this.template.querySelector("[data-rt-field='RecordTypeId']").value;
                type = this.recordTypeOptions.find(item => item.value === type).label;
            }
            if (this.template.querySelector("[data-field='AH_Pump_Size__c']") && this.template.querySelector("[data-field='AH_Pump_Size__c']").value)
                size = this.template.querySelector("[data-field='AH_Pump_Size__c']").value;
            if (this.template.querySelector("[data-field='AH_Bearing__c']") && this.template.querySelector("[data-field='AH_Bearing__c']").value)
                bearing = this.template.querySelector("[data-field='AH_Bearing__c']").value;  
            if (this.template.querySelector("[data-field='AH_Build_Code__c']") && this.template.querySelector("[data-field='AH_Build_Code__c']").value)
                buildCode = this.template.querySelector("[data-field='AH_Build_Code__c']").value;    
    
            if (type && size && bearing && buildCode)
                bomCode = type + size.replace('.','').replace('/','') + bearing + '/' + buildCode;   
        }     
        return bomCode;
    }

    get bomLookup() {
        //console.log('get bomLookup');
        let bomCode = this.bomCode;
        let bomUnique = '';        
        this.isLoading; //Just to trigger on load
        if (this.template.querySelector("[data-field='BOM_Unique__c']") && this.template.querySelector("[data-field='BOM_Unique__c']").value)
            bomUnique = this.template.querySelector("[data-field='BOM_Unique__c']").value;
        if (bomCode && bomUnique)
            return bomCode + '-' + bomUnique;
        else
            return '';
    }    

    connectedCallback() {
        console.log('connectedCallback');
    }

    renderedCallback() {
        console.log('renderedCallback');
    }

    renderFormData()
    {
        console.log('renderFormData');        
        //Compare with master
        let buildCode = this.template.querySelector("[data-field='AH_Build_Code__c']").value;            
        getMasterData({ objectApiName: this.objectApiName, buildCode: buildCode })
            .then(result => {
                console.log(result);
                this.master = result;
                if (result)
                {                  
                    Object.keys(result).forEach(fieldApiName => {   
                        if (this.template.querySelector("[data-field='" + fieldApiName + "']"))
                        {
                            //console.log(fieldApiName);
                            let value = this.template.querySelector("[data-field='" + fieldApiName + "']").value;
                            //console.log(value);
                            if (value === result[fieldApiName])
                            {
                                if (this.template.querySelector("[data-default='" + fieldApiName + "']"))
                                    this.template.querySelector("[data-default='" + fieldApiName + "']").className = 'slds-show';
                                if (this.template.querySelector("[data-changed='" + fieldApiName + "']"))
                                    this.template.querySelector("[data-changed='" + fieldApiName + "']").className = 'slds-hide';
                            }
                            else
                            {
                                if (this.template.querySelector("[data-default='" + fieldApiName + "']"))
                                    this.template.querySelector("[data-default='" + fieldApiName + "']").className = 'slds-hide';
                                if (this.template.querySelector("[data-changed='" + fieldApiName + "']"))
                                    this.template.querySelector("[data-changed='" + fieldApiName + "']").className = 'slds-show';                                    
                            }                            
                            if (result[fieldApiName] === 'N/A') {
                                console.log(fieldApiName + ':' + result[fieldApiName]);                                
                                this.template.querySelector("[data-field='" + fieldApiName + "']").disabled = true;    
                                if (this.template.querySelector("[data-default='" + fieldApiName + "']"))                            
                                    this.template.querySelector("[data-default='" + fieldApiName + "']").className = 'slds-hide';
                                if (this.template.querySelector("[data-changed='" + fieldApiName + "']"))
                                    this.template.querySelector("[data-changed='" + fieldApiName + "']").className = 'slds-hide';
                            }                            
                        }                                                         
                    });
                }                  
                this.isLoading = false;
            })
            .catch(error => {
                console.log(error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error querying defaults',
                        message: reduceErrors(error).toString(),
                        variant: 'error'
                    })
                );                      
                this.isLoading = false;
            });    
    }

    @wire(getRecord, { recordId: '$_recordId', layoutTypes: 'Full' })
    wiredRecord({ error, data }) {
        console.log('getRecord');
        if (error) {            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading',
                    message: reduceErrors(error),
                    variant: 'error',
                }),
            );
        }
        else if (data) {
            console.log(data);            
            this.recordTypeId = data.recordTypeId;
            this._parentId = data.fields.Quote_Line_Item__c.value;
            this.form = data;            
        }
        this.showSpinner = false;
    }

    handleChange(event) {
        console.log('handleChange');
        console.log('loading: ' + this.isLoading);
        if (this.isLoading) {
            return;
        }
        this.isLoading = true;
        let field = event.target.dataset.field;
        let value = event.target.value;
        console.log(field + " > " + value);
        this.isLoading = false;
        if (field == 'AH_Build_Code__c') {
            this.showSpinner = true;           
            getMasterData({ objectApiName: this.objectApiName, buildCode: value })
                .then(result => {
                    this.master = result;
                    console.log('handleChange: getMasterData');
                    console.log(result);
                    if (result)
                    {
                        this.layout.sections.forEach(section => {
                            section.layoutRows.forEach(layoutRow => {
                                layoutRow.layoutItems.forEach(layoutItem => {
                                    layoutItem.layoutComponents.forEach(layoutComponent => {
                                        let fieldApiName = layoutComponent.apiName;
                                        if (result[layoutComponent.apiName])
                                        {
                                            let resultValue = result[layoutComponent.apiName];                                            
                                            if (resultValue !== 'N/A')
                                            {
                                                layoutComponent.value = resultValue;
                                                if (this.template.querySelector("[data-field='" + fieldApiName + "']"))
                                                    this.template.querySelector("[data-field='" + fieldApiName + "']").value = resultValue;
                                                layoutComponent.disabled = false;
                                                layoutComponent.isDefault = true;
                                                layoutComponent.isChanged = false;
                                            }
                                            else
                                            {
                                                layoutComponent.value = null;
                                                if (this.template.querySelector("[data-field='" + fieldApiName + "']"))
                                                    this.template.querySelector("[data-field='" + fieldApiName + "']").value = null;
                                                layoutComponent.disabled = true;
                                                layoutComponent.defaultClass = false;
                                                layoutComponent.changedClass = false;                                               
                                            }
                                        }
                                        else
                                        {
                                            layoutComponent.value = null;
                                            if (this.template.querySelector("[data-field='" + fieldApiName + "']"))
                                                this.template.querySelector("[data-field='" + fieldApiName + "']").value = null;
                                            layoutComponent.disabled = false;
                                            layoutComponent.defaultClass = true;
                                            layoutComponent.changedClass = false;                                             
                                        }
                                    });
                                });                            
                            });
                        });
                    }
                    else
                    {
                        console.log('hide default/changed icon');
                        this.template.querySelectorAll("[data-field]").forEach(item => {
                            item.disabled = false;            
                        });                        
                        this.template.querySelectorAll("[data-default]").forEach(item => {
                            item.className = 'slds-hide';            
                        });
                        this.template.querySelectorAll("[data-changed]").forEach(item => {
                            item.className = 'slds-hide';            
                        });                        
                    }
                    this.showSpinner = false;
                })
                .catch(error => {
                    console.log(error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error querying defaults',
                            message: reduceErrors(error).toString(),
                            variant: 'error'
                        })
                    );                    
                    //this.reset();
                    this.showSpinner = false;
                });
        }
        else if (this.master) {
            this.layout.sections.forEach(section => {
                section.layoutRows.forEach(layoutRow => {
                    layoutRow.layoutItems.forEach(layoutItem => {
                        layoutItem.layoutComponents.forEach(layoutComponent => {
                            if (layoutComponent.apiName === field)
                            {
                                if (this.master[field] === value || (!this.master[field] && !value)) 
                                {
                                    layoutComponent.isDefault = true;
                                    layoutComponent.isChanged = false;
                                }
                                else
                                {
                                    layoutComponent.isDefault = false;
                                    layoutComponent.isChanged = true;                                
                                }
                            }
                        });
                    });                            
                });
            });
/*
            if (this.master[field] == value || (!this.master[field] && !value)) {
                if (this.template.querySelector("[data-default='" + field + "']"))
                    this.template.querySelector("[data-default='" + field + "']").className = 'slds-show';
                if (this.template.querySelector("[data-changed='" + field + "']"))
                    this.template.querySelector("[data-changed='" + field + "']").className = 'slds-hide';
            }
            else {
                if (this.template.querySelector("[data-default='" + field + "']"))
                    this.template.querySelector("[data-default='" + field + "']").className = 'slds-hide';
                if (this.template.querySelector("[data-changed='" + field + "']"))
                    this.template.querySelector("[data-changed='" + field + "']").className = 'slds-show';
            }    
            */        
        }
    }

    cancelForm() {
        console.log('cancelForm');
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this._parentId,
                actionName: 'view'
            }
        });
    }

    closeForm() {
        console.log('closeForm');
        this.dispatchEvent(new CustomEvent('closeproductform'));
    }

    nextStep() {
        console.log('nextStep');
        let scopeOfSupply = this.template.querySelector("[data-input='Scope_of_Supply__c']").value;
        this.scopeOfSupply = scopeOfSupply;
        console.log(scopeOfSupply);
        if (scopeOfSupply.startsWith('Pump'))
        {
            this.objectApiName = 'Pump__c';
            let productType = this.template.querySelector("[data-input='Product_Type__c']").value;
            this.recordTypeId = this.recordTypeOptions.find(item => item.label === productType).value;            
        }
        else
        {
            this.objectApiName = scopeOfSupply;
        }
        this.showForm = true;
    }

    saveAndCloseForm() {
        this.close = true;
        this.saveForm();
    }

    handleActive(event) {
        console.log('handleActive');
        console.log(event.target.value);
        /*
        if (this.master)
        {
            let result = this.master;
            Object.keys(result).forEach(fieldApiName => {   
                if (result[fieldApiName] !== 'N/A') {
                    if (this.template.querySelector("[data-field='" + fieldApiName + "']"))                         
                        this.template.querySelector("[data-field='" + fieldApiName + "']").value = result[fieldApiName];
                    if (this.template.querySelector("[data-default='" + fieldApiName + "']"))
                        this.template.querySelector("[data-default='" + fieldApiName + "']").className = 'slds-show';
                    if (this.template.querySelector("[data-changed='" + fieldApiName + "']"))
                        this.template.querySelector("[data-changed='" + fieldApiName + "']").className = 'slds-hide';
                }
                else {
                    console.log(fieldApiName + ':' + result[fieldApiName]);
                    if (this.template.querySelector("[data-field='" + fieldApiName + "']")) 
                    {
                        this.template.querySelector("[data-field='" + fieldApiName + "']").disabled = true;    
                        this.template.querySelector("[data-field='" + fieldApiName + "']").value = null;
                    }
                    if (this.template.querySelector("[data-default='" + fieldApiName + "']"))                            
                        this.template.querySelector("[data-default='" + fieldApiName + "']").className = 'slds-hide';
                    if (this.template.querySelector("[data-changed='" + fieldApiName + "']"))
                        this.template.querySelector("[data-changed='" + fieldApiName + "']").className = 'slds-hide';
                }                                                                 
            });
        }
        else
        {
            console.log('hide default/changed icon');
            this.template.querySelectorAll("[data-field]").forEach(item => {
                item.disabled = false;            
            });                        
            this.template.querySelectorAll("[data-default]").forEach(item => {
                item.className = 'slds-hide';            
            });
            this.template.querySelectorAll("[data-changed]").forEach(item => {
                item.className = 'slds-hide';            
            });                        
        }      
        */  
    }

    saveForm() {
        this.showSpinner = true;
        const fields = {};

        this.template.querySelectorAll("[data-field]").forEach(item => {
            let fieldApiName = item.getAttribute('data-field');
            fields[fieldApiName] = item.value;
        });       

        const recordInput = { fields };

        if (this._recordId) {
            fields.Id = this._recordId;
            fields.RecordTypeId = this.recordTypeId;

            updateRecord(recordInput)
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Form saved',
                            variant: 'success'
                        })
                    );
                    // Display fresh data in the form
                    //return refreshApex(this.contact);
                    if (this.close) {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this._parentId,
                                actionName: 'view'
                            }
                        });
                    }
                    this.close = false;
                    this.showSpinner = false;
                })
                .catch(error => {                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error updating record',
                            message: reduceErrors(error).toString(),
                            variant: 'error'
                        })
                    );
                    this.close = false;
                    this.showSpinner = false;
                });
        }
        else {
            //fields[QUOTE_LINE_ITEM_FIELD.fieldApiName] = this._parentId;
            recordInput.apiName = this.objectApiName;
            fields.RecordTypeId = this.recordTypeId;     
            fields.Quote_Line_Item__c = this._parentId;       
            createRecord(recordInput)
                .then(record => {
                    console.log(record);
                    this._recordId = record.id;
                    this.updateQuoteLineItem(record.id);
                    /*
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Record created',
                            variant: 'success',
                        }),
                    );
                    if (this.close) {
                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this._parentId,
                                actionName: 'view'
                            }
                        });
                    }
                    this.close = false;
                    this.showSpinner = false;
                    */
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: reduceErrors(error),
                            variant: 'error',
                        }),
                    );
                    this.close = false;
                    this.showSpinner = false;
                });
        }
    }

    toggleSection(event) {        
        let section = event.currentTarget.dataset.targetsection;
        console.log(section);
        if (this.template.querySelector("[data-section='" + section + "']").classList.contains('slds-is-open'))
        {
            this.template.querySelector("[data-section='" + section + "']").classList.remove('slds-is-open');
            this.template.querySelector("[data-section='" + section + "']").classList.add('slds-is-closed');
        }
        else
        {
            this.template.querySelector("[data-section='" + section + "']").classList.remove('slds-is-closed');
            this.template.querySelector("[data-section='" + section + "']").classList.add('slds-is-open');            
        }
        event.preventDefault();
    }    

    updateQuoteLineItem(productFormId) {
        console.log('updateQuoteLineItem');
        const fields = {};
        const recordInput = { fields };
        fields.Id = this._parentId;
        fields.Pump__c = productFormId;
        fields.Scope_of_Supply__c = this.scopeOfSupply;

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Form saved',
                        variant: 'success'
                    })
                );
                // Display fresh data in the form
                //return refreshApex(this.contact);
                if (this.close) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            recordId: this._parentId,
                            actionName: 'view'
                        }
                    });
                }
                this.close = false;
                this.showSpinner = false;
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error creating record',
                        message: reduceErrors(error),
                        variant: 'error'
                    })
                );
                this.close = false;
                this.showSpinner = false;
            });        
    }


}