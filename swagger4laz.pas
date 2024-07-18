unit swagger4laz;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, httproute, HTTPDefs, RegExpr, fpjson, jsonparser, fgl, Variants;

type

  TRouteMethod = (
    rmUnknown,
    rmAll,
    rmGet,
    rmPost,
    rmPut,
    rmDelete,
    rmOptions,
    rmHead,
    rmTrace
  );

  TParamIn = (
    piQuery,
    piHeader,
    piPath,
    piCookie
  );

  TSecurityScheme = (
    ssNone,
    ssBasic,
    ssBearer
  );

  TSecuritySchemes = set of TSecurityScheme;

  { TSwaggerComponents }
  TSwaggerComponents = class
  private
    FSecuritySchemes: TSecuritySchemes;
    FModels: TJSONObject;
  public
    property SecuritySchemes: TSecuritySchemes read FSecuritySchemes write FSecuritySchemes;
    property Models: TJSONObject read FModels;

    constructor Create;
    destructor Destroy; override;

    function ToJson: TJSONObject;
  end;

  TDocContent = record
    ContentType: string;
    Content: string;
    Required: Boolean;
    Description: string;
  end;

  TDocResponse = class
    Code: string;
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
    FSecurity: TSecurityScheme;
    FSummary: string;
    FTags: Tstrings;

  public
    property Summary: string read FSummary;
    function SetSummary(Text: string): THTTPDocRoute;

    property Responses: TResponseList read FResponses;
    function AddResponse(Code: Integer; ADescription: string = ''; Content: string = ''; ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponse(Code: string; ADescription: string = ''; Content: string = ''; ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function JsonResponse: TJSONObject;

    property Params: TDocReqParamList read FParams;
    function AddParam(AName: string; ATitle: string = ''; Required: Boolean = True; ParamIn: TParamIn = piQuery; ParamType: string = 'string'; ParamDefault: string = ''): THTTPDocRoute;
    function AddPathParam(AName: string; Required: Boolean = True): THTTPDocRoute;
    function AddQueryParam(AName: string; Required: Boolean = True): THTTPDocRoute;
    function AddHeaderParam(AName: string; Required: Boolean = True): THTTPDocRoute;
    function JsonParams: TJSONArray;

    property BodyContent: TDocContent read FBodyContent;
    function SetBodyContent(Content: string; Required: Boolean = True; ContentType: string = 'application/json'): THTTPDocRoute;
    function JsonBody: TJSONObject;

    property Security: TSecurityScheme read FSecurity;
    function SetSecurity(Scheme: TSecurityScheme): THTTPDocRoute;

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
    FComponents: TSwaggerComponents;
    FTitle: string;
    FVersion: string;
    FDescription: string;
    FDefaultContentType: string;
    procedure HTTPRouterAfterRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse);
    procedure HTTPRouterBeforeRequest(Sender: TObject; ARequest: TRequest;
      AResponse: TResponse);
  public
    property Title: string read FTitle;
    property Version: string read FVersion;
    property Description: string read FDescription;
    property DefaultContentType: string read FDefaultContentType;
    property Components: TSwaggerComponents read FComponents;

    class function Initialize: TSwaggerRouter;

    function RegisterRoute(Const APattern : String; AMethod : TRouteMethod; ACallBack: TRouteCallBack; IsDefault : Boolean = False): THTTPDocRoute;
    function RegisterModel(AName: string; AModel: TJSONData): TSwaggerRouter;
      overload;
    function RegisterModel(AName: string; AModel: string): TSwaggerRouter; overload;
    function SetDocRoute(Endpoint: string): TSwaggerRouter;
    function SetTitle(ATitle: string): TSwaggerRouter;
    function SetVersion(AVersion: string): TSwaggerRouter;
    function SetDescription(Text: string): TSwaggerRouter;
    function SetDefaultContentType(Text: string): TSwaggerRouter;

    constructor Create;
    destructor Destroy; override;
  end;

  var
    SwaggerRouter: TSwaggerRouter;
    HTTPRouter: THTTPRouter;

implementation

var
  Buffer: String;

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
  SL: TStringList;
  Str: string;
begin
  AResp.ContentType := 'application/json';
  if not Buffer.IsEmpty then
  begin
    AResp.Content := Buffer;
    AResp.SendContent;
    Exit;
  end;

  Json := TJSONObject.Create();
  JsonInfo := TJSONObject.Create();
  JsonPaths := TJSONObject.Create();
  SL := TStringList.Create;
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
      SL.Add(Route.Tags.DelimitedText + '##' + I.ToString);
    end;

    SL.Sort;
    for I := 0 to Pred(SL.Count) do
    begin
      Str := SL.Strings[I];
      Str := Copy(Str, Pos('##', Str) + 2, Str.Length);
      Route := HTTPRouter.Routes[Str.ToInteger] as THTTPDocRoute;
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
        if not BodyContent.Content.IsEmpty then
        begin
          JsonMethod.Add('requestBody', JsonBody);
        end;

        case Route.Security of
          ssBasic: JsonMethod.Add('security', GetJSON('[{"BasicAuth": []}]'));
          ssBearer: JsonMethod.Add('security',GetJSON('[{"BearerAuth": []}]'));
        end;
      end;

      case TRouteMethod(Route.Method) of
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
    Json.Add('components', SwaggerRouter.Components.ToJson);

    AResp.Contents.Text := Json.AsJSON;
    Buffer := AResp.Contents.Text;
  finally
    Json.Free;
    SL.Free;
  end;
end;

procedure SwaggerUI(AReq: TRequest; AResp: TResponse);
begin
  AResp.Contents.Add('<!DOCTYPE html>');
  AResp.Contents.Add('<html>');
  AResp.Contents.Add('<head>');
  AResp.Contents.Add('  <link type="text/css" rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">');
  AResp.Contents.Add('  <title>Swagger UI</title>');
  AResp.Contents.Add('</head>');
  AResp.Contents.Add('<body>');
  AResp.Contents.Add('  <div id="swagger-ui">');
  AResp.Contents.Add('  </div>');
  AResp.Contents.Add('  <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>');
  AResp.Contents.Add('  <!-- `SwaggerUIBundle` is now available on the page -->');
  AResp.Contents.Add('  <script>');
  AResp.Contents.Add('  const ui = SwaggerUIBundle({');
  AResp.Contents.Add('      url: ''/openapi.json'',');
  AResp.Contents.Add('  "dom_id": "#swagger-ui",');
  AResp.Contents.Add('"layout": "BaseLayout",');
  AResp.Contents.Add('"deepLinking": true,');
  AResp.Contents.Add('"displayRequestDuration": true,');
  AResp.Contents.Add('"docExpansion": "none",');
  AResp.Contents.Add('"showExtensions": true,');
  AResp.Contents.Add('"showCommonExtensions": true,');
  AResp.Contents.Add('oauth2RedirectUrl: window.location.origin + ''/docs/oauth2-redirect'',');
  AResp.Contents.Add('    presets: [');
  AResp.Contents.Add('        SwaggerUIBundle.presets.apis,');
  AResp.Contents.Add('        SwaggerUIBundle.SwaggerUIStandalonePreset');
  AResp.Contents.Add('        ],');
  AResp.Contents.Add('    })');
  AResp.Contents.Add('  </script>');
  AResp.Contents.Add('</body>');
  AResp.Contents.Add('</html>');
  AResp.ContentType :=  'text/html'
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

{ TSwaggerComponents }

constructor TSwaggerComponents.Create;
begin
  inherited Create;
  FModels := TJSONObject.Create;
end;

destructor TSwaggerComponents.Destroy;
begin
  FModels.Free;
  inherited Destroy;
end;

function TSwaggerComponents.ToJson: TJSONObject;
var
  Security: TJSONObject;
begin
  Result := TJSONObject.Create;
  if SecuritySchemes <> [] then
  begin
    Security := TJSONObject.Create;
    Result.Add('securitySchemes', Security);
    if ssBasic in SecuritySchemes then
    begin
      Security.Add(
        'BasicAuth',
        GetJson(
          '{ ' +
          '  "type": "http", ' +
          '  "scheme": "basic" ' +
          '}'
        )
      );
    end;

    if ssBearer in SecuritySchemes then
    begin
      Security.Add(
        'BearerAuth',
        GetJson(
          '{ ' +
          '"type": "http", ' +
          '"scheme": "bearer", ' +
          '"bearerFormat": "JWT" ' +
          '}'
        )
      );
    end;
  end;

  if FModels.Count > 0 then
  begin
    Result.Add('schemas', FModels);
  end;
end;

{ THTTPDocRoute }

function THTTPDocRoute.SetSummary(Text: string): THTTPDocRoute;
begin
  Result := Self;
  FSummary := Text;
end;

function THTTPDocRoute.AddResponse(Code: Integer; ADescription: string;
  Content: string; ContentType: string): THTTPDocRoute;
begin
  Result := Self.AddResponse(
    Code.ToString,
    ADescription,
    Content,
    ContentType
  );
end;

function THTTPDocRoute.AddResponse(Code: string; ADescription: string;
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
  Schema: TJSONData;
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
      try
        Schema := GetJson(R.DocContent.Content);
        JsonSchema.Add('schema', Schema);
      except
        on E: Exception do
        begin
          JsonSchema.Add('schema', GetJson('{"$ref": "#/components/schemas/' + R.DocContent.Content + '"}'));
        end;
      end;
      JsonCont.Add(R.DocContent.ContentType, JsonSchema);
      Item.Add('content', JsonCont);
    end;

    Result.Add(R.Code, Item);
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

function THTTPDocRoute.AddPathParam(AName: string; Required: Boolean
  ): THTTPDocRoute;
begin
  Result := Self.AddParam(
    AName,
    AName,
    Required,
    piPath
  );
end;

function THTTPDocRoute.AddQueryParam(AName: string; Required: Boolean
  ): THTTPDocRoute;
begin
  Result := Self.AddParam(
    AName,
    AName,
    Required,
    piQuery
  );
end;

function THTTPDocRoute.AddHeaderParam(AName: string; Required: Boolean
  ): THTTPDocRoute;
begin
  Result := Self.AddParam(
    AName,
    AName,
    Required,
    piHeader
  );
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
      piPath: JsonItem.Add('in', 'path');
      piCookie: JsonItem.Add('in', 'cookie');
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

function THTTPDocRoute.SetBodyContent(Content: string; Required: Boolean;
  ContentType: string): THTTPDocRoute;
begin
  Result := Self;
  FBodyContent.Content := Content;
  FBodyContent.ContentType := ContentType;
  FBodyContent.Required := Required;
end;

function THTTPDocRoute.JsonBody: TJSONObject;
var
  JBody, JSchema: TJSONObject;
begin
  Result := TJSONObject.Create();
  JBody := TJSONObject.Create();
  JSchema := TJSONObject.Create();
  Result.Add('description', FBodyContent.Description);
  Result.Add('required', FBodyContent.Required);
  Result.Add('content', JBody);
  JBody.Add(FBodyContent.ContentType, JSchema);
  JSchema.Add('schema', GetJSON(FBodyContent.Content));
end;

function THTTPDocRoute.SetSecurity(Scheme: TSecurityScheme): THTTPDocRoute;
begin
  Result := Self;
  FSecurity := Scheme;

  if not (Scheme in SwaggerRouter.Components.SecuritySchemes) then
  begin
    SwaggerRouter.Components.SecuritySchemes :=
      SwaggerRouter.Components.SecuritySchemes +
      [Scheme]
  end;
end;

function TSwaggerRouter.RegisterModel(AName: string; AModel: TJSONData
  ): TSwaggerRouter;
begin
  Result := Self;
  FComponents.Models.Add(AName, AModel);
end;

function TSwaggerRouter.RegisterModel(AName: string; AModel: string
  ): TSwaggerRouter;
var
  Json: TJSONData;
begin
  Json := GetJSON(AModel, False);
  Result := Self.RegisterModel(AName, Json);
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
  FSecurity := ssNone;
end;

destructor THTTPDocRoute.Destroy;
begin
  FResponses.Free;
  FTags.Free;
  FParams.Free;

  inherited;
end;

{ TSwaggerRouter }

procedure TSwaggerRouter.HTTPRouterBeforeRequest(Sender: TObject;
  ARequest: TRequest; AResponse: TResponse);
begin
  AResponse.ContentType := SwaggerRouter.DefaultContentType;
end;

procedure TSwaggerRouter.HTTPRouterAfterRequest(Sender: TObject;
  ARequest: TRequest; AResponse: TResponse);
begin

end;

class function TSwaggerRouter.Initialize: TSwaggerRouter;
begin
  if SwaggerRouter = nil then
    SwaggerRouter := TSwaggerRouter.Create;

  Result := SwaggerRouter;

  Result.SetDefaultContentType('application/json');
  HTTPRouter.BeforeRequest := @HTTPRouterBeforeRequest;
  HTTPRouter.AfterRequest := @HTTPRouterAfterRequest;
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

function TSwaggerRouter.SetDefaultContentType(Text: string): TSwaggerRouter;
begin
  FDefaultContentType := Text;
  Result := Self;
end;

constructor TSwaggerRouter.Create;
begin
  FComponents := TSwaggerComponents.Create;
end;

destructor TSwaggerRouter.Destroy;
begin
  FComponents.Free;
  inherited Destroy;
end;

initialization
  HTTPRouter := httproute.HTTPRouter;
  TSwaggerRouter.Initialize;
  Buffer := EmptyStr;

finalization
  SwaggerRouter.Free;

end.
