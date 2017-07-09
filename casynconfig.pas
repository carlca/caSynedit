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


unit casynconfig;

{$mode objfpc}{$H+}
{.$DEFINE DBG}

interface

uses
  Classes, SysUtils, TypInfo, Graphics, caMatrix, cajsonconfig, cadbg;

type

  { TcaSynConfigType }

  TcaSynConfigType = (
    ctComment,
    ctConstant,
    ctDot,
    ctEntity,
    ctIdentifier,
    ctKey,
    ctNumber,
    ctObject,
    ctPreprocessor,
    ctSpace,
    ctString,
    ctSymbol,
    ctVariable);

  { TcaSynConfig }

  TcaSynConfig = class(TObject)
  private
    // private members
    FData: TcaMatrix;
    FOnChanged: TNotifyEvent;
  protected
    // protected members
    procedure DoChanged; virtual;
    property Data: TcaMatrix read FData;
  public
    // public members
    constructor Create;
    destructor Destroy; override;
    class function ConfigTypeToString(AConfigType: TcaSynConfigType): string;
    procedure Assign(ASource: TcaSynConfig);
    procedure LoadConfig(const AConfigPath: string);
    procedure SaveConfig(const AConfigPath: string);
    procedure SetRow(AConfigType: TcaSynConfigType; AItalic, ABold: Boolean; AForeColor, ABackColor: TColor);
    procedure GetRow(AConfigType: TcaSynConfigType; var AItalic, ABold: Boolean; var AForeColor, ABackColor: TColor);
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

implementation

type

  { Cols }

  Cols = class
    class function Attribute: Byte;
    class function Italic: Byte;
    class function Bold: Byte;
    class function ForeColor: Byte;
    class function BackColor: Byte;
    class function Count: Byte;
  end;

{ Cols }

class function Cols.Attribute: Byte;
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

class function Cols.ForeColor: Byte;
begin
  Result := 3;
end;

class function Cols.BackColor: Byte;
begin
  Result := 4;
end;

class function Cols.Count: Byte;
begin
  Result := 5;
end;

{ TcaSynConfig }

procedure TcaSynConfig.DoChanged;
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

constructor TcaSynConfig.Create;
begin
  inherited;
  FData := TcaMatrix.Create(nil);
  FData.ColCount := Cols.Count;
  FData.RowCount := Ord(High(TcaSynConfigType)) + 1;
end;

destructor TcaSynConfig.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TcaSynConfig.LoadConfig(const AConfigPath: string);
var
  Config: TcaJsonConfig;
  ConfigType: TcaSynConfigType;
begin
  Config := TcaJsonConfig.Create(nil);
  try
    Config.HexDigits := 6;
    Config.Filename := AConfigPath;
    for ConfigType := Low(TcaSynConfigType) to High(TcaSynConfigType) do
      begin
        Config.Group := TcaSynConfig.ConfigTypeToString(ConfigType);
        FData.Strings[Cols.Attribute, Ord(ConfigType)] := Config.Group;
        FData.Booleans[Cols.Italic, Ord(ConfigType)] := Config.BoolProp['italic'];
        FData.Booleans[Cols.Bold, Ord(ConfigType)] := Config.BoolProp['bold'];
        FData.UInt32s[Cols.ForeColor, Ord(ConfigType)] := Config.HexProp['foreColor'];
        FData.UInt32s[Cols.BackColor, Ord(ConfigType)] := Config.HexProp['backColor'];
      end;
  finally
    Config.Free;
  end;
  DoChanged;
end;

procedure TcaSynConfig.SaveConfig(const AConfigPath: string);
var
  Config: TcaJsonConfig;
  ConfigType: TcaSynConfigType;
begin
  Config := TcaJsonConfig.Create(nil);
  try
    Config.HexDigits := 6;
    Config.Filename := AConfigPath;
    for ConfigType := Low(TcaSynConfigType) to High(TcaSynConfigType) do
      begin
        Config.Group := FData.Strings[Cols.Attribute, Ord(ConfigType)];
        Config.BoolProp['italic'] := FData.Booleans[Cols.Italic, Ord(ConfigType)];
        Config.BoolProp['bold'] := FData.Booleans[Cols.Bold, Ord(ConfigType)];
        Config.HexProp['foreColor'] := FData.UInt32s[Cols.ForeColor, Ord(ConfigType)];
        Config.HexProp['backColor'] := FData.UInt32s[Cols.BackColor, Ord(ConfigType)];
      end;
  finally
    Config.Free;
  end;
end;

class function TcaSynConfig.ConfigTypeToString(AConfigType: TcaSynConfigType): string;
begin
  Result := GetEnumName(TypeInfo(TcaSynConfigType), Ord(AConfigType));
  Delete(Result, 1, 2);
end;

procedure TcaSynConfig.Assign(ASource: TcaSynConfig);
begin
  FData.Assign(ASource.Data);
  DoChanged;
end;

procedure TcaSynConfig.GetRow(AConfigType: TcaSynConfigType; var AItalic, ABold: Boolean; var AForeColor, ABackColor: TColor);
begin
  AItalic := FData.Booleans[Cols.Italic, Ord(AConfigType)];
  ABold := FData.Booleans[Cols.Bold, Ord(AConfigType)];
  AForeColor := FData.UInt32s[Cols.ForeColor, Ord(AConfigType)];
  ABackColor := FData.UInt32s[Cols.BackColor, Ord(AConfigType)];
end;

procedure TcaSynConfig.SetRow(AConfigType: TcaSynConfigType; AItalic, ABold: Boolean; AForeColor, ABackColor: TColor);
begin
  FData.Strings[Cols.Attribute, Ord(AConfigType)] := ConfigTypeToString(AConfigType);
  FData.Booleans[Cols.Italic, Ord(AConfigType)] := AItalic;
  FData.Booleans[Cols.Bold, Ord(AConfigType)] := ABold;
  FData.UInt32s[Cols.ForeColor, Ord(AConfigType)] := AForeColor;
  FData.UInt32s[Cols.BackColor, Ord(AConfigType)] := ABackColor;
end;

end.

