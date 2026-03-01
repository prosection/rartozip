@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

rem ===== 設定 =====
rem 元ファイル削除設定（1=削除する、0=削除しない）
set "DELETE_ORIGINAL=1"

rem ===== 7z.exe の場所を探す（Scoop版を最優先）=====
set "SEVENZIP="
set "SCOOP_7ZIP=C:\Users\end\scoop\apps\7zip\current\7z.exe"

echo 7-Zip検索中...

rem 1. Scoop版を最優先で確認
if exist "%SCOOP_7ZIP%" goto use_scoop

rem 2. PATH環境変数内を検索
where 7z.exe >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%P in ('where 7z.exe') do (
        set "SEVENZIP=%%~fP"
        echo [PATH] 環境変数から検出: "%%~fP"
        goto found_7z
    )
)

rem 3. 標準インストールパス（64bit）
if exist "%ProgramFiles%\7-Zip\7z.exe" goto use_standard_64

rem 4. 標準インストールパス（32bit）
if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" goto use_standard_32

goto no_7z_found

:use_scoop
set "SEVENZIP=%SCOOP_7ZIP%"
echo [優先] Scoop版7-Zipを使用: "%SCOOP_7ZIP%"
goto found_7z

:use_standard_64
set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
echo [標準] 64bit版を検出: "%ProgramFiles%\7-Zip\7z.exe"
goto found_7z

:use_standard_32
set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"
echo [標準] 32bit版を検出: "%ProgramFiles(x86)%\7-Zip\7z.exe"
goto found_7z

:found_7z
if "%~1"=="" (
    echo ============================================================
    echo RAR → ZIP 変換ツール（高速版・元ファイル削除対応）
    echo ============================================================
    echo 使用する7-Zip: "%SEVENZIP%"
    echo 圧縮設定: 無圧縮（最高速度優先）
    if "%DELETE_ORIGINAL%"=="1" (
        echo 元ファイル削除: 有効（変換成功後に元RARファイルを完全削除）
        echo   - 単一RAR: 元ファイルを削除
        echo   - 分割RAR: すべてのパートファイルを削除
        echo   - 旧形式分割: .r00, .r01等も含めて削除
    ) else (
        echo 元ファイル削除: 無効
    )
    echo.
    echo 使用方法：
    echo   RARファイルまたはフォルダをこのバッチにドラッグ＆ドロップ
    echo.
    echo 重要な注意事項：
    echo   - 削除はゴミ箱に入らず完全削除されます
    echo   - 変換が成功した場合のみ削除を実行します
    echo   - 削除を無効にする場合は、ファイル先頭のDELETE_ORIGINAL=0に変更
    echo ============================================================
    pause
    exit /b 0
)

echo 使用する7-Zip: "%SEVENZIP%"
if "%DELETE_ORIGINAL%"=="1" (
    echo 元ファイル削除: 有効
) else (
    echo 元ファイル削除: 無効
)
echo 処理開始...
echo.

:processArg
if "%~1"=="" goto end_process

if exist "%~1\NUL" (
    echo [フォルダ処理] 内部のRARファイルを検索: "%~1"
    for /r "%~1" %%F in (*.rar) do call :convert "%%~fF"
) else (
    call :convert "%~1"
)

shift
goto processArg

:end_process
exit /b 0

:convert
setlocal
set "SRC=%~1"
if not exist "%SRC%" (
    echo [スキップ] ファイルが見つかりません: "%SRC%"
    goto convert_end
)
if /I not "%~x1"==".rar" (
    echo [スキップ] 拡張子がRARではありません: "%SRC%"
    goto convert_end
)

rem 分割RARの後続ボリューム（part2以降）はスキップ
set "NAME=%~n1"
set "IS_SPLIT=0"
echo "%NAME%" | findstr /I /C:".part" >nul
if not errorlevel 1 (
    echo "%NAME%" | findstr /I /C:".part1" >nul
    if errorlevel 1 (
        echo [スキップ] 分割RARの後続ボリューム: "%SRC%"
        goto convert_end
    ) else (
        set "IS_SPLIT=1"
    )
)

set "BASE=%~dpn1"
set "ZIP=%BASE%.zip"
set "TMP=%BASE%_tmp_unpack"

rem 一時フォルダの重複を避ける
set /a RAND=%RANDOM%
if exist "%TMP%" set "TMP=%TMP%_%RAND%"

echo ==============================================================
echo [変換開始] "%~nx1"
echo 元ファイル: "%SRC%"
echo 出力先: "%ZIP%"
echo 一時展開先: "%TMP%"
if "%IS_SPLIT%"=="1" (
    echo 分割RAR: はい（全パートファイルを処理対象）
)
echo ==============================================================

rem 一時フォルダ作成
mkdir "%TMP%" >nul 2>&1
if errorlevel 1 (
    echo [エラー] 一時フォルダ作成に失敗: "%TMP%"
    goto convert_end
)

rem RAR展開
echo [1/4] RAR展開中...
"%SEVENZIP%" x -y -bso0 -bse1 -o"%TMP%" -- "%SRC%"
if errorlevel 1 (
    echo [エラー] RAR展開に失敗: "%SRC%"
    rd /s /q "%TMP%" >nul 2>&1
    goto convert_end
)

