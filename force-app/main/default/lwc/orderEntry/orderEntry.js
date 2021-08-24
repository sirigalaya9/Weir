import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';

import getQuoteLines from '@salesforce/apex/OrderEntryController.getQuoteLines';
import saveOrderEntry from '@salesforce/apex/OrderEntryController.saveOrderEntry';

const columns = [
    { label: 'Product Name', fieldName: 'Product_Name__c' },
    { label: 'Unit Price', fieldName: 'UnitPrice', type: 'currency' },
    { label: 'Quantity Available', fieldName: 'Quantity', type: 'number' },
    { label: 'Selected Quantity', fieldName: 'SelectedQuantity', type: 'number', editable: true },
    { label: 'Total Price', fieldName: 'TotalPrice', type: 'currency' }
];

export default class OrderEntry extends NavigationMixin(LightningElement) {

    @api recordId;
    columns = columns;
    step = "1";
    selectedRows = [];
    showSpinner = true;
    orderEntry = {};
    errors;
    @track quoteLines;
    quote;    
    selectedQuoteLines = [];    

    get showStep1() {
        if (this.step == "1") {
            return true;
        }
        else
            return false;
    }

    get showStep2() {
        if (this.step == "2") {
            return true;
        }
        else
            return false;
    }

    get showStep3() {
        if (this.step == "3") {
            return true;
        }
        else
            return false;
    }

    @wire(getRecord, { recordId: '$recordId', fields: ['Quote.AccountId','Quote.OpportunityId', 'Quote.IsSyncing', 'Quote.Opportunity.Sales_Office__c', 
    'Quote.Opportunity.Sales_Group__c', 'Quote.Opportunity.Shipping_Address__c'] })
    wiredRecord({ error, data }) {
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading contact',
                    message,
                    variant: 'error',
                }),
            );
            this.showSpinner = false;
        } else if (data) {
            this.quote = data;
            console.log(this.quote);
            this.orderEntry.Account__c = this.quote.fields.AccountId.value;
            this.orderEntry.Opportunity__c = this.quote.fields.OpportunityId.value;
            this.orderEntry.Quote__c = this.quote.id;                        
            this.orderEntry.Sales_Office__c = this.quote.fields.Opportunity.value.fields.Sales_Office__c.value;
            this.orderEntry.Sales_Group__c = this.quote.fields.Opportunity.value.fields.Sales_Group__c.value;
            this.orderEntry.Ship_To__c = this.quote.fields.Opportunity.value.fields.Shipping_Address__c.value;
            console.log('IsSyncing: ' + this.quote.fields.IsSyncing.value);
            if (!this.quote.fields.IsSyncing.value)
            {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Order Entry is only applicable for Synced Quotes.',
                        variant: 'error',
                    }),
                );    
                this.closeModal();
                this.showSpinner = false;
            }
            else
            {
                getQuoteLines({quoteId: this.recordId})
                .then(result => {
                    console.log(result);
                    this.quoteLines = JSON.parse(JSON.stringify(result));
                    this.quoteLines.forEach(item => {
                        item.SelectedQuantity = item.Quantity;
                        item.TotalPrice = item.Quantity * item.UnitPrice;
                    });                    
                    this.showSpinner = false;
                })
                .catch(error => {
                    console.log(error);
                    this.showSpinner = false;
                });
            }
        }
    }

    getSelectedRows(event) {
        console.log('getSelectedRows');
        const selectedRows = event.detail.selectedRows;
        this.selectedQuoteLines = [];
        for (let i = 0; i < selectedRows.length; i++) {
            console.log("You selected: " + selectedRows[i].Id);
            this.selectedQuoteLines.push(selectedRows[i].Id);
        }
    }

    cellChanged(event) {
        console.log('cellChanged');
        console.log(event.detail.draftValues);
        let draftValue = event.detail.draftValues[0];        
        this.errors = null;        
        this.quoteLines.forEach(item => {
            if (item.Id == draftValue.Id)
            {
                item.SelectedQuantity = draftValue.SelectedQuantity;
                item.TotalPrice = item.SelectedQuantity * item.UnitPrice;
            }
            if (item.SelectedQuantity > item.Quantity || item.SelectedQuantity <= 0) {
                if (this.errors == null) {
                    this.errors = {};
                    this.errors.rows = {};
                    this.errors.table = {
                        title: 'Your entry cannot be saved. Fix the errors and try again.',
                        /*
                        messages: [
                            'Row 2 amount must be number',
                            'Row 2 email is invalid'
                        ]
                        */
                    };
                }                
                this.errors.rows[item.Id] = {
                    title: 'Errors Found',
                    messages: [],
                    fieldNames: ['SelectedQuantity']
                };
                if (item.SelectedQuantity > item.Quantity)
                {
                    this.errors.rows[item.Id].messages.push('Selected Quantity cannot be greater than Available Quantity.' );
                }
                else if (item.SelectedQuantity <= 0)
                {
                    this.errors.rows[item.Id].messages.push('Selected Quantity cannot be less than or equal to 0.' );
                }                
                  
            }
        });        
    }

    next() {
        if (this.step == "1")
        {        
            this.step = "2";            
        }
        else if (this.step == "2")
        {            
            this.step = "3";            
        }
    }

    get nextDisabled() {
        if ((this.step == "1" || this.step == "2") && this.selectedQuoteLines.length > 0 && !this.errors)
            return false;
        else
            return true;
    }

    previous() {
        if (this.step == "3")
        {
            this.step = "2";            
        }
        else if (this.step == "2")
        {            
            this.step = "1";
            this.selectedRows = this.selectedQuoteLines;            
        }
    }

    get preDisabled() {
        if (this.step == "2" || this.step == "3")
            return false;
        else
            return true;
    }   
    
    get saveDisabled() {
        if (this.step == "3")
            return false;
        else
        return true;
    }

    handleChange(event)
    {
        let field = event.target.dataset.name;
        let value = event.target.value;
        console.log(field);
        console.log(value);
        this.orderEntry[field] = value;
    }

    save() {
        this.showSpinner = true;                             
        let entryItems = [];
        for (let i=0; i<this.quoteLines.length; i++)
        {
            let quoteLine = this.quoteLines[i];
            if (this.selectedQuoteLines.includes(quoteLine.Id))
            {
                entryItems.push({Product__c : quoteLine.Product2Id, Quantity__c : quoteLine.SelectedQuantity, UnitPrice__c : quoteLine.UnitPrice});
            }
        }
        saveOrderEntry({orderEntry: this.orderEntry, entryItems: entryItems})
        .then(result => {
            this.showSpinner = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Form saved',
                    variant: 'success',
                }),
            );            
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: result,
                    actionName: 'view'
                }
            });
        })
        .catch(error => {
            this.showSpinner = false;
            console.log(error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error creating record',
                    message: error.body.message,
                    variant: 'error',
                }),
            );            
        });
    }

    closeModal() {
        // to close modal set isModalOpen tarck value as false
        const closeQA = new CustomEvent('close');
        this.dispatchEvent(closeQA);
    }
}