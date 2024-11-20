unit mde.service;

{$MODE DELPHI}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, LazUTF8, Jsons, ACBrUtil, ACBrDFe, ACBrNFe;

type

  { TMDFe }

  TMDFe = class
  private

  public
    constructor Create();
    destructor Destroy; override;

    function postMDFeNFe (aJson: String): String;
    function patchMDFeXML (aJson: String): String;
  end;

implementation

uses
  pcnAuxiliar, pcnNFe, pcnConversao, pcnConversaoNFe, pcnNFeRTXT, pcnRetConsReciDFe,
  pcnRetDistDFeInt, ACBrDFeConfiguracoes, ACBrDFeSSL, ACBrDFeOpenSSL, ACBrDFeUtil,
  ACBrNFeNotasFiscais, ACBrNFeConfiguracoes;

{ TMDFe }

constructor TMDFe.Create();
begin
  // Cria diretorio.
  if not DirectoryExists(ExtractFilePath(ParamStr(0))+'temp') then
    CreateDir(ExtractFilePath(ParamStr(0))+'temp');
end;

function TMDFe.postMDFeNFe(aJson: String): String;
var
  lNFe: TACBrNFe;
  lJson: TJson;
  i: Integer;
  iDFe: Integer;
  iQtdDFe: Integer;
  lCNPJ: String;
  lultNSU: String;
  lDocZip: TdocZipCollectionItem;
  lChaveAcesso: String;
begin

  lNFe  := TACBrNFe.Create(nil);
  lJson := TJson.Create;
  try

    if not lJson.IsJsonObject(aJson) then
      Raise Exception.Create('JSON Invalid');

    // Json Parse
    lJson.Parse(aJson);

    lCNPJ   := lJson.Values['cnpj'].AsString; // Pega o CNPJ da empresa
    lultNSU := lJson.Values['nsu'].AsString;  // Pega o ultimo NSU

    // Cria diretorio baseado no CNPJ
    if not DirectoryExists(ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ) then
      CreateDir(ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ);

    // Carrega Libs
    lNFe.Configuracoes.Geral.SSLLib            := libOpenSSL;
    lNFe.Configuracoes.Geral.SSLCryptLib       := cryOpenSSL;
    lNFe.Configuracoes.Geral.SSLHttpLib        := httpOpenSSL;
    lNFe.Configuracoes.Geral.SSLXmlSignLib     := xsLibXml2;

    // Caminho dos arquivos
    lNFe.Configuracoes.Arquivos.PathSchemas  := './Schemas/NFe';
    lNFe.Configuracoes.Arquivos.Salvar       := True;
    lNFe.Configuracoes.Arquivos.PathNFe      := ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ;
    lNFe.Configuracoes.Arquivos.PathInu      := ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ;
    lNFe.Configuracoes.Arquivos.PathSalvar   := ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ;
    lNFe.Configuracoes.Arquivos.PathEvento   := ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ;

    // Ambiente
    lNFe.Configuracoes.WebServices.Ambiente := taProducao;

    // Forma de emissao
    lNFe.Configuracoes.Geral.FormaEmissao := teNormal;

    // carrega certificado
    lNFe.Configuracoes.WebServices.UF          := 'SP';
    lNFe.Configuracoes.Certificados.ArquivoPFX := ExtractFilePath(ParamStr(0))+'14422979000109.pfx';
    lNFe.Configuracoes.Certificados.Senha      := '123456';


    // Busca Resumo da NFe pelo  ltimo NSU
    lNFe.DistribuicaoDFe(35, lCNPJ, lultNSU, '');
    iQtdDFe := lNFe.WebServices.DistribuicaoDFe.retDistDFeInt.docZip.Count -1;

    if iQtdDFe > 0 then begin
     for i := 0 to Pred(iQtdDFe) do begin
       iDFe    := 0;
       lDocZip := lNFe.WebServices.DistribuicaoDFe.retDistDFeInt.docZip[i];
       lultNSU := lDocZip.NSU;

       if lNFe.WebServices.DistribuicaoDFe.retDistDFeInt.docZip[i].resDFe.chDFe <> '' then begin
         lChaveAcesso := lNFe.WebServices.DistribuicaoDFe.retDistDFeInt.docZip[i].resDFe.chDFe;

         // Faz ciencia da NFe
         with lNFe.EventoNFe.Evento.New do begin
           InfEvento.cOrgao   := 91;
           InfEvento.chNFe    := lChaveAcesso;
           InfEvento.CNPJ     := lCNPJ;
           InfEvento.dhEvento := now;
           InfEvento.tpEvento := teManifDestCiencia;
         end;

         // Envia manifestação
         lNFe.EnviarEvento(StrToInt(lultNSU));
         with lNFe.WebServices.EnvEvento.EventoRetorno.retEvento.Items[iDFe].RetInfEvento do begin

           iDFe := iDFe + 1;
         end;
       end;
       // Devolve o a chave de acesso o ultimo NSU
       lJson.Clear;
       lJson.Put('success', True);
       lJson.Put('nsu', lultNSU);
       lJson.Put('chaveacesso', lChaveAcesso);
       lJson.Put('message', lNFe.WebServices.DistribuicaoDFe.Msg);
     end;
    end
    else begin
       lJson.Clear;
       lJson.Put('success', False);
       lJson.Put('message', lNFe.WebServices.DistribuicaoDFe.Msg);
    end;

  finally
    Result := lJson.Stringify;
    lNFe.Free;
    lJson.Free;
  end;
