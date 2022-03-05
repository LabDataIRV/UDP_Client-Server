unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  blcksock; //модуль сетевых сокетов

type

  { UDPServer }
  // Класс для прослушивания порта в отдельном потоке
  TUDPServer = class(TThread)
  private
      FSocket:TUDPBlockSocket; // объект UDP сокета приема
      message: String;         // принятое сообщение
  protected
       procedure Execute;override; // Функция ожидания сообщения параллельно
       procedure TakeMessage;      // Функция передачи сообщения основной программе
  end;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    MsgE: TEdit;
    BrodcastIP: TEdit;
    User: TEdit;
    sPort: TEdit;
    cPort: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    procedure SendMessage(MessageText: string; IP:string); // функция отправки сообщения
  public
  end;


var
  Form1: TForm1;
  Server : TUDPServer; // объект UDP сервера
implementation

{$R *.lfm}

  { UDPServer }
// Ожидание сообщений
procedure TUDPServer.Execute;
var S: string;
begin
  FSocket:=TUDPBlockSocket.Create; // Создание объекта сокета
  try
    FSocket.EnableReuse(True);//включаем режим повторного использования адреса
    FSocket.Bind(FSocket.LocalName,Form1.sPort.Text);//привязываем сокет к адресу
    if FSocket.LastError<>0 then //во время привязки произошла ошибка
      begin
        message:='Ошибка запуска сервера';
        Synchronize(@TakeMessage); // Вызов функции отправки сообщения
        Exit;
      end;
    while not Terminated do  // Цикл до завершения потока
      begin
        S:=FSocket.RecvPacket(10); //пробуем получить пакет
        if S<>'' then // Если что-то принято
        begin
          message:=S; //пакет получен - обрабатываем
          Synchronize(@TakeMessage); // Вызов функции отправки сообщения
        end;
      end;
  finally
    FSocket.Free; // Освобождение сокета
  end;
end;
// Получение сообщений
procedure TUDPServer.TakeMessage;
begin
      Form1.Memo1.Append(message); // Обращение к элементам формы
end;

  { TForm1 }
//Старт сервера
procedure TForm1.Button1Click(Sender: TObject);
begin
    Server:=TUDPServer.Create(True);// Создание объекта сокета
    Server.Priority:=tpNormal; // Приоритет использования профессора
    Server.Start;             // Запуск прослушивания порта
end;
// Отпрвить всем сообщение
procedure TForm1.Button2Click(Sender: TObject);
begin
  SendMessage(MsgE.Text,'');//Отправка сообщения
end;
// Остановка сервера
procedure TForm1.Button3Click(Sender: TObject);
begin
    Server.Terminate; // Остановить поток сервера
    Server.WaitFor;   // Ожидание окончания процессов
    Server.Free;      // Освобождение памяти
end;
// Отправка сообщения
procedure TForm1.SendMessage(MessageText: string; IP:string);
var s: string;
    SendSock: TUDPBlockSocket;
begin
  S:=Format('%s:%s',[User.Text,MessageText]);
  SendSock:=TUDPBlockSocket.Create;
  try
    SendSock.createsocket;
    if IP='' then // отправка всем
      begin
        SendSock.EnableBroadcast(True);
        SendSock.Connect(BrodcastIP.Text,cPort.Text);
      end
    else
      SendSock.Connect(IP,cPort.Text);//отправить отдельно по IP
    SendSock.SendString(s);
    if SendSock.LastError<>0 then
       Memo1.Append('Ошибка отправки сообщения');
  finally
    SendSock.Free;
  end;
end;

end.

