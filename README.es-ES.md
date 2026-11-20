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

**Swagger4Laz** es una biblioteca moderna y fluida para **Lazarus / Free Pascal (FPC)** diseñada para integrarse a la perfección con **FCL-Web** (`httproute.THTTPRouter`). Automatiza la generación de la especificación **OpenAPI 3.1** (`openapi.json`) y sirve directamente la interfaz visual de **Swagger UI** desde el binario nativo compilado, eliminando la necesidad de servidores auxiliares (como Node.js) o herramientas externas.

---

## ✨ Características

- 📄 **OpenAPI 3.1 Automático**: Genera dinámicamente el archivo `openapi.json` a partir de las rutas registradas.
- 🎨 **Swagger UI Integrado**: Sirve la interfaz web interactiva de Swagger UI en una ruta configurable (por defecto `/docs`).
- 🔗 **Enrutamiento Fluido**: Extensión de `THTTPRouter` con llamadas a métodos encadenados (`Get`, `Post`, `Put`, `Delete`, `Patch`).
- 🎯 **Gestión Exhaustiva de Parámetros**:
  - Parámetros de ruta con conversión automática de `:param` a notación `{param}`.
  - Parámetros de consulta (Query), Encabezados (Headers) y Cookies.
  - Soporte completo para enumeraciones (enums) y valores predeterminados.
- 📦 **Documentación de Cuerpos y Respuestas**:
  - Esquemas tipados para el cuerpo de la petición (Request Body).
  - Múltiples códigos de respuesta HTTP con descripciones y esquemas JSON.
- 🔒 **Esquemas de Seguridad**:
  - **Bearer Token (JWT)**
  - **Autenticación Básica (Basic Auth)**
  - **API Key** (mediante encabezado HTTP personalizable, ej.: `X-API-Key`)
- 🌐 **Listo para Proxies Inversos**:
  - Detección automática de prefijos mediante encabezados `X-Forwarded-Prefix`.
  - BasePath configurable para entornos en contenedores.
- 🛡️ **CORS y Encabezados Globales**:
  - Soporte para encabezados personalizados globales en la documentación y respuestas.
- ⚡ **Deduplicación y Normalización de Métodos HTTP**:
  - Agrupa múltiples verbos HTTP bajo la misma ruta y normaliza barras finales.
- 🌐 **Internacionalización Integrada (i18n)**:
  - Mensajes de error y excepciones configurables por idioma (`en-US`, `pt-BR`, `es-ES`) mediante `SetSwaggerLocale` o variables de entorno `SWAGGER_LOCALE` / `ZENITH_LOCALE`.
  - Identificadores y métodos 100% en inglés nativo (`Documentation`, con alias de compatibilidad `Documentacao`).

---

## 📦 Requisitos

- **Free Pascal Compiler (FPC)** 3.2.2 o superior.
- **Lazarus IDE** 2.2 o superior.
- Paquete **FCL-Web** (incluido en la instalación estándar de FPC).

---

## 🚀 Inicio Rápido

### 1. Inicialización Básica

Simplemente importe `swagger4laz` en su unidad o programa principal. La instancia global `SwaggerRouter` estará lista para usarse:

```pascal
program MiApi;

{$mode ObjFPC}{$H+}

uses
  Classes, SysUtils, fphttpapp,
  swagger4laz;

begin
  // Configuración de los metadatos de la API
  SwaggerRouter
    .SetTitle('Mi API en Lazarus')
    .SetVersion('1.0.0')
    .SetDescription('Documentación interactiva generada con Swagger4Laz')
    .SetDocRoute('/docs') // Endpoint donde se sirve Swagger UI
    .AddServer('http://localhost:8080', 'Servidor Local de Desarrollo');

  Application.Port := 8080;
  Application.Initialize;
  Application.Run;
end.
```

Abra su navegador en:
- Swagger UI: `http://localhost:8080/docs`
- OpenAPI JSON: `http://localhost:8080/docs/openapi.json`

El documento JSON se expone automáticamente bajo la ruta configurada. Por ejemplo, `SetDocRoute('/api/docs')` registrará el archivo en `/api/docs/openapi.json`.

---

### 2. Registro de Rutas con Documentación

