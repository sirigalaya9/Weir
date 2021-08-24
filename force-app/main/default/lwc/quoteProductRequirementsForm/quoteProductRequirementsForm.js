import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMasterData from '@salesforce/apex/QuoteProductRequirementsFormController.getMasterData';
import getPriceData from '@salesforce/apex/QuoteProductRequirementsFormController.getPriceData';

import PRODUCT_REQUIREMENTS_FORM_OBJECT from '@salesforce/schema/Cyclone__c';
import ID_FIELD from '@salesforce/schema/Cyclone__c.Id';
import QUOTE_LINE_ITEM_FIELD from '@salesforce/schema/Cyclone__c.Quote_Line_Item__c';
import NAME_FIELD from '@salesforce/schema/Cyclone__c.Name';
import ORIGINATOR_FIELD from '@salesforce/schema/Cyclone__c.Originator__c';
import DATE_FIELD from '@salesforce/schema/Cyclone__c.Date__c';
import PROJECT_FIELD from '@salesforce/schema/Cyclone__c.Project__c';
import QUOTE_NO_FIELD from '@salesforce/schema/Cyclone__c.Quote_No__c';
import ORDER_NO_FIELD from '@salesforce/schema/Cyclone__c.Order_No__c';
import SERIAL_NUMBER_FIELD from '@salesforce/schema/Cyclone__c.Serial_Number__c';
import REVISION_FIELD from '@salesforce/schema/Cyclone__c.Revision__c';
import CUSTOMER_FIELD from '@salesforce/schema/Cyclone__c.Customer__c';
import TAG_NR_FIELD from '@salesforce/schema/Cyclone__c.TAG_Nr__c';
import QUANTITY_FIELD from '@salesforce/schema/Cyclone__c.Quantity__c';
import LOCATION_FIELD from '@salesforce/schema/Cyclone__c.Location__c';
import MODEL_NAME_FIELD from '@salesforce/schema/Cyclone__c.Model_Name__c';
import MODEL_SIZE_FIELD from '@salesforce/schema/Cyclone__c.Model_Size__c';
import CONE_ANGLE_FIELD from '@salesforce/schema/Cyclone__c.Cone_Angle__c';
import INLET_FIELD from '@salesforce/schema/Cyclone__c.Inlet__c';
import VORTEX_FINDER2_FIELD from '@salesforce/schema/Cyclone__c.Vortex_Finder2__c';
import SPIGOT_LINER_SIZE_FIELD from '@salesforce/schema/Cyclone__c.Spigot_Liner_Size2__c';

//import PLASSON_NUT_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Plasson_Nut__c';
//import PLASSON_NUT_TEXT_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Plasson_Nut_Text__c';
//import PLASSON_NUT_PRICE_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Plasson_Nut_Price__c';
//import FEED_MATCHING_PIECE_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Feed_Matching_Piece__c';
//import FEED_MATCHING_PIECE_TEXT_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Feed_Matching_Piece_Text__c';
//import FEED_MATCHING_PIECE_PRICE_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Feed_Matching_Piece_Price__c';
import FEED_FLANGE_FIELD from '@salesforce/schema/Cyclone__c.Feed_Flange__c';
import FEED_FLANGE_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Feed_Flange_Text__c';
import FEED_FLANGE_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Feed_Flange_Price__c';
import VORTEX_FINDER_FIELD from '@salesforce/schema/Cyclone__c.Vortex_Finder__c';
import VORTEX_FINDER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Vortex_Finder_Text__c';
import VORTEX_FINDER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Vortex_Finder_Price__c';
import COVER_FIELD from '@salesforce/schema/Cyclone__c.Cover__c';
import COVER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Cover_Text__c';
import COVER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Cover_Price__c';
import COVER_LINE_FIELD from '@salesforce/schema/Cyclone__c.Cover_Line__c';
import COVER_LINE_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Cover_Line_Text__c';
import COVER_LINE_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Cover_Line_Price__c';
import WEDGE_FIELD from '@salesforce/schema/Cyclone__c.Wedge__c';
import WEDGE_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Wedge_Text__c';
import WEDGE_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Wedge_Price__c';
import FEED_CHAMBER_FIELD from '@salesforce/schema/Cyclone__c.Feed_Chamber__c';
import FEED_CHAMBER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Feed_Chamber_Text__c';
import FEED_CHAMBER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Feed_Chamber_Price__c';
import FEED_CHAMBER_LINER_FIELD from '@salesforce/schema/Cyclone__c.Feed_Chamber_Liner__c';
import FEED_CHAMBER_LINER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Feed_Chamber_Liner_Text__c';
import FEED_CHAMBER_LINER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Feed_Chamber_Liner_Price__c';
import CONE_FIELD from '@salesforce/schema/Cyclone__c.Cone__c';
import CONE_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Cone_Text__c';
import CONE_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Cone_Price__c';
import CONER_LINER_FIELD from '@salesforce/schema/Cyclone__c.Coner_Liner__c';
import CONER_LINER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Coner_Liner_Text__c';
import CONER_LINER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Coner_Liner_Price__c';
import SPIGOT_HOLDER_FIELD from '@salesforce/schema/Cyclone__c.Spigot_Holder__c';
import SPIGOT_HOLDER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Spigot_Holder_Text__c';
import SPIGOT_HOLDER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Spigot_Holder_Price__c';
import SPIGOT_LINER_FIELD from '@salesforce/schema/Cyclone__c.Spigot_Liner__c';
import SPIGOT_LINER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Spigot_Liner_Text__c';
import SPIGOT_LINER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Spigot_Liner_Price__c';
import SPRAY_GUARD_HOLDER_FIELD from '@salesforce/schema/Cyclone__c.Spray_Guard_Holder__c';
import SPRAY_GUARD_HOLDER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Spray_Guard_Holder_Text__c';
import SPRAY_GUARD_HOLDER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Spray_Guard_Holder_Price__c';
import SPRAY_GUARD_LINER_FIELD from '@salesforce/schema/Cyclone__c.Spray_Guard_Liner__c';
import SPRAY_GUARD_LINER_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Spray_Guard_Liner_Text__c';
import SPRAY_GUARD_LINER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Spray_Guard_Liner_Price__c';
import QUICK_RELEASE_CLAMP_FIELD from '@salesforce/schema/Cyclone__c.Quick_Release_Clamp__c';
import QUICK_RELEASE_CLAMP_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Quick_Release_Clamp_Text__c';
import QUICK_RELEASE_CLAMP_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Quick_Release_Clamp_Price__c';
import FASTENERS_FIELD from '@salesforce/schema/Cyclone__c.Fasteners__c';
import FASTENERS_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Fasteners_Text__c';
import FASTENERS_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Fasteners_Price__c';
import FLANGE_CONNECTIONS_FIELD from '@salesforce/schema/Cyclone__c.Flange_Connections__c';

