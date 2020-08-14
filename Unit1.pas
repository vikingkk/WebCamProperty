unit Unit1;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  inifiles,
  ComCtrls,
  JPEG,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  VSample,
  VFrames, {$IFDEF DXErr} DXErr9, {$ENDIF}
  DirectShow9;

type
  TPropertyControl = record
    PCLabel: TLabel;
    PCTrackbar: TTrackBar;
    PCCheckbox: TCheckBox;
  end;

  TVideoSampleCallBack = procedure(pb: pbytearray; var Size: integer) of object;

  TSampleGrabberCBInt = interface(ISampleGrabberCB)
    function SampleCB(SampleTime: Double; pSample: IMediaSample): HResult; stdcall;
    function BufferCB(SampleTime: Double; pBuffer: PByte; BufferLen: longint): HResult; stdcall;
  end;

  TSampleGrabberCB = class(TInterfacedObject, TSampleGrabberCBInt)
    FSampleGrabberCB: TSampleGrabberCBImpl;
    CallBack: TVideoSampleCallBack;
    property SampleGrabberCB: TSampleGrabberCBImpl read FSampleGrabberCB implements TSampleGrabberCBInt;
  end;

  TFormatInfo = record
    Width, Height: integer;
    SSize: cardinal;
    OIndex: integer;
    pmt: PAMMediaType;
    FourCC: array [0 .. 3] of char;
  end;

type
  PRGBTripleArray = ^TRGBTripleArray;
  TRGBTripleArray = array [0 .. 4095] of TRGBTriple;

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
    Memo2: TMemo;
    Button_redefult: TButton;
    Timer1: TTimer;
    Button_Stop: TButton;
    procedure btnTakeClickClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure Button_fitClick(Sender: TObject);
    procedure Button_SavePropertyClick(Sender: TObject);
    procedure Button_LoadPropertyClick(Sender: TObject);
    procedure Button_CallPropertyClick(Sender: TObject);
    procedure Button_CallImageSettingClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Memo2Click(Sender: TObject);
    procedure ComboBox_CamsChange(Sender: TObject);
    procedure Button_redefultClick(Sender: TObject);
    procedure Button_StopClick(Sender: TObject);

    private
      { Private declarations }
      Initialized: boolean;
      OnNewFrameBusy: boolean;
      fFrameCnt    : integer;
      fSkipCnt     : integer;
      f30FrameTick : integer;
      VideoImage   : TVideoImage;
      VideoBMPIndex: integer;
      VideoBMP     : array [0 .. 1] of TBitmap;
      // Used below in case we want to paint the image by ourselfs....
      CopyBMP  : TBitmap;
      ModeBMP  : TBitmap;
      DiffCol  : array [-255 .. 255] of byte;
      DiffRatio: Double;
      AppPath  : string;
      SpyIndex : integer;
      LocalJPG : TJPEGImage;
      PropCtrl : array [TVideoProperty] of TPropertyControl;
      PropContralCtrl: array [TVideoControlProperty] of TPropertyControl;
      fileName: string;

      procedure CleanPaintBoxVideo;
      procedure OnNewFrame(Sender: TObject; Width, Height: integer; DataPtr: pointer);
      procedure PropertyTrackBarChange(Sender: TObject);
      procedure PropertyCheckBoxClick(Sender: TObject);
      procedure ControlPropertyTrackBarChange(Sender: TObject);
      procedure ControlPropertyCheckBoxClick(Sender: TObject);
    public
      { Public declarations }
      procedure InitFrame;
      procedure UpdateCamList;
      function SetVideoSizeByListIndex(ListIndex: integer): HResult;
      function GetCaptureIAMStreamConfig(var pSC: IAMStreamConfig): HResult;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.btnTakeClickClick(Sender: TObject);
var
  i : integer;
  SL: TStringList;
  VP: TVideoProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
  VCP     : TVideoControlProperty;
