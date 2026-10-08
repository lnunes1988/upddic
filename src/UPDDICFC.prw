#Include "Protheus.ch"

/*/{Protheus.doc} UPDDIC
Atualiza dicionario (SX2, SX3 e SIX) a partir de um arquivo JSON.

O arquivo precisa estar visivel para o AppServer. Se o caminho vier do
SmartClient e o servidor nao enxergar o arquivo, a rotina copia com CpyT2S.

Chamada manual: U_UPDDIC()
Chamada com arquivo: U_UPDDIC("C:\pasta\dicionario.json")
Chamada de job: U_UPDDIC("C:\pasta\dicionario.json", "99", "01")

Modelo: exemplo-upddic.json
Manual: MANUAL-UPDDIC.md

@param cArquivo, character, Caminho do JSON
@param cEmpAmb, character, Empresa, quando a rotina roda sem tela de selecao
@param cFilAmb, character, Filial usada no RpcSetEnv
@return nil
@author Po-UI-servico
@since 06/10/2026
/*/
User Function UPDDIC(cArquivo, cEmpAmb, cFilAmb)

    Local aMarcadas := {}
    Local cMsg      := ""
    Local lAuto     := .F.
    Local lOk       := .F.
    Local oJson     := Nil

    Private oProc    := Nil
    Private aArqUpd  := {}
    Private lX31Erro := .F.
    Private aPend    := {}
    Private nTabInc  := 0
    Private nTabAlt  := 0
    Private nCpoInc  := 0
    Private nCpoAlt  := 0
    Private nCpoIgu  := 0
    Private nIndInc  := 0
    Private nIndAlt  := 0
    Private aJsonTab := {}
    Private aJsonCpo := {}

    Default cArquivo := ""
    Default cEmpAmb  := ""
    Default cFilAmb  := ""

    lAuto := !Empty(cEmpAmb)

    If GetVersao(.F.) < "12" .Or. (FindFunction("MPDicInDB") .And. !MPDicInDB())
        cMsg := "Este update so roda com dicionario no banco, em versao 12 ou superior."
        If lAuto
            ConOut(cMsg)
        Else
            MsgStop(cMsg, "UPDDIC")
        EndIf
        Return Nil
    EndIf

    If Empty(AllTrim(cArquivo))
        If lAuto
            ConOut("UPDDIC: arquivo JSON nao informado.")
            Return Nil
        EndIf
        cArquivo := DicTela()
        If Empty(cArquivo)
            Return Nil
        EndIf
    EndIf

    oJson := DicLoad(AllTrim(cArquivo), @cMsg)
    If oJson == Nil
        If lAuto
            ConOut("UPDDIC: " + cMsg)
        Else
            MsgStop(cMsg, "UPDDIC")
        EndIf
        Return Nil
    EndIf

    If lAuto
        aMarcadas := { { cEmpAmb, cFilAmb, cEmpAmb + cFilAmb } }
    Else
        aMarcadas := DicEscEmp()
    EndIf

    If Len(aMarcadas) == 0
        If !lAuto
            MsgInfo("Atualizacao nao realizada.", "UPDDIC")
        EndIf
        Return Nil
    EndIf

    If !lAuto
        If !DicPrevTela(aMarcadas, cArquivo)
            Return Nil
        EndIf
        If !DicConfirma(aMarcadas, cArquivo)
            Return Nil
        EndIf
    EndIf

    oProc := MsNewProcess():New({|lEnd| lOk := DicProc(lEnd, aMarcadas, oJson, cArquivo) }, "Atualizando", "Aguarde, atualizando dicionario...", .F.)
    oProc:Activate()

    cMsg := DicResumo()
    If lAuto
        ConOut(cMsg)
    Else
        DicFim(cMsg, lOk)
    EndIf

Return Nil