import DWKIT_FIELD from '@salesforce/schema/Cyclone__c.DWKit__c';
import DWKIT_PRICE_FIELD from '@salesforce/schema/Cyclone__c.DWKit_Price__c';
import OVERFLOW_BEND_FIELD from '@salesforce/schema/Cyclone__c.Overflow_Bend__c';
import OVERFLOW_BEND_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Overflow_Bend_Text__c';
import OVERFLOW_BEND_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Overflow_Bend_Price__c';
import MOUNTING_PLATE_FIELD from '@salesforce/schema/Cyclone__c.Mounting_Plate__c';
import MOUNTING_PLATE_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Mounting_Plate_Text__c';
import MOUNTING_PLATE_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Mounting_Plate_Price__c';
import LIP_SEAL_FIELD from '@salesforce/schema/Cyclone__c.Lip_Seal__c';
import LIP_SEAL_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Lip_Seal_Text__c';
import LIP_SEAL_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Lip_Seal_Price__c';
import PRESSURE_FLANGE_FIELD from '@salesforce/schema/Cyclone__c.Pressure_Flange__c';
import PRESSURE_FLANGE_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Pressure_Flange_Price__c';
import COMMISSIONING_KIT_FIELD from '@salesforce/schema/Cyclone__c.Commissioning_Kit__c';
import COMMISSIONING_KIT_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Commissioning_Kit_Price__c';
import OVERFLOW_ADAPTOR_FIELD from '@salesforce/schema/Cyclone__c.Overflow_Adaptor__c';
import OVERFLOW_ADAPTOR_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Overflow_Adaptor_Text__c';
import OVERFLOW_ADAPTOR_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Overflow_Adaptor_Price__c';
import SYNERTREX_FIELD from '@salesforce/schema/Cyclone__c.Synertrex__c';
import SYNERTREX_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Synertrex_Price__c';
import ACB_CORE_BOOSTER_FIELD from '@salesforce/schema/Cyclone__c.ACB_Core_Booster__c';
import ACB_CORE_BOOSTER_PRICE_FIELD from '@salesforce/schema/Cyclone__c.ACB_Core_Booster_Price__c';
import EXTENSION_FIELD from '@salesforce/schema/Cyclone__c.Extension__c';
import EXTENSION_TEXT_FIELD from '@salesforce/schema/Cyclone__c.Extension_Text__c';
import EXTENSION_PRICE_FIELD from '@salesforce/schema/Cyclone__c.Extension_Price__c';
//import EXTENSION_LINER_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Extension_Liner__c';
//import EXTENSION_LINER_TEXT_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Extension_Liner_Text__c';
//import EXTENSION_LINER_PRICE_FIELD from '@salesforce/schema/Product_Requirements_Form__c.Extension_Liner_Price__c';
import PAINTING_FIELD from '@salesforce/schema/Cyclone__c.Painting__c';

