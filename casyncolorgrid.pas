{ This file is part of the caSynEdit (for Lazarus/FPC) package

  Copyright (C) 1999-2017 - Carl Caulkett - carl.caulkett@gmail.com

  MODIFIED LGPL Licence - this is the same licence as that used by the Free Pascal Compiler (FPC)
  A copy of the full licence can be found in the file Licence.md in the same folder as this file.

  This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public
  License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version
  with the following modification:

  As a special exception, the copyright holders of this library give you permission to link this library with independent
  modules to produce an executable, regardless of the license terms of these independent modules, and to copy and distribute the
  resulting executable under terms of your choice, provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a module which is not derived from or based on this
  library. If you modify this library, you may extend this exception to your version of the library, but you are not obligated
  to do so. If you do not wish to do so, delete this exception statement from your version.

  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.

  You should have received a copy of the GNU Library General Public License along with this library; if not, write to the Free
  Software Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston, MA 02110-1335, USA.
}


unit casyncolorgrid;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Graphics, Dialogs, Menus,
  cargbspinedit, caMatrix, TypInfo, casynconfig;

const
  cRGBWidth = 110;
  cRowHeight = 24;

type

  { TcaSynColorGrid }

  TcaSynColorGrid = class(TCustomPanel)
  private
    FColorConfig: TcaSynConfig;
    FData: TcaMatrix;
    FMenu: TPopupMenu;
    FCopy: TMenuItem;
    FPaste: TMenuItem;
    FCopiedColor: TColor;
    // private methods
    function ColorButtonToEdit(Btn: TColorButton): TcaRGBSpinEdit;
    function CreateEdit: TcaRGBSpinEdit;
    function CreateLabel(const ACaption: string): TLabel;
    function CreateColorButton: TColorButton;
    function CreateCheckBox: TCheckBox;
    function EditToColorButton(Edit: TcaRGBSpinEdit): TColorButton;
    function FindAttribute(const AAttribute: string): Integer;
    function GetColorConfig: TcaSynConfig;
    procedure AddRows;
    procedure AddRow(const ARowTitle: string);
    procedure AddTitles;
    procedure ClearChildControls;
    procedure ColorChangedEvent(Sender: TObject);
    procedure CreatePopupMenu;
    procedure EditChangedEvent(Sender: TObject);
    procedure OnCopyClick(Sender: TObject);
    procedure OnPasteClick(Sender: TObject);
    procedure GetRow(AConfigType: TcaSynConfigType; var AItalic, ABold: Boolean; var AForeColor, ABackColor: TColor);
    procedure SetColorConfig(AValue: TcaSynConfig);
    procedure SetRow(AConfigType: TcaSynConfigType; AItalic, ABold: Boolean; AForeColor, ABackColor: TColor);
    procedure UpdateConfig;
    procedure UpdateFromConfig;
    // property methods
    function GetColCount: Integer;
    function GetRowCount: Integer;
    procedure SetColCount(AValue: Integer);
    procedure SetRowCount(AValue: Integer);
  protected
    property ColCount: Integer read GetColCount write SetColCount;
    property RowCount: Integer read GetRowCount write SetRowCount;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ColorConfig: TcaSynConfig read GetColorConfig write SetColorConfig;
  end;

implementation

type

{ Cols }

Cols = class
  class function Lbl: Byte;
  class function Italic: Byte;
  class function Bold: Byte;
  class function ForeBtn: Byte;
  class function ForeEdit: Byte;
  class function BackBtn: Byte;
  class function BackEdit: Byte;
  class function Count: Byte;
end;

{ Cols }

class function Cols.Lbl: Byte;
begin
  Result := 0;
end;

class function Cols.Italic: Byte;
begin
  Result := 1;
end;

class function Cols.Bold: Byte;
begin
  Result := 2;
end;

class function Cols.ForeBtn: Byte;
begin
  Result := 3;
end;

class function Cols.ForeEdit: Byte;
begin
  Result := 4;
end;

class function Cols.BackBtn: Byte;
begin
  Result := 5;
end;

