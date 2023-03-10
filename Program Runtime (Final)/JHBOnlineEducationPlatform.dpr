{
Jan-Hendrik Brink 2022-08-25
 _________   _    _     _ ____
|___   ___| | |  | |   | |__  |
    | |     | |__| |   | |__|_|
  __| |     |  __  |   | |__| |
 |____|     |_|  |_|   |_|____|
}
program JHBOnlineEducationPlatform;

uses    //Al die nuttige en nodige Libraries wat gebruik word
  Windows,Messages,SysUtils,Variants,Classes,Graphics,Controls,Forms,ComCtrls,Dialogs,ExtCtrls,
  StdCtrls,ActiveX,ComObj,ADODB,DB,DBgrids,Math,ShellAPI,Buttons,Jpeg,pngimage,Spin,Diagnostics,Menus;

{$R *.res} //Konstantes
const CONNECTIONSTRING = 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source=OnlineEducationDB.mdb; Mode=ReadWrite; Persist Security Info=False';
      BIT16INTEGER = 65535;   //Grootste moontlike getal wat in 16 binere bits se inlingtg pas
      clBackGround = $0267DB;   //agter grond kleur van login-skerm
type
//=====================================================================================
  TJHBGraphicControl = class(TCustomControl)   //klas vir Spesiale grafiese komponent
    const
     gsRectangle = 0;         //Vorms wat die komponent kan aan neem
     gsEllipse = 1;
     gsRoundRect =2;
     gsPolygon = 3;
    Type
     PointArr = Array of TPoint;        //n array van punte wat se waar elke hoek van die komponet is
    private
      GraphKoordinates : PointArr;      //grafiekse koordinate vir die grafika
      TextKoordinates : PointArr;       //teks koordinate vir die teks van die komponent
      byGraphicShape : byte;              //stoor vorm van komonent
      Caption : string;
      TextFormat : TTextFormat;         //formaate van teks

    Public
      procedure JhbbtnColorChange(Sender:Tobject);   //verander kleur
      procedure SetGraphic(_Koordinate : PointArr; _graphicshape : byte; _BrushColor : tColor; _BrushStyle : TBrushStyle;  _PenColor : TColor; _PenWidth : integer);   //stel grafiese koordinante en kleure
      procedure SetText(p_FontName : string; p_FontColor : TColor; p_FontStyles : TFontStyles ;p_TextFormat : TTextFormat; p_FontSize : integer; _Koordinate : PointArr);  //set teks koordinate ek kleure
      function IntArrTOPointArr(intarr : array of integer) : pointarr; //maak array van integers na n array van koordinate
      protected
      procedure Paint; override; //skryf die inligting van die komponent na VRAM om geteken te word op skerm
  end;
//=====================================================================================
  TCourse = class
   type
        RElementPropertiesGUI = record    //Record om al die grafiese komponente te stoor
          arrlbl : array[1..10] of TLabel;
          arrspnedt : array[1..4] of TSpinEdit;
          arredt : array[1..6] of TEdit;
          arrcmb : array [1..3] of TComboBox;
          arrbitbtn : array[1..3] of TBitBtn;
          arrmovebtn : array[1..2] of TButton;
          arrshp : array[1..2] of TShape;
          arrcb : array [1..1] of TCheckBox;
        end;

        TCourseElement = class(TJHBGraphicControl)  //Kursus element  , "Inherit" van die JHBGRAPHIC CONTROL af
          const
           cePage = 0;                //Tipe Kurus element
           ceBlankSpace = 1;
           ceText = 2;
           ceiFrame = 3;
           ceImage = 4;
           ceAudio = 5;
           ceVideo = 6;

           alLeft = 0;               //Alignment vand ie kursus element
           alCentre = 1;
           alRight = 2;

          public
           imgIcon : TImage;                       //publike grafiese komponente
           byElementType  : byte;
           iIndexPosition : integer;
           tfAlignment : TTextFormats;
           PropertiesGUI : RelementPropertiesGUI;  //Die Grafiekse komponente rekord
           ssource , shref : string;
           idispHeight , idispWidth : integer;
           bIsLink : boolean;                    //stel of komponent n HREF tag is
          procedure UpdateCourseElementGraphics(Element : TCourse.TCourseElement);
          procedure ChangePenColorOnMouseOver(Sender : TObject);       //verande kleur as muis oor beweeg
          procedure FreeAndNilElementPropertiesGuiComponents();
        end;

   private
   arrCourseContent : array of TCourseElement;
   arrCoursePopulationElements : array[1..6] of TCourseElement; //Array om elk van die  verskillende Elemente te hou
   CourseMainFileElement : TCourseElement;        //hou hoof inligting van kursus blad

   iSelectedElementIndex : integer;
   procedure TranslateCourseContentTOHTML(Sender : TObject); //save kursus
   procedure LoadCourseFromHTML(Sender : TObject);
   procedure CourseElementMouseUpInteract(Sender : Tobject; Button : TMouseButton; Shift : TShiftState; X , Y : integer);
   procedure populateElementList(CreateParent : TWinControl);
   procedure AddElementToCourse(Sender : Tobject);
   procedure CloneCourseElement(Old, New : TCourseElement);
   procedure OpenElementProperties(Sender : Tobject);
   procedure OpenCourseProperties(Sender : TObject);
   procedure ElementPopupMenu(Sender : Tobject); //Nie in FASE 1
   procedure SaveAndViewCourse(Sender : Tobject); //Nie in FASE 1
   procedure UpdateCourseElementIndexPosition(Sender : TOBject);
   procedure CreateCourseElementMovementButtons(Sender : Tobject);
   procedure OrganiseElementsInOutput();
   procedure DeleteCourseElement(Sender : Tobject);
   procedure UpdateCourseElementCaption(Sender : Tobject);
   procedure UpdateCourseElementFontSize(Sender : TObject);
   procedure GetTextFromJHBInputQuery(Sender : Tobject);
   procedure UpdateCourseElementSource(Sender : Tobject);
   procedure UpdateCourseElementDispWidth(Sender : Tobject);
   procedure UpdateCourseElementDispHeight(Sender : Tobject);
   procedure UpdateCourseElementHref(Sender : Tobject);
   procedure UpdateCourseElementColor(Sender : Tobject);
   procedure UpdateCourseMainFileName(Sender : TObject);
   procedure ReadSourceFromOpenDlg(Sender : TObject) ;
   procedure UpdateCourseMainFileImgSource(Sender : TObject);
   procedure PublishbtnMouseUpInteract(Sender : Tobject; Button : TMouseButton; Shift : TShiftState; X , Y : integer);
   procedure PublishPopupMenu(Sender: TObject);
   procedure PublishCourse(Sender : TObject);
  end;
//=====================================================================================
//=======================================================================================
  TMain = class     //Die hoof klas wat hoof en sub forms beheer
     type
      TCompiledCourse = class(TJHBGraphicControl)    //Finaal gekompleerde kursus grafika waarop gebruiker kan klik
         type
           TGUI = record
             img : TImage;
             jhbgraphcrtl : TJHBGraphicControl;        //Subscribe knoppie
             jhbgraphctrlLike : TJHBGraphicControl;    //hou van knoppie
             jhbgraphctrlDisLike : TJHBGraphicControl; //hou nie van knoppie
           end;
       private
       GUI : TGUI;                                                   //die GGK van die komponent
       sCourseID : string;
       procedure SetupGUI(Jpgimg : TJpegImage; bowned , bBrowsing : boolean);   //Stel GGK op
       procedure HighlightSubButton(Sender : Tobject);
       procedure HighlightLikeORDislikeButton(Sender : Tobject);
       Procedure SubscribeToCourse(Sender : TObject);
       Procedure UnSubscribeFromCourse(Sender : TObject);
       procedure OpenCourseinBrowser(Sender : Tobject);
       procedure MouseUpInteract(Sender : Tobject; Button : TMouseButton; Shift : TShiftState; X , Y : integer);
       procedure CompiledCoursePopup(Sender : TObject);
       procedure RateCourse(Sender : TObject);
       destructor destroy();override;         //OM die geheue skoon te maak waarin die komponent tgestoor is
     end;

    private                                        //GGK komponente wat deel is van MIAN klass
      arrlbl : array[1..10] of TLabel;
      arredt : array[1..4] of TEdit;
      arrbitbtn : array[1..3] of TBitBtn;
      arrcheckbox : array[1..2] of TCheckBox;
      arrpanel : array[1..2] of TPanel;
      arrjhbgraphctrl : array[1..5] of TJHBGraphicControl;
      arrscrlbox : array[1..3] of TScrollbox;
      timer : Ttimer;
      sVerifyCode : String;
      sUserName : string;
      sUserEmail : string;
      sBrowseFilter : string;
      sMotherBoardSerial : string;
      arrBrowseableCourses : array of TCompiledCourse;
      frm : TForm;
      Tempfrm : TForm;
      RedtDist : TRichEdit;//Richedit om Donasie dustrubiese te verteenwoordig
      btnPay : TButton;
      rPay : real;
      iTotalRating : integer;
    public                                                     //Publieke funksies en procedures
      procedure WelcomeUser();
      procedure CheckForAutoSignin(Sender : TObject);

      procedure CreateAccount(Sender : TObject);
      procedure CheckAccountRegisteredits(Sender : TOBject);
      procedure PostNewAccount(Sender : TObject);

      procedure SignInToAccount(Sender : TObject);
      procedure SignIn(Sender : TObject);
      procedure AutoSignInToAccount();

      procedure RetryEditResponse(Sender : TObject);
      procedure LabelHrefColorChange(Sender : TObject);

      procedure MainMenu(Sender:Tobject);
      procedure SignOutLabelColorAndTextChange(Sender:Tobject);
      procedure SignOutofAccount(Sender:Tobject);
      procedure SetSelectFilter(Sender : Tobject);

      procedure ForgotPassword(Sender: TObject);
      procedure PasswordReset(Sender : TObject);
      procedure VerifyAndReset(Sender : TObject);
      procedure SendVerificationEmail(Sender : TObject);
      procedure SetNewPassword(Sender : TObject);

      procedure CreateNewCourse(Sender : TObject);
      procedure BrowseCourses(Sender : Tobject);
      procedure DisplayCompiledCourses(bBrowsing : Boolean);
      procedure SetBrowseFilter(Sender : Tobject);

      procedure FreeAndNilGUIComponents();
      function  GetMotherBoardSerial() : string;
      procedure AppEntry();

      function InttoHTMLHex(value : TColor) : string;     //Nie in fase 1
      function HTMLHEXtoint(svalue : string) : integer; //Nie in fase 1
      function JHBInputQuery(sTitle , sCaption  , sDescription: string; var sResult : string) : boolean;
      function FileSelectDialog(Title,Filter : string) : string;

      procedure TempPopupDlg(sText : string ; rshowTime : real);
      procedure CloseTempFrm(Sender : TObject);
      procedure RestartProgram(cmdParam : string);

      procedure DonateToPlatform(Sender : TObject);
      procedure CalcMoneyDist(Sender : TObject);
      procedure SubmitDonation(Sender : TObject);

      destructor destroy(); override;
  end;
//=====================================================================================
  TDB = class           //Klas om al die Data Basis operasies te beheer
    private
    public
    fname : string;
    fConnectionString : string;
    Con : TADOConnection;
    tblusr : TADOTable;
    tblcourse : TADOTable;
    tblOwnedcourses : TADOTABLE;
    CourseFileBlobField : TBlobField;
    qry : TADOQuery;
    constructor Create(Databasename , ConnectionString : string);
    function SearchDB(table , field , value : string) : integer;       //Soek in die databasis
    procedure RunSQLQuery(funcqry : TADOQUERY;SQLStatements : array of string);
    function CompareLoginDetails(sUsername , sPassword , sEmail : string) : boolean;
    procedure PublishCourse(scoursename , sfilepath , simgPath : string)  ;
    procedure DisplayData(dispqry : TADOquery); //DBGrid Usage
    destructor destroy();override;                  //maak data basis klas se geheue skoon
  end;
//=====================================================================================
var
  Main : TMain;       //Main komponents om hoof procedures te beheer
  DB : TDB;           //Data basis komponent om Databasis procedures te beheer
//.......................................................................................
//                                 TMain
//.......................................................................................
procedure TMain.AppEntry();        //Begin punt van die Main komponent van die program
begin                          //(1)
frm := TForm.Create(nil) ;                   //Hoof form wat gebruik word
 with frm do                                  //Stel form se GGK , en dimensies
  begin
   Width := 960;
   Height := 540;
   Caption := 'JHB-Online Education !' ;
   color := clBackGround;
   Position := poScreenCenter;          //Form posisie
  end;
sMotherBoardSerial := GetMotherBoardSerial;   //Moederbord se serial nommer

if ParamStr(1) = 'Signout' then          //Indien program met "Signout" begin word , doen eerdie die
SignintoAccount(self)
else
WelcomeUser();                            //begin sonder parameter

frm.showmodal;                             //wys form
end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.WelcomeUser();          //Welkom skerm
begin
arrlbl[1] := TLabel.Create(nil);
 with arrlbl[1] do                      //(2)           //maak label wat vertoon word
  begin
   Parent := frm;
   Caption := 'Welcome to Jan-Hendrik''s ' +#13+#13+ 'Online Education Platform';
   Font.Size := 30;
   Font.Name := 'Unispace';
   Font.Style := [fsbold];
   Top := trunc(frm.Height /2) - HEight;
   Left := trunc((frm.Width /2) -(Width/2));
  end;

timer := TTimer.Create(nil);                           //maak timer wat 2 sekondes tel
 with timer do
  begin
    timer.Interval := 2000;
    timer.OnTimer := Main.CheckForAutoSignin;
  end;

end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.CheckForAutoSignin(Sender : TObject);      //kyk of gebruiker klaar op die rekenaar bekend is
begin
FreeandNil(arrlbl[1]);
FreeAndNil(timer);                            //(3)

if DB.SearchDB('tblusr','ActiveComputer',sMotherBoardSerial) = 1 then     //kyk of rekenaar bestaan
 Main.AutoSignInToAccount()
else if DB.SearchDB('tblcomputers','MotherboardSerial',sMotherBoardSerial) = 0 then
    main.CreateAccount(nil)               //maak nuwe account
else
    Main.SignInToAccount(nil);            //sign in n account is

end;
/////////////////////////////////////////////////////////////////////////////////////////
function TMain.GetMotherBoardSerial():string;  //Kry moeder bord se serial nommer
var
  objWMIService : OLEVariant;
  colItems      : OLEVariant;
  colItem       : OLEVariant;
  oEnum         : IEnumvariant;
  iValue        : LongWord;
  function GetWMIObject(const objectName: String): IDispatch;    //Maak n Windows Menu Interface Object
       var
        chEaten: Integer;
        BindCtx: IBindCtx;
        Moniker: IMoniker;
       begin
        OleCheck(CreateBindCtx(0, bindCtx));      //maak binding na CTX
        OleCheck(MkParseDisplayName(BindCtx, StringToOleStr(objectName), chEaten, Moniker)); //Maak die Display oop na die Moniker(Systeem)
        OleCheck(Moniker.BindToObject(BindCtx, nil, IDispatch, Result));//Bind die CTX en Moniker
       end;
begin
  Result:='';
  objWMIService := GetWMIObject('winmgmts:\\localhost\root\cimv2');  //Maak die Windows Menu Intefece Voorwerp
  colItems      := objWMIService.ExecQuery('SELECT SerialNumber FROM Win32_BaseBoard','WQL',0); //Run Die Windows Query om Die moederbord se serial nommer te kry
  oEnum         := IUnknown(colItems._NewEnum) as IEnumVariant;
  if oEnum.Next(1, colItem, iValue) = 0 then
  Result:=VarToStr(colItem.SerialNumber);    //verwerk die "VAR"(onbekende) na n string
end;
///////////////////////////////////////////////////////////////////////////////////////
procedure TMain.FreeAndNilGuiComponents();     //Maak GGK van MAIN komponent skoon
var
icount : integer;
begin

try
for icount := low(arrjhbgraphctrl) to high(arrjhbgraphctrl) do
    FreeAndNil(arrjhbgraphctrl[icount]);
for icount := low(arrlbl) to high(arrlbl) do
    FreeAndNil(arrlbl[icount]);
for icount := low(arrbitbtn) to high(arrbitbtn) do
    FreeAndNil(arrbitbtn[icount]);                                   //Gaan deur elke komponent en FREE()
for icount := low(arredt) to high(arredt) do
    FreeAndNil(arredt[icount]);
for icount := low(arrcheckbox) to high(arrcheckbox) do
    FreeAndNil(arrcheckbox[icount]);
for icount := low(arrpanel) to high(arrpanel) do
    FreeAndNil(arrpanel[icount]);
for icount := low(arrBrowseableCourses) to high(arrBrowseableCourses) do
    freeandnil(arrBrowseableCourses[icount]);
    setlength(arrBrowseableCourses , 0);
for icount := low(arrscrlbox) to high(arrscrlbox) do
    FreeAndNil(arrscrlbox[icount]);
FreeAndNil(timer);
FreeAndNil(RedtDist);
except
showmessage('Error Freeing');
end;


end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.CreateAccount(Sender : TObject);     //Maak nuwe account
const
EDTWIDTH = 400;
LABELFONT = 'UniSpace';
begin
FreeAndNilGuiComponents();

arrlbl[5] := TLabel.Create(nil);            //(3.1)         //Label om as Heading te dien
with arrlbl[5] do
begin
parent := frm;
name := 'lblRegisterHEading';
Caption := 'Register New Account';
Font.Size := 35;
Font.name := LABELFONT;
Font.Style := [fsUnderline , fsBold];
Top := 8;
Left := trunc(frm.Width / 2) - trunc(Width /2);
end;

arrlbl[1] := TLabel.Create(nil);                            //Label om Naam van Gebruiker te gee
with arrlbl[1] do
begin
  name := 'lblname';
  parent := frm;
  Caption := 'Name : ';
  Font.Size := 20;
  Font.name := LABELFONT;
  Top := 100;
  Left := trunc(((frm.Width / 2) - (Width /2) )/ 4);
end;

    arredt[1] := TEdit.Create(nil);                                    //Edit om naam van gebruiker te neem
    with arredt[1] do
    begin
      name := 'edtname';
      parent := frm;
      TextHint := 'Your Username';
      Text := '';
      Font.Size := 18;
      Font.name := LABELFONT;
      Top := arrlbl[1].Top + arrlbl[1].Height + 5;
      Left := arrlbl[1].Left;
      Width := edtwidth;
      OnChange := Main.CheckAccountRegisterEdits;
     end;

arrlbl[2] := TLabel.Create(nil);                                  //Label om Epoas te beskryf
with arrlbl[2] do
begin
  name := 'lblemail';
  parent := frm;
  Caption := 'Email adress : ';
  Font.Size := 20;
  Font.name := LABELFONT;
  Top := arrlbl[1].Top + arrlbl[1].Height + 50;
  Left := arrlbl[1].Left;
end;

    arredt[2] := TEdit.Create(nil);                            //Edit om epos in te neem
    with arredt[2] do
    begin
      name := 'edtemail';
      parent := frm;
      TextHint := 'Your EmailAdress';
      text := '';
      Font.Size := 18;
      Font.name := LABELFONT;
      Top := arrlbl[2].Top + arrlbl[2].Height + 5;
      Left := arrlbl[2].Left;
      Width := edtwidth;
      OnChange := Main.CheckAccountRegisterEdits;            //kyk of inset valid is
    end;

arrlbl[3] := TLabel.Create(nil);                       //Label om wagwoord te vra
with arrlbl[3] do
begin
  name := 'lblpswd';
  parent := frm;
  Caption := 'Password : ';
  Font.Size := 20;
  Font.name := LABELFONT;
  Top := arrlbl[2].Top + arrlbl[2].Height + 50;
  Left := arrlbl[2].Left;
end;

    arredt[3] := TEdit.Create(nil);                //Edit om Wagwoord te ontvang
    with arredt[3] do
    begin
      name := 'edtpswd';
      parent := frm;
      TextHint := 'Your Password';
      text := '';
      Font.Size := 18;
      Font.name := LABELFONT;
      Top := arrlbl[3].Top + arrlbl[3].Height + 5;
      Left := arrlbl[3].Left;
      Width := edtwidth;
      PasswordChar := '*';
      OnChange := Main.CheckAccountRegisterEdits;       //Kyk of wagwoord vaid is

    end;

arrlbl[4] := TLabel.Create(nil);                      //lABEL OM VIR Confirm wagwoord te vra
with arrlbl[4] do
begin
  name := 'lblconfpswd';
  parent := frm;
  Caption := 'Confirm Password : ';
  Font.Size := 20;
  Font.name := LABELFONT;
  Top := arrlbl[3].Top + arrlbl[3].Height + 50;
  Left := arrlbl[3].Left;
end;

    arredt[4] := TEdit.Create(nil);                         //Edit om Confirm wagwoord te ontvang
    with arredt[4] do
    begin
      name := 'edtconfpaswd';
      parent := frm;
      TextHint := 'Confirm Password';
      text := '';
      Font.Size := 18;
      Font.name := LABELFONT;
      Top := arrlbl[4].Top + arrlbl[4].Height + 5;
      Left := arrlbl[2].Left;
      Width := edtwidth;
      PasswordChar := '*';
      OnChange := Main.CheckAccountRegisterEdits;                      //Kyk of confirm wagwoord valid is
    end;

          arrbitbtn[1] := TBitBtn.Create(nil);             //Bit Button om Account te SUBMIT
          with arrbitbtn[1] do
          begin
            name := 'lblWarning' ;
            parent := frm;
            Caption := 'Create Account !';
            Font.Size := 19;
            Font.name := LABELFONT;
            Font.Style := [fsbold];
            Font.Color := $2cc748;
            Top := arredt[4].Top + arredt[4].Height + 15;
            Left := arredt[4].Left + 70;
            Height := 40;
            Width := 250;
            OnClick := Main.PostNewAccount;     //Lees nuwe account is databasis in
          end;

arrlbl[6] := TLabel.Create(nil);           //Label om te waarsku dat al die insette ingevul moet word
with arrlbl[6] do
begin
  name := 'lblWarning' ;
  parent := frm;
  Caption := 'All fields need to be filled in !';
  Font.Size := 20;
  Font.name := LABELFONT;
  Font.Style := [fsitalic , fsUnderline];
  Font.Color := clred;
  Top := arrlbl[5].Top + arrlbl[5].Height + 10;
  Left := arrlbl[5].Left + ((arrlbl[5].width - arrlbl[6].width) DIV 2);
  Width := Width + 20;
end;

arrlbl[7] := TLabel.Create(nil);                //Label om se indien naam gevat is of oop is
with arrlbl[7] do
begin
  name := 'lblnamecheck';
  parent := frm;
  Font.Size := 15;
  Font.name := LABELFONT;
  Top := arredt[1].top+5;
  Left := arredt[1].Left + arredt[1].width + 10;
  Visible := false;
end;

arrlbl[8] := TLabel.Create(nil);            //Label om se indien Epos-Adress gevat is of oop is
with arrlbl[8] do
begin
  name := 'lblemailcheck';
  parent := frm;
  Font.Size := 15;
  Font.name := LABELFONT;
  Top := arredt[2].top+5;
  Left := arredt[2].Left + arredt[2].width + 10;
  Visible := false;
end;