const MATERIAL_FIELDS_LEFT = [
    //PLASSON_NUT_FIELD,
    //FEED_MATCHING_PIECE_FIELD,
    FEED_FLANGE_FIELD,
    VORTEX_FINDER_FIELD,
    COVER_FIELD,
    COVER_LINE_FIELD,
    WEDGE_FIELD,
    FEED_CHAMBER_FIELD,
    FEED_CHAMBER_LINER_FIELD,
    CONE_FIELD
];
const MATERIAL_FIELDS_RIGHT = [    
    CONER_LINER_FIELD,
    SPIGOT_HOLDER_FIELD,
    SPIGOT_LINER_FIELD,
    SPRAY_GUARD_HOLDER_FIELD,
    SPRAY_GUARD_LINER_FIELD,
    QUICK_RELEASE_CLAMP_FIELD,
    FASTENERS_FIELD,
    FLANGE_CONNECTIONS_FIELD
];
const MATERIAL_FIELDS = [
    ...MATERIAL_FIELDS_LEFT,
    ...MATERIAL_FIELDS_RIGHT
];
const ANCILARIES_FIELDS_LEFT = [
    DWKIT_FIELD,
    OVERFLOW_BEND_FIELD,
    MOUNTING_PLATE_FIELD,
    LIP_SEAL_FIELD,
    PRESSURE_FLANGE_FIELD,
    PAINTING_FIELD    
];
const ANCILARIES_FIELDS_RIGHT = [
    COMMISSIONING_KIT_FIELD,
    OVERFLOW_ADAPTOR_FIELD,
    SYNERTREX_FIELD,
    ACB_CORE_BOOSTER_FIELD,
    EXTENSION_FIELD,
    //EXTENSION_LINER_FIELD
];
const ANCILARIES_FIELDS = [
    ...ANCILARIES_FIELDS_LEFT,
    ...ANCILARIES_FIELDS_RIGHT
];
const MASTER_FIELDS = [
    ...MATERIAL_FIELDS, ...ANCILARIES_FIELDS
];
const INPUT_FIELDS = [    
    ORIGINATOR_FIELD,
    DATE_FIELD,
    PROJECT_FIELD,
    QUOTE_NO_FIELD,
    ORDER_NO_FIELD,
    SERIAL_NUMBER_FIELD,
    REVISION_FIELD,
    TAG_NR_FIELD,
    CUSTOMER_FIELD,
    QUANTITY_FIELD,
    LOCATION_FIELD,
    MODEL_NAME_FIELD,
    MODEL_SIZE_FIELD,
    CONE_ANGLE_FIELD,
    INLET_FIELD,
    VORTEX_FINDER2_FIELD,
    SPIGOT_LINER_SIZE_FIELD,
    //PLASSON_NUT_TEXT_FIELD,
    //PLASSON_NUT_PRICE_FIELD,
    //FEED_MATCHING_PIECE_TEXT_FIELD,
    //FEED_MATCHING_PIECE_PRICE_FIELD,
    FEED_FLANGE_TEXT_FIELD,
    //FEED_FLANGE_PRICE_FIELD,
    VORTEX_FINDER_TEXT_FIELD,
    //VORTEX_FINDER_PRICE_FIELD,
    COVER_TEXT_FIELD,
    //COVER_PRICE_FIELD,
    COVER_LINE_TEXT_FIELD,
    //COVER_LINE_PRICE_FIELD,
    WEDGE_TEXT_FIELD,
    //WEDGE_PRICE_FIELD,
    FEED_CHAMBER_TEXT_FIELD,
    //FEED_CHAMBER_PRICE_FIELD,
    FEED_CHAMBER_LINER_TEXT_FIELD,
    //FEED_CHAMBER_LINER_PRICE_FIELD,
    CONE_TEXT_FIELD,
    //CONE_PRICE_FIELD,
    CONER_LINER_TEXT_FIELD,
    //CONER_LINER_PRICE_FIELD,
    SPIGOT_HOLDER_TEXT_FIELD,
    //SPIGOT_HOLDER_PRICE_FIELD,
    SPIGOT_LINER_TEXT_FIELD,
    //SPIGOT_LINER_PRICE_FIELD,
    SPRAY_GUARD_HOLDER_TEXT_FIELD,
    //SPRAY_GUARD_HOLDER_PRICE_FIELD,
    SPRAY_GUARD_LINER_TEXT_FIELD,
    //SPRAY_GUARD_LINER_PRICE_FIELD,
    QUICK_RELEASE_CLAMP_TEXT_FIELD,
    //QUICK_RELEASE_CLAMP_PRICE_FIELD,
    FASTENERS_TEXT_FIELD,
    //FASTENERS_PRICE_FIELD,
    //DWKIT_PRICE_FIELD,
    OVERFLOW_BEND_TEXT_FIELD,
    //OVERFLOW_BEND_PRICE_FIELD,
    MOUNTING_PLATE_TEXT_FIELD,
    //MOUNTING_PLATE_PRICE_FIELD,
    LIP_SEAL_TEXT_FIELD,
    //LIP_SEAL_PRICE_FIELD,
    //PRESSURE_FLANGE_PRICE_FIELD,
    //COMMISSIONING_KIT_PRICE_FIELD,
    OVERFLOW_ADAPTOR_TEXT_FIELD,
    //OVERFLOW_ADAPTOR_PRICE_FIELD,
    //SYNERTREX_PRICE_FIELD,
    //ACB_CORE_BOOSTER_PRICE_FIELD,
    EXTENSION_TEXT_FIELD,
    //EXTENSION_PRICE_FIELD,
    //EXTENSION_LINER_TEXT_FIELD,
    //EXTENSION_LINER_PRICE_FIELD,
    ...MASTER_FIELDS
];

