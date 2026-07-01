unit Repository.Base;

{
  Repositório genérico com CRUD dinâmico via RTTI.
  Adaptado de IBX/Firebird para FireDAC/SQLite.
  Uso: declare [TTable] na classe e [TColumn] em cada property mapeada.
}

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  FireDAC.Comp.Client,
  FireDAC.Stan.Param;

type
  /// <summary> Atributo que mapeia a classe ao nome da tabela no banco. </summary>
  TTableAttribute = class(TCustomAttribute)
  strict private
    FTableName: string;
  public
    constructor Create(const pTableName: string);
    property TableName: string read FTableName;
  end;

  /// <summary> Atributo que mapeia uma property ao nome da coluna no banco. </summary>
  TColumnAttribute = class(TCustomAttribute)
  strict private
    FColumnName: string;
    FIsPK: Boolean;
  public
    constructor Create(const pColumnName: string; const pIsPK: Boolean = False);
    property ColumnName: string read FColumnName;
    property IsPK: Boolean read FIsPK;
  end;

  /// <summary> Repositório genérico RTTI para FireDAC/SQLite. </summary>
  TRepository<T: class, constructor> = class
  strict private
    FCtx: TRttiContext;
    FConn: TFDConnection;  // conexão injetada no construtor (sem global)

    /// <summary> Lê o atributo [TTable] da classe T e retorna o nome da tabela. </summary>
    function ObterNomeTabela: string;

    /// <summary> Percorre as properties de T procurando [TColumn] com IsPK=True. </summary>
    function ObterColunaPK: string;

    /// <summary> Atribui valor ao parâmetro com dispatch pelo tipo RTTI (Integer/String/Float/DateTime). </summary>
    procedure AtribuirParam(const pQry: TFDQuery; const pNomeParam: string; const pValor: TValue);

  protected
    /// <summary> Cria um TFDQuery vinculado à conexão injetada. </summary>
    function CriarQuery: TFDQuery;

  public
    constructor Create(const pConn: TFDConnection);
    destructor Destroy; override;

    /// <summary> Insere a entidade via RTTI. Colunas IsPK=True são omitidas (AUTOINCREMENT). </summary>
    procedure Inserir(const pEntidade: T); virtual;

    /// <summary> Atualiza a entidade via RTTI. SET em colunas não-PK; WHERE na coluna PK. </summary>
    procedure Alterar(const pEntidade: T); virtual;

    /// <summary> Exclui o registro pelo código (valor da coluna PK). </summary>
    procedure Excluir(const pCodigo: Integer); virtual;
  end;

implementation

{ TTableAttribute }

constructor TTableAttribute.Create(const pTableName: string);
begin
  inherited Create;
  FTableName := pTableName;
end;

{ TColumnAttribute }

constructor TColumnAttribute.Create(const pColumnName: string; const pIsPK: Boolean);
begin
  inherited Create;
  FColumnName := pColumnName;
  FIsPK := pIsPK;
end;

{ TRepository<T> }

constructor TRepository<T>.Create(const pConn: TFDConnection);
begin
  inherited Create;
  FConn := pConn;
  FCtx := TRttiContext.Create;
end;

destructor TRepository<T>.Destroy;
begin
  FCtx.Free;
  inherited Destroy;
end;

function TRepository<T>.CriarQuery: TFDQuery;
var
  lQry: TFDQuery;
begin
  lQry := TFDQuery.Create(nil);
  try
    lQry.Connection := FConn;
    Result := lQry;
  except
    lQry.Free;
    raise;
  end;
end;

function TRepository<T>.ObterNomeTabela: string;
var
  lType: TRttiType;
  lAttr: TCustomAttribute;
begin
  Result := '';
  // RTTI: obtém o tipo da classe T e percorre seus atributos de classe
  lType := FCtx.GetType(T);
  for lAttr in lType.GetAttributes do
  begin
    if lAttr is TTableAttribute then
    begin
      Result := TTableAttribute(lAttr).TableName;
      Exit;
    end;
  end;

  if Result = '' then
    raise EArgumentException.CreateFmt('Classe %s não possui o atributo [TTable].', [T.ClassName]);
