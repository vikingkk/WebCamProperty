unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics, inifiles, ComCtrls,JPEG,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,VSample, VFrames ,{$ifdef DXErr} DXErr9, {$endif}
     DirectShow9;
type
  TPropertyControl  = RECORD
                        PCLabel    : TLabel;
                        PCTrackbar : TTrackBar;
                        PCCheckbox : TCheckBox;
                      END;
  TVideoSampleCallBack= procedure(pb : pbytearray; var Size: integer) of object;
  TSampleGrabberCBInt = interface(ISampleGrabberCB)
                          function  SampleCB(SampleTime: Double; pSample: IMediaSample): HResult; stdcall;
                          function  BufferCB(SampleTime: Double; pBuffer: PByte; BufferLen: longint): HResult; stdcall;
                        end;

  TSampleGrabberCB =    class(TInterfacedObject, TSampleGrabberCBInt)
                          FSampleGrabberCB: TSampleGrabberCBImpl;
                          CallBack    : TVideoSampleCallBack;
                          property SampleGrabberCB: TSampleGrabberCBImpl read FSampleGrabberCB implements TSampleGrabberCBInt;
                        end;


  TFormatInfo   = RECORD
                    Width,
                    Height : integer;
                    SSize  : cardinal;
                    OIndex : integer;
                    pmt    : PAMMediaType;
                    FourCC : ARRAY[0..3] OF char;
                  END;
 type
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array[0..4095] of TRGBTriple;
type
  TForm1 = class(TForm)
    Panel3: TPanel;
    Panel4: TPanel;
    Panel1: TPanel;
    ComboBox_Cams: TComboBox;
    btnTakeClick: TButton;
    ComboBox1: TComboBox;
    Button_fit: TButton;
    Button_SaveProperty: TButton;
    panel2: TPanel;
    PaintBox_Video: TPaintBox;
    Button_LoadProperty: TButton;
    SaveDialog1: TSaveDialog;
    Memo1: TMemo;
    OpenDialog1: TOpenDialog;
    Panel5: TPanel;
    Button_CallProperty: TButton;
    Button_CallImageSetting: TButton;
    procedure btnTakeClickClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button_fitClick(Sender: TObject);
    procedure Button_SavePropertyClick(Sender: TObject);
    procedure Button_LoadPropertyClick(Sender: TObject);
    procedure Button_CallPropertyClick(Sender: TObject);
    procedure Button_CallImageSettingClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

  private
    { Private declarations }
    Initialized  : boolean;
    OnNewFrameBusy: boolean;
    fFrameCnt    : integer;
    fSkipCnt     : integer;
    f30FrameTick : integer;
    VideoImage   : TVideoImage;
    VideoBMPIndex: integer;
    VideoBMP     : ARRAY[0..1] OF TBitmap;  // Used below in case we want to paint the image by ourselfs....
    CopyBMP      : TBitmap;
    ModeBMP      : TBitmap;
    DiffCol      : ARRAY[-255..255] OF byte;
    DiffRatio    : double;
    AppPath      : string;
    SpyIndex     : integer;
    LocalJPG     : TJPEGImage;
    PropCtrl            : ARRAY[TVideoProperty] OF TPropertyControl;
    PropContralCtrl     : ARRAY[TVideoControlProperty] OF TPropertyControl;
    fileName     : string;

    procedure CleanPaintBoxVideo;
    procedure OnNewFrame(Sender : TObject; Width, Height: integer; DataPtr: pointer);
    procedure PropertyTrackBarChange(Sender: TObject);
    procedure PropertyCheckBoxClick(Sender: TObject);
    procedure ControlPropertyTrackBarChange(Sender: TObject);
    procedure ControlPropertyCheckBoxClick(Sender: TObject);
  public
    { Public declarations }
    procedure InitFrame;
    procedure UpdateCamList;
    FUNCTION    SetVideoSizeByListIndex(ListIndex: integer): HResult;
    FUNCTION    GetCaptureIAMStreamConfig(VAR pSC: IAMStreamConfig): HResult;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}



procedure TForm1.btnTakeClickClick(Sender: TObject);
var
  i         : integer;
  SL        : TStringList;
  VP        : TVideoProperty;
  MinVal,
  MaxVal,
  StepSize,
  Default,
  Actual    : integer;
  AutoMode  : boolean;
  VCP       : TVideoControlProperty;
