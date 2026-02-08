unit uOCRWorkerThread;

interface

uses
  System.Classes, System.SyncObjs, System.SysUtils, System.Generics.Collections,
  System.Messaging, uTesseractBaseAPI, uTesseractOCR;

const
  OCRTHREADMSG_QUIT       = 1;
  OCRTHREADMSG_SETIMAGE   = 2;
  OCRTHREADMSG_RECOGNIZE  = 3;
  OCRTHREADMSG_INITIALIZE = 4;

type
  TMsgInfo = record
    Msg          : integer;
    ID           : integer;
    PageSegMode  : integer;
    Data         : TBytes;
    LeptonicaLib : string;
    TesseractLib : string;
    Datapath     : string;
    Language     : string;
  end;

  IMessageReceiverForm = interface
    procedure HandleSetImageResult(aMessageID: integer; aResult : boolean);
    procedure HandleRecognizeResult(aMessageID: integer; const aText: string; aResult : boolean);
    procedure HandleInitializationResult(aResult : boolean);
  end;

  TCustomMessage = TMessage<TMsgInfo>;

  TOCRWorkerThread = class(TThread)
    protected
      FCritSect        : TCriticalSection;
      FEvent           : TEvent;
      FWaiting         : boolean;
      FStop            : boolean;
      FMsgQueue        : TQueue<TCustomMessage>;
      FTesseractOCR    : TTesseractOCR;
      FForm            : IMessageReceiverForm;

      function  Lock : boolean;
      procedure Unlock;
      function  CanContinue : boolean;
      procedure ReadAllPendingMessages;
      function  ReadPendingMessage(var aMsgInfo : TMsgInfo) : boolean;
      procedure StopThread;
      procedure DestroyQueue;

      procedure Execute; override;

    public
      constructor Create(const aForm : IMessageReceiverForm);
      destructor  Destroy; override;
      procedure   AfterConstruction; override;
      procedure   EnqueueMessage(const aMessage : TCustomMessage);
  end;

implementation

uses
  FMX.Forms, uTesseractTypes;

constructor TOCRWorkerThread.Create(const aForm : IMessageReceiverForm);
begin
  FCritSect        := nil;
  FWaiting         := False;
  FStop            := False;
  FEvent           := nil;
  FMsgQueue        := nil;
  FTesseractOCR    := nil;
  FForm            := aForm;

  inherited Create(True);

  FreeOnTerminate := False;
end;

destructor TOCRWorkerThread.Destroy;
begin
  if (FEvent        <> nil) then FreeAndNil(FEvent);
  if (FCritSect     <> nil) then FreeAndNil(FCritSect);
  if (FTesseractOCR <> nil) then FreeAndNil(FTesseractOCR);

  DestroyQueue;

  FForm := nil;

  inherited Destroy;
end;

procedure TOCRWorkerThread.DestroyQueue;
begin
  if (FMsgQueue <> nil) then
    begin
      while (FMsgQueue.Count > 0) do
        FMsgQueue.Dequeue.Free;

      FMsgQueue.Clear;
      FreeAndNil(FMsgQueue);
    end;
end;

procedure TOCRWorkerThread.AfterConstruction;
begin
  inherited AfterConstruction;

  FEvent        := TEvent.Create(nil, False, False, '');
  FCritSect     := TCriticalSection.Create;
  FMsgQueue     := TQueue<TCustomMessage>.Create;
  FTesseractOCR := TTesseractOCR.Create(nil);
end;

function TOCRWorkerThread.Lock : boolean;
begin
  if (FCritSect <> nil) then
    begin
      FCritSect.Acquire;
      Result := True;
    end
   else
    Result := False;
end;

procedure TOCRWorkerThread.Unlock;
begin
  if (FCritSect <> nil) then FCritSect.Release;
end;

procedure TOCRWorkerThread.StopThread;
begin
  if Lock then
    begin
      FStop := True;
      Unlock;
    end;
end;

procedure TOCRWorkerThread.EnqueueMessage(const aMessage : TCustomMessage);
begin
  if Lock then
    try
      if (FMsgQueue <> nil) then FMsgQueue.Enqueue(aMessage);

      if FWaiting then
        begin
          FWaiting := False;
          FEvent.SetEvent;
        end;
    finally
      Unlock;
    end;
end;

function TOCRWorkerThread.ReadPendingMessage(var aMsgInfo : TMsgInfo) : boolean;
var
  TempMessage : TCustomMessage;
begin
  Result := False;

  if Lock then
    try
      FWaiting := False;

      if (FMsgQueue <> nil) and (FMsgQueue.Count > 0) then
        begin
          TempMessage := FMsgQueue.Dequeue;
          aMsgInfo    := TempMessage.Value;
          Result      := True;
          TempMessage.Free;
        end;
    finally
      Unlock;
    end;
end;

procedure TOCRWorkerThread.ReadAllPendingMessages;
var
  TempInfo : TMsgInfo;
  TempText : string;
  TempRslt : boolean;
  TempStream : TMemoryStream;
begin
  while ReadPendingMessage(TempInfo) do
    case TempInfo.Msg of
      OCRTHREADMSG_QUIT :
        begin
          StopThread;
          exit;
        end;

      OCRTHREADMSG_SETIMAGE :
        begin
          TempStream := TMemoryStream.Create;
          TempStream.WriteBuffer(TempInfo.Data, length(TempInfo.Data));
          TempRslt := FTesseractOCR.BaseAPI.SetImage(TempStream);
          TempStream.Free;

          Synchronize(procedure
                      begin
                        FForm.HandleSetImageResult(TempInfo.ID, TempRslt);
                      end);
        end;

      OCRTHREADMSG_RECOGNIZE :
        begin
          TempRslt := False;
          TempText  := '';

          if FTesseractOCR.Initialized then
            begin
              FTesseractOCR.BaseAPI.PageSegMode := TessPageSegMode(TempInfo.PageSegMode);

              if FTesseractOCR.Recognize then
                begin
                  TempText := FTesseractOCR.BaseAPI.GetText;
                  TempRslt := True;
                end;
            end;

          Synchronize(procedure
                      begin
                        FForm.HandleRecognizeResult(TempInfo.ID, TempText, TempRslt);
                      end);
        end;

      OCRTHREADMSG_INITIALIZE :
        begin
          TempRslt := FTesseractOCR.Initialize(TempInfo.LeptonicaLib,
                                               TempInfo.TesseractLib,
                                               TempInfo.Datapath,
                                               TempInfo.Language);
          Synchronize(procedure
                      begin
                        FForm.HandleSetImageResult(TempInfo.ID, TempRslt);
                      end);
        end;
    end;
end;

function TOCRWorkerThread.CanContinue : boolean;
begin
  Result := False;

  if Lock then
    try
      if not(Terminated) and not(FStop) then
        begin
          Result   := True;
          FWaiting := True;
          FEvent.ResetEvent;
        end;
    finally
      Unlock;
    end;
end;

procedure TOCRWorkerThread.Execute;
begin
  while CanContinue do
    begin
      FEvent.WaitFor(INFINITE);
      ReadAllPendingMessages;
    end;
end;

end.
