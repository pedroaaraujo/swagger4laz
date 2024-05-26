unit swagger4laz;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, httproute, HTTPDefs, RegExpr, fpjson, jsonparser, fgl, Variants;

type

  TRouteMethod = (rmUnknown,rmAll,rmGet,rmPost,rmPut,rmDelete,rmOptions,rmHead, rmTrace);
  TParamIn = (piQuery, piHeader);

  TDocContent = record
    ContentType: string;
    Content: string;
  end;

  TDocResponse = class
    Code: Integer;
    Description: string;
    DocContent: TDocContent;
  end;

  TDocReqParam = class
    Name: string;
    Title: string;
    ParamIn: TParamIn;
    ParamType: string;
    ParamDefault: Variant;
    Required: Boolean;
  end;

  TResponseList = specialize TFPGObjectList<TDocResponse>;
  TDocReqParamList = specialize TFPGObjectList<TDocReqParam>;

  { THTTPDocRoute }

  THTTPDocRoute = class(httproute.THTTPRouteCallback)
  private
    FBodyContent: TDocContent;
    FParams: TDocReqParamList;
    FResponses: TResponseList;
    FSummary: string;
    FTags: Tstrings;

  public
    property Summary: string read FSummary;
    function SetSummary(Text: string): THTTPDocRoute;

    property Responses: TResponseList read FResponses;
    function AddResponse(Code: Integer; ADescription: string; Content: string = ''; ContentType: string = 'application/json'): THTTPDocRoute;
    function JsonResponse: TJSONObject;

    property Params: TDocReqParamList read FParams;
    function AddParam(AName: string; ATitle: string = ''; Required: Boolean = True; ParamIn: TParamIn = piQuery; ParamType: string = 'string'; ParamDefault: string = ''): THTTPDocRoute;
    function JsonParams: TJSONArray;

    property BodyContent: TDocContent read FBodyContent;
    function SetBodyContent(Content: string; ContentType: string = 'application/json'): THTTPDocRoute;
    function JsonBody: TJSONObject;

    property Tags: TStrings read FTags;
    function AddTags(ADescription: string): THTTPDocRoute;
    function JsonTags: TJSONArray;

    procedure Initialize;
    destructor Destroy; override;
  end;

  { THTTPRouterHelper }

  THTTPRouterHelper = class helper for httproute.THTTPRouter
  public
    function RegisterDocRoute(Const APattern : String; AMethod : TRouteMethod; ACallBack: TRouteCallBack; IsDefault : Boolean = False): THTTPDocRoute;
  end;

  { TSwaggerRouter }

  TSwaggerRouter = class
  private
    FTitle: string;
    FVersion: string;
    FDescription: string;
  public
    property Title: string read FTitle;
    property Version: string read FVersion;
    property Description: string read FDescription;

    class function Initialize: TSwaggerRouter;

    function RegisterRoute(Const APattern : String; AMethod : TRouteMethod; ACallBack: TRouteCallBack; IsDefault : Boolean = False): THTTPDocRoute;
    function SetDocRoute(Endpoint: string): TSwaggerRouter;
    function SetTitle(ATitle: string): TSwaggerRouter;
    function SetVersion(AVersion: string): TSwaggerRouter;
    function SetDescription(Text: string): TSwaggerRouter;
  end;

  var
    SwaggerRouter: TSwaggerRouter;
    HTTPRouter: THTTPRouter;

implementation

function ReplaceUrlParameter(const Url: string): string;
var
  RegEx: TRegExpr;
  NewUrl: string;
begin
  RegEx := TRegExpr.Create;
  try
    RegEx.Expression := ':(\w+)/';
    NewUrl := Url;

    NewUrl := RegEx.Replace(NewUrl, '{$1}/', True);
    Result := NewUrl;
  finally
    RegEx.Free;
  end;
end;

procedure Documentacao(AReq: TRequest; AResp: TResponse);
var
  I: Integer;
  Json, JsonInfo, JsonPaths, JsonURI, JsonMethod: TJSONObject;
  Pattern: string;
  Route: THTTPDocRoute;
  Method: string;