begin
  // Video already initialized, but paused?

  IF assigned(VideoImage) then
    IF VideoImage.IsPaused then
      begin
        VideoImage.VideoResume;
        exit;
      end;
  VideoImage.VideoStart('#' + IntToStr(ComboBox_Cams.itemIndex+1));
  Screen.Cursor := crDefault;
  Application.ProcessMessages;

  SL := TStringList.Create;
  VideoImage.GetListOfSupportedVideoSizes(SL);
  ComboBox1.Items.Assign(SL);
  SL.Free;

  VideoImage.SetResolutionByIndex(20);

  FOR VP := Low(TVideoProperty) TO High(TVideoProperty) DO
    BEGIN
      IF Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, Default, Actual, AutoMode)) then
        begin
          WITH PropCtrl[VP] DO
            BEGIN
              PCLabel.Enabled     := true;
              PCTrackbar.Enabled  := true;
              PCTrackbar.Min      := MinVal;
              PCTrackbar.Max      := MaxVal;
              PCTrackbar.Frequency:= StepSize;
              PCTrackbar.Position := Actual;
              PCCheckbox.Enabled  := true;
              PCCheckbox.Checked  := AutoMode;
            end;
        end
        else begin
          WITH PropCtrl[VP] DO
            BEGIN
              PCLabel.Enabled := false;
            end;
        end;
    END;

   FOR VCP := Low(TVideoControlProperty) TO High(TVideoControlProperty) DO
    BEGIN
      IF Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, Default, Actual, AutoMode)) then
        begin

          WITH PropContralCtrl[VCP] DO
            BEGIN

              PCLabel.Enabled     := true;
              PCTrackbar.Enabled  := true;
              PCTrackbar.Min      := MinVal;
              PCTrackbar.Max      := MaxVal;
              PCTrackbar.Frequency:= StepSize;
              PCTrackbar.Position := Actual;
              PCCheckbox.Enabled  := true;
              PCCheckbox.Checked  := AutoMode;
            end;
        end
        else begin
          WITH PropContralCtrl[VCP] DO
            BEGIN
              PCLabel.Enabled := false;
            end;
        end;
    END;

    //Timer1.Enabled:=true;
end;

procedure TForm1.InitFrame;
var
  i  : integer;
  VP : TVideoProperty;
  VCP: TVideoControlProperty;
begin
  IF Initialized then
    EXIT;
  Initialized := true;
  LocalJPG := TJPEGImage.create;
  AppPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  //SpeedButton_Stop.Enabled := false;

  // --- Instantiate TVideoImage
  VideoImage := TVideoImage.Create;
  //VideoImage.SetDisplayCanvas(PaintBox_Video.Canvas); // For automatically drawing video frames on paintbox
  VideoImage.SetDisplayCanvas(nil); // For drawing video by ourself
  VideoImage.OnNewVideoFrame := OnNewFrame;

  // --- Load ComboBox_Cams with list of available video interfaces (WebCams...)
  UpdateCamList;

  VideoBMP[0] := TBitmap.Create;
  VideoBMP[1] := TBitmap.Create;
  ModeBMP     := TBitmap.Create;
  CopyBMP     := TBitmap.Create;
  VideoBMP[0].PixelFormat := pf24bit;
  VideoBMP[1].PixelFormat := pf24bit;

    FOR VP := Low(TVideoProperty) TO High(TVideoProperty) DO
    WITH PropCtrl[VP] DO
      BEGIN
        PCLabel           := TLabel.Create(Panel3);
        PCLabel.Parent    := Panel3;
        PCLabel.Left      := 8;
        PCLabel.Top       := 20 + Integer(VP)*26 + Integer(VP)*26;
        PCLabel.Caption   := GetVideoPropertyName(VP);

        PCTrackbar        := TTrackBar.Create(Panel3);
        PCTrackbar.Parent := Panel3;
        PCTrackbar.Left   := 0;
        PCTrackbar.Top    := PCLabel.Top-8+26;
        PCTrackbar.Width  := 210;
        PCTrackbar.Tag    := integer(VP);
        PCTrackbar.Enabled:= false;
        PCTrackbar.ThumbLength := 9;
        PCTrackbar.Height := 25;
        PCTrackbar.TickMarks := tmBoth;
        PCTrackBar.OnChange := PropertyTrackBarChange;
        PCTrackBar.Anchors := [akLeft, akTop, akRight];

        PCCheckbox        := TCheckBox.Create(Panel3);
        PCCheckbox.Parent := Panel3;
        PCCheckbox.Left   := PCTrackbar.Left + PCTrackbar.Width + 8;
        PCCheckbox.Top    := PCLabel.Top-3+26;
        PCCheckbox.Tag    := integer(VP);
        PCCheckbox.Enabled:= false;
        PCCheckbox.Caption:= '';
        PCCheckbox.Width  := PCCheckbox.Height+4;
        PCCheckbox.OnClick:= PropertyCheckBoxClick;
        PCCheckbox.Anchors := [akTop, akRight];
        PCCheckbox.Checked := false;

      END;

   FOR VCP := Low(TVideoControlProperty) TO High(TVideoControlProperty) DO
    WITH PropContralCtrl[VCP] DO
      BEGIN
        PCLabel           := TLabel.Create(Panel5);
        PCLabel.Parent    := Panel5;
        PCLabel.Left      := 8;
        PCLabel.Top       := 20 + Integer(VCP)*26 + Integer(VCP)*26;
        PCLabel.Caption   := GetVideoControlPropertyName(VCP);

        PCTrackbar        := TTrackBar.Create(Panel5);
        PCTrackbar.Parent := Panel5;
        PCTrackbar.Left   := 0;
        PCTrackbar.Top    := PCLabel.Top-8+26;
        PCTrackbar.Width  := 210;
        PCTrackbar.Tag    := integer(VCP);
        PCTrackbar.Enabled:= false;
        PCTrackbar.ThumbLength := 9;
        PCTrackbar.Height := 25;
        PCTrackbar.TickMarks := tmBoth;
        PCTrackBar.OnChange := ControlPropertyTrackBarChange;
        PCTrackBar.Anchors := [akLeft, akTop, akRight];

        PCCheckbox        := TCheckBox.Create(Panel5);
        PCCheckbox.Parent := Panel5;
        PCCheckbox.Left   := PCTrackbar.Left + PCTrackbar.Width + 8;
        PCCheckbox.Top    := PCLabel.Top-3+26;
        PCCheckbox.Tag    := integer(VCP);
        PCCheckbox.Enabled:= false;
        PCCheckbox.Caption:= '';
        PCCheckbox.Width  := PCCheckbox.Height+4;
        PCCheckbox.OnClick:= ControlPropertyCheckBoxClick;
        PCCheckbox.Anchors := [akTop, akRight];
        PCCheckbox.Checked := false;

      END;

