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

## 手動で行う場合

スクリプトを使わずに設定する場合は、Arduino IDE を終了した状態で、次の手順を行います。

1. Arduino IDE のウィンドウをすべて閉じます。タスク マネージャーで `Arduino IDE` または
   `arduino-cli` が残っていないことも確認します。
2. エクスプローラーで `C:\ArduinoWork`、`C:\ArduinoWork\data`、
   `C:\ArduinoWork\cache` を作成します。
3. `%LOCALAPPDATA%\Arduino15` の中身を `C:\ArduinoWork\data` にコピーします。
   コピー元の `Arduino15` フォルダ自体ではなく、その中身をコピーしてください。
   コピー後も元のフォルダとファイルは削除しません。

   コマンド プロンプトを使う場合は、次のコマンドでもコピーできます。

   ```bat
   robocopy "%LOCALAPPDATA%\Arduino15" "C:\ArduinoWork\data" /E /COPY:DAT /DCOPY:DAT /XJ
   ```

4. `%USERPROFILE%\.arduinoIDE\arduino-cli.yaml` を別名でバックアップします。
   例: `arduino-cli.yaml.backup-20261117`
5. `arduino-cli.yaml` をテキストエディターで開き、次の設定を追加または変更します。
   YAML のインデントにはスペースを使用してください。

   ```yaml
   build_cache:
     path: C:\ArduinoWork\cache
   directories:
     data: C:\ArduinoWork\data
   ```

   既に `directories.data` が別のフォルダを指している場合は、既存データの扱いを
   確認してから変更してください。`directories.user` は変更しません。
6. ファイルを保存し、Arduino IDE を起動します。Blink などをコンパイルして、
   コンパイルログに `C:\ArduinoWork` 配下のパスが表示されることを確認します。

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
