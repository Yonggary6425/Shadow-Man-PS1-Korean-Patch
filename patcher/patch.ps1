# Shadow Man (PS1 북미판 SLUS-00895) 한글패치 적용기 - Windows PowerShell 기본 기능만 사용
# 사용: "Shadow Man (USA) (Track 1).bin" 을 "패치하기.bat" 위에 끌어다 놓기
#       powershell -File patch.ps1 "Shadow Man (USA) (Track 1).bin"
param([Parameter(Mandatory = $true)][string]$Bin)
$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Add-Type -TypeDefinition @'
using System; using System.IO; using System.IO.Compression; using System.Security.Cryptography; using System.Text;
public static class SmPatch {
  public static string Header(string patch, out long bodyOffset) {
    using (FileStream f = File.OpenRead(patch)) using (BinaryReader r = new BinaryReader(f)) {
      string magic = Encoding.ASCII.GetString(r.ReadBytes(8));
      if (magic != "SMKOR1\0\0") throw new Exception("패치 데이터 형식이 다릅니다: " + patch);
      int n = r.ReadInt32(); string json = Encoding.UTF8.GetString(r.ReadBytes(n)); bodyOffset = f.Position; return json;
    }
  }
  static string Hex(byte[] h) { return BitConverter.ToString(h).Replace("-", "").ToLowerInvariant(); }
  public static string Md5(string file) {
    using (FileStream f = new FileStream(file, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 20)) using (MD5 m = MD5.Create()) { return Hex(m.ComputeHash(f)); }
  }
  // ops: 0 SEEK(target offset) 1 COPY(original offset, length) 2 DATA(length) 3 ZERO(length)
  // returns the MD5 of every byte written, in order
  public static string Apply(string orig, string patch, long bodyOffset, string output, bool create, long targetSize) {
    byte[] ops;
    using (MD5 sum = MD5.Create())
    using (FileStream p = File.OpenRead(patch)) {
      p.Position = bodyOffset; byte[] b4 = new byte[4]; p.Read(b4, 0, 4); int opsLen = BitConverter.ToInt32(b4, 0);
      byte[] z = new byte[opsLen]; int got = 0; while (got < opsLen) got += p.Read(z, got, opsLen - got);
      using (MemoryStream ms = new MemoryStream(z)) using (DeflateStream d = new DeflateStream(ms, CompressionMode.Decompress)) using (MemoryStream o = new MemoryStream()) { d.CopyTo(o); ops = o.ToArray(); }
      using (DeflateStream data = new DeflateStream(p, CompressionMode.Decompress))
      using (FileStream src = new FileStream(orig, FileMode.Open, FileAccess.Read, FileShare.Read, 1 << 20))
      using (FileStream dst = new FileStream(output, create ? FileMode.Create : FileMode.Open, FileAccess.Write, FileShare.None, 1 << 20)) {
        byte[] buf = new byte[1 << 20]; byte[] zero = new byte[1 << 20];
        for (int i = 0; i + 13 <= ops.Length; i += 13) {
          int type = ops[i]; long len = BitConverter.ToUInt32(ops, i + 1); long arg = BitConverter.ToInt64(ops, i + 5);
          if (type == 0) { dst.Position = arg; continue; }
          if (type == 1) src.Position = arg;
          while (len > 0) {
            int n = (int)Math.Min(len, buf.Length);
            if (type == 3) { dst.Write(zero, 0, n); if (!create) sum.TransformBlock(zero, 0, n, null, 0); }
            else {
              Stream s = type == 1 ? (Stream)src : data; int have = 0;
              while (have < n) { int r = s.Read(buf, have, n - have); if (r <= 0) throw new Exception("데이터가 모자랍니다 (원본 bin 또는 패치 파일 손상)"); have += r; }
              dst.Write(buf, 0, n); if (!create) sum.TransformBlock(buf, 0, n, null, 0);
            }
            len -= n;
          }
        }
        if (create && dst.Length != targetSize) throw new Exception("결과 크기가 다릅니다");
      }
      sum.TransformFinalBlock(new byte[0], 0, 0); return Hex(sum.Hash);
    }
  }
}
'@