//--------------------------------------------------------------------
Static Function DicPrevTela(aMarcadas, cArquivo)

    Local nDlgAlt := 900
    Local nDlgLar := 1860
    Local aResolucao := {}
    Local nEscala := 2
    Local nTelaAlt := 0
    Local nTelaLar := 0
    Local nPctAlt := 0.85
    Local nPctLar := 0.90
    Local nMargem := 10
    Local nAltCtrl := 10
    Local nGapVert := 4
    Local nLargCtrl := 0
    Local nYArquivo := 0
    Local nYResumo := 0
    Local nYNota := 0
    Local nYLista := 0
    Local nYBotoes := 0
    Local nAltLista := 0
    Local nLargBotao := 45
    Local nGapBotao := 6
    Local nXCancelar := 0
    Local nXContinuar := 0
    Local aItens  := {}
    Local aCampos := {}
    Local aInd    := {}
    Local cVar    := ""
    Local cResumo := ""
    Local cAlias  := ""
    Local cNome   := ""
    Local cCampo  := ""
    Local cTipo   := ""
    Local cTam    := ""
    Local nTotCpo := 0
    Local nTotInd := 0
    Local nI      := 0
    Local nJ      := 0
    Local lOk     := .F.
    Local oDlg
    Local oLbx

    For nI := 1 To Len(aMarcadas)
        aAdd(aItens, { "Destino", "Empresa " + AllTrim(cValToChar(aMarcadas[nI][1])), "Filial " + AllTrim(cValToChar(aMarcadas[nI][2])) })
    Next nI

    For nI := 1 To Len(aJsonTab)
        cAlias := Upper(AllTrim(DicJStr(aJsonTab[nI], "alias")))
        cNome  := DicJStr(aJsonTab[nI], "nome")
        aCampos := DicArr(aJsonTab[nI], "campos")
        aInd := DicArr(aJsonTab[nI], "indices")
        nTotCpo += Len(aCampos)
        nTotInd += Len(aInd)
        aAdd(aItens, { "Tabela", cAlias, cNome + " | " + cValToChar(Len(aCampos)) + " campos | " + cValToChar(Len(aInd)) + " indices" })

        For nJ := 1 To Len(aCampos)
            cCampo := Upper(AllTrim(DicJStr(aCampos[nJ], "campo")))
            cTipo := DicJStr(aCampos[nJ], "tipo")
            cTam := DicJStr(aCampos[nJ], "tamanho")
            aAdd(aItens, { "Campo", cAlias + "." + cCampo, "Tipo " + cTipo + " | Tamanho " + cTam })
        Next nJ

        For nJ := 1 To Len(aInd)
            aAdd(aItens, { "Indice", cAlias + " / " + DicJStr(aInd[nJ], "ordem"), DicJStr(aInd[nJ], "chave") })
        Next nJ
    Next nI

    For nI := 1 To Len(aJsonCpo)
        cAlias := Upper(AllTrim(DicJStr(aJsonCpo[nI], "arquivo")))
        cCampo := Upper(AllTrim(DicJStr(aJsonCpo[nI], "campo")))
        cTipo := DicJStr(aJsonCpo[nI], "tipo")
        cTam := DicJStr(aJsonCpo[nI], "tamanho")
        nTotCpo++
        aAdd(aItens, { "Campo avulso", cAlias + "." + cCampo, "Tipo " + cTipo + " | Tamanho " + cTam })
    Next nI

    cResumo := "Tabelas: " + cValToChar(Len(aJsonTab))
    cResumo += "    Campos: " + cValToChar(nTotCpo)
    cResumo += "    Indices: " + cValToChar(nTotInd)
    cResumo += "    Destinos: " + cValToChar(Len(aMarcadas))

    Begin Sequence
        aResolucao := GetScreenRes()
        If ValType(aResolucao) == "A" .And. Len(aResolucao) >= 2
            nTelaLar := aResolucao[1]
            nTelaAlt := aResolucao[2]
            If nTelaLar > 0 .And. nTelaAlt > 0
                nDlgLar := Min(nDlgLar, Int(nTelaLar * nPctLar))
                nDlgAlt := Min(nDlgAlt, Int(nTelaAlt * nPctAlt))
            EndIf
        EndIf
    Recover
        nTelaLar := 0
        nTelaAlt := 0
    End Sequence

    nLargCtrl := (nDlgLar / nEscala) - (2 * nMargem)
    nYArquivo := nMargem
    nYResumo := nYArquivo + nAltCtrl + nGapVert
    nYNota := nYResumo + nAltCtrl + nGapVert
    nYLista := nYNota + nAltCtrl + nGapVert
    nYBotoes := (nDlgAlt / nEscala) - nMargem - nAltCtrl
    nAltLista := nYBotoes - nYLista - nMargem
    nXCancelar := (nDlgLar / nEscala) - nMargem - nLargBotao
    nXContinuar := nXCancelar - nGapBotao - nLargBotao
    Define MsDialog oDlg Title "Revisao dos dados" From 0, 0 To nDlgAlt, nDlgLar Pixel

    @ nYArquivo, nMargem Say "Arquivo: " + AllTrim(cArquivo) Size nLargCtrl, nAltCtrl Of oDlg Pixel
    @ nYResumo, nMargem Say cResumo Size nLargCtrl, nAltCtrl Of oDlg Pixel
    @ nYNota, nMargem Say "Itens do JSON; inclusoes e alteracoes serao identificadas durante a execucao." Size nLargCtrl, nAltCtrl Of oDlg Pixel
    @ nYLista, nMargem Listbox oLbx Var cVar Fields Header "Tipo", "Tabela / campo", "Detalhes" Size nLargCtrl, nAltLista Of oDlg Pixel
    oLbx:SetArray(aItens)
    oLbx:bLine := {|| { aItens[oLbx:nAt][1], aItens[oLbx:nAt][2], aItens[oLbx:nAt][3] } }

    @ nYBotoes, nXContinuar Button "Continuar" Size nLargBotao, nAltCtrl Pixel Of oDlg Action {|| lOk := .T., oDlg:End() }
    @ nYBotoes, nXCancelar Button "Cancelar" Size nLargBotao, nAltCtrl Pixel Of oDlg Action (oDlg:End())

    Activate MsDialog oDlg Center

Return lOk

//--------------------------------------------------------------------
Static Function DicLimitaResol(nDlgAlt, nDlgLar, nPctAlt, nPctLar)

    Local aResolucao := {}
    Local nTelaAlt   := 0
    Local nTelaLar   := 0

    Begin Sequence
        aResolucao := GetScreenRes()
        If ValType(aResolucao) == "A" .And. Len(aResolucao) >= 2
            nTelaLar := aResolucao[1]
            nTelaAlt := aResolucao[2]
            If nTelaLar > 0 .And. nTelaAlt > 0
                nDlgLar := Min(nDlgLar, Int(nTelaLar * nPctLar))
                nDlgAlt := Min(nDlgAlt, Int(nTelaAlt * nPctAlt))
            EndIf
        EndIf
    Recover
        nTelaAlt := 0
        nTelaLar := 0
    End Sequence

Return { nDlgAlt, nDlgLar, nTelaLar, nTelaAlt }

//--------------------------------------------------------------------
Static Function DicConfirma(aMarcadas, cArquivo)

    Local nDlgAlt := 300
    Local nDlgLar := 620
    Local nEscala := 2
    Local nMargem := 10
    Local nAltCtrl := 10
    Local nGapVert := 4
    Local nLargCtrl := 0
    Local nYAviso := 0
    Local nYTexto := 0
    Local nYBotoes := 0
    Local nAltTexto := 0
    Local nLargBotao := 65
    Local nGapBotao := 8
    Local nXExecutar := 0
    Local nXCancelar := 0
    Local aDim := {}
    Local cTexto := ""
    Local lOk := .F.
    Local nI := 0
    Local nInd := 0
    Local aInd := {}
    Local oDlg
    Local oGet

    For nI := 1 To Len(aJsonTab)
        aInd := DicArr(aJsonTab[nI], "indices")
        nInd += Len(aInd)
    Next nI

    cTexto := "Arquivo: " + AllTrim(cArquivo) + CRLF
    cTexto += "Tabelas: " + cValToChar(Len(aJsonTab)) + CRLF
    cTexto += "Campos avulsos: " + cValToChar(Len(aJsonCpo)) + CRLF
    cTexto += "Indices: " + cValToChar(nInd) + CRLF + CRLF
    cTexto += "Destinos: " + cValToChar(Len(aMarcadas)) + " empresa(s)/filial(is)" + CRLF + CRLF
    cTexto += "A rotina gravara SX2, SX3 e SIX. Alteracoes estruturais podem atualizar as tabelas no banco."

    aDim := DicLimitaResol(nDlgAlt, nDlgLar, 0.85, 0.90)
    nDlgAlt := aDim[1]
    nDlgLar := aDim[2]
    nLargCtrl := Int(nDlgLar / nEscala) - (2 * nMargem)
    nYAviso := nMargem
    nYTexto := nYAviso + nAltCtrl + nGapVert
    nYBotoes := Int(nDlgAlt / nEscala) - nMargem - nAltCtrl
    nAltTexto := nYBotoes - nYTexto - nMargem
    nXCancelar := Int(nDlgLar / nEscala) - nMargem - nLargBotao
    nXExecutar := nXCancelar - nGapBotao - nLargBotao

    Define MsDialog oDlg Title "Confirmar execucao" From 0, 0 To nDlgAlt, nDlgLar Pixel

    @ nYAviso, nMargem Say "A atualizacao ainda nao foi iniciada." Size nLargCtrl, nAltCtrl Of oDlg Pixel
    @ nYTexto, nMargem Get oGet Var cTexto Memo Size nLargCtrl, nAltTexto Of oDlg Pixel When .F.
    @ nYBotoes, nXExecutar Button "Executar" Size nLargBotao, nAltCtrl Pixel Of oDlg Action {|| lOk := .T., oDlg:End() }
    @ nYBotoes, nXCancelar Button "Cancelar" Size nLargBotao, nAltCtrl Pixel Of oDlg Action (oDlg:End())

    Activate MsDialog oDlg Center