arrlbl[9] := TLabel.Create(nil);
with arrlbl[9] do
begin
  name := 'lblemailcheck';
  parent := frm;
  Font.Size := 15;
  Font.name := LABELFONT;
  Top := arredt[4].top+5;
  Left := arredt[4].Left + arredt[4].width + 10;
  Visible := false;

  Main.CheckAccountRegisterEdits(self);
end;

arrlbl[10] := tLabel.Create(nil);       //Label om as knoppie te dien vir om as n account in te sign
  with arrlbl[10] do
    begin
        parent := frm;
        name := 'lblregister';
        Caption := 'Login to existing account';
        Font.Size := 15;
        Font.name := LABELFONT;
        Font.Style := [fsUnderline];
        Font.Color := clsilver;
        Top := frm.Height - 75;
        Left := frm.Width DIV 2 + 130;
        Width := width + 10;
        OnMouseEnter := Main.LabelHrefColorChange;   //verander kleur
        OnMouseLeave := Main.LabelHrefColorChange;    //verander kleur
        OnClick := Main.SignInToAccount;      //verander skerm
    end;

end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.CheckAccountRegisterEdits;    //Kyk of inset van n edit valid is.
begin

arrlbl[7].Visible := false;
arrlbl[8].Visible := false;
arrlbl[9].Visible := false;
arrbitbtn[1].Enabled := true;

if (arredt[1].Text = '') OR (arredt[2].Text = '') OR (arredt[3].Text = '') OR (arredt[4].Text = '') then
   begin                                       //Kyk of al die edits ingevul is
      arrlbl[6].Caption := 'All fields need to be filled in';
      arrlbl[6].Font.Color := clred;
   end
else
   begin
      arrlbl[6].Caption := '';
      arrlbl[6].Font.Color := clLime;
   end;

arrlbl[6].Width := arrlbl[6].Width + 20;

if arredt[1].Text <> '' then
   begin
     arrlbl[7].Visible := true;
     if DB.SearchDB('tblusr','UserName',arredt[1].Text) = 0 then   //Kyk of naam oop is
        begin
          arrlbl[7].Caption := 'Username Available';
          arrlbl[7].Font.Color := clLime;   //Naam oop
        end
     else
        begin
          arrlbl[7].Caption := 'Username Taken';
          arrlbl[7].Font.Color := clred;    //Naam gevat
     end;
end;

if arredt[2].Text <> '' then
   begin
     arrlbl[8].Visible := true;
     if DB.SearchDB('tblusr','EmailAdress',arredt[2].Text) = 0 then   //kyk of Epos oop is
        begin
          arrlbl[8].Caption := 'Email-adress Available';  //Epos is oop
          arrlbl[8].Font.Color := clLime;
        end
     else
        begin
          arrlbl[8].Caption := 'Email-adress Taken';  //epos is gevat
          arrlbl[8].Font.Color := clred;
        end;
 end;

if (arredt[3].Text <> '') AND (arredt[4].Text <> '') then
 begin
   arrlbl[9].Visible := true;
   if arredt[3].Text <> arredt[4].text  then   //Kyk of wagwoorde dieselfde is
      begin
         arrlbl[9].Caption := 'Password does not match'; //wagwoorde is nie dieselfde nie
         arrlbl[9].Font.Color := clred;
      end
   else
      begin
         arrlbl[9].Caption := 'Password matches';    //wagwoorde is dieselfde
         arrlbl[9].Font.Color := clLime;
      end;
 end;
    //Indien enige van die labels se kleur ROOI is , moet die uitset nie submit kan word nie.
if (arrlbl[6].Font.Color = clred) OR (arrlbl[7].Font.Color = clred) OR (arrlbl[8].Font.Color = clred) OR (arrlbl[9].Font.Color = clred) then
    begin
      arrbitbtn[1].Enabled := false; //Stell submit konopie oop saodat die gebruiker kan aansit
    end;



end;
/////////////////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.PostNewAccount(Sender : TObject);
begin
DB.tblusr.Insert;
DB.tblusr['Username'] := arredt[1].text;     //Lees Edit se Strings in die Databasis in
DB.tblusr['EmailAdress'] := arredt[2].text;
DB.tblusr['Password'] := arredt[3].text;
if Messagedlg('Are you sure these credentials are correct ?',mtInformation ,[mbYes , mbNo],0) = mrYes then
begin                              //Gee Messagedlg om seker te maak dat al die data korrek is
if DB.SearchDB('tblcomputers','MotherboardSerial',sMotherBoardSerial) = 0 then
   begin
     DB.RunSQLQuery(DB.qry , ['INSERT INTO tblcomputers (MotherboardSerial)','VALUES ("'+sMotherboardSerial+'")']);
   end;                  //Lees die moederbord Serial nommer  in databasis in
DB.tblusr.Post;
DB.RunSQLQuery(DB.qry , ['INSERT INTO tblOwnedCourses (UserName,CourseID) VALUES ("'+arredt[1].text+'","Aller-Leer Kursusse Tutorial")']);
SignInToAccount(nil);                 //Gee nuwe account DIe "Aller-Leer Tutorial kursus" sodat hul kan begin leer
end
else
exit;

end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure Tmain.AutoSignInToAccount();  //AUtomaties laat die gebruiker in sign nadat hy Gestel he t dat die rekenaar onthou moet word
 begin
   DB.runSQLquery(DB.qry , ['SELECT Username,EmailAdress FROM tblusr WHERE ActiveComputer = '+'"'+SMotherboardSerial+'"']);
   DB.qry.Open;
   sUsername := DB.qry['Username'];    //kry gebruiker se naam
   sUserEmail := DB.qry['EmailAdress']; //kry gebruiker se epos adress
   Main.MainMenu(self);       //maak die hoof form oop
 end;
///////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.SignInToAccount(Sender : TObject);  //(3.2)  //Skep ggk sodat gebruiker kan in sign
const
LABELFONT = 'UniSpace';
EDITWIDTH = 600;
begin

FreeAndNilGuiComponents();    //maak ggk skoon sodat geeheur nie oorheers word nie

frm.Color :=  clBackground;       //stel form agter grond kleur
arrlbl[1] := TLabel.Create(nil);      //maak label om hoof opskrif te gee
 with arrlbl[1] do
   begin
     parent := frm;
     name := 'lblHeading';
     Caption := 'Login to your account';
     Font.Size := 35;
     Font.name := LABELFONT;
     Font.Style := [fsUnderline , fsBold];
     Top := 8;
     Left := trunc(frm.Width / 2) - trunc(Width /2);   //sit label na middel van skerm
   end;

arrlbl[2] := TLabel.Create(nil);  //label om vir Username te vra
 with arrlbl[2] do
   begin
     parent := frm;
     name := 'lblusername';
     Caption := 'Username : ';
     Font.Size := 20;
     Font.name := LABELFONT;
     Font.Style := [];
     Top := arrlbl[1].Top + 120;
     Left := trunc(frm.Width / 2) - trunc(Width /2);  //stel laberl na miderl van sekerm
   end;

     arredt[2] := TEdit.Create(nil);    //edit om inset vannnaf user te vat om die username te aanvaar
       with arredt[2] do
         begin
           name := 'edtname';
           parent := frm;
           TextHint := 'Username';
           Text := '';
           Font.Size := 18;
           Font.name := LABELFONT;
           Width := EDITWIDTH;
           Top := arrlbl[2].Top + arrlbl[2].Height + 10;
           Left := arrlbl[2].left  - (Width DIV 2) + (arrlbl[2].width DIV 2);
           OnChange := Main.retryEditResponse;    //verander edit kleur om te wys of dit valid is of nie
        end;

arrlbl[3] := TLabel.Create(nil);   //label om te vra vir die wagwoord
 with arrlbl[3] do
   begin
     parent := frm;
     name := 'lblpassword';
     Caption := 'Password : ';
     Font.Size := 20;
     Font.name := LABELFONT;
     Font.Style := [];
     Top := arredt[2].Top + 50;
     Left := trunc(frm.Width / 2) - trunc(Width /2);   //sit label na middel van skerm
   end;

     arredt[3] := TEdit.Create(nil);     //edit om wagwoord inset te4 asanvaar
       with arredt[3] do
         begin
           name := 'edtpassword';
           parent := frm;
           TextHint := 'Password';
           Text := '';
           Font.Size := 18;
           Font.name := LABELFONT;
           Width := EDITWIDTH;
           Top := arrlbl[3].Top + arrlbl[3].Height + 10;
           Left := arrlbl[3].left - (Width DIV 2) + (arrlbl[3].width DIV 2);
           PasswordChar := '*';  //verang elke karakterm met n "*"
           OnChange := Main.RetryEditResponse;   //verander kleur indien die wagwoord verkeerd ingetik is
        end;


             arrbitbtn[1] := TBitBtn.Create(nil);  //BitButton om inset te aanvaar
              with arrbitbtn[1] do
               begin
                 parent := frm;
                 name := 'bitbtnLogin';
                 Caption := 'Login';
                 Font.Size := 20;
                 Font.Name := LABELFONT;
                 Width := 160;
                 Height := 45;
                 Top := arredt[3].Top + arredt[3].Height + 60;
                 Left := arrlbl[3].Left + (width - arrlbl[3].width)-40;
                 OnClick := Main.SignIn; //Indien geklik word Sign die User in en kyk of korrek is
               end;

arrcheckbox[1] := TCheckBox.Create(nil);    //Checkbox om te aanvaar of die gebruiker onthou will word op die rekenaar
  with arrcheckbox[1] do
    begin
      parent := frm;
      Caption := 'Remember me on this computer ?';
      Font.Size := 15;
      Font.Name := LABELFONT;
      Color := clWhite;
      Width := 12 * length(Caption);
      Height := Height + 10;
      Top  := arredt[3].Top + arredt[3].Height + 30;
      Left := arrlbl[3].Left - (Width DIV 2) + (arrlbl[3].width DIV 2); //stel na middel van skerm
    end;



arrlbl[4] := TLabel.Create(nil); //label om te se dat die wagwoord of username invalid is
 with arrlbl[4] do
   begin
     parent := frm;
     name := 'lblinfo';
     Caption := 'Username or password invalid';
     Font.Size := 15;
     Font.name := LABELFONT;
     Font.Style := [fsitalic];
     Font.Color := clred;
     Top := arrlbl[1].Top + 60;
     Left := trunc(frm.Width / 2) - trunc(Width /2);
     Width := width + 10;
     Visible := false;
   end;

arrlbl[5] := tLabel.Create(nil);   //label om te dien as button om  gebruiker na"Create new account" form te neem
  with arrlbl[5] do
   begin
        parent := frm;
        name := 'lblgotoregister';
        Caption := 'Register new account';
        Font.Size := 15;
        Font.name := LABELFONT;
        Font.Style := [fsUnderline];
        Font.Color := clsilver;
        Top := frm.Height - 75;
        Left := 20;
        Width := width + 10;
        OnMouseEnter := Main.LabelHrefColorChange;   //Veranderk kleur indien muis in gaan
        OnMouseLeave := Main.LabelHrefColorChange;   //Vender kleur indienb muis uit gaan
        OnClick := Main.CreateAccount;   //maak die "Create Account" form oop
    end;

arrlbl[6] := tLabel.Create(nil);   //Label om te dien as Button om na "Forgot password" form te gaan
  with arrlbl[6] do
    begin
        parent := frm;
        name := 'lblpasswordreset';
        Caption := 'Forgot Password';
        Font.Size := 15;
        Font.name := LABELFONT;
        Font.Style := [fsUnderline];
        Font.Color := clsilver;
        Top := frm.Height - 75;
        Left := frm.Width DIV 2 + 250;
        Width := width + 10;
        OnMouseEnter := Main.LabelHrefColorChange;  //verander kleur indien muis oor beweeg
        OnMouseleave := Main.LabelHrefColorChange;  //verander kleur indiem muis uit beweeg
        OnClick := Main.ForgotPassword;//maak "Forgot password" form oop
    end;

end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.SignIn(Sender : TObject); //Sign in na n account
begin

   arrlbl[4].Visible := true;
   arredt[2].Color := clred;
   arredt[3].Color := clred;

 if DB.CompareLoginDetails(arredt[2].text , arredt[3].text , '') = true then //kyk of beide die wagwoord en Usernaam is dieselfde rekord in die databasis bestaan
  begin
    sUserName := arredt[2].Text;
    sUserEmail := DB.tblusr['EmailAdress']; //stel Susername na die rekord in die databasis

    if arrcheckbox[1].Checked then
    begin

     if DB.SearchDB('tblcomputers','MotherboardSerial',sMotherBoardSerial) = 0 then
      begin
        DB.RunSQLQuery(DB.qry , ['INSERT INTO tblcomputers (MotherboardSerial)','VALUES ("'+sMotherboardSerial+'")']);
      end;

     if DB.SearchDB('tblusr','ActiveComputer',sMotherBoardSerial) > 0 then
      begin   //Kyk of daar n akriewe rekenaar gestel is
       DB.tblusr.First;
       while not(DB.tblusr.eof) do
         begin
           if DB.tblusr['ActiveComputer'] = sMotherBoardSerial then
             begin    //kyk of activecomputer feld in databasis gelyk is aan "Motherboard Serial string"
               DB.tblusr.Edit;
               DB.tblusr['ActiveComputer'] := NULL;//Stel almal wie nie anthou moet word nie se rekenaar na 0 indien hul dieselfde moerderboard serial nommer het
             end;
           DB.tblusr.Next;
         end;

      end;     //Stel gebruiker se waardes en Aktiewe rekenaar
       DB.tblusr.Locate('Username',sUsername,[]);
       DB.tblusr.Edit;
       DB.tblusr['ActiveComputer'] := sMotherboardSerial;
       DB.tblusr.Post;

    end;

    Main.MainMenu(self);
   end;
end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.RestartProgram(cmdParam: string);  //restart die program maar met die parameter sodat dit automaties inlog
begin
   ShellExecute(0, nil, PChar(Application.ExeName), PWideChar(cmdParam), nil, SW_SHOWNORMAL);
   Application.Terminate; //hardloop Shelll-Script om program weer oop te maak
end;
////////////////////////////////////////////////////////////////////////////////
procedure TMain.RetryEditResponse(Sender : TObject);    //verander kleur van tedit indien weer op geklik word
begin
   arredt[2].Color := clwhite;
   arredt[3].Color := clwhite;
   arrlbl[4].Visible := false;
end;
//////////////////////////////////////////////////////////////////////////////////////
procedure TMain.LabelHrefColorChange(Sender : TObject);//verander kleaur van label
 begin
  if (Sender AS TLabel).Font.Color = clsilver then    //Indien silver maak Blou
   begin
   (Sender AS TLabel).Font.Color := clBlue;
   end
  else if (Sender AS TLabel).Font.Color = clBlue then //indien blou maak silver
   begin
   (Sender AS TLabel).Font.Color := clsilver;
   end;
 end;
///////////////////////////////////////////////////////////////////////////////////////
procedure TMain.ForgotPassword(Sender : TObject);  //(3.3) //maak vorm oop ingeval dat die gebruiker sy wagwoord vergeet
const
LABELFONT = 'UniSpace';
EDITWIDTH = 400;
begin
//Using components From SingintoAccount
FreeAndNil(arrcheckbox[1]);

with arrlbl[1] do   //verander label om as Opskrif te dien
 begin
    Caption := 'Reset Password';
    Left := trunc(frm.Width / 2) - trunc(Width /2);    //stel na midel van skerm
 end;

with arrlbl[2] do  //label om te vra vir die gebruiker se account naam
 begin
    Caption := 'Account User name :';
    Left := 50;
 end;
          with arredt[2] do //Editom inset te aanvaar vir die usernaam
           begin
            Text := '';
            TextHint := 'UserName';
            Left := arrlbl[2].Left;
            Width := EDITWIDTH;
           end;

with arrlbl[3] do  //label om te vra vir epos adress
 begin
    Caption := 'Email-Adress :';
    Left := 50;
 end;
          with arredt[3] do  //Eidt om epos adres te inset te neem
           begin
            Text := '';
            TextHint := 'Email-Adress';
            Left := arrlbl[3].Left;
            PasswordChar := #0;  //maak wagwoord letter onbekend sodat epos gesien kan word
            Width := EDITWIDTH;
           end;

with arrlbl[4] do //label om te wys dat Epos of useraam verkeerd is
 begin
    Caption := 'Email or Username invalid';
    Left := trunc(frm.Width / 2) - trunc(Width /2);
    width := width + 10;
 end;

                    with arrbitbtn[1] do//Button om te finaliseer en die funksire te run
                     begin
                        arrbitbtn[1].Caption := 'Reset';
                        Left := arredt[2].Left + (arredt[2].width DIV 4);
                        OnClick := Main.PasswordReset; //begin wagwoord reste proses
                     end;

with arrlbl[5] do  //label om as konoppie te dien vir om terug te gaan na login to account
 begin
    Caption := 'Login to existing account';
    OnClick := Main.SignInToAccount;   //maak login to account form oop
 end;

with arrlbl[6] do //label om basiese inligting te gee oor wagwoord reset proses
 begin
   WordWrap := true;
   Caption := 'When resetting your Password : a Email will be sent to you with a verification code';
   Font.Style := [];
   Font.Color := clBlack;
   Font.Size := 14;
   Left := arredt[2].Left + arredt[2].Width + 80;
   Height := 300;
   Top := arredt[2].Top;
   Width := 380;
   OnClick := nil;  //haal klik proses af sodat die nie geklik kan word nie
   OnMouseEnter := nil;//haal kleuer veranderings prosesse af sodat dit nie kleur verander nie
   OnMouseLeave := nil;//haal kleuer veranderings prosesse af sodat dit nie kleur verander nie
 end;

end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.PasswordReset(Sender : TObject);   //Reset pasword procedure
 begin
 if DB.CompareLoginDetails(arredt[2].text , '' , arredt[3].text) then   //vergelyk die login details om seker te maak dit is die regte gebruiker
    begin
      sUsername := DB.tblusr['UserName'];
      sUserEmail := DB.tblusr['EmailAdress'];
      FreeAndNil(arrlbl[3]);
      FreeAndNil(arredt[3]);

      with arrLbl[1] do    //Label om as hoof opskfrif te dien
        begin
          Font.Size := Font.Size - 1;
          Caption := 'Verification For Password Reset';
          Left := trunc(frm.Width / 2) - trunc(Width /2); //sit label na middel van skerm
        end;

      with arrlbl[2] do //Label om te wys waar om, kode in te sit
        begin
          Caption := 'Enter Code Here :';
          Left := trunc(frm.Width / 2) - trunc(Width /2); //sit na middel van skerm
        end;

              with arredt[2] do //Edit om Verifikasie kode te aanvaar
                begin
                  OnChange := nil;
                  Width := 150;
                  NumbersOnly := true; //kan selgs nommer aanvaar
                  Text := '';
                  TextHint := '';
                  Font.Size := 30;
                  Left := arrlbl[2].left - (Width DIV 2) + (arrlbl[2].width DIV 2); //stel na middel van skerm
                end;

                     with arrbitbtn[1] do//Knoppie om te submit en kode te verifieer
                        begin
                          Caption := 'Submit';
                          Left := arrlbl[2].left - (Width DIV 2) + (arrlbl[2].width DIV 2);
                          OnClick := VerifyAndReset;//verifieer en reset die kode om nuwe wagwoord te gee
                        end;

      with arrlbl[6] do//label om as konoppie te dien om nuwe epos met kode te stuur
        begin
          Caption := 'Resend verification code';
          Font.Color := clSilver;
          Font.Size := 14;
          Font.Style := [fsUnderline];
          Height := 24;
          Top := arredt[2].Top + arredt[2].Height + 10;
          Left := arredt[2].Left + (arredt[2].Width DIV 2) - (arrlbl[2].width DIV 2);
          OnMouseEnter := Main.LabelHrefColorChange; //verander kleur indien muis oor gaan
          OnMouseLeave := Main.LabelHrefColorChange; //verander kelur indien muis uit beweeg
          OnClick := Main.SendVerificationEmail;//stuur die verifikasie Epos weer met an ander kode
        end;

      SendVerificationEmail(self);//stuur die verifikasie Epos sodra GGK klaar gemaak is

    end
  else
    begin
      arredt[2].color := clred;  //verander kleure indien name of epos verkeerd
      arredt[3].Color := clred;
      arrlbl[4].Visible := true;  //maak die waarskuwings label sigbaar
    end;
 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure Tmain.SendVerificationEmail(Sender : TObject);     //stuur die verifikasie epos
 var
  sicount : shortint;

  begin
  sVerifyCode := '';
    for sicount := 1 to 6 do                              //Genereer 6 karakter verifikasie kode
     begin
       sVerifyCode := sVerifyCode + inttostr(RandomRange(0,10));//random getalle vir verifikasie kode
     end;  //hardloop ekserne Program "JHB-Email.exe" om epos te stuur aan gebruiker
     ShellExecute(0 , 'open' , 'JHB-Email.exe' , PChar(sUserEmail + ' ' + 'Password_Reset' + ' ' + sUserName + ' ' + sVerifyCode) , nil , SW_HIDE);
  end;
////////////////////////////////////////////////////////////////////////////////////////////
procedure Tmain.VerifyAndReset(Sender : TObject);   //verifieer kode en reset wagworod
const
EDITWIDTH = 400;
  begin
    if (arredt[2].Text = sVerifyCode) then //indien kode korrek begin reset proses
      begin
      freeandNil(arrlbl[6]); //maak lbl[6] se gehue skoon
         with arrlbl[1] do  //label om as hoof opskrif te dien
          begin
            arrlbl[1].Caption := 'Choose New Password';
            Left := trunc(frm.Width / 2) - trunc(Width /2); //stel na middel van skerm
          end;

         with arrlbl[2] do //maak label om te vra vir nuwe wagwoord
          begin
             Caption := 'New Password :';
             Left := 50;
          end;
                   with arredt[2] do  //edit om  wagwoord inset te aanvaar
                    begin
                     Text := '';
                     TextHint := 'New Password';
                     Font.Size := 18;
                     Top := arrlbl[2].Top + arrlbl[2].Height + 10;
                     Left := arrlbl[2].Left;
                     Width := EDITWIDTH;
                     Numbersonly := false;
                     PasswordChar := '*'; //stel wagwoord karakter
                     OnChange := RetryEditResponse;
                    end;

         arrlbl[3] := TLabel.Create(nil);//label om vir "confirm" van wagwoord dte vra
         with arrlbl[3] do
          begin
             parent := frm;
             name:= 'lblconfirmpassword';
             Font.Size := arrlbl[2].Font.Size;
             Font.Style := arrlbl[2].Font.Style;
             Font.Name := arrlbl[2].Font.Name;
             Height := arrlbl[2].Height;
             Top := arredt[2].Top + arredt[2].Height + 10;
             Caption := 'Confirm Password : ';
             Left := 50;
          end;
                   arredt[3] := TEdit.Create(nil);  //Edit om Confirm wagwoord se inset te aanvaar
                   with arredt[3] do
                    begin
                     parent := frm;
                     name := 'edtconfpassword';
                     Text := '';
                     TextHint := 'Confirm New Password';
                     Left := arrlbl[3].Left;
                     Top := arrlbl[3].Top + arrlbl[3].Height + 10;
                     Font := arredt[2].Font;
                     Width := EDITWIDTH;
                     PasswordChar := '*';//stel wagwoord displat karakter na "*"
                     OnChange := RetryEditResponse;//retry Edit response
                    end;

                              with arrbitbtn[1] do  //button om wagworod te aanvaar indien wagwoorde dieselfde is
                               begin
                                 Caption := 'Set New Password';
                                 Left := arrlbl[2].left - (Width DIV 2) + (arrlbl[2].width DIV 2);
                                 OnClick := Main.SetNewPassword; //stel nuwe wagwoord
                                 Width := width + 110;
                               end;

          with arrlbl[4] do //label om te waarsku indien wagwoorde nie dieselfde is nie
           begin
             arrlbl[4].Caption := 'Passwords does not match';
             width := width + 10;
             Left := arredt[3].Left + arredt[3].Width + 10;
             Top :=  arredt[3].Top;
           end;
      end
      else
       begin
         arredt[2].Color := clred;   //indien verkeer maak keuer rooi

       end;
  end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.SetNewPassword(Sender: TObject);//stel nuwe wagwoord
