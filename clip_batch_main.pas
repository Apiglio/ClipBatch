unit clip_batch_main;

{$mode objfpc}{$H+}
{$goto on}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Menus, Apiglio_Useful;

const version_str = '0.1.2';
      CRLF = #13#10;

      { TBorderActivate }
      baNone   = $00;
      baTop    = $01;
      baLeft   = $02;
      baRight  = $04;
      baBottom = $08;
      baMove   = $0f;

type

  TBorderActivate = Byte; //0xb TLRBM


  { TForm_Clip_Batch }

  TForm_Clip_Batch = class(TForm)
    Button_transpose: TButton;
      Image_show: TImage;
      ListBox_filenames: TListBox;
      MainMenu: TMainMenu;
      MenuItem_selection_ratio_32: TMenuItem;
      MenuItem_selection_ratio_107: TMenuItem;
      MenuItem_selection_ratio_75: TMenuItem;
      MenuItem_selection_ratio_65: TMenuItem;
      MenuItem_selection_ratio_54: TMenuItem;
      MenuItem_selection_ratio_customize: TMenuItem;
      MenuItem_selection_autotranspose: TMenuItem;
      MenuItem_selection_ratio_169: TMenuItem;
      MenuItem_selection_ratio_2351: TMenuItem;
      MenuItem_selection_ratio_11: TMenuItem;
      MenuItem_selection_ratio_43: TMenuItem;
      MenuItem_selection_ratio: TMenuItem;
      MenuItem_tool_div_01: TMenuItem;
      MenuItem_selection_border: TMenuItem;
      MenuItem_selection_proportional: TMenuItem;
      MenuItem_selection: TMenuItem;
      MenuItem_about: TMenuItem;
      MenuItem_openFiles: TMenuItem;
      MenuItem_openDir: TMenuItem;
      MenuItem_open: TMenuItem;
      MenuItem_tool: TMenuItem;
      OpenDialog1: TOpenDialog;
      Panel_show: TPanel;
      SelectDirectoryDialog1: TSelectDirectoryDialog;
      Shape_select: TShape;
      SplitterV: TSplitter;
      procedure Button_transposeClick(Sender: TObject);
      procedure FormCreate(Sender: TObject);
      procedure FormDropFiles(Sender: TObject; const FileNames: array of String);
      procedure ListBox_filenamesClick(Sender: TObject);
      procedure MenuItem_aboutClick(Sender: TObject);
      procedure MenuItem_openDirClick(Sender: TObject);
      procedure MenuItem_openFilesClick(Sender: TObject);
      procedure MenuItem_selection_autotransposeClick(Sender: TObject);
      procedure MenuItem_selection_borderClick(Sender: TObject);
      procedure MenuItem_selection_proportionalClick(Sender: TObject);
      procedure MenuItem_selection_ratio_107Click(Sender: TObject);
      procedure MenuItem_selection_ratio_11Click(Sender: TObject);
      procedure MenuItem_selection_ratio_169Click(Sender: TObject);
      procedure MenuItem_selection_ratio_2351Click(Sender: TObject);
      procedure MenuItem_selection_ratio_32Click(Sender: TObject);
      procedure MenuItem_selection_ratio_43Click(Sender: TObject);
      procedure MenuItem_selection_ratio_54Click(Sender: TObject);
      procedure MenuItem_selection_ratio_65Click(Sender: TObject);
      procedure MenuItem_selection_ratio_75Click(Sender: TObject);
      procedure MenuItem_selection_ratio_customizeClick(Sender: TObject);
      procedure Panel_showResize(Sender: TObject);
      procedure Shape_selectMouseDown(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X, Y: Integer);
      procedure Shape_selectMouseMove(Sender: TObject; Shift: TShiftState; X,
          Y: Integer);
      procedure Shape_selectMouseUp(Sender: TObject; Button: TMouseButton;
          Shift: TShiftState; X, Y: Integer);
  private
      FFileName:string;
      FMouseCursor:TPoint;
      FShapeRect:TRect;
      FProportion:double;
      FMouseHold:Boolean;
      FBorderActivate:TBorderActivate;
  private
      function BestRect(aRect:TRect):TRect;
      procedure CheckTranspose;
  public
      Selection_Proportional:boolean;
      Selection_Ratio:double;
      Portrait:boolean;
      AutoTranspose:boolean;
      activate_margin:integer;
  public
      function LoadFiles(aFileNames:array of string):boolean;
      procedure LoadDirectory(aDirectory:string);

      procedure LoadImage(aFilename:string);
      procedure ClipImage(aFilename:string);
  end;

