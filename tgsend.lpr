program tgsend;

// My dear friends. Below code is very terrible.
// I am not a programmer, but.. it works!

// Copyright 2019 Anton Shevtsov <x09@altlinux.org>

{
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
 }

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads,
  baseunix,
  unix, {$ENDIF} {$ENDIF}
  Classes,
  SysUtils,
  httpsend,
  openssl,
  synacode,
  INIFiles,
  laz_synapse,
  synautil,
  CustApp { you can add units after this };

const
  version: string = '1.3.4';

type

  { TTgSend }

  TTgSend = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    procedure SendMessage;
    procedure SendFile;
    function MimeTypeByExt(const FileName: string): string;
  end;

  { TTgSend }

var
  optArr: array [0..3] of string;
  debug: boolean;
  proxy: string;
  proxy_port: string;
  home, config: string;

const
  conf_path: array [0..3] of string = (
    ('.tgsend/tgsend.conf'),
    ('/etc/tgsend.conf'),
    ('/usr/local/etc/tgsend.conf'),
    ('/opt/tgsend/etc/tgsend.conf'));

const
  MimeTypeCount = 376;
  MimeTypesArray: array [1 .. 376, 1 .. 2] of string =
    (('.nml', 'animation/narrative'),
    ('.aac', 'audio/mp4'),
    ('.aif', 'audio/x-aiff'),
    ('.aifc', 'audio/x-aiff'),
    ('.aiff', 'audio/x-aiff'),
    ('.au', 'audio/basic'),
    ('.gsm', 'audio/x-gsm'),
    ('.kar', 'audio/midi'),
    ('.m3u', 'audio/mpegurl'),
    ('.m4a', 'audio/x-mpg'),
    ('.mid', 'audio/midi'),
    ('.midi', 'audio/midi'),
    ('.mpega', 'audio/x-mpg'),
    ('.mp2', 'audio/x-mpg'),
    ('.mp3', 'audio/x-mpg'),
    ('.mpga', 'audio/x-mpg'),
    ('.m3u', 'audio/x-mpegurl'),
    ('.pls', 'audio/x-scpls'),
    ('.qcp', 'audio/vnd.qcelp'),
    ('.ra', 'audio/x-realaudio'),
    ('.ram', 'audio/x-pn-realaudio'),
    ('.rm', 'audio/x-pn-realaudio'),
    ('.sd2', 'audio/x-sd2'),
    ('.sid', 'audio/prs.sid'),
    ('.snd', 'audio/basic'),
    ('.wav', 'audio/x-wav'),
    ('.wax', 'audio/x-ms-wax'),
    ('.wma', 'audio/x-ms-wma'),
    ('.mjf', 'audio/x-vnd.AudioExplosion.MjuiceMediaFile'),
    ('.art', 'image/x-jg'),
    ('.bmp', 'image/bmp'),
    ('.cdr', 'image/x-coreldraw'),
    ('.cdt', 'image/x-coreldrawtemplate'),
    ('.cpt', 'image/x-corelphotopaint'),
    ('.djv', 'image/vnd.djvu'),
    ('.djvu', 'image/vnd.djvu'),
    ('.gif', 'image/gif'),
    ('.ief', 'image/ief'),
    ('.ico', 'image/x-icon'),
    ('.jng', 'image/x-jng'),
    ('.jpg', 'image/jpeg'),
    ('.jpeg', 'image/jpeg'),
    ('.jpe', 'image/jpeg'),
    ('.pat', 'image/x-coreldrawpattern'),
    ('.pcx', 'image/pcx'),
    ('.pbm', 'image/x-portable-bitmap'),
    ('.pgm', 'image/x-portable-graymap'),
    ('.pict', 'image/x-pict'),
    ('.png', 'image/x-png'),
    ('.pnm', 'image/x-portable-anymap'),
    ('.pntg', 'image/x-macpaint'),
    ('.ppm', 'image/x-portable-pixmap'),
    ('.psd', 'image/x-psd'),
    ('.qtif', 'image/x-quicktime'),
    ('.ras', 'image/x-cmu-raster'),
    ('.rf', 'image/vnd.rn-realflash'),
    ('.rgb', 'image/x-rgb'),
    ('.rp', 'image/vnd.rn-realpix'),
    ('.sgi', 'image/x-sgi'),
    ('.svg', 'image/svg-xml'),
    ('.svgz', 'image/svg-xml'),
    ('.targa', 'image/x-targa'),
    ('.tif', 'image/x-tiff'),
    ('.wbmp', 'image/vnd.wap.wbmp'),
    ('.xbm', 'image/xbm'),
    ('.xbm', 'image/x-xbitmap'),
    ('.xpm', 'image/x-xpixmap'),
    ('.xwd', 'image/x-xwindowdump'),
    ('.323', 'text/h323'),
    ('.xml', 'text/xml'),
    ('.uls', 'text/iuls'),
    ('.txt', 'text/plain'),
    ('.rtx', 'text/richtext'),
    ('.wsc', 'text/scriptlet'),
    ('.rt', 'text/vnd.rn-realtext'),
    ('.htt', 'text/webviewhtml'),
    ('.htc', 'text/x-component'),
    ('.vcf', 'text/x-vcard'),
    ('.asf', 'video/x-ms-asf'),
    ('.asx', 'video/x-ms-asf'),
    ('.avi', 'video/x-msvideo'),
    ('.dl', 'video/dl'),
    ('.dv', 'video/dv'),
    ('.flc', 'video/flc'),
    ('.fli', 'video/fli'),
    ('.gl', 'video/gl'),
    ('.lsf', 'video/x-la-asf'),
    ('.lsx', 'video/x-la-asf'),
    ('.mng', 'video/x-mng'),
    ('.mp2', 'video/mpeg'),
    ('.mp3', 'video/mpeg'),
    ('.mp4', 'video/mpeg'),
    ('.mpeg', 'video/x-mpeg2a'),
    ('.mpa', 'video/mpeg'),
    ('.mpe', 'video/mpeg'),
    ('.mpg', 'video/mpeg'),
    ('.moov', 'video/quicktime'),
    ('.mov', 'video/quicktime'),
    ('.mxu', 'video/vnd.mpegurl'),
    ('.qt', 'video/quicktime'),
    ('.qtc', 'video/x-qtc'),
    ('.rv', 'video/vnd.rn-realvideo'),
    ('.ivf', 'video/x-ivf'),
    ('.wm', 'video/x-ms-wm'),
    ('.wmp', 'video/x-ms-wmp'),
    ('.wmv', 'video/x-ms-wmv'),
    ('.wmx', 'video/x-ms-wmx'),
    ('.wvx', 'video/x-ms-wvx'),
    ('.rms', 'video/vnd.rn-realvideo-secure'),
    ('.asx', 'video/x-ms-asf-plugin'),
    ('.movie', 'video/x-sgi-movie'),
    ('.7z', 'application/x-7z-compressed'),
    ('.a', 'application/x-archive'),
    ('.aab', 'application/x-authorware-bin'),
    ('.aam', 'application/x-authorware-map'),
    ('.aas', 'application/x-authorware-seg'),
    ('.abw', 'application/x-abiword'),
    ('.ace', 'application/x-ace-compressed'),
    ('.ai', 'application/postscript'),
    ('.alz', 'application/x-alz-compressed'),
    ('.ani', 'application/x-navi-animation'),
    ('.arj', 'application/x-arj'),
    ('.asf', 'application/vnd.ms-asf'),
    ('.bat', 'application/x-msdos-program'),
    ('.bcpio', 'application/x-bcpio'),
    ('.boz', 'application/x-bzip2'),
    ('.bz', 'application/x-bzip'),
    ('.bz2', 'application/x-bzip2'),
    ('.cab', 'application/vnd.ms-cab-compressed'),
    ('.cat', 'application/vnd.ms-pki.seccat'),
    ('.ccn', 'application/x-cnc'),
    ('.cco', 'application/x-cocoa'),
    ('.cdf', 'application/x-cdf'),
    ('.cer', 'application/x-x509-ca-cert'),
    ('.chm', 'application/vnd.ms-htmlhelp'),
    ('.chrt', 'application/vnd.kde.kchart'),
    ('.cil', 'application/vnd.ms-artgalry'),
    ('.class', 'application/java-vm'),
    ('.com', 'application/x-msdos-program'),
    ('.clp', 'application/x-msclip'),
    ('.cpio', 'application/x-cpio'),
    ('.cpt', 'application/mac-compactpro'),
    ('.cqk', 'application/x-calquick'),
    ('.crd', 'application/x-mscardfile'),
    ('.crl', 'application/pkix-crl'),
    ('.csh', 'application/x-csh'),
    ('.dar', 'application/x-dar'),
    ('.dbf', 'application/x-dbase'),
    ('.dcr', 'application/x-director'),
    ('.deb', 'application/x-debian-package'),
    ('.dir', 'application/x-director'),
    ('.dist', 'vnd.apple.installer+xml'),
    ('.distz', 'vnd.apple.installer+xml'),
    ('.dll', 'application/x-msdos-program'),
    ('.dmg', 'application/x-apple-diskimage'),
    ('.doc', 'application/msword'),
    ('.dot', 'application/msword'),
    ('.dvi', 'application/x-dvi'),
    ('.dxr', 'application/x-director'),
    ('.ebk', 'application/x-expandedbook'),
    ('.eps', 'application/postscript'),
    ('.evy', 'application/envoy'),
    ('.exe', 'application/x-msdos-program'),
    ('.fdf', 'application/vnd.fdf'),
    ('.fif', 'application/fractals'),
    ('.flm', 'application/vnd.kde.kivio'),
    ('.fml', 'application/x-file-mirror-list'),
    ('.gzip', 'application/x-gzip'),
    ('.gnumeric', 'application/x-gnumeric'),
    ('.gtar', 'application/x-gtar'),
    ('.gz', 'application/x-gzip'),
    ('.hdf', 'application/x-hdf'),
    ('.hlp', 'application/winhlp'),
    ('.hpf', 'application/x-icq-hpf'),
    ('.hqx', 'application/mac-binhex40'),
    ('.hta', 'application/hta'),
    ('.ims', 'application/vnd.ms-ims'),
    ('.ins', 'application/x-internet-signup'),
    ('.iii', 'application/x-iphone'),
    ('.iso', 'application/x-iso9660-image'),
    ('.jar', 'application/java-archive'),
    ('.karbon', 'application/vnd.kde.karbon'),
    ('.kfo', 'application/vnd.kde.kformula'),
    ('.kon', 'application/vnd.kde.kontour'),
    ('.kpr', 'application/vnd.kde.kpresenter'),
    ('.kpt', 'application/vnd.kde.kpresenter'),
    ('.kwd', 'application/vnd.kde.kword'),
    ('.kwt', 'application/vnd.kde.kword'),
    ('.latex', 'application/x-latex'),
    ('.lha', 'application/x-lzh'),
    ('.lcc', 'application/fastman'),
    ('.lrm', 'application/vnd.ms-lrm'),
    ('.lz', 'application/x-lzip'),
    ('.lzh', 'application/x-lzh'),
    ('.lzma', 'application/x-lzma'),
    ('.lzo', 'application/x-lzop'),
    ('.lzx', 'application/x-lzx'),
    ('.m13', 'application/x-msmediaview'),
    ('.m14', 'application/x-msmediaview'),
    ('.mpp', 'application/vnd.ms-project'),
    ('.mvb', 'application/x-msmediaview'),
    ('.man', 'application/x-troff-man'),
    ('.mdb', 'application/x-msaccess'),
    ('.me', 'application/x-troff-me'),
    ('.ms', 'application/x-troff-ms'),
    ('.msi', 'application/x-msi'),
    ('.mpkg', 'vnd.apple.installer+xml'),
    ('.mny', 'application/x-msmoney'),
    ('.nix', 'application/x-mix-transfer'),
    ('.o', 'application/x-object'),
    ('.oda', 'application/oda'),
    ('.odb', 'application/vnd.oasis.opendocument.database'),
    ('.odc', 'application/vnd.oasis.opendocument.chart'),
    ('.odf', 'application/vnd.oasis.opendocument.formula'),
    ('.odg', 'application/vnd.oasis.opendocument.graphics'),
    ('.odi', 'application/vnd.oasis.opendocument.image'),
    ('.odm', 'application/vnd.oasis.opendocument.text-master'),
    ('.odp', 'application/vnd.oasis.opendocument.presentation'),
    ('.ods', 'application/vnd.oasis.opendocument.spreadsheet'),
    ('.ogg', 'application/ogg'),
    ('.odt', 'application/vnd.oasis.opendocument.text'),
    ('.otg', 'application/vnd.oasis.opendocument.graphics-template'),
    ('.oth', 'application/vnd.oasis.opendocument.text-web'),
    ('.otp', 'application/vnd.oasis.opendocument.presentation-template'),
    ('.ots', 'application/vnd.oasis.opendocument.spreadsheet-template'),
    ('.ott', 'application/vnd.oasis.opendocument.text-template'),
    ('.p10', 'application/pkcs10'),
    ('.p12', 'application/x-pkcs12'),
    ('.p7b', 'application/x-pkcs7-certificates'),
    ('.p7m', 'application/pkcs7-mime'),
    ('.p7r', 'application/x-pkcs7-certreqresp'),
    ('.p7s', 'application/pkcs7-signature'),
    ('.package', 'application/vnd.autopackage'),
    ('.pfr', 'application/font-tdpfr'),
    ('.pkg', 'vnd.apple.installer+xml'),
    ('.pdf', 'application/pdf'),
    ('.pko', 'application/vnd.ms-pki.pko'),
    ('.pl', 'application/x-perl'),
    ('.pnq', 'application/x-icq-pnq'),
    ('.pot', 'application/mspowerpoint'),
    ('.pps', 'application/mspowerpoint'),
    ('.ppt', 'application/mspowerpoint'),
    ('.ppz', 'application/mspowerpoint'),
    ('.ps', 'application/postscript'),
    ('.pub', 'application/x-mspublisher'),
    ('.qpw', 'application/x-quattropro'),
    ('.qtl', 'application/x-quicktimeplayer'),
    ('.rar', 'application/rar'),
    ('.rdf', 'application/rdf+xml'),
    ('.rjs', 'application/vnd.rn-realsystem-rjs'),
    ('.rm', 'application/vnd.rn-realmedia'),
    ('.rmf', 'application/vnd.rmf'),
    ('.rmp', 'application/vnd.rn-rn_music_package'),
    ('.rmx', 'application/vnd.rn-realsystem-rmx'),
    ('.rnx', 'application/vnd.rn-realplayer'),
    ('.rpm', 'application/x-redhat-package-manager'),
    ('.rsml', 'application/vnd.rn-rsml'),
    ('.rtsp', 'application/x-rtsp'),
    ('.rss', 'application/rss+xml'),
    ('.scm', 'application/x-icq-scm'),
    ('.ser', 'application/java-serialized-object'),
    ('.scd', 'application/x-msschedule'),
    ('.sda', 'application/vnd.stardivision.draw'),
    ('.sdc', 'application/vnd.stardivision.calc'),
    ('.sdd', 'application/vnd.stardivision.impress'),
    ('.sdp', 'application/x-sdp'),
    ('.setpay', 'application/set-payment-initiation'),
    ('.setreg', 'application/set-registration-initiation'),
    ('.sh', 'application/x-sh'),
    ('.shar', 'application/x-shar'),
    ('.shw', 'application/presentations'),
    ('.sit', 'application/x-stuffit'),
    ('.sitx', 'application/x-stuffitx'),
    ('.skd', 'application/x-koan'),
    ('.skm', 'application/x-koan'),
    ('.skp', 'application/x-koan'),
    ('.skt', 'application/x-koan'),
    ('.smf', 'application/vnd.stardivision.math'),
    ('.smi', 'application/smil'),
    ('.smil', 'application/smil'),
    ('.spl', 'application/futuresplash'),
    ('.ssm', 'application/streamingmedia'),
    ('.sst', 'application/vnd.ms-pki.certstore'),
    ('.stc', 'application/vnd.sun.xml.calc.template'),
    ('.std', 'application/vnd.sun.xml.draw.template'),
    ('.sti', 'application/vnd.sun.xml.impress.template'),
    ('.stl', 'application/vnd.ms-pki.stl'),
    ('.stw', 'application/vnd.sun.xml.writer.template'),
    ('.svi', 'application/softvision'),
    ('.sv4cpio', 'application/x-sv4cpio'),
    ('.sv4crc', 'application/x-sv4crc'),
    ('.swf', 'application/x-shockwave-flash'),
    ('.swf1', 'application/x-shockwave-flash'),
    ('.sxc', 'application/vnd.sun.xml.calc'),
    ('.sxi', 'application/vnd.sun.xml.impress'),
    ('.sxm', 'application/vnd.sun.xml.math'),
    ('.sxw', 'application/vnd.sun.xml.writer'),
    ('.sxg', 'application/vnd.sun.xml.writer.global'),
    ('.t', 'application/x-troff'),
    ('.tar', 'application/x-tar'),
    ('.tcl', 'application/x-tcl'),
    ('.tex', 'application/x-tex'),
    ('.texi', 'application/x-texinfo'),
    ('.texinfo', 'application/x-texinfo'),
    ('.tbz', 'application/x-bzip-compressed-tar'),
    ('.tbz2', 'application/x-bzip-compressed-tar'),
    ('.tgz', 'application/x-compressed-tar'),
    ('.tlz', 'application/x-lzma-compressed-tar'),
    ('.tr', 'application/x-troff'),
    ('.trm', 'application/x-msterminal'),
    ('.troff', 'application/x-troff'),
    ('.tsp', 'application/dsptype'),
    ('.torrent', 'application/x-bittorrent'),
    ('.ttz', 'application/t-time'),
    ('.txz', 'application/x-xz-compressed-tar'),
    ('.udeb', 'application/x-debian-package'),
    ('.uin', 'application/x-icq'),
    ('.urls', 'application/x-url-list'),
    ('.ustar', 'application/x-ustar'),
    ('.vcd', 'application/x-cdlink'),
    ('.vor', 'application/vnd.stardivision.writer'),
    ('.vsl', 'application/x-cnet-vsl'),
    ('.wcm', 'application/vnd.ms-works'),
    ('.wb1', 'application/x-quattropro'),
    ('.wb2', 'application/x-quattropro'),
    ('.wb3', 'application/x-quattropro'),
    ('.wdb', 'application/vnd.ms-works'),
    ('.wks', 'application/vnd.ms-works'),
    ('.wmd', 'application/x-ms-wmd'),
    ('.wms', 'application/x-ms-wms'),
    ('.wmz', 'application/x-ms-wmz'),
    ('.wp5', 'application/wordperfect5.1'),
    ('.wpd', 'application/wordperfect'),
    ('.wpl', 'application/vnd.ms-wpl'),
    ('.wps', 'application/vnd.ms-works'),
    ('.wri', 'application/x-mswrite'),
    ('.xfdf', 'application/vnd.adobe.xfdf'),
    ('.xls', 'application/x-msexcel'),
    ('.xlb', 'application/x-msexcel'),
    ('.xpi', 'application/x-xpinstall'),
    ('.xps', 'application/vnd.ms-xpsdocument'),
    ('.xsd', 'application/vnd.sun.xml.draw'),
    ('.xul', 'application/vnd.mozilla.xul+xml'),
    ('.z', 'application/x-compress'),
    ('.zoo', 'application/x-zoo'),
    ('.zip', 'application/x-zip-compressed'),
    ('.wbmp', 'image/vnd.wap.wbmp'),
    ('.wml', 'text/vnd.wap.wml'),
    ('.wmlc', 'application/vnd.wap.wmlc'),
    ('.wmls', 'text/vnd.wap.wmlscript'),
    ('.wmlsc', 'application/vnd.wap.wmlscriptc'),
    ('.asm', 'text/x-asm'),
    ('.p', 'text/x-pascal'),
    ('.pas', 'text/x-pascal'),
    ('.cs', 'text/x-csharp'),
    ('.c', 'text/x-csrc'),
    ('.c++', 'text/x-c++src'),
    ('.cpp', 'text/x-c++src'),
    ('.cxx', 'text/x-c++src'),
    ('.cc', 'text/x-c++src'),
    ('.h', 'text/x-chdr'),
    ('.h++', 'text/x-c++hdr'),
    ('.hpp', 'text/x-c++hdr'),
    ('.hxx', 'text/x-c++hdr'),
    ('.hh', 'text/x-c++hdr'),
    ('.java', 'text/x-java'),
    ('.css', 'text/css'),
    ('.js', 'text/javascript'),
    ('.htm', 'text/html'),
    ('.html', 'text/html'),
    ('.ls', 'text/javascript'),
    ('.mocha', 'text/javascript'),
    ('.shtml', 'server-parsed-html'),
    ('.xml', 'text/xml'),
    ('.sgm', 'text/sgml'),
    ('.sgml', 'text/sgml'));


  procedure TTgSend.DoRun;
  const
    cmd_options: array [0..3, 0..1] of string = (
      ('t', 'token'),
      ('i', 'chatId'),
      ('m', 'message'),
      ('f', 'file')
      );

  var
    ErrorMsg, _tmpstr1: string;
    _tmpchar1: char;
    x, y: shortint;
    IniF: TINIFile;

    // 0 - token
    // 1 - chatid
    // 2 - message
    // 3 - file

  begin
    // quick check parameters
    debug := False;
    proxy_port := '8080';
    conf_path[0] := GetUserDir + conf_path[0];

    ErrorMsg := CheckOptions('hf:i:t:m:dp:P:c:C:FAV',
      'help file: chatId: token: message: debug proxy: proxy-port: config: caption: foto audio voice');

    writeln(ErrorMsg);

    if ErrorMsg <> '' then
    begin
      ShowException(Exception.Create(ErrorMsg));
      Terminate;
      Exit;
    end;

    if HasOption('d', 'debug') then
      debug := True;

    if HasOption('c', 'config') then
    begin
      config := GetOptionValue('c', 'config');
      if not FileExists(config) then
      begin
        WriteLn('file not exists: ' + config);
        Terminate;
        Exit;
      end;
    end
    else
    begin
      for x := 0 to 3 do
      begin
        if (debug) then
          writeln('check config file: ' + conf_path[x]);
        if FileExists(conf_path[x]) then
        begin
          config := conf_path[x];
          break;
        end;
      end;
    end;


    if (HasOption('t', 'token') or HasOption('i', 'chatId')) then
    begin
      config := '';
    end;


    if (debug) and (config <> '') then
      WriteLn('use config file: ' + config);

    if (debug) and (config = '') then
      WriteLn('Config file not found. ');

    if (config <> '') then
    begin
      Inif := TINIFile.Create(config);
      _tmpstr1 := INiF.ReadString('Bot', 'token', '');
      if (_tmpstr1 <> '') then
      begin
        optArr[0] := _tmpstr1;
        if (debug) then
          writeln('use token: ' + optArr[0]);
      end;

      _tmpstr1 := IniF.ReadString('Bot', 'chatId', '');
      if (_tmpstr1 <> '') then
      begin
        optArr[1] := _tmpstr1;
        if (debug) then
          writeln('use chatId: ' + optArr[1]);
      end;

      INIf.Free;
    end;

    // parse parameters
    if HasOption('h', 'help') then
    begin
      WriteHelp;
      Terminate;
      Exit;
    end;


