{*******************************************************}
{                                                       }
{               HCView V1.0  作者：荆通                 }
{                                                       }
{      本代码遵循BSD协议，你可以加入QQ群 649023932      }
{            来获取更多的技术交流 2018-5-4              }
{                                                       }
{                文本类的HCItem基类单元                 }
{                                                       }
{*******************************************************}

unit HCTextItem;

interface

uses
  Windows, Classes, SysUtils, Graphics, HCStyle, HCItem;

type
  THCTextItem = class(THCCustomItem)
  private
    FText: string;
  protected
    function GetText: string; override;
    procedure SetText(const Value: string); override;
    function GetLength: Integer; override;
    procedure Assign(Source: THCCustomItem); override;
    function BreakByOffset(const AOffset: Integer): THCCustomItem; override;
    // 保存和读取
    procedure SaveToStream(const AStream: TStream; const AStart, AEnd: Integer); override;
    procedure LoadFromStream(const AStream: TStream; const AStyle: THCStyle;
      const AFileVersion: Word); override;
  public
    constructor CreateByText(const AText: string); virtual;

    /// <summaryy 复制一部分文本 </summary>
    /// <param name="AStartOffs">复制的起始位置(大于0)</param>
    /// <param name="ALength">众起始位置起复制的长度</param>
    /// <returns>文本内容</returns>
    function GetTextPart(const AStartOffs, ALength: Integer): string;
  end;

implementation

uses
  HCCommon, HCTextStyle;

{ THCTextItem }

constructor THCTextItem.CreateByText(const AText: string);
begin
  Create;  // 这里如果 inherited Create; 则调用THCCustomItem的Create，子类TEmrTextItem调用CreateByText时不能执行自己的Create
  FText := AText;
  StyleNo := THCStyle.RsNull;  // 默认无样式
end;

procedure THCTextItem.Assign(Source: THCCustomItem);
begin
  inherited Assign(Source);
  Self.Text := (Source as THCTextItem).Text;
end;

function THCTextItem.BreakByOffset(const AOffset: Integer): THCCustomItem;
begin
  if (AOffset >= Length) or (AOffset <= 0) then
    Result := nil
  else
  begin
    Result := inherited BreakByOffset(AOffset);
    Result.Text := Self.GetTextPart(AOffset + 1, Length - AOffset);
    Delete(FText, AOffset + 1, Length - AOffset);  // 当前Item减去光标后的字符串
  end;
end;

function THCTextItem.GetLength: Integer;
begin
  Result := System.Length(FText);
end;

function THCTextItem.GetText: string;
begin
  Result := FText;
end;

function THCTextItem.GetTextPart(const AStartOffs, ALength: Integer): string;
begin
  Result := Copy(FText, AStartOffs, ALength);
end;

procedure THCTextItem.LoadFromStream(const AStream: TStream;
  const AStyle: THCStyle; const AFileVersion: Word);
var
  vSize: Word;
  vBuffer: TBytes;
begin
  inherited LoadFromStream(AStream, AStyle, AFileVersion);
  AStream.ReadBuffer(vSize, SizeOf(vSize));
  if vSize > 0 then
  begin
    SetLength(vBuffer, vSize);
    AStream.Read(vBuffer[0], vSize);
    FText := StringOf(vBuffer);
  end;
end;

procedure THCTextItem.SaveToStream(const AStream: TStream; const AStart, AEnd: Integer);
var
  vBuffer: TBytes;
  vSize: Word;  // 最多65536个字节，如果超过65536，可使用写入文本后再写一个结束标识(如#9)，解析时遍历直到此标识
  vS: string;
begin
  inherited SaveToStream(AStream, AStart, AEnd);
  vS := GetTextPart(AStart + 1, AEnd - AStart);
  vBuffer := BytesOf(vS);
  if System.Length(vBuffer) > MAXWORD then
    raise Exception.Create(CFE_EXCEPTION + 'TextItem的内容超出最大字符数据！');
  vSize := System.Length(vBuffer);
  AStream.WriteBuffer(vSize, SizeOf(vSize));
  if vSize > 0 then
    AStream.WriteBuffer(vBuffer[0], vSize);
end;

procedure THCTextItem.SetText(const Value: string);
begin
  FText := Value;
end;

end.
