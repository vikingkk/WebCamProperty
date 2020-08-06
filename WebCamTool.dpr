program WebCamTool;

uses
  Vcl.Forms,
  Unit1 in 'Unit1.pas' {Form1},
  Direct3D9 in 'DirectX\Direct3D9.pas',
  DirectDraw in 'DirectX\DirectDraw.pas',
  DirectShow9 in 'DirectX\DirectShow9.pas',
  DirectSound in 'DirectX\DirectSound.pas',
  DXTypes in 'DirectX\DXTypes.pas',
  VFrames in 'VFrames.pas',
  VSample in 'VSample.pas',
  Unit_Image_process in 'D:\Bitbucket\TQ_TDE\ipcam\Unit_Image_process.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
