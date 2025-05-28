# AuthNotifier クラス

## 概要
`AuthNotifier` はRiverpodの`StateNotifier`を継承し、アプリケーションの認証状態を管理するクラスです。メールアドレス/パスワード認証、GoogleおよびAppleを使用したソーシャルサインイン、ログアウト機能を提供します。

**ファイルパス**: `lib/presentation/state/notifiers/auth_notifier.dart`

## クラス定義
```dart
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository authRepository;
  
  AuthNotifier({required this.authRepository}) : super(const AuthState());
}
```

## 依存関係
- `flutter_riverpod`: 状態管理ライブラリ
- `AuthRepository`: 認証処理を実装するリポジトリ
- `AuthState`: 認証状態を表すデータクラス

## プロパティ
| プロパティ名 | 型 | 説明 |
|------------|-------|------|
| `authRepository` | `AuthRepository` | 認証処理を実装するリポジトリインスタンス |

## メソッド

#### `_initialize()`
```dart
Future<void> _initialize() async {
  try {
    // 既存の認証情報をチェック
    final user = await authRepository.getCurrentUser();
    if (user != null) {
      state = AuthState(
        user: user,
        status: AuthStatus.authenticated,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  } catch (e) {
    state = AuthState(
      status: AuthStatus.error,
      errorMessage: e.toString(),
    );
  }
}
```
**戻り値型**: `Future<void>`  
**説明**: AuthNotifierの初期化処理を行うプライベートメソッド。コンストラクタから呼び出され、既存の認証情報があるかどうかを確認します。

#### `signInWithEmailPassword(String email, String password)`
```dart
Future<void> signInWithEmailPassword(String email, String password) async {
  try {
    state = const AuthState(status: AuthStatus.loading);
    
    final user = await authRepository.signInWithEmailPassword(email, password);
    
    state = AuthState(
      user: user,
      status: AuthStatus.authenticated,
    );
  } catch (e) {
    state = AuthState(
      status: AuthStatus.error,
      errorMessage: e.toString(),
    );
    throw e; // UIでのエラーハンドリングのため再スロー
  }
}
```
**戻り値型**: `Future<void>`  
**パラメータ**:
- `email`: ユーザーのメールアドレス
- `password`: ユーザーのパスワード

**説明**: メールアドレスとパスワードを使用してユーザーを認証します。処理中は`loading`状態に、成功すると`authenticated`状態に、失敗すると`error`状態に状態を更新します。

#### `signInWithGoogle()`
```dart
Future<void> signInWithGoogle() async {
  try {
    state = const AuthState(status: AuthStatus.loading);
    
    final user = await authRepository.signInWithGoogle();
    
    state = AuthState(
      user: user,
      status: AuthStatus.authenticated,
    );
  } catch (e) {
    state = AuthState(
      status: AuthStatus.error,
      errorMessage: e.toString(),
    );
    throw e;
  }
}
```
**戻り値型**: `Future<void>`  
**説明**: Googleアカウントを使用してユーザーを認証します。処理中は`loading`状態に、成功すると`authenticated`状態に、失敗すると`error`状態に状態を更新します。

#### `signInWithApple()`
```dart
Future<void> signInWithApple() async {
  try {
    state = const AuthState(status: AuthStatus.loading);
    
    final user = await authRepository.signInWithApple();
    
    state = AuthState(
      user: user,
      status: AuthStatus.authenticated,
    );
  } catch (e) {
    state = AuthState(
      status: AuthStatus.error,
      errorMessage: e.toString(),
    );
    throw e;
  }
}
```
**戻り値型**: `Future<void>`  
**説明**: Appleアカウントを使用してユーザーを認証します。処理中は`loading`状態に、成功すると`authenticated`状態に、失敗すると`error`状態に状態を更新します。

#### `signOut()`
```dart
Future<void> signOut() async {
  try {
    await authRepository.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  } catch (e) {
    state = AuthState(
      status: AuthStatus.error,
      errorMessage: e.toString(),
    );
    throw e;
  }
}
```
**戻り値型**: `Future<void>`  
**説明**: ユーザーをログアウトし、状態を`unauthenticated`に更新します。失敗した場合は`error`状態に更新します。

# AuthState クラス

## 概要
`AuthState`は認証状態を表現するクラスです。現在のユーザー、認証ステータス、エラーメッセージなどの情報を保持します。

**ファイルパス**: `lib/presentation/state/states/auth_state.dart`

## クラス定義
```dart
class AuthState {
  final User? user;
  final AuthStatus status;
  final String? errorMessage;
  
  const AuthState({
    this.user,
    this.status = AuthStatus.initial,
    this.errorMessage,
  });
}
```

## 列挙型

### AuthStatus
```dart
enum AuthStatus {
  initial,      // 初期状態
  authenticated, // 認証済み
  unauthenticated, // 未認証
  loading,      // 認証処理中
  error,        // エラー発生
}
```
**説明**: 認証状態を表す列挙型。認証プロセスの様々な段階を表現します。

## プロパティ
| プロパティ名 | 型 | 説明 |
|------------|-------|------|
| `user` | `User?` | 認証されたユーザー情報。未認証の場合はnull |
| `status` | `AuthStatus` | 現在の認証ステータス |
| `errorMessage` | `String?` | エラーが発生した場合のメッセージ。エラーがない場合はnull |

## ゲッター

#### `isAuthenticated`
```dart
bool get isAuthenticated => status == AuthStatus.authenticated;
```
**戻り値型**: `bool`  
**説明**: ユーザーが認証済みかどうかを返す便利なゲッター。

#### `isLoading`
```dart
bool get isLoading => status == AuthStatus.loading;
```
**戻り値型**: `bool`  
**説明**: 認証処理中かどうかを返す便利なゲッター。

## メソッド

#### `copyWith({User? user, AuthStatus? status, String? errorMessage})`
```dart
AuthState copyWith({
  User? user,
  AuthStatus? status,
  String? errorMessage,
}) {
  return AuthState(
    user: user ?? this.user,
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}
```
**戻り値型**: `AuthState`  
**パラメータ**:
- `user`: 新しいユーザー情報（オプション）
- `status`: 新しい認証ステータス（オプション）
- `errorMessage`: 新しいエラーメッセージ（オプション）

**説明**: 現在のAuthStateのインスタンスを基に、指定されたプロパティだけを更新した新しいAuthStateインスタンスを作成します。イミュータブルなオブジェクトのパターンに従っています。