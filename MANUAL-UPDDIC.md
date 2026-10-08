# Manual do `U_UPDDIC`

Atualiza o dicionário do Protheus a partir de um arquivo JSON. Cria ou altera tabelas (SX2), campos (SX3) e índices (SIX). O que muda de tipo, tamanho, decimal, grupo ou chave de índice também é aplicado na tabela do banco, via `X31UpdTable`.

Fonte: `src/UPDDICFC.prw`  
Modelo: `exemplo-upddic.json`

Parâmetro (SX6), gatilho (SX7) e help de campo (SX1) não entram neste fonte.

## Quando usar

Use para levar uma alteração de dicionário de um ambiente para outro sem gerar um `UPD*.prw` com os dados fixos no fonte. O JSON descreve o estado desejado. Rodar de novo o mesmo arquivo não recria o que já está igual.

A rotina só segue em Protheus 12 ou superior, com o dicionário no banco. Em dicionário ISAM ela para na entrada.

Rode com o ambiente exclusivo e com backup do dicionário e da base. Ela grava SX2, SX3 e SIX e pode alterar colunas e índices no banco.

## Como chamar

Programa de menu: `U_UPDDIC`.

| Chamada | O que acontece |
|---|---|
| `U_UPDDIC()` | Pede o arquivo e a empresa na tela |
| `U_UPDDIC("C:\pasta\dicionario.json")` | Usa esse arquivo e ainda pede a empresa |
| `U_UPDDIC("C:\pasta\dicionario.json", "99", "01")` | Job, sem tela. Empresa 99, filial 01 no `RpcSetEnv` |

Na tela, Continuar só avança se o caminho estiver preenchido. A empresa se marca com duplo clique na linha, ou com Marcar. Sem empresa marcada, Processar avisa e não fecha a tela.

Com tela, depois da empresa vem a revisão do JSON (tabelas, campos e índices) e a confirmação. Cancelar em qualquer uma das duas interrompe sem gravar. O job pula essas telas. A barra de progresso mostra o alias, o campo e o índice em execução.

O arquivo precisa ser lido pelo AppServer. Se o caminho estiver na máquina do SmartClient e o servidor não enxergar, a rotina copia com `CpyT2S` e apaga a cópia depois da leitura. Caminho vazio ou JSON ilegível interrompe antes de abrir a empresa.

O JSON precisa ter a lista `tabelas`, a lista `campos`, ou as duas.

## Regra de gravação

Chave ausente no JSON não mexe no que já existe. Chave presente grava aquele valor, mesmo vazio.

Campo novo recebe os padrões abaixo quando a chave não vem no arquivo. Campo que já existe só muda nas chaves enviadas.

O nome do campo é único no SX3. Se `ZZ1_COD` já estiver na ZZ1, um JSON pedindo o mesmo campo na SEA é ignorado e entra no resumo como erro. A rotina não move campo de uma tabela para outra.

A ordem do campo no SX3 (`X3_ORDEM`) é calculada na inclusão, no fim da tabela. O JSON não escolhe essa ordem.

## Tabelas

Ficam em `tabelas`. O alias tem 3 caracteres. Na inclusão, o arquivo físico do SX2 fica `alias + empresa + 0` (empresa 99 e alias ZZ1 geram `ZZ1990`). O caminho (`X2_PATH`) é copiado de uma tabela que já existe no SX2.

| Chave | SX2 | Na inclusão, se omitir |
|---|---|---|
| `alias` | `X2_CHAVE` | Obrigatório, 3 caracteres |
| `nome` | `X2_NOME` | O próprio alias |
| `nomeSpa` | `X2_NOMESPA` | O nome |
| `nomeEng` | `X2_NOMEENG` | O nome |
| `modo` | `X2_MODO` | `C` (compartilhado) |
| `modoEmp` | `X2_MODOEMP` | `E` (exclusivo) |
| `modoUn` | `X2_MODOUN` | `E` (exclusivo) |
| `unico` | `X2_UNICO` | Vazio |

`modo` `C` é tabela compartilhada. `E` é exclusiva. O mesmo vale para empresa e unidade.

Tabela nova dispara atualização física. Tabela que já existe só dispara atualização física se algum campo ou índice dela mudar a estrutura.

Dentro da tabela podem vir `campos` e `indices`.

## Campos

Um campo dentro de `tabelas[].campos` herda o alias da tabela. Um campo na lista raiz `campos` precisa da chave `arquivo` com o alias de 3 letras. Serve para campo novo numa tabela padrão, como a SEA.

`campo` é obrigatório e tem no máximo 10 caracteres.

