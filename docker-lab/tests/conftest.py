"""pytest 設定。docker-lab/ ルートを sys.path に追加して src パッケージを解決する。"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
