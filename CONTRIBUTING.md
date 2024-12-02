# Contribution Guide

このプロジェクトへのコントリビュート方法についてガイドです。

## Issues

次のIssueを受け付けています。

- 内容に対する質問 => [こちらから質問できます](https://github.com/ntc-uchida-co-jp/ms-giga-usage-report/issues/new?template=question.md)
- 内容のエラーや問題の報告 => [こちらからバグ報告できます](https://github.com/ntc-uchida-co-jp/ms-giga-usage-report/issues/new?template=bug_report.md)
- 解説の改善を提案 => [こちらから提案できます](https://github.com/ntc-uchida-co-jp/ms-giga-usage-report/issues/new?template=feature_request.md)

[その他のIssue](https://github.com/ntc-uchida-co-jp/ms-giga-usage-report/issues/new?template=other.md)も歓迎しています。

## Pull Request

Pull Requestはいつでも歓迎しています。  

次の種類のPull Requestを受け付けています。  
基本的なPull Request（特に細かいもの）は、Issueを立てずにPull Requestを送ってもらって問題ありません。  

「このような修正/改善はどうでしょう？」という疑問がある場合は、Issueを立てて相談してください。  
- 誤字の修正
- サンプルコードやスペルの修正
- 別の説明方法の提案や修正
- 文章をわかりやすくするように改善
- テストの改善

:memo: **Note:** Pull Requestを受け入れるとあなたの貢献が[Contributorsリスト](https://github.com/ntc-uchida-co-jp/ms-giga-usage-report/graphs/contributors)に追加されます。  
また、Pull Requestを送った内容は本プロジェクトの[ライセンス](./LICENSE)（**Mozilla Public License Version 2.0**）が適用されます。  
**※[CODE OF CONDUCT](./.github/CODE_OF_CONDUCT.md)に反する内容を含むPull Requestは受け付けません。**

### 修正の手順  
以下の手順によって、Pull Requestを作成し、修正内容を送ってください。
1. 自身のリポジトリにForkする
2. 変更内容をcommitする
3. 既存のフォーマットに従って、Pull Request作成する
    ```
    ## 概要
    このPull Requestが解決する内容を簡単に説明してください。  
    また、**変更内容に関連のある項目をラベル付けしてください。**
    
    ## 変更点
    - 修正した具体的な内容を記載してください。
    - 変更点や意図を明確に説明してください。
    
    ## 背景
    なぜこの変更が必要か、背景を簡潔に説明してください。
    
    ## 関連するIssue
    - Issue番号: #
    
    ## 確認項目
    - [ ] 既存の機能への影響範囲を確認しました。
    - [ ] 修正した内容が期待通り動作することを確認しました。
    - [ ] 既存の他の機能への影響がないことを確認しました。
    - [ ] 関連するドキュメントが最新の状態に更新しました。
    
    ## その他
    レビュー時に注意すべきポイントや参考情報があれば記載してください。
    ```

4. (**※管理者による操作**)変更内容の承認、mainへのマージ

## テスト  

本プロジェクトでのテストは"作業者によるテスト"と"CIによるテスト"の2種に分けられます。  
基本的に、CIでは各ドキュメントが一定のコード品質を保っているかを確認しており、機能の整合性の確認は行っておりません。  
変更による、既存のドキュメントの整合性や機能への影響範囲や動作確認については、作業者にて行っていただきます。

### 作業者によるテスト
- **.pbit**  
  テスト観点  
  - a
- **.md**  
  テスト観点  
  - 変更後、各ドキュメントとの整合性を確認して下さい
- **.ps1**  
  テスト観点  
  - a
- **.yml**  
  テスト観点  
  - a

### CIによるテスト
本プロジェクトのCIでは、mainブランチへのPull Request作成時およびPush時にリントツールを使用したテストを行うことでコード品質を保っています。  
※"Info", "Warn"レベルの差異は許容しています。

- **.md**  
リントツール: remark-cli  
対象: リポジトリ内のすべてのMarkdownファイル    
カスタム設定: なし  
詳細は[こちら](https://www.npmjs.com/package/remark-preset-lint-consistent)


- **.ps1**  
リントツール: PSScriptAnalyser  
対象: リポジトリ内のすべての.ps1ファイル  
カスタム設定: なし  
詳細は[こちら](https://learn.microsoft.com/ja-jp/powershell/utility-modules/psscriptanalyzer/rules/readme?view=ps-modules)


- **.yml**  
リントツール: yamllint  
対象: .github/workflowsは以下のすべての.ymlファイル  
カスタム設定: **あり**  
※リポジトリのルートに存在する「.yamllint」ファイルにて定義  
詳細は[こちら](https://yamllint.readthedocs.io/en/stable/rules.html#)

## ディレクトリ構造

本プロジェクトでは以下のようなディレクトリ構造となっています。

```
└── ...
```


**各ディレクトリについて説明を記載する**
- aaa  
- bbb  
...
