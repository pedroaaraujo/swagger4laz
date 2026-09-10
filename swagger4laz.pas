unit swagger4laz;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, httproute, HTTPDefs, RegExpr, fpjson, jsonparser, fgl, Variants, TypInfo;

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
    ssBearer,
    ssApiKey
  );

  TSecuritySchemes = set of TSecurityScheme;

  { TSwaggerComponents }
  TSwaggerComponents = class
  private
    FSecuritySchemes: TSecuritySchemes;
    FModels: TJSONObject;
    FApiKeyHeaderName: string;
  public
    property SecuritySchemes: TSecuritySchemes read FSecuritySchemes write FSecuritySchemes;
    property ApiKeyHeaderName: string read FApiKeyHeaderName write FApiKeyHeaderName;
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
  public
    Code: string;
    Description: string;
    DocContent: TDocContent;
  end;

  TDocReqParam = class
  public
    Name: string;
    Title: string;
    Description: string;
    ParamIn: TParamIn;
    ParamType: string;
    ParamDefault: Variant;
    Required: Boolean;
    EnumValues: array of string;
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
    FDescription: string;
    FOperationId: string;
    FDeprecated: Boolean;
    FTags: TStrings;
  public
    property Summary: string read FSummary;
    property Description: string read FDescription;
    property OperationId: string read FOperationId;
    property IsDeprecated: Boolean read FDeprecated;

    function SetSummary(Text: string): THTTPDocRoute;
    function SetDescription(Text: string): THTTPDocRoute;
    function SetOperationId(OpId: string): THTTPDocRoute;
    function SetDeprecated(Value: Boolean = True): THTTPDocRoute;

    property Responses: TResponseList read FResponses;
    function AddResponse(Code: Integer; ADescription: string = ''; Content: string = ''; ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponse(Code: string; ADescription: string = ''; Content: string = ''; ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function JsonResponse: TJSONObject;

    property Params: TDocReqParamList read FParams;
    function AddParam(AName: string; ATitle: string = ''; Required: Boolean = True; ParamIn: TParamIn = piQuery; ParamType: string = 'string'; ParamDefault: string = ''; ADescription: string = ''): THTTPDocRoute;
    function AddEnumParam(AName: string; const AValues: array of string; Required: Boolean = False; ParamIn: TParamIn = piQuery; DefaultValue: string = ''; ADescription: string = ''): THTTPDocRoute;
    function AddPathParam(AName: string; Required: Boolean = True; ParamType: string = 'string'; DefaultValue: string = ''; ADescription: string = ''): THTTPDocRoute;
    function AddQueryParam(AName: string; Required: Boolean = False; ParamType: string = 'string'; DefaultValue: string = ''; ADescription: string = ''): THTTPDocRoute;
    function AddHeaderParam(AName: string; Required: Boolean = False; ParamType: string = 'string'; DefaultValue: string = ''; ADescription: string = ''): THTTPDocRoute;
    function JsonParams: TJSONArray;

    property BodyContent: TDocContent read FBodyContent;
    function SetBodyContent(Content: string; Required: Boolean = True; ContentType: string = 'application/json'; ADescription: string = ''): THTTPDocRoute;
    function JsonBody: TJSONObject;

    property Security: TSecurityScheme read FSecurity;
    function SetSecurity(Scheme: TSecurityScheme): THTTPDocRoute;
    function SetSecurityBearer: THTTPDocRoute;
    function SetSecurityBasic: THTTPDocRoute;
    function SetSecurityApiKey(HeaderName: string = 'X-API-Key'): THTTPDocRoute;
    function SetSecurityNone: THTTPDocRoute;

    property Tags: TStrings read FTags;
    function AddTags(ADescription: string): THTTPDocRoute;
    function JsonTags: TJSONArray;

    procedure Initialize;
    destructor Destroy; override;
  end;

  { THTTPRouterHelper }

  THTTPRouterHelper = class helper for httproute.THTTPRouter
  public
    function RegisterDocRoute(const APattern: String; AMethod: TRouteMethod; ACallBack: TRouteCallBack; IsDefault: Boolean = False): THTTPDocRoute;
  end;

  { TSwaggerRouter }

  TSwaggerRouter = class
  private
    FComponents: TSwaggerComponents;
    FTitle: string;
    FVersion: string;
    FDescription: string;
    FDefaultContentType: string;
    FDefaultCustomHeaders: TStringList;
    FServers: TJSONArray;
    FContactObj: TJSONObject;
    FLicenseObj: TJSONObject;
    FDocCache: string;
    procedure HTTPRouterAfterRequest(Sender: TObject; ARequest: TRequest; AResponse: TResponse);
    procedure HTTPRouterBeforeRequest(Sender: TObject; ARequest: TRequest; AResponse: TResponse);
  public
    property Title: string read FTitle;
    property Version: string read FVersion;
    property Description: string read FDescription;
    property DefaultContentType: string read FDefaultContentType;
    property Components: TSwaggerComponents read FComponents;

    class function Initialize: TSwaggerRouter;

    function RegisterRoute(const APattern: String; AMethod: TRouteMethod; ACallBack: TRouteCallBack; IsDefault: Boolean = False): THTTPDocRoute;
    function Get(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Post(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Put(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Delete(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;

    { Model & Enum Registration }
    function RegisterModel(AName: string; AModel: TJSONData): TSwaggerRouter; overload;
    function RegisterModel(AName: string; AModel: string): TSwaggerRouter; overload;
    function RegisterEnumModel(AName: string; TypeInfoData: PTypeInfo): TSwaggerRouter; overload;
    function RegisterEnumModel(AName: string; const AValues: array of string): TSwaggerRouter; overload;

    { Configuration }
    function SetDocRoute(Endpoint: string = '/docs'): TSwaggerRouter;
    function SetTitle(ATitle: string): TSwaggerRouter;
    function SetVersion(AVersion: string): TSwaggerRouter;
    function SetDescription(Text: string): TSwaggerRouter;
    function SetContact(const Name, Url, Email: string): TSwaggerRouter;
    function SetLicense(const Name, Url: string): TSwaggerRouter;
    function AddServer(const Url: string; const ADescription: string = ''): TSwaggerRouter;
    function SetDefaultContentType(Text: string): TSwaggerRouter;
    function AddCustomHeader(const AHeader, AValue: string): TSwaggerRouter;
    procedure ClearCache;

    constructor Create;
    destructor Destroy; override;
  end;

var
  SwaggerRouter: TSwaggerRouter;
  HTTPRouter: THTTPRouter;

implementation

function ReplaceUrlParameter(const Url: string): string;
var
  RegEx: TRegExpr;
begin
  RegEx := TRegExpr.Create;
  try
    RegEx.Expression := ':(\w+)';
    Result := RegEx.Replace(Url, '{$1}', True);
  finally
    RegEx.Free;
  end;
end;

procedure Documentacao(AReq: TRequest; AResp: TResponse);
var
  I: Integer;
  Json, JsonInfo, JsonPaths, JsonURI, JsonMethod, SecurityItem: TJSONObject;
  SecurityArr: TJSONArray;
  Pattern, Str, MethodStr: string;
  Route: THTTPDocRoute;
  SL: TStringList;
begin
  AResp.ContentType := 'application/json';

  if not SwaggerRouter.FDocCache.IsEmpty then
  begin
    AResp.Content := SwaggerRouter.FDocCache;
    AResp.SendContent;
    Exit;
  end;

  Json := TJSONObject.Create;
  JsonInfo := TJSONObject.Create;
  JsonPaths := TJSONObject.Create;
  SL := TStringList.Create;
  try
    Json.Add('openapi', '3.1.0');

    JsonInfo.Add('title', SwaggerRouter.Title);
    JsonInfo.Add('version', SwaggerRouter.Version);
    if not SwaggerRouter.Description.IsEmpty then
      JsonInfo.Add('description', SwaggerRouter.Description);

    if SwaggerRouter.FContactObj <> nil then
      JsonInfo.Add('contact', SwaggerRouter.FContactObj.Clone as TJSONObject);

    if SwaggerRouter.FLicenseObj <> nil then
      JsonInfo.Add('license', SwaggerRouter.FLicenseObj.Clone as TJSONObject);

    Json.Add('info', JsonInfo);

    if SwaggerRouter.FServers.Count > 0 then
      Json.Add('servers', SwaggerRouter.FServers.Clone as TJSONArray);

    for I := 0 to Pred(HTTPRouter.RouteCount) do
    begin
      if HTTPRouter.Routes[I] is THTTPDocRoute then
      begin
        Route := THTTPDocRoute(HTTPRouter.Routes[I]);
        SL.Add(Route.Tags.Text + '##' + I.ToString);
      end;
    end;

    SL.Sort;

    for I := 0 to Pred(SL.Count) do
    begin
      Str := SL.Strings[I];
      Str := Copy(Str, Pos('##', Str) + 2, Length(Str));
      Route := THTTPDocRoute(HTTPRouter.Routes[Str.ToInteger]);

      Pattern := ReplaceUrlParameter(Route.URLPattern);
      if not Pattern.StartsWith('/') then
        Pattern := '/' + Pattern;

      JsonURI := JsonPaths.Find(Pattern) as TJSONObject;
      if JsonURI = nil then
      begin
        JsonURI := TJSONObject.Create;
        JsonPaths.Add(Pattern, JsonURI);
      end;

      JsonMethod := TJSONObject.Create;
      with Route do
      begin
        JsonMethod.Add('tags', JsonTags);
        JsonMethod.Add('summary', Summary);
        if not Description.IsEmpty then
          JsonMethod.Add('description', Description);

        JsonMethod.Add('operationId', OperationId);
        JsonMethod.Add('deprecated', IsDeprecated);
        JsonMethod.Add('parameters', JsonParams);
        JsonMethod.Add('responses', JsonResponse);

        if not BodyContent.Content.IsEmpty then
          JsonMethod.Add('requestBody', JsonBody);

        case Route.Security of
          ssBasic:
            begin
              SecurityArr := TJSONArray.Create;
              SecurityItem := TJSONObject.Create;
              SecurityItem.Add('BasicAuth', TJSONArray.Create);
              SecurityArr.Add(SecurityItem);
              JsonMethod.Add('security', SecurityArr);
            end;
          ssBearer:
            begin
              SecurityArr := TJSONArray.Create;
              SecurityItem := TJSONObject.Create;
              SecurityItem.Add('BearerAuth', TJSONArray.Create);
              SecurityArr.Add(SecurityItem);
              JsonMethod.Add('security', SecurityArr);
            end;
          ssApiKey:
            begin
              SecurityArr := TJSONArray.Create;
              SecurityItem := TJSONObject.Create;
              SecurityItem.Add('ApiKeyAuth', TJSONArray.Create);
              SecurityArr.Add(SecurityItem);
              JsonMethod.Add('security', SecurityArr);
            end;
        end;
      end;

      case TRouteMethod(Route.Method) of
        rmGet: MethodStr := 'get';
        rmPost: MethodStr := 'post';
        rmPut: MethodStr := 'put';
        rmDelete: MethodStr := 'delete';
        rmOptions: MethodStr := 'options';
        rmHead: MethodStr := 'head';
        rmTrace: MethodStr := 'trace';
      else
        MethodStr := 'get';
      end;

      JsonURI.Add(MethodStr, JsonMethod);
    end;

    Json.Add('paths', JsonPaths);
    Json.Add('components', SwaggerRouter.Components.ToJson);

    SwaggerRouter.FDocCache := Json.AsJSON;
    AResp.Content := SwaggerRouter.FDocCache;
    AResp.SendContent;
  finally
    Json.Free;
    SL.Free;
  end;
end;

procedure SwaggerUI(AReq: TRequest; AResp: TResponse);
begin
  AResp.ContentType := 'text/html';
  AResp.Contents.Clear;
  AResp.Contents.Add('<!DOCTYPE html>');
  AResp.Contents.Add('<html>');
  AResp.Contents.Add('<head>');
  AResp.Contents.Add('  <meta charset="UTF-8">');
  AResp.Contents.Add('  <title>' + SwaggerRouter.Title + ' - Swagger UI</title>');
  AResp.Contents.Add('  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">');
  AResp.Contents.Add('</head>');
  AResp.Contents.Add('<body>');
  AResp.Contents.Add('  <div id="swagger-ui"></div>');
  AResp.Contents.Add('  <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>');
  AResp.Contents.Add('  <script>');
  AResp.Contents.Add('    window.onload = function() {');
  AResp.Contents.Add('      const ui = SwaggerUIBundle({');
  AResp.Contents.Add('        url: "/openapi.json",');
  AResp.Contents.Add('        dom_id: "#swagger-ui",');
  AResp.Contents.Add('        deepLinking: true,');
  AResp.Contents.Add('        docExpansion: "list",');
  AResp.Contents.Add('        filter: true,');
  AResp.Contents.Add('        presets: [');
  AResp.Contents.Add('          SwaggerUIBundle.presets.apis,');
  AResp.Contents.Add('          SwaggerUIBundle.SwaggerUIStandalonePreset');
  AResp.Contents.Add('        ]');
  AResp.Contents.Add('      });');
  AResp.Contents.Add('    };');
  AResp.Contents.Add('  </script>');
  AResp.Contents.Add('</body>');
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

{ TSwaggerComponents }

constructor TSwaggerComponents.Create;
begin
  inherited Create;
  FModels := TJSONObject.Create;
  FApiKeyHeaderName := 'X-API-Key';
end;

destructor TSwaggerComponents.Destroy;
begin
  FModels.Free;
  inherited Destroy;
end;

function TSwaggerComponents.ToJson: TJSONObject;
var
  Security, SchemeObj: TJSONObject;
begin
  Result := TJSONObject.Create;

  if SecuritySchemes <> [] then
  begin
    Security := TJSONObject.Create;
    Result.Add('securitySchemes', Security);

    if ssBasic in SecuritySchemes then
    begin
      SchemeObj := TJSONObject.Create;
      SchemeObj.Add('type', 'http');
      SchemeObj.Add('scheme', 'basic');
      Security.Add('BasicAuth', SchemeObj);
    end;

    if ssBearer in SecuritySchemes then
    begin
      SchemeObj := TJSONObject.Create;
      SchemeObj.Add('type', 'http');
      SchemeObj.Add('scheme', 'bearer');
      SchemeObj.Add('bearerFormat', 'JWT');
      Security.Add('BearerAuth', SchemeObj);
    end;

    if ssApiKey in SecuritySchemes then
    begin
      SchemeObj := TJSONObject.Create;
      SchemeObj.Add('type', 'apiKey');
      SchemeObj.Add('name', FApiKeyHeaderName);
      SchemeObj.Add('in', 'header');
      Security.Add('ApiKeyAuth', SchemeObj);
    end;
  end;

  if FModels.Count > 0 then
    Result.Add('schemas', FModels.Clone as TJSONObject);
end;

{ THTTPDocRoute }

procedure THTTPDocRoute.Initialize;
begin
  FResponses := TResponseList.Create(True);
  FParams := TDocReqParamList.Create(True);
  FTags := TStringList.Create;
  FSecurity := ssNone;
  FDeprecated := False;
end;

destructor THTTPDocRoute.Destroy;
begin
  FResponses.Free;
  FTags.Free;
  FParams.Free;
  inherited Destroy;
end;

function THTTPDocRoute.SetSummary(Text: string): THTTPDocRoute;
begin
  FSummary := Text;
  Result := Self;
end;

function THTTPDocRoute.SetDescription(Text: string): THTTPDocRoute;
begin
  FDescription := Text;
  Result := Self;
end;

function THTTPDocRoute.SetOperationId(OpId: string): THTTPDocRoute;
begin
  FOperationId := OpId;
  Result := Self;
end;

function THTTPDocRoute.SetDeprecated(Value: Boolean): THTTPDocRoute;
begin
  FDeprecated := Value;
  Result := Self;
end;

function THTTPDocRoute.AddResponse(Code: Integer; ADescription: string;
  Content: string; ContentType: string): THTTPDocRoute;
begin
  Result := AddResponse(Code.ToString, ADescription, Content, ContentType);
end;

function THTTPDocRoute.AddResponse(Code: string; ADescription: string;
  Content: string; ContentType: string): THTTPDocRoute;
var
  Response: TDocResponse;
begin
  Response := TDocResponse.Create;
  Response.Code := Code;
  Response.Description := ADescription;
  Response.DocContent.Content := Content;
  Response.DocContent.ContentType := ContentType;
  FResponses.Add(Response);
  Result := Self;
end;

function THTTPDocRoute.JsonResponse: TJSONObject;
var
  R: TDocResponse;
  Item, JsonCont, JsonSchema, RefObj: TJSONObject;
  ContentStr: string;
begin
  Result := TJSONObject.Create;
  for R in Responses do
  begin
    Item := TJSONObject.Create;
    Item.Add('description', R.Description);

    ContentStr := Trim(R.DocContent.Content);
    if not ContentStr.IsEmpty then
    begin
      JsonCont := TJSONObject.Create;
      JsonSchema := TJSONObject.Create;

      if ContentStr.StartsWith('{') or ContentStr.StartsWith('[') then
      begin
        try
          JsonSchema.Add('schema', GetJSON(ContentStr));
        except
          RefObj := TJSONObject.Create;
          RefObj.Add('$ref', '#/components/schemas/' + ContentStr);
          JsonSchema.Add('schema', RefObj);
        end;
      end
      else
      begin
        RefObj := TJSONObject.Create;
        RefObj.Add('$ref', '#/components/schemas/' + ContentStr);
        JsonSchema.Add('schema', RefObj);
      end;

      JsonCont.Add(R.DocContent.ContentType, JsonSchema);
      Item.Add('content', JsonCont);
    end;

    Result.Add(R.Code, Item);
  end;
end;

function THTTPDocRoute.AddParam(AName: string; ATitle: string;
  Required: Boolean; ParamIn: TParamIn; ParamType: string; ParamDefault: string;
  ADescription: string): THTTPDocRoute;
var
  Param: TDocReqParam;
begin
  if ATitle.IsEmpty then
    ATitle := AName;

  Param := TDocReqParam.Create;
  Param.Name := AName;
  Param.Title := ATitle;
  Param.Description := ADescription;
  Param.Required := Required;
  Param.ParamType := ParamType;
  Param.ParamIn := ParamIn;
  Param.ParamDefault := ParamDefault;

  FParams.Add(Param);
  Result := Self;
end;

function THTTPDocRoute.AddEnumParam(AName: string; const AValues: array of string;
  Required: Boolean; ParamIn: TParamIn; DefaultValue: string; ADescription: string): THTTPDocRoute;
var
  Param: TDocReqParam;
  I: Integer;
begin
  Param := TDocReqParam.Create;
  Param.Name := AName;
  Param.Title := AName;
  Param.Description := ADescription;
  Param.Required := Required;
  Param.ParamType := 'string';
  Param.ParamIn := ParamIn;
  Param.ParamDefault := DefaultValue;

  SetLength(Param.EnumValues, Length(AValues));
  for I := 0 to High(AValues) do
    Param.EnumValues[I] := AValues[I];

  FParams.Add(Param);
  Result := Self;
end;

function THTTPDocRoute.AddPathParam(AName: string; Required: Boolean;
  ParamType: string; DefaultValue: string; ADescription: string): THTTPDocRoute;
begin
  Result := AddParam(AName, AName, Required, piPath, ParamType, DefaultValue, ADescription);
end;

function THTTPDocRoute.AddQueryParam(AName: string; Required: Boolean;
  ParamType: string; DefaultValue: string; ADescription: string): THTTPDocRoute;
begin
  Result := AddParam(AName, AName, Required, piQuery, ParamType, DefaultValue, ADescription);
end;

function THTTPDocRoute.AddHeaderParam(AName: string; Required: Boolean;
  ParamType: string; DefaultValue: string; ADescription: string): THTTPDocRoute;
begin
  Result := AddParam(AName, AName, Required, piHeader, ParamType, DefaultValue, ADescription);
end;

function THTTPDocRoute.JsonParams: TJSONArray;
var
  JsonItem, JsonSchema: TJSONObject;
  EnumArr: TJSONArray;
  P: TDocReqParam;
  I: Integer;
begin
  Result := TJSONArray.Create;
  for P in Params do
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
    JsonItem.Add('required', P.Required);
    if not P.Description.IsEmpty then
      JsonItem.Add('description', P.Description);

    JsonSchema.Add('type', P.ParamType);

    if Length(P.EnumValues) > 0 then
    begin
      EnumArr := TJSONArray.Create;
      for I := 0 to High(P.EnumValues) do
        EnumArr.Add(P.EnumValues[I]);
      JsonSchema.Add('enum', EnumArr);
    end;

    if not P.Title.IsEmpty then
      JsonSchema.Add('title', P.Title);

    if not VarIsNull(P.ParamDefault) and (VarToStr(P.ParamDefault) <> '') then
      JsonSchema.Add('default', VarToStr(P.ParamDefault));

    JsonItem.Add('schema', JsonSchema);
    Result.Add(JsonItem);
  end;
end;

function THTTPDocRoute.SetBodyContent(Content: string; Required: Boolean;
  ContentType: string; ADescription: string): THTTPDocRoute;
begin
  FBodyContent.Content := Content;
  FBodyContent.ContentType := ContentType;
  FBodyContent.Required := Required;
  FBodyContent.Description := ADescription;
  Result := Self;
end;

function THTTPDocRoute.JsonBody: TJSONObject;
var
  JBody, JSchema, RefObj: TJSONObject;
  ContentStr: string;
begin
  Result := TJSONObject.Create;
  JBody := TJSONObject.Create;
  JSchema := TJSONObject.Create;

  if not FBodyContent.Description.IsEmpty then
    Result.Add('description', FBodyContent.Description);

  Result.Add('required', FBodyContent.Required);
  Result.Add('content', JBody);
  JBody.Add(FBodyContent.ContentType, JSchema);

  ContentStr := Trim(FBodyContent.Content);
  if ContentStr.StartsWith('{') or ContentStr.StartsWith('[') then
  begin
    try
      JSchema.Add('schema', GetJSON(ContentStr));
    except
      RefObj := TJSONObject.Create;
      RefObj.Add('$ref', '#/components/schemas/' + ContentStr);
      JSchema.Add('schema', RefObj);
    end;
  end
  else
  begin
    RefObj := TJSONObject.Create;
    RefObj.Add('$ref', '#/components/schemas/' + ContentStr);
    JSchema.Add('schema', RefObj);
  end;
end;

function THTTPDocRoute.SetSecurity(Scheme: TSecurityScheme): THTTPDocRoute;
begin
  FSecurity := Scheme;
  if not (Scheme in SwaggerRouter.Components.SecuritySchemes) then
    SwaggerRouter.Components.SecuritySchemes := SwaggerRouter.Components.SecuritySchemes + [Scheme];
  Result := Self;
end;

function THTTPDocRoute.SetSecurityBearer: THTTPDocRoute;
begin
  Result := SetSecurity(ssBearer);
end;

function THTTPDocRoute.SetSecurityBasic: THTTPDocRoute;
begin
  Result := SetSecurity(ssBasic);
end;

function THTTPDocRoute.SetSecurityApiKey(HeaderName: string): THTTPDocRoute;
begin
  SwaggerRouter.Components.ApiKeyHeaderName := HeaderName;
  Result := SetSecurity(ssApiKey);
end;

function THTTPDocRoute.SetSecurityNone: THTTPDocRoute;
begin
  Result := SetSecurity(ssNone);
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

{ TSwaggerRouter }

constructor TSwaggerRouter.Create;
begin
  inherited Create;
  FDefaultCustomHeaders := TStringList.Create;
  FComponents := TSwaggerComponents.Create;
  FServers := TJSONArray.Create;
  FDocCache := '';
end;

destructor TSwaggerRouter.Destroy;
begin
  FComponents.Free;
  FDefaultCustomHeaders.Free;
  FServers.Free;
  if FContactObj <> nil then FContactObj.Free;
  if FLicenseObj <> nil then FLicenseObj.Free;
  inherited Destroy;
end;

procedure TSwaggerRouter.ClearCache;
begin
  FDocCache := '';
end;

procedure TSwaggerRouter.HTTPRouterAfterRequest(Sender: TObject;
  ARequest: TRequest; AResponse: TResponse);
begin
end;

procedure TSwaggerRouter.HTTPRouterBeforeRequest(Sender: TObject;
  ARequest: TRequest; AResponse: TResponse);
var
  I: Integer;
begin
  AResponse.ContentType := SwaggerRouter.DefaultContentType;

  for I := 0 to Pred(SwaggerRouter.FDefaultCustomHeaders.Count) do
    AResponse.CustomHeaders.Add(SwaggerRouter.FDefaultCustomHeaders.Strings[I]);
end;

class function TSwaggerRouter.Initialize: TSwaggerRouter;
begin
  if SwaggerRouter = nil then
    SwaggerRouter := TSwaggerRouter.Create;

  Result := SwaggerRouter;
  Result.SetDefaultContentType('application/json');
  HTTPRouter.BeforeRequest := @Result.HTTPRouterBeforeRequest;
  HTTPRouter.AfterRequest := @Result.HTTPRouterAfterRequest;
end;

function TSwaggerRouter.RegisterRoute(const APattern: String;
  AMethod: TRouteMethod; ACallBack: TRouteCallBack; IsDefault: Boolean
  ): THTTPDocRoute;
begin
  ClearCache;
  Result := HTTPRouter.RegisterDocRoute(APattern, AMethod, ACallBack, IsDefault);
end;

function TSwaggerRouter.Get(const APattern: string; ACallBack: TRouteCallBack
  ): THTTPDocRoute;
begin
  Result := RegisterRoute(APattern, rmGet, ACallBack);
end;

function TSwaggerRouter.Post(const APattern: string; ACallBack: TRouteCallBack
  ): THTTPDocRoute;
begin
  Result := RegisterRoute(APattern, rmPost, ACallBack);
end;

function TSwaggerRouter.Put(const APattern: string; ACallBack: TRouteCallBack
  ): THTTPDocRoute;
begin
  Result := RegisterRoute(APattern, rmPut, ACallBack);
end;

function TSwaggerRouter.Delete(const APattern: string; ACallBack: TRouteCallBack
  ): THTTPDocRoute;
begin
  Result := RegisterRoute(APattern, rmDelete, ACallBack);
end;

function TSwaggerRouter.RegisterModel(AName: string; AModel: TJSONData
  ): TSwaggerRouter;
begin
  ClearCache;
  FComponents.Models.Add(AName, AModel);
  Result := Self;
end;

function TSwaggerRouter.RegisterModel(AName: string; AModel: string
  ): TSwaggerRouter;
begin
  Result := RegisterModel(AName, GetJSON(AModel, False));
end;

function TSwaggerRouter.RegisterEnumModel(AName: string; TypeInfoData: PTypeInfo): TSwaggerRouter;
var
  TypeData: PTypeData;
  I: Integer;
  EnumArr: TJSONArray;
  SchemaObj: TJSONObject;
begin
  if TypeInfoData^.Kind <> tkEnumeration then
    raise Exception.CreateFmt('O tipo "%s" não é um Enum Pascal válido.', [TypeInfoData^.Name]);

  TypeData := GetTypeData(TypeInfoData);
  EnumArr := TJSONArray.Create;

  for I := TypeData^.MinValue to TypeData^.MaxValue do
    EnumArr.Add(GetEnumName(TypeInfoData, I));

  SchemaObj := TJSONObject.Create;
  SchemaObj.Add('type', 'string');
  SchemaObj.Add('enum', EnumArr);

  Result := RegisterModel(AName, SchemaObj);
end;

function TSwaggerRouter.RegisterEnumModel(AName: string; const AValues: array of string): TSwaggerRouter;
var
  EnumArr: TJSONArray;
  SchemaObj: TJSONObject;
  I: Integer;
begin
  EnumArr := TJSONArray.Create;
  for I := 0 to High(AValues) do
    EnumArr.Add(AValues[I]);

  SchemaObj := TJSONObject.Create;
  SchemaObj.Add('type', 'string');
  SchemaObj.Add('enum', EnumArr);

  Result := RegisterModel(AName, SchemaObj);
end;

function TSwaggerRouter.SetDocRoute(Endpoint: string): TSwaggerRouter;
begin
  if Endpoint.IsEmpty then
    Endpoint := '/docs';

  HTTPRouter.RegisterRoute(Endpoint, httproute.TRouteMethod(rmGet), @SwaggerUI);
  HTTPRouter.RegisterRoute('/openapi.json', httproute.TRouteMethod(rmGet), @Documentacao);
  Result := Self;
end;

function TSwaggerRouter.SetTitle(ATitle: string): TSwaggerRouter;
begin
  FTitle := ATitle;
  Result := Self;
end;

function TSwaggerRouter.SetVersion(AVersion: string): TSwaggerRouter;
begin
  FVersion := AVersion;
  Result := Self;
end;

function TSwaggerRouter.SetDescription(Text: string): TSwaggerRouter;
begin
  FDescription := Text;
  Result := Self;
end;

function TSwaggerRouter.SetContact(const Name, Url, Email: string): TSwaggerRouter;
begin
  if FContactObj = nil then FContactObj := TJSONObject.Create;
  FContactObj.Clear;
  if not Name.IsEmpty then FContactObj.Add('name', Name);
  if not Url.IsEmpty then FContactObj.Add('url', Url);
  if not Email.IsEmpty then FContactObj.Add('email', Email);
  Result := Self;
end;

function TSwaggerRouter.SetLicense(const Name, Url: string): TSwaggerRouter;
begin
  if FLicenseObj = nil then FLicenseObj := TJSONObject.Create;
  FLicenseObj.Clear;
  FLicenseObj.Add('name', Name);
  if not Url.IsEmpty then FLicenseObj.Add('url', Url);
  Result := Self;
end;

function TSwaggerRouter.AddServer(const Url: string; const ADescription: string
  ): TSwaggerRouter;
var
  ServerObj: TJSONObject;
begin
  ServerObj := TJSONObject.Create;
  ServerObj.Add('url', Url);
  if not ADescription.IsEmpty then
    ServerObj.Add('description', ADescription);
  FServers.Add(ServerObj);
  Result := Self;
end;

function TSwaggerRouter.SetDefaultContentType(Text: string): TSwaggerRouter;
begin
  FDefaultContentType := Text;
  Result := Self;
end;

function TSwaggerRouter.AddCustomHeader(const AHeader, AValue: string
  ): TSwaggerRouter;
begin
  FDefaultCustomHeaders.Values[AHeader] := AValue;
  Result := Self;
end;

initialization
  HTTPRouter := httproute.HTTPRouter;
  TSwaggerRouter.Initialize;

finalization
  SwaggerRouter.Free;

end.
