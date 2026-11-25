program test_swagger;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cwstring, { UTF-8 <-> UnicodeString nas leituras do fpjson }
  {$ENDIF}
  Classes, SysUtils, fpjson, jsonparser, HTTPDefs, httproute,
  swagger4laz;

var
  GPassCount, GFailCount: Integer;

procedure AssertTrue(ACond: Boolean; const AMsg: string);
begin
  if ACond then
  begin
    Inc(GPassCount);
    WriteLn('  [PASS] ' + AMsg);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn('  [FAIL] ' + AMsg);
  end;
end;

procedure AssertEquals(const AExpected, AActual, AMsg: string);
begin
  if AExpected = AActual then
  begin
    Inc(GPassCount);
    WriteLn('  [PASS] ' + AMsg);
  end
  else
  begin
    Inc(GFailCount);
    WriteLn(Format('  [FAIL] %s - Esperado: "%s", Obtido: "%s"', [AMsg, AExpected, AActual]));
  end;
end;

procedure DummyHandler(AReq: TRequest; AResp: TResponse);
begin
end;

procedure RunTests;
var
  JsonDoc: string;
  Doc, Components, Schemas, Paths: TJSONObject;
  TodoSchema: TJSONObject;
  ProblemResponses: TJSONObject;
begin
  WriteLn('===================================================================');
  WriteLn('          Swagger4Laz - Suíte de Testes Automatizados              ');
  WriteLn('===================================================================');

  // 1. Router Configuration
  SwaggerRouter
    .SetTitle('Test API')
    .SetVersion('1.0.0')
    .SetDescription('API para testes de schemas e $ref');

  // 2. HasModel and EnsureModel Test
  AssertTrue(not SwaggerRouter.HasModel('TodoItem'), 'HasModel retorna False para modelo não cadastrado');

  SwaggerRouter.EnsureModel('TodoItem', '{"type": "object", "properties": {"id": {"type": "integer"}, "title": {"type": "string"}}}');
  AssertTrue(SwaggerRouter.HasModel('TodoItem'), 'HasModel retorna True após EnsureModel');

  // EnsureModel Idempotency
  SwaggerRouter.EnsureModel('TodoItem', '{"type": "object", "properties": {"id": {"type": "integer"}}}');
  AssertTrue(SwaggerRouter.HasModel('TodoItem'), 'EnsureModel é idempotente e não falha');

  // 3. Route Registration with Ref methods and Multiple Media Types
  SwaggerRouter
    .Get('/todos/:id', @DummyHandler)
    .SetSummary('Buscar Todo')
    .AddTags('Todos')
    .AddPathParam('id', True, 'integer', '1', 'ID do item')
    .Produces(200, 'TodoItem', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON, MEDIA_TYPE_XML, MEDIA_TYPE_CSV], 'Todo localizado em múltiplos formatos')
    .AcceptsGzip
    .ProducesGzip;

  SwaggerRouter
    .Get('/todos', @DummyHandler)
    .SetSummary('Listar Todos')
    .AddTags('Todos')
    .AddResponseRefArray(200, 'TodoItem', 'Lista de todos')
    .Produces([MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON]);

  SwaggerRouter
    .Get('/todos/paginados', @DummyHandler)
    .SetSummary('Listar Todos Paginados')
    .AddTags('Todos')
    .ProducesPaginated(200, 'TodoItem', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR], 'Todos paginados');

  SwaggerRouter
    .Post('/todos', @DummyHandler)
    .SetSummary('Criar Todo')
    .AddTags('Todos')
    .Consumes('TodoItem', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON], True, 'Dados de criação')
    .Produces(201, 'TodoItem', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR], 'Criado com sucesso');

  // TSwaggerRouteGroup Test with Fluent Defaults
  SwaggerRouter
    .Group('/api/v2')
    .Tag('V2')
    .ProducesMediaTypes([MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR])
    .EnableGzip
    .Get('/items', @DummyHandler)
    .Produces(200, 'TodoItem', 'Items v2');

  // ProducesProblem with route-specific description (new code and update of an existing one)
  SwaggerRouter
    .Get('/problemas', @DummyHandler)
    .SetSummary('Problemas com descrição')
    .ProducesProblem(404)
    .ProducesProblem(403, 'Sem acesso ao módulo')
    .ProducesProblem(404, 'Item não encontrado')
    .ProducesProblem(409, '');

  // 4. Verify generated OpenAPI JSON
  JsonDoc := SwaggerRouter.BuildOpenAPISpecification;
  AssertTrue(Length(JsonDoc) > 0, 'BuildOpenAPISpecification gerou JSON');

  Doc := TJSONObject(GetJSON(JsonDoc));
  try
    AssertEquals('3.1.0', Doc.Get('openapi', ''), 'Versão OpenAPI é 3.1.0');

    Components := Doc.Get('components', TJSONObject(nil));
    AssertTrue(Assigned(Components), 'OpenAPI possui components');
    if Assigned(Components) then
    begin
      Schemas := Components.Get('schemas', TJSONObject(nil));
      AssertTrue(Assigned(Schemas), 'Components possui schemas');
      if Assigned(Schemas) then
      begin
        TodoSchema := Schemas.Get('TodoItem', TJSONObject(nil));
        AssertTrue(Assigned(TodoSchema), 'Schemas possui modelo TodoItem registrado');
      end;
    end;

    Paths := Doc.Get('paths', TJSONObject(nil));
    AssertTrue(Assigned(Paths), 'OpenAPI possui paths documentados');
    AssertTrue(Pos('#/components/schemas/TodoItem', JsonDoc) > 0, 'OpenAPI contém referências canônicas $ref');

    // Multiple Media Types and Encodings Validations
    AssertTrue(Pos('application/json', JsonDoc) > 0, 'OpenAPI contém application/json');
    AssertTrue(Pos('application/cbor', JsonDoc) > 0, 'OpenAPI contém application/cbor');
    AssertTrue(Pos('application/bson', JsonDoc) > 0, 'OpenAPI contém application/bson');
    AssertTrue(Pos('application/xml', JsonDoc) > 0, 'OpenAPI contém application/xml');
    AssertTrue(Pos('text/csv', JsonDoc) > 0, 'OpenAPI contém text/csv');
    AssertTrue(Pos('Accept-Encoding', JsonDoc) > 0, 'OpenAPI contém parâmetro de cabeçalho Accept-Encoding');
    AssertTrue(Pos('Content-Encoding', JsonDoc) > 0, 'OpenAPI contém cabeçalho de resposta Content-Encoding');
    AssertTrue(Pos('gzip', JsonDoc) > 0, 'OpenAPI contém encoding gzip');
    AssertTrue(Pos('/api/v2/items', JsonDoc) > 0, 'OpenAPI contém rota de grupo /api/v2/items');

    ProblemResponses := TJSONObject(Doc.FindPath('paths./problemas.get.responses'));
    AssertTrue(Assigned(ProblemResponses), 'Rota /problemas possui responses');
    if Assigned(ProblemResponses) then
    begin
      AssertEquals('Sem acesso ao módulo', ProblemResponses.Objects['403'].Get('description', ''),
        'ProducesProblem(código, descrição) usa a descrição informada');
      AssertEquals('Item não encontrado', ProblemResponses.Objects['404'].Get('description', ''),
        'ProducesProblem(código, descrição) atualiza código já registrado');
      AssertEquals('Conflict', ProblemResponses.Objects['409'].Get('description', ''),
        'ProducesProblem(código, '''') usa a descrição padrão');
      AssertTrue(Pos('application/problem+json', ProblemResponses.Objects['403'].AsJSON) > 0,
        'ProducesProblem(código, descrição) usa application/problem+json');
      AssertTrue(Pos('#/components/schemas/ProblemDetails', ProblemResponses.Objects['403'].AsJSON) > 0,
        'ProducesProblem(código, descrição) referencia ProblemDetails');
    end;
  finally
    Doc.Free;
  end;

  WriteLn('');
  WriteLn('===================================================================');
  WriteLn(Format('RESULTADO: Total: %d | Passaram: %d | Falharam: %d',
    [GPassCount + GFailCount, GPassCount, GFailCount]));
  WriteLn('===================================================================');

  if GFailCount > 0 then
    Halt(1)
  else
    Halt(0);
end;

begin
  GPassCount := 0;
  GFailCount := 0;
  try
    RunTests;
  except
    on E: Exception do
    begin
      WriteLn('[EXCEPTION FATAL]: ' + E.Message);
      Halt(2);
    end;
  end;
end.
