/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/08/29/o-que-e-mensagem-vazia-em-validacoes-mvc-ti-responde-019/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include "Totvs.ch"
#Include "TopConn.ch"

/*/{Protheus.doc} A010TOK
Ponto de entrada, na valida��o do bot�o confirmar no cadastro de Produtos
@author Atilio
@since 08/03/2022
@version 1.0
@type function
/*/

User Function A010TOK()
	Local aArea    := FWGetArea()
	Local aAreaSB1 := SB1->(FWGetArea())
	Local lRet     := .T.
	Local cGrupo   := M->B1_GRUPO
    Local cTipo    := M->B1_TIPO

    //Se for produto Acabado
    If cTipo == "PA"
        //Se o Grupo for o 3, n�o permite continuar
        If cGrupo == "0003"
            lRet := .F.

            //Se usar assim, ser� mostrado uma mensagem vazia pois a tela � em MVC
            //MsgStop("O grupo [" + cGrupo + "] n�o pode ser usado para produtos do tipo [" + cTipo + "]!", "Aten��o")

            //O certo � usar a fun��o Help
            Help(, , "Help", , "Cadastro Inv�lido!", 1, 0, , , , , , {"O grupo [" + cGrupo + "] n�o pode ser usado para produtos do tipo [" + cTipo + "]!"})
        EndIf
    EndIf

	FWRestArea(aAreaSB1)
	FWRestArea(aArea)
Return lRet
