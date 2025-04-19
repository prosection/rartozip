# RAR to ZIP Converter

RARアーカイブをZIP（無圧縮）に一括変換するバッチツールです。

## 特徴
- `.rar` ファイルを `.zip` に無圧縮で変換
- 複数ファイル対応（ドラッグ＆ドロップ）
- 変換後は元のRARを削除
- 既にZIPがある場合はリネームして保存

## 使用方法
1. `rarfile` をインストール：
    ```bash
    pip install rarfile
    ```
2. Windowsの場合、`unrar.exe` をスクリプトと同じフォルダに配置
3. `.rar` ファイルをスクリプトにドラッグ＆ドロップ

## 実行例（コマンドライン）
```bash
python rar_to_zip.py sample1.rar sample2.rar
```

## EXE化（任意）
PyInstallerを使って実行ファイル化可能：
```bash
pyinstaller --onefile rar_to_zip.py
```

## ライセンス
MIT License
