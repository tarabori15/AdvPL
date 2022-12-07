//Bibliotecas
#Include "Protheus.ch"
#Include "TopConn.ch"
  
//Legendas
Static oBmpVerde    := LoadBitmap( GetResources(), "BR_VERDE")
Static oBmpVermelho := LoadBitmap( GetResources(), "BR_VERMELHO")
Static oBmpPreto    := LoadBitmap( GetResources(), "BR_PRETO")
  
/*/{Protheus.doc} zVid0024
Fun��o para ver os grupos de produto
@author Atilio
@since 24/05/2021
@version 1.0
@type function
@obs Exemplo baseado no link https://terminaldeinformacao.com/knowledgebase/msnewgetdados/
    O ideal � fazer grids com FWBrowse, por�m se precisar adaptar algum fonte legado, 
    pode-se basear no exemplo abaixo
 
    Ah, se voc� quiser copiar o CSS de outro componente, use o m�todo GetCSS() e salve em um txt
    Depois copie esse txt e coloque no SetCSS do seu componente
/*/
  
User Function zVid0024()
    Local aArea := GetArea()
    //Objetos da Janela
    Private oDlgPvt
    Private oMsGetSBM
    Private aHeadSBM := {}
    Private aColsSBM := {}
    Private oBtnSalv
    Private oBtnFech
    Private oBtnLege
    //Tamanho da Janela
    Private aSize := MsAdvSize(.F.)
    Private nJanLarg := aSize[5]
    Private nJanAltu := aSize[6]
    //Fontes
    Private    cFontUti   := "Tahoma"
    Private    oFontAno   := TFont():New(cFontUti,,-38)
    Private    oFontSub   := TFont():New(cFontUti,,-20)
    Private    oFontSubN  := TFont():New(cFontUti,,-20,,.T.)
    Private    oFontBtn   := TFont():New(cFontUti,,-14)
      
    //Criando o cabe�alho da Grid
    //              T�tulo               Campo        M�scara                        Tamanho                   Decimal                   Valid               Usado  Tipo F3     Combo
    aAdd(aHeadSBM, {"",                  "XX_COR",    "@BMP",                        002,                      0,                        ".F.",              "   ", "C", "",    "V",     "",      "",        "", "V"})
    aAdd(aHeadSBM, {"C�digo",            "BM_GRUPO",  "",                            TamSX3("BM_GRUPO")[01],   0,                        ".T.",              ".T.", "C", "",    ""} )
    aAdd(aHeadSBM, {"Descri��o",         "BM_DESC",   "",                            TamSX3("BM_DESC")[01],    0,                        "NaoVazio()",       ".T.", "C", "",    ""} )
    aAdd(aHeadSBM, {"Status Grupo",      "BM_STATUS", "",                            TamSX3("BM_STATUS")[01],  0,                        "PERTENCE('1234')", ".T.", "C", "",    "1=Novo;2=Remanufaturado;3=Reciclado;4=Usado"} )
    aAdd(aHeadSBM, {"Procedencia",       "BM_PROORI", "",                            TamSX3("BM_PROORI")[01],  0,                        "Pertence('01')",   ".T.", "C", "",    "1=Original;0=Nao Original"} )
    aAdd(aHeadSBM, {"Total de Produtos", "XX_TOTAL",  "@E 999,999,999,999,999,999",  018,                      0,                        ".T.",              ".T.", "N", "",    ""} )
    aAdd(aHeadSBM, {"SBM Recno",         "XX_RECNO",  "@E 999,999,999,999,999,999",  018,                      0,                        ".T.",              ".T.", "N", "",    ""} )
  
    Processa({|| fCarAcols()}, "Processando")
  
    //Cria��o da tela com os dados que ser�o informados
    DEFINE MSDIALOG oDlgPvt TITLE "Grupos de Produto" FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
        //Labels gerais
        @ 004, 003 SAY "TST"                SIZE 200, 030 FONT oFontAno  OF oDlgPvt COLORS RGB(149,179,215) PIXEL
        @ 004, 050 SAY "Listagem de"        SIZE 200, 030 FONT oFontSub  OF oDlgPvt COLORS RGB(031,073,125) PIXEL
        @ 014, 050 SAY "Grupos de Produtos" SIZE 200, 030 FONT oFontSubN OF oDlgPvt COLORS RGB(031,073,125) PIXEL
          
        //Bot�es
        @ 006, (nJanLarg/2-001)-(0052*01) BUTTON oBtnFech  PROMPT "Fechar"        SIZE 050, 018 OF oDlgPvt ACTION (oDlgPvt:End())                               FONT oFontBtn PIXEL
        @ 006, (nJanLarg/2-001)-(0052*02) BUTTON oBtnLege  PROMPT "Legenda"       SIZE 050, 018 OF oDlgPvt ACTION (fLegenda())                                  FONT oFontBtn PIXEL
        @ 006, (nJanLarg/2-001)-(0052*03) BUTTON oBtnSalv  PROMPT "Salvar"        SIZE 050, 018 OF oDlgPvt ACTION (fSalvar())                                   FONT oFontBtn PIXEL
        @ 006, (nJanLarg/2-001)-(0052*04) BUTTON oBtnCopi  PROMPT "Copiar"        SIZE 050, 018 OF oDlgPvt ACTION (fCopiar())                                   FONT oFontBtn PIXEL
          
        //Grid dos grupos
        oMsGetSBM := MsNewGetDados():New(    029,;                //nTop      - Linha Inicial
                                            003,;                //nLeft     - Coluna Inicial
                                            (nJanAltu/2)-3,;     //nBottom   - Linha Final
                                            (nJanLarg/2)-3,;     //nRight    - Coluna Final
                                            GD_INSERT + GD_UPDATE + GD_DELETE,;                   //nStyle    - Estilos para edi��o da Grid (GD_INSERT = Inclus�o de Linha; GD_UPDATE = Altera��o de Linhas; GD_DELETE = Exclus�o de Linhas)
                                            "AllwaysTrue()",;    //cLinhaOk  - Valida��o da linha
                                            ,;                   //cTudoOk   - Valida��o de todas as linhas
                                            "",;                 //cIniCpos  - Fun��o para inicializa��o de campos
                                            ,;                   //aAlter    - Colunas que podem ser alteradas
                                            ,;                   //nFreeze   - N�mero da coluna que ser� congelada
                                            9999,;               //nMax      - M�ximo de Linhas
                                            ,;                   //cFieldOK  - Valida��o da coluna
                                            ,;                   //cSuperDel - Valida��o ao apertar '+'
                                            ,;                   //cDelOk    - Valida��o na exclus�o da linha
                                            oDlgPvt,;            //oWnd      - Janela que � a dona da grid
                                            aHeadSBM,;           //aHeader   - Cabe�alho da Grid
                                            aColsSBM)            //aCols     - Dados da Grid
        oMsGetSBM:oBrowse:SetCSS(;
            "QHeaderView::Section {font-weight: bold;} " +; //Cabe�allho
            "QTableView { font-size: 14px; } "; //Grid
        )
          
    ACTIVATE MSDIALOG oDlgPvt CENTERED
      
    RestArea(aArea)