Return lOk

//--------------------------------------------------------------------
Static Function DicFim(cMsg, lOk)

    Local nDlgAlt := 300
    Local nDlgLar := 620
    Local nEscala := 2
    Local nMargem := 10
    Local nAltCtrl := 10
    Local nLargCtrl := 0
    Local nYTexto := 0
    Local nYBotao := 0
    Local nAltTexto := 0
    Local nLargBotao := 45
    Local nXBotao := 0
    Local aDim := {}
    Local cTit := IIf(lOk, "Atualizacao concluida", "Atualizacao com erro")
    Local cTxt := cMsg
    Local oDlg
    Local oGet

    aDim := DicLimitaResol(nDlgAlt, nDlgLar, 0.85, 0.90)
    nDlgAlt := aDim[1]
    nDlgLar := aDim[2]
    nLargCtrl := Int(nDlgLar / nEscala) - (2 * nMargem)
    nYTexto := nMargem
    nYBotao := Int(nDlgAlt / nEscala) - nMargem - nAltCtrl
    nAltTexto := nYBotao - nYTexto - nMargem
    nXBotao := Int((Int(nDlgLar / nEscala) - nLargBotao) / 2)

    Define MsDialog oDlg Title cTit From 0, 0 To nDlgAlt, nDlgLar Pixel

    @ nYTexto, nMargem Get oGet Var cTxt Memo Size nLargCtrl, nAltTexto Of oDlg Pixel When .F.
    @ nYBotao, nXBotao Button "Ok" Size nLargBotao, nAltCtrl Pixel Of oDlg Action (oDlg:End())

    Activate MsDialog oDlg Center

Return Nil

//--------------------------------------------------------------------
Static Function DicProc(lEnd, aMarcadas, oJson, cArquivo)

    Local aTabs   := {}
    Local aCampos := {}
    Local cEmp    := ""
    Local cFil    := ""
    Local lEnv    := .F.
    Local lRet    := .T.
    Local nI      := 0
    Local nJ      := 0
    Local nTotTab := 0
    Local nTotCpo := 0
    Local oErro   := Nil

    aTabs   := aJsonTab
    aCampos := aJsonCpo
    nTotTab := Len(aTabs)
    nTotCpo := Len(aCampos)

    For nI := 1 To Len(aMarcadas)

        If lEnd
            AutoGrLog("Cancelado pelo usuario.")
            lRet := .F.
            Exit
        EndIf

        cEmp := aMarcadas[nI][1]
        cFil := aMarcadas[nI][2]

        If !DicOpen(.T.)
            AutoGrLog("Nao foi possivel abrir o SM0 exclusivo da empresa " + cEmp + ".")
            lRet := .F.
            Exit
        EndIf
        SM0->(DbCloseArea())

        lEnv := .F.
        Begin Sequence

            RpcSetEnv(cEmp, cFil)
            lEnv := .T.
            lMsFinalAuto := .F.
            lMsHelpAuto  := .F.
            aArqUpd := {}

            AutoGrLog(Replicate("-", 80))
            AutoGrLog("UPDDIC " + cArquivo)
            AutoGrLog("Empresa / Filial: " + cEmpAnt + "/" + cFilAnt)
            AutoGrLog("Inicio: " + DToC(Date()) + " " + Time())

            oProc:SetRegua1(4)

            oProc:IncRegua1("Tabelas (" + cValToChar(nTotTab) + ")")
            For nJ := 1 To Len(aTabs)
                DicTab(aTabs[nJ])
            Next nJ

            oProc:IncRegua1("Campos (" + cValToChar(nTotCpo) + ")")
            DicCampos(aCampos, "")

            oProc:IncRegua1("Estrutura fisica")
            If !DicFisico()
                lRet := .F.
            EndIf

            AutoGrLog("Fim: " + DToC(Date()) + " " + Time())
            AutoGrLog(Replicate("-", 80))

        Recover Using oErro
            AutoGrLog("Erro na empresa " + cEmp + ": " + oErro:Description)
            lRet := .F.
        End Sequence

        If lEnv
            RpcClearEnv()
        EndIf

    Next nI

Return lRet

//--------------------------------------------------------------------
Static Function DicTab(oTab)

    Local cAlias := Upper(DicJStr(oTab, "alias"))
    Local cNome  := DicJStr(oTab, "nome")
    Local cPath  := ""
    Local lNova  := .F.

    If Len(cAlias) != 3
        AutoGrLog("Alias invalido [" + cAlias + "]. Use 3 caracteres.")
        lX31Erro := .T.
        Return Nil
    EndIf

    If ValType(oProc) == "O"
        oProc:SetRegua2(1)
        oProc:IncRegua2("Tabela: " + cAlias)
    EndIf

    DbSelectArea("SX2")
    SX2->(DbSetOrder(1))
    SX2->(DbGoTop())
    cPath := SX2->X2_PATH

    If !SX2->(DbSeek(cAlias))
        lNova := .T.
        RecLock("SX2", .T.)
        DicPut("X2_CHAVE", cAlias)
        DicPut("X2_PATH", cPath)
        DicPut("X2_ARQUIVO", cAlias + cEmpAnt + "0")
        DicPut("X2_NOME", IIf(Empty(cNome), cAlias, cNome))
        DicPut("X2_NOMESPA", DicJStr(oTab, "nomeSpa", IIf(Empty(cNome), cAlias, cNome)))
        DicPut("X2_NOMEENG", DicJStr(oTab, "nomeEng", IIf(Empty(cNome), cAlias, cNome)))
        DicPut("X2_MODO", DicJStr(oTab, "modo", "C"))
        DicPut("X2_MODOEMP", DicJStr(oTab, "modoEmp", "E"))
        DicPut("X2_MODOUN", DicJStr(oTab, "modoUn", "E"))
        DicPut("X2_UNICO", DicJStr(oTab, "unico"))
        If FieldPos("X2_MODULO") > 0
            FieldPut(FieldPos("X2_MODULO"), 0)
        EndIf
        MsUnlock()
        nTabInc++
        AutoGrLog("Tabela incluida: " + cAlias)
        DicAddArq(cAlias)
    Else
        If DicAtuTab(oTab, cAlias)
            nTabAlt++
            AutoGrLog("Tabela alterada: " + cAlias)
        Else
            AutoGrLog("Tabela sem alteracao: " + cAlias)
        EndIf
    EndIf

    DicCampos(DicArr(oTab, "campos"), cAlias)
    DicIndices(DicArr(oTab, "indices"), cAlias)