begin
  Json := TJSONObject.Create();
  JsonInfo := TJSONObject.Create();
  JsonPaths := TJSONObject.Create();
  try
    Json.Add('openapi', '3.1.0');

    JsonInfo.Add('title', SwaggerRouter.Title);
    JsonInfo.Add('version', SwaggerRouter.Version);
    JsonInfo.Add('description', SwaggerRouter.Description);

    Json.Add('info', JsonInfo);

    for I := 0 to Pred(HTTPRouter.RouteCount) do
    begin
      if not (HTTPRouter.Routes[I] is THTTPDocRoute) then
      begin
        Continue;
      end;

      Route := HTTPRouter.Routes[I] as THTTPDocRoute;
      Pattern := '/' + ReplaceUrlParameter(Route.URLPattern);
      JsonURI := JsonPaths.Find(Pattern) as TJSONObject;
      if JsonURI = nil then
      begin
        JsonURI := TJSONObject.Create();
        JsonPaths.Add(Pattern, JsonURI);
      end;

      JsonMethod := TJSONObject.Create();
      with Route do
      begin
        JsonMethod.Add('tags', JsonTags);
        JsonMethod.Add('summary', Summary);
        JsonMethod.Add('operationId', '');
        JsonMethod.add('parameters', JsonParams);
        JsonMethod.add('responses', JsonResponse);
      end;

      case TRouteMethod(HTTPRouter.Routes[I].Method) of
        rmUnknown: Method := 'unknown';
        rmAll:     Method := 'all';
        rmGet:     Method := 'get';
        rmPost:    Method := 'post';
        rmPut:     Method := 'put';
        rmDelete:  Method := 'delete';
        rmOptions: Method := 'options';
        rmHead:    Method := 'head';
        rmTrace:   Method := 'trace';
      else
        Method := 'get';
      end;
      JsonURI.Add(Method, JsonMethod);
    end;

    Json.Add('paths', JsonPaths);

    AResp.Content := Json.AsJSON;
    AResp.ContentType := 'application/json';
  finally
    Json.Free;
  end;
end;

procedure SwaggerUI(AReq: TRequest; AResp: TResponse);
begin
  AResp.Contents.Add('<!DOCTYPE html>');
  AResp.Contents.Add('<html lang="en">');
  AResp.Contents.Add('  <head>');
  AResp.Contents.Add('    <meta charset="utf-8" />');
  AResp.Contents.Add('    <meta name="viewport" content="width=device-width, initial-scale=1" />');
  AResp.Contents.Add('    <meta name="description" content="SwaggerUI" />');
  AResp.Contents.Add('    <title>SwaggerUI</title>');
  AResp.Contents.Add('    <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui.css" />');
  AResp.Contents.Add('  </head>');
  AResp.Contents.Add('  <body>');
  AResp.Contents.Add('  <div id="swagger-ui"></div>');
  AResp.Contents.Add('  <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-bundle.js" crossorigin></script>');
  AResp.Contents.Add('  <script src="https://unpkg.com/swagger-ui-dist@5.11.0/swagger-ui-standalone-preset.js" crossorigin></script>');
  AResp.Contents.Add('  <script>');
  AResp.Contents.Add('    window.onload = () => {');
  AResp.Contents.Add('      window.ui = SwaggerUIBundle({');
  AResp.Contents.Add('        url: ''/openapi.json'',');
  AResp.Contents.Add('        dom_id: ''#swagger-ui'',');
  AResp.Contents.Add('        presets: [');
  AResp.Contents.Add('          SwaggerUIBundle.presets.apis,');
  AResp.Contents.Add('          SwaggerUIStandalonePreset');
  AResp.Contents.Add('        ],');
  AResp.Contents.Add('        layout: "StandaloneLayout",');
  AResp.Contents.Add('      });');
  AResp.Contents.Add('    };');
  AResp.Contents.Add('  </script>');
  AResp.Contents.Add('  </body>');
  AResp.Contents.Add('</html>');
end;

{ THTTPRouterHelper }

function THTTPRouterHelper.RegisterDocRoute(const APattern: String;
  AMethod: TRouteMethod; ACallBack: TRouteCallBack; IsDefault: Boolean
  ): THTTPDocRoute;
begin
  Result := CreateHTTPRoute(THTTPDocRoute, APattern, httproute.TRouteMethod(AMethod), IsDefault) as THTTPDocRoute;
  Result.Initialize;
  THTTPRouteCallback(Result).CallBack := ACallBack;
end;

{ THTTPDocRoute }

function THTTPDocRoute.SetSummary(Text: string): THTTPDocRoute;
begin
  Result := Self;
  FSummary := Text;
end;

function THTTPDocRoute.AddResponse(Code: Integer; ADescription: string;
  Content: string; ContentType: string): THTTPDocRoute;
var
  Response: TDocResponse;
begin
  Response := TDocResponse.Create;
  FResponses.Add(Response);
  Response.Code := Code;
  Response.Description := ADescription;
  Response.DocContent.Content := Content;
  Response.DocContent.ContentType := ContentType;
  Result := Self;
end;

function THTTPDocRoute.JsonResponse: TJSONObject;
var
  R: TDocResponse;
  Item, JsonCont, JsonSchema: TJSONObject;
