Despliegue en una organización limpia *

# 1. Clonar el repositorio
git clone <URL_DEL_REPOSITORIO>
Ingresar al proyecto:
cd solicitud-retiro-salesforce

# 2. Autenticar la organización

Autenticar una organización Salesforce utilizando SF CLI:
sf org login web --alias Evaluacion
Se abrirá el navegador para completar la autenticación.
Verificar las organizaciones autenticadas:
sf org list

# 3. Validar el proyecto
Verificar que el proyecto contiene el archivo:
sfdx-project.json
y la metadata dentro de:
force-app/main/default/

# 4. Validar el despliegue
Antes de realizar el despliegue definitivo se recomienda ejecutar una validación:
sf project deploy start \
    --source-dir force-app/main/default \
    --target-org Evaluacion \
    --dry-run
Si la validación finaliza correctamente, proceder con el despliegue.

# 5. Desplegar la metadata
sf project deploy start \
    --source-dir force-app/main/default \
    --target-org Evaluacion
También se puede utilizar el package.xml incluido en el proyecto:

sf project deploy start \
    --manifest manifest/package.xml \
    --target-org Evaluacion
Ejecución de pruebas

Después del despliegue:
sf apex run test \
    --target-org Evaluacion \
    --result-format human \
    --wait 10

# Para ejecutar específicamente las pruebas de la solución:

sf apex run test \
    --class-names SolicitudRetiroTriggerHandlerTest \
    --target-org Evaluacion \
    --result-format human \
    --wait 10
Verificación

# Una vez desplegado el proyecto se recomienda verificar:

El objeto Solicitud_Retiro__c.
El objeto Contact
Sus campos y relaciones.
El Trigger SolicitudRetiroTrigger.
El Handler SolicitudRetiroTriggerHandler.
La clase de pruebas.
Los Flows incluidos.
La aplicación Lightning.
El agente de Agentforce.
Los dos subagentes.
Las acciones utilizadas por Agentforce.

# Consideraciones

El despliegue debe realizarse sobre una organización con las funcionalidades requeridas disponibles.
Los datos de prueba no forman parte del repositorio. Las pruebas Apex crean sus propios datos utilizando @TestSetup y/o métodos de prueba.

No se almacenan credenciales ni información de autenticación de Salesforce dentro del repositorio.

# Autor

Carlos Ardila Chacon - Desarrollador Salesforce Junior

Desarrollado utilizando Salesforce Platform, Apex, Flow, Agentforce y Salesforce CLI