begin
  // Video already initialized, but paused?

  if assigned(VideoImage) then
    if VideoImage.IsPaused then
    begin
      VideoImage.VideoResume;
      exit;
    end;
  VideoImage.VideoStart('#' + IntToStr(ComboBox_Cams.itemIndex + 1));
  Screen.Cursor := crDefault;
  Application.ProcessMessages;

  SL := TStringList.Create;
  VideoImage.GetListOfSupportedVideoSizes(SL);

  ComboBox1.Items.Assign(SL);
  SL.Free;

  VideoImage.SetResolutionByIndex(20);

  for VP := low(TVideoProperty) to high(TVideoProperty) do
  begin
    if Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropCtrl[VP] do
      begin
        PCLabel.Enabled := true;
        // PCTrackbar.Enabled := AutoMode xor true;
        PCTrackbar.Max := MaxVal;
        PCTrackbar.min := MinVal;
        PCTrackbar.Frequency := StepSize;
        PCTrackbar.Position := Actual;
        PCCheckbox.Enabled := true;
        PCCheckbox.Checked := not(AutoMode);
      end;
    end
    else
    begin
      with PropCtrl[VP] do
      begin
        PCLabel.Enabled := false;
        PCCheckbox.Enabled := false;
        PCLabel.Enabled := false;
        PCTrackbar.Enabled := false;
      end;
    end;
  end;
  for VCP := low(TVideoControlProperty) to high(TVideoControlProperty) do
  begin
    if Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin

      with PropContralCtrl[VCP] do
      begin
        // PCTrackbar.Enabled := true xor Automode;
        PCTrackbar.Enabled := true;
        PCLabel.Enabled := true;
        PCTrackbar.min := MinVal;
        PCTrackbar.Max := MaxVal;
        PCTrackbar.Frequency := StepSize;
        PCTrackbar.Position := Actual;
        PCTrackbar.Enabled := AutoMode;
        PCCheckbox.Checked := not(AutoMode);
      end;
    end
    else
    begin
      with PropContralCtrl[VCP] do
      begin
        PCLabel.Enabled := false;
        PCCheckbox.Enabled := false;
        PCLabel.Enabled := false;
        PCTrackbar.Enabled := false;
      end;
    end;
  end;

end;

procedure TForm1.InitFrame;
var
  i  : integer;
  VP : TVideoProperty;
  VCP: TVideoControlProperty;
begin
  if Initialized then
    exit;
  Initialized := true;
  LocalJPG    := TJPEGImage.Create;
  AppPath     := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  // SpeedButton_Stop.Enabled := false;

  // --- Instantiate TVideoImage
  VideoImage := TVideoImage.Create;
  // VideoImage.SetDisplayCanvas(PaintBox_Video.Canvas); // For automatically drawing video frames on paintbox
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

  for VP := low(TVideoProperty) to high(TVideoProperty) do
    with PropCtrl[VP] do
    begin
      PCLabel := TLabel.Create(Panel3);
      PCLabel.Parent := Panel3;
      PCLabel.Left := 8;
      PCLabel.Top  := 20 + integer(VP) * 26 + integer(VP) * 26;
      PCLabel.Caption := GetVideoPropertyName(VP);

      PCTrackbar := TTrackBar.Create(Panel3);
      PCTrackbar.Parent := Panel3;
      PCTrackbar.Left := 0;
      PCTrackbar.Top := PCLabel.Top - 8 + 26;
      PCTrackbar.Width := 210;
      PCTrackbar.Tag := integer(VP);
      PCTrackbar.Enabled := true;
      PCTrackbar.ThumbLength := 9;
      PCTrackbar.Height := 25;
      PCTrackbar.TickMarks := tmBoth;
      PCTrackbar.OnChange := PropertyTrackBarChange;
      PCTrackbar.Anchors := [akLeft, akTop, akRight];

      PCCheckbox := TCheckBox.Create(Panel3);
      PCCheckbox.Parent := Panel3;
      PCCheckbox.Left := PCTrackbar.Left + PCTrackbar.Width + 8;
      PCCheckbox.Top := PCLabel.Top - 3 + 26;
      PCCheckbox.Tag := integer(VP);
      PCCheckbox.Enabled := true;
      PCCheckbox.Caption := '';
      PCCheckbox.Width := PCCheckbox.Height + 4;
      PCCheckbox.OnClick := PropertyCheckBoxClick;
      PCCheckbox.Anchors := [akTop, akRight];
      PCCheckbox.Checked := false;

    end;

  for VCP := low(TVideoControlProperty) to high(TVideoControlProperty) do
    with PropContralCtrl[VCP] do
    begin
      PCLabel := TLabel.Create(Panel5);
      PCLabel.Parent := Panel5;
      PCLabel.Left := 8;
      PCLabel.Top  := 20 + integer(VCP) * 26 + integer(VCP) * 26;
      PCLabel.Caption := GetVideoControlPropertyName(VCP);

      PCTrackbar := TTrackBar.Create(Panel5);
      PCTrackbar.Parent := Panel5;
      PCTrackbar.Left := 0;
      PCTrackbar.Top := PCLabel.Top - 8 + 26;
      PCTrackbar.Width := 210;
      PCTrackbar.Tag := integer(VCP);
      PCTrackbar.Enabled := true;
      PCTrackbar.ThumbLength := 9;
      PCTrackbar.Height := 25;
      PCTrackbar.TickMarks := tmBoth;
      PCTrackbar.OnChange := ControlPropertyTrackBarChange;
      PCTrackbar.Anchors := [akLeft, akTop, akRight];

      PCCheckbox := TCheckBox.Create(Panel5);
      PCCheckbox.Parent := Panel5;
      PCCheckbox.Left := PCTrackbar.Left + PCTrackbar.Width + 8;
      PCCheckbox.Top := PCLabel.Top - 3 + 26;
      PCCheckbox.Tag := integer(VCP);
      PCCheckbox.Enabled := true;
      PCCheckbox.Caption := '';
      PCCheckbox.Width := PCCheckbox.Height + 4;
      PCCheckbox.OnClick := ControlPropertyCheckBoxClick;
      PCCheckbox.Anchors := [akTop, akRight];
      PCCheckbox.Checked := false;

    end;

