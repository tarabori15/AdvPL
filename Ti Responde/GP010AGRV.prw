/* ===
    Esse � um exemplo disponibilizado no Terminal de Informa��o
    Confira o artigo sobre esse assunto, no seguinte link: https://terminaldeinformacao.com/2022/07/25/disparo-de-e-mail-na-admissao-e-demissao-de-funcionarios-ti-responde-015/
    Caso queira ver outros conte�dos envolvendo AdvPL e TL++, veja em: https://terminaldeinformacao.com/advpl/
=== */

//Bibliotecas
#Include 'TOTVS.ch'

/*/{Protheus.doc} User Function GP010AGRV
Ponto de entrada ap�s gravar na rotina de cadastro de funcion�rios
@type  Function
@author Atilio
@since 03/03/2022
@see https://centraldeatendimento.totvs.com/hc/pt-br/articles/360020432511-MP-ADVPL-GP010AGRV
/*/

User Function GP010AGRV()
	Local aArea     := FWGetArea()
	Local nOpc      := ParamIXB[1]
	Local lGrava    := ParamIXB[2]
	Local cCorpoMsg := ""
	Local cAssunto  := "Admiss�o de Funcion�rio (" + Alltrim(Capital(SRA->RA_NOME)) + ")"
	Local cPara     := SuperGetMV("MV_X_DESTI", .F., "email@empresa.com;")

	//Se o registro foi gravado (e for inclus�o ou c�pia)
	If lGrava .And. (nOpc == 3 .Or. nOpc == 7)
		//Monta a mensagem do email e realiza o disparo
		cCorpoMsg := '<p>Ol�.</p>' + CRLF
		cCorpoMsg += '<p>Um novo funcion�rio foi admitido, verifique se ser� necess�rio liberar acessos aos sistemas.</p>' + CRLF
		cCorpoMsg += '<p>Abaixo os dados:</p>' + CRLF
		cCorpoMsg += '<ul>' + CRLF
		cCorpoMsg += '<li><strong>Filial:</strong> ' + SRA->RA_FILIAL + '</li>' + CRLF
		cCorpoMsg += '<li><strong>Matr�cula:</strong> ' + SRA->RA_MAT + '</li>' + CRLF
		cCorpoMsg += '<li><strong>Nome:</strong> ' + Alltrim(Capital(SRA->RA_NOMECMP)) + '</li>' + CRLF
		cCorpoMsg += '</ul>' + CRLF
		cCorpoMsg += '<p>e-Mail gerado automaticamente em ' + dToC(Date()) + ' �s ' + Time() + '.</p>' + CRLF
		
		GPEMail(cAssunto, cCorpoMsg, cPara)
	EndIf

	FWRestArea(aArea)
Return
