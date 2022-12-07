/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/08/01/como-usar-bi-com-tcloud-ti-responde-016/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} User Function zImporta
Fun��o que realiza a importa��o dos arquivos da Protheus Data para a Base Local
@type  Function
@author Atilio
@since 19/08/2021
@version version
@obs Esse fonte tem que ser compilado e executado na base Local

	Para a grava��o dos logs, foi necess�rio criar duas tabelas

    Tabela ZZ1 - Log da Integra��o
        ZZ1_CODIGO, C�digo Sequencial,  caractere, tamanho 9
        ZZ1_ARQUIV, Nome do Arquivo,    caractere, tamanho 50
        ZZ1_EXPDAT, Data da exporta��o, data,      tamanho 8
        ZZ1_EXPHOR, Hora da exporta��o, caractere, tamanho 8
        ZZ1_IMPDAT, Data da importa��o, data,      tamanho 8
        ZZ1_IMPHOR, Hora da importa��o, caractere, tamanho 8
        
    Tabela ZZ2 - Vinculo de Recnos
        ZZ2_CODIGO, C�digo Sequencial,   caractere, tamanho 9
        ZZ2_TABELA, Alias da Tabela,     caractere, tamanho 3
        ZZ2_EXPREC, Recno da exporta��o, numerico,  tamanho 16
        ZZ2_IMPREC, Recno da importa��o, numerico,  tamanho 16
        ZZ2_DATA,   Data,                data,      tamanho 8
        ZZ2_HORA,   Hora,                caractere, tamanho 8