La API fluida permite encadenar metadatos, parámetros de consulta, cuerpos de petición y respuestas:

```pascal
uses
  HTTPDefs, swagger4laz;

// Controlador para listar usuarios
procedure GetUsers(ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.Code := 200;
  AResponse.ContentType := 'application/json';
  AResponse.Content := '[{"id": 1, "name": "Juan"}]';
end;

// Controlador para crear usuario
procedure CreateUser(ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.Code := 201;
  AResponse.ContentType := 'application/json';
  AResponse.Content := '{"id": 2, "name": "María"}';
end;

procedure RegisterRoutes;
begin
  // GET /users con parámetros de consulta y respuesta
  SwaggerRouter
    .Get('/users', @GetUsers)
    .SetSummary('Lista de usuarios registrados')
    .SetDescription('Devuelve una lista paginada de usuarios')
    .AddTags('Usuarios')
    .AddQueryParam('page', False, 'integer', '1', 'Número de página')
    .AddQueryParam('limit', False, 'integer', '10', 'Cantidad de registros por página')
    .AddResponse(200, 'Lista de usuarios devuelta con éxito', '[{"id":1,"name":"string"}]');

  // POST /users con cuerpo de petición y seguridad Bearer JWT
  SwaggerRouter
    .Post('/users', @CreateUser)
    .SetSummary('Registra un nuevo usuario')
    .AddTags('Usuarios')
    .SetSecurityBearer
    .SetBodyContent('{"name": "string", "email": "string"}', True, 'application/json', 'Datos del usuario')
    .AddResponse(201, 'Usuario creado con éxito')
    .AddResponse(400, 'Datos de solicitud inválidos');
end;
```

---

### 3. Parámetros de Ruta (Path Parameters)

Declare parámetros de ruta precedidos por dos puntos (`:param`). Swagger4Laz los transformará automáticamente a la notación `{param}` de OpenAPI y registrará la ruta en `THTTPRouter`:

```pascal
procedure GetUserById(ARequest: TRequest; AResponse: TResponse);
var
  UserId: string;
begin
  UserId := ARequest.RouteParams['id'];
  AResponse.Code := 200;
  AResponse.ContentType := 'application/json';
  AResponse.Content := Format('{"id": %s, "name": "Juan"}', [UserId]);
end;

procedure RegisterUserRoute;
begin
  SwaggerRouter
    .Get('/users/:id', @GetUserById)
    .SetSummary('Obtener usuario por ID')
    .AddTags('Usuarios')
    .AddPathParam('id', True, 'integer', '', 'Identificador único del usuario')
    .AddResponse(200, 'Usuario encontrado')
    .AddResponse(404, 'Usuario no encontrado');
end;
```

---

### 4. Parámetros Enum y Encabezados

```pascal
SwaggerRouter
  .Get('/orders', @GetOrders)
  .AddTags('Pedidos')
  .AddEnumParam('status', ['PENDING', 'APPROVED', 'CANCELLED'], False, piQuery, 'PENDING', 'Filtro por estado del pedido')
  .AddHeaderParam('X-Tenant-ID', True, 'string', '', 'Identificador del Tenant')
  .AddResponse(200, 'Pedidos filtrados');
```

---

### 5. Esquemas de Seguridad

Defina autenticación por ruta o de manera global:

```pascal
// Bearer Token (JWT)
Router.Get('/private-data', @PrivateHandler)
  .SetSecurityBearer;

// Autenticación Básica (usuario/contraseña)
Router.Get('/admin', @AdminHandler)
  .SetSecurityBasic;

// API Key en encabezado HTTP personalizado
Router.Get('/service-api', @ServiceHandler)
  .SetSecurityApiKey('X-Custom-API-Key');

// Ruta explícitamente pública
Router.Get('/public', @PublicHandler)
  .SetSecurityNone;
```

---

### 6. Registro Canónico de Esquemas en `components.schemas` y Resolución `$ref`

Swagger4Laz implementa un registro centralizado y seguro para hilos de esquemas de componentes según OpenAPI 3.1:

#### A. Registro de Esquemas en el Router