rem 既存のZIPファイルを削除
if exist "%ZIP%" (
    echo [準備] 既存のZIPファイルを削除
    del /f /q "%ZIP%" >nul 2>&1
)

rem ZIP作成（最高速設定）
echo [2/4] ZIP作成中...（無圧縮・最高速度）
"%SEVENZIP%" a -tzip -mx=0 -mmt=on -y -bso0 -bse1 -- "%ZIP%" "%TMP%\*"
if errorlevel 1 (
    echo [エラー] ZIP作成に失敗: "%ZIP%"
    rd /s /q "%TMP%" >nul 2>&1
    goto convert_end
)

rem 一時ファイル削除
echo [3/4] 一時ファイル削除中...
rd /s /q "%TMP%" >nul 2>&1

rem ファイルサイズ比較表示
for %%A in ("%SRC%") do set "RAR_SIZE=%%~zA"
for %%A in ("%ZIP%") do set "ZIP_SIZE=%%~zA"

echo [変換完了] 変換が正常に完了しました
echo   元RARサイズ: !RAR_SIZE! bytes
echo   新ZIPサイズ: !ZIP_SIZE! bytes
if !ZIP_SIZE! GTR !RAR_SIZE! (
    echo   注意: ZIPファイルの方が大きくなりました（無圧縮のため）
)

rem 変換成功時のみ元ファイル削除
if "%DELETE_ORIGINAL%"=="1" (
    echo [4/4] 元ファイル削除処理中...
    call :delete_source "%SRC%" "!IS_SPLIT!"
) else (
    echo [4/4] 元ファイル削除: スキップ（設定により無効）
)

echo ==============================================================
echo.

:convert_end
endlocal
exit /b 0

rem ===== 元RAR削除処理（分割ファイル完全対応） =====
:delete_source
setlocal
set "SRC=%~1"
set "IS_SPLIT=%~2"
set "DIR=%~dp1"
set "NAME_NOEXT=%~n1"
set "DELETED_COUNT=0"

if "%IS_SPLIT%"=="1" (
    rem 分割RAR（.part形式）の処理
    set "BASE_ROOT=%NAME_NOEXT:.part1=%"
    echo 分割RARファイルを削除中: "%DIR%!BASE_ROOT!.part*.rar"
    
    rem 起点ファイル（part1）を削除
    if exist "%SRC%" (
        del /f /q "%SRC%" >nul 2>&1
        if not errorlevel 1 (
            set /a DELETED_COUNT+=1
            echo   削除: "%SRC%"
        ) else (
            echo   [警告] 削除失敗: "%SRC%"
        )
    )
    
    rem 他のパートファイルを検索・削除
    pushd "%DIR%" >nul 2>&1
    for /f "delims=" %%G in ('dir /b /a:-d "!BASE_ROOT!.part*.rar" 2^>nul') do (
        if /I not "%%~nxG"=="!NAME_NOEXT!.rar" (
            if exist "%%~G" (
                del /f /q "%%~G" >nul 2>&1
                if not errorlevel 1 (
                    set /a DELETED_COUNT+=1
                    echo   削除: "%%~G"
                ) else (
                    echo   [警告] 削除失敗: "%%~G"
                )
            )
        )
    )
    popd >nul 2>&1
) else (
    rem 単一RARまたは旧形式分割RARの処理
    echo 元RARファイルを削除中: "%SRC%"
    
    rem メインファイル削除
    if exist "%SRC%" (
        del /f /q "%SRC%" >nul 2>&1
        if not errorlevel 1 (
            set /a DELETED_COUNT+=1
            echo   削除: "%SRC%"
        ) else (
            echo   [警告] 削除失敗: "%SRC%"
        )
    )
    
    rem 旧形式分割ファイル（.r00, .r01, .r02...）も削除
    pushd "%DIR%" >nul 2>&1
    for /f "delims=" %%G in ('dir /b /a:-d "%NAME_NOEXT%.r??" 2^>nul') do (
        if exist "%%~G" (
            del /f /q "%%~G" >nul 2>&1
            if not errorlevel 1 (
                set /a DELETED_COUNT+=1
                echo   削除: "%%~G"
            ) else (
                echo   [警告] 削除失敗: "%%~G"
            )
        )
    )
    popd >nul 2>&1
)

echo [削除完了] !DELETED_COUNT!個のファイルを削除しました
endlocal
exit /b 0

:no_7z_found
echo ============================================================
echo エラー: 7-Zip ^(7z.exe^) が見つかりません
echo ============================================================
echo 確認した場所：
echo   1. Scoop版: %SCOOP_7ZIP%
echo   2. PATH環境変数
echo   3. %ProgramFiles%\7-Zip\7z.exe
echo   4. %ProgramFiles(x86)%\7-Zip\7z.exe
echo.
echo 解決方法：
echo   - Scoopで再インストール: scoop install 7zip
echo   - 公式サイトからインストール: https://7-zip.org/
echo   - パスが正しいか確認してください
echo ============================================================
pause
exit /b 1