Return Nil

//--------------------------------------------------------------------
Static Function DicAtuTab(oTab, cAlias)

    Local lMudou := .F.

    aPend := {}

    If DicTem(oTab, "nome")
        lMudou := DicAtuC("X2_NOME", DicJStr(oTab, "nome")) .Or. lMudou
    EndIf
    If DicTem(oTab, "nomeSpa")
        lMudou := DicAtuC("X2_NOMESPA", DicJStr(oTab, "nomeSpa")) .Or. lMudou
    EndIf
    If DicTem(oTab, "nomeEng")
        lMudou := DicAtuC("X2_NOMEENG", DicJStr(oTab, "nomeEng")) .Or. lMudou
    EndIf
    If DicTem(oTab, "modo")
        lMudou := DicAtuC("X2_MODO", DicJStr(oTab, "modo")) .Or. lMudou
    EndIf
    If DicTem(oTab, "modoEmp")
        lMudou := DicAtuC("X2_MODOEMP", DicJStr(oTab, "modoEmp")) .Or. lMudou
    EndIf
    If DicTem(oTab, "modoUn")
        lMudou := DicAtuC("X2_MODOUN", DicJStr(oTab, "modoUn")) .Or. lMudou
    EndIf
    If DicTem(oTab, "unico")
        lMudou := DicAtuC("X2_UNICO", DicJStr(oTab, "unico")) .Or. lMudou
    EndIf

    If lMudou
        RecLock("SX2", .F.)
        DicFlush()
        MsUnlock()
    EndIf

Return lMudou

//--------------------------------------------------------------------
Static Function DicCampos(aCampos, cAliasPad)

    Local nI := 0

    oProc:SetRegua2(Max(Len(aCampos), 1))
    For nI := 1 To Len(aCampos)
        DicCampo(aCampos[nI], cAliasPad)
    Next nI

Return Nil

//--------------------------------------------------------------------
Static Function DicCampo(oCpo, cAliasPad)

    Local cAlias  := Upper(DicJStr(oCpo, "arquivo"))
    Local cCampo  := Upper(DicJStr(oCpo, "campo"))
    Local cGrupo  := ""
    Local cTipo   := ""
    Local cOrdem  := ""
    Local lNova   := .F.
    Local lMudou  := .F.
    Local lEstr   := .F.
    Local nTam    := 0
    Local nDec    := 0
    Local nNivel  := 0
    Local nSeek   := 0
    Local aMapa   := {}
    Local nI      := 0

    aPend := {}

    If Empty(cAlias)
        cAlias := Upper(cAliasPad)
    EndIf

    If Len(cAlias) != 3 .Or. Empty(cCampo) .Or. Len(cCampo) > 10
        AutoGrLog("Campo ignorado. Alias [" + cAlias + "] campo [" + cCampo + "].")
        lX31Erro := .T.
        Return Nil
    EndIf

    If ValType(oProc) == "O"
        oProc:IncRegua2("Campo: " + cAlias + "." + cCampo)
    EndIf

    DbSelectArea("SX3")
    SX3->(DbSetOrder(2))
    nSeek := Len(SX3->X3_CAMPO)

    If SX3->(DbSeek(PadR(cCampo, nSeek)))
        If AllTrim(SX3->X3_ARQUIVO) != cAlias
            AutoGrLog("Campo " + cCampo + " ja existe em " + AllTrim(SX3->X3_ARQUIVO) + ". Nao foi movido para " + cAlias + ".")
            lX31Erro := .T.
            Return Nil
        EndIf
        lNova := .F.
    Else
        lNova := .T.
    EndIf

    If DicTem(oCpo, "grupo")
        cGrupo := DicJStr(oCpo, "grupo")
    ElseIf lNova .And. Right(cCampo, 7) == "_FILIAL"
        cGrupo := "033"
    ElseIf !lNova
        cGrupo := AllTrim(SX3->X3_GRPSXG)
    EndIf

    If DicTem(oCpo, "tamanho")
        nTam := DicJNum(oCpo, "tamanho", 0)
    ElseIf lNova
        nTam := IIf(Right(cCampo, 7) == "_FILIAL", 8, 1)
    Else
        nTam := SX3->X3_TAMANHO
    EndIf
    nTam := DicGrpTam(cGrupo, nTam)

    If DicTem(oCpo, "tipo")
        cTipo := DicJStr(oCpo, "tipo")
    ElseIf lNova
        cTipo := "C"
    Else
        cTipo := SX3->X3_TIPO
    EndIf

    If DicTem(oCpo, "decimal")
        nDec := DicJNum(oCpo, "decimal", 0)
    ElseIf lNova
        nDec := 0
    Else
        nDec := SX3->X3_DECIMAL
    EndIf

    If DicTem(oCpo, "nivel")
        nNivel := DicJNum(oCpo, "nivel", 0)
    ElseIf lNova .And. Right(cCampo, 7) == "_FILIAL"
        nNivel := 1
    ElseIf lNova
        nNivel := 0
    Else
        nNivel := SX3->X3_NIVEL
    EndIf

    aMapa := { ;
        { "titulo"       , "X3_TITULO" , "C", IIf(lNova, cCampo, "") }, ;
        { "tituloSpa"    , "X3_TITSPA" , "C", "" }, ;
        { "tituloEng"    , "X3_TITENG" , "C", "" }, ;
        { "descricao"    , "X3_DESCRIC", "C", IIf(lNova, cCampo, "") }, ;
        { "descSpa"      , "X3_DESCSPA", "C", "" }, ;
        { "descEng"      , "X3_DESCENG", "C", "" }, ;
        { "picture"      , "X3_PICTURE", "C", IIf(lNova .And. Right(cCampo, 7) == "_FILIAL", "@!", "") }, ;
        { "valid"        , "X3_VALID"  , "C", "" }, ;
        { "usado"        , "X3_USADO"  , "C", DicUsado() }, ;
        { "relacao"      , "X3_RELACAO", "C", "" }, ;
        { "f3"           , "X3_F3"     , "C", "" }, ;
        { "propri"       , "X3_PROPRI" , "C", "U" }, ;
        { "browse"       , "X3_BROWSE" , "C", "N" }, ;
        { "visual"       , "X3_VISUAL" , "C", IIf(lNova .And. Right(cCampo, 7) == "_FILIAL", "", "A") }, ;
        { "contexto"     , "X3_CONTEXT", "C", IIf(lNova .And. Right(cCampo, 7) == "_FILIAL", "", "R") }, ;
        { "obrigatorio"  , "X3_OBRIGAT", "C", "" }, ;
        { "vldUser"      , "X3_VLDUSER", "C", "" }, ;
        { "combo"        , "X3_CBOX"   , "C", "" }, ;
        { "when"         , "X3_WHEN"   , "C", "" }, ;
        { "inicializador", "X3_INIBRW" , "C", "" }, ;
        { "folder"       , "X3_FOLDER" , "C", "" }, ;
        { "ortografia"   , "X3_ORTOGRA", "C", "N" }, ;
        { "idxFld"       , "X3_IDXFLD" , "C", "N" }, ;
        { "reservado"    , "X3_RESERV" , "C", "xxxxxx x" } }

    If lNova
        cOrdem := DicOrdem(cAlias)
        RecLock("SX3", .T.)
        DicPut("X3_ARQUIVO", cAlias)
        DicPut("X3_ORDEM", cOrdem)
        DicPut("X3_CAMPO", cCampo)
        DicPut("X3_TIPO", cTipo)
        DicPutN("X3_TAMANHO", nTam)
        DicPutN("X3_DECIMAL", nDec)
        DicPutN("X3_NIVEL", nNivel)
        DicPut("X3_GRPSXG", cGrupo)
        For nI := 1 To Len(aMapa)
            DicPutMapa(oCpo, aMapa[nI], .T.)
        Next nI
        MsUnlock()
        DbCommit()
        nCpoInc++
        AutoGrLog("Campo criado: " + cAlias + " " + cCampo)
        DicAddArq(cAlias)
        Return Nil
    EndIf

    lEstr := DicDifN("X3_TAMANHO", nTam) .Or. DicDifC("X3_TIPO", cTipo) .Or. DicDifN("X3_DECIMAL", nDec)
    If DicTem(oCpo, "grupo")
        lEstr := lEstr .Or. DicDifC("X3_GRPSXG", cGrupo)
    EndIf
    If DicTem(oCpo, "nivel")
        lMudou := DicDifN("X3_NIVEL", nNivel)
    EndIf

    lMudou := lMudou .Or. lEstr
    For nI := 1 To Len(aMapa)
        If DicTem(oCpo, aMapa[nI][1])
            lMudou := DicPutMapa(oCpo, aMapa[nI], .F.) .Or. lMudou
        EndIf
    Next nI

    If !lMudou
        nCpoIgu++
        AutoGrLog("Campo sem alteracao: " + cCampo)
        Return Nil
    EndIf

    RecLock("SX3", .F.)
    If DicTem(oCpo, "tipo") .Or. lEstr
        DicPut("X3_TIPO", cTipo)
    EndIf
    If DicTem(oCpo, "tamanho") .Or. DicTem(oCpo, "grupo") .Or. DicDifN("X3_TAMANHO", nTam)
        DicPutN("X3_TAMANHO", nTam)
    EndIf
    If DicTem(oCpo, "decimal")
        DicPutN("X3_DECIMAL", nDec)
    EndIf
    If DicTem(oCpo, "nivel")
        DicPutN("X3_NIVEL", nNivel)
    EndIf
    If DicTem(oCpo, "grupo")
        DicPut("X3_GRPSXG", cGrupo)
    EndIf
    DicFlush()
    MsUnlock()
    DbCommit()

    nCpoAlt++
    AutoGrLog("Campo alterado: " + cCampo)
    If lEstr
        DicAddArq(cAlias)
    EndIf

