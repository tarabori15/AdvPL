/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/07/04/como-usar-a-funcao-softlock-ti-responde-012/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include "TOTVS.ch"

/*/{Protheus.doc} User Function zVid0012
Fun��o para travar a tabela SB1 com SoftLock (ir� exibir a mensagem que tem registro bloqueado)
@type  Function
@author Atilio
@since 23/02/2022
/*/

User Function zVid0012()
    Local aArea := FWGetArea()
    Local cCodProd := "F0001"

    DbSelectArea("SB1")
    SB1->(DbSetOrder(1)) // B1_FILIAL + B1_COD

    //Posiciona no produto
    If SB1->(MsSeek(FWxFilial("SB1") + cCodProd))
        If SoftLock("SB1")
            Alert("Aqui pode ser feito valida��es antes do reclock...")

            RecLock("SB1", .F.)
                //...
            SB1->(MsUnlock())
        EndIf
    EndIf

    FWRestArea(aArea)    
Return