begin
  if (arredt[2].Text = arredt[3].Text) AND (arredt[2].Text <> '') AND (arredt[3].Text <> '') then //maak seker die edits is nie leeg nie
    begin
    if DB.CompareLoginDetails(sUSername , '' , SUserEmail) then //vergelyk login inligting
       begin
        DB.tblusr.Edit;//set databasis in edit mode
        DB.tblUsr['Password'] := arredt[3].Text; //stel databais wagwoord gelyk aan insegette wagwoord
        DB.tblusr.Post;//Post na datbasis om ingeskryf te word

        main.SignInToAccount(self); //maak sign in form om inte sign in program in
       end;
    end
  else
    begin
      arredt[2].Color := clred;  //Indien inligting verkeer maak edits rooi
      arredt[3].Color := clred;
      arrlbl[4].Visible := true;  //maak lbl[4] sigbaar
    end;
end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.MainMenu(Sender:Tobject);  //Maak program hoof form oop
const
 LABELFONT = 'UniSpace';
  begin
     FreeAndNilGUIComponents();//maak GGK komponente skoon
     frm.Color := $47454a;

     arrlbl[1] := TLabel.Create(nil); //maak label om as hoof opskrif te dien
      with arrlbl[1] do
        begin
          parent := frm;
          Caption := 'Aller-leer kursusse';
          Font.Size := 35;
          Font.Style := [fsbold , fsunderline];//stel die styles van die font
          Font.Name := LABELFONT;
          Top := 8;
          Left := trunc(frm.Width / 2) - trunc(Width /2);//sit na middel van skerm
        end;

      arrpanel[1] := TPanel.Create(nil); //maak paneel om inligting te hou
       with arrpanel[1] do
        begin
         parent := frm;
         parentColor := false;
         parentBackground := false;
         name := 'pnlinfo';
         Caption := '';
         Top := arrlbl[1].Top + arrlbl[1].Height + 5;
         Width := frm.Width;
         Height := 30;
         Left := 0;
         color := clNone;
         BevelKind := bkNone;//haal bevel af
         BevelInner := bvNone;    //haal innerlike bevel af
         BevelOuter := bvNone;    //haal uitelike bevel af
         BevelWidth := 1;
         BevelEdges := [beBottom];  //stel edges van bevel na onder
        end;

                arrlbl[2] := Tlabel.Create(nil);  //maak label om Aksies te verteenworrdig
                 with arrlbl[2] do
                  begin
                    parent := arrpanel[1];  //stel ouer na die paneel
                    Caption := 'Actions :';
                    Top := 3;
                    Left := 8;
                    Font.Size := 15;
                    Font.Color := clSilver;
                    Font.Style := [];
                    Font.Name := LABELFONT;
                  end;

                arrlbl[3] := Tlabel.Create(nil);  //maak label om te wys as wie ingesign is
                 with arrlbl[3] do
                  begin
                    parent := arrpanel[1];
                    Caption := 'Signed into : ' + sUsername; //sit naam van gebruiker by die teks
                    Top := 3;
                    Left := frm.Width - 280;
                    Font.Size := 15;
                    Font.Color := clSilver;
                    Font.Style := [fsUnderline];
                    Font.Name := LABELFONT;
                    OnMouseEnter := Main.SignOutLabelColorAndTextChange; //indien muis oor beweee gverander die kleur
                    OnMouseLeave := Main.SignOutLabelColorAndTextChange; //indien die muis uit beweer verander die kleur
                    OnClick := Main.SignOutofAccount;   //sign uit die account uit en reset die inligting gestel
                  end;

        arrjhbgraphctrl[1] := TJHBGraphicControl.Create(nil);//maak JHBGraphicControl om as konoppie te dien vir die Browse Courses Koppie
        with arrjhbgraphctrl[1] do
         begin
          Parent := frm;
          width := 200;
          Height := 67;
          Left := 5;
          Top := arrpanel[1].Top + arrpanel[1].Height + 5;
          Caption := 'Browse Courses';
          SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3); //stel grafika van die komponent
          SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter,tfWordBreak],13,intarrtopointarr([0,(height DIV 2)-9,width,height])); //stel die teks van die komponent
          OnMouseEnter := arrjhbgraphctrl[1].JhbbtnColorChange;//indien muis oor beweeg verander die kleur
          OnMouseLeave := arrjhbgraphctrl[1].JhbbtnColorChange;//indien muis uit beweeg vernader die kleur
          OnClick := BrowseCourses;  //indien geklik word hardloop die Browse courses procedure
         end;

       arrjhbgraphctrl[2] := TJHBGraphicControl.Create(nil);//maak JHBGrapghicControl vir Create new Course
        with arrjhbgraphctrl[2] do
         begin
          Parent := frm;
          width := 200;
          Height := 67;
          Left := arrjhbgraphctrl[1].Left + arrjhbgraphctrl[1].width + 5;
          Top := arrpanel[1].Top + arrpanel[1].Height + 5;
          Caption := 'Create New Course';
          SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);//Stel komopnet se grafika
          SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));  //Stel komponent se teks
          OnMouseEnter := arrjhbgraphctrl[2].JhbbtnColorChange;//vernader kluer indien die muis oor beweeg
          OnMouseLeave := arrjhbgraphctrl[2].JhbbtnColorChange;//verander kleur indien die muis Uit beweeg
          OnClick := Main.CreateNewCourse; //maak die nuwe kursus oop om geEdit te word
         end;



      arrpanel[2] := TPanel.Create(nil);  //maak 2de paneel om as kursus inligting te dien
       with arrpanel[2] do
        begin
         parent := frm;
         parentColor := false;
         parentBackground := false;
         name := 'pnlCoursesinfo';
         Caption := '';
         Top := arrjhbgraphctrl[2].Top + arrjhbgraphctrl[2].Height + 5; //sit onder JHBGraphicControls
         Width := frm.Width;
         Height := 30;
         Left := 0;
         color := clNone;
         BevelKind := bkNone;   //haal bevel af
         BevelInner := bvNone;  //haal inerlike bevel af
         BevelOuter := bvNone; //haal uitelike bevel af
         BevelWidth := 1;
         BevelEdges := [beBottom];  //stel bevel na onderkant van die paneel
        end;

                arrlbl[4] := TLAbel.Create(nil);//stel label om inligting te gee oot nuwe kursusse
                 with arrlbl[4] do
                  begin
                    parent := arrpanel[2];
                    Caption := 'Owned Courses :';
                    Top := 3 ;
                    Left := 8;
                    Font.Size := 15;
                    Font.Color := clSilver;
                    Font.Style := [];
                    Font.Name := LABELFONT;
                  end;

                   arrjhbgraphctrl[3] := TJHBGraphicControl.Create(nil);  //Maak JHBGraphicControl om as Search konppie op te tree
                      with arrjhbgraphctrl[3] do
                       begin
                        Parent := arrpanel[2];
                        Caption := 'Search';
                        width := length(Caption) * round(Font.Size * 1.4) + 10;
                        Height :=30;
                        Left :=  Parent.Width - Width - 30;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);  //stel grafika
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));//stel teks van komponent
                        OnMouseEnter := arrjhbgraphctrl[1].JhbbtnColorChange;//verander kelur indien muis oor beweeg
                        OnMouseLeave := arrjhbgraphctrl[1].JhbbtnColorChange; //verander kleur indien muis uit beweeg
                        OnClick := SetSelectFilter;  //tel die search filter
                       end;

                    arredt[1] := TEdit.Create(nil);//maak edit om Search teks te aanvaar
                      with arredt[1] do
                       begin
                         Parent := arrpanel[2];
                         Width := 300;
                         Height := 20;
                         Top := (parent.Height DIV 2) - (Height DIV 2)-3;
                         Left := arrjhbgraphctrl[3].left - (Width);
                         Font.Size := 11;
                         OnEnter := SetSelectFilter;//stel die search filter waarme kusrsusse georganisser word
                       end;

        arrscrlbox[1] := TScrollBox.Create(nil); //maak scrollbox wat die Kursusse hou
        with arrscrlbox[1] do
         begin
           parent := frm;
           Left := 4;
           Top := arrpanel[2].Top + arrpanel[2].Height + 5;
           Width := frm.Width - Left - 25;
           Height := frm.Height - arrScrlbox[1].Top - 70;
         end;

     sBrowseFilter := '';
     DisplayCompiledCourses(false);  //vetroon die kursusse in tblOwned Courses

                arrlbl[5] := tLabel.Create(nil);
                with arrlbl[5] do
                 begin
                    parent := arrpanel[2];
                    Caption := inttostr(length(arrBrowseableCourses));//Gee lengte van die Browseable Course Array
                    Top := 3 ;
                    Left := arrlbl[4].Left + arrlbl[4].Width + 5;
                    Font.Size := 15;
                    Font.Color := clSilver;
                    Font.Style := [];
                    Font.Name := LABELFONT;
                 end;

                 arrlbl[6] := TLabel.Create(nil);
                 with arrlbl[6] do
                  begin
                    parent := frm;
                    Caption := 'Donate to Project';
                    Top := arrlbl[1].top + (arrlbl[1].height DIV 2);
                    Left := arrlbl[1].Left + arrlbl[1].width + 25;
                    Font.Size := 13;
                    Font.Color := clSilver;
                    Font.Style := [fsUnderline];
                    Font.Name := LABELFONT;
                    OnMouseEnter := Main.LabelHrefColorChange; //indien muis oor beweee gverander die kleur
                    OnMouseLeave := Main.LabelHrefColorChange; //indien die muis uit beweer verander die kleur
                    OnClick := Main.DonateToPlatform;   //sign uit die account uit en reset die inligting gestel
                  end;

  end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.SignOutLabelColorAndTextChange(Sender:Tobject); //verander kleuren teks van signout form

 begin
   if (Sender AS TLabel).Font.Color = clSilver then//indien sliver
     begin
      (Sender AS TLabel).Caption := 'Sign out of : ' + sUsername; //verander caption
     end
   else if (Sender AS TLabel).Font.Color = clBlue then   //indien blou verander caption
     begin
       (Sender AS TLabel).Caption := 'Signed into : ' + sUsername;
     end;
    Main.LabelHrefColorChange(Sender);  //verander kluer (selfde kriteria as bo)
 end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.SignOutofAccount(Sender:Tobject);   //Sign uit die account uit
 begin
   DB.tblusr.Locate('Username',sUsername,[]); //kry die gebruiker by sy naam
   DB.tblusr.edit;
   DB.tblusr['ActiveComputer'] := '';  //stel die aktiewe rekaanaar na NULL
   DB.tblusr.post;
   sUsername := '';
   sUserEmail := '';

   //showmessage(VarToStr(DB.tblusr['ActiveComputer']));
   RestartProgram('Signout');  //Restart die program met die 'signout parameter
 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.CreateNewCourse(Sender : TObject);//maak nuwe kursus
const
LABELFONT = 'UniSpace';
var
newCourse : TCourse; //veranderlike vir nuwe kursus
 begin
   FreeAndNilGUIComponents(); //maak GGk komponente skoon
       // frm.Color := $8a6555;
        NewCourse := TCourse.Create();//maak nuwe kursus objek

     arrlbl[1] := TLabel.Create(nil);    //maak label om as hoofopskrif te dien
      with arrlbl[1] do
        begin
          parent := frm;
          Caption := 'Create New Course !';
          Font.Size := 35;
          Font.Style := [fsbold , fsunderline];
          Font.Name := LABELFONT;
          Top := 8;
          Left := trunc(frm.Width / 2) - trunc(Width /2);  //stel na middel van skerm
        end;

      arrpanel[1] := TPanel.Create(nil); //maak paneel om inlgting op te vertoorn as ook knoppies
       with arrpanel[1] do
        begin
         parent := frm;
         parentColor := false;
         parentBackground := false;
         name := 'pnlinfo';
         Caption := '';
         Top := arrlbl[1].Top + arrlbl[1].Height + 5;
         Width := frm.Width;
         Height := 50;
         Left := 0;
         color := clNone;
         BevelKind := bkNone;   //haal bevel af
         BevelInner := bvNone;  //haal inerlike bevel af
         BevelOuter := bvNone;  //haal uiterlike bevel af
         BevelWidth := 1;
         BevelEdges := [beBottom];  //stel bevel na onderkant van die komponent
        end;

                   arrjhbgraphctrl[1] := TJHBGraphicControl.Create(nil); //maak JHBGrapicControl om mainmenu te verteenwoordig
                      with arrjhbgraphctrl[1] do
                       begin
                        Parent := arrpanel[1];
                        Caption := 'Back to MainMenu';
                        width := length(Caption) * round(Font.Size * 1.4);
                        Height :=30;
                        Left :=  5;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
                        OnMouseEnter := arrjhbgraphctrl[1].JhbbtnColorChange;//indien muis oor beweeg verander kelur
                        OnMouseLeave := arrjhbgraphctrl[1].JhbbtnColorChange;//indien muis uit beweeg verande kelur
                        OnClick := Main.MainMenu; //maak main menu form oop
                       end;

                   arrjhbgraphctrl[2] := TJHBGraphicControl.Create(nil);  //maak JHBGrapicControl om Translate Course To HTML te verteenwoordig
                      with arrjhbgraphctrl[2] do
                       begin
                        Parent := arrpanel[1];
                        Caption := 'Save Course';
                        width := length(Caption) * round(Font.Size * 1.45);
                        Height := 30;
                        Left :=  arrjhbgraphctrl[1].Left + arrjhbgraphctrl[1].Width + 5;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
                        OnMouseEnter := arrjhbgraphctrl[2].JhbbtnColorChange;//verander kleur indien muis oor beweeg
                        OnMouseLeave := arrjhbgraphctrl[2].JhbbtnColorChange;//verander kleur indien muis uit beweeg
                        OnClick := NewCourse.TranslateCourseContentTOHTML;//Transleer die kursus na n HTMl leer wat gelees kan word
                       end;

                    arrjhbgraphctrl[3] := TJHBGraphicControl.Create(nil);//maak JHBGrapicControl om LoadCourseFromHTML te verteenwoordig
                      with arrjhbgraphctrl[3] do
                       begin
                        Parent := arrpanel[1];
                        Caption := 'Load Course';
                        width := length(Caption) * round(Font.Size * 1.45);
                        Height := 30;
                        Left :=  arrjhbgraphctrl[2].Left + arrjhbgraphctrl[2].Width + 5;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
                        OnMouseEnter := arrjhbgraphctrl[3].JhbbtnColorChange; //verander kleur indien muis oor beweeg
                        OnMouseLeave := arrjhbgraphctrl[3].JhbbtnColorChange;//verander kleur indien muis Uit beweeg
                        OnClick := NewCourse.LoadCourseFromHTML;//indien geklik word maak file dialog oop en kies kursus om te laai
                       end;

                    arrjhbgraphctrl[4] := TJHBGraphicControl.Create(nil); //maak JHBGrapicControl om Save and view te verteenwoordig
                      with arrjhbgraphctrl[4] do
                       begin
                        Parent := arrpanel[1];
                        Caption := 'View Course in WebBrowser';
                        width := length(Caption) * round(Font.Size * 1.4);
                        Height := 30;
                        Left :=  arrjhbgraphctrl[3].Left + arrjhbgraphctrl[3].Width + 5;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
                        OnMouseEnter := arrjhbgraphctrl[4].JhbbtnColorChange; //verander kluer van die komponent indien muis oor beweeg
                        OnMouseLeave := arrjhbgraphctrl[4].JhbbtnColorChange; //verander kluer van die komponent indien muis uit beweeg
                        OnClick := NewCourse.SaveAndViewCourse; //save die kursus (Translate to HTML) en view dit in die webbrowser
                       end;

                    arrjhbgraphctrl[5] := TJHBGraphicControl.Create(nil);//maak JHBGraphicControl om Publish Course te verteenwoordig
                      with arrjhbgraphctrl[5] do
                       begin
                        Parent := arrpanel[1];
                        Caption := 'Publish Course';
                        width := length(Caption) * round(Font.Size * 1.4);
                        Height := 30;
                        Left :=  arrjhbgraphctrl[4].Left + arrjhbgraphctrl[4].Width + 5;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
                        OnMouseEnter := arrjhbgraphctrl[5].JhbbtnColorChange;//veradner kleur van komponent indie muis oor beweeg
                        OnMouseLeave := arrjhbgraphctrl[5].JhbbtnColorChange;//veradner kleur van komponent indie muis Uit beweeg
                        OnMouseUp := NewCourse.PublishbtnMouseUpInteract; //maak die hardloop die PublishCourse Muis check
                       end;

        arrscrlbox[1] := TScrollBox.Create(nil);//maak scrollbox om course Elements te hou
         with arrscrlbox[1] do
          begin
           parent := frm;
           Color := $8fa364;  //stel kleur
           name := 'scrlboxItems';
           Top := arrpanel[1].Top + arrpanel[1].Height + 5;
           Left := 5;
           Height := frm.Height - top - 50;
           Width := 200;
          end;
                arrlbl[2] := TLabel.Create(nil);//label om Courese Element menu te titel
                 with arrlbl[2] do
                  begin
                   parent := arrscrlbox[1];
                   Caption := 'Course Elements :';
                   Font.Size := 16;
                   Font.Style := [fsUnderline , fsBold];//stel die font styles
                   Top := 0;
                   Left := 2;
                 end;

        arrscrlbox[2] := TScrollBox.Create(nil); //maak scroll box om die "Propeties" menu te hou
         with arrscrlbox[2] do
          begin
            parent := frm;
            Color := $8fa364;
            name := 'scrlboxProperties';
            Top := arrpanel[1].Top + arrpanel[1].Height + 5;
            Height := frm.Height - top - 50;
            Width := 200;
            Left := frm.Width - arrscrlbox[2].Width - 20;//sit na middel van die menu
          end;
                arrlbl[3] := TLabel.Create(nil); //label om die Propeties menu n titel te gee
                 with arrlbl[3] do
                  begin
                   parent := arrscrlbox[2];
                   Caption := 'Properties Menu :';
                   Font.Size := 14;
                   Font.Style := [fsUnderline , fsBold];
                   Top := 0;
                   Left := 2;
                 end;

        arrscrlbox[3] := TScrollBox.Create(nil); //scrollbox om die kursus elemente te hou wat gekompeleer word teen die einde van die dag
         with arrscrlbox[3] do
          begin
            parent := frm;
            Color := clwhite;
            name := 'scrlboxCourse';
            Top := arrpanel[1].Top + arrpanel[1].Height + 5;
            Left := arrscrlbox[1].Left + arrscrlbox[1].Width +5;
            Height := frm.Height - top - 50;
            Width := arrscrlbox[2].Left - left - 5;
            OnClick := newCourse.OpenCourseProperties; //maak die kursus properties oop van die hoof blad van die kursus
          end;

        NewCourse.populateElementList(arrscrlbox[1]);//populeer die "Course Element" Menu met al die elemente

 end;
//////////////////////////////////////////////////////////////////////////////////////////
function TMain.JHBInputQuery(sTitle , sCaption , sDescription :string ;  var sResult : string) : boolean;
var  //inset query wat teksleers kan lees sowel as inligting neem vanaf n TRIchEdit
 Frm : TForm;
 tf : TextFile;
 FilePath , sLine : string;
 btnOK , btnCancel , btnTextFile : TButton;
 lblCaption , lbldescription : TLabel;
 redIN : TRichEdit;
 begin
   frm := TFOrm.Create(nil);  //maak form om JHBInputQuery te hou
   frm.Caption := sTitle;//stel title na die form se kapsie toe
   frm.Width := 400;
   frm.Height := 400;
   frm.Position := poScreenCenter ;

   lblCaption := TLabel.Create(nil);  //label om title van die JHBInputQuery te hou
    with lblCaption do
     begin
       parent := frm;
       Caption := sCaption;
       Top := 8 ;
       LEft := 8;
       Font.Size := 15;
       WordWrap := true;
       width :=  parent.Width - (LEft*4);
       if (length(Caption) * 15) > width then
        Height := Height + Font.Size*( (length(Caption) * 15)DIV width ); //pas hoogte aan met die lengte van die Caption
     end;

     lbldescription := TLabel.Create(nil);//maak lbldescription om n beskrywing te bied aan die JHBInputQuery
     with lbldescription do
      begin
        parent := frm;
        Caption := sDescription; //tel kapsie van lbldescription na die Sdescription parameter
        Left := 8;
        Top := lblCaption.Top + lblCaption.Height;
      end;

     btnTextFile := TButton.Create(nil);//maak button om as inset vir die "lees teksleer" opsie te dien
      with btnTextFile do
       begin
         parent := frm;
         Caption := 'Read from TextFile';
         Top := lbldescription.Top + lbldescription.Height + 10;
         LEft := 8;
         Width := 110;
         ModalResult := 80; //stel modale russeltaat van die knoppie
       end;

     redIN := tRichEdit.Create(nil);//maak richedit om inset van die gebruiker af te neem
      with redIN do
       begin
         parent := frm;
         left := 8;
         Top := btnTextFile.Top + btnTextFile.Height +  10;
         Width := parent.Width - (left*4);
         Height := Parent.Height - Top - 75;
         RedIN.Text := sResult;//stel die teks gelyk aan die rusetaal van die vorige opening
       end;

     btnCancel := TButton.Create(nil); //button cancel , maak die form toe sonder om inset terug te stuur
      with btnCancel do
       begin
         parent := frm;
         Caption := 'Cancel';
         Top := redIN.Top + redIn.Height + 10;
         Left := Parent.Width - (width*4);
         ModalResult := mrCancel;//stel modale russeltaat na 2
       end;

     btnOK := TButton.Create(nil); //maak button ok , wat die inset na waar stel en terug stuur
      with btnOK do
       begin
         parent := frm;
         Caption := 'OK';
         Top := redIN.Top + redIn.Height + 10;
         Left := btnCancel.Left + btnCancel.Width + 10;
         ModalResult := mrOK;  //stel modale russeltaat na  1
       end;

 case frm.ShowModal of    //toets gevalle van modale russeltate
  mrCancel : result := false;  //indien 2 , dan maak rusltaat vals en maak toe sonder om terug te stuur
  mrOK : begin  //indien 1  dan maak ruseltaat True en stuur waarde terug
           result := true;
           sResult := RedIN.Text;
         end;
  80 : begin    //indien 80 maak teksleer seleksie oop
       FilePath := FileSelectDialog('Select Input TextFile','Text Files|*.txt');
       sResult := RedIN.Text;
       if FilePath <> '' then
         begin

           AssignFile(tf , Filepath);
           Reset(tf);
           while NOT eof(tf) do
            begin
             readln(tf,sLine);              //sit elke lyn wat geleer word in sy eie lyntjie
             sResult := SResult + #13 + sLine;
            end;
           CloseFile(tf); //maak die teksleer toe
         end;

       JHBInputQuery(sTitle , sCaption , sDescription , sResult); //maak weer JHBInputQuery oop na dat teksleer gekies is
       end;
 end;
 Result := false; //onder enige ander omstandighere maak toe en stuur niks terug nie
 end;
