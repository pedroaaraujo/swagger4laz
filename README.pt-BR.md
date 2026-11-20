<p align="right">
  [ English ](README.md) | [ Português (Brasil) ](README.pt-BR.md) | [ Español ](README.es-ES.md)
</p>

# Swagger4Laz

[![FPC](https://img.shields.io/badge/FPC-%3E%3D%203.2.2-blue.svg)](https://www.freepascal.org/)
[![Lazarus](https://img.shields.io/badge/Lazarus-%3E%3D%203.0-orange.svg)](https://www.lazarus-ide.org/)
[![OpenAPI](https://img.shields.io/badge/OpenAPI-3.1-brightgreen.svg)](https://swagger.io/specification/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Swagger4Laz é uma biblioteca de documentação OpenAPI 3.1 e roteador com Swagger UI embutido para Free Pascal e Lazarus. Ela estende o `httproute.THTTPRouter` nativo do FPC para declarar rotas tipadas, esquemas de dados, parâmetros de requisição, envelopes de resposta, negociação multi-formato (JSON, CBOR, BSON, XML, CSV) e erros no padrão RFC 7807 via API fluente em Pascal.

---

## Especificações Técnicas

- **Compilador**: Free Pascal Compiler (FPC) >= 3.2.2.
- **IDE / Ferramental**: Lazarus >= 3.0 (`lazbuild`).
- **Sistemas Operacionais**: Linux (x86_64, aarch64), Windows (x86_64, i386), macOS (x86_64, arm64).
- **Padrões Suportados**: OpenAPI 3.1.0 e RFC 7807 (Problem Details for HTTP APIs).
- **Media Types Suportados**: `application/json`, `application/cbor`, `application/bson`, `application/xml`, `text/xml`, `text/csv`, `application/x-www-form-urlencoded`, `multipart/form-data`.
- **Dependências Internas**: `httproute`, `fpjson`, `jsonparser`, `fgl`, `TypInfo`. Sem dependência de bibliotecas C externas.

---

## Instalação

### Método 1: Gerenciador de Pacotes do Lazarus
1. No Lazarus, acesse `Pacote` -> `Abrir Arquivo de Pacote (.lpk)`.
2. Abra `swagger4laz.lpk`.
3. Clique em `Compilar` e em seguida `Usar` -> `Instalar`.

### Método 2: Caminho de Units Manual
Adicione o diretório `swagger4laz.pas` ao caminho de units do seu compilador:
```bash
fpc -Fu/caminho/para/swagger4laz minha_api.lpr
```

---

## Quickstart (60 Segundos)

API HTTP funcional com documentação interativa e Swagger UI integrado:

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
  AResp.Content := '{"id":' + AReq.RouteParams['id'] + ',"name":"Carlos Silva"}';
end;

begin
  // Metadados do OpenAPI
  SwaggerRouter
    .SetTitle('API de Usuários')
    .SetVersion('1.0.0')
    .SetDescription('Serviço de gerenciamento de contas')
    .SetDocRoute('/docs'); // Disponibiliza o Swagger UI em /docs e o JSON em /docs/openapi.json

  // Registro de esquema em components.schemas
  SwaggerRouter.EnsureModel(
    'User',
    '{"type":"object","properties":{"id":{"type":"integer"},"name":{"type":"string"}}}'
  );

  // Registro e documentação do endpoint
  SwaggerRouter
    .Get('/api/v1/users/:id', @HandleGetUser)
    .SetSummary('Buscar usuário por ID')
    .Tag('Users')
    .PathParam('id', 'integer', 'Identificador numérico do usuário')
    .Produces(200, 'User', 'Usuário localizado')
    .ProducesProblem(404);

  // Inicialização do servidor na porta 8080
  Application.Port := 8080;
  Application.Threaded := True;
  Application.Initialize;
  Application.Run;
end.
```

Acesse `http://localhost:8080/docs` no navegador para interagir com a interface.

---

## API de Roteamento

### Registro de Rotas
O `SwaggerRouter` implementa os métodos padrão correspondentes ao `httproute`:

```pascal
SwaggerRouter.Get('/items', @HandleListItems);
SwaggerRouter.Post('/items', @HandleCreateItem);
SwaggerRouter.Put('/items/:id', @HandleUpdateItem);
SwaggerRouter.Delete('/items/:id', @HandleDeleteItem);
SwaggerRouter.Patch('/items/:id', @HandlePatchItem);
```

### Grupos de Rotas (`TSwaggerRouteGroup`)
Grupos compartilham prefixo de URL, tags, esquemas de autenticação e códigos de erro entre rotas:

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

  // Herda prefixo '/api/v1/clientes', tag 'Clientes', Bearer auth e respostas de erro 400/401/404
  Api.Get('', @HandleListarClientes)
     .ProducesPaginated(200, 'Cliente', 'Lista paginada de clientes');

  Api.Get('/:id', @HandleBuscarCliente)
     .PathParam('id', 'integer', 'ID do cliente')
     .Produces(200, 'Cliente', 'Dados do cliente');

  Api.Post('', @HandleCriarCliente)
     .ConsumesJson('ClienteInput', True, 'Payload de cadastro')
     .Produces(201, 'Cliente', 'Cliente criado');

  Api.Delete('/:id', @HandleExcluirCliente)
     .PathParam('id', 'integer', 'ID do cliente')
     .ProducesEmpty(204, 'Cliente removido');
end;
```

---

## Parâmetros de Requisição

Declare parâmetros com tipos estritos e escopos (`Path`, `Query`, `Header`, `Enum`):

```pascal
SwaggerRouter.Get('/api/v1/busca/:categoria', @HandleBusca)
  // Parâmetro de rota (obrigatório)
  .PathParam('categoria', 'string', 'Filtro de categoria')

  // Parâmetro de query com valor padrão
  .QueryParam('q', 'string', '', 'Texto de busca')
  .QueryParam('page', 'integer', '1', 'Número da página')
  .QueryParam('page_size', 'integer', '20', 'Quantidade por página')

  // Cabeçalho HTTP
  .HeaderParam('X-Trace-Id', 'string', False, 'Identificador de rastreamento')

  // Parâmetro com valores fixos permitidos (Enum)
  .EnumParam('status', ['ATIVO', 'INATIVO', 'PENDENTE'], 'Filtro por status');
```

---

## Corpo da Requisição (Payload Multi-Formato)

Declare formatos de entrada esperados para JSON, formatos binários (CBOR, BSON), XML e formulários:

```pascal
// Payload JSON padrão referenciando components.schemas/ProdutoInput
Route.ConsumesJson('ProdutoInput', True, 'Dados do produto em JSON');

// Payload binário CBOR (RFC 8949)
Route.SetBodyContentRef('ProdutoInput', True, 'application/cbor', 'Payload binário CBOR');

// Payload binário BSON (v1.1)
Route.SetBodyContentRef('ProdutoInput', True, 'application/bson', 'Documento binário BSON');

// Payload XML corporativo
Route.SetBodyContentRef('ProdutoInput', True, 'application/xml', 'Documento XML');

// Dados codificados em formulário padrão (application/x-www-form-urlencoded)
Route.ConsumesFormData('Formulário de login');

// Upload multipart para arquivos (multipart/form-data)
Route.ConsumesMultipart('Upload de arquivos e anexos');
```

---

## Definição de Respostas & Negociação Multi-Formato

O Swagger4Laz permite mapear múltiplas representações sob o mesmo código de status HTTP, viabilizando documentação OpenAPI 3.1 precisa para endpoints com negociação de conteúdo via cabeçalho `Accept`:

```pascal
// Referência a objeto único em JSON (padrão)
Route.Produces(200, 'Produto', 'Operação realizada com sucesso');

// Definições de respostas multi-formato:
Route
  .AddResponseRef(200, 'Produto', 'Resposta padrão em JSON', 'application/json')
  .AddResponseRef(200, 'Produto', 'Payload binário CBOR de alta taxa', 'application/cbor')
  .AddResponseRef(200, 'Produto', 'Documento binário BSON', 'application/bson')
  .AddResponseRef(200, 'Produto', 'Documento XML enterprise', 'application/xml')
  .AddResponseRefArray(200, 'Produto', 'Exportação tabular em CSV', 'text/csv');

// Lista simples: { type: "array", items: { $ref: #/components/schemas/Produto } }
Route.ProducesArray(200, 'Produto', 'Lista de produtos');

// Envelope paginado: { type: "object", properties: { items: [...], total_records: ... } }
Route.ProducesPaginated(200, 'Produto', 'Resposta paginada');

// Resposta sem conteúdo (HTTP 204)
Route.ProducesEmpty(204, 'Registro excluído');
```

### Panorama de Tradeoffs dos Media Types

| Media Type | Payload vs JSON | Contexto Ideal | Características Principais |
| :--- | :--- | :--- | :--- |
| `application/json` | Linha de base (100%) | Web SPAs, clientes JavaScript | Compatibilidade universal, legível por humanos |
| `application/cbor` | ~40-60% menor | Mobile (Flutter), IoT, microsserviços | Binário compacto, floats IEEE 754, parsing Zero-DOM |
| `application/bson` | Comparável | Bancos documentais, workers analíticos | Prefixo de tamanho de 32 bits, tipos ricos, UTC ms |
| `text/csv` | Compacto para tabelas | Exportações em lote, analytics | Registros tabulares RFC 4180, pronto para planilhas |
| `application/xml` | ~20-40% maior | Enterprise legado, compliance fiscal | Validação estrita W3C, escape canônico de entidades |

---

## Erros no Padrão RFC 7807

O esquema `ProblemDetails` é registrado automaticamente em `components.schemas`:

```pascal
// Resposta de erro individual com Content-Type: application/problem+json
Route.ProducesProblem(400); // Bad Request
Route.ProducesProblem(404); // Not Found

// Declaração de múltiplos erros
Route.ProducesProblem([400, 403, 404, 409]);

// Declaração do conjunto padrão de erros (400, 401, 403, 404, 409, 422, 500)
Route.ProducesStandardProblems;
```

---

## Esquemas de Autenticação

Configure a autenticação em nível de rota, grupo ou global:

```pascal
// Bearer JWT (Authorization: Bearer <token>)
Route.SecurityBearer;

// HTTP Basic (Authorization: Basic <credenciais>)
Route.SecurityBasic;

// Chave no cabeçalho HTTP (padrão: X-API-Key)
Route.SecurityApiKey('X-Tenant-Key');

// Rota pública dentro de um grupo protegido
Route.SecurityNone;
```

---

## Registro de Modelos

Os esquemas podem ser adicionados ao dicionário `components.schemas` programaticamente:

```pascal
// Registrar esquema JSON bruto
SwaggerRouter.RegisterModel(
  'Pedido',
  '{"type":"object","properties":{"id":{"type":"integer"},"total":{"type":"number"}}}'
);

// Registro idempotente (não duplica caso já exista)
SwaggerRouter.EnsureModel('Pedido', JsonSchemaString);

// Registro de Enum
SwaggerRouter.RegisterEnumModel('StatusPedido', ['RASCUNHO', 'CONFIRMADO', 'ENVIADO', 'CANCELADO']);
```

---

## Publicação de Endpoints

```pascal
// Registra automaticamente Swagger UI em /docs e especificação em /docs/openapi.json
SwaggerRouter.SetDocRoute('/docs');

// Ou registro manual das procedures:
HTTPRouter.RegisterRoute('/api/openapi.json', rmGet, @Documentation);
HTTPRouter.RegisterRoute('/api/docs', rmGet, @SwaggerUI);
```

---

## Licença

Distribuído sob a licença MIT. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
