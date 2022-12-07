//Bibliotecas
#Include "TOTVS.ch"

/*/{Protheus.doc} User Function zVid0028
Fun��o para criar uma pasta padr�o de impressora
@type  Function
@author Atilio
@since 19/04/2022
@obs Acionar essa fun��o dentro do P.E. AfterLogin ou ChkExec
/*/

User Function zVid0028()
    Local aArea  := FWGetArea()
    Local cPasta := "C:\spool\"

    //Se a pasta n�o existir, ir� criar
    If ! ExistDir(cPasta)
        MakeDir(cPasta)
    EndIf

    FWRestArea(aArea)
Return