var
    Form_Clip_Batch: TForm_Clip_Batch;

implementation

{$R *.lfm}

{ TForm_Clip_Batch }

procedure TForm_Clip_Batch.FormDropFiles(Sender: TObject; const FileNames: array of String);
label drop_mismatch;
begin
    ListBox_filenames.Clear;
    if Length(FileNames)=1 then begin
        if not DirectoryExists(FileNames[0]) then goto drop_mismatch;
        LoadDirectory(FileNames[0]);
    end else begin
        if not LoadFiles(FileNames) then goto drop_mismatch;
    end;
    exit;
drop_mismatch:
    ShowMessage('请拖拽一个文件夹或多个文件。');
end;

procedure TForm_Clip_Batch.FormCreate(Sender: TObject);
begin
    Image_show.Picture.Bitmap:=TBitmap.Create;
    Selection_Proportional:=true;
    activate_margin:=12;
    Selection_Ratio:=1.0;
    Portrait:=false;
    AutoTranspose:=true;
    FFileName:='';
end;

procedure TForm_Clip_Batch.Button_transposeClick(Sender: TObject);
var old_autotranspose:boolean;
begin
    //Form_Clip_Batch.Selection_Ratio:=1/Form_Clip_Batch.Selection_Ratio;
    Portrait:=not Portrait;
    old_autotranspose:=AutoTranspose;
    AutoTranspose:=false;
    Panel_showResize(Panel_show);
    AutoTranspose:=old_autotranspose;
end;

procedure TForm_Clip_Batch.ListBox_filenamesClick(Sender: TObject);
begin
    LoadImage(ListBox_filenames.Items[ListBox_filenames.ItemIndex]);
end;

procedure TForm_Clip_Batch.MenuItem_aboutClick(Sender: TObject);
begin
  MessageDlg('About', 'ClipBatch '+version_str+CRLF+'by Apiglio'+CRLF+'powered by Lazarus 1.8.4' , mtInformation, [mbOK], 0);
end;

procedure TForm_Clip_Batch.MenuItem_openDirClick(Sender: TObject);
begin
    with SelectDirectoryDialog1 do if Execute then begin
        LoadDirectory(FileName);
    end;
end;

procedure TForm_Clip_Batch.MenuItem_openFilesClick(Sender: TObject);
var tmpFiles:array of string;
    index:integer;
begin
    with OpenDialog1 do if Execute then begin
        SetLength(tmpFiles,Files.Count);
        index:=Files.Count-1;
        while index>=0 do begin
          tmpFiles[index]:=Files[index];
          dec(index);
        end;
        LoadFiles(tmpFiles);
        SetLength(tmpFiles,0);
    end;
end;

procedure TForm_Clip_Batch.MenuItem_selection_autotransposeClick(Sender: TObject
  );
begin
    (Sender as TMenuItem).Checked:=not (Sender as TMenuItem).Checked;
    AutoTranspose:=(Sender as TMenuItem).Checked;
end;

procedure TForm_Clip_Batch.MenuItem_selection_borderClick(Sender: TObject);
begin
    (Sender as TMenuItem).Checked:=not (Sender as TMenuItem).Checked;
    if (Sender as TMenuItem).Checked then Form_Clip_Batch.activate_margin:=12 else Form_Clip_Batch.activate_margin:=4;
