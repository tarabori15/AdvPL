/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/08/01/como-usar-bi-com-tcloud-ti-responde-016/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include "TOTVS.ch"
#Include "TopConn.ch"
#Include "FileIO.ch"

/*/{Protheus.doc} User Function zExporta
Fun��o que realiza a exporta��o das tabelas para arquivos txt dentro da Protheus Data
@type  Function
@author Atilio
@since 12/08/2021
@version version
@obs Esse fonte tem que ser compilado e executado na base TCloud
/*/

User Function zExporta()
    Local aArea
    Local lContinua := .F.
    Private lJobPvt := .F.

    //Se n�o tiver ambiente aberto, � job
    If Select("SX2") == 0
        //Reseta o ambiente e abre ele novamente
        RpcClearEnv()
        RpcSetEnv("01", "0101", "usuario", "senha", "")
        lJobPvt := .T.
        lContinua := .T.
    Else
        lContinua := MsgYesNo("Deseja executar a exporta��o geral de dados para o Banco Local?", "Aten��o")
    EndIf
    aArea := GetArea()

    //Se for continuar, ir� chamar a rotina de processamento
    If lContinua
        If ! LockByName("zExporta", .T., .F.)

        Else
            Processa({|| fExporta() }, "Exportando...")
            UnLockByName("zExporta", .T., .F.)
        EndIf
    EndIf

    RestArea(aArea)
Return

Static Function fExporta()
    Local aArea     := GetArea()
    Local cPasta    := "\x_bancolocal\"
    Local cArquivo  := ""
    Local nAtual    := 0
    Local nTotal    := 0
	Local cTabAtu   := ""
	Local aTabelas  := {}
    Local cQryExp   := ""    
    Local cCabecalho := ""
    Local nCampo     := 0
    Local aEstrutTab := {}
    Private cDelim   := ''

    //Se a pasta n�o existir, cria a pasta
    If ! ExistDir(cPasta)
        MakeDir(cPasta)
    EndIf

	aTabelas := {"SB1", "SBM"} //aqui voc� pode por as outras tabelas
	nTotal := Len(aTabelas)
    
    //Enquanto houver dados
    For nAtual := 1 To Len(aTabelas)
        //Incrementa a r�gua
        nAtual++
        IncProc("Exportando tabela " + Alltrim(cTabAtu) + " (" + cValToChar(nAtual) + " de " + cValToChar(nTotal) + ")...")

        //Busca a estrutura da tabela
		cTabAtu := aTabelas[nAtual]
        DbSelectArea(cTabAtu)
        aEstrutTab := (cTabAtu)->(DbStruct())

        //Monta a query de exporta��o
        cQryExp := " SELECT " + CRLF
        cQryExp += "     R_E_C_N_O_ AS RECNO, " + CRLF
        cQryExp += "     D_E_L_E_T_ AS DELET " + CRLF
        For nCampo := 1 To Len(aEstrutTab)
            cQryExp += ", " + CRLF

            //Se for campo caractere, ir� remover as v�rgulas para n�o dar problema na importa��o
            //  Por algum motivo, sem o substring, ele estourava o campo, como se 
            //  ele entendesse uma estrutura nova aumentando o tamanho do campo
            If aEstrutTab[nCampo][2] == "C"
                cQryExp += "     SUBSTRING(  REPLACE(REPLACE(REPLACE( REPLACE(" + aEstrutTab[nCampo][1] + ", ',', ''), CHAR(13), '\n'), CHAR(10), ''), '''', '')  , 1, " + cValToChar(aEstrutTab[nCampo][3]) + ") AS " + aEstrutTab[nCampo][1]

            ElseIf aEstrutTab[nCampo][2] == "M"
                cQryExp += "     REPLACE(REPLACE(REPLACE( REPLACE(ISNULL(CAST(CAST(" + aEstrutTab[nCampo][1] + " AS VARBINARY(8000)) AS VARCHAR(8000)),''), ',', ''), CHAR(13), '\n'), CHAR(10), ''), '''', '') AS " + aEstrutTab[nCampo][1]

            //Sen�o (num�rico, l�gico ou data), adiciona direto
            Else
                cQryExp += "     " + aEstrutTab[nCampo][1]
            EndIf
        Next
        cQryExp += CRLF
        cQryExp += " FROM " + CRLF
        cQryExp += "     " + RetSQLName(cTabAtu) + " TAB " + CRLF
        cQryExp += " WHERE " + CRLF
		cQryExp += "     D_E_L_E_T_ = '' " + CRLF
        cQryExp += " ORDER BY " + CRLF
        cQryExp += "     RECNO " + CRLF
		
		//Coloco a flag como T de Total, caso voc� mude a query para gerar poucos registros, ou com filtros de per�odo, use a flag P de parcial
		cTipoExp := "T"

        //Executa a query e realiza a exporta��o
        PLSQuery(cQryExp, 'QRY_EXP')
        If ! QRY_EXP->(EoF())
            //Monta o nome do arquivo que ser� gerado, e se ele existir, j� apaga da Protheus Data
            cArquivo := cTipoExp + "_" + Alltrim(cTabAtu) + "_" + dToS(Date()) + "_" + StrTran(Time(), ":", "-") + ".txt"
            If File(cPasta + cArquivo)
                FErase(cPasta + cArquivo)
            EndIf

            //Realiza a exporta��o
            Copy To (cPasta + cArquivo) DELIMITED WITH (cDelim)
            cCabecalho := fCabecalho()

            //Insere o cabe�alho com o nome das colunas no arquivo
            nHandle := FOpen(cPasta + cArquivo, FO_READWRITE + FO_SHARED )
            FSeek(nHandle, 0, FS_SET)
            FWrite(nHandle, cCabecalho + CRLF, Len(cCabecalho + CRLF))
            FClose(nHandle)
        EndIf
        QRY_EXP->(DbCloseArea())
		
    Next

    RestArea(aArea)
Return

Static Function fCabecalho()
    Local nCampo := 0
    Local aEstrut := QRY_EXP->(DbStruct())
    Local cCabecalho := ""

    //Percorre a estrutura de campos e adiciona na linha de cabe�alho
    For nCampo := 1 To Len(aEstrut)
        If ! Empty(cCabecalho)
            cCabecalho += ','
        EndIf
        cCabecalho += cDelim + Alltrim(aEstrut[nCampo][1]) + cDelim
    Next
Return cCabecalho
