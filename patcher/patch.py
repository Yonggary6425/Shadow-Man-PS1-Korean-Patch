#!/usr/bin/env python3
"""Shadow Man (PS1 북미판 SLUS-00895) 한글패치 적용기 (Python 3.8+, 추가 설치 없음)
사용: python3 patch.py "Shadow Man (USA) (Track 1).bin"
결과: 같은 폴더에 "원본이름 (Korean).bin" 과, cue 파일이 있으면 "cue이름 (Korean).cue" """
import sys, os, json, zlib, struct, hashlib, glob

HERE = os.path.dirname(os.path.abspath(__file__))
CHUNK = 1 << 20
MAGIC = b"SMKOR1\0\0"


def fail(msg, out=None):
    if out and os.path.exists(out):
        os.remove(out)
    print("\n[실패] " + msg)
    sys.exit(1)


def md5(path):
    h = hashlib.md5()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(CHUNK), b""):
            h.update(b)
    return h.hexdigest()


def header(path):
    with open(path, "rb") as f:
        if f.read(8) != MAGIC:
            fail("패치 데이터 형식이 다릅니다: " + path)
        n = struct.unpack("<I", f.read(4))[0]
        return json.loads(f.read(n).decode("utf-8")), f.tell()


class Data:
    """raw deflate 스트림에서 필요한 만큼만 읽는다"""
    def __init__(self, f):
        self.f, self.d, self.buf = f, zlib.decompressobj(-15), bytearray()

    def read(self, n):
        while len(self.buf) < n:
            raw = self.f.read(CHUNK)
            if not raw:
                break
            self.buf += self.d.decompress(raw)
        if len(self.buf) < n:
            fail("패치 데이터가 모자랍니다 (파일 손상)")
        out = bytes(self.buf[:n])
        del self.buf[:n]
        return out


def apply(orig, patch, body, out):
    """ops: 0 SEEK(대상 위치) 1 COPY(원본 위치, 길이) 2 DATA(길이) 3 ZERO(길이)"""
    with open(patch, "rb") as p, open(orig, "rb") as src, open(out, "wb") as dst:
        p.seek(body)
        ops = zlib.decompress(p.read(struct.unpack("<I", p.read(4))[0]), -15)
        data = Data(p)
        for i in range(0, len(ops) - 12, 13):
            typ, length, arg = struct.unpack_from("<BIQ", ops, i)
            if typ == 0:
                dst.seek(arg)
                continue
            if typ == 1:
                src.seek(arg)
            while length:
                n = min(length, CHUNK)
                if typ == 3:
                    b = bytes(n)
                elif typ == 1:
                    b = src.read(n)
                    if len(b) != n:
                        fail("원본 bin을 끝까지 읽지 못했습니다")
                else:
                    b = data.read(n)
                dst.write(b)
                length -= n


def make_cue(bin_path, out_bin):
    """같은 폴더에서 원본 bin을 가리키는 cue를 찾아 Track 1 이름만 바꾼 한글판 cue를 만든다"""
    folder, name = os.path.split(bin_path)
    new_name = os.path.basename(out_bin)
    for cue in sorted(glob.glob(os.path.join(folder, "*.cue"))):
        if cue.endswith(" (Korean).cue"):
            continue
        try:
            text = open(cue, "rb").read().decode("utf-8")
        except UnicodeDecodeError:
            continue
        if '"%s"' % name in text:
            out_cue = os.path.splitext(cue)[0] + " (Korean).cue"
            with open(out_cue, "wb") as f:
                f.write(text.replace('"%s"' % name, '"%s"' % new_name).encode("utf-8"))
            return out_cue
    return None


def main():
    if len(sys.argv) < 2:
        fail('사용법: python3 patch.py "Shadow Man (USA) (Track 1).bin"')
    src = os.path.abspath(sys.argv[1])
    base = os.path.join(HERE, "sm_kor.bin")
    if not os.path.isfile(base):
        fail("sm_kor.bin 이 patch.py 와 같은 폴더에 없습니다.")
    if not os.path.isfile(src):
        fail("원본 bin 파일을 찾을 수 없습니다: " + src)
    h, body = header(base)
    print("섀도우맨 (PS1) 한글패치 v%s  -  by Yonggary6425" % h["version"])
    print("원본:", src, "\n")
    size = os.path.getsize(src)
    if size != h["origSize"]:
        fail("원본 크기가 다릅니다. (필요: %d 바이트, 지금: %d 바이트)\n  북미판 SLUS-00895 의 Track 1 bin 인지, 이미 패치한 파일이 아닌지 확인해 주세요." % (h["origSize"], size))
    print("원본 확인 중...")
    if md5(src) != h["origMd5"]:
        fail("원본 내용이 제작에 쓴 원본과 다릅니다. (필요 MD5: %s)" % h["origMd5"])
    out = os.path.splitext(src)[0] + " (Korean).bin"
    print("한글판 만드는 중...")
    apply(src, base, body, out)
    print("결과 확인 중...")
    if md5(out) != h["targetMd5"]:
        fail("결과 파일 검사값이 다릅니다. 파일을 지웠습니다. 다시 시도해 주세요.", out)
    cue = make_cue(src, out)
    print("\n완료!\n만든 파일: %s" % out)
    if cue:
        print("cue 파일: %s  (에뮬레이터에서 이 cue를 여세요)" % cue)
    else:
        print("cue 파일을 찾지 못했습니다. 원본 cue의 Track 1 파일 이름을 위 파일 이름으로 바꿔 쓰세요.")


if __name__ == "__main__":
    main()