```pascal
// 1. Registro idempotente (EnsureModel): no duplica ni lanza error si ya existe
SwaggerRouter.EnsureModel('Producto', '{"type": "object", "properties": {"id": {"type": "integer"}, "nombre": {"type": "string"}}}');

// 2. Registro estricto (RegisterModel): lanza excepción si existe, salvo que AOverwrite sea True
SwaggerRouter.RegisterModel('Categoria', '{"type": "object", "properties": {"descripcion": {"type": "string"}}}', True);

// 3. Verificación de existencia
if not SwaggerRouter.HasModel('Producto') then
  SwaggerRouter.EnsureModel('Producto', ProductoSchemaJson);
```

#### B. Resolución de Punteros `$ref` en Peticiones y Respuestas

Al documentar endpoints, puede hacer referencia a modelos registrados mediante prefijos intuitivos o punteros canónicos JSON:

```pascal
procedure RegisterProductRoutes;
begin
  // 1. Referencia directa al esquema:
  // Genera: {"schema": {"$ref": "#/components/schemas/Producto"}}
  SwaggerRouter
    .Get('/productos/:id', @GetProduct)
    .SetSummary('Obtener producto por ID')
    .AddTags('Productos')
    .AddPathParam('id', True, 'integer', '1', 'ID del producto')
    .AddResponse(200, 'Producto localizado', 'ref:Producto'); // o '#/components/schemas/Producto'

  // 2. Array de referencias:
  // Genera: {"schema": {"type": "array", "items": {"$ref": "#/components/schemas/Producto"}}}
  SwaggerRouter
    .Get('/produtos', @ListProducts)
    .SetSummary('Listar todos los productos')
    .AddTags('Productos')
    .AddResponse(200, 'Lista de productos', 'array:Producto');

  // 3. Envoltorio paginado de referencias:
  // Genera: {"schema": {"type": "object", "properties": {"items": {"type": "array", "items": {"$ref": "#/components/schemas/Producto"}}, "page": ..., "total_records": ...}}}
  SwaggerRouter
    .Get('/produtos/paginados', @ListProductsPaginated)
    .SetSummary('Listar productos con paginación')
    .AddTags('Productos')
    .AddResponse(200, 'Productos paginados', 'paginated:Producto');
end;
```

#### C. Validación Estricta en Tiempo de Ejecución

Si una ruta referencia un modelo no registrado en `components/schemas` (por ejemplo, `ref:Inexistente`), Swagger4Laz lanza de inmediato una excepción explícita al renderizar el documento:
```
Exception: Schema "Inexistente" no registrado en components/schemas.
```
Esto previene que se publiquen especificaciones OpenAPI defectuosas o con punteros rotos hacia clientes frontend o herramientas de integración.

---

### 7. Integración Nativa con DeltaModel ORM

Bibliotecas como **DeltaModel** se integran directamente con Swagger4Laz generando esquemas canónicos y envoltorios sin código repetitivo:

```pascal
SwaggerRouter
  .Post('/productos', @CreateProduct)
  .AddTags('Productos')
  // Cuerpo de la petición con esquema de objeto
  .SetBodyContent(TProductModel.SwaggerSchemaObject(), True)
  // Respuesta con envoltorio paginado
  .AddResponse(200, 'Lista paginada', TProductModel.SwaggerSchemaPaginated())
  // Respuesta que referencia components.schemas
  .AddResponse(201, 'Producto creado', TProductModel.SwaggerSchemaRefObject);
```

---

## 🛠️ Referencia de la API

### `TSwaggerRouter`

