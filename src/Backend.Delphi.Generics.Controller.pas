unit Backend.Delphi.Generics.Controller;

interface

uses Horse;

type
  IGenericController<T: class, constructor> = interface
    ['{FD521148-714F-453F-96D1-1320F871E26C}']
    procedure Registry(const AResource: string);
  end;

  TGenericController<T: Class, constructor> = class(TInterfacedObject, IGenericController<T>)
    private const
      NOT_FOUND: string = 'O registro não existe no banco de dados';
    private
      procedure DoListAll(Req: THorseRequest; Res: THorseResponse);
      procedure DoGetById(Req: THorseRequest; Res: THorseResponse);
      procedure DoAppend(Req: THorseRequest; Res: THorseResponse);
      procedure DoUpdate(Req: THorseRequest; Res: THorseResponse);
      procedure DoDelete(Req: THorseRequest; Res: THorseResponse);
      procedure Registry(const AResource: string);
    public
      class function New: IGenericController<T>;
  end;

implementation

uses Backend.Delphi.Cadastro, System.JSON, DataSet.Serialize, Data.Db;



class function TGenericController<T>.New: IGenericController<T>;
begin
  Result := TGenericController<T>.Create;
end;

procedure TGenericController<T>.DoListAll(Req: THorseRequest; Res: THorseResponse);
var
  LService: TBackendDelphiCadastro;
  LJSONObject: TJSONObject;
begin
  LService := TBackendDelphiCadastro(T.Create);
  try
    LJSONObject := TJSONObject.Create;
    LJSONObject.AddPair('data', LService.ListAll(Req.Query.Dictionary).ToJSONArray());
    LJSONObject.AddPair('records', TJSONNumber.Create(LService.GetRecordCount));

    Res.Send<TJSONObject>(LJSONObject);
  finally
    LService.Free;
  end;
end;

procedure TGenericController<T>.DoGetById(Req: THorseRequest; Res: THorseResponse);
var
  LService: TBackendDelphiCadastro;
begin
  LService := TBackendDelphiCadastro(T.Create);
  try
    if LService.GetById(Req.Params['id']).IsEmpty then
      raise EHorseException.New.Status(THTTPStatus.NotFound).Error(NOT_FOUND);

    Res.Send<TJSONObject>(LService.qryCadastro.ToJSONObject());

  finally
    LService.Free;
  end;
end;

procedure TGenericController<T>.DoAppend(Req: THorseRequest; Res: THorseResponse);
var
  LService: TBackendDelphiCadastro;
begin
  LService := TBackendDelphiCadastro(T.Create);
  try
    if LService.Append(Req.Body<TJSONObject>) then
      Res.Send<TJSONObject>(LService.qryCadastro.ToJSONObject()).Status(THTTPStatus.Created);

  finally
    LService.Free;
  end;
end;

procedure TGenericController<T>.DoUpdate(Req: THorseRequest; Res: THorseResponse);
var
  LService: TBackendDelphiCadastro;
begin
  LService := TBackendDelphiCadastro(T.Create);
  try
    if LService.GetById(Req.Params['id']).IsEmpty then
      raise EHorseException.New.Status(THTTPStatus.NotFound).Error(NOT_FOUND);

    if LService.Update(Req.Body<TJSONObject>) then
      Res.Status(THTTPStatus.NoContent);

  finally
    LService.Free;
  end;
end;

procedure TGenericController<T>.DoDelete(Req: THorseRequest; Res: THorseResponse);
var
  LService: TBackendDelphiCadastro;
begin
  LService := TBackendDelphiCadastro(T.Create);
  try
    if LService.GetById(Req.Params['id']).IsEmpty then
      raise EHorseException.New.Status(THTTPStatus.NotFound).Error(NOT_FOUND);

    if LService.Delete then
      Res.Status(THTTPStatus.NoContent);

  finally
    LService.Free;
  end;
end;

procedure TGenericController<T>.Registry(const AResource: string);
var
  LResourceId: string;
begin
  LResourceId := AResource + '/:id';
  THorse.Get(AResource, DoListAll);
  THorse.Get(LResourceId, DoGetById);
  THorse.Post(AResource, DoAppend);
  THorse.Put(LResourceId, DoUpdate);
  THorse.Delete(LResourceId, DoDelete);
end;

end.
