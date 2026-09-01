# CUIの最初の30分

上から1行ずつ実行する、Linux / WSL2向けの最短演習です。プロンプトの `$` は入力しません。自分のホームディレクトリ以外へ移動した場合は開始しません。

## 0〜5分 — 自分と場所を確認

```bash
whoami
hostname
pwd
```

**表示の意味:** 順に「操作中のユーザー」「操作中の環境名」「現在地」です。`pwd` が `/home/<自分のユーザー名>` でなければ `cd` を実行してから再確認します。

## 5〜15分 — 学習用ファイルを作る

```bash
mkdir cui-practice
cd cui-practice
printf '%s\n' 'first practice' > note.txt
cat note.txt
```

**期待結果:** `cat` の次の行に `first practice` と表示されます。`>` はファイルを上書きするため、この演習で今作った `note.txt` だけに使います。

## 15〜20分 — コピーして違いがないか確認

```bash
cp note.txt note-backup.txt
ls -la
cmp note.txt note-backup.txt
echo $?
```

**期待結果:** 一覧に2ファイルがあり、`cmp` は何も表示せず、終了コードは `0` です。表示がないことだけで成功と決めず、終了コードでも確認します。

## 20〜25分 — 証拠を残す

```bash
{
  date -Is
  whoami
  hostname
  pwd
  ls -la
} > practice-result.txt
cat practice-result.txt
```

**期待結果:** 時刻、ユーザー、環境名、現在地、一覧がファイルに入ります。公開前にはユーザー名や環境名を伏せます。

## 25〜30分 — 対象を確認して片付ける

```bash
cd ..
pwd
find cui-practice -maxdepth 1 -type f -print
rm -rI cui-practice
test ! -e cui-practice
echo $?
```

一覧がこの演習で作った3ファイルだけであることを確認してから、確認質問に答えます。最後の終了コードが `0` なら学習用ディレクトリはなくなっています。

## 違う結果になったら

連続してコマンドを試さず、入力した行とエラー全文を保存します。`Permission denied`、`command not found`、`No such file or directory` は[初心者向けエラーFAQ](./beginner-troubleshooting.md)で確認します。完了したら[CUIマニュアル](../cui-manual.html)の段階演習へ進みます。
