//Bibliotecas
#Include "TOTVS.ch"

/*/{Protheus.doc} User Function MA010BUT
Ponto de entrada para adicionar fun��es no ButtonBar da Mata010
@type  Function
@author Atilio
@since 16/03/2022
@see https://tdn.engpro.totvs.com.br/pages/releaseview.action?pageId=6087592
/*/

User Function MA010BUT()
    Local aArea := FWGetArea()
    Local aButtons := {}
    
    aAdd(aButtons, {'NOTE', {|| u_zVid0027()}, '* Atualizar Grupo', '* Grupos' } )

    FWRestArea(aArea)
Return aButtons

/*/{Protheus.doc} User Function zVid0027
Fun��o para simular a digita��o do campo de grupo de produtos
@type  Function
@author Atilio
@since 16/03/2022
/*/

User Function zVid0027()
    Local aArea     := FWGetArea()
    Local aPergs    := {}
    Local cCampo    := "B1_GRUPO"
	Local cGrupo    := Space(TamSX3(cCampo)[1])
    Local cVldSis   := ""
    Local cVldUsr   := ""
    Local lContinua := .T.
    Local cConteud  := ""

    //Somente se for inclus�o ou altera��o
    If INCLUI .Or. ALTERA
        //Adicionando os parametros do ParamBox
        aAdd(aPergs, {1, "Grupo", cGrupo,  "", ".T.", "SBM", ".T.", 80,  .F.})
        
        //Se a pergunta for confirma, chama a tela
        If ParamBox(aPergs, "Informe os parametros", , , , , , , , , .F., .F.)
            cConteud := MV_PAR01

            //Busca as valida��es do campo
            cVldSis := GetSX3Cache(cCampo, "X3_VALID")
	        cVldUsr := GetSX3Cache(cCampo, "X3_VLDUSER")

            //Altera o ReadVar da Mem�ria
			__ReadVar   := "M->" + cCampo
			M->B1_GRUPO := cConteud

			//Chama a valida��o do sistema
			If ! Empty(cVldSis)
				lContinua := &(cVldSis)
			EndIf

			//Chama a valida��o de usu�rio
			If ! Empty(cVldUsr) .And. lContinua
				lContinua := &(cVldUsr)
			EndIf

            //Se deu tudo certo nas valida��es
            If lContinua
                //Como a mata010 esta em mvc, � necess�rio atualizar o campo no modelo de dados
                FWFldPut(cCampo, cConteud)

                //Chama gatilho caso exista
                If ExistTrigger(cCampo)
                    RunTrigger( ;
                        1,;           //nTipo (1=Enchoice; 2=GetDados; 3=F3)
                        Nil,;         //Linha atual da Grid quando for tipo 2
                        Nil,;         //N�o utilizado
                        ,;            //Objeto quando for tipo 1
                        cCampo;       //Campo que dispara o gatilho
                    )
                EndIf

            Else
                Help(, , "Help", , "Falha ao validar o grupo!", 1, 0, , , , , , {"Verifique se o c�digo do grupo informado esta correto"})
            EndIf
        EndIf
    EndIf

    FWRestArea(aArea)
Return
