@IsTest
public class SolicitudRetiroTriggerHandlerTest {

    /**
     * Método auxiliar para crear un afiliado.
     */
    private static Contact crearAfiliado(String nombre) {

        Contact afiliado = new Contact(
            LastName = nombre
        );

        insert afiliado;

        return afiliado;
    }


    /**
     * 1. Crear una solicitud sin duplicado.
     */
    @IsTest
    static void testCrearSolicitudSinDuplicado() {

        Contact afiliado = crearAfiliado('Afiliado Positivo');

        Solicitud_Retiro__c solicitud = new Solicitud_Retiro__c(
            Afiliado__c = afiliado.Id,
            Motivo__c = 'Vivienda',
            Estado__c = 'Radicada'
        );

        Test.startTest();

        insert solicitud;

        Test.stopTest();

        Solicitud_Retiro__c resultado = [
            SELECT Id,
                   Afiliado__c,
                   Motivo__c,
                   Estado__c
            FROM Solicitud_Retiro__c
            WHERE Id = :solicitud.Id
        ];

        System.assertNotEquals(
            null,
            resultado.Id,
            'La solicitud debería haberse creado.'
        );

        System.assertEquals(
            afiliado.Id,
            resultado.Afiliado__c,
            'El afiliado no coincide.'
        );

        System.assertEquals(
            'Vivienda',
            resultado.Motivo__c,
            'El motivo no coincide.'
        );

        System.assertEquals(
            'Radicada',
            resultado.Estado__c,
            'El estado no coincide.'
        );
    }


    /**
     * 2. Impedir dos solicitudes abiertas
     *    para el mismo afiliado y motivo.
     */
    @IsTest
    static void testBloquearSolicitudDuplicada() {

        Contact afiliado = crearAfiliado('Afiliado Duplicado');

        Solicitud_Retiro__c solicitudExistente =
            new Solicitud_Retiro__c(
                Afiliado__c = afiliado.Id,
                Motivo__c = 'Vivienda',
                Estado__c = 'Radicada'
            );

        insert solicitudExistente;


        Solicitud_Retiro__c solicitudDuplicada =
            new Solicitud_Retiro__c(
                Afiliado__c = afiliado.Id,
                Motivo__c = 'Vivienda',
                Estado__c = 'En validación'
            );

        Test.startTest();

        Database.SaveResult resultado =
            Database.insert(solicitudDuplicada, false);

        Test.stopTest();


        System.assertEquals(
            false,
            resultado.isSuccess(),
            'La solicitud duplicada debería ser rechazada.'
        );

        System.assert(
            resultado.getErrors()[0]
                .getMessage()
                .contains('ya tiene una solicitud abierta'),
            'El mensaje debería indicar que ya existe una solicitud abierta.'
        );
    }


    /**
     * 3. Permitir una nueva solicitud cuando
     *    la solicitud anterior fue Rechazada.
     *
     *    Una solicitud Rechazada debe tener
     *    Motivo_Rechazo__c diligenciado.
     */
    @IsTest
    static void testPermitirSiAnteriorFueRechazada() {

        Contact afiliado = crearAfiliado('Afiliado Rechazado');

        Solicitud_Retiro__c solicitudRechazada =
            new Solicitud_Retiro__c(
                Afiliado__c = afiliado.Id,
                Motivo__c = 'Vivienda',
                Estado__c = 'Rechazada',
                Motivo_Rechazo__c = 'Documentación incompleta'
            );

        insert solicitudRechazada;


        Solicitud_Retiro__c nuevaSolicitud =
            new Solicitud_Retiro__c(
                Afiliado__c = afiliado.Id,
                Motivo__c = 'Vivienda',
                Estado__c = 'Radicada'
            );

        Test.startTest();

        insert nuevaSolicitud;

        Test.stopTest();


        System.assertNotEquals(
            null,
            nuevaSolicitud.Id,
            'La nueva solicitud debería permitirse porque la anterior fue rechazada.'
        );


        Solicitud_Retiro__c resultado = [
            SELECT Id,
                   Estado__c,
                   Motivo_Rechazo__c
            FROM Solicitud_Retiro__c
            WHERE Id = :solicitudRechazada.Id
        ];

        System.assertEquals(
            'Rechazada',
            resultado.Estado__c,
            'La solicitud anterior debería permanecer rechazada.'
        );

        System.assertEquals(
            'Documentación incompleta',
            resultado.Motivo_Rechazo__c,
            'El motivo de rechazo debería estar diligenciado.'
        );
    }


