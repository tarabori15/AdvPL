//Bibliotecas
#Include "Totvs.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} User Function zVid0026
Fun��o que cria tabela tempor�ria
@author Atilio
@since 16/03/2022
@version 1.0
/*/

User Function zVid0026()
	Local aArea := FWGetArea()
	Local aPergs   := {}
	Local cGrupoDe := Space(TamSX3('BM_GRUPO')[1])
	Local cGrupoAt := StrTran(cGrupoDe, ' ', 'Z')
	
	//Adicionando os parametros do ParamBox
	aAdd(aPergs, {1, "Grupo De", cGrupoDe,  "", ".T.", "SBM", ".T.", 80,  .F.})
	aAdd(aPergs, {1, "Grupo At�", cGrupoAt,  "", ".T.", "SBM", ".T.", 80,  .T.})
	
	//Se a pergunta for confirma, chama a tela
	If ParamBox(aPergs, "Informe os parametros")
		fMontaTela()
	EndIf
	
	FWRestArea(aArea)
Return

/*/{Protheus.doc} fMontaTela
Monta a tela com a marca��o de dados
@author Atilio
@since 16/03/2022
@version 1.0
/*/

Static Function fMontaTela()
    Local aArea         := GetArea()
    Local aCampos := {}
    Local oTempTable := Nil
    Local aColunas := {}
    Local cFontPad    := 'Tahoma'
    Local oFontGrid   := TFont():New(cFontPad,,-14)
    //Janela e componentes
    Private oDlgExemp
    Private oPanGrid
    Private oBrowse
    Private cAliasTmp := GetNextAlias()
    //Tamanho da janela
    Private aTamanho := MsAdvSize()
    Private nJanLarg := aTamanho[5]
    Private nJanAltu := aTamanho[6]
     
    //Adiciona as colunas que ser�o criadas na tempor�ria
    aAdd(aCampos, { 'BM_GRUPO', 'C', 4, 0}) //C�digo
    aAdd(aCampos, { 'BM_DESC', 'C', 30, 0}) //Descri��o

    //Cria a tabela tempor�ria
    oTempTable:= FWTemporaryTable():New(cAliasTmp)
    oTempTable:SetFields( aCampos )
    oTempTable:Create()  

    //Popula a tabela tempor�ria
    Processa({|| fPopula()}, 'Processando...')

    //Adiciona as colunas que ser�o exibidas no FWMarkBrowse
    aColunas := fCriaCols()
     
    //Criando a janela
    DEFINE MSDIALOG oDlgExemp TITLE 'Tela de exemplo' FROM 000, 000  TO nJanAltu, nJanLarg COLORS 0, 16777215 PIXEL
        //Dados
        oPanGrid := tPanel():New(001, 001, '', oDlgExemp, , , , RGB(000,000,000), RGB(254,254,254), (nJanLarg/2)-1,     (nJanAltu/2 - 1))
        oBrowse := FWBrowse():New()
        oBrowse:SetAlias(cAliasTmp)                
        oBrowse:SetDescription('Fun��o de navega��o na tabela tempor�ria')
        oBrowse:DisableFilter()
        oBrowse:DisableConfig()
        oBrowse:DisableSeek()
        oBrowse:DisableSaveConfig()
        oBrowse:SetFontBrowse(oFontGrid)
        oBrowse:SetDoubleClick( {|| fDupClique() } ) 
        oBrowse:SetDataTable()
        oBrowse:SetInsert(.F.)
        oBrowse:SetDelete(.F., { || .F. })
        oBrowse:lHeaderClick := .F.
        oBrowse:SetColumns(aColunas)
        oBrowse:SetOwner(oPanGrid)
        oBrowse:Activate()
    ACTIVATE MsDialog oDlgExemp CENTERED
    
    //Deleta a tempor�ria e desativa a tela de marca��o
    oTempTable:Delete()
    oBrowse:DeActivate()
    
    RestArea(aArea)
Return

/*/{Protheus.doc} fPopula
Executa a query SQL e popula essa informa��o na tabela tempor�ria usada no browse
@author Atilio
@since 16/03/2022
@version 1.0
/*/

Static Function fPopula()
    Local cQryDados := ''
    Local nTotal := 0
    Local nAtual := 0

    //Monta a consulta
    cQryDados += "SELECT "		+ CRLF
    cQryDados += " BM_GRUPO, "		+ CRLF
    cQryDados += " BM_DESC "		+ CRLF
    cQryDados += "FROM "		+ CRLF
    cQryDados += " " + RetSQLName('SBM') + " SBM "		+ CRLF
    cQryDados += "WHERE "		+ CRLF
    cQryDados += " BM_FILIAL = '" + FWxFilial('SBM') + "' "		+ CRLF
    cQryDados += " AND BM_GRUPO >= '" + MV_PAR01 + "' "		+ CRLF
    cQryDados += " AND BM_GRUPO <= '" + MV_PAR02 + "' "		+ CRLF
    cQryDados += " AND SBM.D_E_L_E_T_ = ' '"		+ CRLF
    PLSQuery(cQryDados, 'QRYDADTMP')

    //Definindo o tamanho da r�gua
    DbSelectArea('QRYDADTMP')
    Count to nTotal
    ProcRegua(nTotal)
    QRYDADTMP->(DbGoTop())

    //Enquanto houver registros, adiciona na tempor�ria
    While ! QRYDADTMP->(EoF())
        nAtual++
        IncProc('Analisando registro ' + cValToChar(nAtual) + ' de ' + cValToChar(nTotal) + '...')

        RecLock(cAliasTmp, .T.)
            (cAliasTmp)->BM_GRUPO := QRYDADTMP->BM_GRUPO
            (cAliasTmp)->BM_DESC := QRYDADTMP->BM_DESC
        (cAliasTmp)->(MsUnlock())

        QRYDADTMP->(DbSkip())
    EndDo
    QRYDADTMP->(DbCloseArea())
    (cAliasTmp)->(DbGoTop())
Return

/*/{Protheus.doc} fCriaCols
Fun��o que gera as colunas usadas no browse (similar ao antigo aHeader)
@author Atilio
@since 16/03/2022
@version 1.0
/*/

Static Function fCriaCols()
    Local nAtual       := 0 
    Local aColunas := {}
    Local aEstrut  := {}
    Local oColumn
    
    //Adicionando campos que ser�o mostrados na tela
    //[1] - Campo da Temporaria
    //[2] - Titulo
    //[3] - Tipo
    //[4] - Tamanho
    //[5] - Decimais
    //[6] - M�scara
    aAdd(aEstrut, { 'BM_GRUPO', 'C�digo', 'C', 4, 0, ''})
    aAdd(aEstrut, { 'BM_DESC', 'Descri��o', 'C', 30, 0, ''})

    //Percorrendo todos os campos da estrutura
    For nAtual := 1 To Len(aEstrut)
        //Cria a coluna
        oColumn := FWBrwColumn():New()
        oColumn:SetData(&('{|| ' + cAliasTmp + '->' + aEstrut[nAtual][1] +'}'))
        oColumn:SetTitle(aEstrut[nAtual][2])
        oColumn:SetType(aEstrut[nAtual][3])
        oColumn:SetSize(aEstrut[nAtual][4])
        oColumn:SetDecimal(aEstrut[nAtual][5])
        oColumn:SetPicture(aEstrut[nAtual][6])

        //Adiciona a coluna
        aAdd(aColunas, oColumn)
    Next
Return aColunas

/*/{Protheus.doc} fDupClique
Fun��o acionada ao dar duplo clique na grid
@author Atilio
@since 16/03/2022
@version 1.0
/*/

Static Function fDupClique()
    Local aArea   := FWGetArea()
    Local cGrupo  := (cAliasTmp)->BM_GRUPO
    Local cFunBkp := FunName()

    //Se a pergunta for confirmada, abre a visualiza��o do grupo
    If FWAlertYesNo("Deseja visualizar o grupo '" + cGrupo + "'?", "Continua?")
        DbSelectArea('SBM')
        SBM->(DbSetOrder(1)) //Filial + C�digo + Loja
        
        //Se conseguir posicionar
        If SBM->(DbSeek(FWxFilial('SBM') + cGrupo))
            SetFunName("MATA035")
            FWExecView('Visualiza��o do Grupo', 'MATA035', MODEL_OPERATION_VIEW)
            SetFunName(cFunBkp)
        EndIf

    EndIf

    FWRestArea(aArea)
Return
