unit swagger4laz;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Types, syncobjs, contnrs, httproute, HTTPDefs, RegExpr, fpjson, jsonparser, fgl, Variants, TypInfo;

const
  // Canonical Media Types (RFC 6838, RFC 8949, BSON, XML, CSV)
  MEDIA_TYPE_JSON         = 'application/json';
  MEDIA_TYPE_CBOR         = 'application/cbor';
  MEDIA_TYPE_BSON         = 'application/bson';
  MEDIA_TYPE_XML          = 'application/xml';
  MEDIA_TYPE_TEXT_XML     = 'text/xml';
  MEDIA_TYPE_CSV          = 'text/csv';
  MEDIA_TYPE_OCTET_STREAM = 'application/octet-stream';
  MEDIA_TYPE_FORM         = 'application/x-www-form-urlencoded';
  MEDIA_TYPE_MULTIPART    = 'multipart/form-data';
  MEDIA_TYPE_PROBLEM_JSON = 'application/problem+json';

  // Compression Encodings
  ENCODING_GZIP           = 'gzip';
  ENCODING_DEFLATE        = 'deflate';
  ENCODING_BR             = 'br';
  ENCODING_IDENTITY       = 'identity';

  // Backward-compatible MIME aliases
  MIME_APPLICATION_JSON   = MEDIA_TYPE_JSON;
  MIME_APPLICATION_CBOR   = MEDIA_TYPE_CBOR;
  MIME_APPLICATION_BSON   = MEDIA_TYPE_BSON;
  MIME_APPLICATION_XML    = MEDIA_TYPE_XML;
  MIME_TEXT_XML           = MEDIA_TYPE_TEXT_XML;
  MIME_TEXT_CSV           = MEDIA_TYPE_CSV;

