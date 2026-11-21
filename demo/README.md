# Swagger4Laz — Demo Server & Automated OpenAPI 3.1 Test Suite (`demo`)

This directory contains two standalone programs demonstrating **Swagger4Laz** (`swagger4laz.pas`), the fluent OpenAPI 3.1 documentation generator and HTTP route builder for Free Pascal and Lazarus:

1. **`project1.lpr` (`utodo.pas`)**: A standalone `fphttpapp` HTTP server exposing documented `/todo` routes with multi-format content negotiation (`application/json`, `application/cbor`, `application/bson`, `application/xml`, `text/csv`), GZIP encoding headers, and an embedded interactive Swagger UI at `/docs`.
2. **`test_swagger.lpr`**: An automated CLI verification suite testing OpenAPI 3.1 JSON specification generation, component schema registration (`EnsureModel` / `HasModel`), `$ref` linking, paginated envelopes (`ProducesPaginated`), route grouping (`TSwaggerRouteGroup`), multi-format media types, and `Accept-Encoding` / `Content-Encoding` GZIP metadata.

---

## 🚀 Key Features Demonstrated

- **Component Schema Registry**:
  - Idempotent model registration via `SwaggerRouter.EnsureModel('Todo', '{...}')` and lookup via `SwaggerRouter.HasModel('Todo')`.
- **Multi-Format Content Negotiation**:
  - `.Produces(200, 'Todo', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON, MEDIA_TYPE_XML, MEDIA_TYPE_CSV], 'List of todos')`
  - `.Consumes('Todo', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON], True, 'Todo payload')`
  - `.ProducesPaginated(200, 'TodoItem', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR], 'Paginated items')`
- **GZIP Compression Metadata**:
  - `.AcceptsGzip` and `.ProducesGzip` (or group-level `.EnableGzip`) documenting `Accept-Encoding` request headers and `Content-Encoding: gzip` response headers.
- **Fluent Route Groups (`TSwaggerRouteGroup`)**:
  - `SwaggerRouter.Group('/api/v2').Tag('V2').ProducesMediaTypes([MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR]).EnableGzip`

---

## 🛠️ Build & Run

### 1. Automated OpenAPI 3.1 Test Suite (`test_swagger.lpr`)

Compile and run the self-contained test suite using a temporary output folder:

```bash
mkdir -p /tmp/swagger4laz_demo
cd demo

fpc -MObjFPC -Scghi -O2 \
  -FE/tmp/swagger4laz_demo \
  -FU/tmp/swagger4laz_demo \
  -Fu.. \
  -Fu. \
  test_swagger.lpr

/tmp/swagger4laz_demo/test_swagger
```

Expected result: all assertions pass (`Fail: 0`) with exit code `0`.

### 2. Interactive HTTP Server Demo (`project1.lpr`)

#### Option A: Compile with Free Pascal Compiler (`fpc`)

```bash
mkdir -p /tmp/swagger4laz_demo
cd demo

fpc -MObjFPC -Scghi -O2 \
  -FE/tmp/swagger4laz_demo \
  -FU/tmp/swagger4laz_demo \
  -Fu.. \
  -Fu. \
  project1.lpr
```

#### Option B: Compile with Lazarus (`lazbuild`)

```bash
lazbuild demo/project1.lpi
```

#### Running the Demo Server

```bash
/tmp/swagger4laz_demo/project1
```

Once running on port `8080`, open:
- **Interactive Swagger UI**: `http://localhost:8080/docs`
- **OpenAPI 3.1 JSON Specification**: `http://localhost:8080/docs/openapi.json`

---

## 🛡️ License

Part of the **Swagger4Laz / Zenith Framework** ecosystem under the MIT License.