{    if ( not HasOption('t', 'token') or
       not HasOption('i', 'chatid') )
    begin
      writeln('Bot token and chat_id is required!');
      terminate;
      exit;
    end;
 }

    if HasOption('p', 'proxy') then
      proxy := GetOptionValue('p', 'proxy');

    if HasOption('P', 'proxy-port') then
      proxy_port := GetOptionValue('P', 'proxy-port');


    for x := 0 to 3 do
    begin
      _tmpchar1 := cmd_options[x, 0][1];
      _tmpstr1 := cmd_options[x, 1];
      if HasOption(_tmpchar1, _tmpstr1) then
      begin
        if optArr[x] = '' then
          optArr[x] := GetOptionValue(_tmpchar1, _tmpstr1);
        if (debug) then
        begin
          writeln('option:' + _tmpchar1);
          writeln('  value:' + optArr[x]);
        end;
      end;
    end;

    if (optArr[0] = '') or (optArr[1] = '') then
    begin
      writeln('Bot token and chat_id is required!');
      terminate;
      exit;
    end;

    if (optArr[2] <> '') then
    begin
      SendMessage;
    end;

    if (optArr[3] <> '') then
    begin
      SendFile;

    end;

    { add your program here }

    // stop program loop
    Terminate;

  end;

  constructor TTgSend.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

  destructor TTgSend.Destroy;
  begin
    inherited Destroy;
  end;