//////////////////////////////////////////////////////////////////////////////////////////
function TMain.FileSelectDialog(Title , filter : string) : string;//kies leer duer middel van n Open Dialog Box
var
  opendialog: topendialog;
begin
  opendialog := topendialog.create(nil); //maak die TOpen Dialog voorwerp
  opendialog.Title := Title;
  opendialog.Filter := Filter;
  opendialog.InitialDir := GetCurrentDir;
  opendialog.Options := [ofFileMustExist];
  if opendialog.Execute then
    Result := opendialog.FileName;    //stel russeltaat van funksie gelyk aan die opendialog mse geslekteedre leer pad
  opendialog.Free;   //maak geheue wat open dialog hou skoon
end;
////////////////////////////////////////////////////////////////////////////////////////////
function TMain.InttoHTMLHex(value : TColor) : string;  //vernader n integer na HTML heksadesimaal wat kleure verteenwoordig
var
iR , iG , iB : byte;
begin
  iR := GetRvalue(value);
  iG := GetGvalue(value);  //kry individuere kleure se waardes
  iB := GetBValue(value);
  Result :='#' + inttoHex(iR,2) + inttohex(iG,2) + inttohex(iB,2); //maak eind russeltaat
end;
/////////////////////////////////////////////////////////////////////////////////////////////
function TMain.HTMLHEXtoint(svalue : string) : integer;  //vernader HTML heksadesimaal na integer getal
var iR , iG , iB : byte;
    ColValue : TColor;
begin
  ColValue:= strtoint('$00'+Copy(sValue,2,length(sValue)));
  iR := GetRvalue(ColValue);
  iG := GetGvalue(ColValue);  //kry individule keure se waardes
  iB := GetBValue(ColValue);
 // Result := strtoint('$00' + inttohex(iB,2) + inttohex(iG,2) + inttohex(iR,2));
  Result := strtoint('$00' + inttohex(iR,2) + inttohex(iG,2) + inttohex(iB,2));
end;
//////////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.TempPopupDlg(sText : string ; rshowtime : Real); //tydelike form wat op-pop en inlgting gee
var
 TempLbl : TLabel;
 Timer : TTimer;
begin
   Tempfrm := TForm.Create(nil);    //maak form oop om te display
   Tempfrm.Position := poScreenCenter;

   Templbl := TLabel.Create(nil);//maak lebel om inligting te vertoon
   Templbl.Parent := Tempfrm;
   Templbl.font.Size := 15;    //stel kapsie na sText parameter
   Templbl.Caption := sText;
   Templbl.Left :=  20;
   Templbl.Top := 20;

   Tempfrm.Width := TempLbl.Width+TempLBL.Left+50; //pas wydte van form aan gebaseer op grote van label
   Tempfrm.Height := TempLbl.Height+Templbl.Top+50; //pas hoogte aan van form gebaseer op grote van label

   Timer := TTimer.Create(nil);   //maak timer om n wag (pause) te beheer
   Timer.Interval := round(rshowtime*1000);//verander millisekondes tyd na sekondes
   Timer.OnTimer := Main.CloseTempFrm;  //maak temp form toe nadat timer verby getik het

   Tempfrm.ShowModal  //vetroon die Tempfrm modaal sodat net dit na gekyk word
end;
////////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.CloseTempFrm(Sender : TObject); //Wanner timer tik !
 begin
   Tempfrm.Close;  //maak Tempfrm Toe
 end;
////////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.BrowseCourses(Sender: TObject); //Maak GGK om kursusse mee te "Browse" na te kyk en te soek
const
LABELFONT = 'Unispace';
 begin
     FreeAndnilGUIComponents();//maak GGK komponente skoon

