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

**Swagger4Laz** é uma biblioteca moderna e fluente para **Lazarus / Free Pascal (FPC)** desenvolvida para integrar-se perfeitamente com o **FCL-Web** (`httproute.THTTPRouter`). Ela automatiza a geração da especificação **OpenAPI 3.1** (`openapi.json`) e serve diretamente a interface visual do **Swagger UI**, eliminando a necessidade de servidores auxiliares (como Node.js) ou ferramentas externas.

---

## ✨ Recursos

- 📄 **OpenAPI 3.1 Automático**: Gera dinamicamente o arquivo `openapi.json` a partir das rotas cadastradas.
- 🎨 **Swagger UI Embutido**: Serve a interface web interativa do Swagger UI em rota configurável (padrão `/docs`).
- 🔗 **Roteamento Fluente**: Extensão de `THTTPRouter` com métodos encadeados (`Get`, `Post`, `Put`, `Delete`, `Patch`).
- 🎯 **Tratamento de Parâmetros**:
  - Path parameters com conversão automática de `:param` para `{param}`.
  - Query parameters, Headers e Cookies.
  - Suporte a enums e valores padrão.
- 📦 **Documentação de Corpos e Respostas**:
  - Schemas de requisição (Request Body).
  - Múltiplas respostas HTTP com códigos de status, descrições e schemas JSON.
- 🔒 **Esquemas de Segurança**:
  - **Bearer Token (JWT)**
  - **Basic Authentication**
  - **API Key** (via Header customizável, ex.: `X-API-Key`)
- 🌐 **Pronto para Reverse Proxies**:
  - Detecção automática de prefixos via cabeçalho `X-Forwarded-Prefix`.
  - BasePath configurável.
- 🛡️ **CORS & Headers**:
  - Suporte a headers globais customizados na documentação e nas respostas.
- ⚡ **Desduplicação e Normalização de Métodos HTTP**:
  - Agrupa múltiplos verbos HTTP na mesma URI e normaliza barras finais.
- 🌐 **Internacionalização de Mensagens (i18n)**:
  - Mensagens de erro e exceções configuráveis por idioma (`en-US`, `pt-BR`, `es-ES`) via `SetSwaggerLocale` ou variáveis de ambiente `SWAGGER_LOCALE` / `ZENITH_LOCALE`.
  - Código-fonte, métodos e identificadores 100% em inglês (`Documentation`, com alias `Documentacao`).

---

## 📦 Requisitos

- **Free Pascal Compiler (FPC)** 3.2.2 ou superior.
- **Lazarus IDE** 2.2 ou superior.
- Pacote **FCL-Web** (incluído na instalação padrão do FPC).

---

## 🚀 Como Usar

### 1. Inicialização Básica

Basta importar `swagger4laz` na sua unidade ou programa principal. A instância global `SwaggerRouter` já estará disponível:

```pascal
uses
  Classes, SysUtils, fphttpapp,
  swagger4laz;

begin
  // Configuração dos metadados da API
  SwaggerRouter
    .SetTitle('Minha API Lazarus')
    .SetVersion('1.0.0')
    .SetDescription('Documentação interativa gerada com Swagger4Laz')
    .SetDocRoute('/docs') // Endpoint onde o Swagger UI será servido
    .AddServer('http://localhost:8080', 'Servidor Local');

  Application.Port := 8080;
  Application.Initialize;
  Application.Run;
end.
```

Acesse no navegador:
- Swagger UI: `http://localhost:8080/docs`
- OpenAPI JSON: `http://localhost:8080/docs/openapi.json`

O documento JSON fica sob a rota do Swagger UI configurada com `SetDocRoute`.
Por exemplo, `SetDocRoute('/api/docs')` registra a especificação em `/api/docs/openapi.json`.

---

### 2. Registrando Rotas com Documentação

A API fluente do `SwaggerRouter` permite configurar tags, parâmetros, corpo e respostas encadeando chamadas:

