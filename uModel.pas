unit uModel;

{
  Modelo de exemplo: TPessoa.
  Demonstra os 4 tipos suportados pelo dispatch RTTI do repositório:
  Integer, String, Double (Float) e TDateTime.
}

interface

uses
  System.SysUtils,
  Repository.Base;

type
  [TTable('PESSOA')]
  TPessoa = class
  strict private
    FId: Integer;
    FNome: string;
    FIdade: Integer;
    FDataNascimento: TDateTime;
  public
    [TColumn('ID', True)]
    property Id: Integer read FId write FId;

    [TColumn('NOME')]
    property Nome: string read FNome write FNome;

    [TColumn('IDADE')]
    property Idade: Integer read FIdade write FIdade;

    [TColumn('DATANASCIMENTO')]
    property DataNascimento: TDateTime read FDataNascimento write FDataNascimento;
  end;

implementation

end.
