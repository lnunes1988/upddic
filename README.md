# UPDDIC

Atualiza o dicionário do Protheus (SX2, SX3 e SIX) a partir de um arquivo JSON.

## Telas

O caminho do JSON pode ser absoluto, se estiver dentro do Protheus Data, ou relativo a essa pasta.

![Tela do arquivo JSON](imagens/print-arquivo.png)

Marque a empresa e processe.

![Seleção da empresa](imagens/print-empresas.png)

Antes de gravar, a rotina mostra o que o JSON descreve (tabelas, campos e índices) e pede confirmação.

No fim, a rotina mostra o que foi incluído, o que mudou e o que já estava igual.

![Resumo da atualização](imagens/print-resumo.png)

![Do arquivo JSON ate o banco](imagens/fluxo-upddic.jpg)

| Arquivo | Conteúdo |
|---|---|
| `src/UPDDICFC.prw` | Fonte. Programa de menu `U_UPDDIC` |
| `MANUAL-UPDDIC.md` | Como chamar, formato do JSON e o que a rotina grava |
| `exemplo-upddic.json` | Modelo de tabela, campos e índices |

![O que o JSON descreve](imagens/json-upddic.jpg)

![Como chamar a rotina](imagens/chamadas-upddic.jpg)

Rode com o ambiente exclusivo e com backup do dicionário e da base. O manual descreve a regra de gravação e a atualização física via `X31UpdTable`.

Compile `src/UPDDICFC.prw` no RPO do ambiente. Quem cadastra o menu é o cliente. O programa é `U_UPDDIC`.