| Método | Descripción |
| :--- | :--- |
| `Get(APattern, ACallBack)` | Registra ruta para el verbo HTTP GET (retorna `THTTPDocRoute`) |
| `Post(APattern, ACallBack)` | Registra ruta para el verbo HTTP POST (retorna `THTTPDocRoute`) |
| `Put(APattern, ACallBack)` | Registra ruta para el verbo HTTP PUT (retorna `THTTPDocRoute`) |
| `Delete(APattern, ACallBack)` | Registra ruta para el verbo HTTP DELETE (retorna `THTTPDocRoute`) |
| `Patch(APattern, ACallBack)` | Registra ruta para el verbo HTTP PATCH (retorna `THTTPDocRoute`) |
| `SetDocRoute(Endpoint)` | Define la URI de Swagger UI (por defecto: `/docs`) |
| `SetTitle(ATitle)` | Define el título de la API |
| `SetVersion(AVersion)` | Define la versión de la API |
| `SetDescription(Text)` | Define la descripción general de la API |
| `AddServer(Url, Description)` | Agrega una URL de servidor en la especificación OpenAPI |
| `SetBasePath(APath)` | Configura el prefijo de ruta base para proxies |
| `AddCustomHeader(Header, Value)` | Agrega encabezado global a las respuestas |
| `EnsureModel(Name, Schema)` | Registra un esquema en `components/schemas` de forma idempotente |
| `RegisterModel(Name, Schema, Overwrite)` | Registra un esquema con control de sobrescritura |
| `HasModel(Name)` | Comprueba si el esquema ya existe |
| `RegisterEnumModel(Name, Values)` | Registra una enumeración en `components/schemas` |
| `BuildOpenAPISpecification(BasePath)` | Genera la especificación OpenAPI 3.1 completa en JSON |
| `ClearCache` | Invalida la memoria caché del documento OpenAPI |

### `THTTPDocRoute`

| Método | Descripción |
| :--- | :--- |
| `SetSummary(Text)` / `Summary(Text)` | Define el resumen corto del endpoint |
| `SetDescription(Text)` / `Description(Text)` | Define la descripción detallada |
| `AddTags(Name)` / `Tag(Name)` / `Tags(Array)` | Agrega etiqueta para agrupación visual en Swagger UI |
| `SetSecurityBearer` / `SecurityBearer` | Configura seguridad Bearer JWT |
| `SetSecurityBasic` / `SecurityBasic` | Configura seguridad Basic Auth |
| `SetSecurityApiKey(Name)` / `SecurityApiKey(Name)` | Configura seguridad por API Key en encabezado |
| `SetSecurityNone` / `SecurityNone` | Marca la ruta como explícitamente pública |
| `AddPathParam(...)` / `PathParam(...)` | Documenta parámetro en la URL (`:param`) |
| `AddQueryParam(...)` / `QueryParam(...)` | Documenta parámetro de consulta (`?param=...`) |
| `AddHeaderParam(...)` / `HeaderParam(...)` | Documenta parámetro en encabezado HTTP |
| `AddEnumParam(...)` | Documenta parámetro con valores predefinidos |
| `SetBodyContent(...)` / `Body(...)` | Define esquema del cuerpo de la petición |
| `SetBodyContentRef(ModelName, ...)` | Define cuerpo apuntando directamente a `$ref` |
| `AddResponse(...)` / `Response(...)` | Documenta código HTTP y esquema de respuesta |
| `AddResponseRef(Code, ModelName, ...)` | Documenta respuesta apuntando a `$ref` |
| `AddResponseRefArray(Code, ModelName, ...)` | Documenta respuesta como array de `$ref` |
| `AddResponseRefPaginated(Code, ModelName, ...)` | Documenta respuesta con envoltorio paginado de `$ref` |
| `SetDeprecated(Value)` | Marca el endpoint como obsoleto en Swagger UI |

---

## 🧪 Suite de Pruebas Automatizadas

Swagger4Laz incluye una suite de pruebas unitarias en `demo/test_swagger.lpr` que valida el 100% de las funciones:

- **Idempotencia**: `EnsureModel` no duplica registros ni lanza excepciones al registrar el mismo modelo varias veces.
- **Búsqueda de Modelos**: `HasModel` refleja con precisión el estado del registro.
- **Resolución de `$ref`**:
  - `ref:NombreModelo` y `#/components/schemas/NombreModelo` generan `{"$ref": "#/components/schemas/NombreModelo"}`.
  - `array:NombreModelo` genera `{"type": "array", "items": {"$ref": "#/components/schemas/NombreModelo"}}`.
  - `paginated:NombreModelo` genera envoltorios canónicos paginados con metadatos.
- **Control Estricto de Contratos**: Comprueba que referencias a modelos inexistentes lancen excepciones inmediatas y descriptivas.

### Ejecución de pruebas:

```bash
cd demo
fpc -B -FE. -FUlib -Fu.. test_swagger.lpr
./test_swagger
```

---

## 📄 Licencia

Distribuido bajo la Licencia MIT. Consulte `LICENSE` para más detalles.
