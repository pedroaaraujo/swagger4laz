program project1;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, cmem,
  {$ENDIF}
  Classes,
  fphttpapp,
  swagger4laz, UTodo;

begin
  Application.Threaded:=False;
  Application.Port:=8080;
  Application.Title:='Swagger4Laz Demo';

  SwaggerRouter
    .SetDocRoute('/docs')
    .SetTitle(Application.Title)
    .SetDescription('A Swagger4Laz exemple - made by paaraujo')
    .SetVersion('1.0.0');

  Application.Initialize;
  Application.Run;
end.