type
  TSwaggerRouter = class;
  THTTPDocRoute = class;
  TSwaggerRouteGroup = class;

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

  { TDocContentItem }
  TDocContentItem = class
  public
    ContentType: string;
    Content: string;
    Description: string;
  end;

  TDocContentItemList = specialize TFPGObjectList<TDocContentItem>;

  { TDocResponseHeader }
  TDocResponseHeader = class
  public
    Name: string;
    HeaderType: string;
    Description: string;
    DefaultValue: string;
  end;

  TDocResponseHeaderList = specialize TFPGObjectList<TDocResponseHeader>;

  TDocResponse = class
  private
    FContents: TDocContentItemList;
    FHeaders: TDocResponseHeaderList;
  public
    Code: string;
    Description: string;
    DocContent: TDocContent;
    property Contents: TDocContentItemList read FContents;
    property Headers: TDocResponseHeaderList read FHeaders;

    constructor Create;
    destructor Destroy; override;

    function HasContentType(const AContentType: string): Boolean;
    procedure AddOrUpdateContent(const AContentType, AContent: string; const ADescription: string = '');
    function FindHeader(const AName: string): TDocResponseHeader;
    procedure AddOrUpdateHeader(const AName, AType: string; const ADescription: string = ''; const ADefault: string = '');
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
    FBodyContents: TDocContentItemList;
    FDefaultMediaTypes: array of string;
    FDefaultConsumesMediaTypes: array of string;
    FParams: TDocReqParamList;
    FResponses: TResponseList;
    FSecurity: TSecurityScheme;
    FSummary: string;
    FDescription: string;
    FOperationId: string;
    FDeprecated: Boolean;
    FTags: TStrings;
    function GetPath: string;
    procedure InvalidateCache;
  protected
    procedure DoHandleRequest(ARequest: TRequest; AResponse: TResponse); override;
  public
    property DocMethod: TRouteMethod read FDocMethod write FDocMethod;
    property Path: string read GetPath;
    property OperationId: string read FOperationId;
    property IsDeprecated: Boolean read FDeprecated;

    function Summary: string; overload;
    function Summary(Text: string): THTTPDocRoute; overload;
    function Description: string; overload;
    function Description(Text: string): THTTPDocRoute; overload;
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
    function FindResponse(const ACode: string): TDocResponse; overload;
    function FindResponse(ACode: Integer): TDocResponse; overload;
    function JsonResponse: TJSONObject;

    property Params: TDocReqParamList read FParams;
    function AddParam(AName: string; ATitle: string = ''; Required: Boolean = True; ParamIn: TParamIn = piQuery; ParamType: string = 'string'; ParamDefault: string = ''; ADescription: string = ''): THTTPDocRoute;
    function AddEnumParam(AName: string; const AValues: array of string; Required: Boolean = False; ParamIn: TParamIn = piQuery; DefaultValue: string = ''; ADescription: string = ''): THTTPDocRoute;
    function AddPathParam(AName: string; Required: Boolean = True; ParamType: string = 'string'; DefaultValue: string = ''; ADescription: string = ''): THTTPDocRoute;
    function AddQueryParam(AName: string; Required: Boolean = False; ParamType: string = 'string'; DefaultValue: string = ''; ADescription: string = ''): THTTPDocRoute;
    function AddHeaderParam(AName: string; Required: Boolean = False; ParamType: string = 'string'; DefaultValue: string = ''; ADescription: string = ''): THTTPDocRoute;
    function FindParam(const AName: string): TDocReqParam;
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

    { Fluent Semantic Chaining }
    function Produces(Code: Integer; const AModelName: string; const ADescription: string = ''): THTTPDocRoute; overload;
    function Produces(const AMediaTypes: array of string): THTTPDocRoute; overload;
    function Produces(Code: Integer; const AModelName: string; const AMediaTypes: array of string; const ADescription: string = ''): THTTPDocRoute; overload;
    function ProducesArray(Code: Integer; const AModelName: string; const ADescription: string = ''): THTTPDocRoute; overload;
    function ProducesArray(Code: Integer; const AModelName: string; const AMediaTypes: array of string; const ADescription: string = ''): THTTPDocRoute; overload;
    function ProducesPaginated(Code: Integer; const AModelName: string; const ADescription: string = ''): THTTPDocRoute; overload;
    function ProducesPaginated(Code: Integer; const AModelName: string; const AMediaTypes: array of string; const ADescription: string = ''): THTTPDocRoute; overload;
    function ProducesEmpty(Code: Integer = 204; const ADescription: string = ''): THTTPDocRoute;
    function Consumes(const AModelName: string; Required: Boolean = True; const ADescription: string = 'Payload'): THTTPDocRoute; overload;
    function Consumes(const AModelName: string; const AMediaTypes: array of string; Required: Boolean = True; const ADescription: string = 'Payload'): THTTPDocRoute; overload;
    function Consumes(const AMediaTypes: array of string): THTTPDocRoute; overload;
    function ConsumesJson(const AModelName: string; Required: Boolean = True; const ADescription: string = 'JSON Payload'): THTTPDocRoute;
    function ConsumesFormData(const ADescription: string = 'Form Data Payload'): THTTPDocRoute;
    function ConsumesMultipart(const ADescription: string = 'Multipart Form Payload'): THTTPDocRoute;

    { Content Encoding & Compression Helpers }
    function AcceptsGzip(Required: Boolean = False): THTTPDocRoute;
    function AcceptsEncoding(const AEncoding: string = 'gzip'; Required: Boolean = False): THTTPDocRoute;
    function ProducesEncoding(const AEncoding: string = 'gzip'; Code: Integer = 200): THTTPDocRoute;
    function ProducesGzip(Code: Integer = 200): THTTPDocRoute;
    function AddResponseHeader(Code: Integer; const AName, AType: string; const ADescription: string = ''; const ADefault: string = ''): THTTPDocRoute; overload;
    function AddResponseHeader(const ACode: string; const AName, AType: string; const ADescription: string = ''; const ADefault: string = ''): THTTPDocRoute; overload;

    { Defaults Setters }
    procedure SetDefaultMediaTypes(const AMediaTypes: array of string);
    procedure SetDefaultConsumesMediaTypes(const AMediaTypes: array of string);

    { RFC 7807 Problem Details }
    function ProducesProblem(ACode: Integer): THTTPDocRoute; overload;
    { Same as ProducesProblem(ACode) with a route-specific description. If the code
      was already registered (e.g. by a group default), only its description is updated. }
    function ProducesProblem(ACode: Integer; const ADescription: string): THTTPDocRoute; overload;
    function ProducesProblem(const ACodes: array of Integer): THTTPDocRoute; overload;
    function ProducesStandardProblems: THTTPDocRoute;

    { Concise Parameter Helpers }
    function QueryParam(const AName: string; const AType: string = 'string'; const ADefault: string = ''; const ADescription: string = ''): THTTPDocRoute;
    function PathParam(const AName: string; const AType: string = 'integer'; const ADescription: string = ''): THTTPDocRoute;
    function HeaderParam(const AName: string; const AType: string = 'string'; Required: Boolean = False; const ADescription: string = ''): THTTPDocRoute;
    function EnumParam(const AName: string; const AValues: array of string; const ADescription: string = ''): THTTPDocRoute;

    { Fluent Security Shortcuts }
    function SecurityBearer: THTTPDocRoute;
    function SecurityBasic: THTTPDocRoute;
    function SecurityApiKey(const AHeader: string = 'X-API-Key'): THTTPDocRoute;
    function SecurityNone: THTTPDocRoute;

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

  { TSwaggerRouteGroup }

  TSwaggerRouteGroup = class
  private
    FRouter: TSwaggerRouter;
    FPrefix: string;
    FTag: string;
    FSecurity: TSecurityScheme;
    FApiKeyHeader: string;
    FHasSecurity: Boolean;
    FProblemCodes: array of Integer;
    FDefaultMediaTypes: array of string;
    FDefaultConsumesMediaTypes: array of string;
    FDefaultEncodings: array of string;
    FEnableGzip: Boolean;
    function CombinePath(const ASubPattern: string): string;
    function ApplyGroupSettings(ARoute: THTTPDocRoute): THTTPDocRoute;
  public
    constructor Create(ARouter: TSwaggerRouter; const APrefix: string);

    property Prefix: string read FPrefix;
    property CurrentTag: string read FTag;

    function Tag(const ATag: string): TSwaggerRouteGroup;
    function Security(AScheme: TSecurityScheme): TSwaggerRouteGroup;
    function SecurityBearer: TSwaggerRouteGroup;
    function SecurityBasic: TSwaggerRouteGroup;
    function SecurityApiKey(const AHeader: string = 'X-API-Key'): TSwaggerRouteGroup;
    function SecurityNone: TSwaggerRouteGroup;

    function Problem(ACode: Integer): TSwaggerRouteGroup;
    function StandardProblems: TSwaggerRouteGroup;

    function ProducesMediaTypes(const AMediaTypes: array of string): TSwaggerRouteGroup;
    function ConsumesMediaTypes(const AMediaTypes: array of string): TSwaggerRouteGroup;
    function AcceptsGzip(Required: Boolean = False): TSwaggerRouteGroup;
    function AcceptsEncoding(const AEncoding: string = 'gzip'; Required: Boolean = False): TSwaggerRouteGroup;
    function ProducesEncoding(const AEncoding: string = 'gzip'): TSwaggerRouteGroup;
    function EnableGzip(AEnabled: Boolean = True): TSwaggerRouteGroup;

    function Get(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Post(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Put(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Delete(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Patch(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Options(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Head(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
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
    function Options(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Head(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
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
    FDefaultMediaTypes: array of string;
    FDefaultConsumesMediaTypes: array of string;
    FDefaultEncodings: array of string;
    FEnableGzip: Boolean;
    FServers: TJSONArray;
    FContactObj: TJSONObject;
    FLicenseObj: TJSONObject;
    FBasePath: string;
    FDocRoute: string;
    FDocCache: string;
    FDocCacheBasePath: string;
    FCacheLock: TCriticalSection;
    FGroups: TFPObjectList;
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
    function Options(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Head(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
    function Group(const APrefix: string): TSwaggerRouteGroup;

    { Defaults & Encodings }
    function SetDefaultMediaTypes(const AMediaTypes: array of string): TSwaggerRouter;
    function SetDefaultConsumesMediaTypes(const AMediaTypes: array of string): TSwaggerRouter;
    function SetDefaultEncodings(const AEncodings: array of string): TSwaggerRouter;
    function EnableGzip(AEnabled: Boolean = True): TSwaggerRouter;
    function IsGzipEnabled: Boolean;
    function GetDefaultMediaTypes: TStringDynArray;
    function GetDefaultConsumesMediaTypes: TStringDynArray;
    function GetDefaultEncodings: TStringDynArray;

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
    function BuildOpenAPISpecification(const ABasePath: string = ''): string;

    constructor Create;
    destructor Destroy; override;
  end;

var
  SwaggerRouter: TSwaggerRouter;
  HTTPRouter: THTTPRouter;

type
  { Supported locales for Swagger4Laz messages }
  TSwaggerLocale = (slEnUS, slPtBR, slEsES);

procedure SetSwaggerLocale(ALocale: TSwaggerLocale);
function GetSwaggerLocale: TSwaggerLocale;
procedure SetSwaggerLocaleByName(const AName: string);
function GetSwaggerLocaleName: string;

procedure Documentation(AReq: TRequest; AResp: TResponse);
procedure Documentacao(AReq: TRequest; AResp: TResponse); // Backward compatibility alias
procedure SwaggerUI(AReq: TRequest; AResp: TResponse);

implementation

uses
  zstream;

var
  GSwaggerLocale: TSwaggerLocale = slEnUS;

const
  STR_SWAGGER_LOCALE_NAMES: array[TSwaggerLocale] of string = ('en-US', 'pt-BR', 'es-ES');

  STR_SWAGGER_INVALID_PREFIX: array[TSwaggerLocale] of string = (
    'Invalid route prefix: %s',
    'Prefixo de rota inválido: %s',
    'Prefijo de ruta no válido: %s'
  );
  STR_SWAGGER_SCHEMA_MUST_BE_JSON: array[TSwaggerLocale] of string = (
    'OpenAPI schema must be a JSON object.',
    'OpenAPI schema precisa ser um objeto JSON.',
    'El esquema OpenAPI debe ser un objeto JSON.'
  );
  STR_SWAGGER_SCHEMA_NOT_REGISTERED: array[TSwaggerLocale] of string = (
    'Schema "%s" not registered in components/schemas.',
    'Schema "%s" não registrado em components/schemas.',
    'Esquema "%s" no registrado en components/schemas.'
  );
  STR_SWAGGER_INVALID_DEFAULT_NUMERIC: array[TSwaggerLocale] of string = (
    'Invalid numeric default value for %s.',
    'Valor padrão numérico inválido para %s.',
    'Valor predeterminado numérico no válido para %s.'
  );
  STR_SWAGGER_INVALID_DEFAULT_INTEGER: array[TSwaggerLocale] of string = (
    'Invalid integer default value for %s.',
    'Valor padrão inteiro inválido para %s.',
    'Valor predeterminado entero no válido para %s.'
  );
  STR_SWAGGER_INVALID_DEFAULT_BOOLEAN: array[TSwaggerLocale] of string = (
    'Invalid boolean default value for %s.',
    'Valor padrão booleano inválido para %s.',
    'Valor predeterminado booleano no válido para %s.'
  );
  STR_SWAGGER_INVALID_OPENAPI_TYPE: array[TSwaggerLocale] of string = (
    'Invalid OpenAPI type for %s.',
    'Tipo OpenAPI inválido para %s.',
    'Tipo de OpenAPI no válido para %s.'
  );
  STR_SWAGGER_ROUTE_PARAM_NOT_EXIST: array[TSwaggerLocale] of string = (
    'Route parameter "%s" does not exist in %s.',
    'Parâmetro de rota "%s" não existe em %s.',
    'El parámetro de ruta "%s" no existe en %s.'
  );
  STR_SWAGGER_DUPLICATE_OPERATION_ID: array[TSwaggerLocale] of string = (
    'Duplicate operationId: %s',
    'operationId duplicado: %s',
    'operationId duplicado: %s'
  );
  STR_SWAGGER_METHOD_NOT_DOCUMENTABLE: array[TSwaggerLocale] of string = (
    'HTTP method not documentable in %s.',
    'Método HTTP não documentável em %s.',
    'Método HTTP no documentable en %s.'
  );
  STR_SWAGGER_DUPLICATE_ROUTE: array[TSwaggerLocale] of string = (
    'Duplicate route for %s %s.',
    'Rota duplicada para %s %s.',
    'Ruta duplicada para %s %s.'
  );
  STR_SWAGGER_INVALID_RESPONSE_CODE: array[TSwaggerLocale] of string = (
    'Invalid OpenAPI response code: %s',
    'Código de resposta OpenAPI inválido: %s',
    'Código de respuesta OpenAPI no válido: %s'
  );
  STR_SWAGGER_CONTENT_TYPE_EMPTY: array[TSwaggerLocale] of string = (
    'Response Content-Type cannot be empty.',
    'Content-Type da resposta não pode ficar vazio.',
    'El Content-Type de respuesta no puede estar vacío.'
  );
  STR_SWAGGER_DUPLICATE_RESPONSE: array[TSwaggerLocale] of string = (
    'Response %s has already been documented on this route.',
    'Resposta %s já foi documentada nesta rota.',
    'La respuesta %s ya ha sido documentada en esta ruta.'
  );
  STR_SWAGGER_PARAM_NAME_EMPTY: array[TSwaggerLocale] of string = (
    'Parameter name cannot be empty.',
    'Nome do parâmetro não pode ficar vazio.',
    'El nombre del parámetro no puede estar vacío.'
  );
  STR_SWAGGER_INVALID_PARAM_TYPE: array[TSwaggerLocale] of string = (
    'Invalid OpenAPI parameter type: %s',
    'Tipo de parâmetro OpenAPI inválido: %s',
    'Tipo de parámetro OpenAPI no válido: %s'
  );
  STR_SWAGGER_PATH_PARAM_MUST_BE_REQUIRED: array[TSwaggerLocale] of string = (
    'Path parameters must be required.',
    'Parâmetros de rota precisam ser obrigatórios.',
    'Los parámetros de ruta deben ser obligatorios.'
  );
  STR_SWAGGER_DUPLICATE_PARAM: array[TSwaggerLocale] of string = (
    'Parameter %s has already been documented on this route.',
    'Parâmetro %s já foi documentado nesta rota.',
    'El parámetro %s ya ha sido documentado en esta ruta.'
  );
  STR_SWAGGER_ENUM_MUST_HAVE_VALUES: array[TSwaggerLocale] of string = (
    'Enum must have at least one value.',
    'Enum precisa ter pelo menos um valor.',
    'El enum debe tener al menos un valor.'
  );
  STR_SWAGGER_DEFAULT_MUST_BE_IN_ENUM: array[TSwaggerLocale] of string = (
    'Default value must be one of the enum values.',
    'Valor padrão precisa estar entre os valores do enum.',
    'El valor predeterminado debe ser uno de los valores del enum.'
  );
  STR_SWAGGER_API_KEY_HEADER_EMPTY: array[TSwaggerLocale] of string = (
    'API Key header name cannot be empty.',
    'Nome do header de API Key não pode ficar vazio.',
    'El nombre del encabezado de la clave de API no puede estar vacío.'
  );
  STR_SWAGGER_SINGLE_API_KEY_HEADER: array[TSwaggerLocale] of string = (
    'Swagger4Laz supports a single header name for API Key.',
    'Swagger4Laz suporta um único nome de header para API Key.',
    'Swagger4Laz admite un único nombre de encabezado para la clave de API.'
  );
  STR_SWAGGER_SCHEMA_NAME_EMPTY: array[TSwaggerLocale] of string = (
    'Schema name cannot be empty.',
    'Nome do schema não pode ficar vazio.',
    'El nombre del esquema no puede estar vacío.'
  );
  STR_SWAGGER_SCHEMA_CANNOT_BE_NIL: array[TSwaggerLocale] of string = (
    'Schema "%s" cannot be nil.',
    'Schema "%s" não pode ser nil.',
    'El esquema "%s" no puede ser nulo.'
  );
  STR_SWAGGER_SCHEMA_MUST_BE_OBJECT: array[TSwaggerLocale] of string = (
    'Schema "%s" must be a JSON object.',
    'Schema "%s" precisa ser um objeto JSON.',
    'El esquema "%s" debe ser un objeto JSON.'
  );
  STR_SWAGGER_SCHEMA_ALREADY_REGISTERED: array[TSwaggerLocale] of string = (
    'Schema "%s" is already registered.',
    'Schema "%s" já foi registrado.',
    'El esquema "%s" ya ha sido registrado.'
  );
  STR_SWAGGER_INVALID_PASCAL_ENUM: array[TSwaggerLocale] of string = (
    'Type "%s" is not a valid Pascal Enum.',
    'O tipo "%s" não é um Enum Pascal válido.',
    'El tipo "%s" no es un Enum de Pascal válido.'
  );
  STR_SWAGGER_ROUTE_ALREADY_REGISTERED: array[TSwaggerLocale] of string = (
    'The Swagger route has already been registered and cannot be modified.',
    'A rota do Swagger já foi registrada e não pode ser alterada.',
    'La ruta de Swagger ya ha sido registrada y no se puede modificar.'
  );

procedure SetSwaggerLocale(ALocale: TSwaggerLocale);
begin
  GSwaggerLocale := ALocale;
end;

function GetSwaggerLocale: TSwaggerLocale;
begin
  Result := GSwaggerLocale;
end;

procedure SetSwaggerLocaleByName(const AName: string);
var
  S: string;
begin
  S := LowerCase(Trim(AName));
  if (S = 'pt') or (S = 'pt-br') or (S = 'pt_br') or (S = 'portuguese') then
    GSwaggerLocale := slPtBR
  else if (S = 'es') or (S = 'es-es') or (S = 'es_es') or (S = 'spanish') then
    GSwaggerLocale := slEsES
  else
    GSwaggerLocale := slEnUS;
end;

function GetSwaggerLocaleName: string;
begin
  Result := STR_SWAGGER_LOCALE_NAMES[GSwaggerLocale];
end;

function MsgInvalidRoutePrefix(const APath: string): string;
begin
  Result := Format(STR_SWAGGER_INVALID_PREFIX[GSwaggerLocale], [APath]);
end;

function MsgOpenApiSchemaMustBeJsonObject: string;
begin
  Result := STR_SWAGGER_SCHEMA_MUST_BE_JSON[GSwaggerLocale];
end;

function MsgSchemaNotRegistered(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_SCHEMA_NOT_REGISTERED[GSwaggerLocale], [AName]);
end;

function MsgInvalidDefaultNumeric(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_INVALID_DEFAULT_NUMERIC[GSwaggerLocale], [AName]);
end;

function MsgInvalidDefaultInteger(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_INVALID_DEFAULT_INTEGER[GSwaggerLocale], [AName]);
end;

function MsgInvalidDefaultBoolean(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_INVALID_DEFAULT_BOOLEAN[GSwaggerLocale], [AName]);
end;

function MsgInvalidOpenApiType(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_INVALID_OPENAPI_TYPE[GSwaggerLocale], [AName]);
end;

function MsgRouteParamNotFound(const AParam, ARoute: string): string;
begin
  Result := Format(STR_SWAGGER_ROUTE_PARAM_NOT_EXIST[GSwaggerLocale], [AParam, ARoute]);
end;

function MsgDuplicateOperationId(const AId: string): string;
begin
  Result := Format(STR_SWAGGER_DUPLICATE_OPERATION_ID[GSwaggerLocale], [AId]);
end;

function MsgMethodNotDocumentable(const AMethod: string): string;
begin
  Result := Format(STR_SWAGGER_METHOD_NOT_DOCUMENTABLE[GSwaggerLocale], [AMethod]);
end;

function MsgDuplicateRoute(const AMethod, APattern: string): string;
begin
  Result := Format(STR_SWAGGER_DUPLICATE_ROUTE[GSwaggerLocale], [AMethod, APattern]);
end;

function MsgInvalidResponseCode(const ACode: string): string;
begin
  Result := Format(STR_SWAGGER_INVALID_RESPONSE_CODE[GSwaggerLocale], [ACode]);
end;

function MsgResponseContentTypeEmpty: string;
begin
  Result := STR_SWAGGER_CONTENT_TYPE_EMPTY[GSwaggerLocale];
end;

function MsgDuplicateResponse(const ACode: string): string;
begin
  Result := Format(STR_SWAGGER_DUPLICATE_RESPONSE[GSwaggerLocale], [ACode]);
end;

function MsgParamNameEmpty: string;
begin
  Result := STR_SWAGGER_PARAM_NAME_EMPTY[GSwaggerLocale];
end;

function MsgInvalidParamType(const AType: string): string;
begin
  Result := Format(STR_SWAGGER_INVALID_PARAM_TYPE[GSwaggerLocale], [AType]);
end;

function MsgPathParamMustBeRequired: string;
begin
  Result := STR_SWAGGER_PATH_PARAM_MUST_BE_REQUIRED[GSwaggerLocale];
end;

function MsgDuplicateParam(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_DUPLICATE_PARAM[GSwaggerLocale], [AName]);
end;

function MsgEnumMustHaveValues: string;
begin
  Result := STR_SWAGGER_ENUM_MUST_HAVE_VALUES[GSwaggerLocale];
end;

function MsgDefaultMustBeInEnum: string;
begin
  Result := STR_SWAGGER_DEFAULT_MUST_BE_IN_ENUM[GSwaggerLocale];
end;

function MsgApiKeyHeaderNameEmpty: string;
begin
  Result := STR_SWAGGER_API_KEY_HEADER_EMPTY[GSwaggerLocale];
end;

function MsgSingleApiKeyHeaderSupported: string;
begin
  Result := STR_SWAGGER_SINGLE_API_KEY_HEADER[GSwaggerLocale];
end;

function MsgSchemaNameEmpty: string;
begin
  Result := STR_SWAGGER_SCHEMA_NAME_EMPTY[GSwaggerLocale];
end;

function MsgSchemaCannotBeNil(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_SCHEMA_CANNOT_BE_NIL[GSwaggerLocale], [AName]);
end;

function MsgSchemaMustBeJsonObject(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_SCHEMA_MUST_BE_OBJECT[GSwaggerLocale], [AName]);
end;

function MsgSchemaAlreadyRegistered(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_SCHEMA_ALREADY_REGISTERED[GSwaggerLocale], [AName]);
end;

function MsgInvalidPascalEnum(const AName: string): string;
begin
  Result := Format(STR_SWAGGER_INVALID_PASCAL_ENUM[GSwaggerLocale], [AName]);
end;

function MsgSwaggerRouteAlreadyRegistered: string;
begin
  Result := STR_SWAGGER_ROUTE_ALREADY_REGISTERED[GSwaggerLocale];
end;

procedure Documentation(AReq: TRequest; AResp: TResponse);
begin
  Documentacao(AReq, AResp);
end;

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
    raise Exception.Create(MsgInvalidRoutePrefix(APath));
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
      raise Exception.Create(MsgOpenApiSchemaMustBeJsonObject);
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

  // Validate in SwaggerRouter if the router is instantiated
  if Assigned(SwaggerRouter) and (SwaggerRouter.Components.Models.Find(CleanModelName) = nil) then
    raise Exception.Create(MsgSchemaNotRegistered(CleanModelName));

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
          raise Exception.Create(MsgInvalidDefaultNumeric(AName));
        end;
        if (TypeIndex = 1) and
           ((Pos('.', Parsed) > 0) or (Pos('e', LowerCase(Parsed)) > 0)) then
        begin
          Result.Free;
          Result := nil;
          raise Exception.Create(MsgInvalidDefaultInteger(AName));
        end;
      end;
    3:
      if SameText(AValue, 'true') then
        Result := TJSONBoolean.Create(True)
      else if SameText(AValue, 'false') then
        Result := TJSONBoolean.Create(False)
      else
        raise Exception.Create(MsgInvalidDefaultBoolean(AName));
  else
    raise Exception.Create(MsgInvalidOpenApiType(AName));
  end;
end;

function CanonicalSchemaJson(AData: TJSONData): string;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  Keys: TStringList;
  I: Integer;
  SB: TStringBuilder;
begin
  if AData = nil then
    Exit('null');

  if AData is TJSONObject then
  begin
    Obj := TJSONObject(AData);
    if Obj.Count = 0 then
      Exit('{}');
    Keys := TStringList.Create;
    SB := TStringBuilder.Create;
    try
      Keys.CaseSensitive := True;
      for I := 0 to Obj.Count - 1 do
        Keys.Add(Obj.Names[I]);
      Keys.Sort;
      SB.Append('{');
      for I := 0 to Keys.Count - 1 do
      begin
        if I > 0 then
          SB.Append(',');
        SB.Append('"');
        SB.Append(StringToJSONString(Keys[I]));
        SB.Append('":');
        SB.Append(CanonicalSchemaJson(Obj.Elements[Keys[I]]));
      end;
      SB.Append('}');
      Result := SB.ToString;
    finally
      SB.Free;
      Keys.Free;
    end;
  end
  else if AData is TJSONArray then
  begin
    Arr := TJSONArray(AData);
    if Arr.Count = 0 then
      Exit('[]');
    SB := TStringBuilder.Create;
    try
      SB.Append('[');
      for I := 0 to Arr.Count - 1 do
      begin
        if I > 0 then
          SB.Append(',');
        SB.Append(CanonicalSchemaJson(Arr.Items[I]));
      end;
      SB.Append(']');
      Result := SB.ToString;
    finally
      SB.Free;
    end;
  end
  else
    Result := AData.AsJSON;
end;

function IsDedupCandidateSchema(ANode: TJSONData): Boolean;
var
  Obj: TJSONObject;
  Props: TJSONData;
begin
  Result := False;
  if not (ANode is TJSONObject) then
    Exit;
  Obj := TJSONObject(ANode);
  if Obj.Find('$ref') <> nil then
    Exit;
  if not SameText(Obj.Get('type', ''), 'object') then
    Exit;
  Props := Obj.Find('properties');
  if (Props is TJSONObject) and (TJSONObject(Props).Count > 0) then
    Result := True;
end;

function SchemaContainsRefTo(ANode: TJSONData; const ATargetRef: string): Boolean;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  RefData: TJSONData;
begin
  Result := False;
  if ANode = nil then
    Exit;
  if ANode is TJSONObject then
  begin
    Obj := TJSONObject(ANode);
    RefData := Obj.Find('$ref');
    if (RefData <> nil) and (RefData.JSONType = jtString) and (RefData.AsString = ATargetRef) then
      Exit(True);
    for I := 0 to Obj.Count - 1 do
      if SchemaContainsRefTo(Obj.Items[I], ATargetRef) then
        Exit(True);
  end
  else if ANode is TJSONArray then
  begin
    Arr := TJSONArray(ANode);
    for I := 0 to Arr.Count - 1 do
      if SchemaContainsRefTo(Arr.Items[I], ATargetRef) then
        Exit(True);
  end;
end;

function ToPascalSchemaToken(const S: string): string;
var
  I: Integer;
  CapNext: Boolean;
  Ch: Char;
begin
  Result := '';
  CapNext := True;
  for I := 1 to Length(S) do
  begin
    Ch := S[I];
    if ((Ch >= 'a') and (Ch <= 'z')) or ((Ch >= 'A') and (Ch <= 'Z')) or ((Ch >= '0') and (Ch <= '9')) then
    begin
      if CapNext and (Ch >= 'a') and (Ch <= 'z') then
        Result := Result + UpCase(Ch)
      else
        Result := Result + Ch;
      CapNext := False;
    end
    else
      CapNext := True;
  end;
end;

function SuggestSemanticSchemaName(ANode: TJSONObject; const ACtxPath, ACtxRole: string;
  ASchemasObj: TJSONObject): string;
var
  Props, ListProp, ItemsObj: TJSONObject;
  RefVal, RefName, Suffix, CleanPath, BaseName, Cand: string;
  I, BraceDepth, Idx: Integer;
  Ch: Char;
begin
  Props := ANode.Find('properties') as TJSONObject;
  if Props <> nil then
  begin
    // Paginated or list envelope wrapping a $ref item
    for Idx := 0 to 1 do
    begin
      if Idx = 0 then
        ListProp := Props.Find('items') as TJSONObject
      else
        ListProp := Props.Find('data') as TJSONObject;
      if (ListProp <> nil) and SameText(ListProp.Get('type', ''), 'array') then
      begin
        ItemsObj := ListProp.Find('items') as TJSONObject;
        if (ItemsObj <> nil) and (ItemsObj.Find('$ref') <> nil) then
        begin
          RefVal := ItemsObj.Get('$ref', '');
          if RefVal.StartsWith('#/components/schemas/') then
          begin
            RefName := Copy(RefVal, Length('#/components/schemas/') + 1, MaxInt);
            if (Props.Find('total_records') <> nil) or (Props.Find('page_size') <> nil) then
              Suffix := 'PaginatedResponse'
            else
              Suffix := 'ListResponse';
            Cand := RefName + Suffix;
            if ASchemasObj.Find(Cand) = nil then
              Exit(Cand);
          end;
        end;
      end;
    end;

    // Canonical small shared envelopes
    if (Props.Count = 2) and (Props.Find('mensagem') <> nil) and (Props.Find('sucesso') <> nil) then
      if ASchemasObj.Find('MensagemSucessoResponse') = nil then
        Exit('MensagemSucessoResponse');

    if (Props.Count = 3) and (Props.Find('id') <> nil) and (Props.Find('mensagem') <> nil) and (Props.Find('status') <> nil) then
      if ASchemasObj.Find('OperacaoStatusResponse') = nil then
        Exit('OperacaoStatusResponse');
  end;

  // Replace {param} segments with ById
  CleanPath := '';
  BraceDepth := 0;
  for I := 1 to Length(ACtxPath) do
  begin
    Ch := ACtxPath[I];
    if Ch = '{' then
    begin
      if BraceDepth = 0 then
        CleanPath := CleanPath + '_ById_';
      Inc(BraceDepth);
    end
    else if Ch = '}' then
    begin
      if BraceDepth > 0 then
        Dec(BraceDepth);
    end
    else if BraceDepth = 0 then
      CleanPath := CleanPath + Ch;
  end;

  BaseName := ToPascalSchemaToken(CleanPath) + ToPascalSchemaToken(ACtxRole);
  if BaseName.IsEmpty then
    BaseName := 'SharedSchema';
  if (BaseName[1] >= '0') and (BaseName[1] <= '9') then
    BaseName := 'Schema' + BaseName;

  Cand := BaseName;
  Idx := 2;
  while ASchemasObj.Find(Cand) <> nil do
  begin
    Cand := BaseName + IntToStr(Idx);
    Inc(Idx);
  end;
  Result := Cand;
end;

function ReplaceKnownSchemasInTree(ANode: TJSONData; ACanonIndex, ANames: TStringList;
  ASchemasObj: TJSONObject; ASkipRoot: Boolean; const ASelfName: string): TJSONObject;
const
  COMBINATORS: array[0..2] of string = ('allOf', 'anyOf', 'oneOf');
var
  Obj, PropsObj, Repl: TJSONObject;
  Arr: TJSONArray;
  Child: TJSONData;
  I, CIdx, MapIdx: Integer;
  PropName, Canon, TargetName, SelfRef: string;
begin
  Result := nil;
  if not (ANode is TJSONObject) then
    Exit;
  Obj := TJSONObject(ANode);
  if Obj.Find('$ref') <> nil then
    Exit;

  // Bottom-up: process properties
  Child := Obj.Find('properties');
  if Child is TJSONObject then
  begin
    PropsObj := TJSONObject(Child);
    for I := 0 to PropsObj.Count - 1 do
    begin
      PropName := PropsObj.Names[I];
      Repl := ReplaceKnownSchemasInTree(PropsObj.Items[I], ACanonIndex, ANames, ASchemasObj, False, ASelfName);
      if Repl <> nil then
        PropsObj.Elements[PropName] := Repl;
    end;
  end;

  // Bottom-up: process items
  Child := Obj.Find('items');
  if Child is TJSONObject then
  begin
    Repl := ReplaceKnownSchemasInTree(Child, ACanonIndex, ANames, ASchemasObj, False, ASelfName);
    if Repl <> nil then
      Obj.Elements['items'] := Repl;
  end;

  // Bottom-up: process additionalProperties
  Child := Obj.Find('additionalProperties');
  if Child is TJSONObject then
  begin
    Repl := ReplaceKnownSchemasInTree(Child, ACanonIndex, ANames, ASchemasObj, False, ASelfName);
    if Repl <> nil then
      Obj.Elements['additionalProperties'] := Repl;
  end;

  // Bottom-up: process allOf / anyOf / oneOf
  for CIdx := Low(COMBINATORS) to High(COMBINATORS) do
  begin
    Child := Obj.Find(COMBINATORS[CIdx]);
    if Child is TJSONArray then
    begin
      Arr := TJSONArray(Child);
      for I := 0 to Arr.Count - 1 do
      begin
        Repl := ReplaceKnownSchemasInTree(Arr.Items[I], ACanonIndex, ANames, ASchemasObj, False, ASelfName);
        if Repl <> nil then
          Arr.Items[I] := Repl;
      end;
    end;
  end;

  if (not ASkipRoot) and IsDedupCandidateSchema(Obj) then
  begin
    Canon := CanonicalSchemaJson(Obj);
    if ACanonIndex.Find(Canon, MapIdx) then
    begin
      TargetName := ANames[PtrInt(ACanonIndex.Objects[MapIdx])];
      if TargetName <> ASelfName then
      begin
        SelfRef := '#/components/schemas/' + ASelfName;
        if (ASelfName = '') or (not SchemaContainsRefTo(ASchemasObj.Find(TargetName), SelfRef)) then
        begin
          Result := TJSONObject.Create;
          Result.Add('$ref', '#/components/schemas/' + TargetName);
        end;
      end;
    end;
  end;
end;

procedure CollectInlineSchemaCounts(ANode: TJSONData; const ACtxPath, ACtxRole: string;
  ASkipRoot: Boolean; ACountIndex: TStringList; AFirstPaths, AFirstRoles: TStringList;
  AFirstNodes: TFPList; var ACounts: TIntegerDynArray);
const
  COMBINATORS: array[0..2] of string = ('allOf', 'anyOf', 'oneOf');
var
  Obj, PropsObj: TJSONObject;
  Arr: TJSONArray;
  Child: TJSONData;
  I, CIdx, MapIdx, Slot: Integer;
  Canon: string;
begin
  if not (ANode is TJSONObject) then
    Exit;
  Obj := TJSONObject(ANode);
  if Obj.Find('$ref') <> nil then
    Exit;

  Child := Obj.Find('properties');
  if Child is TJSONObject then
  begin
    PropsObj := TJSONObject(Child);
    for I := 0 to PropsObj.Count - 1 do
      CollectInlineSchemaCounts(PropsObj.Items[I], ACtxPath + '_' + PropsObj.Names[I], ACtxRole,
        False, ACountIndex, AFirstPaths, AFirstRoles, AFirstNodes, ACounts);
  end;

  Child := Obj.Find('items');
  if Child is TJSONObject then
    CollectInlineSchemaCounts(Child, ACtxPath, ACtxRole + 'Item',
      False, ACountIndex, AFirstPaths, AFirstRoles, AFirstNodes, ACounts);

  Child := Obj.Find('additionalProperties');
  if Child is TJSONObject then
    CollectInlineSchemaCounts(Child, ACtxPath, ACtxRole + 'Entry',
      False, ACountIndex, AFirstPaths, AFirstRoles, AFirstNodes, ACounts);

  for CIdx := Low(COMBINATORS) to High(COMBINATORS) do
  begin
    Child := Obj.Find(COMBINATORS[CIdx]);
    if Child is TJSONArray then
    begin
      Arr := TJSONArray(Child);
      for I := 0 to Arr.Count - 1 do
        CollectInlineSchemaCounts(Arr.Items[I], ACtxPath, ACtxRole,
          False, ACountIndex, AFirstPaths, AFirstRoles, AFirstNodes, ACounts);
    end;
  end;

  if (not ASkipRoot) and IsDedupCandidateSchema(Obj) then
  begin
    Canon := CanonicalSchemaJson(Obj);
    if ACountIndex.Find(Canon, MapIdx) then
    begin
      Slot := PtrInt(ACountIndex.Objects[MapIdx]);
      Inc(ACounts[Slot]);
    end
    else
    begin
      Slot := Length(ACounts);
      SetLength(ACounts, Slot + 1);
      ACounts[Slot] := 1;
      AFirstPaths.Add(ACtxPath);
      AFirstRoles.Add(ACtxRole);
      AFirstNodes.Add(Obj);
      ACountIndex.AddObject(Canon, TObject(PtrInt(Slot)));
    end;
  end;
end;

procedure DeduplicateOpenAPISchemas(ADoc: TJSONObject);
const
  HTTP_METHODS: array[0..6] of string = ('get', 'post', 'put', 'delete', 'patch', 'head', 'options');
var
  ComponentsObj, SchemasObj, PathsObj, PathItemObj, OpObj, RbObj, ContentObj, MediaObj,
  ResponsesObj, RespObj, Repl: TJSONObject;
  CanonIndex, Names, CountIndex, FirstPaths, FirstRoles: TStringList;
  FirstNodes: TFPList;
  Counts: TIntegerDynArray;
  I, J, K, M, Iter, Promoted, MapIdx, Slot: Integer;
  SchemaName, PathStr, MethodStr, RespCode, Canon, NewName: string;

  procedure IndexCanonicalName(const ACanon, AName: string);
  var
    Idx, NameIdx: Integer;
  begin
    if not CanonIndex.Find(ACanon, Idx) then
    begin
      NameIdx := Names.Add(AName);
      CanonIndex.AddObject(ACanon, TObject(PtrInt(NameIdx)));
    end;
  end;

  procedure ReplaceAllInPaths;
  var
    PI, MI, CI, RI: Integer;
    PItem, Op, Rb, Cont, Med, Resps, Resp, SchemaRepl: TJSONObject;
    SchemaNode: TJSONData;
    MName: string;
  begin
    if PathsObj = nil then
      Exit;
    for PI := 0 to PathsObj.Count - 1 do
    begin
      if not (PathsObj.Items[PI] is TJSONObject) then
        Continue;
      PItem := TJSONObject(PathsObj.Items[PI]);
      for MI := 0 to PItem.Count - 1 do
      begin
        MName := LowerCase(PItem.Names[MI]);
        if (IndexText(MName, HTTP_METHODS) < 0) or not (PItem.Items[MI] is TJSONObject) then
          Continue;
        Op := TJSONObject(PItem.Items[MI]);

        Rb := Op.Find('requestBody') as TJSONObject;
        if Rb <> nil then
        begin
          Cont := Rb.Find('content') as TJSONObject;
          if Cont <> nil then
            for CI := 0 to Cont.Count - 1 do
              if Cont.Items[CI] is TJSONObject then
              begin
                Med := TJSONObject(Cont.Items[CI]);
                SchemaNode := Med.Find('schema');
                if SchemaNode is TJSONObject then
                begin
                  SchemaRepl := ReplaceKnownSchemasInTree(SchemaNode, CanonIndex, Names, SchemasObj, False, '');
                  if SchemaRepl <> nil then
                    Med.Elements['schema'] := SchemaRepl;
                end;
              end;
        end;

        Resps := Op.Find('responses') as TJSONObject;
        if Resps <> nil then
          for RI := 0 to Resps.Count - 1 do
            if Resps.Items[RI] is TJSONObject then
            begin
              Resp := TJSONObject(Resps.Items[RI]);
              Cont := Resp.Find('content') as TJSONObject;
              if Cont <> nil then
                for CI := 0 to Cont.Count - 1 do
                  if Cont.Items[CI] is TJSONObject then
                  begin
                    Med := TJSONObject(Cont.Items[CI]);
                    SchemaNode := Med.Find('schema');
                    if SchemaNode is TJSONObject then
                    begin
                      SchemaRepl := ReplaceKnownSchemasInTree(SchemaNode, CanonIndex, Names, SchemasObj, False, '');
                      if SchemaRepl <> nil then
                        Med.Elements['schema'] := SchemaRepl;
                    end;
                  end;
            end;
      end;
    end;
  end;

begin
  if ADoc = nil then
    Exit;
  PathsObj := ADoc.Find('paths') as TJSONObject;
  if PathsObj = nil then
    Exit;

  ComponentsObj := ADoc.Find('components') as TJSONObject;
  if ComponentsObj = nil then
  begin
    ComponentsObj := TJSONObject.Create;
    ADoc.Add('components', ComponentsObj);
  end;

  SchemasObj := ComponentsObj.Find('schemas') as TJSONObject;
  if SchemasObj = nil then
  begin
    SchemasObj := TJSONObject.Create;
    ComponentsObj.Add('schemas', SchemasObj);
  end;

  CanonIndex := TStringList.Create;
  Names := TStringList.Create;
  CountIndex := TStringList.Create;
  FirstPaths := TStringList.Create;
  FirstRoles := TStringList.Create;
  FirstNodes := TFPList.Create;
  try
    CanonIndex.CaseSensitive := True;
    CanonIndex.Sorted := True;
    CanonIndex.Duplicates := dupIgnore;

    CountIndex.CaseSensitive := True;
    CountIndex.Sorted := True;
    CountIndex.Duplicates := dupIgnore;

    // Step 1: Index all explicitly registered components.schemas
    for I := 0 to SchemasObj.Count - 1 do
    begin
      SchemaName := SchemasObj.Names[I];
      if SchemasObj.Items[I] is TJSONObject then
        IndexCanonicalName(CanonicalSchemaJson(SchemasObj.Items[I]), SchemaName);
    end;

    // Step 2: Compact existing components.schemas internally (sub-schemas -> $ref)
    for I := 0 to SchemasObj.Count - 1 do
    begin
      SchemaName := SchemasObj.Names[I];
      if SchemasObj.Items[I] is TJSONObject then
      begin
        ReplaceKnownSchemasInTree(SchemasObj.Items[I], CanonIndex, Names, SchemasObj, True, SchemaName);
        IndexCanonicalName(CanonicalSchemaJson(SchemasObj.Items[I]), SchemaName);
      end;
    end;

    // Step 3: Fixed-point deduplication loop
    for Iter := 1 to 5 do
    begin
      ReplaceAllInPaths;
      for I := 0 to SchemasObj.Count - 1 do
      begin
        SchemaName := SchemasObj.Names[I];
        if SchemasObj.Items[I] is TJSONObject then
        begin
          ReplaceKnownSchemasInTree(SchemasObj.Items[I], CanonIndex, Names, SchemasObj, True, SchemaName);
          IndexCanonicalName(CanonicalSchemaJson(SchemasObj.Items[I]), SchemaName);
        end;
      end;

      // Count remaining inline object schemas
      CountIndex.Clear;
      FirstPaths.Clear;
      FirstRoles.Clear;
      FirstNodes.Clear;
      SetLength(Counts, 0);

      for I := 0 to PathsObj.Count - 1 do
      begin
        if not (PathsObj.Items[I] is TJSONObject) then
          Continue;
        PathStr := PathsObj.Names[I];
        PathItemObj := TJSONObject(PathsObj.Items[I]);
        for M := 0 to PathItemObj.Count - 1 do
        begin
          MethodStr := LowerCase(PathItemObj.Names[M]);
          if (IndexText(MethodStr, HTTP_METHODS) < 0) or not (PathItemObj.Items[M] is TJSONObject) then
            Continue;
          OpObj := TJSONObject(PathItemObj.Items[M]);

          RbObj := OpObj.Find('requestBody') as TJSONObject;
          if RbObj <> nil then
          begin
            ContentObj := RbObj.Find('content') as TJSONObject;
            if ContentObj <> nil then
              for J := 0 to ContentObj.Count - 1 do
                if ContentObj.Items[J] is TJSONObject then
                begin
                  MediaObj := TJSONObject(ContentObj.Items[J]);
                  CollectInlineSchemaCounts(MediaObj.Find('schema'), PathStr, 'Request',
                    False, CountIndex, FirstPaths, FirstRoles, FirstNodes, Counts);
                end;
          end;

          ResponsesObj := OpObj.Find('responses') as TJSONObject;
          if ResponsesObj <> nil then
            for K := 0 to ResponsesObj.Count - 1 do
              if ResponsesObj.Items[K] is TJSONObject then
              begin
                RespCode := ResponsesObj.Names[K];
                RespObj := TJSONObject(ResponsesObj.Items[K]);
                ContentObj := RespObj.Find('content') as TJSONObject;
                if ContentObj <> nil then
                  for J := 0 to ContentObj.Count - 1 do
                    if ContentObj.Items[J] is TJSONObject then
                    begin
                      MediaObj := TJSONObject(ContentObj.Items[J]);
                      CollectInlineSchemaCounts(MediaObj.Find('schema'), PathStr, 'Response' + RespCode,
                        False, CountIndex, FirstPaths, FirstRoles, FirstNodes, Counts);
                    end;
              end;
        end;
      end;

      for I := 0 to SchemasObj.Count - 1 do
      begin
        SchemaName := SchemasObj.Names[I];
        if SchemasObj.Items[I] is TJSONObject then
          CollectInlineSchemaCounts(SchemasObj.Items[I], SchemaName, '',
            True, CountIndex, FirstPaths, FirstRoles, FirstNodes, Counts);
      end;

      Promoted := 0;
      for I := 0 to CountIndex.Count - 1 do
      begin
        Slot := PtrInt(CountIndex.Objects[I]);
        if Counts[Slot] >= 2 then
        begin
          Canon := CountIndex[I];
          if not CanonIndex.Find(Canon, MapIdx) then
          begin
            NewName := SuggestSemanticSchemaName(
              TJSONObject(FirstNodes[Slot]), FirstPaths[Slot], FirstRoles[Slot], SchemasObj);
            SchemasObj.Add(NewName, TJSONObject(FirstNodes[Slot]).Clone);
            IndexCanonicalName(Canon, NewName);
            Inc(Promoted);
          end;
        end;
      end;

      if Promoted = 0 then
        Break;
    end;

    // Final replacement pass
    ReplaceAllInPaths;
    for I := 0 to SchemasObj.Count - 1 do
    begin
      SchemaName := SchemasObj.Names[I];
      if SchemasObj.Items[I] is TJSONObject then
      begin
        Repl := ReplaceKnownSchemasInTree(SchemasObj.Items[I], CanonIndex, Names, SchemasObj, True, SchemaName);
        if Repl <> nil then
          Repl.Free;
      end;
    end;
  finally
    FirstNodes.Free;
    FirstRoles.Free;
    FirstPaths.Free;
    CountIndex.Free;
    Names.Free;
    CanonIndex.Free;
  end;
end;

function TSwaggerRouter.BuildOpenAPISpecification(const ABasePath: string): string;
var
  I, J, K, RouteIdx: Integer;
  Json, JsonInfo, JsonPaths, JsonURI, JsonMethod, SecurityItem: TJSONObject;
  SecurityArr, ServersArray: TJSONArray;
  Pattern, MethodStr, EffectiveBasePath, SortKey: string;
  Route: THTTPDocRoute;
  ActualMethod: TRouteMethod;
  RegEx: TRegExpr;
  SL, OperationIds, PathParams: TStringList;
begin
  EffectiveBasePath := ABasePath;
  FCacheLock.Acquire;
  try
    if not FDocCache.IsEmpty and
       (FDocCacheBasePath = EffectiveBasePath) then
    begin
      Result := FDocCache;
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
              raise Exception.Create(MsgRouteParamNotFound(Route.Params[J].Name, Route.URLPattern));

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
                raise Exception.Create(MsgDuplicateOperationId(OperationId));
              OperationIds.Add(OperationId);
              JsonMethod.Add('operationId', OperationId);
            end;
            JsonMethod.Add('deprecated', IsDeprecated);
            JsonMethod.Add('parameters', JsonParams);
            JsonMethod.Add('responses', JsonResponse);

            if (not BodyContent.Content.IsEmpty) or (Route.FBodyContents.Count > 0) then
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
            raise Exception.Create(MsgMethodNotDocumentable(Route.URLPattern));
          end;

          if JsonURI.Find(MethodStr) = nil then
            JsonURI.Add(MethodStr, JsonMethod)
          else
          begin
            JsonMethod.Free;
            raise Exception.Create(MsgDuplicateRoute(MethodStr, Pattern));
          end;
        end;
      finally
        PathParams.Free;
        OperationIds.Free;
        SL.Free;
        RegEx.Free;
      end;

      Json.Add('components', Components.ToJson);
      DeduplicateOpenAPISchemas(Json);

      FDocCache := Json.AsJSON;
      FDocCacheBasePath := EffectiveBasePath;
      Result := FDocCache;
      finally
        Json.Free;
      end;
    end;
  finally
    FCacheLock.Release;
  end;
end;

procedure Documentacao(AReq: TRequest; AResp: TResponse);
var
  EffectiveBasePath: string;
begin
  AResp.ContentType := 'application/json; charset=utf-8';
  EffectiveBasePath := SwaggerRouter.ResolveBasePath(AReq);
  AResp.Content := SwaggerRouter.BuildOpenAPISpecification(EffectiveBasePath);
  AResp.SendContent;
end;

var
  GSwaggerUILock: TCriticalSection = nil;
  GSwaggerUICacheKey: string = '';
  GSwaggerUIHtml: RawByteString = '';
  GSwaggerUIGzip: RawByteString = '';

function SwaggerGzipBytes(const ARaw: RawByteString): RawByteString;
const
  GZipHeader: array[0..9] of Byte = ($1F, $8B, $08, $00, $00, $00, $00, $00, $00, $FF);
var
  OutStream: TMemoryStream;
  ZipStream: TCompressionStream;
  CRC, TotalSize: LongWord;
  Trailer: array[0..1] of LongWord;
  I, J: Integer;
  C: LongWord;
begin
  Result := '';
  if Length(ARaw) = 0 then
    Exit;

  CRC := $FFFFFFFF;
  for I := 1 to Length(ARaw) do
  begin
    C := (CRC xor Byte(ARaw[I])) and $FF;
    for J := 0 to 7 do
      if (C and 1) <> 0 then
        C := $EDB88320 xor (C shr 1)
      else
        C := C shr 1;
    CRC := C xor (CRC shr 8);
  end;
  TotalSize := LongWord(Length(ARaw));

  OutStream := TMemoryStream.Create;
  try
    OutStream.WriteBuffer(GZipHeader, SizeOf(GZipHeader));
    ZipStream := TCompressionStream.Create(clDefault, OutStream, True);
    try
      ZipStream.WriteBuffer(ARaw[1], Length(ARaw));
    finally
      ZipStream.Free;
    end;
    Trailer[0] := NtoLE(CRC xor $FFFFFFFF);
    Trailer[1] := NtoLE(TotalSize);
    OutStream.WriteBuffer(Trailer, SizeOf(Trailer));
    SetLength(Result, OutStream.Size);
    if OutStream.Size > 0 then
    begin
      OutStream.Position := 0;
      OutStream.ReadBuffer(Result[1], OutStream.Size);
    end;
  finally
    OutStream.Free;
  end;
end;

procedure SwaggerUI(AReq: TRequest; AResp: TResponse);
var
  BasePath, JsonUrl, CacheKey, AE: string;
  HtmlBytes, GzipBytes: RawByteString;
  Stream: TMemoryStream;
begin
  BasePath := SwaggerRouter.ResolveBasePath(AReq);
  if SwaggerRouter.FDocRoute = '/' then
    JsonUrl := BasePath + '/openapi.json'
  else
    JsonUrl := BasePath + SwaggerRouter.FDocRoute + '/openapi.json';

  CacheKey := SwaggerRouter.Title + #0 + JsonUrl;

  GSwaggerUILock.Enter;
  try
    if GSwaggerUICacheKey <> CacheKey then
    begin
      GSwaggerUIHtml := RawByteString(
        '<!DOCTYPE html>' + LineEnding +
        '<html>' + LineEnding +
        '<head>' + LineEnding +
        '  <meta charset="UTF-8">' + LineEnding +
        '  <title>' + HtmlEscape(SwaggerRouter.Title) + ' - Swagger UI</title>' + LineEnding +
        '  <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">' + LineEnding +
        '</head>' + LineEnding +
        '<body>' + LineEnding +
        '  <div id="swagger-ui"></div>' + LineEnding +
        '  <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>' + LineEnding +
        '  <script>' + LineEnding +
        '    window.onload = function() {' + LineEnding +
        '      const ui = SwaggerUIBundle({' + LineEnding +
        '        url: ' + JavaScriptString(JsonUrl) + ',' + LineEnding +
        '        dom_id: "#swagger-ui",' + LineEnding +
        '        deepLinking: true,' + LineEnding +
        '        docExpansion: "none",' + LineEnding +
        '        filter: true,' + LineEnding +
        '        presets: [' + LineEnding +
        '          SwaggerUIBundle.presets.apis,' + LineEnding +
        '          SwaggerUIBundle.SwaggerUIStandalonePreset' + LineEnding +
        '        ]' + LineEnding +
        '      });' + LineEnding +
        '    };' + LineEnding +
        '  </script>' + LineEnding +
        '</body>' + LineEnding +
        '</html>' + LineEnding
      );
      GSwaggerUIGzip := SwaggerGzipBytes(GSwaggerUIHtml);
      GSwaggerUICacheKey := CacheKey;
    end;
    HtmlBytes := GSwaggerUIHtml;
    GzipBytes := GSwaggerUIGzip;
  finally
    GSwaggerUILock.Leave;
  end;

  AResp.ContentType := 'text/html; charset=utf-8';
  AResp.Contents.Clear;

  AE := LowerCase(Trim(AReq.AcceptEncoding));
  if AE = '' then
    AE := LowerCase(Trim(AReq.GetCustomHeader('Accept-Encoding')));

  if (Pos('gzip', AE) > 0) and (Length(GzipBytes) > 0) then
  begin
    Stream := TMemoryStream.Create;
    Stream.WriteBuffer(GzipBytes[1], Length(GzipBytes));
    Stream.Position := 0;
    AResp.FreeContentStream := True;
    AResp.ContentStream := Stream;
    AResp.ContentLength := Stream.Size;
    AResp.ContentEncoding := 'gzip';
  end
  else
    AResp.Content := string(HtmlBytes);
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

function THTTPRouterHelper.Options(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := RegisterDocRoute(APattern, rmOptions, ACallBack);
end;

function THTTPRouterHelper.Head(const APattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := RegisterDocRoute(APattern, rmHead, ACallBack);
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

{ TDocResponse }

constructor TDocResponse.Create;
begin
  inherited Create;
  FContents := TDocContentItemList.Create(True);
  FHeaders := TDocResponseHeaderList.Create(True);
  Code := '';
  Description := '';
  DocContent.ContentType := '';
  DocContent.Content := '';
  DocContent.Required := False;
  DocContent.Description := '';
end;

destructor TDocResponse.Destroy;
begin
  FHeaders.Free;
  FContents.Free;
  inherited Destroy;
end;

function TDocResponse.HasContentType(const AContentType: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to FContents.Count - 1 do
    if SameText(FContents[I].ContentType, AContentType) then
      Exit(True);
  if SameText(DocContent.ContentType, AContentType) and not DocContent.Content.IsEmpty then
    Exit(True);
end;

procedure TDocResponse.AddOrUpdateContent(const AContentType, AContent: string; const ADescription: string);
var
  I: Integer;
  Item: TDocContentItem;
begin
  for I := 0 to FContents.Count - 1 do
  begin
    if SameText(FContents[I].ContentType, AContentType) then
    begin
      FContents[I].Content := AContent;
      if not ADescription.IsEmpty then
        FContents[I].Description := ADescription;
      DocContent.ContentType := AContentType;
      DocContent.Content := AContent;
      Exit;
    end;
  end;

  Item := TDocContentItem.Create;
  Item.ContentType := AContentType;
  Item.Content := AContent;
  Item.Description := ADescription;
  FContents.Add(Item);

  if DocContent.ContentType.IsEmpty or (FContents.Count = 1) then
  begin
    DocContent.ContentType := AContentType;
    DocContent.Content := AContent;
  end;
end;

function TDocResponse.FindHeader(const AName: string): TDocResponseHeader;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FHeaders.Count - 1 do
    if SameText(FHeaders[I].Name, AName) then
      Exit(FHeaders[I]);
end;

procedure TDocResponse.AddOrUpdateHeader(const AName, AType: string; const ADescription: string; const ADefault: string);
var
  H: TDocResponseHeader;
begin
  H := FindHeader(AName);
  if H = nil then
  begin
    H := TDocResponseHeader.Create;
    H.Name := AName;
    FHeaders.Add(H);
  end;
  if not AType.IsEmpty then
    H.HeaderType := AType
  else if H.HeaderType.IsEmpty then
    H.HeaderType := 'string';
  if not ADescription.IsEmpty then
    H.Description := ADescription;
  if not ADefault.IsEmpty then
    H.DefaultValue := ADefault;
end;

{ THTTPDocRoute }

function THTTPDocRoute.GetPath: string;
begin
  Result := URLPattern;
  if not Result.StartsWith('/') then
    Result := '/' + Result;
  if (Length(Result) > 1) and Result.EndsWith('/') then
    Result := Copy(Result, 1, Length(Result) - 1);
end;

procedure THTTPDocRoute.Initialize;
begin
  FDocMethod := rmUnknown;
  FResponses := TResponseList.Create(True);
  FParams := TDocReqParamList.Create(True);
  FBodyContents := TDocContentItemList.Create(True);
  SetLength(FDefaultMediaTypes, 0);
  SetLength(FDefaultConsumesMediaTypes, 0);
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
  FBodyContents.Free;
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

function THTTPDocRoute.Summary: string;
begin
  Result := FSummary;
end;

function THTTPDocRoute.Summary(Text: string): THTTPDocRoute;
begin
  Result := SetSummary(Text);
end;

function THTTPDocRoute.Description: string;
begin
  Result := FDescription;
end;

function THTTPDocRoute.Description(Text: string): THTTPDocRoute;
begin
  Result := SetDescription(Text);
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
begin
  if SameText(Code, 'default') then
    Code := 'default'
  else if (StrToIntDef(Code, 0) < 100) or (StrToIntDef(Code, 0) > 599) or
          (IntToStr(StrToIntDef(Code, 0)) <> Code) then
    raise Exception.Create(MsgInvalidResponseCode(Code));
  if ContentType.Trim.IsEmpty then
    raise Exception.Create(MsgResponseContentTypeEmpty);

  Response := FindResponse(Code);
  if Response <> nil then
  begin
    if not ADescription.IsEmpty and Response.Description.IsEmpty then
      Response.Description := ADescription;
    Response.AddOrUpdateContent(ContentType, Content, ADescription);
  end
  else
  begin
    Response := TDocResponse.Create;
    Response.Code := Code;
    Response.Description := ADescription;
    Response.AddOrUpdateContent(ContentType, Content, ADescription);
    FResponses.Add(Response);
  end;
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

function THTTPDocRoute.FindResponse(const ACode: string): TDocResponse;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FResponses.Count - 1 do
    if SameText(FResponses[I].Code, ACode) then
      Exit(FResponses[I]);
end;

function THTTPDocRoute.FindResponse(ACode: Integer): TDocResponse;
begin
  Result := FindResponse(ACode.ToString);
end;

function THTTPDocRoute.JsonResponse: TJSONObject;
var
  R, R200Ghost: TDocResponse;
  Item, JsonCont, JsonHeaders, JsonSchema, HObj, HSchema: TJSONObject;
  ContentStr: string;
  I: Integer;
  CItem: TDocContentItem;
  H: TDocResponseHeader;
  HasAnyContent, HasOther2xx, RespHasContent: Boolean;
begin
  Result := TJSONObject.Create;
  try
    // Detect synthetic empty '200' response created solely by group/router EnableGzip
    // when the route declares another 2xx status (e.g. 201 Created or 204 No Content).
    R200Ghost := nil;
    HasOther2xx := False;
    for R in Responses do
    begin
      if (Length(R.Code) > 0) and (R.Code[1] = '2') then
      begin
        if R.Code <> '200' then
          HasOther2xx := True
        else
        begin
          RespHasContent := not Trim(R.DocContent.Content).IsEmpty;
          if not RespHasContent then
            for I := 0 to R.Contents.Count - 1 do
              if not Trim(R.Contents[I].Content).IsEmpty then
              begin
                RespHasContent := True;
                Break;
              end;
          if (not RespHasContent) and Trim(R.Description).IsEmpty then
            R200Ghost := R;
        end;
      end;
    end;
    if not HasOther2xx then
      R200Ghost := nil;

    for R in Responses do
    begin
      if R = R200Ghost then
        Continue;

      Item := TJSONObject.Create;
      try
        Item.Add('description', R.Description);

        // Check if this response has content
        HasAnyContent := False;
        if R.Contents.Count > 0 then
        begin
          for I := 0 to R.Contents.Count - 1 do
            if not Trim(R.Contents[I].Content).IsEmpty then
            begin
              HasAnyContent := True;
              Break;
            end;
        end
        else
          HasAnyContent := not Trim(R.DocContent.Content).IsEmpty;

        // Response Headers (RFC 7230, OpenAPI 3.1)
        // Propagate headers from suppressed synthetic 200 ghost (e.g. Content-Encoding: gzip)
        // to actual 2xx responses that carry a payload.
        if (R.Headers.Count > 0) or
           ((R200Ghost <> nil) and (R200Ghost.Headers.Count > 0) and HasAnyContent and
            (Length(R.Code) > 0) and (R.Code[1] = '2') and (R.Code <> '204')) then
        begin
          JsonHeaders := TJSONObject.Create;
          Item.Add('headers', JsonHeaders);
          for I := 0 to R.Headers.Count - 1 do
          begin
            H := R.Headers[I];
            HObj := TJSONObject.Create;
            JsonHeaders.Add(H.Name, HObj);
            if not H.Description.IsEmpty then
              HObj.Add('description', H.Description);
            HSchema := TJSONObject.Create;
            HObj.Add('schema', HSchema);
            if not H.HeaderType.IsEmpty then
              HSchema.Add('type', H.HeaderType)
            else
              HSchema.Add('type', 'string');
            if not H.DefaultValue.IsEmpty then
              HSchema.Add('default', H.DefaultValue);
          end;
          if (R200Ghost <> nil) and HasAnyContent and
             (Length(R.Code) > 0) and (R.Code[1] = '2') and (R.Code <> '204') then
          begin
            for I := 0 to R200Ghost.Headers.Count - 1 do
            begin
              H := R200Ghost.Headers[I];
              if JsonHeaders.Find(H.Name) = nil then
              begin
                HObj := TJSONObject.Create;
                JsonHeaders.Add(H.Name, HObj);
                if not H.Description.IsEmpty then
                  HObj.Add('description', H.Description);
                HSchema := TJSONObject.Create;
                HObj.Add('schema', HSchema);
                if not H.HeaderType.IsEmpty then
                  HSchema.Add('type', H.HeaderType)
                else
                  HSchema.Add('type', 'string');
                if not H.DefaultValue.IsEmpty then
                  HSchema.Add('default', H.DefaultValue);
              end;
            end;
          end;
        end;

        // Content Media Types
        if R.Contents.Count > 0 then
        begin
          if HasAnyContent then
          begin
            JsonCont := TJSONObject.Create;
            Item.Add('content', JsonCont);
            for I := 0 to R.Contents.Count - 1 do
            begin
              CItem := R.Contents[I];
              ContentStr := Trim(CItem.Content);
              if not ContentStr.IsEmpty then
              begin
                JsonSchema := TJSONObject.Create;
                JsonCont.Add(CItem.ContentType, JsonSchema);
                JsonSchema.Add('schema', JsonSchemaFromContent(ContentStr));
              end;
            end;
          end;
        end
        else
        begin
          ContentStr := Trim(R.DocContent.Content);
          if not ContentStr.IsEmpty then
          begin
            JsonCont := TJSONObject.Create;
            Item.Add('content', JsonCont);
            JsonSchema := TJSONObject.Create;
            JsonCont.Add(R.DocContent.ContentType, JsonSchema);
            JsonSchema.Add('schema', JsonSchemaFromContent(ContentStr));
          end;
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
    raise Exception.Create(MsgParamNameEmpty);
  if IndexText(ParamType, ['string', 'integer', 'number', 'boolean']) < 0 then
    raise Exception.Create(MsgInvalidParamType(ParamType));
  if (ParamIn = piPath) and not Required then
    raise Exception.Create(MsgPathParamMustBeRequired);
  for I := 0 to FParams.Count - 1 do
    if (FParams[I].ParamIn = ParamIn) and SameText(FParams[I].Name, AName) then
      raise Exception.Create(MsgDuplicateParam(AName));
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
    raise Exception.Create(MsgParamNameEmpty);
  if (ParamIn = piPath) and not Required then
    raise Exception.Create(MsgPathParamMustBeRequired);
  if Length(AValues) = 0 then
    raise Exception.Create(MsgEnumMustHaveValues);
  if (DefaultValue <> '') and (IndexStr(DefaultValue, AValues) < 0) then
    raise Exception.Create(MsgDefaultMustBeInEnum);
  for I := 0 to FParams.Count - 1 do
    if (FParams[I].ParamIn = ParamIn) and SameText(FParams[I].Name, AName) then
      raise Exception.Create(MsgDuplicateParam(AName));
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

function THTTPDocRoute.FindParam(const AName: string): TDocReqParam;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FParams.Count - 1 do
    if SameText(FParams[I].Name, AName) then
      Exit(FParams[I]);
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
var
  I: Integer;
  Found: Boolean;
  Item: TDocContentItem;
begin
  FBodyContent.Content := Content;
  FBodyContent.ContentType := ContentType;
  FBodyContent.Required := Required;
  FBodyContent.Description := ADescription;

  Found := False;
  for I := 0 to FBodyContents.Count - 1 do
  begin
    if SameText(FBodyContents[I].ContentType, ContentType) then
    begin
      FBodyContents[I].Content := Content;
      FBodyContents[I].Description := ADescription;
      Found := True;
      Break;
    end;
  end;

  if not Found then
  begin
    Item := TDocContentItem.Create;
    Item.ContentType := ContentType;
    Item.Content := Content;
    Item.Description := ADescription;
    FBodyContents.Add(Item);
  end;

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
  I: Integer;
  CItem: TDocContentItem;
begin
  Result := TJSONObject.Create;
  try
    JBody := TJSONObject.Create;
    Result.Add('content', JBody);

    if not FBodyContent.Description.IsEmpty then
      Result.Add('description', FBodyContent.Description);
    Result.Add('required', FBodyContent.Required);

    if FBodyContents.Count > 0 then
    begin
      for I := 0 to FBodyContents.Count - 1 do
      begin
        CItem := FBodyContents[I];
        JSchema := TJSONObject.Create;
        JBody.Add(CItem.ContentType, JSchema);
        ContentStr := Trim(CItem.Content);
        if not ContentStr.IsEmpty then
          JSchema.Add('schema', JsonSchemaFromContent(ContentStr));
      end;
    end
    else
    begin
      JSchema := TJSONObject.Create;
      JBody.Add(FBodyContent.ContentType, JSchema);
      ContentStr := Trim(FBodyContent.Content);
      if not ContentStr.IsEmpty then
        JSchema.Add('schema', JsonSchemaFromContent(ContentStr));
    end;
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
    raise Exception.Create(MsgApiKeyHeaderNameEmpty);
  if (ssApiKey in SwaggerRouter.Components.SecuritySchemes) and
     not SameText(SwaggerRouter.Components.ApiKeyHeaderName, HeaderName) then
    raise Exception.Create(MsgSingleApiKeyHeaderSupported);
  SwaggerRouter.Components.ApiKeyHeaderName := HeaderName;
  Result := SetSecurity(ssApiKey);
end;

function THTTPDocRoute.SetSecurityNone: THTTPDocRoute;
begin
  Result := SetSecurity(ssNone);
end;

function GetDefaultProblemDescription(ACode: Integer): string;
begin
  case ACode of
    400: Result := 'Bad Request';
    401: Result := 'Unauthorized';
    403: Result := 'Forbidden';
    404: Result := 'Not Found';
    405: Result := 'Method Not Allowed';
    409: Result := 'Conflict';
    422: Result := 'Unprocessable Entity';
    429: Result := 'Too Many Requests';
    500: Result := 'Internal Server Error';
    502: Result := 'Bad Gateway';
    503: Result := 'Service Unavailable';
  else
    Result := 'Problem Details';
  end;
end;

function THTTPDocRoute.Produces(Code: Integer; const AModelName: string; const ADescription: string): THTTPDocRoute;
var
  M: Integer;
begin
  if Length(FDefaultMediaTypes) > 0 then
  begin
    for M := Low(FDefaultMediaTypes) to High(FDefaultMediaTypes) do
      AddResponseRef(Code, AModelName, ADescription, FDefaultMediaTypes[M]);
    Result := Self;
  end
  else
    Result := AddResponseRef(Code, AModelName, ADescription, MEDIA_TYPE_JSON);
end;

function THTTPDocRoute.Produces(const AMediaTypes: array of string): THTTPDocRoute;
var
  M: Integer;
  LastResp: TDocResponse;
  ContentToClone: string;
begin
  if FResponses.Count > 0 then
  begin
    LastResp := FResponses[FResponses.Count - 1];
    ContentToClone := LastResp.DocContent.Content;
    for M := Low(AMediaTypes) to High(AMediaTypes) do
    begin
      if not LastResp.HasContentType(AMediaTypes[M]) then
        LastResp.AddOrUpdateContent(AMediaTypes[M], ContentToClone, LastResp.Description);
    end;
  end;
  InvalidateCache;
  Result := Self;
end;

function THTTPDocRoute.Produces(Code: Integer; const AModelName: string; const AMediaTypes: array of string; const ADescription: string): THTTPDocRoute;
var
  M: Integer;
begin
  if Length(AMediaTypes) = 0 then
    Result := Produces(Code, AModelName, ADescription)
  else
  begin
    for M := Low(AMediaTypes) to High(AMediaTypes) do
      AddResponseRef(Code, AModelName, ADescription, AMediaTypes[M]);
    Result := Self;
  end;
end;

function THTTPDocRoute.ProducesArray(Code: Integer; const AModelName: string; const ADescription: string): THTTPDocRoute;
var
  M: Integer;
begin
  if Length(FDefaultMediaTypes) > 0 then
  begin
    for M := Low(FDefaultMediaTypes) to High(FDefaultMediaTypes) do
      AddResponseRefArray(Code, AModelName, ADescription, FDefaultMediaTypes[M]);
    Result := Self;
  end
  else
    Result := AddResponseRefArray(Code, AModelName, ADescription, MEDIA_TYPE_JSON);
end;

function THTTPDocRoute.ProducesArray(Code: Integer; const AModelName: string; const AMediaTypes: array of string; const ADescription: string): THTTPDocRoute;
var
  M: Integer;
begin
  if Length(AMediaTypes) = 0 then
    Result := ProducesArray(Code, AModelName, ADescription)
  else
  begin
    for M := Low(AMediaTypes) to High(AMediaTypes) do
      AddResponseRefArray(Code, AModelName, ADescription, AMediaTypes[M]);
    Result := Self;
  end;
end;

function THTTPDocRoute.ProducesPaginated(Code: Integer; const AModelName: string; const ADescription: string): THTTPDocRoute;
var
  M: Integer;
begin
  if Length(FDefaultMediaTypes) > 0 then
  begin
    for M := Low(FDefaultMediaTypes) to High(FDefaultMediaTypes) do
      AddResponseRefPaginated(Code, AModelName, ADescription, FDefaultMediaTypes[M]);
    Result := Self;
  end
  else
    Result := AddResponseRefPaginated(Code, AModelName, ADescription, MEDIA_TYPE_JSON);
end;

function THTTPDocRoute.ProducesPaginated(Code: Integer; const AModelName: string; const AMediaTypes: array of string; const ADescription: string): THTTPDocRoute;
var
  M: Integer;
begin
  if Length(AMediaTypes) = 0 then
    Result := ProducesPaginated(Code, AModelName, ADescription)
  else
  begin
    for M := Low(AMediaTypes) to High(AMediaTypes) do
      AddResponseRefPaginated(Code, AModelName, ADescription, AMediaTypes[M]);
    Result := Self;
  end;
end;

function THTTPDocRoute.ProducesEmpty(Code: Integer; const ADescription: string): THTTPDocRoute;
var
  Desc: string;
begin
  Desc := ADescription;
  if Desc.IsEmpty then
  begin
    if Code = 204 then
      Desc := 'No Content'
    else
      Desc := 'Success';
  end;
  Result := AddResponse(Code, Desc, '', MEDIA_TYPE_JSON);
end;

function THTTPDocRoute.Consumes(const AModelName: string; Required: Boolean; const ADescription: string): THTTPDocRoute;
var
  M: Integer;
begin
  if Length(FDefaultConsumesMediaTypes) > 0 then
  begin
    for M := Low(FDefaultConsumesMediaTypes) to High(FDefaultConsumesMediaTypes) do
      SetBodyContentRef(AModelName, Required, FDefaultConsumesMediaTypes[M], ADescription);
    Result := Self;
  end
  else
    Result := SetBodyContentRef(AModelName, Required, MEDIA_TYPE_JSON, ADescription);
end;

function THTTPDocRoute.Consumes(const AModelName: string; const AMediaTypes: array of string; Required: Boolean; const ADescription: string): THTTPDocRoute;
var
  M: Integer;
begin
  if Length(AMediaTypes) = 0 then
    Result := Consumes(AModelName, Required, ADescription)
  else
  begin
    for M := Low(AMediaTypes) to High(AMediaTypes) do
      SetBodyContentRef(AModelName, Required, AMediaTypes[M], ADescription);
    Result := Self;
  end;
end;

function THTTPDocRoute.Consumes(const AMediaTypes: array of string): THTTPDocRoute;
var
  M: Integer;
  ExistingModel: string;
begin
  ExistingModel := '';
  if FBodyContents.Count > 0 then
    ExistingModel := FBodyContents[0].Content
  else if not FBodyContent.Content.IsEmpty then
    ExistingModel := FBodyContent.Content;

  for M := Low(AMediaTypes) to High(AMediaTypes) do
    SetBodyContent(ExistingModel, FBodyContent.Required, AMediaTypes[M], FBodyContent.Description);
  Result := Self;
end;

function THTTPDocRoute.ConsumesJson(const AModelName: string; Required: Boolean; const ADescription: string): THTTPDocRoute;
begin
  Result := SetBodyContentRef(AModelName, Required, MEDIA_TYPE_JSON, ADescription);
end;

function THTTPDocRoute.ConsumesFormData(const ADescription: string): THTTPDocRoute;
begin
  Result := SetBodyContent('', True, MEDIA_TYPE_FORM, ADescription);
end;

function THTTPDocRoute.ConsumesMultipart(const ADescription: string): THTTPDocRoute;
begin
  Result := SetBodyContent('', True, MEDIA_TYPE_MULTIPART, ADescription);
end;

function THTTPDocRoute.AcceptsGzip(Required: Boolean): THTTPDocRoute;
begin
  Result := AcceptsEncoding(ENCODING_GZIP, Required);
end;

function THTTPDocRoute.AcceptsEncoding(const AEncoding: string; Required: Boolean): THTTPDocRoute;
begin
  if FindParam('Accept-Encoding') = nil then
    Result := AddHeaderParam('Accept-Encoding', Required, 'string', AEncoding, 'Accepted content encoding (e.g. gzip, deflate)')
  else
    Result := Self;
end;

function THTTPDocRoute.ProducesEncoding(const AEncoding: string; Code: Integer): THTTPDocRoute;
begin
  Result := AddResponseHeader(Code, 'Content-Encoding', 'string', 'Payload compression format', AEncoding);
end;

function THTTPDocRoute.ProducesGzip(Code: Integer): THTTPDocRoute;
begin
  Result := ProducesEncoding(ENCODING_GZIP, Code);
end;

function THTTPDocRoute.AddResponseHeader(Code: Integer; const AName, AType: string; const ADescription: string; const ADefault: string): THTTPDocRoute;
begin
  Result := AddResponseHeader(Code.ToString, AName, AType, ADescription, ADefault);
end;

function THTTPDocRoute.AddResponseHeader(const ACode: string; const AName, AType: string; const ADescription: string; const ADefault: string): THTTPDocRoute;
var
  Resp: TDocResponse;
begin
  Resp := FindResponse(ACode);
  if Resp = nil then
  begin
    AddResponse(ACode, '', '', MEDIA_TYPE_JSON);
    Resp := FindResponse(ACode);
  end;
  if Resp <> nil then
    Resp.AddOrUpdateHeader(AName, AType, ADescription, ADefault);
  InvalidateCache;
  Result := Self;
end;

procedure THTTPDocRoute.SetDefaultMediaTypes(const AMediaTypes: array of string);
var
  I: Integer;
begin
  SetLength(FDefaultMediaTypes, Length(AMediaTypes));
  for I := Low(AMediaTypes) to High(AMediaTypes) do
    FDefaultMediaTypes[I - Low(AMediaTypes)] := AMediaTypes[I];
end;

procedure THTTPDocRoute.SetDefaultConsumesMediaTypes(const AMediaTypes: array of string);
var
  I: Integer;
begin
  SetLength(FDefaultConsumesMediaTypes, Length(AMediaTypes));
  for I := Low(AMediaTypes) to High(AMediaTypes) do
    FDefaultConsumesMediaTypes[I - Low(AMediaTypes)] := AMediaTypes[I];
end;

function THTTPDocRoute.ProducesProblem(ACode: Integer): THTTPDocRoute;
var
  I: Integer;
  CodeStr: string;
begin
  CodeStr := ACode.ToString;
  for I := 0 to Responses.Count - 1 do
    if SameText(Responses[I].Code, CodeStr) then
      Exit(Self);

  Result := AddResponseRef(ACode, 'ProblemDetails', GetDefaultProblemDescription(ACode), MEDIA_TYPE_PROBLEM_JSON);
end;

function THTTPDocRoute.ProducesProblem(ACode: Integer; const ADescription: string): THTTPDocRoute;
var
  I: Integer;
  CodeStr, Desc: string;
begin
  CodeStr := ACode.ToString;
  Desc := ADescription;
  if Desc = '' then
    Desc := GetDefaultProblemDescription(ACode);

  for I := 0 to Responses.Count - 1 do
    if SameText(Responses[I].Code, CodeStr) then
    begin
      Responses[I].Description := Desc;
      Exit(Self);
    end;

  Result := AddResponseRef(ACode, 'ProblemDetails', Desc, MEDIA_TYPE_PROBLEM_JSON);
end;

function THTTPDocRoute.ProducesProblem(const ACodes: array of Integer): THTTPDocRoute;
var
  C: Integer;
begin
  for C in ACodes do
    ProducesProblem(C);
  Result := Self;
end;

function THTTPDocRoute.ProducesStandardProblems: THTTPDocRoute;
begin
  Result := ProducesProblem([400, 401, 403, 404, 422, 500]);
end;

function THTTPDocRoute.QueryParam(const AName: string; const AType: string; const ADefault: string; const ADescription: string): THTTPDocRoute;
begin
  Result := AddQueryParam(AName, False, AType, ADefault, ADescription);
end;

function THTTPDocRoute.PathParam(const AName: string; const AType: string; const ADescription: string): THTTPDocRoute;
begin
  Result := AddPathParam(AName, True, AType, '', ADescription);
end;

function THTTPDocRoute.HeaderParam(const AName: string; const AType: string; Required: Boolean; const ADescription: string): THTTPDocRoute;
begin
  Result := AddHeaderParam(AName, Required, AType, '', ADescription);
end;

function THTTPDocRoute.EnumParam(const AName: string; const AValues: array of string; const ADescription: string): THTTPDocRoute;
begin
  Result := AddEnumParam(AName, AValues, False, piQuery, '', ADescription);
end;

function THTTPDocRoute.SecurityBearer: THTTPDocRoute;
begin
  Result := SetSecurityBearer;
end;

function THTTPDocRoute.SecurityBasic: THTTPDocRoute;
begin
  Result := SetSecurityBasic;
end;

function THTTPDocRoute.SecurityApiKey(const AHeader: string): THTTPDocRoute;
begin
  Result := SetSecurityApiKey(AHeader);
end;

function THTTPDocRoute.SecurityNone: THTTPDocRoute;
begin
  Result := SetSecurityNone;
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

const
  SCHEMA_PROBLEM_DETAILS =
    '{' +
    '  "type": "object",' +
    '  "properties": {' +
    '    "type": {"type": "string", "example": "about:blank"},' +
    '    "title": {"type": "string", "example": "Bad Request"},' +
    '    "status": {"type": "integer", "example": 400},' +
    '    "detail": {"type": "string", "example": "One or more validation errors occurred."},' +
    '    "instance": {"type": "string", "example": "/api/v1/resource/123"}' +
    '  },' +
    '  "required": ["type", "title", "status"]' +
    '}';

constructor TSwaggerRouter.Create;
begin
  inherited Create;
  FCacheLock := TCriticalSection.Create; // Initialize lock
  FGroups := TFPObjectList.Create(True);
  FDefaultCustomHeaders := TStringList.Create;
  SetLength(FDefaultMediaTypes, 0);
  SetLength(FDefaultConsumesMediaTypes, 0);
  SetLength(FDefaultEncodings, 0);
  FEnableGzip := False;
  FComponents := TSwaggerComponents.Create;
  FServers := TJSONArray.Create;
  FTitle := 'API';
  FVersion := '1.0.0';
  FBasePath := '';
  FDocRoute := '';
  FDocCache := '';
  FDocCacheBasePath := '';
  EnsureModel('ProblemDetails', SCHEMA_PROBLEM_DETAILS);
end;

destructor TSwaggerRouter.Destroy;
begin
  FGroups.Free;
  FComponents.Free;
  FDefaultCustomHeaders.Free;
  FServers.Free;
  if FContactObj <> nil then FContactObj.Free;
  if FLicenseObj <> nil then FLicenseObj.Free;
  FCacheLock.Free; // Release lock
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
var
  I: Integer;
begin
  FCacheLock.Acquire;
  try
    Result := HTTPRouter.RegisterDocRoute(APattern, AMethod, ACallBack, IsDefault);
    if Length(FDefaultMediaTypes) > 0 then
      Result.SetDefaultMediaTypes(FDefaultMediaTypes);
    if Length(FDefaultConsumesMediaTypes) > 0 then
      Result.SetDefaultConsumesMediaTypes(FDefaultConsumesMediaTypes);
    if FEnableGzip then
    begin
      Result.AcceptsGzip(False);
      Result.ProducesEncoding('gzip');
    end;
    for I := 0 to High(FDefaultEncodings) do
    begin
      Result.AcceptsEncoding(FDefaultEncodings[I], False);
      Result.ProducesEncoding(FDefaultEncodings[I]);
    end;
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

function TSwaggerRouter.Options(const APattern: string; ACallBack: TRouteCallBack
  ): THTTPDocRoute;
begin
  Result := RegisterRoute(APattern, rmOptions, ACallBack);
end;

function TSwaggerRouter.Head(const APattern: string; ACallBack: TRouteCallBack
  ): THTTPDocRoute;
begin
  Result := RegisterRoute(APattern, rmHead, ACallBack);
end;

function TSwaggerRouter.Group(const APrefix: string): TSwaggerRouteGroup;
begin
  Result := TSwaggerRouteGroup.Create(Self, APrefix);
  FGroups.Add(Result);
end;

{ TSwaggerRouteGroup }

constructor TSwaggerRouteGroup.Create(ARouter: TSwaggerRouter; const APrefix: string);
var
  Clean: string;
  I: Integer;
  RMedia, RConsumes, REncodings: TStringDynArray;
begin
  inherited Create;
  FRouter := ARouter;
  Clean := Trim(APrefix);
  if not Clean.StartsWith('/') then
    Clean := '/' + Clean;
  if (Length(Clean) > 1) and Clean.EndsWith('/') then
    Clean := Copy(Clean, 1, Length(Clean) - 1);
  FPrefix := Clean;
  FTag := '';
  FSecurity := ssNone;
  FApiKeyHeader := 'X-API-Key';
  FHasSecurity := False;
  SetLength(FProblemCodes, 0);

  FEnableGzip := False;
  if ARouter <> nil then
  begin
    FEnableGzip := ARouter.IsGzipEnabled;

    RMedia := ARouter.GetDefaultMediaTypes;
    SetLength(FDefaultMediaTypes, Length(RMedia));
    for I := 0 to High(RMedia) do
      FDefaultMediaTypes[I] := RMedia[I];

    RConsumes := ARouter.GetDefaultConsumesMediaTypes;
    SetLength(FDefaultConsumesMediaTypes, Length(RConsumes));
    for I := 0 to High(RConsumes) do
      FDefaultConsumesMediaTypes[I] := RConsumes[I];

    REncodings := ARouter.GetDefaultEncodings;
    SetLength(FDefaultEncodings, Length(REncodings));
    for I := 0 to High(REncodings) do
      FDefaultEncodings[I] := REncodings[I];
  end
  else
  begin
    SetLength(FDefaultMediaTypes, 0);
    SetLength(FDefaultConsumesMediaTypes, 0);
    SetLength(FDefaultEncodings, 0);
  end;
end;

function TSwaggerRouteGroup.CombinePath(const ASubPattern: string): string;
var
  CleanSub: string;
begin
  CleanSub := Trim(ASubPattern);
  if CleanSub = '/' then
    CleanSub := '';

  if CleanSub.IsEmpty then
    Result := FPrefix
  else if CleanSub.StartsWith('/') then
    Result := FPrefix + CleanSub
  else
    Result := FPrefix + '/' + CleanSub;
end;

function TSwaggerRouteGroup.ApplyGroupSettings(ARoute: THTTPDocRoute): THTTPDocRoute;
var
  I: Integer;
begin
  if not FTag.IsEmpty then
    ARoute.AddTag(FTag);

  if FHasSecurity then
  begin
    case FSecurity of
      ssBearer: ARoute.SetSecurityBearer;
      ssBasic:  ARoute.SetSecurityBasic;
      ssApiKey: ARoute.SetSecurityApiKey(FApiKeyHeader);
      ssNone:   ARoute.SetSecurityNone;
    end;
  end;

  for I := 0 to High(FProblemCodes) do
    ARoute.ProducesProblem(FProblemCodes[I]);

  if Length(FDefaultMediaTypes) > 0 then
    ARoute.SetDefaultMediaTypes(FDefaultMediaTypes);

  if Length(FDefaultConsumesMediaTypes) > 0 then
    ARoute.SetDefaultConsumesMediaTypes(FDefaultConsumesMediaTypes);

  if FEnableGzip then
  begin
    ARoute.AcceptsGzip(False);
    ARoute.ProducesEncoding('gzip');
  end;

  for I := 0 to High(FDefaultEncodings) do
  begin
    ARoute.AcceptsEncoding(FDefaultEncodings[I], False);
    ARoute.ProducesEncoding(FDefaultEncodings[I]);
  end;

  Result := ARoute;
end;

function TSwaggerRouteGroup.Tag(const ATag: string): TSwaggerRouteGroup;
begin
  FTag := ATag;
  Result := Self;
end;

function TSwaggerRouteGroup.Security(AScheme: TSecurityScheme): TSwaggerRouteGroup;
begin
  FSecurity := AScheme;
  FHasSecurity := True;
  Result := Self;
end;

function TSwaggerRouteGroup.SecurityBearer: TSwaggerRouteGroup;
begin
  Result := Security(ssBearer);
end;

function TSwaggerRouteGroup.SecurityBasic: TSwaggerRouteGroup;
begin
  Result := Security(ssBasic);
end;

function TSwaggerRouteGroup.SecurityApiKey(const AHeader: string): TSwaggerRouteGroup;
begin
  FApiKeyHeader := AHeader;
  Result := Security(ssApiKey);
end;

function TSwaggerRouteGroup.SecurityNone: TSwaggerRouteGroup;
begin
  Result := Security(ssNone);
end;

function TSwaggerRouteGroup.Problem(ACode: Integer): TSwaggerRouteGroup;
var
  Len, I: Integer;
begin
  for I := 0 to High(FProblemCodes) do
    if FProblemCodes[I] = ACode then
      Exit(Self);
  Len := Length(FProblemCodes);
  SetLength(FProblemCodes, Len + 1);
  FProblemCodes[Len] := ACode;
  Result := Self;
end;

function TSwaggerRouteGroup.StandardProblems: TSwaggerRouteGroup;
begin
  Problem(400);
  Problem(401);
  Problem(403);
  Problem(404);
  Problem(422);
  Problem(500);
  Result := Self;
end;

function TSwaggerRouteGroup.ProducesMediaTypes(const AMediaTypes: array of string): TSwaggerRouteGroup;
var
  I: Integer;
begin
  SetLength(FDefaultMediaTypes, Length(AMediaTypes));
  for I := Low(AMediaTypes) to High(AMediaTypes) do
    FDefaultMediaTypes[I - Low(AMediaTypes)] := AMediaTypes[I];
  Result := Self;
end;

function TSwaggerRouteGroup.ConsumesMediaTypes(const AMediaTypes: array of string): TSwaggerRouteGroup;
var
  I: Integer;
begin
  SetLength(FDefaultConsumesMediaTypes, Length(AMediaTypes));
  for I := Low(AMediaTypes) to High(AMediaTypes) do
    FDefaultConsumesMediaTypes[I - Low(AMediaTypes)] := AMediaTypes[I];
  Result := Self;
end;

function TSwaggerRouteGroup.AcceptsGzip(Required: Boolean): TSwaggerRouteGroup;
begin
  AcceptsEncoding(ENCODING_GZIP, Required);
  Result := Self;
end;

function TSwaggerRouteGroup.AcceptsEncoding(const AEncoding: string; Required: Boolean): TSwaggerRouteGroup;
var
  Len, I: Integer;
begin
  for I := 0 to High(FDefaultEncodings) do
    if SameText(FDefaultEncodings[I], AEncoding) then
      Exit(Self);
  Len := Length(FDefaultEncodings);
  SetLength(FDefaultEncodings, Len + 1);
  FDefaultEncodings[Len] := AEncoding;
  Result := Self;
end;

function TSwaggerRouteGroup.ProducesEncoding(const AEncoding: string): TSwaggerRouteGroup;
var
  Len, I: Integer;
begin
  for I := 0 to High(FDefaultEncodings) do
    if SameText(FDefaultEncodings[I], AEncoding) then
      Exit(Self);
  Len := Length(FDefaultEncodings);
  SetLength(FDefaultEncodings, Len + 1);
  FDefaultEncodings[Len] := AEncoding;
  Result := Self;
end;

function TSwaggerRouteGroup.EnableGzip(AEnabled: Boolean): TSwaggerRouteGroup;
begin
  FEnableGzip := AEnabled;
  Result := Self;
end;

function TSwaggerRouteGroup.Get(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := ApplyGroupSettings(FRouter.Get(CombinePath(ASubPattern), ACallBack));
end;

function TSwaggerRouteGroup.Post(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := ApplyGroupSettings(FRouter.Post(CombinePath(ASubPattern), ACallBack));
end;

function TSwaggerRouteGroup.Put(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := ApplyGroupSettings(FRouter.Put(CombinePath(ASubPattern), ACallBack));
end;

function TSwaggerRouteGroup.Delete(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := ApplyGroupSettings(FRouter.Delete(CombinePath(ASubPattern), ACallBack));
end;

function TSwaggerRouteGroup.Patch(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := ApplyGroupSettings(FRouter.Patch(CombinePath(ASubPattern), ACallBack));
end;

function TSwaggerRouteGroup.Options(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := ApplyGroupSettings(FRouter.Options(CombinePath(ASubPattern), ACallBack));
end;

function TSwaggerRouteGroup.Head(const ASubPattern: string; ACallBack: TRouteCallBack): THTTPDocRoute;
begin
  Result := ApplyGroupSettings(FRouter.Head(CombinePath(ASubPattern), ACallBack));
end;

function TSwaggerRouter.SetDefaultMediaTypes(const AMediaTypes: array of string): TSwaggerRouter;
var
  I: Integer;
begin
  SetLength(FDefaultMediaTypes, Length(AMediaTypes));
  for I := Low(AMediaTypes) to High(AMediaTypes) do
    FDefaultMediaTypes[I - Low(AMediaTypes)] := AMediaTypes[I];
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.SetDefaultConsumesMediaTypes(const AMediaTypes: array of string): TSwaggerRouter;
var
  I: Integer;
begin
  SetLength(FDefaultConsumesMediaTypes, Length(AMediaTypes));
  for I := Low(AMediaTypes) to High(AMediaTypes) do
    FDefaultConsumesMediaTypes[I - Low(AMediaTypes)] := AMediaTypes[I];
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.SetDefaultEncodings(const AEncodings: array of string): TSwaggerRouter;
var
  I: Integer;
begin
  SetLength(FDefaultEncodings, Length(AEncodings));
  for I := Low(AEncodings) to High(AEncodings) do
    FDefaultEncodings[I - Low(AEncodings)] := AEncodings[I];
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.EnableGzip(AEnabled: Boolean): TSwaggerRouter;
begin
  FEnableGzip := AEnabled;
  ClearCache;
  Result := Self;
end;

function TSwaggerRouter.IsGzipEnabled: Boolean;
begin
  Result := FEnableGzip;
end;

function TSwaggerRouter.GetDefaultMediaTypes: TStringDynArray;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(FDefaultMediaTypes));
  for I := 0 to High(FDefaultMediaTypes) do
    Result[I] := FDefaultMediaTypes[I];
end;

function TSwaggerRouter.GetDefaultConsumesMediaTypes: TStringDynArray;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(FDefaultConsumesMediaTypes));
  for I := 0 to High(FDefaultConsumesMediaTypes) do
    Result[I] := FDefaultConsumesMediaTypes[I];
end;

function TSwaggerRouter.GetDefaultEncodings: TStringDynArray;
var
  I: Integer;
begin
  Result := nil;
  SetLength(Result, Length(FDefaultEncodings));
  for I := 0 to High(FDefaultEncodings) do
    Result[I] := FDefaultEncodings[I];
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
    raise Exception.Create(MsgSchemaNameEmpty);
  end;
  if AModel = nil then
    raise Exception.Create(MsgSchemaCannotBeNil(AName));
  if AModel.JSONType <> jtObject then
  begin
    AModel.Free;
    raise Exception.Create(MsgSchemaMustBeJsonObject(AName));
  end;

  FCacheLock.Acquire;
  try
    Existing := FComponents.Models.Find(AName);
    if Existing <> nil then
    begin
      // Already registered: free AModel and do nothing (idempotent)
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
    raise Exception.Create(MsgSchemaNameEmpty);
  if AModel = nil then
    raise Exception.Create(MsgSchemaCannotBeNil(AName));
  if AModel.JSONType <> jtObject then
    raise Exception.Create(MsgSchemaMustBeJsonObject(AName));
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
        raise Exception.Create(MsgSchemaAlreadyRegistered(AName));
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
    raise Exception.Create(MsgInvalidPascalEnum(TypeInfoData^.Name));

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
    raise Exception.Create(MsgSwaggerRouteAlreadyRegistered);
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
  GSwaggerUILock := TCriticalSection.Create;
  if GetEnvironmentVariable('SWAGGER_LOCALE') <> '' then
    SetSwaggerLocaleByName(GetEnvironmentVariable('SWAGGER_LOCALE'))
  else if GetEnvironmentVariable('ZENITH_LOCALE') <> '' then
    SetSwaggerLocaleByName(GetEnvironmentVariable('ZENITH_LOCALE'));
  HTTPRouter := httproute.HTTPRouter;
  TSwaggerRouter.Initialize;

finalization
  SwaggerRouter.Free;
  FreeAndNil(GSwaggerUILock);

end.
