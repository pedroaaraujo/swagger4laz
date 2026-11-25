<p align="right">
  [ English ](README.md) | [ Português (Brasil) ](README.pt-BR.md) | [ Español ](README.es-ES.md)
</p>

# Swagger4Laz

[![FPC](https://img.shields.io/badge/FPC-%3E%3D%203.2.2-blue.svg)](https://www.freepascal.org/)
[![Lazarus](https://img.shields.io/badge/Lazarus-%3E%3D%203.0-orange.svg)](https://www.lazarus-ide.org/)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.1-brightgreen.svg)](https://swagger.io/specification/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Swagger4Laz is an OpenAPI 3.1 specification builder and embedded Swagger UI router for Free Pascal and Lazarus. It extends the native `httproute.THTTPRouter` to declare typed API routes, schemas, request parameters, response envelopes, multi-format content negotiation (JSON, CBOR, BSON, XML, CSV), and RFC 7807 problem details using a fluent Pascal API.

---

## Technical Specifications

- **Compilers**: Free Pascal Compiler (FPC) >= 3.2.2.
- **IDE / Tooling**: Lazarus >= 3.0 (`lazbuild`).
- **Operating Systems**: Linux (x86_64, aarch64), Windows (x86_64, i386), macOS (x86_64, arm64).
- **Specification Standard**: OpenAPI 3.1.0 and RFC 7807 (Problem Details for HTTP APIs).
- **Supported Media Types**: `application/json`, `application/cbor`, `application/bson`, `application/xml`, `text/xml`, `text/csv`, `application/x-www-form-urlencoded`, `multipart/form-data`.
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

## Request Body Declarations (Multi-Format)

Declare expected input payloads for JSON, binary formats (CBOR, BSON), XML, and form uploads:

```pascal
// Fluent multi-format input payload declaration
Route.Consumes('ProductInput', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON], True, 'Product payload');

// Standard JSON payload referencing components.schemas/ProductInput
Route.ConsumesJson('ProductInput', True, 'JSON product payload');

// Binary CBOR payload (RFC 8949)
Route.SetBodyContentRef('ProductInput', True, MEDIA_TYPE_CBOR, 'Binary CBOR payload');

// Binary BSON payload (v1.1)
Route.SetBodyContentRef('ProductInput', True, MEDIA_TYPE_BSON, 'Binary BSON document');

// XML payload
Route.SetBodyContentRef('ProductInput', True, MEDIA_TYPE_XML, 'XML document payload');

// Form data payload (application/x-www-form-urlencoded)
Route.ConsumesFormData('User login form');

// Multipart payload for file uploads (multipart/form-data)
Route.ConsumesMultipart('File attachment payload');
```

---

## Response Definitions & Multi-Format Negotiation

Swagger4Laz models multiple representations under the same HTTP status code, enabling accurate OpenAPI 3.1 documentation for endpoints supporting content negotiation (`Accept` header):

```pascal
// Fluent multi-format response definition in a single call:
Route.Produces(200, 'Product', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON, MEDIA_TYPE_XML, MEDIA_TYPE_CSV], 'Multi-format product');

// Fluent chaining across media types:
Route
  .Produces(200, 'Product', 'Standard JSON response')
  .Produces([MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON]);

// Array and paginated responses in multiple formats:
Route.ProducesArray(200, 'Product', [MEDIA_TYPE_JSON, MEDIA_TYPE_CSV], 'Product list and CSV export');
Route.ProducesPaginated(200, 'Product', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR], 'Paginated products');

// Compression and content encoding headers:
Route
  .AcceptsGzip     // Documents 'Accept-Encoding: gzip' header parameter
  .ProducesGzip;   // Documents 'Content-Encoding: gzip' in 200 response

// No-content response (HTTP 204)
Route.ProducesEmpty(204, 'Entity deleted');
```

### Route Group & Router Defaults

Eliminate repetitive boilerplate across routes by declaring media types and compression defaults at the router or group level:

```pascal
// Group-level defaults automatically inherited by all child routes:
Api := SwaggerRouter.Group('/api/v1/catalog')
  .Tag('Catalog')
  .ProducesMediaTypes([MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON])
  .ConsumesMediaTypes([MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR])
  .EnableGzip;

// Automatically documents JSON, CBOR, BSON and GZIP compression:
Api.Get('/products', @HandleListProducts)
   .Produces(200, 'Product', 'Catalog items');
```

### Media Types Tradeoffs Overview

| Media Type | Payload vs JSON | Ideal Context | Key Characteristics |
| :--- | :--- | :--- | :--- |
| `application/json` | Baseline (100%) | Web SPAs, JavaScript clients | Universal browser compatibility, human-readable |
| `application/cbor` | ~40-60% smaller | Mobile (Flutter), IoT, microservices | Compact binary, IEEE 754 floats, Zero-DOM parsing |
| `application/bson` | Comparable | Document storage, analytical workers | 32-bit length prefix, rich types, UTC datetime ms |
| `text/csv` | Compact for flat tables | Bulk exports, reporting, analytics | RFC 4180 tabular records, spreadsheet ready |
| `application/xml` | ~20-40% larger | Enterprise legacy, fiscal compliance | W3C strict validation, entity escaping |

---

## RFC 7807 Problem Details

Swagger4Laz natively registers the `ProblemDetails` schema in `components.schemas` and provides helpers for standard HTTP error responses:

```pascal
// Register individual error response (returns application/problem+json)
Route.ProducesProblem(400); // Bad Request
Route.ProducesProblem(404); // Not Found

// Route-specific description (updates the code if a group default already added it)
Route.ProducesProblem(403, 'User has no access to the Accounts Payable module');

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