class function Cols.BackEdit: Byte;
begin
  Result := 6;
end;

class function Cols.Count: Byte;
begin
  Result := 7;
end;

{ TcaSynColorGrid }

constructor TcaSynColorGrid.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FColorConfig := TcaSynConfig.Create;
  FData := TcaMatrix.Create(nil);
  ColCount := 7;
  RowCount := 0;
  BorderWidth := 4;
  Width := 560;
  Height := 600;
  CreatePopupMenu;
  AddRows;
end;

destructor TcaSynColorGrid.Destroy;
begin
  ClearChildControls;
  FData.Free;
  FMenu.Free;
  FColorConfig.Free;
  inherited;
end;

procedure TcaSynColorGrid.GetRow(AConfigType: TcaSynConfigType; var AItalic, ABold: Boolean; var AForeColor, ABackColor: TColor);
begin
  AItalic := TCheckBox(FData.Objects[Cols.Italic, Ord(AConfigType)]).Checked;
  ABold := TCheckBox(FData.Objects[Cols.Bold, Ord(AConfigType)]).Checked;
  AForeColor := TColorButton(FData.Objects[Cols.ForeBtn, Ord(AConfigType)]).ButtonColor;
  ABackColor := TColorButton(FData.Objects[Cols.BackBtn, Ord(AConfigType)]).ButtonColor;
end;

procedure TcaSynColorGrid.SetRow(AConfigType: TcaSynConfigType; AItalic, ABold: Boolean; AForeColor, ABackColor: TColor);
begin
  TCheckBox(FData.Objects[Cols.Italic, Ord(AConfigType)]).Checked := AItalic;
  TCheckBox(FData.Objects[Cols.Bold, Ord(AConfigType)]).Checked := ABold;
  TColorButton(FData.Objects[Cols.ForeBtn, Ord(AConfigType)]).ButtonColor := AForeColor;
  TColorButton(FData.Objects[Cols.BackBtn, Ord(AConfigType)]).ButtonColor := ABackColor;
end;

procedure TcaSynColorGrid.AddRows;
var
  ConfigType: TcaSynConfigType;
begin
  AddTitles;
  for ConfigType := Low(TcaSynConfigType) to High(TcaSynConfigType) do
    AddRow(TcaSynConfig.ConfigTypeToString(ConfigType));
end;

function TcaSynColorGrid.CreateLabel(const ACaption: string): TLabel;
var
  Lbl: TLabel;
begin
  Lbl := TLabel.Create(nil);
  Lbl.AutoSize := False;
  Lbl.Parent := Self;
  Lbl.Caption := ACaption;
  Result := Lbl;
end;

function TcaSynColorGrid.CreateColorButton: TColorButton;
var
  Btn: TColorButton;
begin
  Btn := TColorButton.Create(nil);
  Btn.Parent := Self;
  Btn.PopupMenu := FMenu;
  Btn.OnColorChanged := @ColorChangedEvent;
  Result := Btn;
end;

function TcaSynColorGrid.CreateCheckBox: TCheckBox;
var
  Chk: TCheckBox;
begin
  Chk := TCheckBox.Create(nil);
  Chk.Parent := Self;
  Chk.Caption := '';
  Result := Chk;
end;

function TcaSynColorGrid.EditToColorButton(Edit: TcaRGBSpinEdit): TColorButton;
var
  ColRow: TcaColRow;
begin
  Result := nil;
  ColRow := FData.FindObject(Edit);
  if ColRow.Col <> -1 then
    Result := TColorButton(FData.Objects[ColRow.Col - 1, ColRow.Row]);
end;

function TcaSynColorGrid.FindAttribute(const AAttribute: string): Integer;
var
  Row: Integer;
  Lbl: TLabel;
begin
  Result := -1;
  for Row := 0 to Pred(FData.RowCount) do
    begin
      Lbl := TLabel(FData.Objects[Cols.Lbl, Row]);
      if Lbl.Caption = AAttribute then
        begin
          Result := Row;
          Break;
        end;
    end;
end;

