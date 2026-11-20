<p align="right">
  [ English ](README.md) | [ Português (Brasil) ](README.pt-BR.md) | [ Español ](README.es-ES.md)
</p>

# Swagger4Laz

[![FPC](https://img.shields.io/badge/FPC-%3E%3D%203.2.2-blue.svg)](https://www.freepascal.org/)
[![Lazarus](https://img.shields.io/badge/Lazarus-%3E%3D%203.0-orange.svg)](https://www.lazarus-ide.org/)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.1-brightgreen.svg)](https://swagger.io/specification/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Swagger4Laz es una biblioteca de documentación OpenAPI 3.1 y enrutador con Swagger UI integrado para Free Pascal y Lazarus. Extiende el componente `httproute.THTTPRouter` nativo de FPC para declarar rutas tipadas, esquemas de datos, parámetros de solicitud, envoltorios de respuesta y gestión de errores mediante una API fluida en Pascal.

---

## Especificaciones Técnicas

- **Compilador**: Free Pascal Compiler (FPC) >= 3.2.2.
- **IDE / Herramientas**: Lazarus >= 3.0 (`lazbuild`).
- **Sistemas Operativos**: Linux (x86_64, aarch64), Windows (x86_64, i386), macOS (x86_64, arm64).
- **Estándares Compatibles**: OpenAPI 3.1.0 y RFC 7807 (Problem Details for HTTP APIs).
- **Dependencias Internas**: `httproute`, `fpjson`, `jsonparser`, `fgl`, `TypInfo`. Sin dependencias de bibliotecas externas en C.

---

## Instalación

### Método 1: Gestor de Paquetes de Lazarus
1. En Lazarus, vaya a `Paquete` -> `Abrir archivo de paquete (.lpk)`.
2. Seleccione `swagger4laz.lpk`.
3. Haga clic en `Compilar` y luego en `Usar` -> `Instalar`.

### Método 2: Ruta Manual de Unidades
Añada el directorio de `swagger4laz.pas` a la ruta de unidades de su compilador:
```bash
fpc -Fu/ruta/a/swagger4laz mi_api.lpr
```

---

## Guía Rápida (60 Segundos)

API HTTP funcional con documentación interactiva y Swagger UI integrado:

```pascal
program QuickstartApi;

{$mode Delphi}{$H+}

uses
  {$IFDEF UNIX}cthreads, cmem,{$ENDIF}
  SysUtils, HTTPDefs, fphttpapp, httproute,
  swagger4laz;

procedure HandleGetUser(AReq: TRequest; AResp: TResponse);
begin
  AResp.Code := 200;
  AResp.ContentType := 'application/json';
  AResp.Content := '{"id":' + AReq.RouteParams['id'] + ',"name":"Carlos García"}';
end;

begin
  // Metadatos de OpenAPI
  SwaggerRouter
    .SetTitle('API de Usuarios')
    .SetVersion('1.0.0')
    .SetDescription('Servicio de gestión de cuentas')
    .SetDocRoute('/docs'); // Publica Swagger UI en /docs y la especificación en /docs/openapi.json

  // Registro del esquema en components.schemas
  SwaggerRouter.EnsureModel(
    'User',
    '{"type":"object","properties":{"id":{"type":"integer"},"name":{"type":"string"}}}'
  );

  // Registro y documentación de la ruta
  SwaggerRouter
    .Get('/api/v1/users/:id', @HandleGetUser)
    .SetSummary('Buscar usuario por ID')
    .Tag('Users')
    .PathParam('id', 'integer', 'Identificador numérico del usuario')
    .Produces(200, 'User', 'Usuario localizado')
    .ProducesProblem(404);

  // Inicialización del servidor en el puerto 8080
  Application.Port := 8080;
  Application.Threaded := True;
  Application.Initialize;
  Application.Run;
end.
```

Abra `http://localhost:8080/docs` en su navegador para interactuar con la interfaz.

---

## API de Enrutamiento

### Registro de Rutas
`SwaggerRouter` implementa los métodos estándar correspondientes a `httproute`:

```pascal
SwaggerRouter.Get('/items', @HandleListItems);
SwaggerRouter.Post('/items', @HandleCreateItem);
SwaggerRouter.Put('/items/:id', @HandleUpdateItem);
SwaggerRouter.Delete('/items/:id', @HandleDeleteItem);
SwaggerRouter.Patch('/items/:id', @HandlePatchItem);
```

### Grupos de Rutas (`TSwaggerRouteGroup`)
Los grupos permiten compartir prefijos de URL, etiquetas, esquemas de autenticación y códigos de error entre múltiples endpoints:

```pascal
var
  Api: TSwaggerRouteGroup;
begin
  Api := SwaggerRouter.Group('/api/v1/clientes')
           .Tag('Clientes')
           .SecurityBearer
           .Problem(400)
           .Problem(401)
           .Problem(404);

  // Hereda prefijo '/api/v1/clientes', etiqueta 'Clientes', autenticación Bearer y errores 400/401/404
  Api.Get('', @HandleListarClientes)
     .ProducesPaginated(200, 'Cliente', 'Lista paginada de clientes');

  Api.Get('/:id', @HandleBuscarCliente)
     .PathParam('id', 'integer', 'ID del cliente')
     .Produces(200, 'Cliente', 'Datos del cliente');

  Api.Post('', @HandleCrearCliente)
     .ConsumesJson('ClienteInput', True, 'Carga útil de registro')
     .Produces(201, 'Cliente', 'Cliente creado');

  Api.Delete('/:id', @HandleEliminarCliente)
     .PathParam('id', 'integer', 'ID del cliente')
     .ProducesEmpty(204, 'Cliente eliminado');
end;
```

---

## Parámetros de Solicitud

Declare parámetros con tipos estrictos y ámbitos definidos (`Path`, `Query`, `Header`, `Enum`):

```pascal
SwaggerRouter.Get('/api/v1/busqueda/:categoria', @HandleBusqueda)
  // Parámetro de ruta (obligatorio)
  .PathParam('categoria', 'string', 'Filtro por categoría')

  // Parámetro de consulta con valor predeterminado
  .QueryParam('q', 'string', '', 'Texto de búsqueda')
  .QueryParam('page', 'integer', '1', 'Número de página')
  .QueryParam('page_size', 'integer', '20', 'Cantidad por página')

  // Encabezado HTTP
  .HeaderParam('X-Trace-Id', 'string', False, 'Identificador de rastreo')

  // Parámetro con valores fijos permitidos (Enum)
  .EnumParam('status', ['ACTIVO', 'INACTIVO', 'PENDIENTE'], 'Filtro por estado');
```

---

## Cuerpo de la Solicitud (Payload)

```pascal
// Payload JSON referenciando components.schemas/ProductoInput
Route.ConsumesJson('ProductoInput', True, 'Datos del producto');

// Datos en formulario estándar (application/x-www-form-urlencoded)
Route.ConsumesFormData('Formulario de inicio de sesión');

// Carga multipart para subida de ficheros (multipart/form-data)
Route.ConsumesMultipart('Subida de archivos adjuntos');
```

---

## Definición de Respuestas

Métodos directos para respuestas canónicas de OpenAPI:

```pascal
// Referencia a objeto único ($ref: #/components/schemas/Producto)
Route.Produces(200, 'Producto', 'Operación ejecutada con éxito');

// Lista simple: { type: "array", items: { $ref: #/components/schemas/Producto } }
Route.ProducesArray(200, 'Producto', 'Lista de productos');

// Envoltorio paginado: { type: "object", properties: { items: [...], total_records: ... } }
Route.ProducesPaginated(200, 'Producto', 'Respuesta paginada');

// Respuesta sin contenido (HTTP 204)
Route.ProducesEmpty(204, 'Registro eliminado');
```

---

## Errores en el Estándar RFC 7807

El esquema `ProblemDetails` se registra de forma automática en `components.schemas`:

```pascal
// Respuesta de error individual con Content-Type: application/problem+json
Route.ProducesProblem(400); // Bad Request
Route.ProducesProblem(404); // Not Found

// Declaración de múltiples códigos de error
Route.ProducesProblem([400, 403, 404, 409]);

// Declaración del conjunto estándar de errores (400, 401, 403, 404, 409, 422, 500)
Route.ProducesStandardProblems;
```

---

## Esquemas de Autenticación

Configure la autenticación a nivel de ruta, grupo o enrutador global:

```pascal
// Bearer JWT (Authorization: Bearer <token>)
Route.SecurityBearer;

// HTTP Basic (Authorization: Basic <credenciales>)
Route.SecurityBasic;

// Clave en encabezado HTTP (predeterminado: X-API-Key)
Route.SecurityApiKey('X-Tenant-Key');

// Ruta pública dentro de un grupo protegido
Route.SecurityNone;
```

---

## Registro de Modelos

Los esquemas pueden incorporarse a `components.schemas` mediante programación:

```pascal
// Registrar esquema JSON explícito
SwaggerRouter.RegisterModel(
  'Pedido',
  '{"type":"object","properties":{"id":{"type":"integer"},"total":{"type":"number"}}}'
);

// Registro idempotente (no duplica si ya existe)
SwaggerRouter.EnsureModel('Pedido', JsonSchemaString);

// Registro de enumeración (Enum)
SwaggerRouter.RegisterEnumModel('EstadoPedido', ['BORRADOR', 'CONFIRMADO', 'ENVIADO', 'CANCELADO']);
```

---

## Publicación de Endpoints

```pascal
// Registra automáticamente Swagger UI en /docs y la especificación en /docs/openapi.json
SwaggerRouter.SetDocRoute('/docs');

// O vinculación manual de las rutinas:
HTTPRouter.RegisterRoute('/api/openapi.json', rmGet, @Documentation);
HTTPRouter.RegisterRoute('/api/docs', rmGet, @SwaggerUI);
```

---

## Licencia

Distribuido bajo la licencia MIT. Consulte el archivo [LICENSE](LICENSE) para más detalles.
