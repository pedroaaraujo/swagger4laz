# Swagger4Laz

[![Lazarus](https://img.shields.io/badge/Lazarus-2.2%2B-blue.svg)](https://www.lazarus-ide.org/)
[![FreePascal](https://img.shields.io/badge/FPC-3.2.2%2B-green.svg)](https://www.freepascal.org/)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.0.3-brightgreen.svg)](https://swagger.io/specification/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Swagger4Laz** é uma biblioteca moderna e fluente para **Lazarus / Free Pascal (FPC)** desenvolvida para integrar-se perfeitamente com o **FCL-Web** (`httproute.THTTPRouter`). Ela automatiza a geração da especificação **OpenAPI 3.0** (`openapi.json`) e serve diretamente a interface visual do **Swagger UI**, eliminando a necessidade de servidores auxiliares (como Node.js) ou ferramentas externas.

---

## ✨ Recursos

- 📄 **OpenAPI 3.0 Automático**: Gera dinamicamente o arquivo `openapi.json` a partir das rotas cadastradas.
- 🎨 **Swagger UI Embutido**: Serve a interface web interativa do Swagger UI em rota configurável (padrão `/docs`).
- 🔗 **Roteamento Fluente**: Extensão de `THTTPRouter` com métodos encadeados (`Get`, `Post`, `Put`, `Delete`).
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

### 6. Integração com Modelos (DeltaModel / JSON Schemas)

Você pode registrar schemas de modelos diretamente ou vincular schemas gerados por bibliotecas como o **DeltaModel**:

```pascal
// Usando schema gerado por classe do DeltaModel
SwaggerRouter
  .Post('/products', @CreateProduct)
  .AddTags('Produtos')
  .SetBodyContent(TProductModel.SwaggerSchema(), True)
  .AddResponse(201, 'Produto cadastrado', TProductModel.SwaggerSchema());
```

---

## 🛠️ Referência da API

### `TSwaggerRouter`

| Método | Descrição |
| :--- | :--- |
| `Get(APattern, ACallBack)` | Registra rota para o verbo HTTP GET |
| `Post(APattern, ACallBack)` | Registra rota para o verbo HTTP POST |
| `Put(APattern, ACallBack)` | Registra rota para o verbo HTTP PUT |
| `Delete(APattern, ACallBack)` | Registra rota para o verbo HTTP DELETE |
| `SetDocRoute(Endpoint)` | Define a URI do Swagger UI (padrão: `/docs`) |
| `SetTitle(ATitle)` | Define o título da documentação |
| `SetVersion(AVersion)` | Define a versão da API |
| `SetDescription(Text)` | Define a descrição geral da API |
| `AddServer(Url, Description)` | Adiciona uma URL de servidor na especificação OpenAPI |
| `SetBasePath(APath)` | Define o caminho base da API (suporta prefixos de proxy) |
| `AddCustomHeader(Header, Value)` | Adiciona cabeçalho global às respostas |
| `RegisterModel(Name, Schema)` | Registra um schema em `components/schemas` |
| `RegisterEnumModel(Name, Values)` | Registra uma enumeração em `components/schemas` |

### `THTTPDocRoute`

| Método | Descrição |
| :--- | :--- |
| `SetSummary(Text)` | Define o resumo curto do endpoint |
| `SetDescription(Text)` | Define a descrição detalhada |
| `AddTags(Name)` | Adiciona tag para agrupamento visual no Swagger UI |
| `AddPathParam(Name, Required, Type, Default, Desc)` | Documenta parâmetro presente na URL (`:param`) |
| `AddQueryParam(Name, Required, Type, Default, Desc)` | Documenta parâmetro de query string (`?param=valor`) |
| `AddHeaderParam(Name, Required, Type, Default, Desc)` | Documenta cabeçalho HTTP esperado |
| `AddEnumParam(Name, Values, Required, ParamIn, ...)` | Documenta parâmetro aceitando valores pré-definidos |
| `SetBodyContent(Schema, Required, ContentType, Desc)` | Define o corpo da requisição (Payload JSON) |
| `AddResponse(Code, Description, Schema, ContentType)` | Documenta uma resposta HTTP retornada pelo endpoint |
| `SetSecurityBearer` | Exige token Bearer (JWT) para esta rota |
| `SetSecurityBasic` | Exige autenticação HTTP Basic para esta rota |
| `SetSecurityApiKey(HeaderName)` | Exige API Key no cabeçalho especificado |
| `SetDeprecated(Value)` | Marca o endpoint como obsoleto no Swagger UI |

---

## 📄 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para mais detalhes.
