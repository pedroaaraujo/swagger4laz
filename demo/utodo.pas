unit UTodo;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, swagger4laz, HTTPDefs;

implementation

procedure GetTodos(AReq: TRequest; AResp: TResponse);
begin

end;

procedure GetTodo(AReq: TRequest; AResp: TResponse);
begin

end;

procedure CreateTodo(AReq: TRequest; AResp: TResponse);
begin

end;

initialization

SwaggerRouter
  .EnsureModel('Todo', '{"type": "object", "properties": {"id": {"type": "integer"}, "title": {"type": "string"}, "completed": {"type": "boolean"}}}');

// GET route with multiple serialization formats and GZIP compression
SwaggerRouter
  .RegisterRoute('todo', rmGet, @GetTodos, False)
  .SetSummary('Get all TODOs in multiple formats')
  .AddTags('Todo')
  .Produces(200, 'Todo', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON, MEDIA_TYPE_XML, MEDIA_TYPE_CSV], 'List of todos')
  .AcceptsGzip
  .ProducesGzip;

// GET route by ID
SwaggerRouter
  .RegisterRoute('todo/:id', rmGet, @GetTodo, False)
  .SetSummary('Get todo by ID')
  .AddTags('Todo')
  .AddPathParam('id', True, 'integer', '1', 'ID do Todo')
  .Produces(200, 'Todo', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR], 'Todo localizado');

// POST route with multi-format payload
SwaggerRouter
  .RegisterRoute('todo', rmPost, @CreateTodo, False)
  .SetSummary('Create a new TODO item')
  .AddTags('Todo')
  .Consumes('Todo', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR, MEDIA_TYPE_BSON], True, 'Todo payload')
  .Produces(201, 'Todo', [MEDIA_TYPE_JSON, MEDIA_TYPE_CBOR], 'Todo created');

end.