end;

procedure TForm1.Memo2Click(Sender: TObject);
var
  i : integer;
  SL: TStringList;
  VP: TVideoProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
  VCP     : TVideoControlProperty;
begin
  Memo2.Text := '';
  Memo2.Lines.Add('Camera Index : ' + IntToStr(ComboBox1.ItemIndex));
  for VP := low(TVideoProperty) to high(TVideoProperty) do
  begin
    if Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropCtrl[VP] do
      begin
        Memo2.Lines.Add(GetVideoPropertyName(VP) + ' : ' + IntToStr(Actual));
      end;
    end
    else
    begin
      with PropCtrl[VP] do
      begin
        PCLabel.Enabled := false;
      end;
    end;
  end;

  for VCP := low(TVideoControlProperty) to high(TVideoControlProperty) do
  begin
    if Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin

      with PropContralCtrl[VCP] do
      begin
        Memo2.Lines.Add(GetVideoControlPropertyName(VCP) + ' : ' + IntToStr(Actual));
      end;
    end
    else
    begin
      with PropContralCtrl[VCP] do
      begin
        PCLabel.Enabled := false;
      end;
    end;
  end;
  //ComboBox1.ItemIndex:=f-1;
  Memo2.Lines.Add('Webcam Resolution : ' + IntToStr(ComboBox1.ItemIndex+1));
end;

procedure TForm1.OnNewFrame(Sender: TObject; Width, Height: integer; DataPtr: pointer);
begin

  VideoBMPIndex := 1 - VideoBMPIndex;
  VideoImage.GetBitmap(VideoBMP[VideoBMPIndex]);
  ModeBMP.Assign(VideoBMP[VideoBMPIndex]);
  PaintBox_Video.Canvas.Draw(0, 0, ModeBMP);

end;

procedure TForm1.UpdateCamList;
var
  SL: TStringList;
begin
  // Load ComboBox_Cams with list of available video interfaces (WebCams...)
  SL := TStringList.Create;
  VideoImage.GetListOfDevices(SL);
  ComboBox_Cams.Items.Assign(SL);
  SL.Free;

  // At least one WebCam found: enable "Run video" button
  // SpeedButton_RunVideo.Enabled := false;
  if ComboBox_Cams.Items.Count > 0 then
  begin
    if (ComboBox_Cams.itemIndex < 0) or (ComboBox_Cams.itemIndex >= ComboBox_Cams.Items.Count) then
      ComboBox_Cams.itemIndex := 0;
    // SpeedButton_RunVideo.Enabled := true;
  end
  else
  begin
    ComboBox_Cams.Items.Add('No cameras found.');
    // SpeedButton_RunVideo.Enabled := false;
  end;
end;

procedure TForm1.Button_SavePropertyClick(Sender: TObject);
var
  VP          : TVideoProperty;
  VCP         : TVideoControlProperty;
  SL: TStringList;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
  temp_string : string;
  final_string: TStringList;
  path1       : string;
