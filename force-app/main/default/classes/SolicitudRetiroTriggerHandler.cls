public class SolicitudRetiroTriggerHandler {

    public static void validarSolicitudesAbiertas(
        List<Solicitud_Retiro__c> nuevasSolicitudes,
        Map<Id, Solicitud_Retiro__c> solicitudesAnteriores
    ) {

        Set<Id> afiliadoIds = new Set<Id>();
        Set<String> motivos = new Set<String>();
        Set<Id> solicitudIds = new Set<Id>();

        // Estados considerados como solicitud abierta
        Set<String> estadosAbiertos = new Set<String>{
            'Radicada',
            'En validación'
        };

        // 1. Recopilar información de las solicitudes
        for (Solicitud_Retiro__c solicitud : nuevasSolicitudes) {

            if (solicitud.Id != null) {
                solicitudIds.add(solicitud.Id);
            }

            if (solicitud.Afiliado__c == null) {
                continue;
            }

            if (String.isBlank(solicitud.Motivo__c)) {
                continue;
            }

            if (!estadosAbiertos.contains(solicitud.Estado__c)) {
                continue;
            }

            afiliadoIds.add(solicitud.Afiliado__c);
            motivos.add(solicitud.Motivo__c);
        }

        if (afiliadoIds.isEmpty() || motivos.isEmpty()) {
            return;
        }

        // 2. Buscar solicitudes abiertas existentes
        List<Solicitud_Retiro__c> solicitudesExistentes = [
            SELECT Id,
                   Afiliado__c,
                   Motivo__c,
                   Estado__c
            FROM Solicitud_Retiro__c
            WHERE Afiliado__c IN :afiliadoIds
            AND Motivo__c IN :motivos
            AND Estado__c IN :estadosAbiertos
            AND Id NOT IN :solicitudIds
        ];

        // 3. Crear combinaciones existentes: Afiliado + Motivo
        Set<String> combinacionesExistentes = new Set<String>();

        for (Solicitud_Retiro__c solicitud : solicitudesExistentes) {

            String clave =
                String.valueOf(solicitud.Afiliado__c)
                + '|'
                + solicitud.Motivo__c;

            combinacionesExistentes.add(clave);
        }

        // 4. Validar las solicitudes de la transacción
        Set<String> combinacionesNuevas = new Set<String>();

        for (Solicitud_Retiro__c solicitud : nuevasSolicitudes) {

            if (solicitud.Afiliado__c == null ||
                String.isBlank(solicitud.Motivo__c) ||
                !estadosAbiertos.contains(solicitud.Estado__c)) {
                continue;
            }

            String clave =
                String.valueOf(solicitud.Afiliado__c)
                + '|'
                + solicitud.Motivo__c;

            // Ya existe una solicitud abierta
            if (combinacionesExistentes.contains(clave)) {

                solicitud.addError(
                    'El afiliado ya tiene una solicitud abierta para este motivo.'
                );

                continue;
            }

            // Duplicado dentro de la misma carga
            if (combinacionesNuevas.contains(clave)) {

                solicitud.addError(
                    'El afiliado tiene otra solicitud abierta para este mismo motivo dentro de esta carga.'
                );

                continue;
            }

            combinacionesNuevas.add(clave);
        }
    }
}