arrlbl[1] := TLabel.Create(nil); //stel label om as hoof opskrif te dien
      with arrlbl[1] do
        begin
          parent := frm;
          Caption := 'Browse Courses';
          Font.Size := 35;
          Font.Style := [fsbold , fsunderline]; //stel styles van teks
          Font.Name := LABELFONT;
          Top := 8;
          Left := trunc(frm.Width / 2) - trunc(Width /2);
        end;

      arrpanel[1] := TPanel.Create(nil); //maak paneel om die inligting en search funkise te hou
       with arrpanel[1] do
        begin
         parent := frm;
         parentColor := false;
         parentBackground := false;
         name := 'pnlinfo';
         Caption := '';
         Top := arrlbl[1].Top + arrlbl[1].Height + 5;
         Width := frm.Width;
         Height := 50;
         Left := 0;
         color := clNone;
         BevelKind := bkNone; //haal bevel af
         BevelInner := bvNone;  //haal innerlike bevel af
         BevelOuter := bvNone;   //haal uiterlike bevel af
         BevelWidth := 1;
         BevelEdges := [beBottom]; //stel bevel na onderkant van komponent
        end;

                   arrjhbgraphctrl[1] := TJHBGraphicControl.Create(nil);//Maak JHBGraphic Control om gebruiker terug na main menu te neem
                      with arrjhbgraphctrl[1] do
                       begin
                        Parent := arrpanel[1];
                        Caption := 'Back to MainMenu';
                        width := length(Caption) * round(Font.Size * 1.4);
                        Height :=30;
                        Left :=  5;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
                        OnMouseEnter := arrjhbgraphctrl[1].JhbbtnColorChange; //indien muis in beweeg verander kleur
                        OnMouseLeave := arrjhbgraphctrl[1].JhbbtnColorChange; //indien muis uit beweeg verander kelur
                        OnClick := Main.MainMenu; //indien geklik word  maak Main menu form oop en Browse Course Form toe
                       end;


                   arrjhbgraphctrl[2] := TJHBGraphicControl.Create(nil);//JHBGrapicControl om die Course Browser te clean en refresh sodat opgedateer word
                      with arrjhbgraphctrl[2] do
                       begin
                        Parent := arrpanel[1];
                        Caption := 'Refresh';
                        width := length(Caption) * round(Font.Size * 1.4);
                        Height :=30;
                        Left :=  arrjhbgraphctrl[1].Left + arrjhbgraphctrl[1].Width + 5;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
                        OnMouseEnter := arrjhbgraphctrl[1].JhbbtnColorChange;//verander kleur indien muis oor beweeg
                        OnMouseLeave := arrjhbgraphctrl[1].JhbbtnColorChange;//verander kleur indien muis uit beweeg
                        OnClick := Main.SetBrowseFilter; //stel filter na "NULL" herlaai net kurus elemente
                       end;

                   arrjhbgraphctrl[3] := TJHBGraphicControl.Create(nil);//JHBGrapicCOntrol om search funksie te aktiveer
                      with arrjhbgraphctrl[3] do
                       begin
                        Parent := arrpanel[1];
                        Caption := 'Search';
                        width := length(Caption) * round(Font.Size * 1.4) + 10;
                        Height :=30;
                        Left :=  Parent.Width - Width - 30;
                        Top := (parent.Height DIV 2) - (Height DIV 2);
                        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,clskyblue,bsSolid,clblack,3);
                        SetText(LABELFONT,clBlack,[fsBold],[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
                        OnMouseEnter := arrjhbgraphctrl[1].JhbbtnColorChange;//verander kleur indien muis oor beweeg
                        OnMouseLeave := arrjhbgraphctrl[1].JhbbtnColorChange;//verander kleur indien muis uit beweeg
                        OnClick := Main.SetBrowseFilter;//Stel filter gelyk aan "Edit[1].text"
                       end;

                     arredt[1] := TEdit.Create(nil);//maak edit om die browse filter te kry
                      with arredt[1] do
                       begin
                         Parent := arrpanel[1];
                         Width := 300;
                         Height := 30;
                         Top := (parent.Height DIV 2) - (Height DIV 2)-1;
                         Left := arrjhbgraphctrl[3].left - (Width);
                         Font.Size := 15;
                         OnEnter := SetBrowseFilter;//stel die filter gelyk aan "Edit[1].text"
                       end;




       arrscrlbox[1] := TScrollBox.Create(nil); //maak scrollbox om die Compiled Courses te hou
        with arrscrlbox[1] do
         begin
           parent := frm;
           Left := 4;
            Top := arrpanel[1].top + arrpanel[1].Height + 5;
            Width := frm.Width - Left - 25;
            Height := frm.Height - top - 60;
         end;


       arrlbl[2] := TLabel.Create(nil); //maak label om die hoeveelheid kursusse wat gedisplay word te hou
        with arrlbl[2] do
         begin
           parent := frm;
           Left := frm.Width DIV 2 - (width DIV 2);
           Top := arrscrlbox[1].Top + arrscrlbox[1].Height;
           Caption := '0';  //maak 0
           Font.Size := 13;
           Font.Style := [fsBold];
         end;

        sBrowseFilter := '';          //stel die browse filter na '' (lee string)
        DisplayCompiledCourses(true); //vetroon die gekompileerde kursusse in die scrollbox

 end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.SetBrowseFilter(Sender : Tobject);  //stel die filter om die aantal kursusse wat vertoon te sorteer
 begin
       sBrowseFilter := arredt[1].Text;
       DisplayCompiledCourses(true); //vertoon kursusse in "Browse Courses"
 end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.SetSelectFilter(Sender : Tobject);//stel filter om aantal kursusse wat vertoon word in "Onwed Course" te verbeter
 begin
       sBrowseFilter := arredt[1].Text;
       DisplayCompiledCourses(false); //vertoon kursuse in "Owned Courses"
 end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.DisplayCompiledCourses(bBrowsing : Boolean); //vertoon die gekompileerde kursusse
const
 LABELFONT = 'Unispace';
var
 icount : integer;
 imgStrm : TStream;//stroom in linligting van n BLOB of te stream na die program toe
 jpgimg : TJpegImage;   //prent van kursus
 bownedCourse : boolean;
 qryCourses : TADOquery;
 sCourseIDColumbname: string;
 sQuery : string;
begin
        qryCourses := TADOquery.Create(nil);
        qryCourses.Connection := DB.Con;


        if bBrowsing = true then  //Indien daar gebrowse word , kyk in tblCourse
          begin
          sCourseIDColumbname := 'CourseID';
          sQuery := 'SELECT * FROM tblCourse ORDER BY CourseRating DESC';
          end
        else
          begin          //Indien daar Nie gebrowse word , kyk in tblOnwedCourse waar Die Username = sUsername
            sCourseIDColumbname := 'tblCourse.CourseID';
            sQuery := 'SELECT * FROM tblCourse , tblOwnedCourses WHERE tblOwnedCourses.CourseID = tblCourse.CourseID AND tblOwnedCourses.UserName = "'+Main.sUsername+'"';
          end;

          qryCourses.Filtered := false;
         if sBrowseFilter <> '' then  //kyk of daar n browse filter is
          begin
            qryCourses.Filter := sCourseIDColumbname + ' LIKE ' + QuotedStr(sBrowseFilter+'*'); //LIKE search duer die Filter die Tabel
            qryCourses.Filtered := true;  //stel filtered na TRUE
          end;

          //DB.DisplayData(qryCourses);
        DB.RunSQLQuery(qryCourses , [sQuery]);//hardloop die SQL query
        qryCourses.Open;
        qryCourses.Active := true; //stel die Query na Active
        qryCourses.First;    //gaan na eerste rekord in die tabel

        for icount := low(arrBrowseableCourses) to high(arrBrowseableCourses) do//loop dure Browsable Courses
        if assigned(arrBrowseableCourses[icount]) then                       //Free elke element in Browseable Courses
             Freeandnil(arrBrowseableCourses[icount]);                       //indien die element assigned is en n waarde het

        Setlength(arrBrowseableCourses,qryCourses.RecordCount); //stel lengte gelyk aan aantal rekords
        icount := low(arrBrowseableCourses);

        imgstrm := TMemoryStream.Create();//maak n Memory stream om inligting te stroom
        jpgimg := TJpegImage.Create();  //maak Jpeg Image om kursus prent te hou

       try  //kyk vir errors
       while NOT(qryCourses.eof) do
         begin
            //maak die stream oop om n Blob field te lees
           TBlobField(qryCourses.FieldByName('CourseImage')).SaveToStream(imgstrm);
           imgstrm.Position := 0; //stel stream posisie na eers byte
           jpgimg.LoadFromStream(imgstrm);//laai die prent van die stroom
           imgstrm.Size := 0;//stel die size na  0 om die stream te reset

            arrBrowseableCourses[icount] := TCompiledCourse.Create(nil);//maak nuwe kurus
             with arrBrowseableCourses[icount] do
              begin
               Parent := Main.arrscrlbox[1]; //stel ouer van Gekompeleerde krsus

               Caption := qryCourses[sCourseIDColumbname] + #13 + 'By : ' + qryCourses['CreatorName'] + #13 + 'Score : ' + floattostr(qryCourses['CourseRating']);
               sCourseID := qryCourses[sCourseIDColumbname];//stel properties van die TCompiles Course
               Width := (Parent.Width DIV 2) - (Left*3)-20;
               Height := 150;
               Left := 4;
               Top := 4;
                if icount > 0 then
                  begin
                     Left := arrBrowseableCourses[icount-1].Left + arrBrowseableCourses[icount-1].width + 5;
                     Top := arrBrowseableCourses[icount-1].Top;//Stel Posiesie van die gekompeleerde kursus
                     if Left + width > Parent.Width then     //Check if new width is larger that window
                      begin
                        Left := 4;
                        Top := arrBrowseableCourses[icount-1].Top + arrBrowseableCourses[icount-1].Height + 5;
                      end;
                  end; //set Compiled Course Graphic and text
               SetGraphic(intarrtoPointarr([0,0,width,height,20,20]),gsRoundRect,$3E3937,bsSolid,$656678,0);
               SetText(LABELFONT,clBlack,[fsBold],[tfWordBreak],13,intarrtopointarr([160,10,width-10,height-10]));


              bOwnedCourse := false;
               if bBrowsing = true then //check if Browsing
                begin
                 DB.RunSQLQuery(DB.qry , ['SELECT CourseID, UserName FROM tblOwnedCourses WHERE CourseID="'+qryCourses[sCourseIDColumbname]+'" AND UserName="'+Main.sUserName+'"']);
                 DB.qry.Open;//run Query to get all COurses

                 if DB.qry.RecordCount > 0 then
                  bOwnedCourse := true
                end
               else //if Owned , then set interact with right click
                begin
                  onMouseUp := MouseUpInteract;
                end;
              SetupGUI(jpgimg, bOwnedCourse , bBrowsing);//stel GGK van die compiled Course

              end;//With end

           INC(icount);     //Vermeerder Icount en gaan aan na die volgende gekompeleerde kursus
           qryCourses.Next;
         end;
       finally  //Finally , doen altyd die volgende !!!
         //Showmessage('icount= '+inttostr(icount) + '/' + 'high= ' +inttostr(High(BrowseableCourses)));
         FreeAndnil(qryCourses);//maak qry geheu skoon
         FreeAndnil(Jpgimg);   //maak prent skoon
         FreeAndnil(imgstrm); //maak Memeory stream skoon
         DB.qry.Sql.Clear;     //clean die SQL property
         DB.qry.Close;
       end;
      if assigned(arrlbl[5]) then      //indien LBL[5] asigned is ::
      arrlbl[5].Caption := inttostr(length(arrBrowseableCourses));
       if(bBrowsing = true) then
        begin                       //tel aantal rekkord in die kursus teb on te sien hoeveel display word
         DB.RunSQLQuery(DB.qry , ['SELECT COUNT(*) AS fieldcount FROM tblCourse']);
         DB.qry.open;
         arrlbl[2].Caption := inttostr(icount) + ' / ' + inttostr(DB.qry['fieldcount']);
        end;
end;
//////////////////////////////////////////////////////////////////////////////////////
procedure Tmain.DonateToPlatform(Sender : TObject);
 var
  frmDonate : TForm;
  lblCaption : TLabel;
  //lblBank : TLabel;
  lblPrivacy : TLabel;
  //edtBank : TEdit;
  lblPay : TLabel;
  edtPay : TEdit;
  lblDist : TLabel;
  //RedtDist : TRichEdit;
 begin

  frmDonate := TForm.Create(nil);       //Create donations form
   with frmDonate do
    begin
      Caption := 'Donate To Project';
      Position := poScreenCenter;
      Width := 640;
      Height := 480;
      Color := clGreen;
    end;

   lblCaption := TLabel.Create(nil);       //Create donations form caption label
   with lblCaption do
    begin
     Parent := frmDonate;
     name := 'lblCaption';
     Font.Size := 20;
     Caption := 'Donate to the Project';
     Top := 3;
     Left := (frmDonate.Width DIV 2) - (Width DIV 2);
     Font.Style := [fsUnderline];
     Font.Name := 'Unispace';
    end;

    lblPrivacy := TLabel.Create(nil);               //Create Label om privacy inligting te gee
    with lblPrivacy do
     begin
       parent := frmDonate;
       name := 'lblPrivacy';
       Caption := '(No banking details will be saved !)';
       Font.Size := 13;
       Top := lblCaption.Top + lblCaption.Height + 5;
       Left := (frmDonate.Width DIV 2) - (Width DIV 2);
       Font.Name := 'Unispace';
     end;

  {  lblBank := TLabel.Create(nil);       //maak label om bankinset veld voor te stel
    with lblBank do
     begin
       parent := frmDonate;
       name := 'lblBank';
       Top := lblPrivacy.Top + lblPrivacy.Height + 20;
       Left := 8;
       Font.size := 13;
       Caption := 'Please Enter Your Bank Number : ';
     end;

    edtBank := TEdit.Create(nil);         //maak edit om bank inligting te ontvang
     with edtBank do
      begin
        parent := frmDonate;
        Top := lblBank.Top;
        Left := lblBank.Left + lblBank.Width + 15;
        TextHint := 'Bank number :';
        Font.Size := 13;
        name := 'edtBank';
        Text := '';
      end;    }

    lblPay := TLabel.Create(nil);   //maak label om betalling inset veld voor te stel
    with lblPay do
     begin
        parent := frmDonate;
        Top := lblPrivacy.Top + lblPrivacy.Height + 55;
        Left := 8;
        Caption := 'Donation Amount : (Rand)';
        Font.Size := 13;
        name := 'lblPay';
     end;

    edtPay := TEdit.Create(nil);     //edit om betaling inset te onvang
    with edtPay do
     begin
        parent := frmDonate;
        Top := lblPay.Top;
        Left := lblPay.Left + lblPay.Width + 15;
        Font.Size := 13;
        name := 'edtPay';
        Text := '';
        OnChange := CalcMoneyDist;
     end;

    btnPay := TButton.Create(nil);
     with btnPay do
      begin
      parent := frmDonate;
      Top := edtPay.Top;
      Left := edtPay.Left + edtPay.Width + 5;
      Width := 150;
      Font.Size := 13;
      name := 'btnPay';
      Caption := 'Submit Donation';
      OnClick := SubmitDonation;
      Enabled := false;
      end;

     lblDist := TLabel.Create(nil);   //label om te wys waar die distrubisie gewys word
      with lblDist do
       begin
        parent := frmDonate;
        Top := lblPay.Top + lblPay.Height + 15;
        Left := 8;
        Caption := 'How Money will be distributed Accross the different Courses :';
        Font.Size := 13;
        name := 'lblDist';
        Font.Style := [fsUnderline];
       end;

      RedtDist := TRichEdit.Create(nil);   //Richedit om die distubies inligtib voor te stel
       with RedtDist do
        begin
          parent := frmDonate;
          Top := lblDist.Top + lblDist.Height + 15;
          Left := 8;
          Font.Size := 13;
          Width := frmDonate.Width - 35;
          Height := frmDonate.Height - Top - 45;
          name := 'RedtDist';
          Lines.Clear;
          RedtDist.paragraph.TabCount := 3;
          RedtDist.Paragraph.Tab[0] := 200;
          RedtDist.Paragraph.Tab[1] := 300;
          RedtDist.Paragraph.Tab[2] := 400;
        end;


   frmDonate.ShowModal;    //Wys die donasie form in n Modale manier
 end;
 ///////////////////////////////////////////////////////////////////////////////////////
 procedure TMain.CalcMoneyDist(Sender : TObject);
 var
  sPayStr : string;
  icount : integer;
  bdot : boolean;
  begin

    if (Sender is TEdit) then  //toets of die sender well n Tedit is
     begin
          RedtDist.Lines.Clear;
          btnPay.Enabled := false;
          sPayStr := lowercase((Sender as TEdit).Text);

          if length(sPayStr) < 1 then
          exit;

          if length(SPayStr) > 13 then
          begin
            Showmessage('There is No way you have that much money !!!');
            exit;
          end;

          bdot := false;
          for icount := 1 to length(SPayStr) do   //kyk of al die karakter aanvaar baar is
          begin
           if NOT(CharinSet(SPayStr[icount] , ['0'..'9'])) AND NOT(SPayStr[icount] = '.') then
            begin
              showmessage('illegal Character detected !'+#13+'Only Enter only Numbers and "." character');
              exit;
            end;
           if(sPayStr[icount] = '.') AND (bdot = false) then
            bdot := true
            else if(sPayStr[icount] = '.') AND (bdot = true) then
            exit;
          end;

           if( POS('.',SPayStr) > 0) then
           if POS('.',SPayStr)+2 < length(SPayStr) then
            begin                                        //kyk of daar nie teveel decimale is nie
              showmessage('To many Decimals detected');
              exit;
            end;

          rPay := strtofloat(SPayStr);

          DB.RunSQLQuery(DB.qry,['SELECT SUM(CourseRating) as TotalRating , COUNT(CourseRating) as RatingCount FROM tblCourse WHERE CourseRating > 0']);
          DB.qry.Open;
          iTotalRating := DB.qry['TotalRating'];

          DB.RunSQLQuery(DB.qry,['SELECT * FROM tblCourse WHERE CourseRating > 0']);
          DB.qry.Open;                      //maak die databasis oop
          DB.qry.First;

          while NOT(DB.qry.Eof) do
           begin              //lees deur elke record in die databasis
              RedtDist.Lines.Add(DB.qry['CourseID'] + ' : ' + #9 + floattostrf( (rPay * (DB.qry['CourseRating'] / iTotalRating)) ,ffCurrency,14,2) + #9 + floattostrf( ((DB.qry['CourseRating'] / iTotalRating)*100) ,ffFixed,8,0)+'%');
              DB.qry.Next;      //formateer die Uitset Richedit se teks
           end;
     end;
     btnPay.Enabled := true;
  end;
///////////////////////////////////////////////////////////////////////////////////////
procedure TMain.SubmitDonation(Sender : TObject);
var
qryDonate : TADOQuery;
 begin
  qryDonate := TADOQuery.Create(nil);
  qryDonate.Connection := DB.Con;

  DB.RunSQLQuery(qryDonate,['UPDATE tblusr SET AmountDonated = AmountDonated + '+floattostr(rPay)+' WHERE Username = "'+sUsername+'"']);

  DB.qry.First;
  while NOT(DB.qry.Eof) do
  begin
    DB.RunSQLQuery(qryDonate,['UPDATE tblCourse SET DonationsReceived = DonationsReceived + '+floattostrf((rPay * (DB.qry['CourseRating'] / iTotalRating)),ffFixed,13,2)+' WHERE CourseID = "'+DB.qry['CourseID']+'"']);
    DB.qry.Next;
  end;

  showmessage('Thank you '+SUsername+' For Donating '+(floattostrf(rPay,ffCurrency,13,2))+'');

  ((Sender as TButton).parent as TForm).close;
 end;
///////////////////////////////////////////////////////////////////////////////////////
destructor TMain.destroy;   //destroy funksie vir Main , moet frm ook NIL maak
begin
  freeandnil(frm);
  inherited; //inherit kode van normale TOBJECT destructor
end;
//........................................................................................
//             TCompiledCourse
//........................................................................................
//////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.TCompiledCourse.SetupGUI(jpgimg: TJpegImage; bowned : boolean ; bBrowsing : boolean);
var     //Stel GGK van komponent
 ibtncol : integer;
 begin
 try
   Self.GUI.img := TImage.Create(nil); //
    with Self.GUI.img do  //maak JPG image om kursus prent te display
     begin
       parent := Self;
       Left := 10;
       Top := 4;
       Height := Self.Height - (Top*2);
       Width := Height;
       Picture.Graphic := jpgimg;
       Stretch := true;
       Proportional := true; //stel dat image in preprosie wys
     end;

    Self.GUI.jhbgraphcrtl := TJHBGraphicControl.Create(nil); //Maak JHBGraphic Control om die "Interaksie met die" kursus te vertoon
     with Self.GUI.jhbgraphcrtl do
      begin
       parent := Self;
       Width := 160;
       Height := 50;
       Left := Self.Width - Width - 14 ;
       Top := Self.Height - height -5;
       if bBrowsing = false then  //maak dat kursus view
        begin
         Caption := 'View Course';
         ibtncol :=  $70ff57;
         onClick := OpenCourseinBrowser; //maak kursus in webbrowser oop
        end
       else
       if bowned = true then    //maak dat kursus unSubscribe
        begin
         Caption := '╳ Un-subscribe';
         ibtncol := clBackGround;
         OnClick := UnsubScribeFromCourse; //haal kursus uit owned courses uit
        end
       else   //Maak dat kkursus well subscribe.
        begin
         Caption := '➕ Subscribe';
         ibtncol := $70ff57;
         OnClick := SubscribetoCourse;  //sit kursus in owned courses in
        end;

        OnMouseEnter := HighlightSubButton;//indien muis in beweeg verander kleur
        OnMouseLeave := HighlightSubButton;//indien muis uit beweeg verander kleur
        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,ibtncol,bsSolid,clBlack,3);
        SetText('Unispace',clBlack,[fsBold],[tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
      end;


     if bBrowsing = true then//Indien besig is om te Browse
     begin
     Self.GUI.jhbgraphctrlLike := TJHBGraphicControl.Create(nil); //maak Like konppie (JHBGrapicCtrl)
     with Self.GUI.jhbgraphctrlLike do
      begin
       parent := SElf; //Stel Ouer na Moeder kompoonent
       Width := 50;
       Height := 30;
       Top := Self.Height - Height - 5;
       Left := gui.jhbgraphcrtl.Left - (width*2) - 5;
       Caption := '🖒'; //stel grafika en kapsie
       SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,$F0B478,bsSolid,clBlack,3);
       SetText('Unispace',clBlack,[fsbold],[tfCenter],40,intarrtopointarr([0,(height DIV 2)-30,width,height]));
       tag := 1;
       onClick := RateCourse;  //indien geklik word , maar Rating + 1
       OnMouseEnter := HighlightLikeORDislikeButton;   //verander kleur as muis oor beweeg
       OnMouseLeave := HighlightLikeORDislikeButton;   //verander kleur as muis uit beweeh
      end;

    Self.GUI.jhbgraphctrlDisLike := TJHBGraphicControl.Create(nil); //maak Dislike knopie
     with Self.GUI.jhbgraphctrlDisLike do
      begin
        Parent := Self;
        Width := GUI.jhbgraphctrlLike.WIdth;
        Height := GUI.jhbgraphctrlLike.Height;
        Caption := '🖓';
        Top := GUI.jhbgraphctrlLike.Top; //Stel GGk en kapsie , Sowel as Posisie
        Left := GUI.jhbgraphctrlLike.Left + GUI.jhbgraphctrlLike.Width + 2;
        SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,$F0B478,bsSolid,clBlack,3);
        SetText('Unispace',clBlack,[fsbold],[tfCenter],40,intarrtopointarr([0,(height DIV 2)-36,width,height]));
        tag := -1;
        onClick := RateCourse; //indien geklik word maak Raiting - 1
        OnMouseEnter := HighlightLikeORDislikeButton; //verander kluer indien muis oor beweeg
        OnMouseLeave := HighlightLikeORDislikeButton; //verander kleur indien muis uit beweeg
      end;
     end;

 except  //indien fout gebeur , Se presies waar.
   showmessage('Graphical Error in "Setup GUI" Procedure OF "TCompiled Course" Called From "DisplayCompiledCourses"');
 end;

 end;
 /////////////////////////////////////////////////////////////////////////////////////
destructor TMain.TCompiledCourse.destroy;    //destructor vir n Compiled Course
begin
  Freeandnil(GUI.img);
  FreeAndnil(GUI.jhbgraphcrtl);
  FreeAndnil(GUI.jhbgraphctrlLike);    //Moet al die ekstra komponente free en NIL
  FreeAndnil(GUI.jhbgraphctrlDisLike);
  FreeAndnil(GUI);
  inherited; //inherit van gewone TObject  se destructor
end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.TCompiledCourse.HighlightSubButton(Sender : Tobject);  //verander kleur van Subscribe knoppie
  begin
    if (Sender AS TJHBGraphicControl).Canvas.Brush.Color = $70ff57 then//indien $70ff57 maak $388155
     begin
        (Sender AS TJHBGraphicControl).Canvas.Brush.Color := $388a55;
     end
    else if (Sender AS TJHBGraphicControl).Canvas.Brush.Color = $388a55 then //indien $388155 maak $70ff57
     begin
        (Sender AS TJHBGraphicControl).Canvas.Brush.Color := $70ff57;
     end
    else if (Sender AS TJHBGraphicControl).Canvas.Brush.Color = clBackGround then//indien clBackGround maak $174291
     begin
        (Sender AS TJHBGraphicControl).Canvas.Brush.Color := $174291;
     end
    else if (Sender AS TJHBGraphicControl).Canvas.Brush.Color = $174291 then //indien $174291 maak clBackGround
     begin
        (Sender AS TJHBGraphicControl).Canvas.Brush.Color := clBackGround;
     end;
     (Sender AS TJHBGraphicControl).Paint;   //Teken die Grafika komponent na BackBuffer om na Vram van Graphics card gestuur te word sodat die render pipeline kan voltooi word om die grafika te vertoon op die skerm binne die HWND - handeler geplaas te word sodat die grafika geooreenteer kan word sodat die grafika gesentraliseer word binne n spesifieke window
  end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.TCompiledCourse.HighlightLikeORDislikeButton(Sender : Tobject);
Const
 clBASECOL = $F0B478; //Basis kleur
 clHOVCOL = $F59739;   //muis oor kleur
 clLIKEBASECOL = 0;    //Like Kleur
 clLIKEHOVCOL = $67BDC3;//$42EA5B;   //LIke muis oor kleur
 clDISLIKEBASECOL = 0;               //basis kleur vir dislike
 clDISLIKEHOVCOL = $5B54EE;          //kleur vir dislike knoppie

  begin
  if (Sender IS TJHBGraphicControl) then   //toets of sender regte komponent is
   begin
    with (Sender as TJHBGraphicControl) do  //Cast sender as n JHBGraphicContrl
      begin

        if tag = 1 then     //Indien Tag = +1 :: d.w.s dat dit n LIKE button is
         begin
           if Canvas.Brush.Color = clBaseCol then
              Canvas.Brush.Color := clLikeHovCol         //like (gewone) kleur
           else
           if Canvas.Brush.Color = clLikeHovCol then
              Canvas.Brush.Color := clBaseCol;
         end;

        if tag = -1 then  //indien tag = -1 :: d.w.s dat dit n DISLIKE button is
         begin
           if Canvas.Brush.Color = clBaseCol then
              Canvas.Brush.Color := clDisLikeHovCol    //dislike kleur
           else
           if Canvas.Brush.Color = clDisLikeHovCol then
              Canvas.Brush.Color := clBaseCol;
         end;

      end;//end with;
   end//end if;
  else
  showmessage('Sender is NOT TJHBGraphicControl');  //indien die sender nie n TJHBGraphicContrl is is nie.

  (Sender AS TJHBGraphicControl).Paint;  //Teken die Grafika komponent na BackBuffer om na Vram van Graphics card gestuur te word sodat die render pipeline kan voltooi word om die grafika te vertoon op die skerm binne die HWND - handeler geplaas te word sodat die grafika geooreenteer kan word sodat die grafika gesentraliseer word binne n spesifieke window
  end;
////////////////////////////////////////////////////////////////////////////////////////
Procedure TMain.TCompiledCourse.SubscribeToCourse(Sender : TObject);//Sit Kursus in die Gebruiker is "Owned Courses"-Tabel
  begin
    DB.tblOwnedcourses.Insert;  //Tabel in Insert Mode       //Kry ouer van Sende se ID as n String
    DB.tblOwnedcourses['CourseID'] := ((Sender as TJHBGraphicControl).Parent as TCompiledCourse).sCourseID;
    DB.tblOwnedcourses['UserName'] := Main.sUserName;//lees name is
    DB.tblOwnedcourses.Post; //post na die databasis
    Main.DisplayCompiledCourses(true);  //vetroon die kursusse binne die Scrolbox
  end;
//////////////////////////////////////////////////////////////////////////////////////
Procedure TMain.TCompiledCourse.UnSubscribeFromCourse(Sender : TObject);  //verwyder kursus van die gebruiker is "Owned Courses"-tabel
var
 sCourseID : string;
 bRenderBrowse : boolean;
 begin
   if Sender is TMenuItem then//kyk of Sender n TMenuITem is
    begin
     sCourseID := (Sender as TMenuItem).Caption;
     sCourseID := Copy(sCourseID,Pos(':',sCourseID)+2,length(sCourseID));
     bRenderBrowse := false;    //Kopieer die Caption van die MenuItem om vir die Kursus se naam te soek
    end
   else
    begin
     sCourseID := ((Sender as TJHBGraphicControl).Parent as TCompiledCourse).sCourseID;
     bRenderBrowse := true;   //Kry die Course ID vananf die TCompileCourse se Parent af.
    end;
                     //Delete D.M.V n SQL query die kursus vanaf die databasis
   DB.RunSQLQuery(DB.qry , ['DELETE FROM tblOwnedCourses WHERE CourseID="'+sCourseID+'" AND UserName ="'+Main.sUserName+'"']);
   Main.DisplayCompiledCourses(bRenderBrowse);//her teken die kursusse binne die scrolbox

 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure Tmain.TCompiledCourse.MouseUpInteract(Sender : Tobject; Button : TMouseButton; Shift : TShiftState; X , Y : integer);
 begin //Toets vir die "regter klik" om die (Sub-Menu) oop te maak
   if Button = mbRight then
    CompiledCoursePopup(Sender);//Popup Menu oop maak
 end;
////////////////////////////////////////////////////////////////////////////////////////////
Procedure TMain.TCompiledCourse.CompiledCoursePopup(Sender : TObject);
var
 Popup : TPopupMenu;
 UnsubMenuItem : TMenuItem;
 ModPageMenuItem : TMenuItem;
 begin
   Popup := TPopupMenu.Create(nil);//Maak Popup Menu Item
    begin
      UnsubMenuItem := TMenuItem.Create(Popup);
        with unSubMenuItem do
          begin  //Gee opsies :: Unsubsribe Opsie
            Caption := 'UnSubscribe from : '+(Sender as TCompiledCourse).sCourseID;
            OnClick := Unsubscribefromcourse;  //Indien geklik word "Unsubscribe van die kursus"
            Tag := 4;    //tag 4 gee eind
          end;
       ModPageMenuItem := TMenuItem.Create(Popup);
         with ModPageMenuItem do
          begin //Maak Close Knoppie indien geen verandering gebring moet word nie
            Caption := 'Close';
          end;
      Popup.Items.Add(UnsubMenuItem);    //Sit item in die PopUp Menu
      Popup.Items.Add(ModPageMenuItem);
      popup.Popup(Mouse.CursorPos.X , Mouse.CursorPos.y ); //Spwan popup menu by die muis se middelpunt
    end;
 end;
//////////////////////////////////////////////////////////////////////////////////////////
Procedure Tmain.TCompiledCourse.OpenCourseinBrowser(Sender : Tobject);//Maak n kursus oop in die databasis
var
filepath : string;
sCourseID : string;
courseqry : TADOQuery;
 begin
  sCourseID := ((Sender as TJHBGraphicControl).Parent as TCompiledCourse).sCourseID;//kry COURSEID vananf die sender se ouer komponent
  courseqry := TADOQuery.Create(nil);
  courseqry.Connection := DB.Con; //stel konneksie

  DB.RunSQLQuery(courseqry , ['SELECT * FROM tblCourse WHERE CourseID = "'+sCourseID+'"']);
  courseqry.Open; //hardloop n Sql query om fir die kursus te soek

  filepath := GetCurrentDir+'/CourseView.html'; //stel die pad
  if (FileExists(filepath)) then
  DeleteFile(filepath);

  (courseqry.FieldByName('CourseFile') as tblobfield).savetofile(filepath); //Laai die BLOB fieield Bineer vanaf die databasis
                                                                            //Save die Binere inligting by "CourseView.html"
  shellExecute(0,'open',PWideChar(filepath),nil,nil,SW_HIDE);//hardloop ShellScript om Kursus oop te maak
 end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TMain.TCompiledCourse.RateCourse(Sender: TObject); //Verander Kursus te Rating
const
clDislikeClick = $1C12E9;//Dislike Kleur
clLikeClick = $24CED9; //Like Kleur
var
sChange : string;
sWhere : string;
sCourseID : string;
begin
  if (Sender is TJHBGraphicControl) then  //Toets of Sender n TJHBGraphic Control is
   begin
     with (Sender as TJHBGraphicControl) do
      begin
        sCourseID := (Parent as TJHBGraphicControl).Caption; //Kry se Ouer se CourseID vananf se Caption
        sCourseID := Copy(sCourseID,0,Pos(#13,sCourseID)-1);//Kopieer die Spesifike ID vanaf die Ouer Caption
        sWhere := 'UserName="'+Main.sUserName+'" AND CourseID="'+sCourseID+'"'; //Maak SQL Where gedeelte
        if tag = 1 then
         begin

           Canvas.Brush.Color := clLikeClick;
           sChange := 'UpVote = TRUE , DownVote = FALSE'; //Stel die Waarde om + 1 rating te gee
         end;
        if tag = -1 then
         begin
           Canvas.Brush.Color := clDisLikeClick;          //Stel die Waarde om -1 rating te gee
           sChange := 'UpVote = FALSE , DownVote = TRUE';
         end;
      end;
   end;
   {DB.RunSQLQuery(DB.qry , ['SELECT COUNT(*) as AmountFieldsFound FROM tblRating WHERE '+sWhere ,
                            'IF(AmountFieldsFound>0) BEGIN UPDATE tblRating SET '+sChange+' WHERE '+sWhere+' END ' +
                            'ELSE BEGIN INSERT INTO tblRating (UserName , CourseID , Like , DisLike) VALUES ('+main.sUserName+','+sCourseID+',0,0) END'
                           ]);        }
   DB.RunSQLQuery(DB.qry , ['SELECT * FROM tblRating WHERE '+sWhere]);
   DB.qry.Open;    //maak SQL query oop
   if DB.qry.RecordCount = 0 then   //Indien die gebruiker nog nie die kursus gerate het nie
    begin
     DB.qry.Insert;   //Soek vir die Inser Gedeelte  //Leer net nuwe waardes in
     DB.RunSQLQuery(DB.qry , ['INSERT INTO tblRating (UserName , CourseID, UpVote , DownVote) VALUES ("'+main.sUserName+'","'+sCourseID+'",TRUE , TRUE)']);
    end
   else //indien Wel Gebeuiker klaar die kursus gereate het en sy besuilt verander
    DB.RunSQLQuery(DB.qry , ['UPDATE tblRating SET '+sChange+' WHERE '+sWhere]); //verander waarde
    //Tel die Som van al die UPVotes by en trek die DOWNVotes af om die som te kry
    DB.RunSQLQuery(DB.qry , ['SELECT (ABS(SUM(UpVote)) - ABS(SUM(DownVote))) as finrating FROM tblRating WHERE CourseID="'+sCourseID+'"']);
    DB.qry.open;
    sChange := FloatToStr(DB.qry['finrating']);  //Maak tydelike veld om Die Finale rating in te stoor
    DB.RunSQLQuery(DB.qry , ['UPDATE tblCourse SET CourseRating='+sChange+' WHERE CourseID="'+sCourseID+'"']);

    //(SELECT (ABS(SUM(UpVote)) - ABS(SUM(DownVote))) FROM tblRating WHERE CourseID="'+sCourseID+'")
    //showmessage('RATE = ' + floattostr(DB.qry['finrating']));
    Main.DisplayCompiledCourses(true);  //Vertoon al Die kursus grafika in die scrlbox.
end;
//........................................................................................
//             TCourse
//........................................................................................
procedure TCourse.populateElementList(CreateParent : TWinControl);  //populeer Course Element Menu in Create new Course
 var
 sicount: shortint;
 begin
 CourseMainFileElement := TCourseElement.Create(nil);//Maak nuwe Course Element
 CourseMainFileElement.byElementType := CourseMainFileElement.cePage; //Stel Sy tipe an CePage ( = 0 )
 for sicount := 1 to High(arrCoursePopulationElements) do     //maak al die kursus elemente
   begin
     arrCoursePopulationElements[sicount] := TCourseElement.Create(nil);
      with arrCoursePopulationElements[sicount] do
       begin
        Parent := CreateParent;
        byElementType := sicount;
        UpdateCourseElementGraphics(arrCoursePopulationElements[sicount]);  //stel elk se grafika
        Left := 8;
        Top := Main.arrlbl[2].Top + Main.arrlbl[2].Height + 8;
        if sicount > 1 then
        Top := (arrCoursePopulationElements[sicount-1].Top + arrCoursePopulationElements[sicount-1].Height + 8);
        OnMouseEnter := ChangePenColorOnMouseOver;   //indien muis oor beweeg verander border kleur
        OnMouseLeave := ChangePenColorOnMouseOver;   //indien Uit oor beweeg verander border kleur
        OnClick := AddElementToCourse; //indien geklik word , sit n nuwe element by die kursus
      end;
   end;
 end;
 //////////////////////////////////////////////////////////////////////////////////
procedure TCourse.TCourseElement.UpdateCourseElementGraphics(Element : TCourse.TCourseElement);
const                  //Dateer die Element se Grafika op
FONTSIZE = 13;
FONTNAME = 'Terminal';
var
sIconDir : string;
TextColor : TColor;
BrushColor : TColor;
PenColor : TColor;
FontStyles : TFontStyles;
 begin
        Width := 140;
        Height := 30;
        PenColor := Parent.Brush.Color;  //Stel Omring kleur
        TextColor := clBlack;     //Stel die teks se kleur
        BrushColor := clWhite;
        FontStyles := [];     //haal alle styles af.
        Caption := 'Undefined';
      with Element do
       begin
         case Element.byElementType of    //Toets vir elke element tipe
            ceBlankSpace : begin       //indien ceBlankSpace
                       Caption := 'Blank Space';
                      end;

            ceText :  begin           //indien ceText
                       Caption := 'Text';
                      end;

            ceiFrame : begin         //indien ceiFrame
                         Caption := 'Window';
                         TextColor := clBlue;
                         FontStyles := [fsUnderline];
                       end;

            ceImage : begin         //indien ceImage
                        Caption := 'Image';
                      end;

            ceAudio : begin         //indien ceAudi
                        Caption := 'Audio';
                        siconDir := 'Audioicon.jpg'; //Icon Prent
                      end;

            ceVideo : begin         //indien ceVideo
                        Caption := 'Video';
                      end;


           end;    //stel garfika van die element
           SetGraphic(intarrtoPointarr([0,0,width,height]),gsRectangle,BrushColor,bsSolid,PenColor,3);
           SetText(FONTNAME,TextColor,FontStyles,[tfVerticalCenter,tfCenter],13,intarrtopointarr([0,(height DIV 2)-9,width,height]));
           if siconDir <> '' then//toets of Daar n Icon is
            begin
                imgicon := TImage.Create(nil);
                 with imgicon do
                   begin
                    Parent := Element;
                    Height := 24;
                    Width := 24;
                    Picture.LoadFromFile('Icons/'+sicondir);//Laai die Icon Prent
                    Left := Element.Width - Width - 5;
                    Top := Element.Canvas.Pen.Width;   //Sit Icon na regter kant van die GGK
                    Stretch := true;   //laat stretch toe
                   end;
            end;
       end;
 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.TCourseElement.ChangePenColorOnMouseOver(Sender : TObject); //verander kleur van omlyn wanner muis oor beweeg
 begin
      if (Sender as TJHBGraphicControl).Canvas.pen.Color = (Sender as TJHBGraphicControl).Parent.Brush.Color then
     begin        //indien kleur selfde as agter grond van komponent se kleur veradner na clBackGround
       (Sender as TJHBGraphicControl).Canvas.Pen.Color:= clbackground;
       (Sender as TJHBGraphicControl).Paint; //Teken die Grafika komponent na BackBuffer om na Vram van Graphics card gestuur te word sodat die render pipeline kan voltooi word om die grafika te vertoon op die skerm binne die HWND - handeler geplaas te word sodat die grafika geooreenteer kan word sodat die grafika gesentraliseer word binne n spesifieke window
     end          //indien kleur selfde as clBackground verander an agtergrond van komponent se kleur
   else if (Sender as TJHBGraphicControl).Canvas.Pen.Color = clbackground then
     begin
        (Sender as TJHBGraphicControl).Canvas.Pen.Color := (Sender as TJHBGraphicControl).Parent.Brush.Color;
        (Sender as TJHBGraphicControl).Paint; //Teken die Grafika komponent na BackBuffer om na Vram van Graphics card gestuur te word sodat die render pipeline kan voltooi word om die grafika te vertoon op die skerm binne die HWND - handeler geplaas te word sodat die grafika geooreenteer kan word sodat die grafika gesentraliseer word binne n spesifieke window
     end;

 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.AddElementToCourse(Sender : Tobject);  //Sit nuwe elemet by die CourseContent Array
const
ITEMGAP = 8;
TEXTGAP = 5;
var
 Last : integer;  //Laaste Index van CourseContetnt
 begin
  Setlength(arrCourseContent , length(arrCourseContent)+1);  //Stel na laaste index
  last := High(arrCourseContent);
  arrcourseContent[last] := TCourseElement.Create(nil); //maak nuwe COurseElement
  CloneCourseElement(Sender AS TCourseElement , arrcourseContent[last]);   //Clone die Sender se Grafika oor op die nuwe Child wat gemaak word
  with arrcourseContent[last] do   //Stel laaste element wat bygelas word se grafika
   begin
     Parent := main.arrscrlbox[3];
     Width := Parent.Width - (left*4);
     tfAlignment := tfcenter;
     GraphKoordinates := intarrtopointarr([0,0,Width,Height]); //stel grafika koordinate
     TextKoordinates := intarrtopointarr([TEXTGAP,TEXTGAP,Width-TEXTGAP,Height-TEXTGAP]); //stel grafika koordinate
     TextFormat := [tfwordbreak,tfcenter,tfEndEllipsis];//stel teks formaat
     Top := 8;
     iDispWidth := 100;
     iDispHeight := 100;
     Canvas.Pen.Color := clblack;
     Canvas.Brush.Color := clWhite;
     if length(arrCourseContent) > 1 then
     Top := arrCourseContent[last-1].Top + arrCourseContent[last-1].Height + ITEMGAP;
     iIndexPosition := last;//sit index posisie na laaste index
     OnMouseUp := CourseElementMouseUpInteract; //indien muis geklik word , kyk watter knoppie en die iets
     OnMouseEnter := CreateCourseElementMovementButtons;//indien muis oor beweeg maak gradfika om op en af te beweeg
     OnMouseLeave := CreateCourseElementMovementButtons;//indien muis verlaat vernietig maak gradfika om op en af te beweeg
   end;
 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.CloneCourseElement(Old, New : TCourseElement); //Clone een tot een die grafika van die ou komponet na die nuwe een
 begin
  New.Caption := old.Caption;
  New.Width := old.Width;
  New.Height := old.Height;
  New.Top := old.Top;
  NEw.Left := old.Left;
  New.byElementType := Old.byElementType;      //EEN TO EEN kloning
  New.Canvas.Brush := Old.Canvas.Brush;
  New.Canvas.Pen := Old.Canvas.Pen;
  New.Canvas.Font := Old.Canvas.Font;
  New.byGraphicShape := Old.byGraphicShape;
  New.GraphKoordinates := Old.GraphKoordinates;
  NEw.TextKoordinates := old.TextKoordinates;

 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.CourseElementMouseUpInteract(Sender : Tobject; Button : TMouseButton; Shift : TShiftState; X , Y : integer);
 begin   //Toets watter knoppie gedruk word
   if Button = mbleft then
    OpenElementProperties(Sender);  //Indien Links , Dan maak Course Element te Properties oop
   if Button = mbRight then
    ElementPopupMenu(Sender);      //Indien Regs , maak die Popup menu oop
 end;
////////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.CreateCourseElementMovementButtons(Sender: TObject);
var
icount : integer;
 begin
   if(Sender is TCourseElement) then//toets of sender n TCouse Element is
    begin

     for icount := 0 to High(arrCourseContent) do  //Loop Due rLKeke Course Countnt Element
         begin
           FreeAndNil(arrCourseContent[icount].PropertiesGUI.arrmovebtn[1]); //Maak GGK movebtn[1] skoon
           FreeAndNil(arrCourseContent[icount].PropertiesGUI.arrmovebtn[2]); //kmaak GGK movebtn[2] skoon
         end;

        with (Sender as TCourseElement) do   //Cast sender a TCourseElement
         begin

          if(Sender as TCourseElement).iIndexPosition > 0 then  //toets of die Index posise meer is as  0
          begin
            PropertiesGUI.arrmovebtn[1] := TButton.Create(nil);   //maak die beweeg knoppie
            with PropertiesGUI.arrmovebtn[1] do
             begin
               Parent := (Sender as TCourseElement);
               name := 'btnmoveup';
               Caption := #9650;
               Font.Size := 9;
               Left := 5;
               Height := 10;
               Width := (Sender AS TCourseElement).Width - 5 - Left;
               Top := 0;
               tag := (Parent as TCourseElement).iIndexPosition - 1;
               OnClick := UpdateCourseElementIndexPosition; //indien waar beweeg OUER na posies index-1
             end;
          end;

          if(Sender as TCourseElement).iIndexPosition < High(arrCourseContent) then
          begin
            PropertiesGUI.arrmovebtn[2] := TButton.Create(nil); //beweeg af waarts knoppie
            with PropertiesGUI.arrmovebtn[2] do
             begin
               Parent := (Sender as TCourseElement);
               name := 'btnmovedown';
               Caption := #9660;
               Font.Size := 6;
               Left := 5;
               Height := 10;
               Width := (Sender AS TCourseElement).Width - 5 - left;
               Top := (Sender AS TCourseElement).Height - Height;
               tag := (Parent as TCourseElement).iIndexPosition + 1;
               OnClick := UpdateCourseElementIndexPosition;  //indien waar bweeg OUER na index+1
             end;
          end;
             ////Edings of Function
         end;
      end;
 end;
////////////////////////////////////////////////////////////////////////////////////////////
procedure Tcourse.TCourseElement.FreeAndNilElementPropertiesGuiComponents(); //Maak GGK van CourseElement Skoon
var icount : integer;
 begin
   with Self.PropertiesGUI do  //
    begin
            for icount := 1 to length(arredt) do
            freeandnil(arredt[icount]);
            for icount := 1 to length(arrcmb) do
            freeandnil(arrcmb[icount]);
            for icount := 1 to length(arrlbl) do
            freeandnil(arrlbl[icount]);             //Loop Duer Elke GGK komponent en maak dit skoon
            for icount := 1 to length(arrspnedt) do
            freeandnil(arrspnedt[icount]);
            for icount := 1 to length(arrcb) do
            freeandnil(arrcb[icount]);
            for icount := 1 to length(arrshp) do
            freeandnil(arrshp[icount]);
            for icount := 1 to length(arrbitbtn) do
            freeandnil(arrbitbtn[icount]);
    end;
 end;
///////////////////////////////////////////////////////////////////////////////////////////
procedure Tcourse.OpenElementProperties(Sender : Tobject); //Maak GGK vir element properties
const
 BOXLEFT = 70;
var
 sicount : shortint;
 begin
 Main.arrlbl[3].Caption := 'Element Properties :' ;
 with (Sender AS TCourseElement) do
  begin

    for sicount := 0 to High(arrCourseContent) do //Loop duer GGK en maak GGK skoon
     arrCourseContent[sicount].FreeAndNilElementPropertiesGuiComponents();
     CourseMainFileElement.FreeAndNilElementPropertiesGuiComponents(); //Maak page GGK skoon

     iSelectedElementIndex := iIndexPosition;  //Stel Geseleketeede = IndexPosisie
       with PropertiesGUI do
        begin

        sicount := 1;
         arrlbl[sicount] := TLabel.Create(nil);  //label om Index te wys
           with arrlbl[sicount] do
             begin
               parent := Main.arrscrlbox[2];
               Top := Main.arrlbl[2].Top + Main.arrlbl[2].Height + 5;
               Left := 3;
               Font.Size := 10;
               Caption := 'Index >';
             end;
                  arredt[1] := TEdit.Create(nil); //Edit im Index te vertoon
                    with arredt[1] do
                     begin
                       Parent := Main.arrscrlbox[2];
                       Top := arrlbl[sicount].Top;
                       Left := BOXLEFT;
                       Width := 45;
                       Text := inttostr(iIndexPosition);
                       Tag := iIndexPosition; //Store Old Position
                       ReadOnly := true;//kan nie verander word nie
                     end;

       if byElementType = ceBlankSpace then //indien tipe cdBlankspace
        exit;                //top procedure

         inc(sicount);
         arrlbl[sicount] := TLabel.Create(nil); //maak Label om Teks / Caption te vertoon
           with arrlbl[sicount] do
             begin
               parent := Main.arrscrlbox[2];
               Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
               Left := 3;
               Font.Size := 10;
               if (Sender AS TCourseElement).byElementType = ceText then //indien tipe cdText
                  Caption := 'Text >'
               else
                  Caption := 'Caption >';
             end;

                    arredt[2] := TEdit.Create(nil);    //maak edit om teks / Caption inset te neem
                     with arredt[2] do
                      begin
                        Parent := Main.arrscrlbox[2];
                        Top := arrlbl[sicount].Top;
                        LEft := BOXLEFT;
                        Text :=  (Sender AS TCourseElement).Caption;
                        ONchange := UpdateCourseElementCaption;  //indien verander stel Caapsie = <p>teks</p>
                        if (Sender AS TCourseElement).byElementType = ceText then
                         onclick := GetTextFromJHBInputQuery; //maak JHBInpueQUery OOp
                      end;

         inc(sicount);
         arrlbl[sicount] := TLabel.Create(nil);//maak label om Align te vetoon
           with arrlbl[sicount] do
             begin
               parent := Main.arrscrlbox[2];
               Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
               Left := 3;
               Font.Size := 10;
               Caption := 'Align >'
             end;

                    arrcmb[1] := TCOmboBox.Create(nil);  //maak Combo box om Alignment inset te neem
                     with arrcmb[1] do
                      begin
                        Parent := Main.arrscrlbox[2];
                        Top := arrlbl[sicount].Top;
                        LEft := BOXLEFT;
                        Items.add('Left');
                        Items.add('Centre');  //3 tipes alignment
                        Items.add('Right');
                        case tfAlignment of
                        tfLeft : ItemIndex := 0;
                        tfcenter : ItemIndex := 1;  //stel gelyk aan die tipe alignment klaar gekry
                        tfright :  ItemIndex := 2;
                        else
                        ItemIndex := 0;
                        end;
                        Width := 55;
                        ONchange := UpdateCourseElementCaption; //dateer kapsie se posisie op indien verander is
                      end;

        if byElementType = ceText then   //indien teks
            begin

            inc(sicount);
                arrlbl[sicount] := TLabel.Create(nil);//label om Font size aan te wys
                with arrlbl[sicount] do
                  begin
                    parent := Main.arrscrlbox[2];
                    Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                    Left := 3;
                    Font.Size := 10;
                    Caption := 'Font Size >'
                  end;

                        arrspnedt[1] := TSpinEdit.Create(nil); //Spin Edit om FontSize inset te kry
                          with arrspnedt[1] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             Width := 45;
                             MinValue := 1;
                             MaxValue := BIT16INTEGER;
                             Value := (Sender AS TCourseElement).Canvas.Font.Size;
                             ONchange := UpdateCourseElementFontSize;    //verander font size van GGk Teks tipe
                           end;

            inc(sicount);
                arrlbl[sicount] := TLabel.Create(nil); //Maak label om font se color aan te wys
                with arrlbl[sicount] do
                  begin
                    parent := Main.arrscrlbox[2];
                    Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                    Left := 3;
                    Font.Size := 10;
                    Caption := 'Font Color>'
                  end;
                       arredt[3] := TEdit.Create(nil);  //maak edit om font se color te ontvang
                          with arredt[3] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             Width := 80;
                             Text := inttohex((Sender AS TCourseElement).Canvas.Font.Color,6);
                             name := 'Font';
                             tag := 1;
                             ONchange := UpdateCourseElementColor;//verander die teks se kleur
                           end;

                        arrshp[1] := TShape.Create(nil);//Shape om Element se kleur te toon
                          with arrshp[1] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT + arredt[3].Width+1;
                             Height := arredt[3].Height;
                             Brush.Color := (Sender AS TCourseElement).Canvas.Font.Color; //Geselekteerde kleur
                             Width := Height;
                           end;

                        arrbitbtn[1] := TBitBtn.Create(nil);  //Knoppie om Color Dialog oop te maak
                          with arrbitbtn[1] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := arrshp[1].left + arrshp[1].Width+1;
                             Height := arredt[3].Height;
                             Width := Height;
                             tag := 1;
                             Caption := '...';
                             OnClick := UpdateCourseElementColor; //Opdateeer die element se font kleur
                           end;

            inc(sicount);
                arrlbl[sicount] := TLabel.Create(nil); //label om agtergrond kleur aan te wys
                with arrlbl[sicount] do
                  begin
                    parent := Main.arrscrlbox[2];
                    Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                    Left := 3;
                    Font.Size := 10;
                    Caption := 'Back Color>'
                  end;

                       arredt[4] := TEdit.Create(nil);  //Eidt om agter grond kleur te ontavang
                          with arredt[4] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             Width := 80;
                             name := 'Brush';
                             tag := 2;
                             Text := inttohex((Sender AS TCourseElement).Canvas.Brush.Color,6);
                             ONchange := UpdateCourseElementColor; //opdateeer die element se agtergrond kleur
                           end;

                        arrshp[2] := TShape.Create(nil);//Maak Shape om agtergrond kleur aan te wys
                          with arrshp[2] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT + arredt[4].Width+1;
                             Height := arredt[4].Height; //Stel kleur gelyk aan die huidige agtergrond kleur
                             Brush.Color := (Sender AS TCourseElement).Canvas.Brush.Color;
                             Width := Height;
                           end;

                        arrbitbtn[2] := TBitBtn.Create(nil);//button om color dialog oop te maak
                          with arrbitbtn[2] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := arrshp[2].left + arrshp[2].Width+1;
                             Height := arredt[2].Height;
                             Width := Height;
                             tag := 2;
                             Caption := '...';  //opdateer die agetrgrond kleur van die element
                             OnClick := UpdateCourseElementColor;
                           end;

             end;
              //Indien tipe ceiFram , ceImage , ceAudio , cdVideo
           if byElementType in [ceiFrame,ceImage,ceAudio,ceVideo] then
            begin

               inc(sicount);
                arrlbl[sicount] := TLabel.Create(nil); //Maak Label om Source aan te wys
                with arrlbl[sicount] do
                  begin
                    parent := Main.arrscrlbox[2];
                    Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                    Left := 3;
                    Font.Size := 10;
                    Caption := 'Source >';
                  end;

                        arredt[5] := TEdit.Create(nil);//maak edit om source inset te neem
                          with arredt[5] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             Text := sSource;
                             Width := width - 15;
                             ONchange := UpdateCourseElementSource;  //Dateer die element se Source op
                           end;

                        arrbitbtn[3] := TBitBtn.Create(nil);  //knoppie om Source d.m.v n File Dialog te kies
                          with arrbitbtn[3] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arredt[5].Top;
                             Caption := '...';
                             LEft := arredt[5].Width + arredt[5].Left + 1;
                             width := 18;
                             Height := arredt[5].Height;
                             tag := 5;
                             onClick := ReadSourceFromOpenDlg;//Kry source vananf n Open File Dialog
                           end;
            end;
           //indien tipe ceiFram , ceImage , ceVideo
           if byElementType in [ceiFrame,ceImage,ceVideo] then
            begin

               inc(sicount);
                arrlbl[sicount] := TLabel.Create(nil);   //maak label om Width aan te wys
                with arrlbl[sicount] do
                  begin
                    parent := Main.arrscrlbox[2];
                    Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                    Left := 3;
                    Font.Size := 10;
                    Caption := 'Width >';
                  end;

                        arrspnedt[2] := TSpinEdit.Create(nil);//maak Spin Edit om Wydte inset te kry
                          with arrspnedt[2] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             width := 105;
                             MinValue := 1;
                             MaxValue := BIT16INTEGER;//Hoogte moontlike getal 65535
                             Value := iDispWidth;
                             ONchange := UpdateCourseElementDispWidth; //Dateer Wydte op
                           end;

               inc(sicount);
                arrlbl[sicount] := TLabel.Create(nil);  //label om hoogte aan te wys
                with arrlbl[sicount] do
                  begin
                    parent := Main.arrscrlbox[2];
                    Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                    Left := 3;
                    Font.Size := 10;
                    Caption := 'Height >';
                  end;

                        arrspnedt[3] := TSpinEdit.Create(nil); //spin edit om hoogte inst te neem
                          with arrspnedt[3] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             Width := 105;
                             MinValue := 1;
                             MaxValue := BIT16INTEGER; //Hoogte moontlike getal 65535
                             Value := iDispHeight;
                             ONchange := UpdateCourseElementDispHeight;  //verander hoogte getal van element
                           end;
            end;

            inc(sicount);
            arrlbl[sicount] := TLabel.Create(nil);  //label om Hyperlink aan te dui
             with arrlbl[sicount] do
              begin
                parent := Main.arrscrlbox[2];
                Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                Left := 3;
                Font.Size := 10;
                Caption := 'hyperlink >';
              end;

                        arredt[6] := TEdit.Create(nil);  //Edit om hyperlike inset te neem
                          with arredt[6] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             Text := sHref;
                             ONchange := UpdateCourseElementHref; //verander element se hyperlike propertie
                           end;

        end;
     end;
 end;
////////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.OpenCourseProperties(Sender : TObject); //Maak Die Kursus self se propeties oop
const BOXLEFT = 70;
var
sicount : shortint;
begin
 Main.arrlbl[3].Caption := 'Page Properties :' ;
  With CourseMainFileElement do
   begin
      for sicount := 0 to High(arrCourseContent) do
       begin                      //maak Element properties skoon
         arrCourseContent[sicount].FreeAndNilElementPropertiesGuiComponents();
       end;
      FreeAndNilElementPropertiesGuiComponents(); //Maak Course Propetries skoon


     with PropertiesGUI do
      begin

         sicount := 1;
         arrlbl[sicount] := TLabel.Create(nil);  //maak label om Naam aan te wys
           with arrlbl[sicount] do
             begin
               parent := Main.arrscrlbox[2];
               Top := Main.arrlbl[2].Top + Main.arrlbl[2].Height + 5;
               Left := 3;
               Font.Size := 10;
               Caption := 'Name : ';
             end;

                    arredt[1] := TEdit.Create(nil);//maak edit om naam inset te kry
                     with arredt[1] do
                      begin
                        Parent := Main.arrscrlbox[2];
                        Top := arrlbl[sicount].Top;
                        LEft := BOXLEFT;
                        Text := CourseMainFileElement.Caption;
                        ONchange := UpdateCourseMainFileName; //verander naam propetie van die element
                      end;


         inc(sicount);
                arrlbl[sicount] := TLabel.Create(nil);//label om die Color aan te wys
                with arrlbl[sicount] do
                  begin
                    parent := Main.arrscrlbox[2];
                    Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                    Left := 3;
                    Font.Size := 10;
                    Caption := 'Color >'
                  end;

                       arredt[3] := TEdit.Create(nil); //edit om color as inset te kry
                          with arredt[3] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             Width := 80;
                             name := 'Brush';
                             tag := 0;
                             Text := inttohex(CourseMainFileElement.Canvas.Brush.Color,6);
                             ONchange := UpdateCourseElementColor;
                           end;

                        arrshp[1] := TShape.Create(nil);  //shape om kleur te vetoon
                          with arrshp[1] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT + arredt[3].Width+1;
                             Height := arredt[3].Height;
                             Brush.Color := CourseMainFileElement.Canvas.Brush.Color;
                             Width := Height;
                           end;

                        arrbitbtn[1] := TBitBtn.Create(nil);  //knoppie om Color Dialog oop te maak
                          with arrbitbtn[1] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := arrshp[1].left + arrshp[1].Width+1;
                             Height := arredt[3].Height;
                             Width := Height;
                             tag := 0;
                             Caption := '...';
                             OnClick := UpdateCourseElementColor; //Opdateer Kleur van die Kursus back page
                           end;
                         Main.arrscrlbox[3].Color :=  CourseMainFileElement.Canvas.Brush.Color;


                inc(sicount);
                arrlbl[sicount] := TLabel.Create(nil);
                with arrlbl[sicount] do //label om course image aan te wys
                  begin
                    parent := Main.arrscrlbox[2];
                    Top := arrlbl[sicount-1].Top + arrlbl[sicount-1].Height + 10;
                    Left := 3;
                    Font.Size := 10;
                    Caption := 'Image >';
                  end;

                        arredt[4] := TEdit.Create(nil);  //edit om Image as inset te kry (Source)
                          with arredt[4] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arrlbl[sicount].Top;
                             LEft := BOXLEFT;
                             Text := sSource;
                             Width := width - 15;
                             ONchange := UpdateCourseMainFileImgSource; //verander die kursus se image
                           end;

                        arrbitbtn[2] := TBitBtn.Create(nil);  //knoppie op open file dialog oop te maak en image te kies
                          with arrbitbtn[2] do
                           begin
                             Parent := Main.arrscrlbox[2];
                             Top := arredt[4].Top;
                             Caption := '...';
                             LEft := arredt[4].Width + arredt[4].Left + 1;
                             width := 18;
                             Height := arredt[4].Height;
                             tag := cePage;
                             onClick := UpdateCourseMainFileImgSource; //opdateer die kursus te prent met nuwe date
                           end;

      end;
   end;



 end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.ElementPopupMenu(Sender: TObject);  //procedure vir kurses element se piopup menu
var
 Popup : TPopupMenu;
 DelMenuItem : TMenuItem;
 ModPageMenuItem : TMenuItem;
 begin
   Popup := TPopupMenu.Create(nil);//maak die popup menu
    begin
      DelMenuItem := TMenuItem.Create(Popup); //maak die Delte Item
        with DelMenuItem do
          begin
            Caption := 'Delete Element';
            OnClick := DeleteCourseElement; //verwyder element sodra geklik word
            Tag := iSelectedElementIndex; //Verwyder die "Selected Element Index"
          end;
       ModPageMenuItem := TMenuItem.Create(Popup);  //Maak Close Menu Item
         with ModPageMenuItem do
          begin
            Caption := 'Close';
            //OnClick := ;
            Tag := TCourseElement.cePage;
          end;
      Popup.Items.Add(DelMenuItem);     //Sit Menu Items by popup menu
      Popup.Items.Add(ModPageMenuItem);
      popup.Popup(Mouse.CursorPos.X , Mouse.CursorPos.y );  //maak popup menu by die muis te middelpunt
    end;
 end;
////////////////////////////////////////////////////////////////////////////////////////
//[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
procedure TCourse.UpdateCourseMainFileName(Sender : TObject);  //Dateer die Hoof naam van die kursus op
 begin
   CourseMainFileElement.Caption := (Sender as TEdit).Text;
 end;
////////////////////////////////////////////////////////////////////////////////////////
procedure Tcourse.UpdateCourseElementCaption(Sender : Tobject);  //vernader die element se kapsie
  begin
    with arrcourseContent[iSelectedElementIndex] do
     begin

        if (Sender is TEdit) then //toets of sender n TEdit is
          Caption := (Sender as TEdit).Text;//Stel kapsie

        case PropertiesGUI.arrcmb[1].ItemIndex of
          0 : tfAlignMent := tfLeft;
          1 : tfAlignMent := tfCenter;  //Indien cmd[1] verander , veradern tfAlignment
          2 : tfAlignMent := tfRight;
        end;
        TextFormat := [tfWordBreak,tfEndEllipsis,tfAlignment];   //stel die formate van die teks
        OrganiseElementsInOutput();  //her-organiseer die elemente in die kursus
     end;

  end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure Tcourse.DeleteCourseElement(Sender : Tobject);//Delete die Huidige element
var
 icount : integer;
 begin
  arrCourseContent[(Sender as TMenuItem).tag].FreeAndNilElementPropertiesGuiComponents;
  FreeAndNil(arrCourseContent[(Sender as TMenuItem).tag]);//Maak die Geheur waarin GGK gestoor word skoon
  for icount := (Sender as TMenuItem).tag to High(arrCourseContent)-1 do
    begin    //Loop deur elke CourseContent
      arrCourseContent[icount] := arrCourseContent[icount+1];
      arrCourseContent[icount].iIndexPosition := icount;
    end;
    Setlength(arrCourseContent,Length(arrCourseContent)-1);
    OrganiseElementsInOutput(); //Heroraganiseer die GGK elemente in die formaat
 end;
///////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////
procedure Tcourse.UpdateCourseElementIndexPosition(Sender : TOBject);//opdateer die Kursus element se poisie
 var
 SwapElement : tCourseElement;
 iorgIndex : integer;
 inewIndex : integer;
  begin
   if(Sender is TButton) then   //Indien Sender n TButton is
    with (Sender AS TButton) do
     begin
       iorgIndex := ((Sender as TButton).Parent AS TCourseElement).iIndexPosition;
       inewIndex := tag;  //Ruil Ou en Nuwe Element op
       SwapElement := arrCourseContent[iorgIndex];
       arrCourseContent[iorgIndex] := arrCourseContent[inewIndex];
       arrCourseContent[inewIndex] := SwapElement;
     end;
   OrganiseElementsInOutput();  //Heroragniseer die elmente in die uitset GGK
  end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.GetTextFromJHBInputQuery(Sender : Tobject); //Kry teks vanaf die JHBInputQuery
var
 sValue : string;
 begin
   sValue := (Sender AS TEdit).Text;
   Main.JHBInputQuery('Enter Text','Enter Text : ','BOLD=<b> </b> | ITALIC=<i> </i> | UNDERLINE=<u> </u>',sValue);
   (Sender AS TEdit).Text :=  sValue;   //return waarde as SValue
 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.UpdateCourseElementFontSize(Sender : TObject);  //Opdateer die Font Size
 begin
  with (Sender AS TSpinEdit) do
   begin
    if (Text = '') OR  (Value > MaxValue) OR (Value < MinValue) then
     Value := 0;
      arrcourseContent[iSelectedElementIndex].Canvas.Font.Size := Value;
      OrganiseElementsInOutput();//her-Organiseer GGK komponente in Uitset
   end;
 end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.UpdateCourseElementSource(Sender : Tobject);  //Opdateer die ggk msource file vir die eind gebruiker
 begin
  arrcourseContent[iSelectedElementIndex].sSource := (Sender as TEdit).Text; //Stel Source na Text
 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.ReadSourceFromOpenDlg(Sender : TObject);//Lees die Uitset
begin
    arrcourseContent[iSelectedElementIndex].PropertiesGUI.arredt[(Sender as TBitBtn).tag].Text := Main.FileSelectDialog('Local File Select','');
end;    //Stel die Ouer BITBTN , as n FileSelectDialog
///////////////////////////////////////////////////////////////////////////////////////
procedure Tcourse.UpdateCourseElementDispWidth(Sender : Tobject); //Update die Element se Wydte
 begin
  with (Sender AS TSpinEdit) do
   begin    //Gebruik SpinEdit se Waarde om die wydte te opdateer
    if NOT((Text = '') OR  (Value > MaxValue) OR (Value < MinValue)) then
      arrcourseContent[iSelectedElementIndex].iDispWidth := Value; //Stel Wydte gelyk aan value
   end;
 end;
////////////////////////////////////////////////////////////////////////////////////////
procedure Tcourse.UpdateCourseElementDispHeight(Sender : Tobject);
 begin
  with (Sender AS TSpinEdit) do
   begin   //Stel SpinEdit hoogte gelyk aan dike die waardei vanb die spinEdit
    if NOT((Text = '') OR  (Value > MaxValue) OR (Value < MinValue)) then
      arrcourseContent[iSelectedElementIndex].iDispHeight := Value;  //Stel geluyk
   end;
 end;
////////////////////////////////////////////////////////////////////////////////////////
procedure Tcourse.UpdateCourseElementHref(Sender : Tobject); //Element Se hyperlink teks
 begin
   arrcourseContent[iSelectedElementIndex].sHref := (Sender as TEdit).Text; //stel gelyk aan EDIT.text wat sender is
 end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.UpdateCourseElementColor(Sender : TObject);  //Kleur Open Dialog
var
 col : TColor;
 coldlg : TColorDialog;
 itag : integer;
 begin
   col := 0;
   itag := 0;
   if Sender IS TEdit then     //Toets of sender TEdit is
    begin
       with (Sender as TEdit) do
        begin
         itag := tag;
          col := strtoint('$00'+Text);
          if tag = 0 then
           begin //stel Kleur
             CourseMainFileElement.Canvas.Brush.Color := col;
             CourseMainFileElement.PropertiesGUI.arrshp[1].brush.Color := col;
           end;
          if tag = 1 then //idien tag = 1 stel shape 1
           begin
             arrcourseContent[iSelectedElementIndex].Canvas.Font.Color := col;
             arrcourseContent[iSelectedElementIndex].PropertiesGUI.arrshp[1].brush.Color := col;
           end;
          if tag = 2 then
           begin    //indien tag = 2 stel Shape 2
             arrcourseContent[iSelectedElementIndex].Canvas.Brush.Color := col;
             arrcourseContent[iSelectedElementIndex].PropertiesGUI.arrshp[2].brush.Color := col;
           end;
        end;
    end;

   if Sender IS TBitBtn then//toets of sender BitButton is.
    begin
       with (Sender as TBitBtn) do
        begin
         itag := tag;
           coldlg := TColorDialog.Create(nil);//Maak die TColorDialog
           if coldlg.Execute then
             col := coldlg.Color;
           if tag = 1 then
             begin  //indien tag = 1 stel shape 1 en EDIT 3
               arrcourseContent[iSelectedElementIndex].Canvas.Font.Color := col;
               arrcourseContent[iSelectedElementIndex].PropertiesGUI.arrshp[1].brush.Color := col;
               arrcourseContent[iSelectedElementIndex].PropertiesGUI.arredt[3].Text := inttohex(col,6);
             end;
           if tag = 2 then
             begin //indien tag = 2 stel shape 2 ne edit 4
               arrcourseContent[iSelectedElementIndex].Canvas.Brush.Color := col;
               arrcourseContent[iSelectedElementIndex].PropertiesGUI.arrshp[2].brush.Color := col;
               arrcourseContent[iSelectedElementIndex].PropertiesGUI.arredt[4].Text := inttohex(col,6);
             end;
           if tag = 0 then
           begin //indien tag = 0 stel shape 1 en edit 3
               CourseMainFileElement.Canvas.Brush.Color := col;
               CourseMainFileElement.PropertiesGUI.arrshp[1].brush.Color := col;
               CourseMainFileElement.PropertiesGUI.arredt[3].Text := inttohex(col,6);
           end;
        end;
    end;

  if itag <> 0 then
  arrcourseContent[iSelectedElementIndex].Paint //PAINT selfde as voorheer , Copy date na backbuffer
  else
  OpenCourseProperties(self);  //maak die CoursePrperties weer oop
 end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.UpdateCourseMainFileImgSource(Sender : TObject);//Updateer die Course se Image file
 begin
   if Sender is TEdit then  //toets of sender n edit is
   CourseMainFileElement.sSource := (Sender as TEdit).Text;
   if Sender is TBitbtn then //toets of sender n Butbutton is
   begin                                //maak Tfile dialog oop
   CourseMainFileElement.sSource := Main.FileSelectDialog('Local File Select','image(JPEG))|*.jpg;*.jpeg;');
   OpenCourseProperties(Self);  //maak die Kursus Properties weer oop
   end;
 end;
/////////////////////////////////////////////////////////////////////////////////////////
//[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]
procedure Tcourse.OrganiseElementsInOutput();
 const
 ITEMGAP = 8;
 TEXTGAP = 5;
 var
  icount , linebreakcount : Integer;
  stest : string;
  begin
   //showmessage('TranslateCourseContentTOHTML ' + ': ' + inttostr(High(Self.CourseContent)));
    if length(arrCourseContent) < 1 then //kyk fo lengte van CourseContent langer as 1 is.
    exit;

     arrCourseContent[0].Top := 10;
     arrCourseContent[0].iIndexPosition := 0;
     for icount := 0 to High(arrCourseContent) do  //loop duer elke element in CourseContent
       begin
         with arrCourseContent[icount] do
           begin
                if byElementType = ceText then //Indien Tipe Teks
                 begin
                   stest := Caption;
                   linebreakcount := 1 + Round( (length(Caption)*(Canvas.Font.Size/2)) / width );
                   while pos(chr(10) , stest) > 0 do
                    begin
                      Delete(stest,1,pos(chr(10),stest)); //indien teks se lengte lank genoeg is , maak hoogte
                      inc(linebreakcount);                //hoer en sit n Linebreak in
                    end;

                   if (Height < Canvas.Font.Size*3.2*linebreakcount) then
                      Height := ROUND(Canvas.Font.Size*2*linebreakcount)  //Stel nuwe hoogte
                   else if Height > Canvas.Font.Size*3.2*linebreakcount then
                      Height := ROUND(Canvas.Font.Size*2*linebreakcount);



                 end;
                  //stel Teks en Grafika Gaps
                 TextKoordinates := intarrtopointarr([TEXTGAP,TEXTGAP,Width-TEXTGAP,Height-TEXTGAP]);
                 GraphKoordinates := intarrtopointarr([0,0,Width,Height]);
                if icount >= 1 then
                 begin     //heroraganiseeer elke element duer hull hoogte te stel
                   Top :=  arrCourseContent[icount-1].Top + arrCourseContent[icount-1].Height + ITEMGAP;
                   iIndexPosition := icount;
                 end;
                 arrCourseContent[icount].Paint;  //teken elke elment op die skerm
           end;
       end;
  end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.TranslateCourseContentTOHTML(Sender : TObject); //Save ; transleer die kursus na HTML
var
 icount : integer;
 txtfile : TextFile;
 shtmlElement , sFilePath , sImgiFrame ,sMediaType ,sAlign : string;
                     //Formateer die teks om HTML comlient te wees
                   function FormatText(stext : string) : string ;
                      begin
                        while Pos(#13,sText) > 0 do
                          begin
                            sText := Copy(sText,1,Pos(#13,sText)-1) + '</br>' + Copy(sText,Pos(#13,sText)+1,length(sText));
                          end;
                         result := sText; //ge rustltaat terug
                      end;
 begin

 {if (Sender as TJHBGraphicControl).tag = 0 then
 sFilePath :=  Main.FileSelectDialog('Select File','Text Files|*.txt;*.html;*.htm')
 else
 if (Sender as TJHBGraphicControl).tag = 1 then
 sFilePath := (Sender as TJHBGraphicControl).job;     }
 if CourseMainFileElement.Caption = '' then  //kyk of daar is naam is
  begin
    Messagedlg('Your Course needs a name !' , mtWarning , [mbOk] , 0);
    OpenCourseProperties(Self);  //maak CoursePropeties oop
    exit;
  end;

  if NOT(DirectoryExists(GetCurrentDir+'/Saved Courses')) then
   CreateDir(GetCurrentDir+'/Saved Courses');  //maak die "Saved Course" Directory

 sFilePath := 'Saved Courses/'+CourseMainFileElement.Caption + '.html';//stel pad om na gesave te word

 if FileExists(sFilePath) then
  begin
    //if Messagedlg('This Course already exists... do you want to Override ?' , mtWarning , [mbYes , mbNo] , 0) = mrNo then
   // Exit;
  end;

 if SFilePath <> '' then    //kyk of pad gestel is
  begin
   AssignFile(txtfile,sFilePath);             //Boonstevlak Boiler-Plate
    ReWrite(txtfile);
         Writeln(txtfile,'<!DOCTYPEHTML>');
         Writeln(txtFile,'<Head>');
         writeln(txtFile,'<title>'+ CourseMainFileElement.Caption +'</title>');  //Stel titel
         writeln(txtFile,'<!--CourseImagePath :"'+ CourseMainFileElement.sSource +'"/CourseImagePath-->');
         writeln(txtFile,'<style>');                               //stel Source van image
         writeln(txtfile,'.blockcenter' +  //Stel custom klas van .blockcenter
                         '{' +
                         'display: block;' +
                         'margin-left: auto;'+
                         'margin-right: auto;'+
                         'width: 50%;'+
                         '}'
                         );
         writeln(txtFile,'</style>');
         Writeln(txtFile,'</Head>');  //begin body         //stel die kleur van die body
         Writeln(txtFile,'<Body style="background-color:'+Main.InttoHTMLHex(CourseMainFileElement.Canvas.Brush.Color)+'">');

         for icount := 0 to High(Self.arrCourseContent) do   //loop duer elke course element
            begin
             with Self.arrCourseContent[icount] do
             begin
                 sImgiFrame := 'src="'+sSource+'" width="'+inttostr(idispwidth)+'" height="'+inttostr(idispheight)+'" title="'+Caption+'"';
                 sMediaType := Copy(ssource,Pos('.',ssource)+1,5);
                 if sMediaType = 'mp3' then   //indien mp3 maak MPEG
                 sMediaType := 'MPEG';

                 case tfAlignment of
                  tfleft   : sAlign := 'left'  ;
                  tfcenter : sAlign := 'center'  ;   //Kry tipe alignment
                  tfRight  : sAlign := 'right'  ;
                 end;

                 case byElementType of    //Indien Elemet Teks is , Stel om in te pas
                   ceText : shtmlelement :=
                   '<p style="font-size: '+inttostr(Canvas.Font.Size)+'px;'+'color: '+Main.InttoHTMLHex(Canvas.Font.Color)+';background-color: '+Main.InttoHTMLHex(Canvas.brush.Color)+';text-align:'+sAlign+'">'+ FormatText(Caption) +'</p>' ;

                   ceiframe : shtmlelement :=  //Indien Elemet iframe is , Stel om in te pas
                   '<div align="'+sAlign+'"> <iframe '+sImgiFrame+'> </iframe> </div>' ;

                   ceImage : shtmlelement :=   //Indien Elemet Image is , Stel om in te pas
                   '<div align="'+sAlign+'"> <img '+sImgiFrame+'/> </div>' ;

                   ceAudio : shtmlelement :=     //Indien Elemet Audio is , Stel om in te pas
                   '<div align="'+sAlign+'"> <audio controls> <source src="'+sSource+'" type="audio/'+sMediaType+'"> </source> </audio> </div>' ;

                   ceVideo : shtmlelement :=    //Indien Elemet Video is , Stel om in te pas
                   '<div align="'+sAlign+'"> <video width="'+inttostr(idispwidth)+'" height="'+inttostr(idispheight)+'" controls> <source src="'+sSource+'" type="video/'+sMediaType+'> </source> </video> </div>' ;

                   ceBlankSpace : sHtmlelement := '</br>';
                 end;

                 if shref <> '' then   //Indien daar wel n Href is , sit teks vooraan om dit te idenftfiseer
                  begin
                   shtmlelement := '<a href="'+shref+'">' + shtmlelement ;
                   shtmlelement := shtmlelement + '</a>' ;
                  end;

                 Writeln(txtFile,shtmlelement) ;//skryf elke lyn na die teks leer
                // Writeln(txtFile,'</br>') ;
             end;
            end;
         Writeln(txtFile,'</Body>');
    CloseFile(txtfile);   //maak teksleer toe
   Main.TempPopupDlg('Course Successfully Saved',1); //maak n tydelike popup wat se dat die teks gesave is
   end;
 end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.LoadCourseFromHTML(Sender : Tobject);//Laai die Kursus vananf HTML na Course Elements
var
 txtfile : TextFile;
 sFilepath , sHTML , sValue , sLine , sNextHref : string;
 tfNextAlignment : TTextFormats;
 ilast , i1st , i2de , icount : integer;

           function GetClosestElement():integer;  //Kry die naeste element
            var Arr : array[0..7] of integer;
                btcount : byte;
                btval : byte;
            begin
              arr[0] := Pos('<p',sHTML);
              arr[1] := Pos('<iframe',sHTML);
              arr[2] := Pos('<img',sHTML);
              arr[3] := Pos('<audio',sHTML);    //Stel elk se tipe binne d ie array
              arr[4] := Pos('<video',sHTML);
              arr[5] := Pos('</br>',sHTML);
              arr[6] := Pos('<a',sHTML);
              arr[7] := Pos('<div',sHTML);

              if Arr[0] + Arr[1] + Arr[2] + Arr[3] + Arr[4] + Arr[5] + Arr[6] = 0 then
                begin
                  SValue := '<EXITCODE>';     //indien niks , stel uitset na EXITCODE
                  result := -1;
                  exit;
                end;

              result := 999999;//
              btval := 0;
              for btcount := 0 to High(arr) do
                begin
                  if (arr[btcount] < result) AND NOT(arr[btcount] = 0) then
                   begin
                   result := arr[btcount];     //Kyk watter element gevind is
                   btVal := btcount;
                   end
                end;

               case btval of
               0 : sValue := '<p';
               1 : sValue := '<iframe';
               2 : sValue := '<img';
               3 : sValue := '<audio';   //Stel teks dan na Element se tipe
               4 : sValue := '<video';
               5 : sValue := '</br>';
               6 : sValue := '<a';
               7 : sValue := '<div';
               end;

            end;

                   function FormatText(stext : string) : string ;
                      begin  //Formater teks volgens nodigheid vir HTML
                        while Pos('</br>',sText) > 0 do
                          begin
                            sText := Copy(sText,1,Pos('</br>',sText)-1) + #13 + Copy(sText,Pos('</br>',sText)+length('</br>'),length(sText));
                          end;
                         result := sText;
                      end;
  begin

 sFilePath :=  Main.FileSelectDialog('Select File','Text Files|*.txt;*.html;*.htm');//File Dialog om vir leer te soek
 if SFilePath <> '' then
    begin
      AssignFile(txtfile,sFilePath);
      Reset(txtfile);
      try

        tfNextAlignment := tfLeft;  //Default Value

        for icount := high(arrCourseContent) Downto 0 do //Loop duer CourseContent
         begin
           arrCourseContent[icount].FreeAndNilElementPropertiesGuiComponents;
           Freeandnil(arrCourseContent[icount]);       //Maak CourseContent Grafika en self skoon
         end;
         Setlength(arrCourseContent,0);
         sHTML := '';
         while not EOF(txtfile) do       //Terwyl teks leer nog lyntjies het
          begin
            Readln(txtfile , sLine);
            sHTML := sHTML + sLine;
          end;

         i1st := Pos('<title>',sHTML) + length('<title>');
         i2de := Pos('</title>',sHTML);                     //Kry Title element
         CourseMainFileElement.Caption := (Copy(sHTML,i1st,i2de-i1st));
         Delete(sHTML,1,i2de);

         i1st := Pos('<!--CourseImagePath :"',sHTML) + length('<!--CourseImagePath :"');
         i2de := Pos('"/CourseImagePath-->',sHTML);                 //Kry Image path element
         CourseMainFileElement.ssource := (Copy(sHTML,i1st,i2de-i1st));
         Delete(sHTML,1,i2de);

         i1st := Pos('<Body style="background-color:',sHTML) + length('<Body style="background-color:');
         i2de := Pos('">',sHTML);                      //Kry COuse Color element
         CourseMainFileElement.Canvas.Brush.Color := Main.HTMLHEXtoint(Copy(sHTML,i1st,i2de-i1st));
         Delete(sHTML,1,i2de);

         while Length(sHTML) > 0 do    //Gaan duer SHTML teks
          begin
             ilast := high(arrCourseContent)+1;
             i1st := GetClosestElement();

             if sValue = '</br>' then
              begin
               AddElementTOCourse(arrCoursePopulationElements[1]);
               Delete(sHTML,1,i1st+length('</br>')-1);            //indien BR is "Blank Space in"
              end;

             if sValue = '<p' then
              begin
               AddElementTOCourse(arrCoursePopulationElements[2]);
               i2de := Pos('</p>',SHTML);
               sLine := Copy(sHTML ,i1st ,i2de + length('</p>')) ;
               Delete(sHTML,1,i2de+length('</p>')-1);               //indien <p sit  TEXT in

                 i1st := Pos('font-size: ',sLine) + length('font-size: ');
                 i2de := Pos('px',sLine);                           //Kry teks font grote
                 arrCourseContent[ilast].Canvas.Font.Size := strtoint(Copy(sLine,i1st,i2de-i1st));

                 i1st := Pos('color: ',sLine) + length('color: ');
                 i2de := Pos('background-color: ',sLine)-1;  //kry teks foreground color
                 arrCourseContent[ilast].Canvas.Font.Color := Main.HTMLHextoint(Copy(sLine,i1st,i2de-i1st));

                 i1st := Pos('background-color: ',sLine) + length('background-color: ');
                 i2de := Pos('text-align:',sLine)-1;               //kry background color
                 arrCourseContent[ilast].Canvas.Brush.Color := Main.HTMLHextoint(Copy(sLine,i1st,i2de-i1st));

                 i1st := Pos('">',sLine) + length('">');
                 i2de := Pos('</p>',sLine);                  //kry einde van teks
                 arrCourseContent[ilast].Caption := FormatText(Copy(sLine,i1st,i2de-i1st));

                 i1st := Pos('text-align:',sLine) + length('text-align:');
                 i2de := Pos('">',sLine);
                 if Copy(sLine,i1st,i2de-i1st) = 'center' then
                   tfNextAlignment := tfCenter               //kry teks alignment en stel dit
                 else if Copy(sLine,i1st,i2de-i1st) = 'right' then
                   tfNextAlignment:= tfRight
                 else
                   tfNextAlignment := tfLeft;

                 arrCourseContent[ilast].TextFormat := [tfWordBreak,tfEndEllipsis,tfNextAlignment];
                 arrCourseContent[ilast].tfAlignment := tfNextAlignment;  //stel alignment

              end;

             if sValue = '<iframe' then
              begin
               AddElementTOCourse(arrCoursePopulationElements[3]);
               i2de := Pos('</iframe>',SHTML);                         //kyk of element n iframe is
               sLine := Copy(sHTML ,i1st ,i2de + length('/iframe')) ;
               Delete(sHTML,1,i2de+length('</iframe>')-1);
              end;

             if sValue = '<img' then
              begin               //kyk of element n image is
               AddElementTOCourse(arrCoursePopulationElements[4]);
               i2de := Pos('/>',SHTML);
               sLine := Copy(sHTML ,i1st ,i2de + length('/>')) ;
               Delete(sHTML,1,i2de+length('/>')-1); //kry einde van image
              end;

             if sValue = '<audio' then
              begin               //kyk of image audio is
               AddElementTOCourse(arrCoursePopulationElements[5]);
               i2de := Pos('</audio>',SHTML);
               sLine := Copy(sHTML ,i1st ,i2de + length('</audio>')) ;
               Delete(sHTML,1,i2de+length('</audio>')-1);  //kry einde van audio
              end;

             if sValue = '<video' then
              begin               //kyk of element video is
               AddElementTOCourse(arrCoursePopulationElements[6]);
               i2de := Pos('</video>',SHTML);
               sLine := Copy(sHTML ,i1st ,i2de + length('</video>')) ;
               Delete(sHTML,1,i2de+length('</video>')-1);  //kry einde van video element
              end;

            if (sValue = '<video') OR (sValue = '<audio') OR (sValue = '<img') OR (sValue = '<iframe') OR (sValue = '<p') then
            begin
             arrCourseContent[ilast].TextFormat := [tfWordBreak,tfEndEllipsis,tfNextAlignment];
             arrCourseContent[ilast].tfAlignment := tfNextAlignment;
             arrCourseContent[ilast].shref := sNextHref; //indien Href bestaan haal dit uit
             sNextHref := '';

                     if (sValue = '<iframe') OR (sValue = '<img') then
                      begin            //indien iframe
                       i1st := Pos('src="',sLine) + length('src="');
                       i2de := Pos('" width=',sLine);  //kry source teks
                       arrCourseContent[ilast].ssource := Copy(sLine,i1st,i2de-i1st);

                       i1st := Pos('width="',sLine) + length('width="');
                       i2de := Pos('" height=',sLine);   //kry width teks
                       arrCourseContent[ilast].idispwidth := strtoint(Copy(sLine,i1st,i2de-i1st));

                       i1st := Pos('height=',sLine) + length('height=') +1;
                       i2de := Pos('" title=',sLine);        //kry height teks van die komponent
                       arrCourseContent[ilast].idispHeight := strtoint(Copy(sLine,i1st,i2de-i1st));

                       i1st := Pos('title="',sLine) + length('title="');
                       if (sValue = '<iframe') then  //indien iframe , kry eind posisie
                         i2de := Pos('">',sLine);
                       if (sValue = '<img') then    //indien image , kry eind posisie
                         i2de := Pos('"/>',sLine);

                       arrCourseContent[ilast].Caption := (Copy(sLine,i1st,i2de-i1st)); //Stel kapsie van die Element
                      end;


                     if (Pos('<video',sLine) > 0) OR (Pos('<audio',sLine) > 0) then
                       begin         //indien dit vidoe of audio is
                        i1st := Pos('src="',sLine) + length('src="');
                        i2de := Pos('" type=',sLine);       //kry die source
                        arrCourseContent[ilast].ssource := Copy(sLine,i1st,i2de-i1st);

                         if Pos('<video',sLine) > 0 then
                           begin          //kry die width
                             i1st := Pos('width="',sLine) + length('width="');
                             i2de := Pos('" height=',sLine);
                             arrCourseContent[ilast].idispwidth := strtoint(Copy(sLine,i1st,i2de-i1st));
                                                       //kry die height
                             i1st := Pos('height="',sLine) + length('height="');
                             i2de := Pos('" controls',sLine);//kopieer tot by controls  gedeelte
                             arrCourseContent[ilast].idispheight := strtoint(Copy(sLine,i1st,i2de-i1st));
                           end
                       end;
            end;

             if sValue = '<a' then    //indien dit n hyperlik is
              begin
               i2de := Pos('">',SHTML);
               sLine := Copy(sHTML ,i1st ,i2de + length('">')) ;
               Delete(sHTML,1,i2de+length('">')-1);  //koppieer hyperlike teks

               i1st := Pos('<a href="',sLine) + length('<a href="');
               i2de := Pos('">',sLine);               //kry hyperlik teks
               sNextHref := Copy(sLine,i1st,i2de-i1st);

              end;

             if sValue = '<div' then
              begin         //kry die div leer
               i2de := Pos('">',SHTML);
               sLine := Copy(sHTML ,i1st ,i2de + length('">')) ;
               Delete(sHTML,1,i2de+length('">')-1);

               i1st := Pos('<div align="',sLine) + length('<div align="');
               i2de := Pos('">',sLine);      //kry die div alignment
               if Copy(sLine,i1st,i2de-i1st) = 'center' then
               tfNextAlignment := tfCenter
               else if Copy(sLine,i1st,i2de-i1st) = 'right' then
               tfNextAlignment := tfRight
               else
               tfNextAlignment := tfLeft;


              end;



             if sValue = '<EXITCODE>' then  //indien ExitCode
               sHTML := '';                   //Stel sHTML na false
          end;



      finally
       CloseFile(txtfile);  //maak teksleer toe
      end;
    end;

    OrganiseElementsInOutput(); //herorganiseer data in uitset
    OpenCourseProperties(Self);//maak die Course Propeties menu oop

  end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.SaveAndViewCourse(Sender : Tobject); //Save en view die kursus in die webblad
const
TemporaryPath = 'Temporary_Course_Browser_view_(ThisFileWillBeDeleted)';
var
 ShellInfo : TShellExecuteInfo;
 ExitCode : DWORD;  //SHell Execute
 oldCaption : string;
 begin

   oldCaption :=  CourseMainFileElement.Caption   ;
   CourseMainFileElement.Caption := TemporaryPath;
   (Sender as TJHBGraphicControl).Tag := 1;
   TranslateCourseContenttoHTML(Sender);     //Save die kurus

   CourseMainFileElement.Caption  := oldCaption;

   FillChar(ShellInfo, SizeOf(SHellInfo), 0); //fill die SHellInfo
   SHellInfo.cbSize := SizeOf(TShellExecuteInfo);  //Stel die check Block se size
   ShellInfo.fMask :=  SEE_MASK_NOCLOSEPROCESS;   //Stel die file mask
   ShellInfo.Wnd := 0;//stel die window
   ShellInfo.lpFile := PChar('Saved Courses\'+TemporaryPath + '.html'); //stel file om te run
   ShellInfo.nShow := SW_SHOWNORMAL;  //stel show metode

  if SHellExecuteEX(@ShellInfo) then   //execute die shell script
    begin
       repeat
         Application.ProcessMessages;
         GetExitCodeProcess(SHellInfo.hProcess, ExitCode);   //Edit the Exit Process
       until (ExitCode <> STILL_ACTIVE); //Tell ExitCode indien STILL_Active
        // DeleteFile(Temporarypath+'.html');
    end;

 end;/////////////////////////////////////////////////////////////////////////////////////////\
///////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.PublishbtnMouseUpInteract(Sender : Tobject; Button : TMouseButton; Shift : TShiftState; X , Y : integer);
 begin
   if Button = mbleft then
    PublishCourse(Sender);  //Indien links muis , publiseer kursus
   if Button = mbRight then
    PublishPopupMenu(Sender); //Indien regs muis , maak Puliseer popup menu oop
 end;
////////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.PublishPopupMenu(Sender: TObject);//maak die publihs menu
var
 Popup : TPopupMenu;
 PublishSrcFileMenuItem : TMenuItem;
 CloseMenuItem : TMenuItem;
 begin
   Popup := TPopupMenu.Create(nil);   //maak pop-up menu
    begin
      PublishSrcFileMenuItem := TMenuItem.Create(Popup);//Maak menu Item vir publish no checking
        with PublishSrcFileMenuItem do
          begin
            Caption := 'Publish Course Source File (No error checking)';
            tag := 344;
            OnClick := PublishCourse;    //Publiseer kursus met tag 344
          end;
       CloseMenuItem := TMenuItem.Create(Popup);//Maak close item
         with CloseMenuItem do
          begin
            Caption := 'Close';
          end;
      Popup.Items.Add(PublishSrcFileMenuItem);   //Sit items by die popup menu
      Popup.Items.Add(CloseMenuItem);
      popup.Popup(Mouse.CursorPos.X , Mouse.CursorPos.y );  //maak popup menu by die
    end;
 end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TCourse.PublishCourse(Sender : TObject); //publiseer kursus in databasis
const
SOURCEFILEPUBLISH = 344;
var
sfilename : string;
scourseimg : string;
begin

if Length(arrCourseContent) <= 0 then     //indien lengte < 0 dan exit
exit;

if CourseMainFileElement.Caption = '' then  //toets of daar naam gegee is
 begin
   Messagedlg('Your Course needs a name !' , mtWarning , [mbOk] , 0);
   exit;  //indien fals Exit
 end;

 if (Sender is TMenuItem) then//indien sender n Menu Item is
   begin
   if (Sender as TMenuItem).Tag = SOURCEFILEPUBLISH then   //indien tag = 344
    sfilename := Main.FileSelectDialog('Select Course File','Text Files|*.html;*.htm') ;
   end    //maak file dialog oop
   else
   begin
    TranslateCourseContentTOHTML(Self);    //save kursus af HTML
    sfilename := 'Saved Courses/'+CourseMainFileElement.Caption + '.html';   //SAVE KURSUS
   end;



 scourseimg := CourseMainFileElement.ssource;//kry Source image se pad as .source
 if sfilename <> '' then
    begin
      DB.PublishCourse(CourseMainFileElement.Caption , sfilename , scourseimg); //publuseer kursus
    end;

end;
//////////////////////////////////////////////////////////////////////////////////////////
//........................................................................................
//             TDB
//........................................................................................
function TDB.CompareLoginDetails(sUsername , sPassword , sEmail : string) : boolean;//Compare info to see if on same record
begin
 with Self.tblusr do
  begin
    First;
    while NOT (eof) do//while not end of DataBase
     begin
       if ((tblusr['Username'] = sUsername) AND (tblusr['Password'] = sPassword))  OR ((tblusr['Username'] = sUsername) AND (tblusr['EmailAdress'] = sEmail)) then
         begin     //check if all 3 fields match
           result := true;
           exit;          //if true exit procedure
         end;
       Next;
     end;
     result := false; //if not found , return false
  end;
end;
///////////////////////////////////////////////////////////////////////////////////////////
function TDB.SearchDB(table , field , value : string) : integer;  //search the DAtabase
begin
  RunSQLQuery(DB.qry , ['SELECT '+ field +' FROM '+ table +' WHERE '+ field +' = '+'"'+value+'"' ]);
  Self.qry.Open;
  Self.qry.First;    //show first
  Result := self.qry.RecordCount; //return amout of reccords found :: 1 expected else dupicate record
end;
/////////////////////////////////////////////////////////////////////////////////////////
procedure TDB.RunSQLQuery(funcqry : TADOQUERY ;SQLStatements : array of string); //Runs a Series of Querys
var
icount : integer;
begin
  funcqry.Close;   //close and re-do SQL
  funcqry.SQL.Clear;
  for icount := low(SQLStatements) to high(SQLStatements) do //loop trough SQL statements
  funcqry.SQL.add(SQLStatements[icount]);
  funcqry.ExecSQL;       //execute the final query
end;
///////////////////////////////////////////////////////////////////////////////////////
procedure TDB.PublishCourse(scoursename , sfilepath , simgPath : string);   //publihs course in data base
const
PLACEHOLDIMGPATH = 'Icons/PlaceHold.jpg'; //expected path to Placeholder icon
var
 binsert : boolean;
begin
// Showmessage('PUBLISHING COURSE : ' + sfilepath);
 //tblCourse -> CourseID , CreatorName , Cost , CourseFile;
 bInsert := true;
  with Self.tblCourse do
  begin
    First;
    while NOT(TblCourse.eof) do
     begin
         if tblCourse['CourseID'] = scoursename then //if courde is Database exists And Name is linked
            if tblCourse['CreatorName'] = Main.sUserName then
              begin        //if owner of course , van override current course
                 if Messagedlg('This Course Exists And you are the Owner , do you want to OverWrite Current Course ?' , mtWarning , [mbYes , mbNo] , 0) = mrYes then
                   begin
                     bInsert := false;
                     break;
                   end;
              end
            else
                begin        //if not owner cannot override course
                   Messagedlg('This Course Exists And you are NOT the Owner' , mtWarning , [mbok] , 0);
                   exit;
                end;
        Next;
     end;
   end;

  if (bInsert = true) then//if insert is true (entering new course)
  tblCourse.Insert
  else
  tblCourse.Edit;
  tblCourse['CourseID'] := sCourseName;        //Set Database CourseID = sCourseName
  tblCourse['CreatorName'] := Main.sUserName;
  if NOT(FileExists(sFilePath)) then    //Check if the CouseFile Exists
   begin
     Main.TempPopupDlg('CourseFile does not Exists',1);  //Temporary popup to inform
     Exit;
   end;
  (tblCourse.FieldByName('CourseFile') as tblobfield).loadfromfile(sFilepath);
  if FileExists(sImgPath) AND (simgPath <> '') then  //Save the Image of the Course AS a TBlobField
  (tblCourse.FieldByName('CourseImage') as tblobfield).loadfromfile(simgPath)
  else            //If there is no image specified , Save Image PLACEGOLDER
  (tblCourse.FieldByName('CourseImage') as tblobfield).loadfromfile(GetCurrentDir+'/'+PLACEHOLDIMGPATH);
  DB.tblCourse.Post;     //Post to Database

  Main.TempPopupDlg('Course Successfully Published',1);//Temporary popup Dialog to show that Course is Published
end;
//////////////////////////////////////////////////////////////////////////////////////////
procedure TDB.DisplayData(dispqry: TADOQuery);
 var
 dispfrm : TForm;
 dbg : TDBGrid;
 btn : TButton;
 dtsrc : TDataSource;
 begin
  dispfrm := TForm.Create(nil);  //Create new form to display on
    with dispfrm do
       begin
         Position := poScreenCenter;
         Caption := 'Display Data';
         Width := 1000;
         Height := 500;
       end;
  dbg := TDBGrid.Create(nil);//Maak database Grid om inligting te vertoon
     with dbg do
        begin
          parent := dispfrm;
          Left := 4;
          Top := 4;
          Width := dispfrm.Width - 3*(LEft) - 100;
          Height := dispfrm.Height - 3*(top) - 100;
          dtsrc := TDataSource.Create(nil); //maak nuwe data soruce
          dtsrc.DataSet := dispqry; //Stel data set = aan die Parameter Display query
          dtsrc.Enabled  := true;
          dispqry.Active := true;   //stel aktief
          DataSource := dtsrc;         //stel Datrabase Grid se data source = aan query se dataSoruce
          Columns[0].Width := 100;      //stel die Columns se wydte
          Columns[1].Width := 100;
          Columns[2].Width := 100;
        end;

   btn := TButton.Create(nil); //Maak button om die form toe te maak
     with btn do
       begin
         parent := dispfrm;
         ModalResult := 5;
         top := dispfrm.Height -height-50;
         left := 4;
         Caption := 'Done';
       end;

   if dispfrm.ShowModal = 5 then   //show modal , indien 5 gepaas word , maak toe
    begin

    end;
 end;
/////////////////////////////////////////////////////////////////////////////////////////
constructor TDB.Create(Databasename , ConnectionString : string);
begin
Self.fname := Databasename;
Self.Con := TADOConnection.Create(nil);      //maak Databasis konneksie
Self.tblusr := TADOTable.Create(nil);          //maak users tabel
Self.tblcourse := TADOTable.Create(nil);       //maak courses tabel
Self.tblOwnedcourses := TADOTable.Create(nil);  //maak OwnedCourses Tabel
Self.qry := TADOQuery.Create(nil);          //maak ALgemene query

Self.Con.ConnectionString := ConnectionString; //konnekteer die konnksie
Self.Con.LoginPrompt := false;      //stel die login prompt af
Self.Con.Open; //maak die konneksie oop

Self.tblusr.Connection := Self.Con;   //konekteer Die gebruikers tabel komponent aan die databasis
Self.tblusr.TableName := 'tblusr'; //Konnekteer gebruikers tabel kompoment aan gebruikers tabel in databasis
Self.tblusr.Open;  //maak die gebruikers tabel oop

Self.tblcourse.Connection := Self.Con;   //konekteer Die gebruikers tabel komponent aan die databasis
Self.tblcourse.TableName := 'tblcourse'; //Konnekteer gebruikers tabel kompoment aan gebruikers tabel in databasis
Self.tblcourse.Open;  //maak die gebruikers tabel oop

Self.tblOwnedCourses.Connection := Self.Con; //konekteer Die gebruikers tabel komponent aan die databasis
Self.tblOwnedCourses.TableName := 'tblOwnedCourses'; //Konnekteer gebruikers tabel kompoment aan gebruikers tabel in databasis
Self.tblOwnedCourses.Open;               //maak die gebruikers tabel oop

Self.qry.Connection := Self.Con;     //stel die konneksie van die query
Self.qry.Close;      //maak die query toe sodat die SQL parmameter verander kan word
end;
///////////////////////////////////////////////////////////////////////////////////////////////////
destructor TDB.destroy;  //Vernietig die databasis komponent
begin
  freeandnil(Con);      //Maak al die databasis komponente skoon
  freeandnil(tblusr);
  freeandnil(tblcourse);
  freeandnil(tblOwnedcourses);
  freeandnil(qry);
  inherited;//DIe destuctor inherit vna die standaard Tobject Desturctor AF
end;
///////////////////////////////////////////////////////////////////////////////////////////
//........................................................................................
//             TJHBGraphicControl
//........................................................................................
/////////////////////////////////////////////////////////////////////////////////////////
procedure TJHBGraphicControl.Paint;
var         //Render die Grafiese komponent op die skerm
 TextRect : TRect;
begin
  inherited;
 if length(GraphKoordinates) > 0 then
    begin
     Canvas.Pen.Color := Canvas.Pen.Color;
     Canvas.Brush.Color := Canvas.Brush.Color;  //Kopieer die die inligting terug (Back Buffer) sodat dit gerender kan word
     Canvas.Brush.Style := Canvas.Brush.Style;
     Canvas.Pen.Width := Canvas.Pen.Width;
       case byGraphicShape of     //kyk wat die form is
        gsRectangle : Self.Canvas.Rectangle(Self.GraphKoordinates[0].X,Self.GraphKoordinates[0].Y,Self.GraphKoordinates[1].X,Self.GraphKoordinates[1].Y);
        gsEllipse : Self.Canvas.Ellipse(Self.GraphKoordinates[0].X,Self.GraphKoordinates[0].Y,Self.GraphKoordinates[1].X,Self.GraphKoordinates[1].Y);
        gsRoundRect : Self.Canvas.RoundRect(Self.GraphKoordinates[0].X,Self.GraphKoordinates[0].Y,Self.GraphKoordinates[1].X,Self.GraphKoordinates[1].Y,Self.GraphKoordinates[2].X,Self.GraphKoordinates[2].Y);
        gsPolygon : Self.Canvas.Polygon(GraphKoordinates);   //Stel koordinate om n spesifieke form te render
        else
         showmessage('no graphic shape defined');    //indien geen grafika gestel is nie
       end;
   end else
   showmessage('no Graphic koordinates provided');//indien geen koordinate gestel is nie

 if length(TextKoordinates) > 0 then    //kyk of daar well koordinate is
    begin
       Canvas.Font.Name := Canvas.Font.Name;
       Canvas.Font.Color := Canvas.Font.Color;   //Kopieer die die inligting terug (Back Buffer) sodat dit gerender kan word
       Canvas.Font.Style := Canvas.Font.Style;
       Canvas.Font.Size := Canvas.Font.Size;
        with TextRect do
         begin
           TextRect.TopLeft := Self.TextKoordinates[0];  //maak die top een van die teks Koordinaat 1
           //DefTextFormats := [tfCenter,tfEndEllipsis] ;
           TextRect.BottomRight := Self.TextKoordinates[1];//maak die top een van die teks Koordinaat 2
         end;
       Canvas.TextRect(TextRect,Self.Caption,TextFormat);  //maak die Text reghoek om gerender te word

       //Canvas.TextOut(Canvas.PenPos.X , Canvas.PenPos.Y , Self.Caption );
    end else
    showmessage('No Text Koordinates provided'); //indien geen teks koordinate gestel is nie

end;
////////////////////////////////////////////////////////////////////////////////////
procedure TJHBGraphicControl.SetGraphic(_Koordinate : PointArr; _graphicshape : byte; _BrushColor : tColor; _BrushStyle : TBrushStyle;  _PenColor : TColor; _PenWidth : integer);
var                   //stel die grafiese waardes
  icount: Integer;
 begin
   if length(_Koordinate) < 2 then  //kyk of daar 2 of meer koordinate is
    begin
      showmessage(inttostr(length(_Koordinate)) + ': not enough koordinates');
      exit; //indien minder 2 , exit die procedure
    end;
//showmessage(inttostr(_koordinate[0].x) + ',' + inttostr(_koordinate[0].y) + ',' + inttostr(_koordinate[1].x) + ',' + inttostr(_koordinate[1].y) + ',' + inttostr(_koordinate[2].x) + ',' + inttostr(_koordinate[2].y) + ','  + inttostr(_koordinate[3].x) + ',');
    with Self do
     begin
     byGraphicShape :=  _graphicshape;
     Canvas.Pen.Color := _PenColor;
     Canvas.Brush.Color := _BrushColor;  //stel die wardes gelyk aan die wat paramets wat inligting voorsien
     Canvas.Brush.Style := _BrushStyle;
     Canvas.Pen.Width := _PenWidth;
     end;
    Setlength(Self.GraphKoordinates , length(_Koordinate)); //Set die lengte koordinates gelyk aan totaal nodig
    for icount := 0 to length(_Koordinate)-1 do
     begin
       Self.GraphKoordinates[icount] := _Koordinate[icount];
       //showmessage(inttostr(Self.Graphics.Koordinates[icount].X) + ',' + inttostr(Self.Graphics.Koordinates[icount].Y));
     end;
 end;
///////////////////////////////////////////////////////////////////////////////////////
procedure TJHBGraphicControl.SetText(p_FontName : string; p_FontColor : TColor; p_FontStyles : TFontStyles;p_TextFormat : TTextFormat ; p_FontSize : integer; _Koordinate : PointArr);
Var               //stel die teks waardes
icount : integer;
 begin
    with Self do
     begin
       Canvas.Font.Name := p_FontName;
       Canvas.Font.Color := p_FontColor;
       Canvas.Font.Style := p_FontStyles; //Stel Die waardes gelyk aan die parameters gegee
       TextFormat := p_TextFormat;
       Canvas.Font.Size := p_FontSize;
     Setlength(Self.TextKoordinates , length(_Koordinate));   //stel lengte van koordinate na parameters lengte
    for icount := 0 to length(_Koordinate)-1 do
     begin
       Self.TextKoordinates[icount] := _Koordinate[icount];    //stel gelyk
       //showmessage(inttostr(Self.Graphics.Koordinates[icount].X) + ',' + inttostr(Self.Graphics.Koordinates[icount].Y));
     end;
     end;
 end;
//////////////////////////////////////////////////////////////////////////////////////
function TJHBGraphicControl.IntArrTOPointArr(intarr : array of integer) : pointarr;
var               //skakel Array van Integers om na n array van Koordinates
  icount: Integer;
 begin
   if odd(length(intarr)) then  //moet ewe getal wees om punte te vind (Altyd 2D verwag)
    begin
      showmessage('intarr is ODD , points cannot be derived');
      exit;
    end;
    setlength(result , length(intarr) DIV 2);//Maak lengte van punt array
   for icount := 0 to (length(intarr) DIV 2) -1 do
   begin
    Result[icount].x := intarr[(icount*2)];   //Stel elk van die punte gelyk aan wat nodig is
    Result[icount].y := intarr[(icount*2)+1];
   end;
   //showmessage(inttostr(result[0].x) + ',' + inttostr(result[0].y) + ',' +inttostr(result[1].x)+ ',' + inttostr(result[1].y) + ',' + inttostr(result[2].y) + ',' + inttostr(result[2].x) + ',' + inttostr(result[10].x));
 end;
////////////////////////////////////////////////////////////////////////////////////////
procedure TJHBGraphicControl.JhbbtnColorChange(Sender:Tobject);//Verander kleur van die JHBgraphgicControl
 begin
   if (Sender as TJHBGraphicControl).Canvas.Brush.Color = clskyblue then  //indien SkyBlue maak clbackground
     begin
       (Sender as TJHBGraphicControl).Canvas.Brush.Color:= clbackground;
       (Sender as TJHBGraphicControl).Paint;
     end
   else if (Sender as TJHBGraphicControl).Canvas.Brush.Color = clbackground then  //indien Clbackgroung maak SkyBlue
     begin
        (Sender as TJHBGraphicControl).Canvas.Brush.Color := clskyblue;
        (Sender as TJHBGraphicControl).Paint; //Render die Grafika na die skerm
     end;
 end;
/////////////////////////////////////////////////////////////////////////////////////////
begin
Main := TMain.Create;    //Maak die Main komponent
DB := TDB.Create('PAT2022DB' , CONNECTIONSTRING); //Maak Databasis komponent
Main.AppEntry;  //Begin die Program BY Main.AppEntry prcedure
end.
