/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/09/26/validacao-de-anos-em-campos-do-tipo-data-ti-responde-023/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include "TOTVS.ch"

/*/{Protheus.doc} User Function zVldData
Fun��o para validar a data digitada nos campos
@type  Function
@author Atilio
@since 14/03/2022
@obs Colocar u_zVldData() na valida��o (X3_VLDUSER) dos campos
/*/

User Function zVldData()
    Local aArea      := GetArea()
    Local dDataCampo := &(ReadVar())
    Local dDataAtu   := Date()
    Local lRet       := .T.

    //Se a diferen�a passar de 1 ano, mostrar mensagem de falha
    If DateDiffYear(dDataAtu, dDataCampo) >= 1
        Help(, , "Help", , "Cadastro Inv�lido!", 1, 0, , , , , , {"A data informada passa de 1 ano!"})
        lRet := .F.
    EndIf

    RestArea(aArea)
Return lRet