    /**
     * 4. Validar que los estados:
     *    Radicada
     *    En validación
     *    Aprobada
     *
     *    sean considerados estados abiertos.
     */
    @IsTest
    static void testTodosLosEstadosAbiertos() {

        List<String> estados = new List<String>{
            'Radicada',
            'En validación',
            'Aprobada'
        };

        List<Contact> afiliados = new List<Contact>();

        for (String estado : estados) {

            afiliados.add(
                new Contact(
                    LastName = 'Afiliado ' + estado
                )
            );
        }

        insert afiliados;


        List<Solicitud_Retiro__c> solicitudesExistentes =
            new List<Solicitud_Retiro__c>();

        for (Integer i = 0; i < estados.size(); i++) {

            solicitudesExistentes.add(
                new Solicitud_Retiro__c(
                    Afiliado__c = afiliados[i].Id,
                    Motivo__c = 'Vivienda',
                    Estado__c = estados[i]
                )
            );
        }

        insert solicitudesExistentes;


        List<Solicitud_Retiro__c> duplicadas =
            new List<Solicitud_Retiro__c>();

        for (Contact afiliado : afiliados) {

            duplicadas.add(
                new Solicitud_Retiro__c(
                    Afiliado__c = afiliado.Id,
                    Motivo__c = 'Vivienda',
                    Estado__c = 'Radicada'
                )
            );
        }


        Test.startTest();

        Database.SaveResult[] resultados =
            Database.insert(duplicadas, false);

        Test.stopTest();


        for (Integer i = 0; i < resultados.size(); i++) {

            System.assertEquals(
                false,
                resultados[i].isSuccess(),
                'El estado ' +
                estados[i] +
                ' debería considerarse una solicitud abierta.'
            );

            System.assert(
                resultados[i]
                    .getErrors()[0]
                    .getMessage()
                    .contains('ya tiene una solicitud abierta'),
                'Debe indicar que ya existe una solicitud abierta.'
            );
        }
    }


    /**
     * 5. Prueba de carga masiva de 200 registros.
     *
     * 100 solicitudes válidas.
     * 100 solicitudes duplicadas.
     */
    @IsTest
    static void testCargaMasiva200Registros() {

        List<Contact> afiliados = new List<Contact>();

        for (Integer i = 0; i < 100; i++) {

            afiliados.add(
                new Contact(
                    LastName = 'Afiliado Masivo ' + i
                )
            );
        }

        insert afiliados;


        List<Solicitud_Retiro__c> solicitudes =
            new List<Solicitud_Retiro__c>();


        // 100 solicitudes válidas
        for (Contact afiliado : afiliados) {

            solicitudes.add(
                new Solicitud_Retiro__c(
                    Afiliado__c = afiliado.Id,
                    Motivo__c = 'Vivienda',
                    Estado__c = 'Radicada'
                )
            );
        }


        // 100 solicitudes duplicadas
        for (Contact afiliado : afiliados) {

            solicitudes.add(
                new Solicitud_Retiro__c(
                    Afiliado__c = afiliado.Id,
                    Motivo__c = 'Vivienda',
                    Estado__c = 'En validación'
                )
            );
        }


        Test.startTest();

        Database.SaveResult[] resultados =
            Database.insert(solicitudes, false);

        Test.stopTest();


        Integer exitosos = 0;
        Integer errores = 0;


        for (Database.SaveResult resultado : resultados) {

            if (resultado.isSuccess()) {
                exitosos++;
            } else {
                errores++;
            }
        }


        System.assertEquals(
            100,
            exitosos,
            'Deberían crearse exactamente 100 solicitudes.'
        );

        System.assertEquals(
            100,
            errores,
            'Deberían rechazarse exactamente 100 solicitudes duplicadas.'
        );
    }


    /**
     * 6. Validar duplicados dentro de la misma carga.
     */
    @IsTest
    static void testDuplicadosDentroDeLaMismaCarga() {

        Contact afiliado =
            crearAfiliado('Afiliado Misma Carga');


        List<Solicitud_Retiro__c> solicitudes =
            new List<Solicitud_Retiro__c>();


        // Primera solicitud
        solicitudes.add(
            new Solicitud_Retiro__c(
                Afiliado__c = afiliado.Id,
                Motivo__c = 'Vivienda',
                Estado__c = 'Radicada'
            )
        );


        // Segunda solicitud duplicada
        solicitudes.add(
            new Solicitud_Retiro__c(
                Afiliado__c = afiliado.Id,
                Motivo__c = 'Vivienda',
                Estado__c = 'En validación'
            )
        );


        Test.startTest();

        Database.SaveResult[] resultados =
            Database.insert(solicitudes, false);

        Test.stopTest();


        System.assertEquals(
            true,
            resultados[0].isSuccess(),
            'La primera solicitud debería crearse.'
        );

        System.assertEquals(
            false,
            resultados[1].isSuccess(),
            'La segunda solicitud debería ser rechazada.'
        );

        System.assert(
            resultados[1]
                .getErrors()[0]
                .getMessage()
                .contains('otra solicitud abierta'),
            'Debe indicar que existe un duplicado dentro de la carga.'
        );
    }


    /**
     * 7. Una solicitud Rechazada NO cuenta como abierta.
     */
    @IsTest
    static void testRechazadaNoCuentaComoAbierta() {

        Contact afiliado =
            crearAfiliado('Afiliado Rechazada No Abierta');


        Solicitud_Retiro__c rechazada =
            new Solicitud_Retiro__c(
                Afiliado__c = afiliado.Id,
                Motivo__c = 'Vivienda',
                Estado__c = 'Rechazada',
                Motivo_Rechazo__c = 'No cumple requisitos'
            );

        insert rechazada;


        Solicitud_Retiro__c nueva =
            new Solicitud_Retiro__c(
                Afiliado__c = afiliado.Id,
                Motivo__c = 'Vivienda',
                Estado__c = 'Radicada'
            );


        Test.startTest();

        Database.SaveResult resultado =
            Database.insert(nueva, false);

        Test.stopTest();


        System.assertEquals(
            true,
            resultado.isSuccess(),
            'Una solicitud Rechazada no debería bloquear una nueva solicitud.'
        );
    }
}