```pascal
uses
  HTTPDefs, swagger4laz;

// Handler para listar usuários
procedure GetUsers(ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.Code := 200;
  AResponse.ContentType := 'application/json';
  AResponse.Content := '[{"id": 1, "name": "João"}]';
end;

// Handler para criar usuário
procedure CreateUser(ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.Code := 201;
  AResponse.ContentType := 'application/json';
  AResponse.Content := '{"id": 2, "name": "Maria"}';
end;

procedure RegisterRoutes;
begin
  // GET /users com query parameters e resposta
  SwaggerRouter
    .Get('/users', @GetUsers)
    .SetSummary('Lista usuários cadastrados')
    .SetDescription('Retorna uma lista paginada de usuários')
    .AddTags('Usuários')
    .AddQueryParam('page', False, 'integer', '1', 'Número da página')
    .AddQueryParam('limit', False, 'integer', '10', 'Quantidade por página')
    .AddResponse(200, 'Lista de usuários retornada com sucesso', '[{"id":1,"name":"string"}]');

  // POST /users com corpo de requisição e segurança Bearer
  SwaggerRouter
    .Post('/users', @CreateUser)
    .SetSummary('Cadastra um novo usuário')
    .AddTags('Usuários')
    .SetSecurityBearer
    .SetBodyContent('{"name": "string", "email": "string"}', True, 'application/json', 'Dados do usuário')
    .AddResponse(201, 'Usuário criado com sucesso')
    .AddResponse(400, 'Dados inválidos');
end;
```

---

### 3. Parâmetros de Rota (Path Parameters)

Defina rotas com parâmetros precedidos por dois-pontos (`:param`). O Swagger4Laz converterá automaticamente para a notação OpenAPI (`{param}`) e vinculará a rota no `THTTPRouter`:

```pascal
procedure GetUserById(ARequest: TRequest; AResponse: TResponse);
var
  UserId: string;
begin
  UserId := ARequest.RouteParams['id'];
  AResponse.Code := 200;
  AResponse.ContentType := 'application/json';
  AResponse.Content := Format('{"id": %s, "name": "João"}', [UserId]);
end;

procedure RegisterUserRoute;
begin
  SwaggerRouter
    .Get('/users/:id', @GetUserById)
    .SetSummary('Obter usuário por ID')
    .AddTags('Usuários')
    .AddPathParam('id', True, 'integer', '', 'Identificador único do usuário')
    .AddResponse(200, 'Usuário encontrado')
    .AddResponse(404, 'Usuário não encontrado');
end;
```

---

### 4. Parâmetros Enum e Headers

```pascal
SwaggerRouter
  .Get('/orders', @GetOrders)
  .AddTags('Pedidos')
  .AddEnumParam('status', ['PENDING', 'APPROVED', 'CANCELLED'], False, piQuery, 'PENDING', 'Filtro de status do pedido')
  .AddHeaderParam('X-Tenant-ID', True, 'string', '', 'Identificador do Tenant')
  .AddResponse(200, 'Pedidos filtrados');
```

---

### 5. Esquemas de Segurança

É possível definir autenticação por rota ou globalmente:

```pascal
// Bearer Token (JWT)
Router.Get('/private-data', @PrivateHandler)
  .SetSecurityBearer;

// Basic Authentication (usuário/senha)
Router.Get('/admin', @AdminHandler)
  .SetSecurityBasic;

// API Key em Header customizado
Router.Get('/service-api', @ServiceHandler)
  .SetSecurityApiKey('X-Custom-API-Key');

// Rota pública explícita
Router.Get('/public', @PublicHandler)
  .SetSecurityNone;
```

---

### 6. Registro Canônico de Schemas em `components.schemas` e Resolução `$ref`

O Swagger4Laz implementa um registro centralizado e thread-safe de schemas de componentes em conformidade estrita com o OpenAPI 3.1:

#### A. Registrando Schemas no Router

```pascal
// 1. Registro idempotente (EnsureModel): se já existir, não sobrescreve nem lança erro
SwaggerRouter.EnsureModel('Produto', '{"type": "object", "properties": {"id": {"type": "integer"}, "nome": {"type": "string"}}}');

// 2. Registro estrito (RegisterModel): lança exceção se duplicado, a menos que AOverwrite seja True
SwaggerRouter.RegisterModel('Categoria', '{"type": "object", "properties": {"descricao": {"type": "string"}}}', True);

// 3. Verificação de existência
if not SwaggerRouter.HasModel('Produto') then
  SwaggerRouter.EnsureModel('Produto', ProdutoSchemaJson);
```

#### B. Resolução de Referências `$ref` em Respostas e Corpos

