unit mde.router;

{$MODE DELPHI}{$H+}

interface

uses
  Classes, SysUtils, Horse, mde.service;

type

  { TMDE }

  TMDE = class
  public
    class procedure MDE;
  end;

  function TiraPontos(texto : String) : String;

implementation

{ TMDE }

function TiraPontos(texto: String): String;
begin
  While pos('-', Texto) <> 0 Do
    delete(Texto,pos('-', Texto),1);

  While pos('.', Texto) <> 0 Do
    delete(Texto,pos('.', Texto),1);

  While pos('/', Texto) <> 0 Do
    delete(Texto,pos('/', Texto),1);

  While pos(',', Texto) <> 0 Do
    delete(Texto,pos(',', Texto),1);

  While pos('(', Texto) <> 0 Do
    delete(Texto,pos('(', Texto),1);

  While pos(')', Texto) <> 0 Do
    delete(Texto,pos(')', Texto),1);

  While pos(' ', Texto) <> 0 Do
    delete(Texto,pos(' ', Texto),1);

  Result := Texto;
end;

procedure postNFE(AReq: THorseRequest; ARes: THorseResponse);
var
 lService: TMDFe;
begin

  // Cria mde.service;
  lService := TMDFe.Create();

  // Execulta o Request
   aRes.ContentType('application/json')
      .Send(lService.postMDFeNFe(AReq.Body()));
end;

procedure pathXML(AReq: THorseRequest; ARes: THorseResponse);
var
 lService: TMDFe;
begin

  // Cria mde.service;
  lService := TMDFe.Create();

  // Execulta o Request
  aRes.ContentType('application/json')
      .Send(lService.patchMDFeXML(AReq.Body()));
end;

class procedure TMDE.MDE;
begin
  THorse.Group()
        .POST('nfe', postNFE)
        .Patch('nfe', pathXML);
end;

end.

