
import { LightningElement, api, wire } from 'lwc';
import obtenerSolicitudesAbiertas from '@salesforce/apex/SolicitudesAbiertasController.obtenerSolicitudesAbiertas';

const COLUMNS = [
    {
        label: 'Solicitud',
        fieldName: 'Name'
    },
    {
        label: 'Motivo',
        fieldName: 'Motivo__c'
    },
    {
        label: 'Monto solicitado',
        fieldName: 'Monto_Solicitado__c',
        type: 'currency',
        typeAttributes: {
            currencyCode: 'COP',
            maximumFractionDigits: 2
        }
    },
    {
        label: 'Estado',
        fieldName: 'Estado__c'
    },
    {
        label: 'Fecha de radicación',
        fieldName: 'Fecha_Radicacion__c',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }
    }
];

export default class SolicitudesAbierta extends LightningElement {
    @api recordId;

    columns = COLUMNS;

    @wire(obtenerSolicitudesAbiertas, { contactId: '$recordId' })
    resultado;

    get solicitudes() {
        return this.resultado.data || [];
    }

    get haySolicitudes() {
        return this.solicitudes.length > 0;
    }

    get tieneError() {
        return !!this.resultado.error;
    }

    get cargando() {
        return !this.resultado.data && !this.resultado.error;
    }
}