end;

procedure TForm1.OnNewFrame(Sender : TObject; Width, Height: integer; DataPtr: pointer);
begin

  VideoBMPIndex := 1-VideoBMPIndex;
  VideoImage.GetBitmap(VideoBMP[VideoBMPIndex]);
  ModeBMP.assign(VideoBMP[VideoBMPIndex]);
  PaintBox_Video.Canvas.Draw(0, 0, ModeBMP);

end;

procedure TForm1.UpdateCamList;
var
  SL : TStringList;
begin
  // Load ComboBox_Cams with list of available video interfaces (WebCams...)
  SL := TStringList.Create;
  VideoImage.GetListOfDevices(SL);
  ComboBox_Cams.Items.Assign(SL);
  SL.Free;

  // At least one WebCam found: enable "Run video" button
  //SpeedButton_RunVideo.Enabled := false;
  IF ComboBox_Cams.Items.Count > 0 then
    begin
      IF (ComboBox_Cams.ItemIndex < 0) or (ComboBox_Cams.ItemIndex >= ComboBox_Cams.Items.Count) then
        ComboBox_Cams.ItemIndex := 0;
      //SpeedButton_RunVideo.Enabled := true;
    end
    else begin
      ComboBox_Cams.items.add('No cameras found.');
      //SpeedButton_RunVideo.Enabled := false;
    end;
end;

procedure TForm1.Button_SavePropertyClick(Sender: TObject);
var
  VP : TVideoProperty;
  VCP: TVideoControlProperty;
  temp_string: String;
  final_string: TStringlist;
  path1: string;
begin
   path1 := GetCurrentDir;
   SaveDialog1.InitialDir := path1;
   memo1.Text:='';
   temp_string := '[Webcam Property]'+ chr($0D) + chr($0A);
   FOR VP := Low(TVideoProperty) TO High(TVideoProperty) DO
   BEGIN
      temp_string:= temp_string +
      GetVideoPropertyName(VP)  +
      '='                       +
      inttostr(PropCtrl[VP].PCTrackbar.Position)+
      chr($0D)                  +
      chr($0A);
   END;
   FOR VCP := Low(TVideoControlProperty) TO High(TVideoControlProperty) DO
   BEGIN
      temp_string:= temp_string +
      GetVideoControlPropertyName(VCP)  +
      '='                       +
      inttostr(PropContralCtrl[VCP].PCTrackbar.Position)+
      chr($0D)                  +
      chr($0A);
   END;

   temp_string:= temp_string +
   'Webcam_Size'             +
   '='                       +
   inttostr(Combobox1.itemIndex+1)+
   chr($0D)                  +
   chr($0A);

   memo1.Lines.Add(temp_string);
   if SaveDialog1.Execute then
   begin
      //SaveDialog1.FileName
      if Pos('.ini',SaveDialog1.FileName)>0 then
      begin
        memo1.Lines.SaveToFile(SaveDialog1.FileName);
      end else
      begin
        memo1.Lines.SaveToFile(SaveDialog1.FileName+'.ini');
      end;

   end
   else
   begin
      exit;
   end;
