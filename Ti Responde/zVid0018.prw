//Bibliotecas
#Include "TOTVS.ch"

/*/{Protheus.doc} User Function zVid0018
Exemplo acionando zPDFSize para diminuir arquivo
@type  Function
@author Atilio
@since 07/03/2022
/*/

User Function zVid0018()
    Local aArea := FWGetArea()

    u_zPDFSize(;
        "C:\Spool\teste2.pdf",;      //Arquivo original
        "C:\Spool\teste2_menor.pdf"; //Arquivo novo
    )

    FWRestArea(aArea)
Return