function Fail($msg) { Write-Host ""; Write-Host "[실패] $msg" -ForegroundColor Red; exit 1 }

$base = Join-Path $here 'sm_kor.bin'
if (-not (Test-Path -LiteralPath $base)) { Fail "sm_kor.bin 이 patch.ps1 과 같은 폴더에 없습니다." }
if (-not (Test-Path -LiteralPath $Bin -PathType Leaf)) { Fail "원본 bin 파일을 찾을 수 없습니다: $Bin" }
$Bin = (Resolve-Path -LiteralPath $Bin).Path

$off = 0L
$h = [SmPatch]::Header($base, [ref]$off) | ConvertFrom-Json
Write-Host "섀도우맨 (PS1) 한글패치 v$($h.version)  -  by Yonggary6425"
Write-Host "원본: $Bin"
Write-Host ""

$size = (Get-Item -LiteralPath $Bin).Length
if ($size -ne [long]$h.origSize) { Fail "원본 크기가 다릅니다. (필요: $($h.origSize) 바이트, 지금: $size 바이트)`n  북미판 SLUS-00895 의 Track 1 bin 인지, 이미 패치한 파일이 아닌지 확인해 주세요." }
Write-Host "원본 확인 중..."
if ([SmPatch]::Md5($Bin) -ne $h.origMd5) { Fail "원본 내용이 제작에 쓴 원본과 다릅니다. (필요 MD5: $($h.origMd5))" }

$folder = Split-Path -Parent $Bin
$name = Split-Path -Leaf $Bin
$out = Join-Path $folder (([IO.Path]::GetFileNameWithoutExtension($Bin)) + ' (Korean).bin')
$need = [long]$h.targetSize
$drive = Get-PSDrive -Name ([IO.Path]::GetPathRoot($out).Substring(0, 1)) -ErrorAction SilentlyContinue
if ($drive -and $drive.Free -lt $need) { Fail "디스크 공간이 모자랍니다. (필요: $([math]::Round($need / 1MB)) MB)" }

Write-Host "한글판 만드는 중..."
[void][SmPatch]::Apply($Bin, $base, $off, $out, $true, $need)
Write-Host "결과 확인 중..."
if ([SmPatch]::Md5($out) -ne $h.targetMd5) { Remove-Item -LiteralPath $out -Force; Fail "결과 파일 검사값이 다릅니다. 파일을 지웠습니다. 다시 시도해 주세요." }

# 같은 폴더에서 원본 bin을 가리키는 cue를 찾아 Track 1 이름만 바꾼 한글판 cue를 만든다
$newName = Split-Path -Leaf $out
$cueOut = $null
foreach ($cue in (Get-ChildItem -LiteralPath $folder -Filter '*.cue' | Sort-Object Name)) {
  if ($cue.Name.EndsWith(' (Korean).cue')) { continue }
  $text = [IO.File]::ReadAllText($cue.FullName)
  if ($text.Contains('"' + $name + '"')) {
    $cueOut = Join-Path $folder ($cue.BaseName + ' (Korean).cue')
    [IO.File]::WriteAllText($cueOut, $text.Replace('"' + $name + '"', '"' + $newName + '"'), (New-Object Text.UTF8Encoding($false)))
    break
  }
}
Write-Host ""
Write-Host "완료!" -ForegroundColor Green
Write-Host "만든 파일: $out"
if ($cueOut) { Write-Host "cue 파일: $cueOut  (에뮬레이터에서 이 cue를 여세요)" }
else { Write-Host "cue 파일을 찾지 못했습니다. 원본 cue의 Track 1 파일 이름을 위 파일 이름으로 바꿔 쓰세요." }
