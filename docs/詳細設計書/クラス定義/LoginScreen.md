# LoginScreen クラス

## 概要
`LoginScreen` はユーザー認証のためのログイン画面を実装するクラスです。メールアドレスとパスワードによる標準的な認証方式に加え、GoogleやAppleアカウントによるシングルサインオン機能を提供します。

**ファイルパス**: `lib/presentation/screens/auth/login_screen.dart`

## クラス定義
```dart
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}
```

## 依存関係
- `flutter_riverpod`: 状態管理のためのライブラリ
- `AuthNotifier`: 認証状態を管理するクラス
- `AuthRepository`: 認証処理を実装するリポジトリ

## _LoginScreenState クラス

### プロパティ
| プロパティ名 | 型 | 説明 |
|------------|-------|------|
| `_formKey` | `GlobalKey<FormState>` | フォームのバリデーション状態を管理するキー |
| `_emailController` | `TextEditingController` | メールアドレス入力フィールドのコントローラ |
| `_passwordController` | `TextEditingController` | パスワード入力フィールドのコントローラ |
| `_obscurePassword` | `bool` | パスワードを非表示にするかのフラグ |
| `_isLoading` | `bool` | ログイン処理中かどうかのフラグ |
| `_errorMessage` | `String?` | エラーメッセージ |

### メソッド

#### `dispose()`
```dart
@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}
```
**説明**: ステートオブジェクトが破棄される際に、TextEditingControllerを解放するメソッド。

#### `build(BuildContext context)`
```dart
@override
Widget build(BuildContext context) {
  // 画面のレイアウトを構築
  // 全体のレイアウト構造を定義
}
```
**説明**: ログイン画面のUIを構築するメソッド。アプリロゴ、ログインフォーム、SNSログインボタン、新規登録リンクなどを配置します。

#### `_buildAppLogo()`
**戻り値型**: `Widget`  
**説明**: アプリのロゴと名称、キャッチフレーズを表示するウィジェットを構築します。

#### `_buildErrorMessage()`
**戻り値型**: `Widget`  
**説明**: エラーメッセージを表示するウィジェットを構築します。エラーがない場合は表示されません。

#### `_buildLoginForm()`
**戻り値型**: `Widget`  
**説明**: メールアドレスとパスワードの入力フォームを構築します。バリデーションルールも設定します。

#### `_buildForgotPasswordLink()`
**戻り値型**: `Widget`  
**説明**: 「パスワードをお忘れですか？」のリンクを構築します。クリックするとパスワードリセット画面に遷移します。

#### `_buildLoginButton()`
**戻り値型**: `Widget`  
**説明**: ログインボタンを構築します。ログイン処理中はローディングインジケータを表示します。

#### `_buildDividerWithText(String text)`
**戻り値型**: `Widget`  
**パラメータ**:
- `text`: 区切り線の中央に表示するテキスト

**説明**: 水平線とテキストを組み合わせた区切り線を構築します。

#### `_buildSocialLoginButtons()`
**戻り値型**: `Widget`  
**説明**: GoogleとAppleのSNSログインボタンを構築します。

#### `_buildRegisterLink()`
**戻り値型**: `Widget`  
**説明**: 新規登録画面へのリンクを構築します。

#### `_handleLogin()`
**戻り値型**: `Future<void>`  
**説明**: メールアドレスとパスワードを使用したログイン処理を実行します。バリデーションチェックと例外処理も行います。

#### `_handleGoogleSignIn()`
**戻り値型**: `Future<void>`  
**説明**: Googleアカウントでのサインイン処理を実行します。

#### `_handleAppleSignIn()`
**戻り値型**: `Future<void>`  
**説明**: Appleアカウントでのサインイン処理を実行します。

#### `_formatErrorMessage(String errorMessage)`
**戻り値型**: `String`  
**パラメータ**:
- `errorMessage`: エラーメッセージの原文

**説明**: エラーメッセージをユーザーフレンドリーな日本語に変換します。