end;

procedure TForm1.Button_CallImageSettingClick(Sender: TObject);
begin
VideoImage.ShowProperty_Stream;
end;

procedure TForm1.Button_CallPropertyClick(Sender: TObject);
var
  SL        : TStringList;
  VP        : TVideoProperty;
  MinVal,
  MaxVal,
  StepSize,
  Default,
  Actual    : integer;
  AutoMode  : boolean;
  VCP       : TVideoControlProperty;
begin
VideoImage.ShowProperty;
end;

procedure TForm1.Button_fitClick(Sender: TObject);
var
  i  : integer;
  VP : TVideoProperty;
begin

  if (ModeBMP.Width+panel3.Width+22) > 1146 then
  begin
     form1.Width:=ModeBMP.Width+panel3.Width+22;
  end;
  if (ModeBMP.Height+panel1.Height+45) > 594 then
  begin
     form1.Height:=ModeBMP.Height+panel1.Height+45;
  end;

end;

procedure TForm1.Button_LoadPropertyClick(Sender: TObject);
 var
  path1: string;
  VP : TVideoProperty;
  VCP: TVideoControlProperty;
  MinVal,
  MaxVal,
  StepSize,
  Default,
  Actual    : integer;
  AutoMode  : boolean;
  I  : Integer;
  cfg: Tinifile;
  s  : string;
  f  : integer;
begin
  path1 := ExtractFilePath(Application.ExeName);
  OpenDialog1.InitialDir := path1;
  OpenDialog1.DefaultExt := 'ini';

  if OpenDialog1.Execute then
  begin
     //OpenDialog1.FileName
    cfg := Tinifile.Create(OpenDialog1.FileName);
    FOR VP := Low(TVideoProperty) TO High(TVideoProperty) DO
    BEGIN
      IF Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, Default, Actual, AutoMode)) then
        begin
          WITH PropCtrl[VP] DO
            BEGIN

              s := GetVideoPropertyName(VP) ;
              f := cfg.Readinteger('Webcam Property', s, 999);
              PCCheckbox.Enabled  := true;
              PCCheckbox.Checked  := false;
              PCTrackbar.Position := f;

            end;
        end
        else begin
          WITH PropCtrl[VP] DO
            BEGIN
              PCLabel.Enabled := false;
            end;
        end;
    END;


    FOR VCP := Low(TVideoControlProperty) TO High(TVideoControlProperty) DO
    BEGIN
       IF Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, Default, Actual, AutoMode)) then
        begin
          WITH PropContralCtrl[VCP] DO
            BEGIN

              s := GetVideoControlPropertyName(VCP) ;
              f := cfg.Readinteger('Webcam Property', s, 999);
               PCCheckbox.Enabled  := true;
              PCCheckbox.Checked  := false;
              PCTrackbar.Position := f;

              if s = 'Focus' then
              begin
                PCCheckbox.Enabled  := false;
                PCCheckbox.Checked  := true;
              end;

            end;
        end
        else begin
          WITH PropCtrl[VP] DO
            BEGIN
              PCLabel.Enabled := false;
            end;
        end;
    END;

    s := 'Webcam_Size';
    f := cfg.Readinteger('Webcam Property', s, 999);
    if f < 999 then
    begin
      VideoImage.SetResolutionByIndex(f);
    end;



  end;

end;

procedure TForm1.CleanPaintBoxVideo;
begin
  PaintBox_Video.Canvas.Brush.Color := Color;
  PaintBox_Video.Canvas.rectangle(-1, -1, PaintBox_Video.Width+1, PaintBox_Video.Height+1);
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
CleanPaintBoxVideo;
VideoImage.SetResolutionByIndex(Combobox1.itemIndex);
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InitFrame;
end;

FUNCTION TForm1.SetVideoSizeByListIndex(ListIndex: integer): HResult;
// Sets one of the supported video stream sizes listed in "FormatArr".
// ListIndex is the index to one of the sizes from the stringlist received
// from "GetListOfVideoSizes".
VAR
  pSC                   : IAMStreamConfig;
  VideoStreamConfigCaps : TVideoStreamConfigCaps;
  p                     : ^TVideoStreamConfigCaps;
  ppmt                  : PAMMediaType;
  piCount,
  piSize                : integer;
