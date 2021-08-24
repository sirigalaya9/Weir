import { LightningElement, wire, api } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import userId from '@salesforce/user/Id';
import FIELD_ID from '@salesforce/schema/Opportunity.Id';
import FIELD_PROGRESS_UPDATE from '@salesforce/schema/Opportunity.Progress_Update__c';
import FIELD_PROGRESS_UPDATE_REPORT from '@salesforce/schema/Opportunity.Progress_Update_Report__c';
import FIELD_PROGRESS_UPDATE_CREATED_DATE from '@salesforce/schema/Opportunity.Progress_Update_Created_Date__c';
import FIELD_PROGRESS_UPDATE_CREATED_BY from '@salesforce/schema/Opportunity.Progress_Update_Created_By__c';
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';

export default class ProgressUpdate extends LightningElement 
{
    @api 
    recordId;
    //fields = [FIELD_PROGRESS_UPDATE, FIELD_PROGRESS_UPDATE_REPORT];
    showSpinner = false;
    showConfirmation = false;
    mode = "edit";

    @wire(getObjectInfo, { objectApiName: OPPORTUNITY_OBJECT })
    opp;    

    progressUpdateValue;
    progressUpdateReportValue = false;

    get includeInReportOptions() {
        return [
            { label: 'Yes', value: 'Yes' },
            { label: 'No', value: 'No' },
        ];
    }    

    get showViewMode()
    {
        if (this.mode == 'view')
            return true;
        else
            return false;
    }

    get showEditMode()
    {
        if (this.mode == 'edit')
            return true;
        else
            return false;
    }    

    get progressUpdateLabel()
    {
        if (this.opp && this.opp.data)
        {
            return this.opp.data.fields.Progress_Update__c.label;
        }
        else
        {
            return '';
        }
    }

    get progressUpdateHelpText()
    {
        if (this.opp && this.opp.data)
        {
            return this.opp.data.fields.Progress_Update__c.inlineHelpText;
        }
        else
        {
            return '';
        }        
    }

    get progressUpdateReportLabel()
    {
        if (this.opp && this.opp.data)
        {
            return this.opp.data.fields.Progress_Update_Report__c.label;
        }
        else
        {
            return '';
        }
    }

    onEdit()
    {
        //this.showSpinner = true;
        this.mode = 'edit';
    }   

    onCancel()
    {        
        this.mode = "view";
        const closeQA = new CustomEvent('close');        
        this.dispatchEvent(closeQA);
    }

    onCancelConfirmation()
    {
        this.showConfirmation = false;
    }

    progressUpdateValueChanged(event)
    {        
        var value = event.currentTarget.value;   
        console.log(value);
        this.progressUpdateValue = value;        
    }

    progressUpdateReportValueChanged(event)
    {        
        var value = event.currentTarget.value;   
        console.log(value);
        if (value == 'Yes')
            this.progressUpdateReportValue = true;
        else
            this.progressUpdateReportValue = false;
    }

    onSave()
    {
        const allValid = [...this.template.querySelectorAll('lightning-radio-group')].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);     
        const allValid2 = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);          
        if (allValid == true && allValid2 == true)
        {
            const fields = {};
            fields[FIELD_ID.fieldApiName] = this.recordId;
            fields[FIELD_PROGRESS_UPDATE.fieldApiName] = this.progressUpdateValue;
            fields[FIELD_PROGRESS_UPDATE_REPORT.fieldApiName] = this.progressUpdateReportValue;
            fields[FIELD_PROGRESS_UPDATE_CREATED_DATE.fieldApiName] = new Date().toISOString();
            fields[FIELD_PROGRESS_UPDATE_CREATED_BY.fieldApiName] = userId;

            const recordInput = { fields };

            this.showSpinner = true;

            updateRecord(recordInput)
                .then(() => {                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Progress Update successfully updated',
                            variant: 'success'
                        })
                    );   
                    this.showConfirmation = false;
                    this.mode = 'view';   
                    this.showSpinner = false;       
                    this.progressUpdateReportValue = false; 
                    const closeQA = new CustomEvent('close');        
                    this.dispatchEvent(closeQA);                                              
                })
                .catch(error => {                    
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                    this.showSpinner = false;
                });
        }            
    }
}