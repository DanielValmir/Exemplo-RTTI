# Exemplo RTTI em Delphi

Este projeto é um exemplo simples de uso de RTTI com Delphi para criar um repositório genérico de CRUD com FireDAC e SQLite.

## O que o projeto faz

- Exibe uma interface com cadastro de pessoas.
- Cria automaticamente o banco SQLite no diretório do executável.
- Usa atributos como [TTable] e [TColumn] para mapear classes para tabelas e colunas.
- Monta SQL dinamicamente em tempo de execução por meio de RTTI, sem escrever SQL manual para cada operação.

## Estrutura principal

- [RTTIExemplo.dpr](RTTIExemplo.dpr): ponto de entrada do projeto.
- [uPrincipal.pas](uPrincipal.pas): formulário principal com CRUD e conexão com o banco.
- [Repository.Base.pas](Repository.Base.pas): repositório genérico com operações CRUD via RTTI.
- [uModel.pas](uModel.pas): modelo de exemplo com mapeamento das propriedades.
- [dados.db](dados.db): banco SQLite gerado automaticamente ao executar a aplicação.

## Requisitos

- Delphi / RAD Studio com suporte a FireDAC.
- Windows.

## Como executar

1. Abra o projeto [RTTIExemplo.dpr](RTTIExemplo.dpr) no Delphi.
2. Compile e execute a aplicação.
3. O programa criará o arquivo SQLite [dados.db](dados.db) na pasta do executável.

## Observação

O exemplo demonstra como reduzir boilerplate de acesso a dados usando RTTI, deixando o repositório reutilizável para diferentes entidades.