Return
  
/*------------------------------------------------*
 | Func.: fCarAcols                               |
 | Desc.: Fun��o que carrega o aCols              |
 *------------------------------------------------*/
  
Static Function fCarAcols()
    Local aArea  := GetArea()
    Local cQry   := ""
    Local nAtual := 0
    Local nTotal := 0
    Local oBmpAux
      
    //Seleciona dados do documento de entrada
    cQry := " SELECT "                                                  + CRLF
    cQry += "     BM_GRUPO, "                                           + CRLF
    cQry += "     BM_DESC, "                                            + CRLF
    cQry += "     BM_STATUS, "                                          + CRLF
    cQry += "     BM_PROORI, "                                          + CRLF
    cQry += "     ( "                                                   + CRLF
    cQry += "         SELECT "                                          + CRLF
    cQry += "             COUNT(*) "                                    + CRLF
    cQry += "         FROM "                                            + CRLF
    cQry += "             " + RetSQLName('SB1') + " SB1 "               + CRLF
    cQry += "         WHERE "                                           + CRLF
    cQry += "             B1_FILIAL = '" + FWxFilial('SB1') + "' "      + CRLF
    cQry += "             AND B1_GRUPO = BM_GRUPO "                     + CRLF
    cQry += "             AND B1_MSBLQL != '1' "                        + CRLF
    cQry += "             AND SB1.D_E_L_E_T_ = ' ' "                    + CRLF
    cQry += "     ) AS TOT_PROD, "                                      + CRLF
    cQry += "     SBM.R_E_C_N_O_ AS SBMREC "                            + CRLF
    cQry += " FROM "                                                    + CRLF
    cQry += "     " + RetSQLName('SBM') + " SBM "                       + CRLF
    cQry += " WHERE "                                                   + CRLF
    cQry += "     BM_FILIAL = '" + FWxFilial('SBM') + "' "              + CRLF
    cQry += "     AND SBM.D_E_L_E_T_ = ' ' "                            + CRLF
    cQry += " ORDER BY "                                                + CRLF
    cQry += "     BM_GRUPO "                                            + CRLF
    TCQuery cQry New Alias "QRY_SBM"
      
    //Setando o tamanho da r�gua
    Count To nTotal
    ProcRegua(nTotal)
      
    //Enquanto houver dados
    QRY_SBM->(DbGoTop())
    While ! QRY_SBM->(EoF())
      
        //Atualizar r�gua de processamento
        nAtual++
        IncProc("Adicionando " + Alltrim(QRY_SBM->BM_GRUPO) + " (" + cValToChar(nAtual) + " de " + cValToChar(nTotal) + ")...")
          
        //Definindo a legenda padr�o como preto
        oBmpAux := oBmpPreto
          
        //Se for Original ser� verde
        If QRY_SBM->BM_PROORI == '1'
            oBmpAux := oBmpVerde
          
        //Sen�o, se for N�o Original, ser� vermelho
        ElseIf QRY_SBM->BM_PROORI == '0'
            oBmpAux := oBmpVermelho
        EndIf
          
        //Adiciona o item no aCols
        aAdd(aColsSBM, { ;
            oBmpAux,;
            QRY_SBM->BM_GRUPO,;
            QRY_SBM->BM_DESC,;
            QRY_SBM->BM_STATUS,;
            QRY_SBM->BM_PROORI,;
            QRY_SBM->TOT_PROD,;
            QRY_SBM->SBMREC,;
            .F.;
        })
          
        QRY_SBM->(DbSkip())
    EndDo
    QRY_SBM->(DbCloseArea())
      
    RestArea(aArea)
