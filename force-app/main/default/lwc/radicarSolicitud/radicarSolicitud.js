import { LightningElement } from 'lwc';
import radicarSolicitud from '@salesforce/apex/SolicitudRetiroController.radicarSolicitud';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RadicarSolicitud extends LightningElement {
    afiliadoId;
    motivos = [
        { label: 'Vivienda', value: 'Vivienda' },
        { label: 'Educación', value: 'Educación' },
        {
            label: 'Terminación de contrato',
            value: 'Terminación de contrato'
        }
    ];
    montoSolicitado;
    enviando = false;

    get deshabilitarBoton() {
        return this.enviando;
    }

    handleAfiliadoChange(event) {
        this.afiliadoId = event.detail.recordId;
    }

    handleMotivoChange(event) {
        this.motivo = event.detail.value;
    }

    handleMontoChange(event) {
        this.montoSolicitado = event.detail.value;
    }

    async handleRadicar() {
        if (this.enviando) {
            return;
        }

        const campos = [
            ...this.template.querySelectorAll(
                'lightning-input, lightning-combobox'
            )
        ];

        const formularioValido = campos.reduce(
            (valido, campo) => {
                campo.reportValidity();
                return campo.checkValidity() && valido;
            },
            true
        );

        if (!formularioValido || !this.afiliadoId) {
            this.mostrarMensaje(
                'Revisa el formulario',
                'Completa todos los campos obligatorios.',
                'error'
            );
            return;
        }

        if (Number(this.montoSolicitado) <= 0) {
            this.mostrarMensaje(
                'Monto inválido',
                'El monto debe ser mayor que cero.',
                'error'
            );
            return;
        }

        this.enviando = true;

        try {
            const resultado = await radicarSolicitud({
                afiliadoId: this.afiliadoId,
                motivo: this.motivo,
                montoSolicitado: Number(this.montoSolicitado)
            });

            this.mostrarMensaje(
                'Solicitud radicada',
                resultado.mensaje,
                'success'
            );

            this.dispatchEvent(
                new CustomEvent('radicada', {
                    detail: {
                        solicitudId: resultado.solicitudId
                    }
                })
            );

            this.afiliadoId = null;
            this.motivo = '';
            this.montoSolicitado = null;
            this.template.querySelector(
                'lightning-record-picker'
            ).clearSelection();
            campos.forEach(campo => {
                campo.value = null;
            });
        } catch (error) {
            this.mostrarMensaje(
                'Error al radicar',
                error?.body?.message ||
                    'Ocurrió un error al guardar la solicitud.',
                'error'
            );
        } finally {
            this.enviando = false;
        }
    }

    mostrarMensaje(titulo, mensaje, variante) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: titulo,
                message: mensaje,
                variant: variante
            })
        );
    }
}