begin
  Result := TJSONObject.Create;
  for R in Responses do
  begin
    Item := TJSONObject.Create;
    Item.Add('description', R.Description);

    if not R.DocContent.Content.IsEmpty then
    begin
      JsonCont := TJSONObject.Create();
      JsonSchema := TJSONObject.Create();
      JsonSchema.Add('schema', R.DocContent.Content);
      JsonCont.Add(R.DocContent.ContentType, JsonSchema);
      Item.Add('content', JsonCont);
    end;

    Result.Add(R.Code.ToString, Item);
  end;
end;

function THTTPDocRoute.AddParam(AName: string; ATitle: string;
  Required: Boolean; ParamIn: TParamIn; ParamType: string; ParamDefault: string
  ): THTTPDocRoute;
var
  Param: TDocReqParam;
begin
  if ATitle.IsEmpty then
    ATitle := AName;

  Param := TDocReqParam.Create;
  Param.Name := AName;
  Param.Title := ATitle;
  Param.Required := Required;
  Param.ParamType := ParamType;
  Param.ParamIn := ParamIn;
  ParamDefault := ParamDefault;

  FParams.Add(Param);
  Result := Self;
end;

function THTTPDocRoute.JsonParams: TJSONArray;
var
  JsonItem, JsonSchema: TJSONObject;
  P: TDocReqParam;
begin
  Result := TJSONArray.Create;
  for P in Self.Params do
  begin
    JsonItem := TJSONObject.Create;
    JsonSchema := TJSONObject.Create;

    case P.ParamIn of
      piHeader: JsonItem.Add('in', 'header');
      piQuery: JsonItem.Add('in', 'query');
    end;
    JsonItem.Add('name', P.Name);
    Jsonitem.Add('required', P.Required);

    JsonSchema.Add('type', P.ParamType);
    JsonSchema.Add('title', P.Title);
    JsonSchema.Add('default', VarToStr(P.ParamDefault));

    JsonItem.Add('schema', JsonSchema);
    Result.Add(JsonItem);
  end;
end;

function THTTPDocRoute.SetBodyContent(Content: string; ContentType: string
  ): THTTPDocRoute;
begin
  Result := Self;
  FBodyContent.Content := Content;
  FBodyContent.ContentType := ContentType;
end;

function THTTPDocRoute.JsonBody: TJSONObject;
begin
  Result := TJSONObject.Create();

end;

function THTTPDocRoute.AddTags(ADescription: string): THTTPDocRoute;
begin
  FTags.Add(ADescription);
  Result := Self;
end;

function THTTPDocRoute.JsonTags: TJSONArray;
var
  S: string;
begin
  Result := TJSONArray.Create;
  for S in Tags do
  begin
    if not S.IsEmpty then
      Result.Add(S);
  end;
end;

procedure THTTPDocRoute.Initialize;
begin
  FResponses := TResponseList.Create;
  FTags := TStringList.Create;
  FParams := TDocReqParamList.Create;
end;

destructor THTTPDocRoute.Destroy;
begin
  FResponses.Free;
  FTags.Free;
  FParams.Free;

  inherited;
end;

{ TSwaggerRouter }

class function TSwaggerRouter.Initialize: TSwaggerRouter;
begin
  SwaggerRouter := TSwaggerRouter.Create;
  Result := SwaggerRouter;
end;

function TSwaggerRouter.RegisterRoute(const APattern: String;
  AMethod: TRouteMethod; ACallBack: TRouteCallBack; IsDefault: Boolean
  ): THTTPDocRoute;
begin
  Result := HTTPRouter.RegisterDocRoute(APattern, AMethod, ACallBack, IsDefault);
end;

function TSwaggerRouter.SetDocRoute(Endpoint: string): TSwaggerRouter;
begin
  Result := Self;
  HTTPRouter.RegisterRoute(Endpoint, httproute.TRouteMethod(rmGet), @SwaggerUI);
  HTTPRouter.RegisterRoute('/openapi.json', httproute.TRouteMethod(rmGet), @Documentacao);
end;

function TSwaggerRouter.SetTitle(ATitle: string): TSwaggerRouter;
begin
  FTitle := ATitle;
  Result := SwaggerRouter;
end;

function TSwaggerRouter.SetVersion(AVersion: string): TSwaggerRouter;
begin
  FVersion := AVersion;
  Result := SwaggerRouter;
end;

function TSwaggerRouter.SetDescription(Text: string): TSwaggerRouter;
begin
  Result := Self;
  FDescription := Text;
end;

initialization
  TSwaggerRouter.Initialize;
  HTTPRouter := httproute.HTTPRouter;

finalization
  SwaggerRouter.Free;

end.

