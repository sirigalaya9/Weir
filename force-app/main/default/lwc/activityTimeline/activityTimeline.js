import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class ActivityTimeline extends NavigationMixin(LightningElement) {
    @api
    item;

    toggleActivity(event)
    {
        event.target.closest('.slds-timeline__item_expandable').classList.toggle('slds-is-open');
    }

    navigateToRecordPage(event)
    {
        console.log('navigateToRecordPage');
        let id = event.target.dataset.id;
        console.log(id);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: 'view',
            },
        });        
    }
}