function TcaSynColorGrid.ColorButtonToEdit(Btn: TColorButton): TcaRGBSpinEdit;
var
  ColRow: TcaColRow;
begin
  Result := nil;
  ColRow := FData.FindObject(Btn);
  if ColRow.Col <> -1 then
    Result := TcaRGBSpinEdit(FData.Objects[ColRow.Col + 1, ColRow.Row]);
end;

function TcaSynColorGrid.CreateEdit: TcaRGBSpinEdit;
var
  Edit: TcaRGBSpinEdit;
begin
  Edit := TcaRGBSpinEdit.Create(nil);
  Edit.Parent := Self;
  Edit.ColorValue := clBlack;
  Edit.OnEditChanged := @EditChangedEvent;
  Result := Edit;
end;

procedure TcaSynColorGrid.ColorChangedEvent(Sender: TObject);
var
  Btn: TColorButton;
  Edit: TcaRGBSpinEdit;
begin
  Btn := TColorButton(Sender);
  Edit := ColorButtonToEdit(Btn);
  Edit.ColorValue := Btn.ButtonColor;
end;

procedure TcaSynColorGrid.CreatePopupMenu;
begin
  FMenu := TPopupMenu.Create(nil);
  FCopy := TMenuItem.Create(FMenu);
  FCopy.Caption := 'Copy';
  FCopy.OnClick := @OnCopyClick;
  FMenu.Items.Add(FCopy);
  FPaste := TMenuItem.Create(FMenu);
  FPaste.Caption := 'Paste';
  FPaste.OnClick := @OnPasteClick;
  FMenu.Items.Add(FPaste);
end;

procedure TcaSynColorGrid.EditChangedEvent(Sender: TObject);
var
  Edit: TcaRGBSpinEdit;
  ColorBtn: TColorButton;
begin
  Edit := TcaRGBSpinEdit(Sender);
  ColorBtn := EditToColorButton(Edit);
  ColorBtn.ButtonColor := Edit.ColorValue;
end;

procedure TcaSynColorGrid.OnCopyClick(Sender: TObject);
var
  ColorBtn: TColorButton;
begin
  ColorBtn := TColorButton(FMenu.PopupComponent);
  FCopiedColor := ColorBtn.ButtonColor;
end;

procedure TcaSynColorGrid.OnPasteClick(Sender: TObject);
var
  ColorBtn: TColorButton;
begin
  ColorBtn := TColorButton(FMenu.PopupComponent);
  ColorBtn.ButtonColor := FCopiedColor;
end;

procedure TcaSynColorGrid.AddTitles;

  procedure AddOneTitle(ACaption: string; ALeft, ATop, AWidth, AHeight: Integer;
                        ACentered: Boolean = False; AItalic: Boolean = False; ABold: Boolean = False);
  var
    Lbl: TLabel;
  begin
    Lbl := CreateLabel(' ' + ACaption);
    Lbl.SetBounds(ALeft, ATop, AWidth, AHeight);
    Lbl.Color := clGray;
    Lbl.Font.Color := clWhite;
    if ACentered then
      Lbl.Alignment := taCenter
    else
      Lbl.Alignment := taLeftJustify;
  end;

begin
  AddOneTitle('Attribute', 0, 0, 99, 16);
  AddOneTitle('I', 100, 0, 19, 16, True);
  AddOneTitle('B', 120, 0, 19, 16, True);
  AddOneTitle('Foreground', 140, 0, 99, 16);
  AddOneTitle('#RGB', 240, 0, cRGBWidth - 1, 16);
  AddOneTitle('Background', 240 + cRGBWidth, 0, 99, 16);
  AddOneTitle('#RGB', 340 + cRGBWidth, 0, cRGBWidth, 16);
end;

procedure TcaSynColorGrid.AddRow(const ARowTitle: string);
var
  ARow: Integer;
  Lbl: TLabel;
  ForeBtn, BackBtn: TColorButton;
  RowTop: Integer;
  ForeEdit, BackEdit: TcaRGBSpinEdit;
  ItalicChk, BoldChk: TCheckBox;
