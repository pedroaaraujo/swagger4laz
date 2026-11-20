<p align="right">
  [ English ](README.md) | [ Português (Brasil) ](README.pt-BR.md) | [ Español ](README.es-ES.md)
</p>

# Swagger4Laz

[![FPC](https://img.shields.io/badge/FPC-%3E%3D%203.2.2-blue.svg)](https://www.freepascal.org/)
[![Lazarus](https://img.shields.io/badge/Lazarus-%3E%3D%203.0-orange.svg)](https://www.lazarus-ide.org/)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.1-brightgreen.svg)](https://swagger.io/specification/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Swagger4Laz is an OpenAPI 3.1 specification builder and embedded Swagger UI router for Free Pascal and Lazarus. It extends the native `httproute.THTTPRouter` to declare typed API routes, schemas, request parameters, response envelopes, and error objects using a fluent Pascal API.

---

## Technical Specifications

- **Compilers**: Free Pascal Compiler (FPC) >= 3.2.2.
- **IDE / Tooling**: Lazarus >= 3.0 (`lazbuild`).
- **Operating Systems**: Linux (x86_64, aarch64), Windows (x86_64, i386), macOS (x86_64, arm64).
- **Specification Standard**: OpenAPI 3.1.0 and RFC 7807 (Problem Details for HTTP APIs).
- **Core Dependencies**: `httproute`, `fpjson`, `jsonparser`, `fgl`, `TypInfo`. No external C library bindings required.

---

## Installation

### Method 1: Lazarus Package Manager
1. In Lazarus, open `Package` -> `Open Package File (.lpk)`.
2. Select `swagger4laz.lpk`.
3. Click `Compile` and `Use` -> `Install`.

### Method 2: Manual Unit Path
Add `swagger4laz.pas` to your project directory or compiler unit path:
```bash
fpc -Fu/path/to/swagger4laz my_api.lpr
```

---

## Quickstart (60 Seconds)

A minimal standalone HTTP API with documented routes and embedded Swagger UI:

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
  AResp.Content := '{"id":' + AReq.RouteParams['id'] + ',"name":"John Doe"}';
end;

begin
  // Configure OpenAPI metadata
  SwaggerRouter
    .SetTitle('User Directory API')
    .SetVersion('1.0.0')
    .SetDescription('Internal user management service')
    .SetDocRoute('/docs'); // Serves Swagger UI at /docs and OpenAPI spec at /docs/openapi.json

  // Register schema definition in components.schemas
  SwaggerRouter.EnsureModel(
    'User',
    '{"type":"object","properties":{"id":{"type":"integer"},"name":{"type":"string"}}}'
  );

  // Register route with documentation
  SwaggerRouter
    .Get('/api/v1/users/:id', @HandleGetUser)
    .SetSummary('Fetch user by ID')
    .Tag('Users')
    .PathParam('id', 'integer', 'Unique identifier of the user')
    .Produces(200, 'User', 'User found')
    .ProducesProblem(404);

  // Start HTTP server on port 8080
  Application.Port := 8080;
  Application.Threaded := True;
  Application.Initialize;
  Application.Run;
end.
```

Open `http://localhost:8080/docs` in your browser to view the interactive documentation.

---

## Core Routing API

### Route Registration
`SwaggerRouter` exposes HTTP verbs corresponding to `httproute`:

```pascal
SwaggerRouter.Get('/items', @HandleListItems);
SwaggerRouter.Post('/items', @HandleCreateItem);
SwaggerRouter.Put('/items/:id', @HandleUpdateItem);
SwaggerRouter.Delete('/items/:id', @HandleDeleteItem);
SwaggerRouter.Patch('/items/:id', @HandlePatchItem);
```

### Route Groups
Groups allow sharing a path prefix, tags, authentication, and error responses across multiple endpoints:

```pascal
var
  Api: TSwaggerRouteGroup;
begin
  Api := SwaggerRouter.Group('/api/v1/customers')
           .Tag('Customers')
           .SecurityBearer
           .Problem(400)
           .Problem(401)
           .Problem(404);

  // Inherits prefix '/api/v1/customers', tag 'Customers', Bearer auth, and 400/401/404 errors
  Api.Get('', @HandleListCustomers)
     .ProducesPaginated(200, 'Customer', 'Paginated list of customers');

  Api.Get('/:id', @HandleGetCustomer)
     .PathParam('id', 'integer', 'Customer ID')
     .Produces(200, 'Customer', 'Customer profile');

  Api.Post('', @HandleCreateCustomer)
     .ConsumesJson('CustomerInput', True, 'Customer registration payload')
     .Produces(201, 'Customer', 'Customer created');

  Api.Delete('/:id', @HandleDeleteCustomer)
     .PathParam('id', 'integer', 'Customer ID')
     .ProducesEmpty(204, 'Customer deleted');
end;
```

---

## Parameters

Declare parameters with exact types and locations (`Path`, `Query`, `Header`, `Enum`):

```pascal
SwaggerRouter.Get('/api/v1/search/:category', @HandleSearch)
  // Path parameter (always required)
  .PathParam('category', 'string', 'Product category filter')

  // Query parameter with default value
  .QueryParam('q', 'string', '', 'Search query string')
  .QueryParam('page', 'integer', '1', 'Page number')
  .QueryParam('page_size', 'integer', '20', 'Records per page')

  // HTTP Request Header
  .HeaderParam('X-Trace-Id', 'string', False, 'Correlation identifier')

  // Enumerated set of values
  .EnumParam('status', ['ACTIVE', 'INACTIVE', 'PENDING'], 'Account status filter');
```

---

## Request Body Declarations

```pascal
// JSON payload referencing components.schemas/ProductInput
Route.ConsumesJson('ProductInput', True, 'Product data');

// Standard form-data payload (application/x-www-form-urlencoded)
Route.ConsumesFormData('User login form');

// Multipart payload for file uploads (multipart/form-data)
Route.ConsumesMultipart('File attachment payload');
```

---

## Response Definitions

Swagger4Laz provides shorthand builders for canonical OpenAPI responses:

```pascal
// Single object reference ($ref: #/components/schemas/Product)
Route.Produces(200, 'Product', 'Operation succeeded');

// Array response: { type: "array", items: { $ref: #/components/schemas/Product } }
Route.ProducesArray(200, 'Product', 'List of products');

// Paginated envelope: { type: "object", properties: { items: [...], total_records: ... } }
Route.ProducesPaginated(200, 'Product', 'Paginated response');

// No-content response (HTTP 204)
Route.ProducesEmpty(204, 'Entity deleted');
```

---

## RFC 7807 Problem Details

Swagger4Laz natively registers the `ProblemDetails` schema in `components.schemas` and provides helpers for standard HTTP error responses:

```pascal
// Register individual error response (returns application/problem+json)
Route.ProducesProblem(400); // Bad Request
Route.ProducesProblem(404); // Not Found

// Register multiple error codes at once
Route.ProducesProblem([400, 403, 404, 409]);

// Register standard suite (400, 401, 403, 404, 409, 422, 500)
Route.ProducesStandardProblems;
```

---

## Security Schemes

Configure authentication schemes at the router, group, or route level:

```pascal
// Bearer JWT (Authorization: Bearer <token>)
Route.SecurityBearer;

// HTTP Basic (Authorization: Basic <credentials>)
Route.SecurityBasic;

// API Key in HTTP Header (default header: X-API-Key)
Route.SecurityApiKey('X-Tenant-Key');

// Disable authentication for public endpoints in a protected group
Route.SecurityNone;
```

---

## Model Registration

Schemas can be added to `components.schemas` programmatically or dynamically:

```pascal
// Register JSON Schema string
SwaggerRouter.RegisterModel(
  'Order',
  '{"type":"object","properties":{"id":{"type":"integer"},"total":{"type":"number"}}}'
);

// Idempotent registration (skips if already exists)
SwaggerRouter.EnsureModel('Order', JsonSchemaString);

// Register enum schema
SwaggerRouter.RegisterEnumModel('OrderStatus', ['DRAFT', 'CONFIRMED', 'SHIPPED', 'CANCELLED']);
```

---

## Serving Endpoints

```pascal
// Automatically registers Swagger UI at /docs and specification at /docs/openapi.json
SwaggerRouter.SetDocRoute('/docs');

// Or bind endpoints manually:
HTTPRouter.RegisterRoute('/api/openapi.json', rmGet, @Documentation);
HTTPRouter.RegisterRoute('/api/docs', rmGet, @SwaggerUI);
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