Return Nil

//--------------------------------------------------------------------
Static Function DicIndices(aInd, cAlias)

    Local nI := 0

    oProc:SetRegua2(Max(Len(aInd), 1))
    For nI := 1 To Len(aInd)
        oProc:IncRegua2("Indice " + cAlias + " / " + AllTrim(DicJStr(aInd[nI], "ordem", cValToChar(nI))))
        DicIndice(aInd[nI], cAlias)
    Next nI

Return Nil

//--------------------------------------------------------------------
Static Function DicIndice(oInd, cAlias)

    Local cOrdem := AllTrim(DicJStr(oInd, "ordem"))
    Local cChave := DicJStr(oInd, "chave")
    Local lNova  := .F.
    Local lChave := .F.
    Local lMudou := .F.

    If Empty(cChave)
        AutoGrLog("Indice sem chave ignorado na tabela " + cAlias + ".")
        lX31Erro := .T.
        Return Nil
    EndIf

    If Empty(cOrdem)
        cOrdem := DicProxOrd(cAlias)
    EndIf

    DbSelectArea("SIX")
    SIX->(DbSetOrder(1))

    If !SIX->(DbSeek(cAlias + cOrdem))
        lNova := .T.
    Else
        lChave := !(StrTran(Upper(AllTrim(SIX->CHAVE)), " ", "") == StrTran(Upper(AllTrim(cChave)), " ", ""))
    EndIf

    If lNova
        RecLock("SIX", .T.)
        DicPut("INDICE", cAlias)
        DicPut("ORDEM", cOrdem)
        DicPut("CHAVE", cChave)
        DicPut("DESCRICAO", DicJStr(oInd, "descricao", cChave))
        DicPut("DESCSPA", DicJStr(oInd, "descSpa", DicJStr(oInd, "descricao", cChave)))
        DicPut("DESCENG", DicJStr(oInd, "descEng", DicJStr(oInd, "descricao", cChave)))
        DicPut("PROPRI", DicJStr(oInd, "propri", "U"))
        DicPut("F3", DicJStr(oInd, "f3"))
        DicPut("NICKNAME", DicJStr(oInd, "nickname"))
        DicPut("SHOWPESQ", DicJStr(oInd, "showPesq", "N"))
        MsUnlock()
        DbCommit()
        nIndInc++
        AutoGrLog("Indice criado: " + cAlias + "/" + cOrdem + " " + cChave)
        DicAddArq(cAlias)
        Return Nil
    EndIf

    lMudou := lChave
    If DicTem(oInd, "descricao")
        lMudou := DicDifC("DESCRICAO", DicJStr(oInd, "descricao")) .Or. lMudou
    EndIf
    If DicTem(oInd, "descSpa")
        lMudou := DicDifC("DESCSPA", DicJStr(oInd, "descSpa")) .Or. lMudou
    EndIf
    If DicTem(oInd, "descEng")
        lMudou := DicDifC("DESCENG", DicJStr(oInd, "descEng")) .Or. lMudou
    EndIf
    If DicTem(oInd, "propri")
        lMudou := DicDifC("PROPRI", DicJStr(oInd, "propri")) .Or. lMudou
    EndIf
    If DicTem(oInd, "f3")
        lMudou := DicDifC("F3", DicJStr(oInd, "f3")) .Or. lMudou
    EndIf
    If DicTem(oInd, "nickname")
        lMudou := DicDifC("NICKNAME", DicJStr(oInd, "nickname")) .Or. lMudou
    EndIf
    If DicTem(oInd, "showPesq")
        lMudou := DicDifC("SHOWPESQ", DicJStr(oInd, "showPesq")) .Or. lMudou
    EndIf

    If !lMudou
        AutoGrLog("Indice sem alteracao: " + cAlias + "/" + cOrdem)
        Return Nil
    EndIf

    RecLock("SIX", .F.)
    DicPut("CHAVE", cChave)
    If DicTem(oInd, "descricao")
        DicPut("DESCRICAO", DicJStr(oInd, "descricao"))
    EndIf
    If DicTem(oInd, "descSpa")
        DicPut("DESCSPA", DicJStr(oInd, "descSpa"))
    EndIf
    If DicTem(oInd, "descEng")
        DicPut("DESCENG", DicJStr(oInd, "descEng"))
    EndIf
    If DicTem(oInd, "propri")
        DicPut("PROPRI", DicJStr(oInd, "propri"))
    EndIf
    If DicTem(oInd, "f3")
        DicPut("F3", DicJStr(oInd, "f3"))
    EndIf
    If DicTem(oInd, "nickname")
        DicPut("NICKNAME", DicJStr(oInd, "nickname"))
    EndIf
    If DicTem(oInd, "showPesq")
        DicPut("SHOWPESQ", DicJStr(oInd, "showPesq"))
    EndIf
    MsUnlock()
    DbCommit()

    If lChave
        TcInternal(60, RetSqlName(cAlias) + "|" + RetSqlName(cAlias) + cOrdem)
        DicAddArq(cAlias)
    EndIf

    nIndAlt++
    AutoGrLog("Indice alterado: " + cAlias + "/" + cOrdem + " " + cChave)

