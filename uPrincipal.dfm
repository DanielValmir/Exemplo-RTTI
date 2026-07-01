object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  Caption = 'Exemplo RTTI + SQLite'
  ClientHeight = 391
  ClientWidth = 640
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object lblNome: TLabel
    Left = 8
    Top = 54
    Width = 31
    Height = 13
    Caption = 'Nome:'
  end
  object lblIdade: TLabel
    Left = 214
    Top = 54
    Width = 32
    Height = 13
    Caption = 'Idade:'
  end
  object lblData: TLabel
    Left = 300
    Top = 54
    Width = 85
    Height = 13
    Caption = 'Data Nascimento:'
  end
  object lblId: TLabel
    Left = 8
    Top = 8
    Width = 15
    Height = 13
    Caption = 'ID:'
  end
  object lblIdValor: TLabel
    Left = 233
    Top = 93
    Width = 3
    Height = 13
  end
  object edtNome: TEdit
    Left = 8
    Top = 73
    Width = 200
    Height = 21
    TabOrder = 0
  end
  object edtIdade: TEdit
    Left = 214
    Top = 73
    Width = 80
    Height = 21
    TabOrder = 1
  end
  object btnInserir: TButton
    Left = 8
    Top = 100
    Width = 90
    Height = 25
    Caption = 'Inserir'
    TabOrder = 2
    OnClick = btnInserirClick
  end
  object btnAlterar: TButton
    Left = 104
    Top = 100
    Width = 90
    Height = 25
    Caption = 'Alterar'
    TabOrder = 3
    OnClick = btnAlterarClick
  end
  object btnExcluir: TButton
    Left = 200
    Top = 100
    Width = 90
    Height = 25
    Caption = 'Excluir'
    TabOrder = 4
    OnClick = btnExcluirClick
  end
  object DBGrid: TDBGrid
    Left = 0
    Top = 135
    Width = 640
    Height = 256
    Align = alBottom
    DataSource = DataSource
    TabOrder = 5
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnCellClick = DBGridCellClick
    Columns = <
      item
        Expanded = False
        FieldName = 'ID'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'NOME'
        Title.Caption = 'Nome'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'IDADE'
        Title.Caption = 'Idade'
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'DATANASCIMENTO'
        Title.Caption = 'Data Nascimento'
        Width = 109
        Visible = True
      end>
  end
  object edtID: TEdit
    Left = 8
    Top = 27
    Width = 80
    Height = 21
    TabOrder = 6
  end
  object edtData: TDateTimePicker
    Left = 300
    Top = 73
    Width = 120
    Height = 21
    Date = 46199.000000000000000000
    Time = 0.496417766204103800
    TabOrder = 7
  end
  object FDConnection: TFDConnection
    Params.Strings = (
      'DriverID=SQLite')
    LoginPrompt = False
    Left = 64
    Top = 208
  end
  object FDQuery: TFDQuery
    Connection = FDConnection
    SQL.Strings = (
      'SELECT * FROM PESSOA')
    Left = 136
    Top = 208
    object FDQueryID: TFDAutoIncField
      FieldName = 'ID'
      Origin = 'ID'
      ProviderFlags = [pfInWhere, pfInKey]
      ReadOnly = False
    end
    object FDQueryNOME: TWideMemoField
      DisplayWidth = 20
      FieldName = 'NOME'
      Origin = 'NOME'
      BlobType = ftWideMemo
      DisplayValue = dvFullText
    end
    object FDQueryIDADE: TIntegerField
      FieldName = 'IDADE'
      Origin = 'IDADE'
    end
    object FDQueryDATANASCIMENTO: TWideMemoField
      FieldName = 'DATANASCIMENTO'
      Origin = 'DATANASCIMENTO'
      BlobType = ftWideMemo
      DisplayValue = dvFull
    end
  end
  object DataSource: TDataSource
    DataSet = FDQuery
    Left = 200
    Top = 208
  end
  object FDGUIxWaitCursor: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 64
    Top = 264
  end
end