begin
  //Memo2.Lines.Add('Camera Index : ' + IntToStr(ComboBox1.ItemIndex));
  if ComboBox1.ItemIndex = -1 then
  begin
    showmessage('Select webcam resolution first.');
    exit;
  end;

  path1 := GetCurrentDir;
  SaveDialog1.InitialDir := path1;
  Memo1.Text  := '';
  temp_string := '[Webcam Property]' + chr($0D) + chr($0A);

  for VP := low(TVideoProperty) to high(TVideoProperty) do
    begin
      if Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
      begin
        with PropCtrl[VP] do
        begin

         temp_string := temp_string + GetVideoPropertyName(VP) + '=' + IntToStr(PropCtrl[VP].PCTrackbar.Position) + chr($0D) + chr($0A);

        end;
      end;
    end;

  for VCP := low(TVideoControlProperty) to high(TVideoControlProperty) do
    begin
      if Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
      begin
        with PropContralCtrl[VCP] do
        begin

         temp_string := temp_string + GetVideoControlPropertyName(VCP) + '=' + IntToStr(PropContralCtrl[VCP].PCTrackbar.Position) +
         chr($0D) + chr($0A);

        end;
      end;
    end;


  temp_string := temp_string + 'Webcam_Size' + '=' + IntToStr(ComboBox1.itemIndex + 1) + chr($0D) + chr($0A);
  temp_string := temp_string + 'Resolution' + '=' + ComboBox1.Text + chr($0D) + chr($0A);

  Memo1.Lines.Add(temp_string);
  if SaveDialog1.Execute then
  begin
    // SaveDialog1.FileName
    if Pos('.ini', SaveDialog1.fileName) > 0 then
    begin
      Memo1.Lines.SaveToFile(SaveDialog1.fileName);
    end
    else
    begin
      Memo1.Lines.SaveToFile(SaveDialog1.fileName + '.ini');
    end;

  end
  else
  begin
    exit;
  end;
end;

procedure TForm1.Button_StopClick(Sender: TObject);
begin
  Application.ProcessMessages;
  VideoImage.VideoStop;
  UpdateCamList;
end;

procedure TForm1.Button_CallImageSettingClick(Sender: TObject);
begin
  VideoImage.ShowProperty_Stream;
end;

procedure TForm1.Button_CallPropertyClick(Sender: TObject);
var
  SL: TStringList;
  VP: TVideoProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
  VCP     : TVideoControlProperty;
begin
  VideoImage.ShowProperty;
end;

procedure TForm1.Button_fitClick(Sender: TObject);
var
  i : integer;
  VP: TVideoProperty;
begin

  if (ModeBMP.Width + Panel3.Width + 22) > 1146 then
  begin
    Form1.Width := ModeBMP.Width + Panel3.Width + 22;
  end;
  if (ModeBMP.Height + Panel1.Height + 45) > 594 then
  begin
    Form1.Height := ModeBMP.Height + Panel1.Height + 45;
  end;

end;

procedure TForm1.Button_LoadPropertyClick(Sender: TObject);
var
  path1: string;
  VP   : TVideoProperty;
  VCP  : TVideoControlProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
  i       : integer;
  cfg     : Tinifile;
  s       : string;
  f       : integer;
begin
  path1 := ExtractFilePath(Application.ExeName);
  OpenDialog1.InitialDir := path1;
  OpenDialog1.DefaultExt := 'ini';

  if OpenDialog1.Execute then
  begin
    // OpenDialog1.FileName
    cfg    := Tinifile.Create(OpenDialog1.fileName);
    for VP := low(TVideoProperty) to high(TVideoProperty) do
    begin
      if Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
      begin
        with PropCtrl[VP] do
        begin

          s := GetVideoPropertyName(VP);
          f := cfg.Readinteger('Webcam Property', s, 999);
          PCCheckbox.Enabled := true;
          PCCheckbox.Checked := false;
          PCTrackbar.Position := f;

        end;
      end
      else
      begin
        with PropCtrl[VP] do
        begin
          PCLabel.Enabled := false;
        end;
      end;
    end;

    for VCP := low(TVideoControlProperty) to high(TVideoControlProperty) do
    begin
      if Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
      begin
        with PropContralCtrl[VCP] do
        begin

          s := GetVideoControlPropertyName(VCP);
          f := cfg.Readinteger('Webcam Property', s, 999);
          PCCheckbox.Enabled := true;
          PCCheckbox.Checked := false;
          PCTrackbar.Position := f;

        end;
      end
      else
      begin
        with PropContralCtrl[VCP] do
        begin
          PCLabel.Enabled := false;
        end;
      end;
    end;

    s := 'Webcam_Size';
    f := cfg.Readinteger('Webcam Property', s, 999);
    if f < 999 then
    begin
      VideoImage.SetResolutionByIndex(f);
      ComboBox1.ItemIndex:=f-1;
    end;

  end;