function TTgSend.MimeTypeByExt(const FileName: string): string;
  var
    s: string;
    i: integer;
  begin
    s := lowerCase(ExtractFileExt(FileName));
    for I := 1 to MimeTypeCount do
    begin
      if s = MimeTypesArray[i, 1] then
      begin
        Result := MimeTypesArray[i, 2];
        Exit;
      end;
    end;
    Result := 'application/octet-stream';
  end;



  procedure TTgSend.WriteHelp;
  begin
    { add your help code here }
    writeln('tgsend v' + version);
    writeln('Message/file sender from Bot. Use Telegram Bot API' + LineEnding);
    writeln('Usage: ' + ExeName + ' [options]');
    writeln('option:' + LineEnding + '  -t --token         Bot token (*required)' +
      LineEnding + '  -i --chatId        Unique identifier for the target chat (*required)'
      + LineEnding + '' + LineEnding +
      '  -m --message       Text of message (SendMessage method)' +
      LineEnding + '		OR' + LineEnding +
      '  -f --file          Path of sending file (SendDocument method)' +
      LineEnding + '  -F --foto          Send file as photo (SendPhoto method)' +
      LineEnding + '  -A --audio         Send file as audio (SendAudio method)' +
      LineEnding + '  -V --voice         Send file as voice (SendVoice method)' +
      LineEnding + '  -C --caption       Caption (for Photo/Document/Voice/Audio)' +
      LineEnding + LineEnding + '' + LineEnding +
      '  -c --config        Configuration file path' + LineEnding +
      '                     search order:' + LineEnding +
      '                             ~/.tgsend/tgsend.conf' + LineEnding +
      '                             /etc/tgsend.conf' + LineEnding +
      '                             /usr/local/etc/tgsend.conf' +
      LineEnding + '                             /opt/tgsend/etc/tgsend.conf' +
      LineEnding + '' + LineEnding + '  -d --debug         Debug on' +
      LineEnding + '' + LineEnding + '  -p --proxy         Proxy IP' +
      LineEnding + '  -P --proxy-port    Proxy port (8080 default)' +
      LineEnding + '' + LineEnding + '  -h --help          This help' +
      LineEnding + '' + LineEnding + 'Example:' + LineEnding + '' +
      LineEnding + 'Send ''hello world'' text' + LineEnding +
      'tgsend -t ''12345:AAABBBCCCDDDEEEEFFFF'' --chatId=''12345'' -m ''hello world''' +
      LineEnding + '' + LineEnding + 'Send jpg file with debug' +
      LineEnding +
      'tgsend -t ''12345:AAABBBCCCDDDEEEEFFFF'' --chatId=''12345'' -f /tmp/lo.jpg -d' +
      LineEnding + '' + LineEnding + 'Send jpg file as photo with caption and debug' +
      LineEnding +
      'tgsend -t ''12345:AAABBBCCCDDDEEEEFFFF'' --chatId=''12345'' -F -f /tmp/lo.jpg -C "photo caption" -d' +
      LineEnding + '' + LineEnding + 'Send mp3 file as audio with caption and debug' +
      LineEnding +
      'tgsend -t ''12345:AAABBBCCCDDDEEEEFFFF'' --chatId=''12345'' -A -f /tmp/sample.mp3 -C "audio caption" -d' +
      LineEnding + '' + LineEnding + 'Send voice file (ogg format only) as voice with caption and debug' +
      LineEnding +
      'tgsend -t ''12345:AAABBBCCCDDDEEEEFFFF'' --chatId=''12345'' -V -f /tmp/sample.ogg -C "voice caption" -d'
      +
      LineEnding + '' + LineEnding +
      'All question welcome to: Anton Shevtsov <x09@altlinux.org>' + LineEnding);

  end;

  procedure TTgSend.SendMessage;
  var
    HTTP: THTTPSend;
    Data: TstringStream;
    req: string;
  begin
    { add your help code here }
    // 0 - token
    // 1 - chatid
    // 2 - message
    // 3 - file


    try
      http := thttpsend.Create;

      if (Proxy <> '') then
      begin
        HTTP.ProxyHost := proxy;
        HTTP.ProxyPort := proxy_port;
        if (debug) then
          writeln('Use proxy:' + proxy + ':' + proxy_port);
      end;

      HTTP.MimeType := 'application/json';

      req := '{ "chat_id": "' + optArr[1] + '","parse_mode":"HTML", "text":"' +
        optArr[2] + '" }';

      //  writeln(req);

      Data := TStringStream.Create(req);
      HTTP.Document.LoadFromStream(Data);

      //  if (debug) then writeln('make POST request to: '+
      //  'https://api.telegram.org/bot' +     optArr[0] + '/sendMessage');

      if not HTTP.HTTPMethod('POST', 'https://api.telegram.org/bot' +
        optArr[0] + '/sendMessage') or (debug) then
      begin
        writeln('Request: ' + PChar(HTTP.Document.Memory));
        writeln('ResultCode: ' + IntToStr(HTTP.ResultCode));
      end;

    finally
      Data.Free;
      HTTP.Free;
    end;
  end;



  procedure TTgSend.SendFile;
  const
    CR = #$0d;
    LF = #$0a;
    CRLF = CR + LF;
  var
    HTTP: THTTPSend;
    FS: TFileStream;
    s, Caption: ansistring;
    bound, s1, s2: string;
    tgMethod: string;
  begin
    { add your help code here }
    // 0 - token
    // 1 - chatid
    // 2 - message
    // 3 - file

    if not FileExists(optArr[3]) then
    begin
      WriteLn('File not found. Exit.');
      ExitCode:=255;
      Exit;
    end;

    if HasOption('C', 'caption') then
      Caption := GetOptionValue('C', 'caption');

    TgMethod := 'sendDocument';
    s2 := 'document';

    if HasOption('F', 'foto') then
    begin
      TgMethod := 'sendPhoto';
      s2 := 'photo';
    end  ;

    if HasOption('V', 'voice') then
    begin
      TgMethod := 'sendVoice';
      s2 := 'voice';
    end;

    if HasOption('A', 'audio') then
    begin
      TgMethod := 'sendAudio';
      s2 := 'audio';
    end;

    bound := 'END_OF_PART-TGSEND-byX09';

    try
      http := thttpsend.Create;


      if debug then
        writeln('File open: ' + optArr[3]);

      FS := TFileStream.Create(optArr[3], fmOpenRead);

      HTTP.MimeType := 'multipart/form-data;  boundary=' + bound;


      if (Proxy <> '') then
      begin
        HTTP.ProxyHost := proxy;
        HTTP.ProxyPort := proxy_port;
        if (debug) then
          writeln('Use proxy:' + proxy + ':' + proxy_port);
      end;


      HTTP.KeepAlive := True;
      s := '--' + bound + CRLF;
      s := s + 'Content-Disposition: form-data; name="' + s2 +
        '"; filename="' +  ExtractFileName(optArr[3]) + '"' + CRLF;

      s1 := MimeTypeByExt(ExtractFileName(optArr[3]));

      if (Debug) then
      begin
        Writeln('MIME-Type autodetect: ' + s1);
      end;

      s := s + 'Content-Type: ' + s1 + CRLF + CRLF;


      //  s := s + 'Content-Type: application/octet-stream' + CRLF + CRLF;

      if (Debug) then
      begin
        Write(s);
        writeln('*** Binary here ***');
      end;

      HTTP.Document.Write(PAnsiChar(s)^, Length(s));
      FS.Position := 0;
      HTTP.Document.CopyFrom(FS, FS.Size);

      s := CRLF + '--' + bound + CRLF;

      if Caption <> '' then
      begin
        s := s + 'Content-Disposition: form-data; name="caption"' +
          CRLF + CRLF + Caption;
        s := s + CRLF + '--' + bound + CRLF;
      end;

      s := s + 'Content-Disposition: form-data; name="chat_id"' +
        CRLF + CRLF + optArr[1];
      s := s + CRLF + '--' + bound + '--' + CRLF;

      if (Debug) then
        Write(s);

      HTTP.Document.Write(PAnsiChar(s)^, Length(s));

      if not HTTP.HTTPMethod('POST', 'https://api.telegram.org/bot' +
        optArr[0] + '/' + TgMethod) or (debug) then
      begin
        writeln('ResultCode:' + IntToStr(http.ResultCode));
        writeln('ResultString:' + HTTP.ResultString);
      end;


    finally
      HTTP.Free;
      fs.Free;
    end;
  end;


var
  Application: TTgSend;

{$R *.res}

begin
  Application := TTgSend.Create(nil);
  Application.Title := 'tgsend';
  Application.Run;
  Application.Free;
end.