| Chave | SX3 | Na inclusão, se omitir |
|---|---|---|
| `arquivo` | `X3_ARQUIVO` | Alias da tabela, quando o campo está dentro dela |
| `campo` | `X3_CAMPO` | Obrigatório |
| `tipo` | `X3_TIPO` | `C` |
| `tamanho` | `X3_TAMANHO` | `8` se o nome termina em `_FILIAL`; senão `1` |
| `decimal` | `X3_DECIMAL` | `0` |
| `nivel` | `X3_NIVEL` | `1` se o nome termina em `_FILIAL`; senão `0` |
| `grupo` | `X3_GRPSXG` | `033` se o campo novo termina em `_FILIAL` |
| `titulo` | `X3_TITULO` | O nome do campo |
| `tituloSpa` | `X3_TITSPA` | Vazio |
| `tituloEng` | `X3_TITENG` | Vazio |
| `descricao` | `X3_DESCRIC` | O nome do campo |
| `descSpa` | `X3_DESCSPA` | Vazio |
| `descEng` | `X3_DESCENG` | Vazio |
| `picture` | `X3_PICTURE` | `@!` no campo novo de filial |
| `valid` | `X3_VALID` | Vazio |
| `usado` | `X3_USADO` | Máscara de uso em todos os módulos |
| `relacao` | `X3_RELACAO` | Vazio. Inicializador padrão, por exemplo `GETSXENUM(...)` |
| `f3` | `X3_F3` | Vazio. Consulta padrão |
| `propri` | `X3_PROPRI` | `U` |
| `browse` | `X3_BROWSE` | `N` |
| `visual` | `X3_VISUAL` | Vazio na filial nova; `A` nos demais |
| `contexto` | `X3_CONTEXT` | Vazio na filial nova; `R` nos demais |
| `obrigatorio` | `X3_OBRIGAT` | Vazio. Use `x` para obrigatório |
| `vldUser` | `X3_VLDUSER` | Vazio |
| `combo` | `X3_CBOX` | Vazio. Exemplo: `A=Ativo;B=Bloqueado` |
| `when` | `X3_WHEN` | Vazio |
| `inicializador` | `X3_INIBRW` | Vazio. Inicializador de browse |
| `folder` | `X3_FOLDER` | Vazio |
| `ortografia` | `X3_ORTOGRA` | `N` |
| `idxFld` | `X3_IDXFLD` | `N` |
| `reservado` | `X3_RESERV` | `xxxxxx x` |

Se o campo tem grupo e esse grupo existe no SXG, o tamanho gravado é o do grupo, não o do JSON. É o caso da filial no grupo `033`: o JSON pode dizer 8 e a base gravar 2, se o grupo desta empresa for 2.

Mudança de `tipo`, `tamanho`, `decimal` ou `grupo` marca o alias para o `X31UpdTable`. Título, picture, combo e o restante são só dicionário.

## Índices

Ficam em `tabelas[].indices`.

| Chave | SIX | Na inclusão, se omitir |
|---|---|---|
| `ordem` | `ORDEM` | Próximo número da tabela (`1`, `2`, …) |
| `chave` | `CHAVE` | Obrigatória. Exemplo: `ZZ1_FILIAL+ZZ1_COD` |
| `descricao` | `DESCRICAO` | A própria chave |
| `descSpa` | `DESCSPA` | A descrição |
| `descEng` | `DESCENG` | A descrição |
| `propri` | `PROPRI` | `U` |
| `f3` | `F3` | Vazio |
| `nickname` | `NICKNAME` | Vazio |
| `showPesq` | `SHOWPESQ` | `N`. Use `S` para aparecer na pesquisa |

Índice novo, ou índice cuja chave mudou, entra na atualização física. Na troca de chave, o índice antigo é removido do banco antes do `X31UpdTable`. Comparação de chave ignora espaços e maiúsculas.

## Estrutura no banco

Depois do dicionário, a rotina percorre os alias que tiveram mudança estrutural e chama `X31UpdTable`. Alias sem mudança estrutural não passa por essa etapa.

Se o `X31UpdTable` acusar erro, o resumo final começa com "Concluido com erro" e o log recebe o rastro `__GetX31Trace()`. Os outros alias continuam.

Tabela nova fica registrada no SX2 nesse momento. A criação física depende do `X31UpdTable` desta base. Confira no banco se a tabela apareceu. No teste local do update anterior, ZZ1 e ZZ2 entraram no dicionário e as colunas novas da SEA foram criadas; as tabelas físicas `zz1990` e `zz2990` não apareceram no Postgres nessa execução.

## Resultado

No fim, a tela (ou o `ConOut`, no job) mostra:

- tabelas incluídas e alteradas
- campos criados, alterados e sem alteração
- índices criados e alterados

O log linha a linha vai para o log automático da atualização (`AutoGrLog`), com empresa, arquivo e horário. Cada item diz se foi incluído, alterado ou se ficou igual.

## Exemplo mínimo

Campo novo na SEA e uma tabela nova com um índice:

```json
{
  "tabelas": [
    {
      "alias": "ZZ9",
      "nome": "Log de auditoria",
      "modo": "C",
      "modoEmp": "E",
      "modoUn": "E",
      "campos": [
        { "campo": "ZZ9_FILIAL", "tipo": "C", "tamanho": 8, "titulo": "Filial", "grupo": "033" },
        { "campo": "ZZ9_COD", "tipo": "C", "tamanho": 6, "titulo": "Codigo", "browse": "S" }
      ],
      "indices": [
        { "ordem": "1", "chave": "ZZ9_FILIAL+ZZ9_COD", "descricao": "Codigo", "showPesq": "S" }
      ]
    }
  ],
  "campos": [
    { "arquivo": "SEA", "campo": "EA_XSTATUS", "tipo": "C", "tamanho": 1, "titulo": "Status (Pix)" }
  ]
}
```

O arquivo `exemplo-upddic.json` repete a ZZ1 e os campos PIX da SEA já gravados na base local. Rodar esse arquivo de novo deve contar esses itens como sem alteração, desde que o dicionário não tenha sido editado à mão.

## Compilação

Compile o fonte `src/UPDDICFC.prw` no RPO do ambiente. Quem cadastra o menu é o cliente. O programa é `U_UPDDIC`.