Ao documentar endpoints, você pode referenciar modelos registrados utilizando sintaxes amigáveis ou ponteiros JSON canônicos:

```pascal
procedure RegisterProductRoutes;
begin
  // 1. Resposta com referência direta ao schema:
  // Gera: {"schema": {"$ref": "#/components/schemas/Produto"}}
  SwaggerRouter
    .Get('/produtos/:id', @GetProduct)
    .SetSummary('Obter produto por ID')
    .AddTags('Produtos')
    .AddPathParam('id', True, 'integer', '1', 'ID do produto')
    .AddResponse(200, 'Produto localizado', 'ref:Produto'); // ou '#/components/schemas/Produto'

  // 2. Resposta com Array de referências:
  // Gera: {"schema": {"type": "array", "items": {"$ref": "#/components/schemas/Produto"}}}
  SwaggerRouter
    .Get('/produtos', @ListProducts)
    .SetSummary('Listar todos os produtos')
    .AddTags('Produtos')
    .AddResponse(200, 'Lista de produtos', 'array:Produto');

  // 3. Resposta com Envelope Paginado de referências:
  // Gera: {"schema": {"type": "object", "properties": {"items": {"type": "array", "items": {"$ref": "#/components/schemas/Produto"}}, "page": ..., "total_records": ...}}}
  SwaggerRouter
    .Get('/produtos/paginados', @ListProductsPaginated)
    .SetSummary('Listar produtos com paginação')
    .AddTags('Produtos')
    .AddResponse(200, 'Produtos paginados', 'paginated:Produto');
end;
```

#### C. Validação Rigorosa em Runtime

Se uma rota referenciar um modelo não registrado em `components/schemas` (por exemplo, `ref:Inexistente`), o Swagger4Laz lança imediatamente uma exceção explicativa no momento da renderização do documento:
```
Exception: Schema "Inexistente" não registrado em components/schemas.
```
Isso impede que especificações OpenAPI inválidas ou com referências quebradas sejam servidas para clientes frontend ou ferramentas de integração.

---

### 7. Integração Direta com DeltaModel

Bibliotecas como o **DeltaModel** integram-se nativamente ao Swagger4Laz gerando schemas canônicos e referências sem repetição de código:

```pascal
// Usando métodos tipados semânticos do DeltaModel:
SwaggerRouter
  .Post('/produtos', @CreateProduct)
  .AddTags('Produtos')
  // Request Body com schema de objeto
  .SetBodyContent(TProductModel.SwaggerSchemaObject(), True)
  // Response com envelope paginado
  .AddResponse(200, 'Lista paginada', TProductModel.SwaggerSchemaPaginated())
  // Response referenciando components.schemas
  .AddResponse(201, 'Produto cadastrado', TProductModel.SwaggerSchemaRefObject);
```

---

## 🛠️ Referência da API

### `TSwaggerRouter`

| Método | Descrição |
| :--- | :--- |
| `Get(APattern, ACallBack)` | Registra rota para o verbo HTTP GET (retorna `THTTPDocRoute`) |
| `Post(APattern, ACallBack)` | Registra rota para o verbo HTTP POST (retorna `THTTPDocRoute`) |
| `Put(APattern, ACallBack)` | Registra rota para o verbo HTTP PUT (retorna `THTTPDocRoute`) |
| `Delete(APattern, ACallBack)` | Registra rota para o verbo HTTP DELETE (retorna `THTTPDocRoute`) |
| `Patch(APattern, ACallBack)` | Registra rota para o verbo HTTP PATCH (retorna `THTTPDocRoute`) |
| `SetDocRoute(Endpoint)` | Define a URI do Swagger UI (padrão: `/docs`) |
| `SetTitle(ATitle)` | Define o título da documentação |
| `SetVersion(AVersion)` | Define a versão da API |
| `SetDescription(Text)` | Define a descrição geral da API |
| `AddServer(Url, Description)` | Adiciona uma URL de servidor na especificação OpenAPI |
| `SetBasePath(APath)` | Define o caminho base da API (suporta prefixos de proxy) |
| `AddCustomHeader(Header, Value)` | Adiciona cabeçalho global às respostas |
| `EnsureModel(Name, Schema)` | Registra um schema em `components/schemas` de forma idempotente (thread-safe) |
| `RegisterModel(Name, Schema, Overwrite)` | Registra um schema em `components/schemas` com controle de sobrescrita |
| `HasModel(Name)` | Verifica se um schema já está presente em `components/schemas` |
| `RegisterEnumModel(Name, Values)` | Registra uma enumeração em `components/schemas` |
| `BuildOpenAPISpecification(BasePath)` | Gera a especificação OpenAPI 3.1 completa como string JSON (sem expor HTTP) |
| `ClearCache` | Invalida o cache do documento OpenAPI gerado |

