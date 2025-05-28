import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
      ),
      body: Center( // フォームを中央に配置
        child: SingleChildScrollView( // スクロール可能にする
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox( // 最大幅を設定
            constraints: const BoxConstraints(maxWidth: 400), // スマートフォンに適した最大幅
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // 1. アプリロゴ表示エリア (仮のテキストで代替)
                  const Text(
                    '家計簿アプリ ロゴ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent), // スタイル調整
                  ),
                  const SizedBox(height: 40.0), // 間隔調整

                  // エラーメッセージ表示エリア
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20.0), // 間隔調整
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 14), // スタイル調整
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // 2. メールアドレス入力フィールド
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'メールアドレス',
                      hintText: 'email@example.com',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'メールアドレスを入力してください。';
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) { // より正確なメール形式バリデーション
                        return '有効なメールアドレスを入力してください。';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // 3. パスワード入力フィールド
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'パスワード',
                      hintText: 'パスワードを入力',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'パスワードを入力してください。';
                      }
                      if (value.length < 8) {
                        return 'パスワードは8文字以上で入力してください。';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // 4. ログインボタン
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _errorMessage = null;
                        });
                        print('ログイン試行: ${_emailController.text}');
                        // TODO: 実際のログイン処理
                      } else {
                        setState(() {
                          _errorMessage = '入力内容をご確認ください。';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold), // スタイル調整
                    ),
                    child: const Text('ログイン'),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // 5. 「パスワードを忘れた場合」リンク
                  Align( // 右寄せにする
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        print('パスワードを忘れた場合');
                        // TODO: パスワードリセット画面への遷移
                      },
                      child: const Text('パスワードをお忘れですか？'),
                    ),
                  ),
                  const SizedBox(height: 24.0), // 間隔調整

                  // 6. 「新規登録」リンク
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('アカウントをお持ちでないですか？'),
                      TextButton(
                        onPressed: () {
                          print('新規登録画面へ');
                          // TODO: 新規登録画面への遷移
                        },
                        child: const Text('新規登録する'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