/*/

User Function zImporta()
    Local aArea
    Local lContinua := .F.
    Private lJobPvt := .F.

    //Se n�o tiver ambiente aberto, � job
    If Select("SX2") == 0
        RpcSetEnv("99", "01", "usuario", "senha", "GPE")
        lJobPvt := .T.
        lContinua := .T.
    Else
        lContinua := MsgYesNo("Deseja executar a importa��o dos arquivos para o Banco Local?", "Aten��o")
    EndIf
    aArea := GetArea()

    //Se for continuar, ir� chamar a rotina de processamento
    If lContinua
        If ! LockByName("zImporta", .T., .F.)

        Else
            Processa({|| fImporta() }, "Importando...")
            UnLockByName("zImporta", .T., .F.)
        EndIf
    EndIf

    RestArea(aArea)
Return

Static Function fImporta()
    Local cPasta     := "\x_bancolocal\"
    Local aArquivos  := {}
    Local nAtual     := 0
    Local cArqAtu    := ""
    Local cTabela    := ""
    Local oArquivo
    Local nLinha     := 0
    Local nColuna    := 0
    Local aCabecalho := {}
    Local nPosRecno  := 0
    Local nPosDelet := 0
    Local lOperacao
    Local nIndAtu
    Local lFalhou
    Private cCodigoZZ2 := StrTran(Space(TamSX3("ZZ2_CODIGO")[1]), ' ', '0')

	//Se a pasta n�o existir, cria a pasta
    If ! ExistDir(cPasta)
        MakeDir(cPasta)
    EndIf
	
	fBxCloud(cPasta)

    //Buscando os arquivos txt
	aDir(cPasta + "*.txt", aArquivos)

    //Ordena o array, para pegar os totais primeiro T_**** e depois os parciais P_****
    aSort(aArquivos,,, { |x, y| x > y })

    //Define o tamanho da r�gua
    ProcRegua(Len(aArquivos))

    //Se houver arquivos
    If Len(aArquivos) != 0
        //Busca a �ltima ZZ2 apenas 1 vez
        cQryUlt := " SELECT MAX(ZZ2_CODIGO) AS ULTIMO FROM " + RetSQLName("ZZ2") + " ZZ2 "
        TCQuery cQryUlt New Alias "QRY_ULT"

        //Se houver dados
        If ! QRY_ULT->(EoF())
            //E o �ltimo for v�lido
            If ! Empty(QRY_ULT->ULTIMO)
                cCodigoZZ2 := QRY_ULT->ULTIMO
            EndIf
        EndIf
        QRY_ULT->(DbCloseArea())
    EndIf

    //Percorre os arquivos
    For nAtual := 1 To Len(aArquivos)
        //Incrementa a r�gua
        IncProc("Importando arquivo " + cValToChar(nAtual) + " de " + cValToChar(Len(aArquivos)) + "...")

        //Pega o arquivo
        cArqAtu  := aArquivos[nAtual]

        //Se o arquivo j� foi importado anteriormente, pula o registro
        If fJaImport(cArqAtu)
            FErase(cArqAtu)
            Loop
        EndIf

        //Pega a tabela
        cTipoExp := SubStr(cArqAtu, 1, 1)
        cTabela  := SubStr(cArqAtu, 3, 3)
        oArquivo := FWFileReader():New(cPasta + cArqAtu)
        
        //Se for Exporta��o Total (desde o primeiro recno), executa um ZAP para apagar os dados da tabela
        If cTipoExp == "T"
            DbSelectArea(cTabela)
            cQryDel := " DELETE FROM " + RetSQLName(cTabela)
            If TCSqlExec(cQryDel) != 0
                nAtual++
                Loop
            EndIf
        EndIf

        //Se o arquivo pode ser aberto
        If (oArquivo:Open())
            //Busca o �ndice 1 da tabela - Para algumas tabelas, � necess�rio mudar o �ndice, por exemplo SD2 usar o �ndice 3 por causa de chave �nica da tabela
            DbSelectArea(cTabela)
            If cTabela == "SD2"
                (cTabela)->(DbSetOrder(3))
            Else
                (cTabela)->(DbSetOrder(1))
            EndIf
            cIndice := IndexKey(IndexOrd())
            aIndice := Separa(cIndice, "+")
            aPosInd := {}

            //Se n�o for fim do arquivo
            If ! (oArquivo:EoF())
                nLinha     := 0
                nPosRecno  := 0
                nPosDelet := 0

                //Enquanto tiver linhas
                While (oArquivo:HasLine())
                    nLinha++
                    
                    //Pegando a linha atual e transformando em array
                    cLinAtu := oArquivo:GetLine()
                    aLinha  := Separa(cLinAtu, ",")
                    
                    //Se for a linha 1, � cabe�alho
                    If nLinha == 1
                        aCabecalho := aClone(aLinha)
                        nPosRecno  := aScan(aCabecalho, {|x| x == "RECNO"})
                        nPosDelet := aScan(aCabecalho, {|x| x == "DELET"})
                        For nIndAtu := 1 To Len(aIndice)
                            If "DTOS" $ aIndice[nIndAtu]
                                aIndice[nIndAtu] := StrTran(aIndice[nIndAtu], "DTOS(", "")
                                aIndice[nIndAtu] := StrTran(aIndice[nIndAtu], ")", "")
                            EndIf
                            //Posi��o 1 do aPosInd = campo, posi��o 2 = n�mero da coluna do array
                            nPosInd := aScan(aCabecalho, {|x| Alltrim(x) == Alltrim(aIndice[nIndAtu])})
                            aAdd(aPosInd, {aIndice[nIndAtu], nPosInd})
                        Next
                    ElseIf Len(aLinha) > 0
                        DbSelectArea(cTabela)
                        lOperacao := .T.

                        //Se o recno for igual a 0, registro inv�lido, pula
                        If Val(aLinha[nPosRecno]) == 0 .Or. fRecInvalid(aLinha[nPosRecno]) .Or. Len(Alltrim(aLinha[nPosRecno])) > 18
                            Loop
                        EndIf
                        aLinha[nPosRecno] := Val(aLinha[nPosRecno])
                        aLinha[nPosRecno] := cValToChar(aLinha[nPosRecno])

                        //Se for Parcial
                        If cTipoExp == "P"
                            lFalhou := .F.
                            cQryTab := " SELECT " + CRLF
                            cQryTab += "     ZZ2_IMPREC " + CRLF
                            cQryTab += " FROM " + CRLF
                            cQryTab += "     " + RetSQLName("ZZ2") + " ZZ2 " + CRLF
                            cQryTab += " WHERE " + CRLF
                            cQryTab += "     ZZ2_FILIAL = '" + FWxFilial("ZZ2") + "' " + CRLF
                            cQryTab += "     AND ZZ2_TABELA = '" + cTabela + "' " + CRLF
                            cQryTab += "     AND ZZ2_EXPREC = '" + aLinha[nPosRecno] + "' " + CRLF
                            cQryTab += "     AND ZZ2.D_E_L_E_T_ = ' ' " + CRLF
                            cQryTab += " LIMIT 1 " + CRLF
                            TCQuery cQryTab New Alias "QRY_TAB"

                            //Se existir, ser� alteracao
                            If ! QRY_TAB->(EoF())
                                lOperacao := .F.
                                (cTabela)->(DbGoTo(QRY_TAB->ZZ2_IMPREC))

                            //Sen�o, faz uma segunda query pela chave unica para ver se ser� inclus�o ou altera��o
                            Else
                                //Faz uma query e veja se existe os dados
                                cQryTab := " SELECT " + CRLF
                                cQryTab += "     R_E_C_N_O_ AS REC " + CRLF
                                cQryTab += " FROM " + CRLF
                                cQryTab += "     " + RetSQLName(cTabela) + " AS TAB " + CRLF
                                cQryTab += " WHERE " + CRLF
                                cQryTab += "     1 = 1 " + CRLF
                                For nIndAtu := 1 To Len(aPosInd)
                                    cCampo   := aPosInd[nIndAtu][1]
                                    nColuna  := aPosInd[nIndAtu][2]

                                    If nColuna > Len(aLinha)
                                        lFalhou := .T.
                                        Exit
                                    Else
                                        cConteud := aLinha[nColuna]
                                        If "_FILIAL" $ cCampo
                                            cConteud := fTrataFil(cConteud)
                                        EndIf
                                        cQryTab += "     AND " + cCampo + " = '" + cConteud + "' " + CRLF
                                    EndIf
                                Next
                                TCQuery cQryTab New Alias "QRY_TAB2"

                                //Se existir, ser� alteracao
                                If ! QRY_TAB2->(EoF())
                                    lOperacao := .F.
                                    (cTabela)->(DbGoTo(QRY_TAB2->REC))
                                Else
                                    lOperacao := .T.
                                EndIf
                                QRY_TAB2->(DbCloseArea())
                            EndIf
                            QRY_TAB->(DbCloseArea())

                            //Se a linha for inv�lida, pula
                            If lFalhou
                                Loop
                            EndIf
                            
                        //Sen�o ser� inclus�o
                        Else
                            lOperacao := .T.
                        EndIf

                        //Somente se bater o n�mero de colunas da linha com o cabe�alho
                        If Len(aCabecalho) == Len(aLinha)

                            //Trava o registro
                            RecLock(cTabela, lOperacao)

                            //Percorre as colunas
                            For nColuna := 1 To Len(aLinha)

                                //Se a coluna existir
                                If nColuna <= Len(aCabecalho) .And. FieldPos(aCabecalho[nColuna]) > 0
                                    //Se o tipo dos campos for diferente
                                    If ValType((cTabela)->(&(aCabecalho[nColuna]))) != ValType(aLinha[nColuna])
                                        //Campo num�rico
                                        If ValType((cTabela)->(&(aCabecalho[nColuna]))) == "N"
                                            aLinha[nColuna] := Val(aLinha[nColuna])

                                        //Campo data
                                        ElseIf ValType((cTabela)->(&(aCabecalho[nColuna]))) == "D"
                                            aLinha[nColuna] := sToD(aLinha[nColuna])

                                        //Campo caractere
                                        Else
                                            aLinha[nColuna] := cValToChar(aLinha[nColuna])
                                        EndIf
                                    EndIf

                                    //Se for um campo num�rico
                                    If ValType((cTabela)->(&(aCabecalho[nColuna]))) == "N"
                                        //Se o conte�do vindo, for estourar o campo, gravo como -1 para identificar
                                        //   depois para aumentar o campo
                                        If "*" $ Alltrim(Transform(aLinha[nColuna], PesqPict(cTabela, aCabecalho[nColuna])))
                                            aLinha[nColuna] := -1
                                        EndIf
                                    EndIf

                                    //Se for um campo MEMO, ir� substituir o \n por char 13 e 10
                                    If GetSX3Cache(aCabecalho[nColuna], "X3_TIPO") == "M"
                                        aLinha[nColuna] := StrTran(aLinha[nColuna], "\n", CRLF)

                                    //Se for um campo Num�rico, define o tamanho de decimais
                                    ElseIf GetSX3Cache(aCabecalho[nColuna], "X3_TIPO") == "N"
                                        aLinha[nColuna] := NoRound(aLinha[nColuna], TamSX3(aCabecalho[nColuna])[2])
                                    EndIf

                                    //Se for um campo filial, trata o conteudo para gravar
                                    If "_FILIAL" $ aCabecalho[nColuna]
                                        aLinha[nColuna] := fTrataFil(aLinha[nColuna])
                                    EndIf

                                    //Grava o campo
                                    (cTabela)->(&(aCabecalho[nColuna])) := aLinha[nColuna]
                                EndIf
                            Next

                            //Destrava o registro
                            (cTabela)->(MsUnlock())

                            //Se existir a posi��o do RecDel e ele estiver preenchido, deleta o registro
                            If nPosDelet != 0 .And. Len(aLinha) >= nPosDelet .And. ! Empty(aLinha[nPosDelet])
                                RecLock(cTabela, .F.)
                                    DbDelete()
                                (cTabela)->(MsUnlock())
                            EndIf

                            //Somente se for inclus�o
                            If lOperacao
                                fIncLogTab(cTabela, Val(aLinha[nPosRecno]), (cTabela)->(RecNo()))
                            EndIf
                        EndIf
                    EndIf
                    
                EndDo

            Else
                // MsgStop("Arquivo [" + cArqAtu + "] n�o tem conte�do!", "Aten��o")
            EndIf

            //Fecha o arquivo e exclui da Protheus Data da base local
            oArquivo:Close()
            FErase(cPasta + cArqAtu)
            fIncLog(cArqAtu)
            
        Else
            // MsgStop("Arquivo [" + cArqAtu + "] n�o pode ser aberto!", "Aten��o")
        EndIf

    Next
Return

Static Function fTrataFil(cFilDado)
    Local aArea   := GetArea()
    Local cFilNov := cFilDado
    
    cFilNov := StrTran(cFilNov, "01", "A")
    cFilNov := StrTran(cFilNov, "02", "B")
    cFilNov := StrTran(cFilNov, "03", "C")
    cFilNov := StrTran(cFilNov, "04", "D")
    cFilNov := StrTran(cFilNov, "05", "E")
    cFilNov := StrTran(cFilNov, "06", "F")
    cFilNov := StrTran(cFilNov, "07", "G")
    cFilNov := StrTran(cFilNov, "08", "H")
    cFilNov := StrTran(cFilNov, "09", "I")
    cFilNov := StrTran(cFilNov, "  ", " ")

    RestArea(aArea)
Return cFilNov

Static Function fIncLog(cArquivo)
    Local aArea    := GetArea()
    Local cCodigo  := GetSXENum("ZZ1", "ZZ1_CODIGO")
    Local dDataArq := sToD(SubStr(cArquivo, 7,  8))
    Local cHoraArq := StrTran(SubStr(cArquivo, 16, 8), '-', ':')

    //Inclui o Log
    DbSelectArea("ZZ1")
    RecLock("ZZ1", .T.)
        ZZ1->ZZ1_FILIAL := FWxFilial("ZZ1")
        ZZ1->ZZ1_CODIGO := cCodigo
        ZZ1->ZZ1_ARQUIV := cArquivo
        ZZ1->ZZ1_EXPDAT := dDataArq
        ZZ1->ZZ1_EXPHOR := cHoraArq
        ZZ1->ZZ1_IMPDAT := Date()
        ZZ1->ZZ1_IMPHOR := Time()
    ZZ1->(MsUnlock())

    RestArea(aArea)
Return

Static Function fIncLogTab(cTabela, nRecExpor, nRecImpor)
    //Local aArea    := GetArea()
    //Local cCodigo  := GetSXENum("ZZ2", "ZZ2_CODIGO")

    cCodigoZZ2 := Soma1(cCodigoZZ2)

    //Inclui o Log
    DbSelectArea("ZZ2")
    RecLock("ZZ2", .T.)
        ZZ2->ZZ2_FILIAL := FWxFilial("ZZ2")
        ZZ2->ZZ2_CODIGO := cCodigoZZ2
        ZZ2->ZZ2_TABELA := cTabela
        ZZ2->ZZ2_EXPREC := nRecExpor
        ZZ2->ZZ2_IMPREC := nRecImpor
        ZZ2->ZZ2_DATA   := Date()
        ZZ2->ZZ2_HORA   := Time()
    ZZ2->(MsUnlock())

    //RestArea(aArea)
Return

Static Function fJaImport(cArquivo)
    Local aArea   := GetArea()
    Local lExiste := .F.
    Local cQryArq := ""

    //Busca na base se o arquivo j� foi importado
    cQryArq := " SELECT " + CRLF
    cQryArq += "     ZZ1_ARQUIV " + CRLF
    cQryArq += " FROM " + CRLF
    cQryArq += "     " + RetSQLName("ZZ1") + " ZZ1 " + CRLF
    cQryArq += " WHERE " + CRLF
    cQryArq += "     ZZ1_FILIAL = '" + FWxFilial("ZZ1") + "' " + CRLF
    cQryArq += "     AND ZZ1_ARQUIV = '" + cArquivo + "' " + CRLF
    cQryArq += "     AND ZZ1.D_E_L_E_T_ = ' ' " + CRLF
    TCQuery cQryArq New Alias "QRY_EXIST"

    //Se existem dados
    If ! QRY_EXIST->(EoF())
        lExiste := .T.
    EndIf
    QRY_EXIST->(DbCloseArea())

    RestArea(aArea)
Return lExiste

Static Function fRecInvalid(cRecno)
    Local lRet    := .F.
    Local cLetras := "ABCDEFGHIJKLMNOPQRSTUVWXYZ\()�"
    Local nLetra  := 0

    //Deixa tudo maiusculo o texto do recno
    cRecno := Alltrim(Upper(cRecno))

    //Percorre as letras
    For nLetra := 1 To Len(cLetras)
        //Se a letra atual estive no texto, o recno � inv�lido
        If SubStr(cLetras, nLetra, 1) $ cRecno
            lRet := .T.
            Exit
        EndIf
    Next
Return lRet

Static Function fBxCloud(cPastaLoc)
	Local cDirLocal := "C:\TOTVS\ERP\Protheus_Data" + cPastaLoc
    Local cDirCloud := "C:\TOTVS\Cloud\smartclient\"
	Local cPrograma := "u_zCloudBx"
	Local cComunica := "tcp"
	Local cAmbiente := "PRODUCAO01"

    //Executa o smartclient do Cloud para copiar os arquivos para a Protheus Data local
    WaitRun(cDirCloud + "smartclient.exe -c=" + cComunica + " -e=" + cAmbiente + " -m -q -p=" + cPrograma + " -a=" + cDirLocal , 1)
Return

/*/{Protheus.doc} User Function zCloudBx
Fun��o que percorre a pasta na Protheus Data do Cloud e copia os arquivos para a m�quina local
@type  Function
@author Atilio
@since 26/08/2021
@version version
/*/

User Function zCloudBx(cPastaLocal)
    Local cPasta        := "\x_bancolocal\"
    Local cPastaOld     := "\x_bancolocal\old\"
    Local aArquivos     := {}
    Local nAtual        := 0
    Local cDataArqui    := ""
    Default cPastaLocal := ""

    //Se a pasta antiga n�o existir, cria
    If ! ExistDir(cPastaOld)
        MakeDir(cPastaOld)
    EndIf

    //Se tiver pasta local
    If ! Empty(cPastaLocal)
        //Busca todos os TXT do Cloud
        aDir(cPasta + "*.txt", aArquivos)

        //Percorre os arquivos
        For nAtual := 1 To Len(aArquivos)
            cDataArqui := SubStr(aArquivos[nAtual], 7, 8)

            //Copia o arquivo para a pasta local, em seguida para a pasta de backup
            __CopyFile(cPasta + aArquivos[nAtual], cPastaLocal + aArquivos[nAtual])
            __CopyFile(cPasta + aArquivos[nAtual], cPastaOld   + aArquivos[nAtual])

            //Exclui o arquivo original
            FErase(cPasta + aArquivos[nAtual])
        Next
    EndIf
Return