end;

procedure TForm1.Button_redefultClick(Sender: TObject);
var
  i : integer;
  SL: TStringList;
  VP: TVideoProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
  VCP     : TVideoControlProperty;
begin

  for VCP := low(TVideoControlProperty) to high(TVideoControlProperty) do
  begin
    if Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropContralCtrl[VCP] do
      begin
        PCTrackbar.Enabled := not(AutoMode);
        PCTrackbar.Position := default;
        PCCheckbox.Checked := false;
      end;
    end
    else
    begin
      with PropContralCtrl[VCP] do
      begin
        PCLabel.Enabled := false;
      end;
    end;
  end;

  for VP := low(TVideoProperty) to high(TVideoProperty) do
  begin
    if Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropCtrl[VP] do
      begin
        PCTrackbar.Enabled := not(AutoMode);
        PCTrackbar.Position := default;
        PCCheckbox.Checked := false;
      end;
    end
    else
    begin
      with PropCtrl[VP] do
      begin
        PCLabel.Enabled := false;
      end;
    end;
  end;

  for VCP := low(TVideoControlProperty) to high(TVideoControlProperty) do
  begin
    if Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropContralCtrl[VCP] do
      begin
        PCTrackbar.Enabled := not(AutoMode);
        PCTrackbar.Position := default;
        PCCheckbox.Checked := true;
      end;
    end
    else
    begin
      with PropContralCtrl[VCP] do
      begin
        PCLabel.Enabled := false;
      end;
    end;
  end;

  for VP := low(TVideoProperty) to high(TVideoProperty) do
  begin
    if Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropCtrl[VP] do
      begin
        PCTrackbar.Enabled := not(AutoMode);
        PCTrackbar.Position := default;
        PCCheckbox.Checked := true;
      end;
    end
    else
    begin
      with PropCtrl[VP] do
      begin
        PCLabel.Enabled := false;
      end;
    end;
  end;

end;

procedure TForm1.CleanPaintBoxVideo;
begin
  PaintBox_Video.Canvas.Brush.Color := Color;
  PaintBox_Video.Canvas.rectangle(-1, -1, PaintBox_Video.Width + 1, PaintBox_Video.Height + 1);
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  CleanPaintBoxVideo;
  VideoImage.SetResolutionByIndex(ComboBox1.itemIndex);
end;

procedure TForm1.ComboBox_CamsChange(Sender: TObject);
var
  i : integer;
  SL: TStringList;
  VP: TVideoProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
  VCP     : TVideoControlProperty;
begin

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  InitFrame;
end;

function TForm1.SetVideoSizeByListIndex(ListIndex: integer): HResult;
// Sets one of the supported video stream sizes listed in "FormatArr".
// ListIndex is the index to one of the sizes from the stringlist received
// from "GetListOfVideoSizes".
var
  pSC: IAMStreamConfig;
  VideoStreamConfigCaps: TVideoStreamConfigCaps;
  p              : ^TVideoStreamConfigCaps;
  ppmt           : PAMMediaType;
  piCount, piSize: integer;
begin
  Result := GetCaptureIAMStreamConfig(pSC);
  if Succeeded(Result) then
  begin
    piCount := 0;
    piSize  := 0;
    pSC.GetNumberOfCapabilities(piCount, piSize);
    p      := @VideoStreamConfigCaps;
    Result := pSC.GetStreamCaps(2, ppmt, p^);
    if Succeeded(Result) then
      Result := pSC.SetFormat(ppmt^);
  end;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  i : integer;
  SL: TStringList;
  VP: TVideoProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
  VCP     : TVideoControlProperty;
