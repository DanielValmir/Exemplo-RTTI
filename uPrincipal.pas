unit uPrincipal;

{
  Form principal do exemplo RTTI + SQLite.
  Responsabilidades:
    1. Criar e abrir a conexão FireDAC/SQLite (banco dados.db ao lado do .exe).
    2. Garantir que a tabela PESSOA existe (CREATE TABLE IF NOT EXISTS).
    3. Expor campos de edição e botões Inserir/Alterar/Excluir que
       passam pelo TRepository<TPessoa> (RTTI).
    4. Exibir o resultado em um DBGrid via TFDQuery SELECT.
}

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.DateUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.Grids,
  Vcl.DBGrids,
  Data.DB,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteDef,
  FireDAC.Stan.ExprFuncs,
  FireDAC.VCLUI.Wait,
  FireDAC.Comp.Client,
  FireDAC.Comp.DataSet,
  FireDAC.Stan.Param,
  FireDAC.DatS,
  FireDAC.DApt.Intf,
  FireDAC.DApt,
  FireDAC.Comp.UI,
  Repository.Base,
  uModel,
  Vcl.ComCtrls,
  FireDAC.Phys.SQLiteWrapper.Stat;

type
  TfrmPrincipal = class(TForm)
    FDConnection: TFDConnection;
    FDQuery: TFDQuery;
    DataSource: TDataSource;
    FDGUIxWaitCursor: TFDGUIxWaitCursor;
    DBGrid: TDBGrid;
    lblId: TLabel;
    edtNome: TEdit;
    edtIdade: TEdit;
    lblNome: TLabel;
    lblIdade: TLabel;
    lblData: TLabel;
    lblIdValor: TLabel;
    btnInserir: TButton;
    btnAlterar: TButton;
    btnExcluir: TButton;
    edtID: TEdit;
    edtData: TDateTimePicker;
    FDQueryID: TFDAutoIncField;
    FDQueryNOME: TWideMemoField;
    FDQueryIDADE: TIntegerField;
    FDQueryDATANASCIMENTO: TWideMemoField;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInserirClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure DBGridCellClick(Column: TColumn);
  private
    FRepo: TRepository<TPessoa>;
    procedure AbrirConexao;
    procedure CriarSchema;
    procedure AtualizarGrid;
    function LerIdSelecionado: Integer;
    function MontarPessoa: TPessoa;
  end;

var
  frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
  ReportMemoryLeaksOnShutdown := True;
  AbrirConexao;
  CriarSchema;
  FRepo := TRepository<TPessoa>.Create(FDConnection);
  AtualizarGrid;
end;

procedure TfrmPrincipal.FormDestroy(Sender: TObject);
begin
  FRepo.Free;
end;

procedure TfrmPrincipal.AbrirConexao;
var
  lDbPath: string;
begin
  // banco criado ao lado do executável; SQLite cria o arquivo se não existir
  lDbPath := ExtractFilePath(Application.ExeName) + 'dados.db';
  FDConnection.DriverName := 'SQLite';
  FDConnection.Params.Values['Database'] := lDbPath;
  FDConnection.Open;
end;

procedure TfrmPrincipal.CriarSchema;
const
  // TEXT para DATANASCIMENTO: SQLite não tem tipo date nativo; FireDAC converte
  SQL_CREATE =
    'CREATE TABLE IF NOT EXISTS PESSOA (' +
    '  ID INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  NOME TEXT,' +
    '  IDADE INTEGER,' +
    '  DATANASCIMENTO TEXT' +
    ')';
begin
  FDConnection.ExecSQL(SQL_CREATE);
end;

procedure TfrmPrincipal.DBGridCellClick(Column: TColumn);
begin
  // preenche os edits e o label de ID com o registro clicado no grid
  if FDQuery.IsEmpty then
    Exit;

  edtID.Text := FDQuery.FieldByName('ID').AsString;
  edtNome.Text := FDQuery.FieldByName('NOME').AsString;
  edtIdade.Text := FDQuery.FieldByName('IDADE').AsString;
  edtData.Date := ISO8601ToDate(FDQuery.FieldByName('DATANASCIMENTO').AsString, False);
end;

procedure TfrmPrincipal.AtualizarGrid;
begin
  // leitura direta via SELECT — não passa pelo RTTI, só exibe o resultado
  FDQuery.Close;
  FDQuery.SQL.Text := 'SELECT * FROM PESSOA';
  FDQuery.Open;
end;

function TfrmPrincipal.LerIdSelecionado: Integer;
begin
  if FDQuery.IsEmpty then
    raise Exception.Create('Nenhum registro selecionado no grid.');

  Result := FDQuery.FieldByName('ID').AsInteger;
end;

function TfrmPrincipal.MontarPessoa: TPessoa;
begin
  // caminho: edits → objeto TPessoa → repositório RTTI → banco
  Result := TPessoa.Create;
  Result.Nome  := edtNome.Text;
  Result.Idade := StrToIntDef(edtIdade.Text, 0);
  Result.DataNascimento := edtData.Date;
end;

procedure TfrmPrincipal.btnInserirClick(Sender: TObject);
var
  lPessoa: TPessoa;
begin
  // monta TPessoa a partir dos campos → TRepository<TPessoa>.Inserir monta o SQL via RTTI
  lPessoa := MontarPessoa;
  try
    FRepo.Inserir(lPessoa);
  finally
    lPessoa.Free;
  end;
  AtualizarGrid;
end;

procedure TfrmPrincipal.btnAlterarClick(Sender: TObject);
var
  lPessoa: TPessoa;
begin
  // precisa do ID do registro selecionado para o WHERE do UPDATE
  lPessoa := MontarPessoa;
  try
    lPessoa.Id := LerIdSelecionado;
    FRepo.Alterar(lPessoa);
  finally
    lPessoa.Free;
  end;
  AtualizarGrid;
end;

procedure TfrmPrincipal.btnExcluirClick(Sender: TObject);
begin
  // passa só o ID; o repositório monta DELETE FROM PESSOA WHERE ID = :ID via RTTI
  FRepo.Excluir(LerIdSelecionado);
  AtualizarGrid;
  lblIdValor.Caption := '';
end;

end.