end;

function TMDFe.patchMDFeXML(aJson: String): String;
var
  lNFe: TACBrNFe;
  lJson: TJson;
  lCNPJ: String;
  lChaveAcesso: String;
begin
  lNFe  := TACBrNFe.Create(nil);
  lJson := TJson.Create;
  try

    if not lJson.IsJsonObject(aJson) then
      Raise Exception.Create('JSON Invalid');

    // Json Parse
    lJson.Parse(aJson);

    lCNPJ        := lJson.Values['cnpj'].AsString; // Pega o CNPJ da empresa
    lChaveAcesso := lJson.Values['chaveacesso'].AsString; // Chave de Acesso Resumo da NFe

    // Carrega Libs
    lNFe.Configuracoes.Geral.SSLLib            := libOpenSSL;
    lNFe.Configuracoes.Geral.SSLCryptLib       := cryOpenSSL;
    lNFe.Configuracoes.Geral.SSLHttpLib        := httpOpenSSL;
    lNFe.Configuracoes.Geral.SSLXmlSignLib     := xsLibXml2;

    // Caminho dos arquivos
    lNFe.Configuracoes.Arquivos.PathSchemas  := './Schemas/NFe';
    lNFe.Configuracoes.Arquivos.Salvar       := True;
    lNFe.Configuracoes.Arquivos.PathNFe      := ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ;
    lNFe.Configuracoes.Arquivos.PathInu      := ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ;
    lNFe.Configuracoes.Arquivos.PathSalvar   := ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ;
    lNFe.Configuracoes.Arquivos.PathEvento   := ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ;

    // Ambiente
    lNFe.Configuracoes.WebServices.Ambiente := taProducao;

    // Forma de emissao
    lNFe.Configuracoes.Geral.FormaEmissao := teNormal;

    // carrega certificado
    lNFe.Configuracoes.WebServices.UF          := 'SP';
    lNFe.Configuracoes.Certificados.ArquivoPFX := ExtractFilePath(ParamStr(0))+'14422979000109.pfx';
    lNFe.Configuracoes.Certificados.Senha      := '123456';

    // Valida se chave de acesso está autorizada
    lNFe.NotasFiscais.Clear;
    lNFe.WebServices.Consulta.NFeChave := lChaveAcesso;
    lNFe.WebServices.Consulta.Executar;

    if lNFe.WebServices.Consulta.XMotivo = 'Autorizado o uso da NF-e' then begin
     lNFe.NotasFiscais.Clear;

     // Baixa XML Sefaz
     lNFe.DistribuicaoDFePorChaveNFe(35, lCNPJ, lChaveAcesso);

     if FileExists(ExtractFilePath(ParamStr(0))+'temp/'+lCNPJ+'/'+lChaveAcesso+'-nfe.xml') then begin
       lJson.Clear;
       lJson.Put('success', True);
       lJson.Put('message','Arquivo(s) XML baixado com sucesso.');
     end
     else begin
       lJson.Clear;
       lJson.Put('success', False);
       lJson.Put('message','Arquivo xml não encontrado.');
     end;
    end
    else begin
      lJson.Clear;
      lJson.Put('success', False);
      lJson.Put('message','Sem arquivo(s) XML para baixar.');
    end;
  finally
    Result := lJson.Stringify;
    lNFe.Free;
    lJson.Free;
  end;
end;

destructor TMDFe.Destroy;
begin
  inherited Destroy;
end;

end.