Return Nil

//--------------------------------------------------------------------
Static Function DicFisico()

    Local cBuild := ""
    Local cFn    := ""
    Local nX     := 0

    If Len(aArqUpd) == 0
        AutoGrLog("Nenhuma alteracao estrutural.")
        Return .T.
    EndIf

    __SetX31Mode(.F.)

    If FindFunction("TCGetBuild")
        cFn := "TCGetBuild"
        cBuild := &cFn.()
    EndIf

    oProc:SetRegua2(Len(aArqUpd))

    For nX := 1 To Len(aArqUpd)

        oProc:IncRegua2(aArqUpd[nX])

        If cBuild >= "20090811" .And. TcInternal(89) == "CLOB_SUPPORTED"
            If aArqUpd[nX] >= "NQ " .And. aArqUpd[nX] <= "NZZ" .And. !aArqUpd[nX] $ "NQD,NQF,NQP,NQT"
                TcInternal(25, "CLOB")
            EndIf
        EndIf

        If Select(aArqUpd[nX]) > 0
            DbSelectArea(aArqUpd[nX])
            DbCloseArea()
        EndIf

        X31UpdTable(aArqUpd[nX])

        If __GetX31Error()
            lX31Erro := .T.
            AutoGrLog("Erro na estrutura da tabela " + aArqUpd[nX])
            AutoGrLog(__GetX31Trace())
        Else
            AutoGrLog("Estrutura atualizada: " + aArqUpd[nX])
        EndIf

        If cBuild >= "20090811" .And. TcInternal(89) == "CLOB_SUPPORTED"
            TcInternal(25, "OFF")
        EndIf

    Next nX

Return !lX31Erro