const QUERY_FIELDS = [ID_FIELD, NAME_FIELD, QUOTE_LINE_ITEM_FIELD, ...INPUT_FIELDS];
//PLASSON_NUT_FIELD.otherApiName = PLASSON_NUT_TEXT_FIELD.fieldApiName;
//PLASSON_NUT_FIELD.priceApiName = PLASSON_NUT_PRICE_FIELD.fieldApiName;
//FEED_MATCHING_PIECE_FIELD.otherApiName = FEED_MATCHING_PIECE_TEXT_FIELD.fieldApiName;
//FEED_MATCHING_PIECE_FIELD.priceApiName = FEED_MATCHING_PIECE_PRICE_FIELD.fieldApiName;
FEED_FLANGE_FIELD.otherApiName = FEED_FLANGE_TEXT_FIELD.fieldApiName;
//FEED_FLANGE_FIELD.priceApiName = FEED_FLANGE_PRICE_FIELD.fieldApiName;
VORTEX_FINDER_FIELD.otherApiName = VORTEX_FINDER_TEXT_FIELD.fieldApiName;
//VORTEX_FINDER_FIELD.priceApiName = VORTEX_FINDER_PRICE_FIELD.fieldApiName;
COVER_FIELD.otherApiName = COVER_TEXT_FIELD.fieldApiName;
//COVER_FIELD.priceApiName = COVER_PRICE_FIELD.fieldApiName;
COVER_LINE_FIELD.otherApiName = COVER_LINE_TEXT_FIELD.fieldApiName;
//COVER_LINE_FIELD.priceApiName = COVER_LINE_PRICE_FIELD.fieldApiName;
WEDGE_FIELD.otherApiName = WEDGE_TEXT_FIELD.fieldApiName;
//WEDGE_FIELD.priceApiName = WEDGE_PRICE_FIELD.fieldApiName;
FEED_CHAMBER_FIELD.otherApiName = FEED_CHAMBER_TEXT_FIELD.fieldApiName;
//FEED_CHAMBER_FIELD.priceApiName = FEED_CHAMBER_PRICE_FIELD.fieldApiName;
FEED_CHAMBER_LINER_FIELD.otherApiName = FEED_CHAMBER_LINER_TEXT_FIELD.fieldApiName;
//FEED_CHAMBER_LINER_FIELD.priceApiName = FEED_CHAMBER_LINER_PRICE_FIELD.fieldApiName;
CONE_FIELD.otherApiName = CONE_TEXT_FIELD.fieldApiName;
//CONE_FIELD.priceApiName = CONE_PRICE_FIELD.fieldApiName;
CONER_LINER_FIELD.otherApiName = CONER_LINER_TEXT_FIELD.fieldApiName;
//CONER_LINER_FIELD.priceApiName = CONER_LINER_PRICE_FIELD.fieldApiName;
SPIGOT_HOLDER_FIELD.otherApiName = SPIGOT_HOLDER_TEXT_FIELD.fieldApiName;
//SPIGOT_HOLDER_FIELD.priceApiName = SPIGOT_HOLDER_PRICE_FIELD.fieldApiName;
SPIGOT_LINER_FIELD.otherApiName = SPIGOT_LINER_TEXT_FIELD.fieldApiName;
//SPIGOT_LINER_FIELD.priceApiName = SPIGOT_LINER_PRICE_FIELD.fieldApiName;
SPRAY_GUARD_HOLDER_FIELD.otherApiName = SPRAY_GUARD_HOLDER_TEXT_FIELD.fieldApiName;
//SPRAY_GUARD_HOLDER_FIELD.priceApiName = SPRAY_GUARD_HOLDER_PRICE_FIELD.fieldApiName;
SPRAY_GUARD_LINER_FIELD.otherApiName = SPRAY_GUARD_LINER_TEXT_FIELD.fieldApiName;
//SPRAY_GUARD_LINER_FIELD.priceApiName = SPRAY_GUARD_LINER_PRICE_FIELD.fieldApiName;
QUICK_RELEASE_CLAMP_FIELD.otherApiName = QUICK_RELEASE_CLAMP_TEXT_FIELD.fieldApiName;
//QUICK_RELEASE_CLAMP_FIELD.priceApiName = QUICK_RELEASE_CLAMP_PRICE_FIELD.fieldApiName;
FASTENERS_FIELD.otherApiName = FASTENERS_TEXT_FIELD.fieldApiName;
//FASTENERS_FIELD.priceApiName = FASTENERS_PRICE_FIELD.fieldApiName;
//DWKIT_FIELD.priceApiName = DWKIT_PRICE_FIELD.fieldApiName;
OVERFLOW_BEND_FIELD.otherApiName = OVERFLOW_BEND_TEXT_FIELD.fieldApiName;
//OVERFLOW_BEND_FIELD.priceApiName = OVERFLOW_BEND_PRICE_FIELD.fieldApiName;
MOUNTING_PLATE_FIELD.otherApiName = MOUNTING_PLATE_TEXT_FIELD.fieldApiName;
//MOUNTING_PLATE_FIELD.priceApiName = MOUNTING_PLATE_PRICE_FIELD.fieldApiName;
LIP_SEAL_FIELD.otherApiName = LIP_SEAL_TEXT_FIELD.fieldApiName;
//LIP_SEAL_FIELD.priceApiName = LIP_SEAL_PRICE_FIELD.fieldApiName;
//PRESSURE_FLANGE_FIELD.priceApiName = PRESSURE_FLANGE_PRICE_FIELD.fieldApiName;
//COMMISSIONING_KIT_FIELD.priceApiName = COMMISSIONING_KIT_PRICE_FIELD.fieldApiName;
OVERFLOW_ADAPTOR_FIELD.otherApiName = OVERFLOW_ADAPTOR_TEXT_FIELD.fieldApiName;
//OVERFLOW_ADAPTOR_FIELD.priceApiName = OVERFLOW_ADAPTOR_PRICE_FIELD.fieldApiName;
//SYNERTREX_FIELD.priceApiName = SYNERTREX_PRICE_FIELD.fieldApiName;
//ACB_CORE_BOOSTER_FIELD.priceApiName = ACB_CORE_BOOSTER_PRICE_FIELD.fieldApiName;
EXTENSION_FIELD.otherApiName = EXTENSION_TEXT_FIELD.fieldApiName;
//EXTENSION_FIELD.priceApiName = EXTENSION_PRICE_FIELD.fieldApiName;
//EXTENSION_LINER_FIELD.otherApiName = EXTENSION_LINER_TEXT_FIELD.fieldApiName;
//EXTENSION_LINER_FIELD.priceApiName = EXTENSION_LINER_PRICE_FIELD.fieldApiName;