begin
  for VP := low(TVideoProperty) to high(TVideoProperty) do
  begin
    if Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropCtrl[VP] do
      begin
        PCLabel.Caption :=GetVideoPropertyName(VP) + ' : ' + IntToStr(Actual);
      end;
    end
    else
    begin
      with PropCtrl[VP] do
      begin
        PCLabel.Enabled := false;
      end;
    end;
  end;

  for VCP := low(TVideoControlProperty) to high(TVideoControlProperty) do
  begin
    if Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin

      with PropContralCtrl[VCP] do
      begin
        PCLabel.Caption :=GetVideoControlPropertyName(VCP) + ' : ' + IntToStr(Actual);
      end;
    end
    else
    begin
      with PropContralCtrl[VCP] do
      begin
        PCLabel.Enabled := false;
      end;
    end;
  end;
end;

procedure TForm1.PropertyCheckBoxClick(Sender: TObject);
var
  VP: TVideoProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
begin
  with Sender as TCheckBox do
  begin
    VP := TVideoProperty(Tag);
    if Succeeded(VideoImage.GetVideoPropertySettings(VP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropCtrl[VP] do
      begin
        if PCCheckbox.Checked = false then
        begin
          PCTrackbar.Enabled := true;
          VideoImage.SetVideoPropertySettings(VP, default, not(PCCheckbox.Checked));
          PCTrackbar.Position := Actual;
        end
        else if PCCheckbox.Checked = true then
        begin
          PCTrackbar.Enabled := false;
          //PCTrackbar.Position := Actual;
          VideoImage.SetVideoPropertySettings(VP, default, not(PCCheckbox.Checked));
          PCLabel.Caption := GetVideoPropertyName(VP)+' '+inttostr(Actual);
        end;
      end;
    end;
  end;
end;

procedure TForm1.PropertyTrackBarChange(Sender: TObject);
var
  VP: TVideoProperty;
begin
  with Sender as TTrackBar do
  begin
    VP := TVideoProperty(Tag);
    PropCtrl[VP].PCLabel.Caption := GetVideoPropertyName(VP)+' '+inttostr(PropCtrl[VP].PCTrackbar.Position);
    VideoImage.SetVideoPropertySettings(VP, PropCtrl[VP].PCTrackbar.Position, not(PropCtrl[VP].PCCheckbox.Checked));
  end;
end;

procedure TForm1.ControlPropertyCheckBoxClick(Sender: TObject);
var
  VCP: TVideoControlProperty;
  MinVal, MaxVal, StepSize, Default, Actual: integer;
  AutoMode: boolean;
begin
  with Sender as TCheckBox do
  begin
    VCP := TVideoControlProperty(Tag);
    if Succeeded(VideoImage.GetVideoControlPropertySettings(VCP, MinVal, MaxVal, StepSize, default, Actual, AutoMode)) then
    begin
      with PropContralCtrl[VCP] do
      begin
        // PCTrackbar.Position := default;

        if PCCheckbox.Checked = false then
        begin
          PCTrackbar.Enabled := true;
          VideoImage.SetVideoControlPropertySettings(VCP, default, not(PCCheckbox.Checked));
          PCTrackbar.Position := Actual;
        end
        else if PCCheckbox.Checked = true then
        begin
          PCTrackbar.Enabled := false;


          VideoImage.SetVideoControlPropertySettings(VCP, default, not(PCCheckbox.Checked));
          //PCTrackbar.Position := default;
        end;

      end;
    end;
  end;
end;

procedure TForm1.ControlPropertyTrackBarChange(Sender: TObject);
var
  VCP: TVideoControlProperty;
begin
  with Sender as TTrackBar do
  begin
    VCP := TVideoControlProperty(Tag);
    VideoImage.SetVideoControlPropertySettings(VCP, PropContralCtrl[VCP].PCTrackbar.Position,
      not(PropContralCtrl[VCP].PCCheckbox.Checked));
    PropContralCtrl[VCP].PCLabel.Caption := GetVideoControlPropertyName(VCP)+' '+inttostr(PropContralCtrl[VCP].PCTrackbar.Position);
  end;
end;

function TForm1.GetCaptureIAMStreamConfig(var pSC: IAMStreamConfig): HResult;
begin
  // pSC := nil;
  // Result := pICapGraphBuild2.FindInterface(@PIN_CATEGORY_capture,
  // @MEDIATYPE_Video,
  // pIBFVideoSource,
  // IID_IAMStreamConfig, pSC);

end;

end.
