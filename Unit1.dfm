object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'WebCam_Tool'
  ClientHeight = 581
  ClientWidth = 1130
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel3: TPanel
    Left = 625
    Top = 0
    Width = 505
    Height = 581
    Align = alRight
    TabOrder = 0
    DesignSize = (
      505
      581)
    object Memo1: TMemo
      Left = -1
      Top = 0
      Width = 50
      Height = 25
      Lines.Strings = (
        'Memo1')
      TabOrder = 0
      Visible = False
    end
    object Panel5: TPanel
      Left = 248
      Top = 1
      Width = 256
      Height = 579
      Align = alRight
      TabOrder = 1
    end
    object Memo2: TMemo
      Left = 248
      Top = 432
      Width = 241
      Height = 139
      Anchors = [akLeft, akTop, akBottom]
      Lines.Strings = (
        'Memo2')
      ScrollBars = ssVertical
      TabOrder = 2
      OnClick = Memo2Click
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 0
    Width = 625
    Height = 581
    Align = alClient
    TabOrder = 1
    object Panel1: TPanel
      Left = 1
      Top = 1
      Width = 623
      Height = 81
      Align = alTop
      TabOrder = 0
      object ComboBox_Cams: TComboBox
        Left = 8
        Top = 9
        Width = 150
        Height = 31
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        Text = 'ComboBox_Cams'
        OnChange = ComboBox_CamsChange
      end
      object btnTakeClick: TButton
        Left = 8
        Top = 42
        Width = 73
        Height = 33
        Caption = 'Start'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = btnTakeClickClick
      end
      object ComboBox1: TComboBox
        Left = 161
        Top = 9
        Width = 150
        Height = 31
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        Text = 'WebCamSize'
        OnChange = ComboBox1Change
      end
      object Button_fit: TButton
        Left = 161
        Top = 42
        Width = 72
        Height = 33
        Caption = 'Fit Image'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        OnClick = Button_fitClick
      end
      object Button_SaveProperty: TButton
        Left = 470
        Top = 42
        Width = 150
        Height = 33
        Caption = 'Save Property'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -21
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        OnClick = Button_SavePropertyClick
      end
      object Button_CallProperty: TButton
        Left = 317
        Top = 9
        Width = 147
        Height = 31
        Caption = 'Call Property'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -19
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        OnClick = Button_CallPropertyClick
      end
      object Button_CallImageSetting: TButton
        Left = 317
        Top = 44
        Width = 147
        Height = 31
        Caption = 'Call Image Setting'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -17
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 6
        OnClick = Button_CallImageSettingClick
      end
      object Button_redefult: TButton
        Left = 236
        Top = 42
        Width = 76
        Height = 34
        Caption = 'Defult'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 7
        OnClick = Button_redefultClick
      end
    end
    object panel2: TPanel
      Left = 1
      Top = 82
      Width = 623
      Height = 498
      Align = alClient
      TabOrder = 1
      object PaintBox_Video: TPaintBox
        Left = 1
        Top = 1
        Width = 621
        Height = 496
        Align = alClient
        ExplicitLeft = -154
        ExplicitTop = -144
        ExplicitWidth = 833
        ExplicitHeight = 732
      end
    end
  end
  object Button_LoadProperty: TButton
    Left = 471
    Top = 10
    Width = 150
    Height = 31
    Caption = 'Load Property'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -21
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 2
    OnClick = Button_LoadPropertyClick
  end
  object Button_Stop: TButton
    Left = 83
    Top = 43
    Width = 75
    Height = 33
    Caption = 'Stop'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -19
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
    TabOrder = 3
    OnClick = Button_StopClick
  end
  object SaveDialog1: TSaveDialog
    Filter = 'ini|*.ini'
    Left = 584
    Top = 512
  end
  object OpenDialog1: TOpenDialog
    DefaultExt = '*.ini'
    Filter = 'ini|*.ini'
    Left = 534
    Top = 512
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 481
    Top = 512
  end
end