### `THTTPDocRoute`

| Método | Descrição |
| :--- | :--- |
| `SetSummary(Text)` / `Summary(Text)` | Define o resumo curto do endpoint |
| `SetDescription(Text)` / `Description(Text)` | Define a descrição detalhada |
| `AddTags(Name)` / `Tag(Name)` / `Tags(Array)` | Adiciona tag para agrupamento visual no Swagger UI |
| `SetSecurityBearer` / `SecurityBearer` | Configura autenticação Bearer JWT para a rota |
| `SetSecurityBasic` / `SecurityBasic` | Configura autenticação Basic Auth para a rota |
| `SetSecurityApiKey(Name)` / `SecurityApiKey(Name)` | Configura autenticação por API Key no header |
| `SetSecurityNone` / `SecurityNone` | Define rota explicitamente pública |
| `AddPathParam(...)` / `PathParam(...)` | Documenta parâmetro presente na URL (`:param`) |
| `AddQueryParam(...)` / `QueryParam(...)` | Documenta parâmetro de query string (`?param=...`) |
| `AddHeaderParam(...)` / `HeaderParam(...)` | Documenta parâmetro no header HTTP |
| `AddEnumParam(Name, Values, Required, ParamIn, ...)` | Documenta parâmetro aceitando valores pré-definidos |
| `SetBodyContent(...)` / `Body(...)` | Define schema do payload de entrada da requisição |
| `SetBodyContentRef(ModelName, Required, ContentType, Desc)` | Define o corpo da requisição apontando diretamente para um `$ref` em `components/schemas` |
| `AddResponse(...)` / `Response(...)` | Documenta códigos HTTP e schemas de retorno |
| `AddResponseRef(Code, ModelName, Description, ContentType)` | Documenta resposta referenciando diretamente um schema em `components/schemas` |
| `AddResponseRefArray(Code, ModelName, Description, ContentType)` | Documenta resposta como array de itens referenciando um schema em `components/schemas` |
| `AddResponseRefPaginated(Code, ModelName, Description, ContentType)` | Documenta resposta com envelope paginado padrão referenciando itens em `components/schemas` |
| `SetDeprecated(Value)` | Marca o endpoint como obsoleto no Swagger UI |

---

## 🧪 Suíte de Testes Automatizados

O Swagger4Laz disponibiliza uma suíte automatizada de testes unitários em `demo/test_swagger.lpr` cobrindo 100% dos fluxos de registro e resolução de schemas OpenAPI 3.1:

- **Idempotência**: `EnsureModel` não duplica registros nem lança exceções ao registrar o mesmo modelo repetidamente.
- **Validação de Existência**: `HasModel` reflete fielmente o estado do dicionário `components/schemas`.
- **Resolução de `$ref`**:
  - `ref:NomeModelo` e `#/components/schemas/NomeModelo` geram `{"$ref": "#/components/schemas/NomeModelo"}`.
  - `array:NomeModelo` e `ref:array:NomeModelo` geram `{"type": "array", "items": {"$ref": "#/components/schemas/NomeModelo"}}`.
  - `paginated:NomeModelo` e `ref:paginated:NomeModelo` geram envelopes canônicos com metadados e referências.
- **Métodos Semânticos da Rota**: `AddResponseRef`, `AddResponseRefArray`, `AddResponseRefPaginated` e `SetBodyContentRef`.
- **Geração JSON**: `BuildOpenAPISpecification` emite documento JSON válido e sem falhas de sintaxe.
- **Detecção de Quebra de Contrato**: Validação estrita que lança exceção em tempo de compilação/execução caso uma rota aponte para um modelo inexistente em `components/schemas`.

### Executando os testes:

```bash
cd demo
fpc -B -FE. -FUlib -Fu.. test_swagger.lpr
./test_swagger
```

---

## 📄 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para mais detalhes.
