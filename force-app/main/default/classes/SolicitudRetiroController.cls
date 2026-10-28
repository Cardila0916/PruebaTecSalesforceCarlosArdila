
public with sharing class SolicitudRetiroController {

    public class SolicitudResponse {
        @AuraEnabled public Id solicitudId;
        @AuraEnabled public String mensaje;

        public SolicitudResponse(Id solicitudId, String mensaje) {
            this.solicitudId = solicitudId;
            this.mensaje = mensaje;
        }
    }

    @AuraEnabled
    public static SolicitudResponse radicarSolicitud(
        Id afiliadoId,
        String motivo,
        Decimal montoSolicitado
    ) {
        // 1. Validaciones del servidor
        if (afiliadoId == null) {
            throw new AuraHandledException(
                'Debes seleccionar un afiliado.'
            );
        }

        if (String.isBlank(motivo)) {
            throw new AuraHandledException(
                'Debes seleccionar un motivo.'
            );
        }

        if (montoSolicitado == null || montoSolicitado <= 0) {
            throw new AuraHandledException(
                'El monto debe ser mayor que cero.'
            );
        }

        // 2. Validar que el motivo esté activo en la picklist
        Boolean motivoValido = false;

        for (Schema.PicklistEntry opcion :
            Solicitud_Retiro__c.Motivo__c
                .getDescribe()
                .getPicklistValues()
        ) {
            if (opcion.isActive() && opcion.getValue() == motivo) {
                motivoValido = true;
                break;
            }
        }

        if (!motivoValido) {
            throw new AuraHandledException(
                'El motivo seleccionado no es válido.'
            );
        }

        try {
            // 3. Verificar que el afiliado exista
            List<Contact> afiliados = [
                SELECT Id
                FROM Contact
                WHERE Id = :afiliadoId
                WITH USER_MODE
                LIMIT 1
            ];

            if (afiliados.isEmpty()) {
                throw new AuraHandledException(
                    'El afiliado no existe o no tienes acceso.'
                );
            }

            // 4. Construir la solicitud en el servidor
            Solicitud_Retiro__c solicitud =
                new Solicitud_Retiro__c(
                    Afiliado__c = afiliados[0].Id,
                    Motivo__c = motivo,
                    Monto_Solicitado__c = montoSolicitado,
                    Estado__c = 'Radicada',
                    Fecha_Radicacion__c = Date.today()
                );

            // CRUD y FLS del usuario actual
            Database.insert(
                solicitud,
                true,
                AccessLevel.USER_MODE
            );

            return new SolicitudResponse(
                solicitud.Id,
                'Solicitud radicada correctamente.'
            );

        } catch (AuraHandledException e) {
            throw e;

        } catch (DmlException e) {
            // Incluye errores de validaciones y del trigger existente
            throw new AuraHandledException(
                'No fue posible radicar la solicitud: ' +
                e.getDmlMessage(0)
            );

        } catch (QueryException e) {
            throw new AuraHandledException(
                'No fue posible consultar el afiliado. ' +
                'Verifica tus permisos.'
            );

        } catch (Exception e) {
            throw new AuraHandledException(
                'Ocurrió un error al procesar la solicitud. ' +
                'Contacta al administrador.'
            );
        }
    }
}