begin
  ARow := FData.AddRow;
  // Attribute
  Lbl := CreateLabel(' ' + ARowTitle);
  Lbl.Height := 24;
  RowTop := 20 + (Lbl.Height - 1) * ARow + 1;
  Lbl.SetBounds(0, RowTop, 100, cRowHeight);
  FData.Objects[Cols.Lbl, ARow] := Lbl;
  // Italic checkbox
  ItalicChk := CreateCheckBox;
  ItalicChk.SetBounds(101, RowTop + 2, 20, 20);
  FData.Objects[Cols.Italic, ARow] := ItalicChk;
  // Bold checkbox
  BoldChk := CreateCheckBox;
  BoldChk.SetBounds(121, RowTop + 2, 20, 20);
  FData.Objects[Cols.Bold, ARow] := BoldChk;
  // Foreground button
  ForeBtn := CreateColorButton;
  ForeBtn.SetBounds(140, RowTop, 99, cRowHeight - 2);
  FData.Objects[Cols.ForeBtn, ARow] := ForeBtn;
  // Foreground RGB
  ForeEdit := CreateEdit;
  ForeEdit.SetBounds(240, RowTop, cRGBWidth, cRowHeight);
  FData.Objects[Cols.ForeEdit, ARow] := ForeEdit;
  // Background button
  BackBtn := CreateColorButton;
  BackBtn.SetBounds(240 + cRGBWidth + 1, RowTop, 99, cRowHeight - 2);
  FData.Objects[Cols.BackBtn, ARow] := BackBtn;
  // Background RGB
  BackEdit := CreateEdit;
  BackEdit.SetBounds(340 + cRGBWidth + 1, RowTop, cRGBWidth, cRowHeight);
  FData.Objects[Cols.BackEdit, ARow] := BackEdit;
end;

function TcaSynColorGrid.GetColCount: Integer;
begin
  Result := FData.ColCount;
end;

function TcaSynColorGrid.GetRowCount: Integer;
begin
  Result := FData.RowCount;
end;

procedure TcaSynColorGrid.SetColCount(AValue: Integer);
begin
  if FData.ColCount = AValue then Exit;
  FData.ColCount := AValue;
end;

procedure TcaSynColorGrid.SetRowCount(AValue: Integer);
begin
  if FData.RowCount = AValue then Exit;
  FData.RowCount := AValue;
end;

procedure TcaSynColorGrid.ClearChildControls;
var
  ACol, ARow: Integer;
begin
  for ACol := 0 to Pred(ColCount) do
    for ARow := 0 to Pred(RowCount) do
      if FData.Objects[ACol, ARow] is TControl then
        begin
          TControl(FData.Objects[ACol, ARow]).Free;
          FData.Objects[ACol, ARow] := nil;
        end;
end;

function TcaSynColorGrid.GetColorConfig: TcaSynConfig;
begin
  UpdateConfig;
  Result := FColorConfig;
end;

procedure TcaSynColorGrid.UpdateConfig;
var
  ConfigType: TcaSynConfigType;
  ForeColor, BackColor: TColor;
  Italic, Bold: Boolean;
begin
  for ConfigType := Low(TcaSynConfigType) to High(TcaSynConfigType) do
    begin
      GetRow(ConfigType, Italic, Bold, ForeColor, BackColor);
      FColorConfig.SetRow(ConfigType, Italic, Bold, ForeColor, BackColor);
    end;
end;

procedure TcaSynColorGrid.UpdateFromConfig;
var
  ConfigType: TcaSynConfigType;
  ForeColor, BackColor: TColor;
  Italic, Bold: Boolean;
begin
  for ConfigType := Low(TcaSynConfigType) to High(TcaSynConfigType) do
    begin
      FColorConfig.GetRow(ConfigType, Italic, Bold, ForeColor, BackColor);
      SetRow(ConfigType, Italic, Bold, ForeColor, BackColor);
    end;
end;

procedure TcaSynColorGrid.SetColorConfig(AValue: TcaSynConfig);
begin
  FColorConfig.Assign(AValue);
  UpdateFromConfig;
end;

end.