end;

function TRepository<T>.ObterColunaPK: string;
var
  lType: TRttiType;
  lProp: TRttiProperty;
  lAttr: TCustomAttribute;
  lColAttr: TColumnAttribute;
begin
  Result := '';
  // RTTI: percorre todas as properties de T procurando [TColumn] com IsPK=True
  lType := FCtx.GetType(T);
  for lProp in lType.GetProperties do
  begin
    for lAttr in lProp.GetAttributes do
    begin
      if lAttr is TColumnAttribute then
      begin
        lColAttr := TColumnAttribute(lAttr);
        if lColAttr.IsPK then
        begin
          Result := UpperCase(lColAttr.ColumnName);
          Exit;
        end;
      end;
    end;
  end;

  if Result = '' then
    raise EArgumentException.CreateFmt('Classe %s não possui coluna com IsPK=True.', [T.ClassName]);
end;

procedure TRepository<T>.AtribuirParam(const pQry: TFDQuery; const pNomeParam: string; const pValor: TValue);
begin
  // RTTI: pValor.Kind indica o tipo Pascal da property; cada branch popula o param corretamente
  case pValor.Kind of
    tkInteger, tkInt64:
      pQry.ParamByName(pNomeParam).AsInteger := pValor.AsInteger;

    tkString, tkUString, tkLString, tkWString:
      pQry.ParamByName(pNomeParam).AsString := pValor.AsString;

    tkFloat:
      // TDateTime é armazenado como tkFloat; distinguimos pelo TypeInfo
      if pValor.TypeInfo = TypeInfo(TDateTime) then
        pQry.ParamByName(pNomeParam).AsDateTime := pValor.AsExtended
      else
        pQry.ParamByName(pNomeParam).AsFloat := pValor.AsExtended;
  end;
end;

procedure TRepository<T>.Inserir(const pEntidade: T);
var
  lType: TRttiType;
  lProp: TRttiProperty;
  lAttr: TCustomAttribute;
  lColAttr: TColumnAttribute;
  lCampos: string;
  lParams: string;
  lSQL: string;
  lTabela: string;
  lQry: TFDQuery;
begin
  lTabela := ObterNomeTabela;   // lê [TTable] da classe
  lType := FCtx.GetType(T);
  lCampos := '';
  lParams := '';

  // RTTI: monta as listas de colunas e parâmetros percorrendo as properties
  for lProp in lType.GetProperties do
  begin
    for lAttr in lProp.GetAttributes do
    begin
      if lAttr is TColumnAttribute then
      begin
        lColAttr := TColumnAttribute(lAttr);
        if not lColAttr.IsPK then  // omite PK — SQLite gera via AUTOINCREMENT
        begin
          lCampos := lCampos + UpperCase(lColAttr.ColumnName) + ', ';
          lParams := lParams + ':' + UpperCase(lColAttr.ColumnName) + ', ';
        end;
      end;
    end;
  end;

  if lCampos = '' then
    raise EArgumentException.CreateFmt('Nenhuma coluna mapeada para INSERT em %s.', [T.ClassName]);

  // remove a última vírgula+espaço
  lCampos := Copy(lCampos, 1, Length(lCampos) - 2);
  lParams := Copy(lParams, 1, Length(lParams) - 2);

  // SQL montado dinamicamente: INSERT INTO PESSOA (NOME, IDADE, ...) VALUES (:NOME, :IDADE, ...)
  lSQL := Format('INSERT INTO %s (%s) VALUES (%s)', [lTabela, lCampos, lParams]);

  lQry := CriarQuery;
  try
    try
      lQry.SQL.Text := lSQL;

      // RTTI: segunda passagem — atribui os valores reais de cada property ao parâmetro
      for lProp in lType.GetProperties do
      begin
        for lAttr in lProp.GetAttributes do
        begin
          if lAttr is TColumnAttribute then
          begin
            lColAttr := TColumnAttribute(lAttr);
            if not lColAttr.IsPK then
              AtribuirParam(lQry, UpperCase(lColAttr.ColumnName), lProp.GetValue(TObject(pEntidade)));
          end;
        end;
      end;

      FConn.StartTransaction;
      lQry.ExecSQL;
      FConn.Commit;
    except
      on E: Exception do
      begin
        if FConn.InTransaction then
          FConn.Rollback;
        raise Exception.CreateFmt('Erro ao inserir em %s: %s', [lTabela, E.Message]);
      end;
    end;
  finally
    lQry.Free;
  end;
