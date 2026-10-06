unit Backend.Delphi.Cadastro;

interface

uses
  System.SysUtils, System.Classes, Backend.Delphi.Connection, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
  FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
  FireDAC.Phys.PG, FireDAC.Phys.PGDef, FireDAC.ConsoleUI.Wait, FireDAC.Comp.UI,
  Data.DB, FireDAC.Comp.Client, FireDAC.Stan.Param, FireDAC.DatS,
  FireDAC.DApt.Intf, FireDAC.DApt, FireDAC.Comp.DataSet, System.JSON, System.Generics.Collections;

type
  TBackendDelphiCadastro = class(TBackendDelphiConnection)
    qryPesquisa: TFDQuery;
    qryRecordCount: TFDQuery;
    qryCadastro: TFDQuery;
    qryRecordCountCOUNT: TLargeintField;
  private
    procedure SetPagination(AQuery: TFDQuery; AQueryParams: TDictionary<string, string>);
    procedure SetOrdering(AQuery: TFDQuery; AQueryParams: TDictionary<string, string>);
  protected
    function GetQuerysPesquisa: TArray<TFDQuery>;
  public
    function GetRecordCount: Int64; virtual;
    function ListAll(AQueryParams: TDictionary<string, string>): TDataSet; virtual;
    function GetById(const AId: Variant): TDataSet; virtual;
    function Append(const AValue: TJSONObject): Boolean; virtual;
    function Update(const AValue: TJSONObject): Boolean; virtual;
    function Delete: Boolean; virtual;
  end;

var
  BackendDelphiCadastro: TBackendDelphiCadastro;

implementation

uses
  DataSet.Serialize;

{$R *.dfm}

{ TProviderCadastro }

function TBackendDelphiCadastro.Append(const AValue: TJSONObject): Boolean;
var
  LFieldName: string;
  I: Integer;
begin
  LFieldName := EmptyStr;
  for I := 0 to qryCadastro.Fields.Count - 1 do
  begin
    if (pfInKey in qryCadastro.Fields[I].ProviderFlags) then
      LFieldName := qryCadastro.Fields[I].FieldName;
  end;

  qryCadastro.FieldByName(LFieldName).ReadOnly := False;

  qryCadastro.SQL.Add('where 1 = 2');
  qryCadastro.Open();
  qryCadastro.LoadFromJSON(AValue, False);

  qryCadastro.FieldByName(LFieldName).ReadOnly := False;

  Result := True;
end;

function TBackendDelphiCadastro.Delete: Boolean;
begin
  qryCadastro.Delete;
  Result := True;
end;

function TBackendDelphiCadastro.GetById(const AId: Variant): TDataSet;
var
  LFieldName: string;
  I: Integer;
begin
  LFieldName := EmptyStr;
  for I := 0 to qryCadastro.Fields.Count - 1 do
  begin
    if (pfInKey in qryCadastro.Fields[I].ProviderFlags) then
      LFieldName := qryCadastro.Fields[I].FieldName;
  end;

  qryCadastro.SQL.Add(Format('where %s = :%s', [LFieldName, LFieldName]));
  qryCadastro.ParamByName(LFieldName).Value := AId;
  qryCadastro.Open();
  Result := qryCadastro;
end;

function TBackendDelphiCadastro.GetQuerysPesquisa: TArray<TFDQuery>;
begin
  Result := [qryPesquisa, qryRecordCount];
end;

function TBackendDelphiCadastro.GetRecordCount: Int64;
begin
  qryRecordCount.Open();
  Result := qryRecordCountCOUNT.AsLargeInt;
end;

function TBackendDelphiCadastro.ListAll(AQueryParams: TDictionary<string, string>): TDataSet;
begin
  Self.SetOrdering(qryPesquisa, AQueryParams);
  Self.SetPagination(qryPesquisa, AQueryParams);

  qryPesquisa.Open();
  Result := qryPesquisa;
end;

procedure TBackendDelphiCadastro.SetOrdering(AQuery: TFDQuery; AQueryParams: TDictionary<string, string>);
var
  LSQLOrdenacao: string;
  LOrdenacoes: TArray<string>;
  LOrdenacao: string;
  LDadosOrdenacao: TArray<string>;
  LFieldName: string;
  LTipoOrdenacao: string;
begin

  // Caso não tenha o query params sort ele sai
  if not AQueryParams.ContainsKey('sort') then
  begin
    Exit;
  end;

  // Cria o SQL de ordenação

  // Separa a query params sort por ;
  LOrdenacoes := AQueryParams.Items['sort'].Split([';']);

  // Faz um loop em cada registro separado por ;
  for LOrdenacao in LOrdenacoes do
  begin
    // separa o registro por ,
    LDadosOrdenacao := LOrdenacao.Split([',']);

    // Pega o primeiro elemento - que é o campo
    LFieldName := LDadosOrdenacao[0];

    // Checa se esse campo existe na query
    if Assigned(AQuery.Fields.FindField(LFieldName)) then
    begin

      // Insere virgula se o SQL de ordenação já tiver valor - para separar corretamente
      if not LSQLOrdenacao.Trim.IsEmpty then
      begin
        LSQLOrdenacao := LSQLOrdenacao + ', ';
      end;

      // Insere o campo no SQL de ordenação
      LSQLOrdenacao := LSQLOrdenacao + LFieldName;

      // Checa se tem o tipo de ordenação - asc / desc
      if Length(LDadosOrdenacao) = 2 then
      begin
        // Pega o segundo elemento - que é o tipo de ordenação
        LTipoOrdenacao := LDadosOrdenacao[1].Trim.ToLower;

        // Checa se é asc ou desc
        if LTipoOrdenacao.Equals('asc') or LTipoOrdenacao.Equals('desc') then
        begin
          // insere o tipo de ordenação - note que o campo já está no SQL de ordenação
          LSQLOrdenacao := LSQLOrdenacao + ' ' + LTipoOrdenacao;
        end;
      end;
    end;
  end;

  // Se o SQL de ordenação tiver valor ele coloca o order by com as ordenações  
  if not LSQLOrdenacao.Trim.IsEmpty then
  begin
    AQuery.SQL.Add('order by ' + LSQLOrdenacao);
  end;
  
end;

procedure TBackendDelphiCadastro.SetPagination(AQuery: TFDQuery; AQueryParams: TDictionary<string, string>);
begin
  if AQueryParams.ContainsKey('limit') then
  begin
    AQuery.FetchOptions.RecsMax := StrToIntDef(AQueryParams.Items['limit'], 50);
    AQuery.FetchOptions.RowsetSize := AQuery.FetchOptions.RecsMax;
  end;
  if AQueryParams.ContainsKey('offset') then
  begin
    AQuery.FetchOptions.RecsSkip := StrToIntDef(AQueryParams.Items['offset'], 0);
  end;
end;



function TBackendDelphiCadastro.Update(const AValue: TJSONObject): Boolean;
begin
  qryCadastro.MergeFromJSONObject(AValue, False);
  Result := True;
end;

end.
