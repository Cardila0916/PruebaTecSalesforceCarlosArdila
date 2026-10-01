trigger SolicitudRetiroTrigger on Solicitud_Retiro__c (before insert, before update) {
    SolicitudRetiroTriggerHandler.validarSolicitudesAbiertas(
        Trigger.new,
        Trigger.oldMap
    );
}