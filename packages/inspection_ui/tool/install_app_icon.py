"""Run by app owner at final integration; copies only named launcher resources."""
from pathlib import Path
import argparse
import shutil

ui_root=Path(__file__).resolve().parents[1]
repo=ui_root.parent.parent
parser=argparse.ArgumentParser()
parser.add_argument('--target',default=str(repo/'apps/mobile'))
args=parser.parse_args()
target=Path(args.target).resolve()
if not target.is_relative_to(repo.resolve()):
    raise SystemExit('Target must remain inside this repository.')
res=target/'android/app/src/main/res'
if not res.is_dir():
    raise SystemExit('Target is not a generated Android Flutter app.')
for source in (ui_root/'assets/brand/android/res').rglob('*'):
    if source.is_file():
        dest=res/source.relative_to(ui_root/'assets/brand/android/res')
        dest.parent.mkdir(parents=True,exist_ok=True)
        shutil.copyfile(source,dest)
        print(dest.relative_to(repo))
