program test_swagger;

{$mode objfpc}{$H+}

uses
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
begin
  WriteLn('===================================================================');
  WriteLn('          Swagger4Laz - Suíte de Testes Automatizados              ');
  WriteLn('===================================================================');

  // 1. Configuração do Router
  SwaggerRouter
    .SetTitle('Test API')
    .SetVersion('1.0.0')
    .SetDescription('API para testes de schemas e $ref');

  // 2. Teste de HasModel e EnsureModel
  AssertTrue(not SwaggerRouter.HasModel('TodoItem'), 'HasModel retorna False para modelo não cadastrado');

  SwaggerRouter.EnsureModel('TodoItem', '{"type": "object", "properties": {"id": {"type": "integer"}, "title": {"type": "string"}}}');
  AssertTrue(SwaggerRouter.HasModel('TodoItem'), 'HasModel retorna True após EnsureModel');

  // Idempotência de EnsureModel
  SwaggerRouter.EnsureModel('TodoItem', '{"type": "object", "properties": {"id": {"type": "integer"}}}');
  AssertTrue(SwaggerRouter.HasModel('TodoItem'), 'EnsureModel é idempotente e não falha');

  // 3. Registro de Rotas com métodos Ref
  SwaggerRouter
    .Get('/todos/:id', @DummyHandler)
    .SetSummary('Buscar Todo')
    .AddTags('Todos')
    .AddPathParam('id', True, 'integer', '1', 'ID do item')
    .AddResponseRef(200, 'TodoItem', 'Todo localizado');

  SwaggerRouter
    .Get('/todos', @DummyHandler)
    .SetSummary('Listar Todos')
    .AddTags('Todos')
    .AddResponseRefArray(200, 'TodoItem', 'Lista de todos');

  SwaggerRouter
    .Get('/todos/paginados', @DummyHandler)
    .SetSummary('Listar Todos Paginados')
    .AddTags('Todos')
    .AddResponseRefPaginated(200, 'TodoItem', 'Todos paginados');

  SwaggerRouter
    .Post('/todos', @DummyHandler)
    .SetSummary('Criar Todo')
    .AddTags('Todos')
    .SetBodyContentRef('TodoItem', True, 'application/json', 'Dados de criação')
    .AddResponseRef(201, 'TodoItem', 'Criado com sucesso');

  // 4. Verificação do OpenAPI JSON gerado
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
