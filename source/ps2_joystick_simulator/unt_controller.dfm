object Form1: TForm1
  Left = 195
  Top = 115
  Width = 431
  Height = 361
  Caption = 'PSC-Joystick simulation by Aryan Layes'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 16
    Top = 120
    Width = 137
    Height = 137
  end
  object Shape2: TShape
    Left = 160
    Top = 8
    Width = 255
    Height = 255
    Shape = stCircle
    OnMouseMove = Shape2MouseMove
  end
  object Label1: TLabel
    Left = 272
    Top = 280
    Width = 32
    Height = 13
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 272
    Top = 296
    Width = 32
    Height = 13
    Caption = 'Label2'
  end
  object Label3: TLabel
    Left = 216
    Top = 280
    Width = 38
    Height = 13
    Caption = 'x-Achse'
  end
  object Label4: TLabel
    Left = 216
    Top = 296
    Width = 38
    Height = 13
    Caption = 'y-Achse'
  end
  object Memo1: TMemo
    Left = 16
    Top = 8
    Width = 137
    Height = 89
    Lines.Strings = (
      'Dieses Programm habe ich '
      'geschrieben um '
      'herauszufinden, wie man '
      'die Position des Joysticks '
      'berechnen kann.')
    ReadOnly = True
    TabOrder = 0
  end
end