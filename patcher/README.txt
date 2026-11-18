섀도우맨 (PS1 북미판 SLUS-00895) 한글패치 v1.0
by Yonggary6425 (용가리) - 본 한글패치는 개인이 제작한 비공식·비상업적 팬 한글패치입니다.

[준비물]
  - 원본: Shadow Man (USA) / SLUS-00895 (bin/cue, 2트랙)
    Shadow Man (USA) (Track 1).bin  크기 534,042,768 바이트, MD5 763cd348b7f8da79963f97d05c19fb65
    Shadow Man (USA) (Track 2).bin  오디오 트랙 (바꾸지 않음)
  - 빈 디스크 공간 약 550 MB

[적용 방법]
  A) Windows (기본 PowerShell 사용 - 별도 설치 불필요)
     1. "Shadow Man (USA) (Track 1).bin" 을 "패치하기.bat" 위에 끌어다 놓습니다.
     2. 같은 폴더에 "Shadow Man (USA) (Track 1) (Korean).bin" 이 생깁니다. (원본은 수정하지 않음)
     3. 원본 cue 가 같은 폴더에 있으면 "Shadow Man (USA) (Korean).cue" 도 만듭니다.
        에뮬레이터에서 이 cue 를 여세요. ("완료!"가 나오면 성공)
  B) Python (macOS/Linux)
     python3 patch.py "Shadow Man (USA) (Track 1).bin"

  - 적용 전에 원본의 MD5를, 적용 후에 결과를 검사합니다.
  - 결과 Track 1 MD5: 2329bb09e9125d3c9af5738199aca266
  - cue 를 직접 고칠 때는 Track 1 의 파일 이름만 결과 파일 이름으로 바꾸면 됩니다.

[주의]
  - 세이브 스테이트로 불러오면 이전 글꼴·문장이 보일 수 있습니다. 메모리 카드 세이브로 불러오세요.
  - 이미 패치한 파일에 다시 적용하지 말고, 항상 원본 Track 1 에 적용하세요.

[한글화 범위]
  - 대사 자막 74개 장면 985줄 (표시 시점·순서는 원본 그대로)
  - 메뉴·옵션·조작 설정·게임 중 메뉴·메모리 카드 안내·지역명·아이템명 170줄
  - 문서: 네티의 파일(경찰 보고서), 잭의 일기, 세인트 제임스의 편지·예언·유물 목록
  - 실행 파일 안의 장면 제목 등 42개, 크레딧 직책 53개
  - 한글 글꼴 1,388자 (Galmuri 12px·8px), 타이틀 localization by yonggary 표기
  - 음성과 그래픽 글자(Loading 등)는 원본 그대로입니다.

[알려진 사항]
  - 확인한 범위: 타이틀·메뉴·옵션·조작 설정, 인트로 자막, 바이유 첫 장면, 게임 중 메뉴,
    모험 저장 화면, 인벤토리, 네티의 파일 (DuckStation)
  - 이후 레벨 자막, 잭의 일기·세인트 제임스 문서, 크레딧 화면은 확인하지 못했습니다.
  - 실기(PS1 본체)에서는 확인하지 않았습니다.

[파일]  (모두 같은 폴더에 두세요)
  패치하기.bat / patch.ps1 : Windows 적용기
  patch.py                 : Python 적용기
  sm_kor.bin               : 한글패치 데이터

[문의·제보] https://github.com/Yonggary6425/Shadow-Man-PS1-Korean-Patch
