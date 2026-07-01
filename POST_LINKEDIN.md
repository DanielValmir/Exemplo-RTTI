**Você escreve INSERT, UPDATE e DELETE para cada tabela do sistema. Agora multiplica por 40 tabelas.**

Esse ciclo mata a produtividade de qualquer dev. Em Delphi dá pra quebrar ele com RTTI — e o código fica menor do que parece.

A ideia: anota o model com atributos e deixa o repositório montar o SQL em tempo de execução. **Uma vez pronto, o mesmo `TRepository<T>` serve para qualquer entidade do seu sistema.**

```delphi
{ Qualquer model.pas — só declaração, zero SQL }
[TTable('PESSOA')]
TPessoa = class
  [TColumn('ID', True)]   // IsPK = True → omitido no INSERT
  property Id: Integer ...
  [TColumn('NOME')]
  property Nome: string ...
  [TColumn('DATANASCIMENTO')]
  property DataNascimento: TDateTime ...
end;

[TTable('PRODUTO')]  // Outro model — MESMO repositório!
TProduto = class
  [TColumn('IDPRODUTO', True)]
  property IdProduto: Integer ...
  [TColumn('DESCRICAO')]
  property Descricao: string ...
end;

{ Repository.Base.pas — RTTI monta os campos em runtime }
for lProp in lType.GetProperties do
  for lAttr in lProp.GetAttributes do
    if lAttr is TColumnAttribute then
      lCampos := lCampos + UpperCase(lColAttr.ColumnName) + ', ';
// resultado (automático para qualquer T):
// "INSERT INTO PESSOA (NOME, IDADE, DATANASCIMENTO) VALUES (:NOME, :IDADE, :DATANASCIMENTO)"
// "INSERT INTO PRODUTO (DESCRICAO) VALUES (:DESCRICAO)"
```

`TRepository<T>` percorre os atributos `[TColumn]` via `TRttiContext`, monta o SQL dinamicamente e parametriza tudo. **Não importa se você tem 1 tabela ou 100 — o repositório é genérico e reutilizável.**

Adiciona um novo model? Só anotar com `[TTable]` e `[TColumn]` — sem tocar na base repositório. Escala.

Clone, rode e veja o `dados.db` sendo criado ao lado do .exe: [link do repositório]

#Delphi #RTTI #Pascal #Programacao #GenericRepository