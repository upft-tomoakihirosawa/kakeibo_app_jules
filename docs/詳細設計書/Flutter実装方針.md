# Flutter実装方針書

---

## 1. ドキュメント管理

- 文書名: Flutter実装方針書
- 作成者: 廣澤
- 作成日: 2025-05-16

---

## 2. 概要

本文書は、家計簿アプリのモバイル版（Android/iOS）をFlutter + Riverpodで実装するための方針を定めるものです。基本設計書で定義されたMVVMアーキテクチャに基づき、Flutter特有の開発パターンやベストプラクティスを加味した詳細設計を記載します。

---

## 3. 技術スタック

### フレームワークとライブラリ

| 項目 | 使用技術 | バージョン | 用途 |
|-----|---------|----------|-----|
| UI フレームワーク | Flutter | 3.10.0以上 | クロスプラットフォームUI開発 |
| 状態管理 | Riverpod | 2.3.0以上 | アプリ全体の状態管理 |
| ルーティング | go_router | 7.0.0以上 | 画面遷移とディープリンク |
| HTTP通信 | dio | 5.0.0以上 | バックエンドとの通信 |
| ローカルストレージ | shared_preferences | 2.1.0以上 | ユーザー設定等の保存 |
| セキュアストレージ | flutter_secure_storage | 8.0.0以上 | 認証情報等の安全な保存 |
| 依存性注入 | riverpod | 2.3.0以上 | サービスの依存性注入 |
| フォームバリデーション | form_field_validator | 1.1.0以上 | 入力フォームの検証 |
| グラフ描画 | fl_chart | 0.62.0以上 | 円グラフ、棒グラフ等の描画 |
| 日付処理 | intl | 0.18.0以上 | 日付フォーマットとローカライゼーション |
| 認証 | firebase_auth | 4.6.0以上 | ユーザー認証 |
| データベース | cloud_firestore | 4.7.0以上 | クラウドデータ保存・同期 |
| テスト | flutter_test, mockito | 標準 | ユニットテスト、ウィジェットテスト |

---

## 4. プロジェクト構成

プロジェクトのディレクトリ構造は以下の通りとする:

```
lib/
├── config/                  # アプリ全体の設定
│   ├── routes.dart          # ルート定義
│   ├── themes.dart          # テーマ設定
│   └── constants.dart       # 定数定義
├── domain/                  # ドメインロジックとエンティティ
│   ├── entities/            # データモデル（Entity）
│   ├── repositories/        # リポジトリインタフェース
│   └── usecases/            # ユースケース
├── data/                    # データ層
│   ├── datasources/         # データソース（API、ローカルDBなど）
│   ├── repositories/        # リポジトリ実装
│   └── models/              # APIレスポンスモデル
├── presentation/            # プレゼンテーション層
│   ├── screens/             # 画面
│   │   ├── login/           # ログイン関連画面
│   │   ├── home/            # ホーム関連画面
│   │   ├── transactions/    # 取引関連画面
│   │   ├── categories/      # カテゴリ関連画面
│   │   └── settings/        # 設定関連画面
│   ├── widgets/             # 共通ウィジェット
│   └── state/               # 状態管理
│       └── providers/       # Riverpodプロバイダー定義
├── core/                    # 共通ユーティリティ
│   ├── utils/               # ユーティリティ関数
│   ├── errors/              # エラー定義
│   └── extensions/          # 拡張メソッド
└── main.dart                # アプリのエントリーポイント
```

---

## 5. 状態管理アーキテクチャ

### Riverpodを活用したMVVMパターン

基本設計書のMVVMアーキテクチャをFlutterとRiverpodで実現するため、以下の構成を採用します:

- **Model**: domain層のエンティティとdata層のリポジトリ
- **View**: presentation層のscreens（StatelessWidget）
- **ViewModel**: presentation/state/providersのStateNotifierProvider

#### Provider設計

Riverpodの各種プロバイダーを以下のように使い分けます:

1. **StateNotifierProvider**: 
   - 状態の変更を伴うViewModel（例：トランザクション一覧、ユーザー情報）

2. **FutureProvider**: 
   - 非同期で取得するデータ（例：APIからのカテゴリ一覧取得）

3. **Provider**: 
   - 単純な値や計算値の提供（例：合計金額計算）

4. **StreamProvider**:
   - リアルタイムに変化する値の監視（例：Firebase Firestoreのリアルタイムリスナー）

---

## 6. 画面遷移（ルーティング）

