unit status.router;

{$MODE DELPHI}{$H+}

interface

uses
  Classes, SysUtils, Horse;

type

  { TStatus }

  TStatus = class
  public
    class procedure Status;
  end;

implementation

{ TStatus }

procedure OnStatus (AReq :THorseRequest; aRes :THorseResponse; aNext :TNextProc);
begin

  // Status do Serviço
  aRes.ContentType('text/html; charset=utf-8')
      .Send(Format('<h2> Server Horse is runing version: %s</h2> server date and time: '+FormatDateTime('dd/mm/yyyy hh:mm', now), [THorse.Version]));

end;

class procedure TStatus.Status;
begin
  THorse.Get('/', OnStatus);
end;

end.

