unit swagger4laz;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, syncobjs, httproute, HTTPDefs, RegExpr, fpjson, jsonparser, fgl, Variants, TypInfo;

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
    rmTrace,
    rmPatch
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
    FDocMethod: TRouteMethod;
    FBodyContent: TDocContent;
    FParams: TDocReqParamList;
    FResponses: TResponseList;
    FSecurity: TSecurityScheme;
    FSummary: string;
    FDescription: string;
    FOperationId: string;
    FDeprecated: Boolean;
    FTags: TStrings;
    procedure InvalidateCache;
  protected
    procedure DoHandleRequest(ARequest: TRequest; AResponse: TResponse); override;
  public
    property DocMethod: TRouteMethod read FDocMethod write FDocMethod;
    property Summary: string read FSummary;
    property Description: string read FDescription;
    property OperationId: string read FOperationId;
    property IsDeprecated: Boolean read FDeprecated;

    function SetSummary(Text: string): THTTPDocRoute;
    function SetDescription(Text: string): THTTPDocRoute;
    function SetOperationId(AId: string): THTTPDocRoute;
    function SetDeprecated(Value: Boolean = True): THTTPDocRoute;

    property Responses: TResponseList read FResponses;
    function AddResponse(Code: Integer; ADescription: string = ''; Content: string = ''; ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponse(Code: string; ADescription: string = ''; Content: string = ''; ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponseRef(Code: Integer; const AModelName: string; const ADescription: string = ''; const ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponseRef(Code: string; const AModelName: string; const ADescription: string = ''; const ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponseRefArray(Code: Integer; const AModelName: string; const ADescription: string = ''; const ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponseRefArray(Code: string; const AModelName: string; const ADescription: string = ''; const ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponseRefPaginated(Code: Integer; const AModelName: string; const ADescription: string = ''; const ContentType: string = 'application/json'): THTTPDocRoute; overload;
    function AddResponseRefPaginated(Code: string; const AModelName: string; const ADescription: string = ''; const ContentType: string = 'application/json'): THTTPDocRoute; overload;
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
    function SetBodyContentRef(const AModelName: string; Required: Boolean = True; const ContentType: string = 'application/json'; const ADescription: string = ''): THTTPDocRoute;
    function JsonBody: TJSONObject;

    property Security: TSecurityScheme read FSecurity;
    function SetSecurity(Scheme: TSecurityScheme): THTTPDocRoute;
    function SetSecurityBearer: THTTPDocRoute;
    function SetSecurityBasic: THTTPDocRoute;
    function SetSecurityApiKey(HeaderName: string = 'X-API-Key'): THTTPDocRoute;
    function SetSecurityNone: THTTPDocRoute;

    property Tags: TStrings read FTags;
    function AddTags(ADescription: string): THTTPDocRoute;
    function AddTag(ADescription: string): THTTPDocRoute;
    function Tag(ADescription: string): THTTPDocRoute;
    function SetTag(ADescription: string): THTTPDocRoute;
    function SetTags(const ATags: array of string): THTTPDocRoute;
    function JsonTags: TJSONArray;

    procedure Initialize;
    destructor Destroy; override;
  end;

  { THTTPRouterHelper }

  THTTPRouterHelper = class helper for httproute.THTTPRouter
  public
    function RegisterDocRoute(const APattern: String; AMethod: TRouteMethod; ACallBack: TRouteCallBack; IsDefault: Boolean = False): THTTPDocRoute;
    function Get(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Post(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Put(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Delete(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Patch(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
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
    FBasePath: string;
    FDocRoute: string;
    FDocCache: string;
    FDocCacheBasePath: string;
    FCacheLock: TCriticalSection;
    procedure HTTPRouterAfterRequest(Sender: TObject; ARequest: TRequest; AResponse: TResponse);
    procedure HTTPRouterBeforeRequest(Sender: TObject; ARequest: TRequest; AResponse: TResponse);
    function ResolveBasePath(AReq: TRequest): string;
  public
    property Title: string read FTitle;
    property Version: string read FVersion;
    property Description: string read FDescription;
    property DefaultContentType: string read FDefaultContentType;
    property BasePath: string read FBasePath;
    property Components: TSwaggerComponents read FComponents;

    class function Initialize: TSwaggerRouter;

    function RegisterRoute(const APattern: String; AMethod: TRouteMethod; ACallBack: TRouteCallBack; IsDefault: Boolean = False): THTTPDocRoute;
    function Get(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Post(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Put(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Delete(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Patch(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;

    { Model & Enum Registration }
    function HasModel(const AName: string): Boolean;
    function EnsureModel(const AName: string; AModel: TJSONData): TSwaggerRouter; overload;
    function EnsureModel(const AName: string; const AModel: string): TSwaggerRouter; overload;
    function RegisterModel(AName: string; AModel: TJSONData): TSwaggerRouter; overload;
    function RegisterModel(AName: string; AModel: string): TSwaggerRouter; overload;
    function RegisterModel(AName: string; AModel: TJSONData; AOverwrite: Boolean): TSwaggerRouter; overload;
    function RegisterModel(AName: string; AModel: string; AOverwrite: Boolean): TSwaggerRouter; overload;
    function RegisterEnumModel(AName: string; TypeInfoData: PTypeInfo): TSwaggerRouter; overload;
    function RegisterEnumModel(AName: string; const AValues: array of string): TSwaggerRouter; overload;

    { Configuration }
    function SetDocRoute(Endpoint: string = '/docs'): TSwaggerRouter;
    function SetTitle(ATitle: string): TSwaggerRouter;
    function SetVersion(AVersion: string): TSwaggerRouter;
    function SetDescription(Text: string): TSwaggerRouter;
    function SetBasePath(const APath: string): TSwaggerRouter;
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

procedure Documentacao(AReq: TRequest; AResp: TResponse);
procedure SwaggerUI(AReq: TRequest; AResp: TResponse);

implementation

function IsSafePathPrefix(const APath: string): Boolean;
var
  I: Integer;
begin
  Result := APath.IsEmpty or APath.StartsWith('/');
  if not Result or (Pos('//', APath) > 0) or (Pos('\', APath) > 0) or
     (Pos('?', APath) > 0) or (Pos('#', APath) > 0) or
     (Pos('/../', '/' + APath + '/') > 0) or (Pos('/./', '/' + APath + '/') > 0) then
    Exit(False);
  for I := 1 to Length(APath) do
    if not (APath[I] in ['a'..'z', 'A'..'Z', '0'..'9', '/', '-', '.', '_', '~']) then
      Exit(False);
end;

function NormalizePathPrefix(const APath: string): string;
begin
  Result := Trim(APath);
  if Result.IsEmpty then
    Exit;
  if not Result.StartsWith('/') then
    Result := '/' + Result;
  if not IsSafePathPrefix(Result) then
    raise Exception.CreateFmt('Prefixo de rota inválido: %s', [APath]);
  while (Length(Result) > 1) and Result.EndsWith('/') do
    Delete(Result, Length(Result), 1);
end;

function TSwaggerRouter.ResolveBasePath(AReq: TRequest): string;
var
  ForwardedPrefix: string;
begin
  Result := FBasePath;

  if AReq <> nil then
  begin
    ForwardedPrefix := AReq.GetCustomHeader('X-Forwarded-Prefix');
    if not ForwardedPrefix.IsEmpty then
    begin
      if IsSafePathPrefix(ForwardedPrefix.Trim) then
      begin
        Result := NormalizePathPrefix(ForwardedPrefix);
        if Result = '/' then
          Result := '';
      end;
    end;
  end;
end;

function HtmlEscape(const AValue: string): string;
begin
  Result := StringReplace(AValue, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '&quot;', [rfReplaceAll]);
  Result := StringReplace(Result, '''', '&#39;', [rfReplaceAll]);
end;

function JavaScriptString(const AValue: string): string;
var
  JsonString: TJSONString;
begin
  JsonString := TJSONString.Create(AValue);
  try
    Result := JsonString.AsJSON;
  finally
    JsonString.Free;
  end;
  Result := StringReplace(Result, '<', '\u003C', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '\u003E', [rfReplaceAll]);
  Result := StringReplace(Result, '&', '\u0026', [rfReplaceAll]);
end;

function JsonSchemaFromContent(const AContent: string): TJSONData;
var
  ContentName, CleanModelName, RefName: string;
  IsArray, IsPaginated: Boolean;
  ItemRefObj, PropsObj, ArrayObj, PageProp, PageSizeProp, TotalProp, TotalPagesProp: TJSONObject;
begin
  ContentName := Trim(AContent);
  if ContentName.IsEmpty then
    Exit(TJSONObject.Create);

  if ContentName.StartsWith('{') or ContentName.StartsWith('[') then
  begin
    Result := GetJSON(ContentName);
    if Result.JSONType <> jtObject then
    begin
      Result.Free;
      raise Exception.Create('OpenAPI schema precisa ser um objeto JSON.');
    end;
    Exit;
  end;

  IsArray := False;
  IsPaginated := False;

  if ContentName.StartsWith('ref:array:', True) then
  begin
    IsArray := True;
    CleanModelName := Copy(ContentName, 11, MaxInt);
  end
  else if ContentName.StartsWith('array:', True) then
  begin
    IsArray := True;
    CleanModelName := Copy(ContentName, 7, MaxInt);
  end
  else if ContentName.StartsWith('ref:paginated:', True) then
  begin
    IsPaginated := True;
    CleanModelName := Copy(ContentName, 15, MaxInt);
  end
  else if ContentName.StartsWith('paginated:', True) then
  begin
    IsPaginated := True;
    CleanModelName := Copy(ContentName, 11, MaxInt);
  end
  else if ContentName.StartsWith('ref:', True) then
  begin
    CleanModelName := Copy(ContentName, 5, MaxInt);
  end
  else
    CleanModelName := ContentName;

  CleanModelName := Trim(CleanModelName);

  if CleanModelName.StartsWith('#/components/schemas/') then
    CleanModelName := Copy(CleanModelName, 22, MaxInt);

  // Validação no SwaggerRouter se o router estiver instanciado
  if Assigned(SwaggerRouter) and (SwaggerRouter.Components.Models.Find(CleanModelName) = nil) then
    raise Exception.CreateFmt('Schema "%s" não registrado em components/schemas.', [CleanModelName]);

  RefName := CleanModelName;
  RefName := StringReplace(RefName, '~', '~0', [rfReplaceAll]);
  RefName := StringReplace(RefName, '/', '~1', [rfReplaceAll]);

  if IsPaginated then
  begin
    Result := TJSONObject.Create;
    TJSONObject(Result).Add('type', 'object');

    PropsObj := TJSONObject.Create;

    ArrayObj := TJSONObject.Create;
    ArrayObj.Add('type', 'array');
    ItemRefObj := TJSONObject.Create;
    ItemRefObj.Add('$ref', '#/components/schemas/' + RefName);
    ArrayObj.Add('items', ItemRefObj);
    PropsObj.Add('items', ArrayObj);

    PageProp := TJSONObject.Create;
    PageProp.Add('type', 'integer');
    PageProp.Add('example', 1);
    PropsObj.Add('page', PageProp);

    PageSizeProp := TJSONObject.Create;
    PageSizeProp.Add('type', 'integer');
    PageSizeProp.Add('example', 20);
    PropsObj.Add('page_size', PageSizeProp);

    TotalProp := TJSONObject.Create;
    TotalProp.Add('type', 'integer');
    TotalProp.Add('format', 'int64');
    TotalProp.Add('example', 100);
    PropsObj.Add('total_records', TotalProp);

    TotalPagesProp := TJSONObject.Create;
    TotalPagesProp.Add('type', 'integer');
    TotalPagesProp.Add('example', 5);
    PropsObj.Add('total_pages', TotalPagesProp);

    TJSONObject(Result).Add('properties', PropsObj);
  end
  else if IsArray then
  begin
    Result := TJSONObject.Create;
    TJSONObject(Result).Add('type', 'array');
    ItemRefObj := TJSONObject.Create;
    ItemRefObj.Add('$ref', '#/components/schemas/' + RefName);
    TJSONObject(Result).Add('items', ItemRefObj);
  end
  else
  begin
    Result := TJSONObject.Create;
    TJSONObject(Result).Add('$ref', '#/components/schemas/' + RefName);
  end;
end;

function ParameterDefaultJson(const AType, AName, AValue: string): TJSONData;
var
  Parsed: string;
  TypeIndex: Integer;
begin
  Result := nil;
  if AValue = '' then
    Exit;
  TypeIndex := IndexText(AType, ['string', 'integer', 'number', 'boolean']);
  case TypeIndex of
    0: Result := TJSONString.Create(AValue);
    1, 2:
      begin
        Parsed := AValue.Trim;
        Result := GetJSON(Parsed);
        if Result.JSONType <> jtNumber then
        begin
          Result.Free;
          Result := nil;
          raise Exception.CreateFmt('Valor padrão numérico inválido para %s.', [AName]);
        end;
        if (TypeIndex = 1) and
           ((Pos('.', Parsed) > 0) or (Pos('e', LowerCase(Parsed)) > 0)) then
        begin
          Result.Free;
          Result := nil;
          raise Exception.CreateFmt('Valor padrão inteiro inválido para %s.', [AName]);
        end;
      end;
    3:
      if SameText(AValue, 'true') then
        Result := TJSONBoolean.Create(True)
      else if SameText(AValue, 'false') then
        Result := TJSONBoolean.Create(False)
      else
        raise Exception.CreateFmt('Valor padrão booleano inválido para %s.', [AName]);
  else
    raise Exception.CreateFmt('Tipo OpenAPI inválido para %s.', [AName]);
  end;
end;

procedure Documentacao(AReq: TRequest; AResp: TResponse);
var
  I, J, K, RouteIdx: Integer;
  Json, JsonInfo, JsonPaths, JsonURI, JsonMethod, SecurityItem: TJSONObject;
  SecurityArr, ServersArray: TJSONArray;
  Pattern, MethodStr, EffectiveBasePath, SortKey, ResponseBody: string;
  Route: THTTPDocRoute;
  ActualMethod: TRouteMethod;
  RegEx: TRegExpr;
  SL, OperationIds, PathParams: TStringList;
begin
  AResp.ContentType := 'application/json; charset=utf-8';
  EffectiveBasePath := SwaggerRouter.ResolveBasePath(AReq);
  SwaggerRouter.FCacheLock.Acquire;
  try
    if not SwaggerRouter.FDocCache.IsEmpty and
       (SwaggerRouter.FDocCacheBasePath = EffectiveBasePath) then
    begin
      ResponseBody := SwaggerRouter.FDocCache;
    end
    else
    begin
      Json := TJSONObject.Create;
      try
      Json.Add('openapi', '3.1.0');

      JsonInfo := TJSONObject.Create;
      Json.Add('info', JsonInfo);

      JsonInfo.Add('title', SwaggerRouter.Title);
      JsonInfo.Add('version', SwaggerRouter.Version);
      if not SwaggerRouter.Description.IsEmpty then
        JsonInfo.Add('description', SwaggerRouter.Description);

      if SwaggerRouter.FContactObj <> nil then
        JsonInfo.Add('contact', SwaggerRouter.FContactObj.Clone as TJSONObject);

      if SwaggerRouter.FLicenseObj <> nil then
        JsonInfo.Add('license', SwaggerRouter.FLicenseObj.Clone as TJSONObject);

      if SwaggerRouter.FServers.Count > 0 then
      begin
        ServersArray := SwaggerRouter.FServers.Clone as TJSONArray;
        Json.Add('servers', ServersArray);
      end
      else if not EffectiveBasePath.IsEmpty then
      begin
        ServersArray := TJSONArray.Create;
        Json.Add('servers', ServersArray);
        SecurityItem := TJSONObject.Create;
        ServersArray.Add(SecurityItem);
        SecurityItem.Add('url', EffectiveBasePath);
        SecurityItem.Add('description', 'Reverse Proxy Base Path');
      end
      else
        Json.Delete('servers');

      JsonPaths := TJSONObject.Create;
      Json.Add('paths', JsonPaths);

      RegEx := TRegExpr.Create;
      SL := TStringList.Create;
      OperationIds := TStringList.Create;
      PathParams := TStringList.Create;
      try
        RegEx.Expression := ':(\w+)';

        for I := 0 to Pred(HTTPRouter.RouteCount) do
        begin
          if HTTPRouter.Routes[I] is THTTPDocRoute then
          begin
            Route := THTTPDocRoute(HTTPRouter.Routes[I]);

            if Route.Tags.Count > 0 then
              SortKey := Route.Tags[0]
            else
              SortKey := 'zzzz_untagged';

            SortKey := SortKey + '|' + Route.URLPattern;

            SL.AddObject(SortKey, TObject(PtrInt(I)));
          end;
        end;

        SL.Sort;

        for RouteIdx := 0 to Pred(SL.Count) do
        begin
          I := PtrInt(SL.Objects[RouteIdx]);
          Route := THTTPDocRoute(HTTPRouter.Routes[I]);

          PathParams.Clear;
          if RegEx.Exec(Route.URLPattern) then
          begin
            repeat
              PathParams.Add(RegEx.Match[1]);
            until not RegEx.ExecNext;
          end;
          for J := 0 to PathParams.Count - 1 do
          begin
            K := 0;
            while (K < Route.Params.Count) and
              not ((Route.Params[K].ParamIn = piPath) and
                SameText(Route.Params[K].Name, PathParams[J])) do
              Inc(K);
            if K >= Route.Params.Count then
            begin
              // Auto-register missing path param
              Route.AddPathParam(PathParams[J], True, 'string', '', '');
            end
            else if not Route.Params[K].Required then
              Route.Params[K].Required := True;
          end;
          for J := 0 to Route.Params.Count - 1 do
            if (Route.Params[J].ParamIn = piPath) and
               (PathParams.IndexOf(Route.Params[J].Name) < 0) then
              raise Exception.CreateFmt('Parâmetro de rota "%s" não existe em %s.',
                [Route.Params[J].Name, Route.URLPattern]);

          Pattern := RegEx.Replace(Route.URLPattern, '{$1}', True);

          if not Pattern.StartsWith('/') then
            Pattern := '/' + Pattern;
          if (Length(Pattern) > 1) and Pattern.EndsWith('/') then
            Pattern := Copy(Pattern, 1, Length(Pattern) - 1);

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
            if not Summary.IsEmpty then
              JsonMethod.Add('summary', Summary)
            else if not Description.IsEmpty then
              JsonMethod.Add('summary', Description);

            if not Description.IsEmpty then
              JsonMethod.Add('description', Description)
            else if not Summary.IsEmpty then
              JsonMethod.Add('description', Summary);

            if not OperationId.IsEmpty then
            begin
              if OperationIds.IndexOf(OperationId) >= 0 then
                raise Exception.CreateFmt('operationId duplicado: %s', [OperationId]);
              OperationIds.Add(OperationId);
              JsonMethod.Add('operationId', OperationId);
            end;
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

          if Route.DocMethod <> rmUnknown then
            ActualMethod := Route.DocMethod
          else
            ActualMethod := TRouteMethod(Route.Method);

          case ActualMethod of
            rmGet: MethodStr := 'get';
            rmPost: MethodStr := 'post';
            rmPut: MethodStr := 'put';
            rmDelete: MethodStr := 'delete';
            rmPatch: MethodStr := 'patch';
            rmOptions: MethodStr := 'options';
            rmHead: MethodStr := 'head';
            rmTrace: MethodStr := 'trace';
          else
            raise Exception.CreateFmt('Método HTTP não documentável em %s.',
              [Route.URLPattern]);
          end;

          if JsonURI.Find(MethodStr) = nil then
            JsonURI.Add(MethodStr, JsonMethod)
          else
          begin
            JsonMethod.Free;
            raise Exception.CreateFmt('Rota duplicada para %s %s.', [MethodStr, Pattern]);
          end;
        end;
      finally
        PathParams.Free;
        OperationIds.Free;
        SL.Free;
        RegEx.Free;
      end;

      Json.Add('components', SwaggerRouter.Components.ToJson);

      SwaggerRouter.FDocCache := Json.AsJSON;
      SwaggerRouter.FDocCacheBasePath := EffectiveBasePath;
      ResponseBody := SwaggerRouter.FDocCache;
      finally
        Json.Free;
      end;
    end;
  finally
    SwaggerRouter.FCacheLock.Release;
  end;
  AResp.Content := ResponseBody;
  AResp.SendContent;
end;

procedure SwaggerUI(AReq: TRequest; AResp: TResponse);
var
  BasePath, JsonUrl: string;
begin
  BasePath := SwaggerRouter.ResolveBasePath(AReq);
  if SwaggerRouter.FDocRoute = '/' then
    JsonUrl := BasePath + '/openapi.json'
  else
    JsonUrl := BasePath + SwaggerRouter.FDocRoute + '/openapi.json';

  AResp.ContentType := 'text/html';
  AResp.Contents.Clear;
  AResp.Contents.Add('<!DOCTYPE html>');
  AResp.Contents.Add('<html>');
  AResp.Contents.Add('<head>');
  AResp.Contents.Add('  <meta charset="UTF-8">');
  AResp.Contents.Add('  <title>' + HtmlEscape(SwaggerRouter.Title) + ' - Swagger UI</title>');
  AResp.Contents.Add('  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">');
  AResp.Contents.Add('</head>');
  AResp.Contents.Add('<body>');
  AResp.Contents.Add('  <div id="swagger-ui"></div>');
  AResp.Contents.Add('  <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>');
  AResp.Contents.Add('  <script>');
  AResp.Contents.Add('    window.onload = function() {');
  AResp.Contents.Add('      const ui = SwaggerUIBundle({');
  AResp.Contents.Add('        url: ' + JavaScriptString(JsonUrl) + ',');
  AResp.Contents.Add('        dom_id: "#swagger-ui",');
  AResp.Contents.Add('        deepLinking: true,');
  AResp.Contents.Add('        docExpansion: "none",');
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
var
  FPCMethod: httproute.TRouteMethod;
begin
  if AMethod = rmPatch then
    FPCMethod := httproute.rmAll
  else
    FPCMethod := httproute.TRouteMethod(AMethod);

  Result := CreateHTTPRoute(THTTPDocRoute, APattern, FPCMethod, IsDefault) as THTTPDocRoute;
  Result.Initialize;
  Result.DocMethod := AMethod;
  THTTPRouteCallback(Result).CallBack := ACallBack;
end;

function THTTPRouterHelper.Get(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := RegisterDocRoute(APattern, rmGet, ACallBack);
end;

function THTTPRouterHelper.Post(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := RegisterDocRoute(APattern, rmPost, ACallBack);
end;

function THTTPRouterHelper.Put(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := RegisterDocRoute(APattern, rmPut, ACallBack);
end;

function THTTPRouterHelper.Delete(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := RegisterDocRoute(APattern, rmDelete, ACallBack);
end;

function THTTPRouterHelper.Patch(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := RegisterDocRoute(APattern, rmPatch, ACallBack);
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
  FDocMethod := rmUnknown;
  FResponses := TResponseList.Create(True);
  FParams := TDocReqParamList.Create(True);
  FTags := TStringList.Create;
  FSecurity := ssNone;
  FDeprecated := False;
end;

procedure THTTPDocRoute.DoHandleRequest(ARequest: TRequest; AResponse: TResponse);
begin
  if (FDocMethod = rmPatch) and not SameText(ARequest.Method, 'PATCH') then
  begin
    AResponse.Code := 405;
    AResponse.ContentType := 'application/json; charset=utf-8';
    AResponse.Content := '{"error": "Method Not Allowed"}';
    Exit;
  end;
  inherited DoHandleRequest(ARequest, AResponse);
end;

destructor THTTPDocRoute.Destroy;
begin
  FResponses.Free;
  FTags.Free;
  FParams.Free;
  inherited Destroy;
end;

procedure THTTPDocRoute.InvalidateCache;
begin
  if SwaggerRouter <> nil then
    SwaggerRouter.ClearCache;
end;

function THTTPDocRoute.SetSummary(Text: string): THTTPDocRoute;
begin
  FSummary := Text;
  InvalidateCache;
  Result := Self;
end;

function THTTPDocRoute.SetDescription(Text: string): THTTPDocRoute;
begin
  FDescription := Text;
  InvalidateCache;
  Result := Self;
end;

function THTTPDocRoute.SetOperationId(AId: string): THTTPDocRoute;
begin
  FOperationId := AId;
  InvalidateCache;
  Result := Self;
end;

function THTTPDocRoute.SetDeprecated(Value: Boolean): THTTPDocRoute;
begin
  FDeprecated := Value;
  InvalidateCache;
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
  I: Integer;
begin
  if SameText(Code, 'default') then
    Code := 'default'
  else if (StrToIntDef(Code, 0) < 100) or (StrToIntDef(Code, 0) > 599) or
          (IntToStr(StrToIntDef(Code, 0)) <> Code) then
    raise Exception.CreateFmt('Código de resposta OpenAPI inválido: %s', [Code]);
  if ContentType.Trim.IsEmpty then
    raise Exception.Create('Content-Type da resposta não pode ficar vazio.');
  for I := 0 to Responses.Count - 1 do
    if SameText(Responses[I].Code, Code) then
      raise Exception.CreateFmt('Resposta %s já foi documentada nesta rota.', [Code]);
  Response := TDocResponse.Create;
  Response.Code := Code;
  Response.Description := ADescription;
  Response.DocContent.Content := Content;
  Response.DocContent.ContentType := ContentType;
  FResponses.Add(Response);
  InvalidateCache;
  Result := Self;
end;

function THTTPDocRoute.AddResponseRef(Code: Integer; const AModelName: string;
  const ADescription: string; const ContentType: string): THTTPDocRoute;
begin
  Result := AddResponseRef(Code.ToString, AModelName, ADescription, ContentType);
end;

function THTTPDocRoute.AddResponseRef(Code: string; const AModelName: string;
  const ADescription: string; const ContentType: string): THTTPDocRoute;
begin
  Result := AddResponse(Code, ADescription, 'ref:' + AModelName, ContentType);
end;

function THTTPDocRoute.AddResponseRefArray(Code: Integer; const AModelName: string;
  const ADescription: string; const ContentType: string): THTTPDocRoute;
begin
  Result := AddResponseRefArray(Code.ToString, AModelName, ADescription, ContentType);
end;

function THTTPDocRoute.AddResponseRefArray(Code: string; const AModelName: string;
  const ADescription: string; const ContentType: string): THTTPDocRoute;
begin
  Result := AddResponse(Code, ADescription, 'ref:array:' + AModelName, ContentType);
end;

function THTTPDocRoute.AddResponseRefPaginated(Code: Integer; const AModelName: string;
  const ADescription: string; const ContentType: string): THTTPDocRoute;
begin
  Result := AddResponseRefPaginated(Code.ToString, AModelName, ADescription, ContentType);
end;

function THTTPDocRoute.AddResponseRefPaginated(Code: string; const AModelName: string;
  const ADescription: string; const ContentType: string): THTTPDocRoute;
begin
  Result := AddResponse(Code, ADescription, 'ref:paginated:' + AModelName, ContentType);
end;

function THTTPDocRoute.JsonResponse: TJSONObject;
var
  R: TDocResponse;
  Item, JsonCont, JsonSchema: TJSONObject;
  ContentStr: string;
begin
  Result := TJSONObject.Create;
  try
    for R in Responses do
    begin
      Item := TJSONObject.Create;
      try
        Item.Add('description', R.Description);

        ContentStr := Trim(R.DocContent.Content);
        if not ContentStr.IsEmpty then
        begin
          JsonCont := TJSONObject.Create;
          Item.Add('content', JsonCont);
          JsonSchema := TJSONObject.Create;
          JsonCont.Add(R.DocContent.ContentType, JsonSchema);
          JsonSchema.Add('schema', JsonSchemaFromContent(ContentStr));
        end;

        Result.Add(R.Code, Item);
        Item := nil;
      finally
        Item.Free;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function THTTPDocRoute.AddParam(AName: string; ATitle: string;
  Required: Boolean; ParamIn: TParamIn; ParamType: string; ParamDefault: string;
  ADescription: string): THTTPDocRoute;
var
  Param: TDocReqParam;
  DefaultData: TJSONData;
  I: Integer;
begin
  if AName.Trim.IsEmpty then
    raise Exception.Create('Nome do parâmetro não pode ficar vazio.');
  if IndexText(ParamType, ['string', 'integer', 'number', 'boolean']) < 0 then
    raise Exception.CreateFmt('Tipo de parâmetro OpenAPI inválido: %s', [ParamType]);
  if (ParamIn = piPath) and not Required then
    raise Exception.Create('Parâmetros de rota precisam ser obrigatórios.');
  for I := 0 to FParams.Count - 1 do
    if (FParams[I].ParamIn = ParamIn) and SameText(FParams[I].Name, AName) then
      raise Exception.CreateFmt('Parâmetro %s já foi documentado nesta rota.', [AName]);
  DefaultData := ParameterDefaultJson(LowerCase(ParamType), AName, ParamDefault);
  DefaultData.Free;
  if ATitle.IsEmpty then
    ATitle := AName;

  Param := TDocReqParam.Create;
  Param.Name := AName;
  Param.Title := ATitle;
  Param.Description := ADescription;
  Param.Required := Required;
  Param.ParamType := LowerCase(ParamType);
  Param.ParamIn := ParamIn;
  Param.ParamDefault := ParamDefault;

  FParams.Add(Param);
  InvalidateCache;
  Result := Self;
end;

function THTTPDocRoute.AddEnumParam(AName: string; const AValues: array of string;
  Required: Boolean; ParamIn: TParamIn; DefaultValue: string; ADescription: string): THTTPDocRoute;
var
  Param: TDocReqParam;
  I: Integer;
begin
  if AName.Trim.IsEmpty then
    raise Exception.Create('Nome do parâmetro não pode ficar vazio.');
  if (ParamIn = piPath) and not Required then
    raise Exception.Create('Parâmetros de rota precisam ser obrigatórios.');
  if Length(AValues) = 0 then
    raise Exception.Create('Enum precisa ter pelo menos um valor.');
  if (DefaultValue <> '') and (IndexStr(DefaultValue, AValues) < 0) then
    raise Exception.Create('Valor padrão precisa estar entre os valores do enum.');
  for I := 0 to FParams.Count - 1 do
    if (FParams[I].ParamIn = ParamIn) and SameText(FParams[I].Name, AName) then
      raise Exception.CreateFmt('Parâmetro %s já foi documentado nesta rota.', [AName]);
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
  InvalidateCache;
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
  DefaultData: TJSONData;
  P: TDocReqParam;
  I: Integer;
begin
  Result := TJSONArray.Create;
  try
    for P in Params do
    begin
    JsonItem := TJSONObject.Create;
    Result.Add(JsonItem);
    JsonSchema := TJSONObject.Create;
    JsonItem.Add('schema', JsonSchema);

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
    begin
      DefaultData := ParameterDefaultJson(P.ParamType, P.Name, VarToStr(P.ParamDefault));
      JsonSchema.Add('default', DefaultData);
    end;

    end;
  except
    Result.Free;
    raise;
  end;
end;

function THTTPDocRoute.SetBodyContent(Content: string; Required: Boolean;
  ContentType: string; ADescription: string): THTTPDocRoute;
begin
  FBodyContent.Content := Content;
  FBodyContent.ContentType := ContentType;
  FBodyContent.Required := Required;
  FBodyContent.Description := ADescription;
  InvalidateCache;
  Result := Self;
end;

function THTTPDocRoute.SetBodyContentRef(const AModelName: string;
  Required: Boolean; const ContentType: string; const ADescription: string): THTTPDocRoute;
begin
  Result := SetBodyContent('ref:' + AModelName, Required, ContentType, ADescription);
end;

function THTTPDocRoute.JsonBody: TJSONObject;
var
  JBody, JSchema: TJSONObject;
  ContentStr: string;
begin
  Result := TJSONObject.Create;
  try
    JBody := TJSONObject.Create;
    Result.Add('content', JBody);
    JSchema := TJSONObject.Create;
    JBody.Add(FBodyContent.ContentType, JSchema);

    if not FBodyContent.Description.IsEmpty then
      Result.Add('description', FBodyContent.Description);
    Result.Add('required', FBodyContent.Required);

    ContentStr := Trim(FBodyContent.Content);
    JSchema.Add('schema', JsonSchemaFromContent(ContentStr));
  except
    Result.Free;
    raise;
  end;
end;

function THTTPDocRoute.SetSecurity(Scheme: TSecurityScheme): THTTPDocRoute;
begin
  FSecurity := Scheme;
  if (Scheme <> ssNone) and
     not (Scheme in SwaggerRouter.Components.SecuritySchemes) then
    SwaggerRouter.Components.SecuritySchemes := SwaggerRouter.Components.SecuritySchemes + [Scheme];
  InvalidateCache;
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
  if HeaderName.Trim.IsEmpty then
    raise Exception.Create('Nome do header de API Key não pode ficar vazio.');
  if (ssApiKey in SwaggerRouter.Components.SecuritySchemes) and
     not SameText(SwaggerRouter.Components.ApiKeyHeaderName, HeaderName) then
    raise Exception.Create('Swagger4Laz suporta um único nome de header para API Key.');
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
  InvalidateCache;
  Result := Self;
end;

function THTTPDocRoute.AddTag(ADescription: string): THTTPDocRoute;
begin
  Result := AddTags(ADescription);
end;

function THTTPDocRoute.Tag(ADescription: string): THTTPDocRoute;
begin
  Result := AddTags(ADescription);
end;

function THTTPDocRoute.SetTag(ADescription: string): THTTPDocRoute;
begin
  FTags.Clear;
  Result := AddTags(ADescription);
end;

function THTTPDocRoute.SetTags(const ATags: array of string): THTTPDocRoute;
var
  I: Integer;
begin
  FTags.Clear;
  for I := Low(ATags) to High(ATags) do
    AddTags(ATags[I]);
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
  FCacheLock := TCriticalSection.Create; // Inicializa o Lock
  FDefaultCustomHeaders := TStringList.Create;
  FComponents := TSwaggerComponents.Create;
  FServers := TJSONArray.Create;
  FTitle := 'API';
  FVersion := '1.0.0';
  FBasePath := '';
  FDocRoute := '';
  FDocCache := '';
  FDocCacheBasePath := '';
end;

destructor TSwaggerRouter.Destroy;
begin
  FComponents.Free;
  FDefaultCustomHeaders.Free;
  FServers.Free;
  if FContactObj <> nil then FContactObj.Free;
  if FLicenseObj <> nil then FLicenseObj.Free;
  FCacheLock.Free; // Libera o Lock
  inherited Destroy;
end;

procedure TSwaggerRouter.ClearCache;
begin
  FCacheLock.Acquire;
  try
    FDocCache := '';
    FDocCacheBasePath := '';
  finally
    FCacheLock.Release;
  end;
end;

procedure TSwaggerRouter.HTTPRouterAfterRequest(Sender: TObject;
  ARequest: TRequest; AResponse: TResponse);
begin
  if SameText(Trim(AResponse.ContentType), 'application/json') then
    AResponse.ContentType := 'application/json; charset=utf-8'
  else if SameText(Trim(AResponse.ContentType), 'application/problem+json') then
    AResponse.ContentType := 'application/problem+json; charset=utf-8';
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
  Result.SetDefaultContentType('application/json; charset=utf-8');
  HTTPRouter.BeforeRequest := @Result.HTTPRouterBeforeRequest;
  HTTPRouter.AfterRequest := @Result.HTTPRouterAfterRequest;
end;

function TSwaggerRouter.RegisterRoute(const APattern: String;
  AMethod: TRouteMethod; ACallBack: TRouteCallBack; IsDefault: Boolean
  ): THTTPDocRoute;
begin
  FCacheLock.Acquire;
  try
    Result := HTTPRouter.RegisterDocRoute(APattern, AMethod, ACallBack, IsDefault);
    FDocCache := '';
    FDocCacheBasePath := '';
  finally
    FCacheLock.Release;
  end;
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

function TSwaggerRouter.Patch(const APattern: string; ACallBack: TRouteCallBack
  ): THTTPDocRoute;
begin
  Result := RegisterRoute(APattern, rmPatch, ACallBack);
end;

function TSwaggerRouter.HasModel(const AName: string): Boolean;
begin
  FCacheLock.Acquire;
  try
    Result := FComponents.Models.Find(AName) <> nil;
  finally
    FCacheLock.Release;
  end;
end;

function TSwaggerRouter.EnsureModel(const AName: string; AModel: TJSONData): TSwaggerRouter;
var
  Existing: TJSONData;
begin
  if AName.Trim.IsEmpty then
  begin
    if Assigned(AModel) then AModel.Free;
    raise Exception.Create('Nome do schema não pode ficar vazio.');
  end;
  if AModel = nil then
    raise Exception.CreateFmt('Schema "%s" não pode ser nil.', [AName]);
  if AModel.JSONType <> jtObject then
  begin
    AModel.Free;
    raise Exception.CreateFmt('Schema "%s" precisa ser um objeto JSON.', [AName]);
  end;

  FCacheLock.Acquire;
  try
    Existing := FComponents.Models.Find(AName);
    if Existing <> nil then
    begin
      // Já registrado: libera AModel e não faz nada (idempotente)
      AModel.Free;
    end
    else
    begin
      FComponents.Models.Add(AName, AModel);
      FDocCache := '';
      FDocCacheBasePath := '';
    end;
  finally
    FCacheLock.Release;
  end;
  Result := Self;
end;

function TSwaggerRouter.EnsureModel(const AName: string; const AModel: string): TSwaggerRouter;
var
  Schema: TJSONData;
begin
  if HasModel(AName) then
    Exit(Self);

  Schema := GetJSON(AModel, False);
  try
    Result := EnsureModel(AName, Schema);
    Schema := nil;
  finally
    Schema.Free;
  end;
end;

function TSwaggerRouter.RegisterModel(AName: string; AModel: TJSONData; AOverwrite: Boolean): TSwaggerRouter;
var
  ExistingIdx: Integer;
begin
  if AName.Trim.IsEmpty then
    raise Exception.Create('Nome do schema não pode ficar vazio.');
  if AModel = nil then
    raise Exception.CreateFmt('Schema "%s" não pode ser nil.', [AName]);
  if AModel.JSONType <> jtObject then
    raise Exception.CreateFmt('Schema "%s" precisa ser um objeto JSON.', [AName]);
  FCacheLock.Acquire;
  try
    ExistingIdx := FComponents.Models.IndexOfName(AName);
    if ExistingIdx >= 0 then
    begin
      if AOverwrite then
      begin
        FComponents.Models.Delete(ExistingIdx);
        FComponents.Models.Add(AName, AModel);
        FDocCache := '';
        FDocCacheBasePath := '';
      end
      else
        raise Exception.CreateFmt('Schema "%s" já foi registrado.', [AName]);
    end
    else
    begin
      FComponents.Models.Add(AName, AModel);
      FDocCache := '';
      FDocCacheBasePath := '';
    end;
  finally
    FCacheLock.Release;
  end;
  Result := Self;
end;

function TSwaggerRouter.RegisterModel(AName: string; AModel: string; AOverwrite: Boolean): TSwaggerRouter;
var
  Schema: TJSONData;
begin
  Schema := GetJSON(AModel, False);
  try
    Result := RegisterModel(AName, Schema, AOverwrite);
    Schema := nil;
  finally
    Schema.Free;
  end;
end;

function TSwaggerRouter.RegisterModel(AName: string; AModel: TJSONData): TSwaggerRouter;
begin
  Result := RegisterModel(AName, AModel, False);
end;

function TSwaggerRouter.RegisterModel(AName: string; AModel: string): TSwaggerRouter;
begin
  Result := RegisterModel(AName, AModel, False);
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
var
  CleanEndpoint: string;
begin
  CleanEndpoint := NormalizePathPrefix(Endpoint);
  if CleanEndpoint.IsEmpty then
    CleanEndpoint := '/docs';

  if not FDocRoute.IsEmpty then
  begin
    if FDocRoute = CleanEndpoint then
      Exit(Self);
    raise Exception.Create('A rota do Swagger já foi registrada e não pode ser alterada.');
  end;

  ClearCache;
  HTTPRouter.RegisterRoute(CleanEndpoint, httproute.TRouteMethod(rmGet), @SwaggerUI);
  if CleanEndpoint <> '/' then
    HTTPRouter.RegisterRoute(CleanEndpoint + '/', httproute.TRouteMethod(rmGet), @SwaggerUI);
  if CleanEndpoint = '/' then
    HTTPRouter.RegisterRoute('/openapi.json', httproute.TRouteMethod(rmGet), @Documentacao)
  else
    HTTPRouter.RegisterRoute(CleanEndpoint + '/openapi.json', httproute.TRouteMethod(rmGet), @Documentacao);
  FDocRoute := CleanEndpoint;

  Result := Self;
end;

function TSwaggerRouter.SetTitle(ATitle: string): TSwaggerRouter;
begin
  FTitle := ATitle;
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.SetVersion(AVersion: string): TSwaggerRouter;
begin
  FVersion := AVersion;
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.SetDescription(Text: string): TSwaggerRouter;
begin
  FDescription := Text;
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.SetBasePath(const APath: string): TSwaggerRouter;
begin
  FBasePath := NormalizePathPrefix(APath);
  if FBasePath = '/' then
    FBasePath := '';
  if FBasePath = '/' then
    FBasePath := '';
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.SetContact(const Name, Url, Email: string): TSwaggerRouter;
begin
  if FContactObj = nil then FContactObj := TJSONObject.Create;
  FContactObj.Clear;
  if not Name.IsEmpty then FContactObj.Add('name', Name);
  if not Url.IsEmpty then FContactObj.Add('url', Url);
  if not Email.IsEmpty then FContactObj.Add('email', Email);
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.SetLicense(const Name, Url: string): TSwaggerRouter;
begin
  if FLicenseObj = nil then FLicenseObj := TJSONObject.Create;
  FLicenseObj.Clear;
  FLicenseObj.Add('name', Name);
  if not Url.IsEmpty then FLicenseObj.Add('url', Url);
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.AddServer(const Url: string; const ADescription: string): TSwaggerRouter;
var
  ServerObj: TJSONObject;
begin
  ServerObj := TJSONObject.Create;
  ServerObj.Add('url', Url);
  if not ADescription.IsEmpty then
    ServerObj.Add('description', ADescription);
  FServers.Add(ServerObj);
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.SetDefaultContentType(Text: string): TSwaggerRouter;
begin
  FDefaultContentType := Text;
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.AddCustomHeader(const AHeader, AValue: string
  ): TSwaggerRouter;
begin
  FDefaultCustomHeaders.Values[AHeader] := AValue;
  ClearCache;
  Result := Self;
end;

initialization
  HTTPRouter := httproute.HTTPRouter;
  TSwaggerRouter.Initialize;

finalization
  SwaggerRouter.Free;

end.