### GoRouterによるルーティング設計

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'transaction/add',
          builder: (context, state) => const TransactionAddScreen(),
        ),
        GoRoute(
          path: 'transaction/edit/:id',
          builder: (context, state) => TransactionEditScreen(
            id: state.params['id']!,
          ),
        ),
        GoRoute(
          path: 'categories',
          builder: (context, state) => const CategoryScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'budget',
          builder: (context, state) => const BudgetScreen(),
        ),
      ],
    ),
  ],
  // 認証状態によるリダイレクト設定
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    final isLoggingIn = state.subloc == '/login' || state.subloc == '/register';
    
    if (!isLoggedIn && !isLoggingIn) {
      return '/login';
    }
    
    if (isLoggedIn && isLoggingIn) {
      return '/home';
    }
    
    return null;
  },
);
```

---

## 7. レスポンシブ設計

本アプリはiOS/Androidの両プラットフォームで利用されるため、以下のレスポンシブ設計を採用します:

1. **デバイス別レイアウト**:
   - `LayoutBuilder`と`MediaQuery`を活用し、画面サイズに応じたレイアウト変更

2. **タブレット対応**:
   - 一定の画面幅を超える場合は、マルチカラムレイアウトに切り替え（例：ホーム画面で履歴とグラフを横並びに）

3. **セーフエリア対応**:
   - `SafeArea`を使用して、ノッチやホームインジケータを回避

4. **ダークモード対応**:
   - システムのダークモード設定を検出し、適切なテーマを適用
   - `ThemeData`の`brightness`プロパティの活用

---

## 8. ローカライゼーション

多言語対応は以下の方針で実装します:

1. **対応言語**:
   - 日本語（デフォルト）
   - 英語（将来拡張）

2. **実装方法**:
   - `flutter_localizations`と`intl`パッケージを使用
   - ARB（Application Resource Bundle）ファイルで翻訳を管理

3. **言語切替**:
   - ユーザー設定画面から言語選択が可能
   - デフォルトはシステム言語を使用

---

## 9. エラーハンドリング

エラー発生時の処理を統一するため、以下の方針を採用します:

1. **例外の定義**:
   - `core/errors/`にアプリ固有の例外を定義
   - ネットワークエラー、認証エラー、バリデーションエラーなど

2. **エラー表示**:
   - 致命的でないエラー: Snackbarで通知
   - 致命的なエラー: ダイアログで通知

3. **ログ記録**:
   - エラー発生時は`logger`パッケージを使用してログを記録

---

## 10. テスト方針

品質確保のため、以下のテスト方針を採用します:

1. **単体テスト（Unit Test）**:
   - ドメインロジック（ユースケース）のテスト
   - リポジトリ実装のテスト
   - ビジネスロジックを含むProviderのテスト

2. **ウィジェットテスト（Widget Test）**:
   - 重要なUIコンポーネントのテスト
   - フォームのバリデーションテスト
   - ユーザーインタラクションのテスト

3. **統合テスト（Integration Test）**:
   - 主要な画面遷移フローのテスト
   - バックエンドとの連携テスト（モックサーバー利用）

---

## 11. パフォーマンス考慮事項

以下のパフォーマンス最適化を実施します:

1. **データの遅延読み込み**:
   - 大量のデータはページネーションで取得
   - リストはLazyな実装（ListView.builder）で効率化

2. **画像処理の最適化**:
   - キャッシュを活用した画像読み込み（cached_network_image）
   - 画像サイズの最適化

3. **状態管理の効率化**:
   - Riverpodの`select`メソッドを使用して不要な再描画を防止
   - memoizeされたProviderの活用

4. **アニメーションの最適化**:
   - 重いアニメーションはスケルトンローディングで代替
   - `RepaintBoundary`の適切な使用

---

## 12. セキュリティ考慮事項

以下のセキュリティ対策を実施します:

1. **認証情報の保護**:
   - `flutter_secure_storage`を使用した安全な認証情報の保存
   - アプリバックグラウンド移行時の認証情報保護

2. **暗号化**:
   - センシティブなデータの暗号化保存

3. **バイオメトリック認証**:
   - 利用可能な場合、指紋認証やFace IDによるアプリロック機能の提供

4. **アプリケーションセキュリティ**:
   - ルート検出（Root/Jailbreak）によるセキュリティ警告
   - スクリーンショット保護（オプション機能）

---

## 13. CI/CD対応

継続的インテグレーション/デリバリーのために以下を設定します:

1. **GitHub Actions**:
   - PR時の自動ビルドとテスト実行
   - コードフォーマットチェック（flutter format）
   - 静的解析（flutter analyze）

2. **Codemagic/Bitrise**:
   - マスターブランチへのマージ時に自動ビルド
   - TestFlightとGoogle Play内部テストへの自動デプロイ

3. **バージョン管理**:
   - セマンティックバージョニングの採用
   - ビルド番号の自動インクリメント

---

## 14. 依存関係図

主要コンポーネント間の依存関係は以下の通りです:

```
Presentation Layer (Screens, Widgets)
        ↓ 依存 ↓
State Layer (Providers, ViewModels)
        ↓ 依存 ↓
Domain Layer (UseCases, Entities, Repository Interfaces)
        ↓ 依存 ↓
Data Layer (Repository Implementations, DataSources)
        ↓ 依存 ↓
External Services (Firebase, APIs, Local Storage)
```

---

## 15. プロジェクト管理

1. **コーディング規約**:
   - Effective Dartに準拠したコーディングスタイル
   - プロジェクト固有のルールはlint.yamlで定義

2. **ドキュメント**:
   - 公開APIには必ずドキュメントコメントを記載
   - 複雑なロジックには説明コメントを追加

3. **変更管理**:
   - 機能単位でのブランチ作成（feature/XXX）
   - PRレビューによる品質担保

---

## 16. 変更履歴

| 日付       | 変更内容               | 担当者 |
| ---------- | ---------------------- | ------ |
| 2025-05-16 | 初版リリース           | 廣澤  |
