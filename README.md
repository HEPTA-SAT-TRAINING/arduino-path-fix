# Arduino IDE 2.x 日本語ユーザー名対策（Windows）

## 目的

Arduino IDE 2.x の以下の保存先を `C:\ArduinoWork` に変更します。

- `build_cache.path` → `C:\ArduinoWork\cache`
- `directories.data` → `C:\ArduinoWork\data`

古い `%LOCALAPPDATA%\Arduino15` の内容は新しい `data` にコピーし、元データは削除しません。
既存の `arduino-cli.yaml` は変更前にバックアップします。
Windows 全体の環境変数は変更せず、管理者権限も要求しません。

## 使い方
1. Arduino IDE のウィンドウをすべて閉じます。
2. ZIP を展開し、2 つのスクリプトを同じフォルダに置きます。
3. `Run-ArduinoPathFix.cmd` をダブルクリックします。
4. `SUCCESS` と表示されたら Arduino IDE を起動し、Blink などをコンパイルします。

## 注意
- Arduino IDE 2.x（目安として 2.3.4 以降）を対象とします。
- `C:\ArduinoWork` に作成・書き込みできる権限が必要です。
  - 書き込みできない場合は、`Fix-ArduinoPaths.ps1` 冒頭の `$basePath` を変更してください。
  - 日本語などの非 ASCII 文字を含まない、個人が安全に書き込める場所を指定してください。
- 「管理者として実行」はしないでください。他のユーザーのプロファイルが対象になる場合があります。
- 組織の実行制御ポリシーやウイルス対策により、スクリプト実行が禁止される場合があります。その場合は組織の規則に従ってください。
- 既に `directories.data` を別の独自フォルダへ変更している場合は、安全のため停止します。
- 同じ PC で複数の Windows ユーザーが使う場合、`C:\ArduinoWork` を共用しないでください。
- このスクリプトは基本的な YAML マッピング形式に対応します。特殊な記法の YAML は手動で確認してください。
- Arduino IDE のスケッチ保存先（`directories.user`）は変更しません。
- 終了後はコンパイルログで実際のパスを確認してください。

## 復元
設定ファイル: `%USERPROFILE%\.arduinoIDE\arduino-cli.yaml`

同じフォルダに作成された `arduino-cli.yaml.backup-日時` を元に戻してください。
データを戻す場合は、変更前の `%LOCALAPPDATA%\Arduino15` に切り替えてください。

## 構成
- `Run-ArduinoPathFix.cmd`: ダブルクリック用起動ファイル
- `Fix-ArduinoPaths.ps1`: 実処理用 PowerShell スクリプト
