/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/03/07/criar-um-log-em-txt-de-forma-generica-ti-responde-003/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */


//Bibliotecas
#Include "TOTVS.ch"

/*/{Protheus.doc} zLogGeneric
Classe para gerar um log gen�rico de arquivo txt
@author Atilio
@since 29/12/2021
@example
    //Vari�veis usadas
    cPasta   := "C:\logs\"
    cArquivo := "log.txt"
    lHora    := .T.

    //Cria o log
	oLogGen  := zLogGeneric():New(cPasta, cArquivo, lHora)

    //Adiciona um texto
    oLogGen:AddText("Usu�rio clicou no bot�o Confirmar")

    //Encerra e mostra o txt
    oLogGen:Finish()
/*/

Class zLogGeneric
	//Atributos
	Data cDirectory
	Data cFileName
	Data lShowTime
    Data oFWriter

	//M�todos
	Method New() CONSTRUCTOR
	Method AddText()
	Method Finish()
EndClass

Method New(cDir, cFile, lShow) Class zLogGeneric
	Default cDir  := GetTempPath()
    Default cFile := "log_" + dToS(Date()) + "_" + StrTran(Time(), ":", "-") + ".txt"
    Default lShow := .T.

    //Se a pasta n�o existir, cria ela
    If ! ExistDir(cDir)
        MakeDir(cDir)
    EndIf

    //Define os atributos
    ::cDirectory := cDir
	::cFileName  := cFile
	::lShowTime  := lShow

    //Cria o arquivo de logs
    ::oFWriter := FWFileWriter():New(::cDirectory + ::cFileName, .T.)
     
    //Se houve falha ao criar, mostra a mensagem
    If ! ::oFWriter:Create()
        Final("Houve um erro ao criar o arquivo - " + ::oFWriter:Error():Message)
    
    //Sen�o, no log escreve um cabe�alho para identificar a rotina
    Else
        ::oFWriter:Write("C�digo do Usu�rio: " + RetCodUsr() + CRLF)
        ::oFWriter:Write("Nome do Usu�rio:   " + UsrRetName(RetCodUsr()) + CRLF)
        ::oFWriter:Write("Fun��o (FunName):  " + FunName() + CRLF)
        ::oFWriter:Write("Ambiente:          " + GetEnvServer() + CRLF)
        ::oFWriter:Write(CRLF)
        ::oFWriter:Write("Log iniciado, data [" + dToC(Date()) + "] e hora [" + Time() + "]" + CRLF)
        ::oFWriter:Write("--" + CRLF)
        ::oFWriter:Write(CRLF)
    EndIf
Return Self

Method AddText(cText) Class zLogGeneric
    Default cText := ""

    //Se for mostrar a hora, adiciona ela a esquerda
    If ::lShowTime
        cText := "[" + Time() + "] " + cText
    EndIf

    //Escreve o texto do log
    ::oFWriter:Write(cText + CRLF)
Return

Method Finish() Class zLogGeneric
    //Mostra um texto no fim do arquivo
    ::oFWriter:Write(CRLF)
    ::oFWriter:Write("--" + CRLF)
    ::oFWriter:Write("Log encerrado, data [" + dToC(Date()) + "] e hora [" + Time() + "]")

    //Encerra o arquivo
    ::oFWriter:Close()

    //Se n�o for via job/webservice, abre o arquivo
    If ! IsBlind()
        ShellExecute("OPEN", ::cFileName, "", ::cDirectory, 1)
    EndIf
Return
