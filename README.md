<p align="right">
  <b>Language / Idioma:</b>
  <a href="README.md">English</a> |
  <a href="README.pt-BR.md">Português (Brasil)</a> |
  <a href="README.es-ES.md">Español</a>
</p>

# Swagger4Laz

[![Lazarus](https://img.shields.io/badge/Lazarus-2.2%2B-blue.svg)](https://www.lazarus-ide.org/)
[![FreePascal](https://img.shields.io/badge/FPC-3.2.2%2B-green.svg)](https://www.freepascal.org/)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.1.0-brightgreen.svg)](https://swagger.io/specification/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Swagger4Laz** is a modern, fluent OpenAPI documentation library for **Lazarus / Free Pascal (FPC)** designed to integrate seamlessly with **FCL-Web** (`httproute.THTTPRouter`). It automates the generation of the **OpenAPI 3.1** specification (`openapi.json`) and serves the interactive **Swagger UI** web interface directly from your compiled native binary, eliminating any requirement for Node.js or third-party documentation runtimes.

---

## ✨ Features

- 📄 **Automated OpenAPI 3.1**: Dynamically builds `openapi.json` from registered routes.
- 🎨 **Embedded Swagger UI**: Serves the interactive Swagger UI directly from a configurable route (defaults to `/docs`).
- 🔗 **Fluent Route Definition**: Extends `THTTPRouter` with chainable method calls (`Get`, `Post`, `Put`, `Delete`, `Patch`).
- 🎯 **Comprehensive Parameter Handling**:
  - Path parameters with automated transformation from `:param` to `{param}` notation.
  - Query parameters, Headers, and Cookies.
  - Full support for enums and default values.
- 📦 **Request & Response Documentation**:
  - Strongly-typed Request Body schemas.
  - Multiple HTTP status responses with descriptions and JSON schemas.
- 🔒 **Security Schemes**:
  - **Bearer Token (JWT)**
  - **Basic Authentication**
  - **API Key** (via customizable HTTP header, e.g., `X-API-Key`)
- 🌐 **Reverse Proxy Ready**:
  - Automatic base path and prefix detection via `X-Forwarded-Prefix` headers.
  - Configurable BasePath for containerized deployments.
- 🛡️ **CORS & Global Headers**:
  - Support for custom global headers in documentation and HTTP responses.
- ⚡ **HTTP Method Deduplication & Normalization**:
  - Groups multiple HTTP verbs under the same path and normalizes trailing slashes.
- 🌐 **Built-in Internationalization (i18n)**:
  - Error messages and internal exceptions configurable by locale (`en-US`, `pt-BR`, `es-ES`) via `SetSwaggerLocale` or environment variables `SWAGGER_LOCALE` / `ZENITH_LOCALE`.
  - 100% English native identifiers and APIs (`Documentation`, with `Documentacao` backwards compatibility alias).

---

## 📦 Requirements

- **Free Pascal Compiler (FPC)** 3.2.2 or higher.
- **Lazarus IDE** 2.2 or higher.
- **FCL-Web** package (bundled with standard FPC installations).

---

## 🚀 Quick Start

### 1. Basic Initialization

Simply import `swagger4laz` in your main program or unit. The global `SwaggerRouter` singleton is immediately ready for use:

```pascal
program MyApi;

{$mode ObjFPC}{$H+}

uses
  Classes, SysUtils, fphttpapp,
  swagger4laz;

begin
  // Configure API metadata
  SwaggerRouter
    .SetTitle('My Lazarus API')
    .SetVersion('1.0.0')
    .SetDescription('Interactive API documentation generated with Swagger4Laz')
    .SetDocRoute('/docs') // Endpoint where Swagger UI is served
    .AddServer('http://localhost:8080', 'Local Development Server');

  Application.Port := 8080;
  Application.Initialize;
  Application.Run;
end.
```

Open your browser at:
- Swagger UI: `http://localhost:8080/docs`
- OpenAPI JSON: `http://localhost:8080/docs/openapi.json`

The OpenAPI JSON specification is automatically exposed under the configured doc route. For example, `SetDocRoute('/api/docs')` will serve the JSON file at `/api/docs/openapi.json`.

---

### 2. Registering Routes with Documentation

The fluent API allows chaining metadata, query parameters, request bodies, and responses:

```pascal
uses
  HTTPDefs, swagger4laz;

// Handler to list users
procedure GetUsers(ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.Code := 200;
  AResponse.ContentType := 'application/json';
  AResponse.Content := '[{"id": 1, "name": "John"}]';
end;

// Handler to create user
procedure CreateUser(ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.Code := 201;
  AResponse.ContentType := 'application/json';
  AResponse.Content := '{"id": 2, "name": "Mary"}';
end;

procedure RegisterRoutes;
begin
  // GET /users with query parameters and response
  SwaggerRouter
    .Get('/users', @GetUsers)
    .SetSummary('List registered users')
    .SetDescription('Returns a paginated list of users')
    .AddTags('Users')
    .AddQueryParam('page', False, 'integer', '1', 'Page number')
    .AddQueryParam('limit', False, 'integer', '10', 'Number of records per page')
    .AddResponse(200, 'User list returned successfully', '[{"id":1,"name":"string"}]');

  // POST /users with request body and Bearer JWT security
  SwaggerRouter
    .Post('/users', @CreateUser)
    .SetSummary('Register a new user')
    .AddTags('Users')
    .SetSecurityBearer
    .SetBodyContent('{"name": "string", "email": "string"}', True, 'application/json', 'User data payload')
    .AddResponse(201, 'User created successfully')
    .AddResponse(400, 'Invalid request payload');
end;
```

---

### 3. Path Parameters

Declare route parameters preceded by a colon (`:param`). Swagger4Laz automatically translates them to OpenAPI `{param}` notation and registers the route in `THTTPRouter`:

```pascal
procedure GetUserById(ARequest: TRequest; AResponse: TResponse);
var
  UserId: string;
begin
  UserId := ARequest.RouteParams['id'];
  AResponse.Code := 200;
  AResponse.ContentType := 'application/json';
  AResponse.Content := Format('{"id": %s, "name": "John"}', [UserId]);
end;

procedure RegisterUserRoute;
begin
  SwaggerRouter
    .Get('/users/:id', @GetUserById)
    .SetSummary('Retrieve user by ID')
    .AddTags('Users')
    .AddPathParam('id', True, 'integer', '', 'Unique user identifier')
    .AddResponse(200, 'User found')
    .AddResponse(404, 'User not found');
end;
```

---

### 4. Enum Parameters and Custom Headers

```pascal
SwaggerRouter
  .Get('/orders', @GetOrders)
  .AddTags('Orders')
  .AddEnumParam('status', ['PENDING', 'APPROVED', 'CANCELLED'], False, piQuery, 'PENDING', 'Order status filter')
  .AddHeaderParam('X-Tenant-ID', True, 'string', '', 'Tenant identifier header')
  .AddResponse(200, 'Filtered orders');
```

---

### 5. Security Schemes

Define authentication per route or globally:

```pascal
// Bearer Token (JWT)
Router.Get('/private-data', @PrivateHandler)
  .SetSecurityBearer;

// Basic Authentication (username/password)
Router.Get('/admin', @AdminHandler)
  .SetSecurityBasic;

// API Key in custom HTTP Header
Router.Get('/service-api', @ServiceHandler)
  .SetSecurityApiKey('X-Custom-API-Key');

// Explicitly Public Route
Router.Get('/public', @PublicHandler)
  .SetSecurityNone;
```

---

### 6. Canonical Schema Registry (`components.schemas`) and `$ref` Resolution

Swagger4Laz provides a centralized, thread-safe schema registry fully compliant with OpenAPI 3.1:

#### A. Registering Schemas in the Router

```pascal
// 1. Idempotent registration (EnsureModel): does nothing if model already exists
SwaggerRouter.EnsureModel('Product', '{"type": "object", "properties": {"id": {"type": "integer"}, "name": {"type": "string"}}}');

// 2. Strict registration (RegisterModel): raises exception on duplicate unless AOverwrite is True
SwaggerRouter.RegisterModel('Category', '{"type": "object", "properties": {"description": {"type": "string"}}}', True);

// 3. Existence check
if not SwaggerRouter.HasModel('Product') then
  SwaggerRouter.EnsureModel('Product', ProductSchemaJson);
```

#### B. Resolving `$ref` Pointers in Requests and Responses

When documenting endpoints, you can reference registered schemas using friendly shorthand prefixes or canonical JSON pointers:

```pascal
procedure RegisterProductRoutes;
begin
  // 1. Single model reference:
  // Produces: {"schema": {"$ref": "#/components/schemas/Product"}}
  SwaggerRouter
    .Get('/products/:id', @GetProduct)
    .SetSummary('Get product by ID')
    .AddTags('Products')
    .AddPathParam('id', True, 'integer', '1', 'Product ID')
    .AddResponse(200, 'Product retrieved', 'ref:Product'); // or '#/components/schemas/Product'

  // 2. Array of references:
  // Produces: {"schema": {"type": "array", "items": {"$ref": "#/components/schemas/Product"}}}
  SwaggerRouter
    .Get('/products', @ListProducts)
    .SetSummary('List all products')
    .AddTags('Products')
    .AddResponse(200, 'Product collection', 'array:Product');

  // 3. Paginated envelope of references:
  // Produces: {"schema": {"type": "object", "properties": {"items": {"type": "array", "items": {"$ref": "#/components/schemas/Product"}}, "page": ..., "total_records": ...}}}
  SwaggerRouter
    .Get('/products/paginated', @ListProductsPaginated)
    .SetSummary('List paginated products')
    .AddTags('Products')
    .AddResponse(200, 'Paginated products envelope', 'paginated:Product');
end;
```

#### C. Strict Runtime Contract Validation

If an endpoint references an unregistered schema (e.g., `ref:NonExistent`), Swagger4Laz throws an informative exception when the OpenAPI document is rendered:
```
Exception: Schema "NonExistent" not registered in components/schemas.
```
This fails fast and guarantees broken documentation or dangling pointers are never published to frontend clients or API consumers.

---

### 7. Native Integration with DeltaModel ORM

Micro-ORMs such as **DeltaModel** integrate directly with Swagger4Laz, generating canonical schemas and envelopes without boilerplate:

```pascal
SwaggerRouter
  .Post('/products', @CreateProduct)
  .AddTags('Products')
  // Request body with model schema
  .SetBodyContent(TProductModel.SwaggerSchemaObject(), True)
  // Response with paginated envelope
  .AddResponse(200, 'Paginated list', TProductModel.SwaggerSchemaPaginated())
  // Response referencing components.schemas
  .AddResponse(201, 'Product created', TProductModel.SwaggerSchemaRefObject);
```

---

## 🛠️ API Reference

### `TSwaggerRouter`

| Method | Description |
| :--- | :--- |
| `Get(APattern, ACallBack)` | Registers an HTTP GET route (returns `THTTPDocRoute`) |
| `Post(APattern, ACallBack)` | Registers an HTTP POST route (returns `THTTPDocRoute`) |
| `Put(APattern, ACallBack)` | Registers an HTTP PUT route (returns `THTTPDocRoute`) |
| `Delete(APattern, ACallBack)` | Registers an HTTP DELETE route (returns `THTTPDocRoute`) |
| `Patch(APattern, ACallBack)` | Registers an HTTP PATCH route (returns `THTTPDocRoute`) |
| `SetDocRoute(Endpoint)` | Sets the Swagger UI URI (defaults to `/docs`) |
| `SetTitle(ATitle)` | Sets API title |
| `SetVersion(AVersion)` | Sets API version |
| `SetDescription(Text)` | Sets API description |
| `AddServer(Url, Description)` | Adds an API server URL |
| `SetBasePath(APath)` | Configures base path prefix for proxies |
| `AddCustomHeader(Header, Value)` | Appends global response header |
| `EnsureModel(Name, Schema)` | Idempotently registers a schema in `components/schemas` |
| `RegisterModel(Name, Schema, Overwrite)` | Registers schema with overwrite flag |
| `HasModel(Name)` | Checks if schema is present |
| `RegisterEnumModel(Name, Values)` | Registers an enum in `components/schemas` |
| `BuildOpenAPISpecification(BasePath)` | Generates complete OpenAPI 3.1 JSON string |
| `ClearCache` | Invalidates cached OpenAPI JSON |

### `THTTPDocRoute`

| Method | Description |
| :--- | :--- |
| `SetSummary(Text)` / `Summary(Text)` | Sets short endpoint summary |
| `SetDescription(Text)` / `Description(Text)` | Sets detailed description |
| `AddTags(Name)` / `Tag(Name)` / `Tags(Array)` | Adds tag for Swagger UI grouping |
| `SetSecurityBearer` / `SecurityBearer` | Configures Bearer JWT security |
| `SetSecurityBasic` / `SecurityBasic` | Configures Basic Auth security |
| `SetSecurityApiKey(Name)` / `SecurityApiKey(Name)` | Configures API Key header security |
| `SetSecurityNone` / `SecurityNone` | Marks route as explicitly public |
| `AddPathParam(...)` / `PathParam(...)` | Documents path parameter (`:param`) |
| `AddQueryParam(...)` / `QueryParam(...)` | Documents query parameter (`?param=...`) |
| `AddHeaderParam(...)` / `HeaderParam(...)` | Documents custom HTTP header parameter |
| `AddEnumParam(...)` | Documents predefined enum parameter |
| `SetBodyContent(...)` / `Body(...)` | Defines Request Body schema payload |
| `SetBodyContentRef(ModelName, ...)` | Sets request body pointing directly to `$ref` |
| `AddResponse(...)` / `Response(...)` | Documents HTTP status code and schema |
| `AddResponseRef(Code, ModelName, ...)` | Documents response pointing to `$ref` |
| `AddResponseRefArray(Code, ModelName, ...)` | Documents response as array of `$ref` |
| `AddResponseRefPaginated(Code, ModelName, ...)` | Documents paginated envelope of `$ref` |
| `SetDeprecated(Value)` | Marks endpoint as deprecated in Swagger UI |

---

## 🧪 Automated Test Suite

Swagger4Laz includes an automated test suite in `demo/test_swagger.lpr` verifying 100% of OpenAPI 3.1 features:

- **Idempotency**: `EnsureModel` never duplicates records nor throws on repeated registration.
- **Model Lookup**: `HasModel` accurately reflects dictionary contents.
- **`$ref` Resolution**:
  - `ref:ModelName` and `#/components/schemas/ModelName` yield `{"$ref": "#/components/schemas/ModelName"}`.
  - `array:ModelName` yields `{"type": "array", "items": {"$ref": "#/components/schemas/ModelName"}}`.
  - `paginated:ModelName` yields canonical paginated envelopes with count and pagination metadata.
- **Strict Contract Enforcement**: Validates that missing references throw fast, descriptive exceptions.

### Running Tests:

```bash
cd demo
fpc -B -FE. -FUlib -Fu.. test_swagger.lpr
./test_swagger
```

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