Return
  
/*--------------------------------------------------------*
 | Func.: fLegenda                                        |
 | Desc.: Fun��o que mostra uma descri��o das legendas    |
 *--------------------------------------------------------*/
  
Static Function fLegenda()
    Local aLegenda := {}
      
    aAdd(aLegenda, {"BR_PRETO",    "Sem Classifica��o"})    
    aAdd(aLegenda, {"BR_VERDE",    "Original"})
    aAdd(aLegenda, {"BR_VERMELHO", "N�o Original"})
      
    BrwLegenda("Grupo de Produtos", "Legenda", aLegenda)
Return
  
/*--------------------------------------------------------*
 | Func.: fSalvar                                         |
 | Desc.: Fun��o que percorre as linhas e faz a grava��o  |
 *--------------------------------------------------------*/
  
Static Function fSalvar()
    Local aColsAux := oMsGetSBM:aCols
    Local nPosCod  := aScan(aHeadSBM, {|x| Alltrim(x[2]) == "BM_GRUPO"})
    Local nPosDes  := aScan(aHeadSBM, {|x| Alltrim(x[2]) == "BM_DESC"})
    Local nPosSta  := aScan(aHeadSBM, {|x| Alltrim(x[2]) == "BM_STATUS"})
    Local nPosPro  := aScan(aHeadSBM, {|x| Alltrim(x[2]) == "BM_PROORI"})
    Local nPosTot  := aScan(aHeadSBM, {|x| Alltrim(x[2]) == "XX_TOTAL"})
    Local nPosRec  := aScan(aHeadSBM, {|x| Alltrim(x[2]) == "XX_RECNO"})
    Local nPosDel  := Len(aHeadSBM) + 1
    Local nLinha   := 0
      
    DbSelectArea('SBM')
      
    //Percorrendo todas as linhas
    For nLinha := 1 To Len(aColsAux)
      
        //Posiciona no registro
        If aColsAux[nLinha][nPosRec] != 0
            SBM->(DbGoTo(aColsAux[nLinha][nPosRec]))
        EndIf
          
        //Se a linha estiver exclu�da
        If aColsAux[nLinha][nPosDel]
              
            //Se n�o for uma linha nova
            If aColsAux[nLinha][nPosRec] != 0
              
                //Se n�o tiver produtos, ai prossegue com exclus�o
                If aColsAux[nLinha][nPosTot] == 0
                    RecLock("SBM", .F.)
                        DbDelete()
                    SBM->(MsUnlock())
                EndIf
                  
            EndIf
              
        //Se a linha for inclu�da
        ElseIf aColsAux[nLinha][nPosRec] == 0
            RecLock('SBM', .T.)
                SBM->BM_FILIAL := FWxFilial("SBM")
                SBM->BM_GRUPO  := aColsAux[nLinha][nPosCod]
                SBM->BM_DESC   := aColsAux[nLinha][nPosDes]
                SBM->BM_STATUS := aColsAux[nLinha][nPosSta]
                SBM->BM_PROORI := aColsAux[nLinha][nPosPro]
            SBM->(MsUnlock())
              
        //Sen�o, ser� altera��o
        Else
            RecLock('SBM', .F.)
                SBM->BM_DESC   := aColsAux[nLinha][nPosDes]
                SBM->BM_STATUS := aColsAux[nLinha][nPosSta]
                SBM->BM_PROORI := aColsAux[nLinha][nPosPro]
            SBM->(MsUnlock())
        EndIf
          
    Next
      
    MsgInfo("Manipula��es finalizadas!", "Aten��o")
    oDlgPvt:End()
Return

/*--------------------------------------------------------*
 | Func.: fCopiar                                         |
 | Desc.: Fun��o que realiza a c�pia da linha posicionada |
 *--------------------------------------------------------*/

Static Function fCopiar()
	Local aCols   := oMsGetSBM:aCols
	Local nLinAtu := oMsGetSBM:nAt
	Local aLinha  := {}
    Local nPosTot  := aScan(aHeadSBM, {|x| Alltrim(x[2]) == "XX_TOTAL"})
    Local nPosRec  := aScan(aHeadSBM, {|x| Alltrim(x[2]) == "XX_RECNO"})

	
    //Se a pergunta for confirmada, ir� clonar a linha e adicionar na grid
	If MsgYesNo("Deseja copiar a linha posicionada?", "Aten��o")
		aLinha := aClone(aCols[nLinAtu])
        aLinha[nPosTot] := 0
        aLinha[nPosRec] := 0

		aAdd(aCols, aLinha)
		oMsGetSBM:Refresh()
	EndIf
Return