//--------------------------------------------------------------------
Static Function DicPath(cArquivo)

    Local cNorm := StrTran(AllTrim(cArquivo), "/", "\")
    Local cRoot := AllTrim(GetSrvProfString("RootPath", ""))

    cRoot := StrTran(cRoot, "/", "\")
    If !Empty(cRoot) .And. Right(cRoot, 1) == "\"
        cRoot := Left(cRoot, Len(cRoot) - 1)
    EndIf

    // Caminho absoluto dentro do Protheus Data vira caminho relativo, que o File() enxerga.
    If !Empty(cRoot) .And. Upper(cNorm) = (Upper(cRoot) + "\")
        cNorm := SubStr(cNorm, Len(cRoot) + 1)
    EndIf

Return cNorm

//--------------------------------------------------------------------
Static Function DicLoad(cArquivo, cMsg)

    Local cErr  := ""
    Local cJson := ""
    Local cSrv  := ""
    Local cTry  := ""
    Local oJson := Nil

    cMsg := ""
    cArquivo := DicPath(AllTrim(cArquivo))

    If File(cArquivo)
        cJson := MemoRead(cArquivo)
    EndIf

    // File() no WebApp as vezes nao ve caminho absoluto que o MemoRead le no servidor.
    If Empty(cJson) .And. (":" $ cArquivo .Or. Left(cArquivo, 1) $ "\/")
        cJson := MemoRead(cArquivo)
    EndIf

    // CpyT2S(arquivo na estacao, pasta no servidor) devolve logico.
    If Empty(cJson) .And. FindFunction("CpyT2S")
        cSrv := "\system\"
        If CpyT2S(cArquivo, cSrv, .F., .F.)
            cSrv += SubStr(cArquivo, RAt("\", StrTran(cArquivo, "/", "\")) + 1)
            If File(cSrv)
                cJson := MemoRead(cSrv)
                FErase(cSrv)
            EndIf
        EndIf
    EndIf

    If Empty(cJson)
        cMsg := "Nao foi possivel ler o arquivo " + cArquivo + ". O AppServer precisa enxergar esse caminho."
        Return Nil
    EndIf

    If Len(cJson) >= 3 .And. SubStr(cJson, 1, 3) == Chr(239) + Chr(187) + Chr(191)
        cJson := SubStr(cJson, 4)
    EndIf

    cTry := cJson
    Begin Sequence
        cTry := DecodeUTF8(cJson, "cp1252")
        If Empty(cTry)
            cTry := cJson
        EndIf
    Recover
        cTry := cJson
    End Sequence

    oJson := JsonObject():New()
    cErr := oJson:FromJson(cTry)
    If !Empty(cErr)
        oJson := JsonObject():New()
        cErr := oJson:FromJson(cJson)
    EndIf

    If !Empty(cErr)
        cMsg := "JSON invalido: " + cErr
        Return Nil
    EndIf

    aJsonTab := oJson:GetJsonObject("tabelas")
    aJsonCpo := oJson:GetJsonObject("campos")
    If ValType(aJsonTab) != "A"
        aJsonTab := {}
    EndIf
    If ValType(aJsonCpo) != "A"
        aJsonCpo := {}
    EndIf

    If Len(aJsonTab) == 0 .And. Len(aJsonCpo) == 0
        cMsg := "O JSON precisa ter a lista tabelas, a lista campos, ou as duas."
        Return Nil
    EndIf

Return oJson

//--------------------------------------------------------------------
Static Function DicArr(oPai, cNome)

    Local aRet  := {}
    Local nFim  := 0
    Local nI    := 0
    Local nIni  := 0
    Local oArr  := Nil
    Local oItem := Nil
    Local xArr  := Nil

    If !DicObj(oPai)
        Return aRet
    EndIf

    xArr := oPai:GetJsonObject(cNome)

    // Devolve o array original. O item do JSON e tipo J e nao sobrevive a uma copia.
    If ValType(xArr) == "A"
        Return xArr
    EndIf

    If ValType(xArr) != "O"
        Return aRet
    EndIf

    oArr := xArr
    Begin Sequence
        nFim := oArr:Length()
    Recover
        nFim := 0
    End Sequence

    If nFim > 0
        oItem := oArr:GetJsonObject(0)
        If ValType(oItem) == "U" .Or. oItem == Nil
            nIni := 1
        Else
            nIni := 0
            nFim := nFim - 1
        EndIf

        For nI := nIni To nFim
            oItem := oArr:GetJsonObject(nI)
            If DicObj(oItem)
                aAdd(aRet, oItem)
            EndIf
        Next nI
        Return aRet
    EndIf

    // Length() nem sempre existe neste JsonObject. Percorre ate o item vazio.
    oItem := oArr:GetJsonObject(0)
    nIni := IIf(DicObj(oItem), 0, 1)
    For nI := nIni To nIni + 499
        oItem := oArr:GetJsonObject(nI)
        If ValType(oItem) != "O"
            Exit
        EndIf
        aAdd(aRet, oItem)
    Next nI

Return aRet

//--------------------------------------------------------------------
Static Function DicObj(xVal)
Return ValType(xVal) $ "OJ"

//--------------------------------------------------------------------
Static Function DicTem(oObj, cNome)
Return DicObj(oObj) .And. oObj:HasProperty(cNome)

//--------------------------------------------------------------------
Static Function DicJStr(oObj, cNome, cPad)

    Local xVal := Nil

    Default cPad := ""

    If !DicTem(oObj, cNome)
        Return cPad
    EndIf

    xVal := oObj[cNome]
    If xVal == Nil .Or. ValType(xVal) == "U"
        Return cPad
    EndIf

Return AllTrim(cValToChar(xVal))

//--------------------------------------------------------------------
Static Function DicJNum(oObj, cNome, nPad)

    Local xVal := Nil

    Default nPad := 0

    If !DicTem(oObj, cNome)
        Return nPad
    EndIf

    xVal := oObj[cNome]
    If ValType(xVal) == "N"
        Return xVal
    EndIf

Return Val(cValToChar(xVal))

//--------------------------------------------------------------------
Static Function DicPutMapa(oCpo, aItem, lNova)

    Local cChave := aItem[1]
    Local cSX    := aItem[2]
    Local xPad   := aItem[4]
    Local xVal   := Nil

    If DicTem(oCpo, cChave)
        xVal := DicJStr(oCpo, cChave)
    ElseIf lNova
        xVal := xPad
    Else
        Return .F.
    EndIf

    If !lNova .And. !DicDifC(cSX, cValToChar(xVal))
        Return .F.
    EndIf

    If !lNova
        aAdd(aPend, { cSX, cValToChar(xVal), "C" })
        Return .T.
    EndIf

    DicPut(cSX, cValToChar(xVal))

Return .T.

//--------------------------------------------------------------------
/* Campos alterados ficam aqui ate o RecLock, para nao gravar leitura como mudanca. */
Static Function DicAtuC(cSX, cValor)

    If !DicDifC(cSX, cValor)
        Return .F.
    EndIf

    aAdd(aPend, { cSX, cValor, "C" })

Return .T.

//--------------------------------------------------------------------
Static Function DicFlush()

    Local nI := 0

    For nI := 1 To Len(aPend)
        If aPend[nI][3] == "N"
            DicPutN(aPend[nI][1], aPend[nI][2])
        Else
            DicPut(aPend[nI][1], aPend[nI][2])
        EndIf
    Next nI

    aPend := {}

Return Nil

//--------------------------------------------------------------------
Static Function DicDifC(cSX, cValor)

    Local nPos := FieldPos(cSX)

    If nPos == 0
        Return .F.
    EndIf

Return RTrim(cValToChar(FieldGet(nPos))) != RTrim(cValToChar(cValor))

//--------------------------------------------------------------------
Static Function DicDifN(cSX, nValor)

    Local nPos := FieldPos(cSX)

    If nPos == 0
        Return .F.
    EndIf

Return FieldGet(nPos) != nValor

//--------------------------------------------------------------------
Static Function DicPut(cSX, cValor)

    If FieldPos(cSX) > 0
        FieldPut(FieldPos(cSX), cValor)
    EndIf

Return Nil

//--------------------------------------------------------------------
Static Function DicPutN(cSX, nValor)

    If FieldPos(cSX) > 0
        FieldPut(FieldPos(cSX), nValor)
    EndIf

Return Nil

//--------------------------------------------------------------------
Static Function DicGrpTam(cGrupo, nTam)

    Local aArea := GetArea()
    Local nRet  := nTam

    If Empty(cGrupo) .Or. Select("SXG") == 0
        Return nRet
    EndIf

    SXG->(DbSetOrder(1))
    If SXG->(DbSeek(cGrupo))
        nRet := SXG->XG_SIZE
    EndIf

    RestArea(aArea)

Return nRet

//--------------------------------------------------------------------
Static Function DicOrdem(cAlias)

    Local cSeq := "00"
    Local nSeq := 0

    DbSelectArea("SX3")
    DbSetOrder(1)
    SX3->(DbSeek(cAlias + "ZZ", .T.))
    DbSkip(-1)

    If AllTrim(SX3->X3_ARQUIVO) == cAlias
        cSeq := SX3->X3_ORDEM
    EndIf

    If FindFunction("RetAsc")
        nSeq := Val(RetAsc(cSeq, 3, .F.)) + 1
        cSeq := RetAsc(Str(nSeq), 2, .T.)
    Else
        nSeq := Val(cSeq) + 1
        cSeq := PadL(AllTrim(Str(nSeq)), 2, "0")
    EndIf

Return cSeq

//--------------------------------------------------------------------
Static Function DicProxOrd(cAlias)

    Local nOrd := 0

    DbSelectArea("SIX")
    SIX->(DbSetOrder(1))
    SIX->(DbSeek(cAlias, .T.))

    While !SIX->(Eof()) .And. AllTrim(SIX->INDICE) == cAlias
        nOrd := Max(nOrd, Val(SIX->ORDEM))
        SIX->(DbSkip())
    End

Return AllTrim(Str(nOrd + 1))

//--------------------------------------------------------------------
Static Function DicAddArq(cAlias)

    If aScan(aArqUpd, {|x| x == cAlias }) == 0
        aAdd(aArqUpd, cAlias)
    EndIf

Return Nil

//--------------------------------------------------------------------
Static Function DicUsado()
Return "x       x       x       x       x       x       x       x       x       x       x       x       x       x       x"

//--------------------------------------------------------------------
Static Function DicResumo()

    Local cMsg := ""

    cMsg := "Tabelas incluidas: " + cValToChar(nTabInc) + CRLF
    cMsg += "Tabelas alteradas: " + cValToChar(nTabAlt) + CRLF
    cMsg += "Campos criados: " + cValToChar(nCpoInc) + CRLF
    cMsg += "Campos alterados: " + cValToChar(nCpoAlt) + CRLF
    cMsg += "Campos sem alteracao: " + cValToChar(nCpoIgu) + CRLF
    cMsg += "Indices criados: " + cValToChar(nIndInc) + CRLF
    cMsg += "Indices alterados: " + cValToChar(nIndAlt)

    If lX31Erro
        cMsg := "Concluido com erro." + CRLF + cMsg
    Else
        cMsg := "Atualizacao concluida." + CRLF + cMsg
    EndIf

Return cMsg

//--------------------------------------------------------------------
Static Function DicTela()

    Local cArq  := Space(180)
    Local lOk   := .F.
    Local oDlg
    Local oGet

    Define MsDialog oDlg Title "Atualizacao de dicionario" From 0, 0 To 220, 520 Pixel

    @ 10, 10 Say "O arquivo JSON descreve tabelas, campos e indices." Size 200, 8 Of oDlg Pixel
    @ 22, 10 Say "Rode com o ambiente exclusivo e com backup do dicionario." Size 200, 8 Of oDlg Pixel
    @ 42, 10 Say "Arquivo" Size 30, 8 Of oDlg Pixel
    @ 40, 40 MsGet oGet Var cArq Size 180, 10 Of oDlg Pixel

    @ 70, 40 Button "Procurar" Size 40, 12 Pixel Of oDlg Action (DicPegaArq(@cArq, oGet))
    @ 70, 130 Button "Continuar" Size 40, 12 Pixel Of oDlg Action {|| DicOk(@lOk, cArq, oDlg) }
    @ 70, 175 Button "Cancelar" Size 40, 12 Pixel Of oDlg Action (oDlg:End())

    Activate MsDialog oDlg Center

    If !lOk
        Return ""
    EndIf

Return AllTrim(cArq)

//--------------------------------------------------------------------
Static Function DicOk(lOk, cArq, oDlg)

    If Empty(AllTrim(cArq))
        MsgStop("Informe o arquivo JSON.", "UPDDIC")
        Return Nil
    EndIf

    lOk := .T.
    oDlg:End()

Return Nil

//--------------------------------------------------------------------
Static Function DicVai(aRet, aEmp, oDlg)

    DicRetEmp(aRet, aEmp)

    If Len(aRet) > 0
        oDlg:End()
    Else
        MsgStop("Selecione ao menos uma empresa.", "UPDDIC")
    EndIf

Return Nil

//--------------------------------------------------------------------
Static Function DicPegaArq(cArq, oGet)

    Local cSel := cGetFile("JSON (*.json)|*.json|", "Arquivo de dicionario", 0, "", .F., 0)

    If !Empty(cSel)
        cArq := PadR(cSel, 180)
        oGet:Refresh()
    EndIf

Return Nil

//--------------------------------------------------------------------
Static Function DicEscEmp()

    Local aEmp    := {}
    Local aRet    := {}
    Local aSalva  := GetArea()
    Local cVar    := ""
    Local oDlg
    Local oLbx

    If !DicOpen(.F.)
        Return aRet
    EndIf

    DbSelectArea("SM0")
    SM0->(DbSetOrder(1))
    SM0->(DbGoTop())

    While !SM0->(Eof())
        If aScan(aEmp, {|x| x[2] == SM0->M0_CODIGO }) == 0
            aAdd(aEmp, { .F., SM0->M0_CODIGO, SM0->M0_CODFIL, AllTrim(SM0->M0_NOME) })
        EndIf
        SM0->(DbSkip())
    End

    SM0->(DbCloseArea())

    Define MsDialog oDlg Title "Selecione a empresa" From 0, 0 To 280, 420 Pixel

    @ 10, 10 Listbox oLbx Var cVar Fields Header " ", "Empresa", "Nome" Size 180, 95 Of oDlg Pixel
    oLbx:SetArray(aEmp)
    oLbx:bLine := {|| { IIf(aEmp[oLbx:nAt][1], "X", " "), aEmp[oLbx:nAt][2], aEmp[oLbx:nAt][4] } }
    oLbx:BlDblClick := {|| aEmp[oLbx:nAt][1] := !aEmp[oLbx:nAt][1], oLbx:Refresh() }

    @ 128, 10 Button "Inverter" Size 37, 12 Pixel Of oDlg Action (DicInv(aEmp), oLbx:Refresh())
    @ 128, 52 Button "Marcar" Size 37, 12 Pixel Of oDlg Action (DicMarca(.T., aEmp), oLbx:Refresh())
    @ 112, 150 Button "Processar" Size 40, 12 Pixel Of oDlg Action {|| DicVai(@aRet, aEmp, oDlg) }
    @ 128, 150 Button "Cancelar" Size 40, 12 Pixel Of oDlg Action (oDlg:End())

    Activate MsDialog oDlg Center

    RestArea(aSalva)

Return aRet

//--------------------------------------------------------------------
Static Function DicMarca(lMarca, aEmp)

    Local nI := 0

    For nI := 1 To Len(aEmp)
        aEmp[nI][1] := lMarca
    Next nI

Return Nil

//--------------------------------------------------------------------
Static Function DicInv(aEmp)

    Local nI := 0

    For nI := 1 To Len(aEmp)
        aEmp[nI][1] := !aEmp[nI][1]
    Next nI

Return Nil

//--------------------------------------------------------------------
Static Function DicRetEmp(aRet, aEmp)

    Local nI := 0

    aRet := {}
    For nI := 1 To Len(aEmp)
        If aEmp[nI][1]
            aAdd(aRet, { aEmp[nI][2], aEmp[nI][3], aEmp[nI][2] + aEmp[nI][3] })
        EndIf
    Next nI

Return Nil

//--------------------------------------------------------------------
Static Function DicOpen(lShared)

    Local lOpen := .F.
    Local nLoop := 0

    If FindFunction("OpenSM0Excl")
        For nLoop := 1 To 20
            If OpenSM0Excl(, .F.)
                lOpen := .T.
                Exit
            EndIf
            Sleep(500)
        Next nLoop
    Else
        For nLoop := 1 To 20
            DbUseArea(.T., , "SIGAMAT.EMP", "SM0", lShared, .F.)
            If !Empty(Select("SM0"))
                lOpen := .T.
                DbSetIndex("SIGAMAT.IND")
                Exit
            EndIf
            Sleep(500)
        Next nLoop
    EndIf

    If !lOpen
        MsgStop("Nao foi possivel abrir o cadastro de empresas (SM0).", "UPDDIC")
    EndIf

Return lOpen
