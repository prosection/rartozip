import sys
import os
import subprocess
import tempfile
import zipfile


def convert_rar_to_zip_with_7zip(rar_path, seven_zip_path='7z.exe'):
    if not rar_path.lower().endswith('.rar'):
        print(f"[SKIP] {rar_path} はRARファイルではありません。")
        return

    base_dir = os.path.dirname(rar_path)
    base_name = os.path.splitext(os.path.basename(rar_path))[0]
    zip_path = os.path.join(base_dir, f"{base_name}.zip")

    counter = 1
    while os.path.exists(zip_path):
        zip_path = os.path.join(base_dir, f"{base_name}_{counter}.zip")
        counter += 1

    try:
        with tempfile.TemporaryDirectory() as tmpdir:
            print(f"[INFO] 解凍中: {rar_path}")
            result = subprocess.run([
                seven_zip_path, 'x', '-y', f"-o{tmpdir}", rar_path
            ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)

            if result.returncode != 0:
                print(f"[ERROR] 7-Zipによる解凍に失敗しました: {result.stderr}")
                return

            print(f"[INFO] ZIP作成中: {zip_path}")
            with zipfile.ZipFile(zip_path, 'w', compression=zipfile.ZIP_STORED) as zf:
                for root, _, files in os.walk(tmpdir):
                    for file in files:
                        full_path = os.path.join(root, file)
                        rel_path = os.path.relpath(full_path, tmpdir)
                        zf.write(full_path, arcname=rel_path)

            os.remove(rar_path)
            print(f"[DONE] 変換完了 & 削除済み: {zip_path}")

    except Exception as e:
        print(f"[ERROR] {rar_path} の変換中に例外が発生しました: {e}")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("RARファイルをこのスクリプトにドラッグ＆ドロップしてください。")
        input("Enterキーで終了します。")
        sys.exit(1)

    for rar_file in sys.argv[1:]:
        convert_rar_to_zip_with_7zip(rar_file)

    input("\nすべての変換が完了しました。Enterキーで終了します。")
