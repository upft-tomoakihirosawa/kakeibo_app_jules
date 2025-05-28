# RegisterScreen クラス

## 概要
`RegisterScreen` はユーザー登録画面を実装するクラスです。メールアドレスとパスワードによる新規ユーザー作成、およびGoogleやAppleなどのソーシャルアカウントによるサインアップ機能を提供します。

**ファイルパス**: `lib/presentation/screens/auth/register_screen.dart`

## クラス定義
```dart
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}
```

## 依存関係
- `flutter_riverpod`: 状態管理のためのライブラリ
- `AuthNotifier`: 認証状態を管理するクラス
- `RegisterFormState`: 登録フォームの状態を管理するクラス

## _RegisterScreenState クラス

### プロパティ
| プロパティ名 | 型 | 説明 |
|------------|-------|------|
| `_formKey` | `GlobalKey<FormState>` | フォームのバリデーション状態を管理するキー |
| `_nameController` | `TextEditingController` | ユーザー名入力フィールドのコントローラ |
| `_emailController` | `TextEditingController` | メールアドレス入力フィールドのコントローラ |
| `_passwordController` | `TextEditingController` | パスワード入力フィールドのコントローラ |
| `_confirmPasswordController` | `TextEditingController` | パスワード確認入力フィールドのコントローラ |
| `_obscurePassword` | `bool` | パスワードを非表示にするかのフラグ |
| `_obscureConfirmPassword` | `bool` | パスワード確認を非表示にするかのフラグ |
| `_isLoading` | `bool` | 登録処理中かどうかのフラグ |
| `_errorMessage` | `String?` | エラーメッセージ |
| `_registerFormNotifier` | `RegisterFormNotifier` | フォーム状態を管理するNotifier |

### メソッド

#### `initState()`
```dart
@override
void initState() {
  super.initState();
  _registerFormNotifier = ref.read(registerFormProvider.notifier);
}
```
**説明**: ステートオブジェクトが初期化される際にフォーム状態Notifierを取得します。

#### `dispose()`
```dart
@override
void dispose() {
  _nameController.dispose();
  _emailController.dispose();
  _passwordController.dispose();
  _confirmPasswordController.dispose();
  super.dispose();
}
```
**説明**: ステートオブジェクトが破棄される際に、各TextEditingControllerを解放するメソッド。

#### `build(BuildContext context)`
```dart
@override
Widget build(BuildContext context) {
  // 画面のレイアウトを構築
  // 全体のレイアウト構造を定義
}
```
**説明**: ユーザー登録画面のUIを構築するメソッド。アプリロゴ、登録フォーム、SNSログインボタン、ログインリンクなどを配置します。

#### `_buildAppLogo()`
**戻り値型**: `Widget`  
**説明**: アプリのロゴと名称、キャッチフレーズを表示するウィジェットを構築します。

#### `_buildErrorMessage()`
**戻り値型**: `Widget`  
**説明**: エラーメッセージを表示するウィジェットを構築します。エラーがない場合は表示されません。

#### `_buildRegisterForm()`
**戻り値型**: `Widget`  
**説明**: ユーザー名、メールアドレス、パスワード、パスワード確認の入力フォームを構築します。各フィールドのバリデーションルールも設定します。

#### `_buildTermsAndPrivacyText()`
**戻り値型**: `Widget`  
**説明**: 利用規約とプライバシーポリシーへの同意文言を表示します。

#### `_buildRegisterButton()`
**戻り値型**: `Widget`  
**説明**: 登録ボタンを構築します。登録処理中はローディングインジケータを表示します。

#### `_buildDividerWithText(String text)`
**戻り値型**: `Widget`  
**パラメータ**:
- `text`: 区切り線の中央に表示するテキスト

**説明**: 水平線とテキストを組み合わせた区切り線を構築します。

#### `_buildSocialLoginButtons()`
**戻り値型**: `Widget`  
**説明**: GoogleとAppleのソーシャルログインボタンを構築します。

#### `_buildLoginLink()`
**戻り値型**: `Widget`  
**説明**: すでにアカウントを持つユーザー向けのログイン画面へのリンクを構築します。

#### `_handleRegister()`
**戻り値型**: `Future<void>`  
**説明**: メールアドレスとパスワードを使用したユーザー登録処理を実行します。バリデーションチェックと例外処理も行います。

#### `_handleGoogleSignIn()`
**戻り値型**: `Future<void>`  
**説明**: Googleアカウントでのサインアップ処理を実行します。

#### `_handleAppleSignIn()`
**戻り値型**: `Future<void>`  
**説明**: Appleアカウントでのサインアップ処理を実行します。

#### `_formatErrorMessage(String errorMessage)`
**戻り値型**: `String`  
**パラメータ**:
- `errorMessage`: エラーメッセージの原文

**説明**: エラーメッセージをユーザーフレンドリーな日本語に変換します。

## RegisterFormNotifier クラス

### 概要
`RegisterFormNotifier`はユーザー登録フォームの状態を管理するStateNotifierクラスです。フォームの入力値、バリデーション状態、エラーメッセージなどを管理します。

### プロパティ
```dart
class RegisterFormState {
  final String name;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isValidName;
  final bool isValidEmail;
  final bool isValidPassword;
  final bool isMatchingPasswords;
  final bool isSubmitting;
  final String? errorMessage;
  
  // 全体のバリデーション状態
  bool get isValid => 
      isValidName && 
      isValidEmail && 
      isValidPassword && 
      isMatchingPasswords;
}
```

### メソッド

#### `updateName(String name)`
**説明**: ユーザー名を更新し、バリデーション状態を更新します。

#### `updateEmail(String email)`
**説明**: メールアドレスを更新し、バリデーション状態を更新します。

#### `updatePassword(String password)`
**説明**: パスワードを更新し、バリデーション状態を更新します。

#### `updateConfirmPassword(String confirmPassword)`
**説明**: 確認用パスワードを更新し、パスワードとの一致を確認します。

#### `validateName(String name)`
**説明**: ユーザー名のバリデーションチェックを行います。

#### `validateEmail(String email)`
**説明**: メールアドレスのバリデーションチェックを行います。

#### `validatePassword(String password)`
**説明**: パスワードのバリデーションチェックを行います。

#### `clearErrors()`
**説明**: エラーメッセージをクリアします。

#### `setSubmitting(bool isSubmitting)`
**説明**: フォーム送信中かどうかの状態を設定します。

#### `setErrorMessage(String? message)`
**説明**: エラーメッセージを設定します。
