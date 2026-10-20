public with sharing class SolicitudesAbiertasController {

    @AuraEnabled(cacheable=true)
    public static List<Solicitud_Retiro__c> obtenerSolicitudesAbiertas(
        Id contactId
    ) {
        if (contactId == null) {
            return new List<Solicitud_Retiro__c>();
        }

        List<Solicitud_Retiro__c> solicitudes = [
            SELECT Id,
                   Name,
                   Afiliado__c,
                   Motivo__c,
                   Monto_Solicitado__c,
                   Estado__c,
                   Fecha_Radicacion__c
            FROM Solicitud_Retiro__c
            WHERE Afiliado__c = :contactId
            AND Estado__c IN ('Radicada', 'En validación')
            WITH USER_MODE
            ORDER BY Fecha_Radicacion__c DESC
        ];

        return solicitudes;
    }
}
