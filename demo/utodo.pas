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
  .RegisterRoute('todo', rmGet, @GetTodos, False)
  .AddResponse(200, 'Ok')
  .SetSummary('Gel all TODOs')
  .AddTags('Todo');

SwaggerRouter
  .RegisterRoute('todo/:id', rmGet, @GetTodo, False)
  .AddResponse(200, 'Ok')
  .SetSummary('Gel todo by ID')
  .AddTags('Todo')
  .AddParam('id', 'id');

end.