export default class QuoteProductRequirementsForm extends NavigationMixin(LightningElement) {
    _recordId;
    _parentId;
    form;
    close;
    master;
    objectInfo;
    showSpinner = true;
    prices;
    isLoading = false;
    _totalAmount = 0;

    @api
    set recordId(val) {        
        console.log('recordId: ' + val);
        this._recordId = val;
        if (!val) { //Reset form if no record id
            INPUT_FIELDS.forEach(item => {
                try {
                    if (this.template.querySelector("[data-field='" + item.fieldApiName + "']")) {
                        this.template.querySelector("[data-field='" + item.fieldApiName + "']").value = null;
                        this.template.querySelector("[data-field='" + item.fieldApiName + "']").disabled = false;
                    }
                    if (this.template.querySelector("[data-amount='" + item.fieldApiName + "']")) {
                        this.template.querySelector("[data-amount='" + item.fieldApiName + "']").value = null;
                        this.template.querySelector("[data-amount='" + item.fieldApiName + "']").disabled = false;
                    }
                    if (this.template.querySelector("[data-default='" + item.fieldApiName + "']")) {
                        this.template.querySelector("[data-default='" + item.fieldApiName + "']").className = 'slds-show';
                    }
                    if (this.template.querySelector("[data-changed='" + item.fieldApiName + "']")) {
                        this.template.querySelector("[data-changed='" + item.fieldApiName + "']").className = 'slds-hide'; 
                    }
                    if (this.template.querySelector("[data-parent='" + item.fieldApiName + "']")) {
                        this.template.querySelector("[data-parent='" + item.fieldApiName + "']").className = 'slds-hide';                        
                    }
                }
                catch (e) {
                    console.log(e);
                }

            });
        }
        else {
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
    }

    get parentId() {
        return this._parentId;
    }

    get materialFields() {
        let items = [];
        for (let i = 0; i < MATERIAL_FIELDS_LEFT.length; i++) {
            if (MATERIAL_FIELDS_RIGHT[i]) {
                let row = { index: i, items: [MATERIAL_FIELDS_LEFT[i], MATERIAL_FIELDS_RIGHT[i]] };
                items.push(row);
            }
            else {
                let row = { index: i, items: [MATERIAL_FIELDS_LEFT[i]] };
                items.push(row);
            }
        }
        return items;
    }

    get ancilariesFields() {
        let items = [];
        for (let i = 0; i < ANCILARIES_FIELDS_LEFT.length; i++) {
            if (ANCILARIES_FIELDS_RIGHT[i]) {
                let row = { index: i, items: [ANCILARIES_FIELDS_LEFT[i], ANCILARIES_FIELDS_RIGHT[i]] };
                items.push(row);
            }
            else {
                let row = { index: i, items: [ANCILARIES_FIELDS_LEFT[i]] };
                items.push(row);
            }
        }
        return items;
    }

    get model() {
        let modelName = '';
        let modelSize = '';
        let coneAngle = '';
        this.isLoading; //Just to trigger on load
        if (this.template.querySelector("[data-field='Model_Name__c']") && this.template.querySelector("[data-field='Model_Name__c']").value)
            modelName = this.template.querySelector("[data-field='Model_Name__c']").value;
        if (this.template.querySelector("[data-field='Model_Size__c']") && this.template.querySelector("[data-field='Model_Size__c']").value)
            modelSize = this.template.querySelector("[data-field='Model_Size__c']").value;
        if (this.template.querySelector("[data-field='Cone_Angle__c']") && this.template.querySelector("[data-field='Cone_Angle__c']").value)
            coneAngle = this.template.querySelector("[data-field='Cone_Angle__c']").value;        
        return modelSize + modelName + coneAngle;
    }

    connectedCallback() {
        console.log('connectedCallback');
    }

    renderedCallback() {
        console.log('renderedCallback');
    }

    @wire(getObjectInfo, { objectApiName: PRODUCT_REQUIREMENTS_FORM_OBJECT })
    getFormInfo({ data, error }) {
        if (data) {
            console.log('getObjectInfo');
            console.log(data);
            this.objectInfo = data;
            INPUT_FIELDS.forEach(item => {
                try {
                    if (this.template.querySelector("[data-field='" + item.fieldApiName + "']")) {
                        this.template.querySelector("[data-field='" + item.fieldApiName + "']").label = data.fields[item.fieldApiName].label;
                    }
                }
                catch (e) {
                    console.log(e);
                }

            });
            this.showSpinner = false;
        }
    }

    @wire(getRecord, { recordId: '$_recordId', fields: QUERY_FIELDS })
    wiredRecord({ error, data }) {
        console.log('getRecord');
        if (error) {
            let message = 'Unknown error';
            if (Array.isArray(error.body)) {
                message = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                message = error.body.message;
            }
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error loading',
                    message,
                    variant: 'error',
                }),
            );
        }
        else if (data) {
            console.log(data);
            this.form = data;
            INPUT_FIELDS.forEach(item => {
                console.log(item.fieldApiName);
                this.template.querySelector("[data-field='" + item.fieldApiName + "']").value = data.fields[item.fieldApiName].value;
                if (this.template.querySelector("[data-parent='" + item.fieldApiName + "']")) {
                    if (data.fields[item.fieldApiName].value === 'Other') {
                        this.template.querySelector("[data-parent='" + item.fieldApiName + "']").className = 'slds-show';
                    }
                    else {
                        this.template.querySelector("[data-parent='" + item.fieldApiName + "']").className = 'slds-hide';
                    }
                }
            });
            this._parentId = data.fields[QUOTE_LINE_ITEM_FIELD.fieldApiName].value;
            this._totalAmount = 1;

            //Set labels again because it is gone
            if (this.objectInfo) {
                INPUT_FIELDS.forEach(item => {
                    try {
                        if (this.template.querySelector("[data-field='" + item.fieldApiName + "']")) {
                            this.template.querySelector("[data-field='" + item.fieldApiName + "']").label = this.objectInfo.fields[item.fieldApiName].label;
                        }
                    }
                    catch (e) {
                        console.log(e);
                    }
    
                }); 
            }           

            //Compare with master
            let location = data.fields[LOCATION_FIELD.fieldApiName].value;
            let modelName = data.fields[MODEL_NAME_FIELD.fieldApiName].value;
            let modelSize = data.fields[MODEL_SIZE_FIELD.fieldApiName].value;
            getMasterData({ location, modelName, modelSize })
                .then(result => {
                    console.log(result);
                    this.master = result;
                    MASTER_FIELDS.forEach(item => {
                        console.log(item.fieldApiName);
                        try {
                            if (result[item.fieldApiName] === 'N/A') {
                                console.log(result[item.fieldApiName]);
                                this.template.querySelector("[data-field='" + item.fieldApiName + "']").disabled = true;
                                //this.template.querySelector("[data-amount='" + item.fieldApiName + "']").disabled = true;
                                this.template.querySelector("[data-default='" + item.fieldApiName + "']").className = 'slds-show';
                                this.template.querySelector("[data-changed='" + item.fieldApiName + "']").className = 'slds-hide';
                            }
                            else {
                                if (data.fields[item.fieldApiName].value == result[item.fieldApiName]) {
                                    this.template.querySelector("[data-default='" + item.fieldApiName + "']").className = 'slds-show';
                                    this.template.querySelector("[data-changed='" + item.fieldApiName + "']").className = 'slds-hide';
                                }
                                else {
                                    this.template.querySelector("[data-default='" + item.fieldApiName + "']").className = 'slds-hide';
                                    this.template.querySelector("[data-changed='" + item.fieldApiName + "']").className = 'slds-show';
                                }
                            }
                        }
                        catch (e) {
                            console.log(e);
                        }
                    });
                    //this.getPrice(true);
                    this.isLoading = false;
                })
                .catch(error => {
                    console.log(error);
                    this.isLoading = false;
                });
        }
        this.showSpinner = false;
    }

    getPrice(fieldApiName) {
        if (!this.prices) {
            getPriceData().then(result => {
                console.log(result);
                this.prices = result;
                let priceMap = new Map(result.map(i => [i.Name, i.Amount__c]));
                if (fieldApiName) {
                    let fieldValue = this.template.querySelector("[data-field='" + fieldApiName + "']").value;
                    this.template.querySelector("[data-amount='" + fieldApiName + "']").value = null;
                    if (priceMap.has(fieldValue)) {
                        this.template.querySelector("[data-amount='" + fieldApiName + "']").value = priceMap.get(fieldValue);
                    }                    
                }
                else {
                    MASTER_FIELDS.forEach(item => {
                        let fieldValue = this.template.querySelector("[data-field='" + item.fieldApiName + "']").value;
                        this.template.querySelector("[data-amount='" + item.fieldApiName + "']").value = null;
                        if (priceMap.has(fieldValue)) {
                            this.template.querySelector("[data-amount='" + item.fieldApiName + "']").value = priceMap.get(fieldValue);
                        }
                    });
                }
            })
                .catch(error => {
                    console.log(error);
                });
        }
        else {
            let result = this.prices;
            let priceMap = new Map(result.map(i => [i.Name, i.Amount__c]));
            if (fieldApiName) {
                let fieldValue = this.template.querySelector("[data-field='" + fieldApiName + "']").value;
                this.template.querySelector("[data-amount='" + fieldApiName + "']").value = null;
                if (priceMap.has(fieldValue)) {
                    this.template.querySelector("[data-amount='" + fieldApiName + "']").value = priceMap.get(fieldValue);
                }                
            }
            else {
                MASTER_FIELDS.forEach(item => {
                    let fieldValue = this.template.querySelector("[data-field='" + item.fieldApiName + "']").value;
                    this.template.querySelector("[data-amount='" + item.fieldApiName + "']").value = null;
                    if (priceMap.has(fieldValue)) {
                        this.template.querySelector("[data-amount='" + item.fieldApiName + "']").value = priceMap.get(fieldValue);
                    }
                });
            }
        }
    }

    get totalAmount() {
        console.log('get totalAmount');
        let amount = 0;
        this._totalAmount;
        MASTER_FIELDS.forEach(item => {
            if (this.template.querySelector("[data-amount='" + item.fieldApiName + "']")) {
                let val = this.template.querySelector("[data-amount='" + item.fieldApiName + "']").value;
                val = parseFloat(val);
                if (!isNaN(val)) {
                    amount += val;
                }
            }
        });
        return amount;
    }

    handleChange(event) {
        console.log('handleChange');
        console.log('loading: ' + this.isLoading);
        if (this.isLoading) {
            return;
        }
        let field = event.target.dataset.field;
        let value = event.target.value;
        console.log(field + " > " + value);
        if (field == LOCATION_FIELD.fieldApiName || field == MODEL_NAME_FIELD.fieldApiName || field == MODEL_SIZE_FIELD.fieldApiName || field == CONE_ANGLE_FIELD.fieldApiName
            || field == INLET_FIELD.fieldApiName || field == VORTEX_FINDER2_FIELD.fieldApiName || field == SPIGOT_LINER_SIZE_FIELD.fieldApiName) {
            let location = this.template.querySelector("[data-field='" + LOCATION_FIELD.fieldApiName + "']").value;
            let modelName = this.template.querySelector("[data-field='" + MODEL_NAME_FIELD.fieldApiName + "']").value;
            let modelSize = this.template.querySelector("[data-field='" + MODEL_SIZE_FIELD.fieldApiName + "']").value;
            this.showSpinner = true;
            getMasterData({ location, modelName, modelSize })
                .then(result => {
                    this.master = result;
                    console.log('handleChange: getMasterData');
                    console.log(result);
                    MASTER_FIELDS.forEach(item => {
                        try {                            
                            console.log(result[item.fieldApiName]);
                            if (result[item.fieldApiName] === 'N/A') {                                
                                this.template.querySelector("[data-field='" + item.fieldApiName + "']").value = null;
                                this.template.querySelector("[data-field='" + item.fieldApiName + "']").disabled = true;
                                //this.template.querySelector("[data-amount='" + item.fieldApiName + "']").disabled = true;
                                this.template.querySelector("[data-default='" + item.fieldApiName + "']").className = 'slds-show';
                                this.template.querySelector("[data-changed='" + item.fieldApiName + "']").className = 'slds-hide';
                                this.template.querySelector("[data-parent='" + item.fieldApiName + "']").className = 'slds-hide';
                            }
                            else {
                                this.template.querySelector("[data-field='" + item.fieldApiName + "']").disabled = false;
                                //this.template.querySelector("[data-amount='" + item.fieldApiName + "']").disabled = false;
                                this.template.querySelector("[data-default='" + item.fieldApiName + "']").className = 'slds-show';
                                this.template.querySelector("[data-changed='" + item.fieldApiName + "']").className = 'slds-hide';

                                if (result[item.fieldApiName]) {
                                    this.template.querySelector("[data-field='" + item.fieldApiName + "']").value = result[item.fieldApiName];
                                }
                                else {
                                    this.template.querySelector("[data-field='" + item.fieldApiName + "']").value = null;
                                }
                                if (this.template.querySelector("[data-parent='" + item.fieldApiName + "']")) {
                                    if (result[item.fieldApiName] === 'Other') {
                                        this.template.querySelector("[data-parent='" + item.fieldApiName + "']").className = 'slds-show';
                                    }
                                    else {
                                        this.template.querySelector("[data-parent='" + item.fieldApiName + "']").className = 'slds-hide';
                                    }
                                }
                                if (this.template.querySelector("[data-amount='" + item.fieldApiName + "']")) {
                                    console.log(item.fieldApiName);
                                    this.template.querySelector("[data-amount='" + item.fieldApiName + "']").value = null;
                                }
                            }

                        }
                        catch (e) {
                            console.log(e);
                        }
                        //this.getPrice(null);
                    });
                    this.showSpinner = false;
                })
                .catch(error => {
                    console.log(error);
                    MASTER_FIELDS.forEach(item => {
                        try {
                            this.template.querySelector("[data-default='" + item.fieldApiName + "']").className = 'slds-hide';
                            this.template.querySelector("[data-changed='" + item.fieldApiName + "']").className = 'slds-show';
                            this.template.querySelector("[data-field='" + item.fieldApiName + "']").value = null;
                            if (this.template.querySelector("[data-parent='" + item.fieldApiName + "']")) {
                                this.template.querySelector("[data-parent='" + item.fieldApiName + "']").className = 'slds-hide';
                            }
                        }
                        catch (e) {
                            console.log(e);
                        }

                    });
                    this.showSpinner = false;
                });
        }
        else if (this.master) {
            if (this.master[field] == value || (!this.master[field] && !value)) {
                this.template.querySelector("[data-default='" + field + "']").className = 'slds-show';
                this.template.querySelector("[data-changed='" + field + "']").className = 'slds-hide';
            }
            else {
                this.template.querySelector("[data-default='" + field + "']").className = 'slds-hide';
                this.template.querySelector("[data-changed='" + field + "']").className = 'slds-show';
            }
            //this.getPrice(field);
            this._totalAmount = value;
        }
        if (this.template.querySelector("[data-parent='" + field + "']")) {
            if (value === 'Other') {
                this.template.querySelector("[data-parent='" + field + "']").className = 'slds-show';
            }
            else {
                this.template.querySelector("[data-parent='" + field + "']").className = 'slds-hide';
            }
        }
    }

    handleAmountChange(event) {
        console.log('handleAmountChange');
        let value = event.target.value;
        this._totalAmount = value;        
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

    saveAndCloseForm() {
        this.close = true;
        this.saveForm();
    }

    saveForm() {
        this.showSpinner = true;
        const fields = {};

        INPUT_FIELDS.forEach(item => {
            if (this.template.querySelector("[data-field='" + item.fieldApiName + "']").value !== 'N/A') {
                fields[item.fieldApiName] = this.template.querySelector("[data-field='" + item.fieldApiName + "']").value;
            }
        });

        const recordInput = { fields };

        if (this._recordId) {
            fields[ID_FIELD.fieldApiName] = this._recordId;

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
                            message: error.body.message,
                            variant: 'error'
                        })
                    );
                    this.close = false;
                    this.showSpinner = false;
                });
        }
        else {
            fields[QUOTE_LINE_ITEM_FIELD.fieldApiName] = this._parentId;
            recordInput.apiName = PRODUCT_REQUIREMENTS_FORM_OBJECT.objectApiName;
            createRecord(recordInput)
                .then(account => {
                    this.accountId = account.id;
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
                })
                .catch(error => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: error.body.message,
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
    }    


}