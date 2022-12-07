/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/04/04/validar-o-tamanho-de-um-arquivo-em-advpl-ti-responde-005/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include "TOTVS.ch"

/*/{Protheus.doc} User Function zVid0005
Fun��o de exemplo para validar o tamanho de um arquivo em AdvPL
@type  Function
@author Atilio
@since 27/11/2021
@version version
/*/

User Function zVid0005()
    Local aArea    := GetArea()
    Local cArquivo := "C:\OBS\Atilio Sistemas\Q100 F�cil.mp4"
    Local oFile
    Local nTamanho := 0
    Local cMascara := "@E 999,999,999,999,999,999"

    //Realiza a abertura do arquivo para pegar o tamanho em bytes
    oFile := FWFileReader():New(cArquivo)
    If oFile:Open()
        nTamanho := oFile:GetFileSize()
        oFile:Close()
    EndIf

    //Se tiver tamanho, exibe uma mensagem para o usu�rio
    If nTamanho > 0
        MsgInfo("O arquivo <strong>" + cArquivo + "</strong>, possui <strong>" + Alltrim(Transform(nTamanho, cMascara)) + " bytes</strong>", "Aten��o")
    EndIf

    RestArea(aArea)
Return
