{
ATGroups - several page-controls, each based on ATTabs
Copyright (c) Alexey Torgashin
License: MPL 2.0
}

{$ifdef FPC}
  {$mode delphi}
{$else}
  {$define SP} //Allow using SpTBXLib
{$endif}

unit ATGroups;

interface

uses
  Classes, Forms, Types, Controls, Graphics,
  ExtCtrls, Menus,
  {$ifdef SP}
  SpTbxDkPanels, SpTbxItem,
  {$endif}
  ATTabs;

type
  TMySplitter = {$ifdef SP}TSpTbxSplitter{$else}TSplitter{$endif};

type
  TATPages = class(TPanel)
  private
    FTabs: TATTabs;
    FOnTabFocus: TNotifyEvent;
    FOnTabClose: TATTabCloseEvent;
    FOnTabAdd: TNotifyEvent;
    FOnTabEmpty: TNotifyEvent;
    procedure SetOnTabClose(AEvent: TATTabCloseEvent);
    procedure SetOnTabAdd(AEvent: TNotifyEvent);
    procedure TabClick(Sender: TObject);
    procedure TabDrawBefore(Sender: TObject;
      AType: TATTabElemType; ATabIndex: Integer;
      C: TCanvas; const ARect: TRect; var ACanDraw: boolean);
    procedure TabEmpty(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure AddTab(AControl: TControl; const ACaption: Widestring;
      AColor: TColor = clNone);
    property Tabs: TATTabs read FTabs;
    property OnTabFocus: TNotifyEvent read FOnTabFocus write FOnTabFocus;
    property OnTabClose: TATTabCloseEvent read FOnTabClose write SetOnTabClose;
    property OnTabAdd: TNotifyEvent read FOnTabAdd write SetOnTabAdd;
    property OnTabEmpty: TNotifyEvent read FOnTabEmpty write FOnTabEmpty;
  end;

type
  TATGroupsMode = (
    gmNone,
    gmOne,
    gm2Horz,
    gm2Vert,
    gm3Horz,
    gm3Vert,
    gm4Horz,
    gm4Vert,
    gm4Grid
    );
type
  TATGroupsNums = 1..4;

type
  TATGroups = class(TPanel)
  private
    FSplit1, FSplit2, FSplit3: TMySplitter;
    FPanel1, FPanel2: TPanel;
    FSplitPopup: {$ifdef SP} TSpTbxPopupMenu {$else} TPopupMenu {$endif};
    FMode: TATGroupsMode;
    FPos1, FPos2, FPos3: Real;
    FOnTabPopup: TNotifyEvent;
    FOnTabFocus: TNotifyEvent;
    FPopupPages: TATPages;
    FPopupTabIndex: Integer;
    procedure TabFocus(Sender: TObject);
    procedure TabEmpty(Sender: TObject);
    procedure TabPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
    procedure SetMode(Value: TATGroupsMode);
    procedure SetSplitPercent(N: Integer);
    procedure Split1Moved(Sender: TObject);
    procedure Split2Moved(Sender: TObject);
    procedure Split3Moved(Sender: TObject);
    procedure SplitClick(Sender: TObject);
    procedure SaveSplitPos;
    procedure RestoreSplitPos;
    procedure InitSplitterPopup;
  protected
    procedure Resize; override;
  public
    Pages1,
    Pages2,
    Pages3,
    Pages4,
    PagesCurrent: TATPages;
    Pages: array[TATGroupsNums] of TATPages;
    constructor Create(AOwner: TComponent); override;
    //
    function PagesSetIndex(ANum: Integer): boolean;
    procedure PagesSetNext(ANext: boolean);
    function PagesIndexOf(APages: TATPages): Integer;
    function PagesIndexOfControl(ACtl: TControl): Integer;
    function PagesNextIndex(AIndex: Integer; ANext: boolean; AEnableEmpty: boolean): Integer;
    //
    procedure MoveTab(AFromPages: TATPages; AFromIndex: Integer;
      AToPages: TATPages; AToIndex: Integer; AActivateTabAfter: boolean);
    procedure MovePopupTabToNext(ANext: boolean);
    procedure MoveCurrentTabToNext(ANext: boolean);
    //
    property Mode: TATGroupsMode read FMode write SetMode;
    property PopupPages: TATPages read FPopupPages;
    property PopupTabIndex: Integer read FPopupTabIndex;
    property SplitPercent: Integer write SetSplitPercent;
    property OnTabPopup: TNotifyEvent read FOnTabPopup write FOnTabPopup;
    property OnTabFocus: TNotifyEvent read FOnTabFocus write FOnTabFocus;
  end;

implementation

uses
  Windows, SysUtils,
  {$ifdef SP}
  SpTbxSkins,
  {$endif}
  Dialogs;

function PtInControl(Control: TControl; const Pnt: TPoint): boolean;
begin
  Result:= PtInRect(Control.ClientRect, Control.ScreenToClient(Pnt));
end;

{ TATPages }

constructor TATPages.Create(AOwner: TComponent);
begin
  inherited;

  Caption:= '';
  BorderStyle:= bsNone;
  BevelInner:= bvNone;
  BevelOuter:= bvNone;

  FTabs:= TATTabs.Create(Self);
  FTabs.Parent:= Self;
  FTabs.Align:= alTop;
  FTabs.OnTabClick:= TabClick;
  FTabs.OnTabDrawBefore:= TabDrawBefore;
  FTabs.OnTabEmpty:= TabEmpty;

  FTabs.TabAngle:= 0;
  FTabs.TabIndentTop:= 1;
  FTabs.TabIndentInter:= 1;
  FTabs.Height:= FTabs.TabHeight+FTabs.TabIndentTop+4;
  FTabs.ColorBg:= clWindow;
end;

procedure TATPages.AddTab(AControl: TControl;
  const ACaption: Widestring; AColor: TColor);
begin
  FTabs.AddTab(-1, ACaption, AControl);
  AControl.Parent:= Self;
  AControl.Align:= alClient;
  FTabs.TabIndex:= FTabs.TabCount-1;
end;

procedure TATPages.TabClick(Sender: TObject);
var
  i: Integer;
  D: TATTabData;
  Ctl: TWinControl;
begin
  for i:= 0 to FTabs.TabCount-1 do
  begin
    D:= FTabs.GetTabData(i);
    if D<>nil then
    begin
      Ctl:= D.TabObject as TWinControl;
      Ctl.Visible:= i=FTabs.TabIndex;
    end;
  end;

  D:= FTabs.GetTabData(FTabs.TabIndex);
  if D<>nil then
  begin
    Ctl:= D.TabObject as TWinControl;
    if Ctl.Showing then
      if Assigned(FOnTabFocus) then
        FOnTabFocus(FTabs);
  end;
end;

procedure TATPages.SetOnTabClose(AEvent: TATTabCloseEvent);
begin
  FOnTabClose:= AEvent;
  FTabs.OnTabClose:= AEvent;
end;

procedure TATPages.SetOnTabAdd(AEvent: TNotifyEvent);
begin
  FOnTabAdd:= AEvent;
  FTabs.OnTabPlusClick:= AEvent;
end;

procedure TATPages.TabEmpty(Sender: TObject);
begin
  if Assigned(FOnTabEmpty) then
    FOnTabEmpty(Sender);
end;

{ TATGroups }

constructor TATGroups.Create(AOwner: TComponent);
var
  i: Integer;
begin
  inherited;

  Caption:= '';
  BorderStyle:= bsNone;
  BevelInner:= bvNone;
  BevelOuter:= bvNone;

  Pages1:= TATPages.Create(Self);
  Pages2:= TATPages.Create(Self);
  Pages3:= TATPages.Create(Self);
  Pages4:= TATPages.Create(Self);

  PagesCurrent:= Pages1;
  Pages[1]:= Pages1;
  Pages[2]:= Pages2;
  Pages[3]:= Pages3;
  Pages[4]:= Pages4;

  for i:= Low(TATGroupsNums) to High(TATGroupsNums) do
    with Pages[i] do
    begin
      Name:= 'aPages'+IntToStr(i);
      Caption:= '';
      Tabs.Name:= 'aTabs'+IntToStr(i);
      //
      Parent:= Self;
      Align:= alLeft;
      OnContextPopup:= Self.TabPopup;
      OnTabEmpty:= Self.TabEmpty;
      OnTabFocus:= Self.TabFocus;
    end;

  FSplit1:= TMySplitter.Create(Self);
  FSplit1.Parent:= Self;
  FSplit1.OnMoved:= Split1Moved;

  FSplit2:= TMySplitter.Create(Self);
  FSplit2.Parent:= Self;
  FSplit2.OnMoved:= Split2Moved;

  FSplit3:= TMySplitter.Create(Self);
  FSplit3.Parent:= Self;
  FSplit3.OnMoved:= Split3Moved;

  FPanel1:= TPanel.Create(Self);
  FPanel1.Parent:= Self;
  FPanel1.Align:= alTop;
  FPanel1.Caption:= '';
  FPanel1.BorderStyle:= bsNone;
  FPanel1.BevelInner:= bvNone;
  FPanel1.BevelOuter:= bvNone;
  FPanel1.Visible:= false;

  FPanel2:= TPanel.Create(Self);
  FPanel2.Parent:= Self;
  FPanel2.Align:= alClient;
  FPanel2.Caption:= '';
  FPanel2.BorderStyle:= bsNone;
  FPanel2.BevelInner:= bvNone;
  FPanel2.BevelOuter:= bvNone;
  FPanel2.Visible:= false;

  InitSplitterPopup;
  FPopupPages:= nil;
  FPopupTabIndex:= -1;
  FMode:= gmNone;

  FOnTabPopup:= nil;
  FOnTabFocus:= nil;
end;

procedure TATGroups.InitSplitterPopup;
  //
  procedure Add(N: Integer);
  var
    MI: {$ifdef SP}TSpTbxItem{$else}TMenuItem{$endif};
  begin
    MI:= {$ifdef SP}TSpTbxItem{$else}TMenuItem{$endif}.Create(Self);
    MI.Caption:= Format('%d/%d', [N, 100-N]);
    MI.Tag:= N;
    MI.OnClick:= SplitClick;
    FSplitPopup.Items.Add(MI);
  end;
  //
begin
  FSplitPopup:= {$ifdef SP}TSpTbxPopupMenu{$else}TPopupMenu{$endif}.Create(Self);
  Add(20);
  Add(30);
  Add(40);
  Add(50);
  Add(60);
  Add(70);
  Add(80);
end;

type
  TControlHack = class(TSplitter);

procedure SetSplitterPopup(ASplitter: TMySplitter; APopup: TPopupMenu);
begin
  {$ifdef SP}
  ASplitter.PopupMenu:= APopup;
  {$else}
  TControlHack(ASplitter).PopupMenu:= APopup;
  {$endif}
end;

procedure TATGroups.SetMode(Value: TATGroupsMode);
var
  FSplitDiv: Real;
begin
  if Value<>FMode then
  begin
    case FMode of
      gm2Horz:
        FSplitDiv:= Pages1.Width / ClientWidth;
      gm2Vert:
        FSplitDiv:= Pages1.Height / ClientHeight;
      else
        FSplitDiv:= 0.5;
    end;

    FMode:= Value;

    if FMode in [gm2Horz, gm2Vert] then
      SetSplitterPopup(FSplit1, FSplitPopup)
    else
      SetSplitterPopup(FSplit1, nil);

    if FMode=gm4Grid then
    begin
      FPanel1.Visible:= true;
      FPanel2.Visible:= true;
      Pages1.Parent:= FPanel1;
      Pages2.Parent:= FPanel1;
      Pages3.Parent:= FPanel2;
      Pages4.Parent:= FPanel2;
      FSplit1.Parent:= FPanel1;
      FSplit2.Parent:= FPanel2;
    end
    else
    begin
      FPanel1.Visible:= false;
      FPanel2.Visible:= false;
      Pages1.Parent:= Self;
      Pages2.Parent:= Self;
      Pages3.Parent:= Self;
      Pages4.Parent:= Self;
      FSplit1.Parent:= Self;
      FSplit2.Parent:= Self;
    end;

    case FMode of
      gmOne:
        begin
          Pages2.Visible:= false;
          Pages3.Visible:= false;
          Pages4.Visible:= false;
          FSplit1.Visible:= false;
          FSplit2.Visible:= false;
          FSplit3.Visible:= false;
          Pages1.Align:= alClient;
        end;
      gm2Horz:
        begin
          Pages2.Visible:= true;
          Pages3.Visible:= false;
          Pages4.Visible:= false;
          FSplit1.Visible:= true;
          FSplit2.Visible:= false;
          FSplit3.Visible:= false;
          Pages1.Align:= alLeft;
          Pages2.Align:= alClient;
          FSplit1.Align:= alLeft;
          //size
          Pages1.Width:= Trunc(ClientWidth * FSplitDiv);
          //pos
          FSplit1.Left:= ClientWidth;
          Pages2.Left:= ClientWidth;
        end;
      gm2Vert:
        begin
          Pages2.Visible:= true;
          Pages3.Visible:= false;
          Pages4.Visible:= false;
          FSplit1.Visible:= true;
          FSplit2.Visible:= false;
          FSplit3.Visible:= false;
          Pages1.Align:= alTop;
          Pages2.Align:= alClient;
          FSplit1.Align:= alTop;
          //size
          Pages1.Height:= Trunc(ClientHeight * FSplitDiv);
          //pos
          FSplit1.Top:= ClientHeight;
          Pages2.Top:= ClientHeight;
        end;
      gm3Horz:
        begin
          Pages2.Visible:= true;
          Pages3.Visible:= true;
          Pages4.Visible:= false;
          FSplit1.Visible:= true;
          FSplit2.Visible:= true;
          FSplit3.Visible:= false;
          Pages1.Align:= alLeft;
          Pages2.Align:= alLeft;
          Pages3.Align:= alClient;
          FSplit1.Align:= alLeft;
          FSplit2.Align:= alLeft;
          //size
          Pages1.Width:= ClientWidth div 3;
          Pages2.Width:= ClientWidth div 3;
          //pos
          FSplit1.Left:= ClientWidth;
          Pages2.Left:= ClientWidth;
          FSplit2.Left:= ClientWidth;
          Pages3.Left:= ClientWidth;
        end;
      gm3Vert:
        begin
          Pages2.Visible:= true;
          Pages3.Visible:= true;
          Pages4.Visible:= false;
          FSplit1.Visible:= true;
          FSplit2.Visible:= true;
          FSplit3.Visible:= false;
          Pages1.Align:= alTop;
          Pages2.Align:= alTop;
          Pages3.Align:= alClient;
          FSplit1.Align:= alTop;
          FSplit2.Align:= alTop;
          //size
          Pages1.Height:= ClientHeight div 3;
          Pages2.Height:= ClientHeight div 3;
          //pos
          FSplit1.Top:= ClientHeight;
          Pages2.Top:= ClientHeight;
          FSplit2.Top:= ClientHeight;
          Pages3.Top:= ClientHeight;
        end;
      gm4Horz:
        begin
          Pages2.Visible:= true;
          Pages3.Visible:= true;
          Pages4.Visible:= true;
          FSplit1.Visible:= true;
          FSplit2.Visible:= true;
          FSplit3.Visible:= true;
          Pages1.Align:= alLeft;
          Pages2.Align:= alLeft;
          Pages3.Align:= alLeft;
          Pages4.Align:= alClient;
          FSplit1.Align:= alLeft;
          FSplit2.Align:= alLeft;
          FSplit3.Align:= alLeft;
          //size
          Pages1.Width:= ClientWidth div 4;
          Pages2.Width:= ClientWidth div 4;
          Pages3.Width:= ClientWidth div 4;
          //pos
          FSplit1.Left:= ClientWidth;
          Pages2.Left:= ClientWidth;
          FSplit2.Left:= ClientWidth;
          Pages3.Left:= ClientWidth;
          FSplit3.Left:= ClientWidth;
          Pages4.Left:= ClientWidth;
        end;
      gm4Vert:
        begin
          Pages2.Visible:= true;
          Pages3.Visible:= true;
          Pages4.Visible:= true;
          FSplit1.Visible:= true;
          FSplit2.Visible:= true;
          FSplit3.Visible:= true;
          Pages1.Align:= alTop;
          Pages2.Align:= alTop;
          Pages3.Align:= alTop;
          Pages4.Align:= alClient;
          FSplit1.Align:= alTop;
          FSplit2.Align:= alTop;
          FSplit3.Align:= alTop;
          //size
          Pages1.Height:= ClientHeight div 4;
          Pages2.Height:= ClientHeight div 4;
          Pages3.Height:= ClientHeight div 4;
          //pos
          FSplit1.Top:= ClientHeight;
          Pages2.Top:= ClientHeight;
          FSplit2.Top:= ClientHeight;
          Pages3.Top:= ClientHeight;
          FSplit3.Top:= ClientHeight;
          Pages4.Top:= ClientHeight;
        end;
      gm4Grid:
        begin
          Pages2.Visible:= true;
          Pages3.Visible:= true;
          Pages4.Visible:= true;
          FSplit1.Visible:= true;
          FSplit2.Visible:= true;
          FSplit3.Visible:= true;
          Pages1.Align:= alLeft;
          Pages2.Align:= alClient;
          Pages3.Align:= alLeft;
          Pages4.Align:= alClient;
          FSplit1.Align:= alLeft;
          FSplit2.Align:= alLeft;
          FSplit3.Align:= alTop;
          //size
          Pages1.Width:= ClientWidth div 2;
          Pages3.Width:= ClientWidth div 2;
          FPanel1.Height:= ClientHeight div 2;
          //pos
          FSplit1.Left:= ClientWidth;
          Pages2.Left:= ClientWidth;
          FSplit2.Left:= ClientWidth;
          Pages4.Left:= ClientWidth;
        end;
    end;

    SaveSplitPos;
  end;
end;

procedure TATGroups.Split1Moved(Sender: TObject);
begin
  if FMode=gm4Grid then
    Pages3.Width:= Pages1.Width;
  SaveSplitPos;
end;

procedure TATGroups.Split2Moved(Sender: TObject);
begin
  if FMode=gm4Grid then
    Pages1.Width:= Pages3.Width;
  SaveSplitPos;
end;

procedure TATGroups.Split3Moved(Sender: TObject);
begin
  SaveSplitPos;
end;

procedure TATGroups.TabPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
var
  Pnt, PntC: TPoint;
begin
  Pnt:= (Sender as TControl).ClientToScreen(MousePos);

  if PtInControl(Pages1.Tabs, Pnt) then
    FPopupPages:= Pages1
  else
  if PtInControl(Pages2.Tabs, Pnt) then
    FPopupPages:= Pages2
  else
  if PtInControl(Pages3.Tabs, Pnt) then
    FPopupPages:= Pages3
  else
  if PtInControl(Pages4.Tabs, Pnt) then
    FPopupPages:= Pages4
  else
  begin
    FPopupPages:= nil;
    FPopupTabIndex:= -1;
    Exit;
  end;

  PntC:= PopupPages.Tabs.ScreenToClient(Pnt);
  FPopupTabIndex:= FPopupPages.Tabs.GetTabAt(PntC.X, PntC.Y);

  if Assigned(FOnTabPopup) then
    FOnTabPopup(Self);
  Handled:= true;
end;

procedure TATPages.TabDrawBefore(Sender: TObject;
  AType: TATTabElemType; ATabIndex: Integer;
  C: TCanvas; const ARect: TRect; var ACanDraw: boolean);
begin
  {$ifndef SP}
  ACanDraw:= true;
  {$else}
  case AType of
    aeBackground:
    begin
      CurrentSkin.PaintBackground(
        C, ARect,
        skncDock, sknsNormal, true{BG}, false{Borders});
      ACanDraw:= false;
    end;
    aeXButton:
    begin
      //if ATabMouseOver then
      //  SpDrawXPToolbarButton(Control.Canvas, R, sknsHotTrack, cpNone);
      SpDrawGlyphPattern(C, ARect, 0{0 is X icon index},
        CurrentSkin.GetTextColor(skncToolbarItem, sknsNormal));
      ACanDraw:= false;
    end;
    aeXButtonOver:
    begin
      SpDrawXPToolbarButton(C,
        Rect(ARect.Left-1, ARect.Top-1, ARect.Right, ARect.Bottom),
        sknsHotTrack, cpNone);
      SpDrawGlyphPattern(C, ARect, 0{0 is X icon index},
        CurrentSkin.GetTextColor(skncToolbarItem, sknsNormal));
      ACanDraw:= false;
    end;
  end;
  {$endif}
end;

procedure TATGroups.SaveSplitPos;
begin
  if ClientWidth<=0 then Exit;
  if ClientHeight<=0 then Exit;

  FPos1:= 0;
  FPos2:= 0;
  FPos3:= 0;

  case FMode of
    gm2Horz,
    gm3Horz,
    gm4Horz:
      begin
        FPos1:= Pages1.Width / ClientWidth;
        FPos2:= Pages2.Width / ClientWidth;
        FPos3:= Pages3.Width / ClientWidth;
      end;
    gm2Vert,
    gm3Vert,
    gm4Vert:
      begin
        FPos1:= Pages1.Height / ClientHeight;
        FPos2:= Pages2.Height / ClientHeight;
        FPos3:= Pages3.Height / ClientHeight;
      end;
    gm4Grid:
      begin
        FPos1:= Pages1.Width / ClientWidth;
        FPos2:= Pages3.Width / ClientWidth;
        FPos3:= FPanel1.Height / ClientHeight;
      end;
  end;
end;

procedure TATGroups.RestoreSplitPos;
begin
  if ClientWidth<=0 then Exit;
  if ClientHeight<=0 then Exit;

  case FMode of
    gm2Horz,
    gm3Horz,
    gm4Horz:
      begin
        Pages1.Width:= Trunc(FPos1 * ClientWidth);
        Pages2.Width:= Trunc(FPos2 * ClientWidth);
        Pages3.Width:= Trunc(FPos3 * ClientWidth);
      end;
    gm2Vert,
    gm3Vert,
    gm4Vert:
      begin
        Pages1.Height:= Trunc(FPos1 * ClientHeight);
        Pages2.Height:= Trunc(FPos2 * ClientHeight);
        Pages3.Height:= Trunc(FPos3 * ClientHeight);
      end;
    gm4Grid:
      begin
        Pages1.Width:= Trunc(FPos1 * ClientWidth);
        Pages3.Width:= Trunc(FPos2 * ClientWidth);
        FPanel1.Height:= Trunc(FPos3 * ClientHeight);
      end;
  end;
end;

procedure TATGroups.Resize;
begin
  RestoreSplitPos;
end;


procedure TATGroups.TabEmpty(Sender: TObject);
begin
  //if last tab closed on Pages1, add new tab
  //if last tab closed on Pages2..Pages4, activate Pages1
  if Sender=Pages1.Tabs then
  begin
    Pages1.OnTabAdd(Pages1.Tabs);
  end
  else
  begin
    if Pages1.Tabs.TabCount>0 then
      Pages1.Tabs.OnTabClick(nil);
  end;
end;

procedure TATGroups.SplitClick(Sender: TObject);
begin
  SetSplitPercent((Sender as TComponent).Tag);
end;

procedure TATGroups.SetSplitPercent(N: Integer);
begin
  case FMode of
    gm2Horz:
      begin
        Pages1.Width:= ClientWidth * N div 100;
        SaveSplitPos;
      end;
    gm2Vert:
      begin
        Pages1.Height:= ClientHeight * N div 100;
        SaveSplitPos;
      end;
  end;
end;

procedure TATGroups.MoveTab(AFromPages: TATPages; AFromIndex: Integer;
  AToPages: TATPages; AToIndex: Integer; AActivateTabAfter: boolean);
var
  D: TATTabData;
begin
  D:= AFromPages.Tabs.GetTabData(AFromIndex);
  if D=nil then Exit;
  AToPages.AddTab(D.TabObject as TControl, D.TabCaption, D.TabColor);
  AFromPages.Tabs.DeleteTab(AFromIndex, false);

  if AActivateTabAfter then
    with AToPages.Tabs do
      TabIndex:= TabCount-1;
end;


function TATGroups.PagesSetIndex(ANum: Integer): boolean;
var
  APages: TATPages;
begin
  if (ANum>=Low(Pages)) and (ANum<=High(Pages)) then
    APages:= Pages[ANum]
  else
    APages:= nil;

  Result:= (APages<>nil) and APages.Visible and (APages.Tabs.TabCount>0);
  if Result then
    APages.Tabs.OnTabClick(nil);
end;

procedure TATGroups.PagesSetNext(ANext: boolean);
var
  Num0, Num1: Integer;
begin
  Num0:= PagesIndexOf(PagesCurrent);
  if Num0<0 then Exit;
  Num1:= PagesNextIndex(Num0, ANext, false);
  if Num1<0 then Exit;
  PagesSetIndex(Num1);
end;


function TATGroups.PagesIndexOfControl(ACtl: TControl): Integer;
var
  i, j: Integer;
begin
  for i:= Low(Pages) to High(Pages) do
    with Pages[i] do
      for j:= 0 to Tabs.TabCount-1 do
        if Tabs.GetTabData(j).TabObject = ACtl then
        begin
          Result:= i;
          Exit
        end;
  Result:= -1;
end;

function TATGroups.PagesIndexOf(APages: TATPages): Integer;
var
  i: Integer;
begin
  Result:= -1;
  for i:= Low(Pages) to High(Pages) do
    if Pages[i] = APages then
    begin
      Result:= i;
      Exit
    end;
end;

function TATGroups.PagesNextIndex(AIndex: Integer; ANext: boolean;
  AEnableEmpty: boolean): Integer;
var
  N: Integer;
begin
  Result:= -1;
  N:= AIndex;

  repeat
    if ANext then Inc(N) else Dec(N);
    if N>High(TATGroupsNums) then
      N:= Low(TATGroupsNums)
    else
    if N<Low(TATGroupsNums) then
      N:= High(TATGroupsNums);

    if N=AIndex then Exit;

    if Pages[N].Visible then
      if (Pages[N].Tabs.TabCount>0) or AEnableEmpty then
      begin
        Result:= N;
        Exit
      end;
  until false;
end;


procedure TATGroups.TabFocus(Sender: TObject);
begin
  if Assigned(FOnTabFocus) then
    FOnTabFocus(Sender);
end;

procedure TATGroups.MovePopupTabToNext(ANext: boolean);
var
  N0, N1: Integer;
begin
  N0:= PagesIndexOf(PopupPages);
  if N0<0 then Exit;
  N1:= PagesNextIndex(N0, ANext, true);
  if N1<0 then Exit;
  MoveTab(PopupPages, PopupTabIndex, Pages[N1], -1, false);
end;

procedure TATGroups.MoveCurrentTabToNext(ANext: boolean);
var
  N0, N1: Integer;
begin
  N0:= PagesIndexOf(PagesCurrent);
  if N0<0 then Exit;
  N1:= PagesNextIndex(N0, ANext, true);
  if N1<0 then Exit;
  MoveTab(PagesCurrent, PagesCurrent.Tabs.TabIndex, Pages[N1], -1, true);
end;

end.