end;

procedure TForm_Clip_Batch.MenuItem_selection_proportionalClick(Sender: TObject
  );
begin
    (Sender as TMenuItem).Checked:=not (Sender as TMenuItem).Checked;
    Form_Clip_Batch.Selection_Proportional:=(Sender as TMenuItem).Checked;
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_107Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=true;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=10/7;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_11Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=true;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=1.0;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_169Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=true;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=16/9;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_2351Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=true;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=2.35;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_32Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=true;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=3/2;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_43Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=true;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=4/3;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_54Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=true;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=5/4;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_65Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=true;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=6/5;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_75Click(Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=true;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=false;
    Form_Clip_Batch.Selection_Ratio:=7/5;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

procedure TForm_Clip_Batch.MenuItem_selection_ratio_customizeClick(
  Sender: TObject);
begin
    MenuItem_selection_ratio_11.Checked:=false;
    MenuItem_selection_ratio_43.Checked:=false;
    MenuItem_selection_ratio_2351.Checked:=false;
    MenuItem_selection_ratio_169.Checked:=false;
    MenuItem_selection_ratio_32.Checked:=false;
    MenuItem_selection_ratio_107.Checked:=false;
    MenuItem_selection_ratio_75.Checked:=false;
    MenuItem_selection_ratio_65.Checked:=false;
    MenuItem_selection_ratio_54.Checked:=false;
    MenuItem_selection_ratio_customize.Checked:=true;
    try
        Form_Clip_Batch.Selection_Ratio:=StrToFloat(
            InputBox('自定义长宽比','长边:短边=',FloatToStr(Form_Clip_Batch.Selection_Ratio))
        );
    except
        MessageDlg('自定义长宽比', '输入有误，未能成功设置自定义比例。', mtError, [mbOK], 0);
        exit;
    end;
    Form_Clip_Batch.Button_transposeClick(Button_transpose); //不刷新图片的范围更新应该专门写一个函数，不应该调用resize
end;

function TForm_Clip_Batch.BestRect(aRect:TRect):TRect;
var img_tt,img_ll,img_rr,img_bb,img_ww,img_hh:integer;
    pp:double;
begin
    img_tt:=Image_show.Top;
    img_ll:=Image_show.Left;
    img_rr:=Image_show.Left + Image_show.Width;
    img_bb:=Image_show.Top  + Image_show.Height;
    img_ww:=Image_show.Width;
    img_hh:=Image_show.Height;

    result:=aRect;

    if aRect.Width > img_ww then begin
        result.Width:=img_ww;
        result.Height:=trunc(img_ww * FProportion);
    end;
    if aRect.Height > img_hh then begin
        result.Height:=img_hh;
        result.Width:=trunc(img_hh / FProportion);
    end;
    if aRect.Left < img_ll then begin
        result.Left  := img_ll;
        result.Right := aRect.Right + img_ll - aRect.Left;
    end;
    if aRect.Right > img_rr then begin
        result.Left  := aRect.Left + img_rr - aRect.Right;
        result.Right := img_rr;
    end;
    if aRect.Top < img_tt then begin
        result.Top  := img_tt;
        result.Bottom := aRect.Bottom + img_tt - aRect.Top;
    end;
    if aRect.Bottom > img_bb then begin
        result.Top  := aRect.Top + img_bb - aRect.Bottom;
        result.Bottom := img_bb;
    end;
    if Selection_Proportional and (aRect.Width<>0) then begin
        pp:=aRect.Height / aRect.Width;
        if pp>FProportion then begin
          result.Height:=trunc(result.Width * FProportion);
        end;
        if pp<FProportion then begin
          result.Width:=trunc(result.Height / FProportion);
        end;
    end;
end;

procedure TForm_Clip_Batch.CheckTranspose;
var image_ratio:double;
begin
    with Image_show.Picture.Bitmap do image_ratio:=Height / Width;
    //if (image_ratio>1) and (Selection_Ratio<1) then Selection_Ratio:=1/Selection_Ratio;
    //if (image_ratio<1) and (Selection_Ratio>1) then Selection_Ratio:=1/Selection_Ratio;
    Portrait:=image_ratio>1;
end;

procedure TForm_Clip_Batch.Panel_showResize(Sender: TObject);
var p1,p2,select_ratio:double;
    img_h,img_w:integer;
begin
    if Image_show.Picture.Bitmap.Width=0 then exit;
    if Panel_show.Width=0 then exit;
    if AutoTranspose then CheckTranspose;
    select_ratio:=Selection_Ratio;
    if not Portrait then select_ratio := 1 / select_ratio;
    img_w:=Image_show.Picture.Bitmap.Width;
    img_h:=Image_show.Picture.Bitmap.Height;
    p1 := img_h / img_w;
    with Panel_show do p2 := Height / Width;
    if p1>p2 then begin
        Image_show.Height:=Panel_show.Height;
        Image_show.Width:=trunc(Panel_show.Height / p1);
    end else begin
        Image_show.Width:=Panel_show.Width;
        Image_show.Height:=trunc(Panel_show.Width * p1);
    end;
    if p1>select_ratio then begin
        Shape_select.Width:=Image_show.Width;
        Shape_select.Height:=trunc(Image_show.Width * select_ratio);
        Shape_select.Top:=trunc((Panel_show.Height - Image_show.Width * select_ratio) / 2);
        Shape_select.Left:=Image_show.Left;
    end else begin
        Shape_select.Height:=Image_show.Height;
        Shape_select.Width:=trunc(Image_show.Height / select_ratio);
        Shape_select.Top:=Image_show.Top;
        Shape_select.Left:=trunc((Panel_show.Width - Image_show.Height / select_ratio) / 2);
    end;
end;

procedure TForm_Clip_Batch.Shape_selectMouseDown(Sender: TObject;
    Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    FProportion:=Shape_select.Height / Shape_select.Width;
    FMouseCursor:=Classes.Point(X+Shape_select.Left,Y+Shape_select.Top);
    with Shape_select do FShapeRect:=Classes.Rect(Left, Top, Left+Width, Top+Height);
    FMouseHold:=true;
    with Shape_select do begin
        if X < activate_margin           then FBorderActivate := FBorderActivate or baLeft;
        if Width - X < activate_margin   then FBorderActivate := FBorderActivate or baRight;
        if Y < activate_margin           then FBorderActivate := FBorderActivate or baTop;
        if Height - Y < activate_margin  then FBorderActivate := FBorderActivate or baBottom;
    end;
    if FBorderActivate = baNone then FBorderActivate:=baMove;
end;

procedure TForm_Clip_Batch.Shape_selectMouseMove(Sender: TObject;
    Shift: TShiftState; X, Y: Integer);
var tmp_rect:TRect;
    cursor_state:TBorderActivate;
    dx,dy:integer;
begin
    if FMouseHold then begin
        dx:=Shape_select.Left + X - FMouseCursor.X;
        dy:=Shape_select.Top  + Y - FMouseCursor.Y;
        tmp_rect:=FShapeRect;
        if (FBorderActivate and baTop)<>0    then inc(tmp_rect.Top,dy);
        if (FBorderActivate and baLeft)<>0   then inc(tmp_rect.Left,dx);
        if (FBorderActivate and baRight<>0)  then inc(tmp_rect.Right,dx);
        if (FBorderActivate and baBottom)<>0 then inc(tmp_rect.Bottom,dy);
        tmp_rect:=BestRect(tmp_rect);
        with tmp_rect do Shape_select.SetBounds(Left, Top, Right-Left, Bottom-Top);
    end else begin
        cursor_state:=0;
        with Shape_select do begin
            if X < activate_margin           then cursor_state := cursor_state or baLeft;
            if Width - X < activate_margin   then cursor_state := cursor_state or baRight;
            if Y < activate_margin           then cursor_state := cursor_state or baTop;
            if Height - Y < activate_margin  then cursor_state := cursor_state or baBottom;
        end;
        case cursor_state of
            baTop, baBottom:                      Shape_select.Cursor:=crSizeNS;
            baLeft, baRight:                      Shape_select.Cursor:=crSizeWE;
            baTop or baLeft, baRight or baBottom: Shape_select.Cursor:=crSizeNWSE;
            baTop or baRight, baLeft or baBottom: Shape_select.Cursor:=crSizeNESW;
            else Shape_select.Cursor:=crSize;
        end;
    end;
end;

procedure TForm_Clip_Batch.Shape_selectMouseUp(Sender: TObject;
    Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
    FMouseHold:=false;
    FBorderActivate:=baNone;
    if Button=mbRight then begin
        if not FileExists(FFileName) then exit;
        case MessageDlg('变更裁切', '将当前裁切覆盖保存？', mtWarning, mbOKCancel, 0) of
            mrOK:ClipImage(FFilename);
        end;
    end;
end;

function TForm_Clip_Batch.LoadFiles(aFileNames:array of string):boolean;
var idx:integer;
    stmp:string;
begin
    result:=true;
    ListBox_filenames.Clear;
    idx:=Length(aFileNames)-1;
    while idx>=0 do begin
        stmp:=aFileNames[idx];
        if not FileExists(stmp) then result:=false;
        ListBox_filenames.AddItem(stmp,nil);
        dec(idx);
    end;
end;

procedure TForm_Clip_Batch.LoadDirectory(aDirectory:string);
begin
    ListBox_filenames.Clear;
    FindAllFiles(ListBox_filenames.Items, aDirectory, '*.*',false,faAnyFile);
end;

procedure TForm_Clip_Batch.LoadImage(aFilename:string);
begin
    FFilename:=aFilename;
    try
      Image_show.Picture.LoadFromFile(aFilename);
      Panel_showResize(Panel_show);
    except
      FFilename:='';
      MessageDlg('文件错误', '未知的图片文件', mtError, [mbOK], 0);
    end;
end;

procedure func_clipbatch_ending(Sender:TObject);
begin
    Form_Clip_Batch.LoadImage(Form_Clip_Batch.FFileName);
end;

procedure TForm_Clip_Batch.ClipImage(aFilename:string);
var pixel_tt,pixel_ll,pixel_ww,pixel_hh:integer;
    scriptlines:TStringList;
begin
    if not FileExists(FFileName) then exit;
    pixel_ww := trunc(Image_show.Picture.Bitmap.Width  * Shape_select.Width  / Image_show.Width);
    pixel_hh := trunc(Image_show.Picture.Bitmap.Height * Shape_select.Height / Image_show.Height);
    pixel_ll := trunc(Image_show.Picture.Bitmap.Width  * (Shape_select.Left  - Image_show.Left) / Image_show.Width);
    pixel_tt := trunc(Image_show.Picture.Bitmap.Height * (Shape_select.Top   - Image_show.Top)  / Image_show.Height);
    //裁切
    scriptlines:=TStringList.Create;
    try
      with scriptlines do begin
        Add('var int image 8');
        Add('img.new @image');
        Add(Format('img.load @image,"%s"',[aFilename]));
        Add(Format('img.clip @image,%d,%d,%d,%d',[pixel_ll,pixel_tt,pixel_ww,pixel_hh]));
        Add(Format('img.save @image,"%s",-f',[aFilename]));
        Add('img.del @image');
        Add('unvar image');
      end;
      Auf.Script.Func_process.ending:=@func_clipbatch_ending;
      Auf.Script.command(scriptlines);
    finally
      scriptlines.Free;
    end;
end;

end.

