/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/02/21/como-adicionar-opcoes-em-uma-rotina-padrao-sem-ter-ponto-de-entrada-no-menudef-ti-responde-002/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include "TOTVS.ch"
#Include "FWMVCDef.ch"

/*/{Protheus.doc} zVid0002
Fun��o para "clonar" a fun��o padr�o FATA110 adicionando op��es no Outras A��es
@author Atilio
@since 29/12/2021
/*/

User Function zVid0002()
    Local oBrowse     := Nil  
    Private cCadastro := "Grupos de Clientes"
    Private aRotina   := FwLoadMenuDef("FATA110")
	
	//Talvez � necess�rio chamar aqui o SetFunName dependendo da rotina padr�o

    //Adicionar a op��o no menu padr�o
    ADD OPTION aRotina TITLE "* Fun��o Teste" ACTION 'Alert("teste")'	OPERATION 8	ACCESS 0

    //Abre o browse da rotina
    oBrowse := FWMBrowse():New()
    oBrowse:SetAlias('ACY')
    oBrowse:SetDescription(cCadastro)
    oBrowse:Activate()
Return

//Busca o Model da fun��o FATA110
Static Function ModelDef()
Return FWLoadModel('FATA110')

//Busca o View da fun��o FATA110
Static Function ViewDef()
Return FWLoadView('FATA110')