BEGIN
  Result := GetCaptureIAMStreamConfig(pSC);
  IF Succeeded(Result) then
    begin
      piCount := 0;
      piSize  := 0;
      pSC.GetNumberOfCapabilities(piCount, piSize);
      p := @VideoStreamConfigCaps;
      Result := pSC.GetStreamCaps(2, ppmt, p^);
      IF Succeeded(Result) then
        Result := pSC.SetFormat(ppmt^);
    end;
END;

procedure TForm1.Timer1Timer(Sender: TObject);
var
BMP:TBitmap;
begin
//BMP := TBitmap.Create;
//VideoImage.GetBitmap(BMP);
//BMP.SaveToFile('C:/image/webcam.bmp');
//BMP.Free;
end;

procedure TForm1.PropertyCheckBoxClick(Sender: TObject);
VAR
  VP : TVideoProperty;
  MinVal,
  MaxVal,
  StepSize,
  Default,
  Actual    : integer;
  AutoMode  : boolean;
begin
  WITH Sender as TCheckBox DO
    BEGIN
      VP := TVideoProperty(Tag);
      IF Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, Default, Actual, AutoMode)) then
      begin
         WITH PropCtrl[VP] DO
         BEGIN
              if PCCheckbox.Checked = false then
              begin
                 PCTrackbar.Enabled  := true;
              end else if PCCheckbox.Checked = true then
              begin
                 PCTrackbar.Enabled:= false;
                 PCTrackbar.Position := Default;
              end;
         end;
      end;
    end;
end;

procedure TForm1.PropertyTrackBarChange(Sender: TObject);
VAR
  VP : TVideoProperty;
begin
  WITH Sender as TTrackBar DO
    BEGIN
      VP := TVideoProperty(Tag);
      VideoImage.SetVideoPropertySettings(VP, PropCtrl[VP].PCTrackbar.Position, PropCtrl[VP].PCCheckbox.Checked);

    end;
end;

procedure TForm1.ControlPropertyCheckBoxClick(Sender: TObject);
VAR
  VCP: TVideoControlProperty;
  MinVal,
  MaxVal,
  StepSize,
  Default,
  Actual    : integer;
  AutoMode  : boolean;
begin
  WITH Sender as TCheckBox DO
    BEGIN
      VCP := TVideoControlProperty(Tag);
      IF Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, Default, Actual, AutoMode)) then
      begin
         WITH PropContralCtrl[VCP] DO
         BEGIN
              PCTrackbar.Position := Default;
              if PCCheckbox.Checked = false then
              begin
                 PCTrackbar.Enabled:= true;
                 VideoImage.SetVideoControlPropertySettings(VCP, Default, AutoMode);
              end else if PCCheckbox.Checked = true then
              begin
                 PCTrackbar.Enabled  := false;
                 //VideoImage.SetVideoControlPropertySettings(VCP, Default, true);
                 VideoImage.SetVideoControlPropertySettings(VCP, Default, false);
              end;


         end;
      end;
    end;
end;

procedure TForm1.ControlPropertyTrackBarChange(Sender: TObject);
VAR
  VCP: TVideoControlProperty;
begin
  WITH Sender as TTrackBar DO
    BEGIN
      VCP := TVideoControlProperty(Tag);
//      if PropContralCtrl[VCP].PCCheckbox.Checked = true then
//      begin
//         VideoImage.SetVideoControlPropertySettings(VCP, PropContralCtrl[VCP].PCTrackbar.Position, false);
//      end else
//      begin
//         VideoImage.SetVideoControlPropertySettings(VCP, PropContralCtrl[VCP].PCTrackbar.Position, true);
//      end;
      //VideoImage.SetVideoControlPropertySettings(VCP, PropContralCtrl[VCP].PCTrackbar.Position, PropContralCtrl[VCP].PCCheckbox.Checked);
      VideoImage.SetVideoControlPropertySettings(VCP, PropContralCtrl[VCP].PCTrackbar.Position, true);

    end;
end;




FUNCTION TForm1.GetCaptureIAMStreamConfig(VAR pSC: IAMStreamConfig): HResult;
BEGIN
//  pSC := nil;
//  Result := pICapGraphBuild2.FindInterface(@PIN_CATEGORY_capture,
//                                           @MEDIATYPE_Video,
//                                           pIBFVideoSource,
//                                           IID_IAMStreamConfig, pSC);

END;

end.