end;

procedure TRepository<T>.Alterar(const pEntidade: T);
var
  lType: TRttiType;
  lProp: TRttiProperty;
  lAttr: TCustomAttribute;
  lColAttr: TColumnAttribute;
  lSet: string;
  lSQL: string;
  lTabela: string;
  lPKCol: string;
  lQry: TFDQuery;
begin
  lTabela := ObterNomeTabela;
  lPKCol := ObterColunaPK;
  lType := FCtx.GetType(T);
  lSet := '';

  // RTTI: monta a cláusula SET para cada coluna não-PK
  for lProp in lType.GetProperties do
  begin
    for lAttr in lProp.GetAttributes do
    begin
      if lAttr is TColumnAttribute then
      begin
        lColAttr := TColumnAttribute(lAttr);
        if not lColAttr.IsPK then
          lSet := lSet + UpperCase(lColAttr.ColumnName) + ' = :' + UpperCase(lColAttr.ColumnName) + ', ';
      end;
    end;
  end;

  if lSet = '' then
    raise EArgumentException.CreateFmt('Nenhuma coluna mapeada para UPDATE em %s.', [T.ClassName]);

  lSet := Copy(lSet, 1, Length(lSet) - 2);

  // SQL: UPDATE PESSOA SET NOME = :NOME, ... WHERE ID = :ID
  lSQL := Format('UPDATE %s SET %s WHERE %s = :%s', [lTabela, lSet, lPKCol, lPKCol]);

  lQry := CriarQuery;
  try
    try
      lQry.SQL.Text := lSQL;

      // RTTI: atribui todos os valores (incluindo PK para o WHERE)
      for lProp in lType.GetProperties do
      begin
        for lAttr in lProp.GetAttributes do
        begin
          if lAttr is TColumnAttribute then
          begin
            lColAttr := TColumnAttribute(lAttr);
            AtribuirParam(lQry, UpperCase(lColAttr.ColumnName), lProp.GetValue(TObject(pEntidade)));
          end;
        end;
      end;

      FConn.StartTransaction;
      lQry.ExecSQL;
      FConn.Commit;
    except
      on E: Exception do
      begin
        if FConn.InTransaction then
          FConn.Rollback;
        raise Exception.CreateFmt('Erro ao alterar em %s: %s', [lTabela, E.Message]);
      end;
    end;
  finally
    lQry.Free;
  end;
end;

procedure TRepository<T>.Excluir(const pCodigo: Integer);
var
  lQry: TFDQuery;
  lSQL: string;
  lTabela: string;
  lPKCol: string;
begin
  lTabela := ObterNomeTabela;
  lPKCol := ObterColunaPK;

  // SQL: DELETE FROM PESSOA WHERE ID = :ID
  lSQL := Format('DELETE FROM %s WHERE %s = :%s', [lTabela, lPKCol, lPKCol]);

  lQry := CriarQuery;
  try
    try
      lQry.SQL.Text := lSQL;
      lQry.ParamByName(lPKCol).AsInteger := pCodigo;

      FConn.StartTransaction;
      lQry.ExecSQL;
      FConn.Commit;
    except
      on E: Exception do
      begin
        if FConn.InTransaction then
          FConn.Rollback;
        raise Exception.CreateFmt('Erro ao excluir de %s: %s', [lTabela, E.Message]);
      end;
    end;
  finally
    lQry.Free;
  end;
end;

end.
