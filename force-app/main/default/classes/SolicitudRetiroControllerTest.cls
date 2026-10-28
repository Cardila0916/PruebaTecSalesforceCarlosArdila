
@IsTest
private class SolicitudRetiroControllerTest {

    @TestSetup
    static void crearDatos() {
        Contact afiliado = new Contact(
            LastName = 'Afiliado Prueba'
        );
        insert afiliado;
    }

    private static Id obtenerAfiliadoId() {
        return [
            SELECT Id
            FROM Contact
            WHERE LastName = 'Afiliado Prueba'
            LIMIT 1
        ].Id;
    }

    @IsTest
    static void radicarSolicitudExitosa() {
        Id afiliadoId = obtenerAfiliadoId();

        Test.startTest();
        SolicitudRetiroController.SolicitudResponse respuesta =
            SolicitudRetiroController.radicarSolicitud(
                afiliadoId,
                'Vivienda',
                500000
            );
        Test.stopTest();

        System.assertNotEquals(
            null,
            respuesta.solicitudId,
            'Debe retornar el Id de la solicitud.'
        );

        Solicitud_Retiro__c solicitud = [
            SELECT Name, Afiliado__c, Motivo__c,
                   Monto_Solicitado__c, Estado__c,
                   Fecha_Radicacion__c
            FROM Solicitud_Retiro__c
            WHERE Id = :respuesta.solicitudId
        ];
        
        System.assert(!String.isBlank(solicitud.Name),'La solicitud debe tener un nombre.');
        System.assertEquals(afiliadoId, solicitud.Afiliado__c);
        System.assertEquals('Vivienda', solicitud.Motivo__c);
        System.assertEquals(500000, solicitud.Monto_Solicitado__c);
        System.assertEquals('Radicada', solicitud.Estado__c);
        System.assertEquals(Date.today(), solicitud.Fecha_Radicacion__c);
    }

    @IsTest
    static void rechazarAfiliadoNulo() {
        Boolean huboError = false;

        Test.startTest();
        try {
            SolicitudRetiroController.radicarSolicitud(
                null,
                'Vivienda',
                500000
            );
        } catch (AuraHandledException e) {
            huboError = true;
        }
        Test.stopTest();

        System.assert(huboError, 'Debe rechazar un afiliado nulo.');
    }

    @IsTest
    static void rechazarMotivoVacio() {
        Boolean huboError = false;

        Test.startTest();
        try {
            SolicitudRetiroController.radicarSolicitud(
                obtenerAfiliadoId(),
                '',
                500000
            );
        } catch (AuraHandledException e) {
            huboError = true;
        }
        Test.stopTest();

        System.assert(huboError, 'Debe rechazar un motivo vacío.');
    }

    @IsTest
    static void rechazarMontoCero() {
        Boolean huboError = false;

        Test.startTest();
        try {
            SolicitudRetiroController.radicarSolicitud(
                obtenerAfiliadoId(),
                'Vivienda',
                0
            );
        } catch (AuraHandledException e) {
            huboError = true;
        }
        Test.stopTest();

        System.assert(huboError, 'Debe rechazar un monto igual a cero.');
    }

    @IsTest
    static void rechazarMotivoNoPermitido() {
        Boolean huboError = false;

        Test.startTest();
        try {
            SolicitudRetiroController.radicarSolicitud(
                obtenerAfiliadoId(),
                'MotivoInventado',
                500000
            );
        } catch (AuraHandledException e) {
            huboError = true;
        }
        Test.stopTest();

        System.assert(huboError, 'Debe rechazar un motivo no permitido.');
    }
}