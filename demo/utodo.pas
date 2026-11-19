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

initialization

SwaggerRouter
  .EnsureModel('Todo', '{"type": "object", "properties": {"id": {"type": "integer"}, "title": {"type": "string"}, "completed": {"type": "boolean"}}}');

SwaggerRouter
  .RegisterRoute('todo', rmGet, @GetTodos, False)
  .AddResponseRefArray(200, 'Ok', 'Todo')
  .SetSummary('Get all TODOs')
  .AddTags('Todo');

SwaggerRouter
  .RegisterRoute('todo/:id', rmGet, @GetTodo, False)
  .AddResponseRef(200, 'Ok', 'Todo')
  .SetSummary('Get todo by ID')
  .AddTags('Todo')
  .AddParam('id', 'id');

end.

