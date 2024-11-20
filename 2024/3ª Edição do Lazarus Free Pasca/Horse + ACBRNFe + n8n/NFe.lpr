program NFe;

{$MODE DELPHI}{$H+}

uses
  {$IFDEF UNIX}
    cthreads,
  {$ENDIF}
  Classes,
  SysUtils,
  Horse,
  Horse.CORS,
  Horse.Compression,
  status.router,
  mde.router;

begin
  THorse.Use(CORS());
  THorse.Use(Compression());

  // Rotas
  TStatus.Status;
  TMDE.MDE;

  {$ifndef horse_cgi}
      THorse.Listen(9095); // Console
  {$else}
      THorse.Listen; // CGI
  {$endif}

end.
