# HomeScreen クラス

## 概要
`HomeScreen` はアプリケーションのメインホーム画面を実装するクラスです。ユーザーの家計状況の概要を表示し、月次の収支、カテゴリ別支出、最近の取引などを可視化します。

**ファイルパス**: `lib/presentation/screens/home/home_screen.dart`

## クラス定義
```dart
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 画面のレイアウトを構築
  }
}
```

## 依存関係
- `flutter_riverpod`: 状態管理のためのライブラリ
- `TransactionRepository`: 取引データを管理するリポジトリ
- `MonthlySummaryProvider`: 月次サマリーデータを提供するプロバイダー
- `CategorySummaryProvider`: カテゴリ別サマリーデータを提供するプロバイダー
- `RecentTransactionsProvider`: 最近の取引データを提供するプロバイダー

## メソッド

#### `_buildAppBar(BuildContext context, WidgetRef ref)`
**戻り値型**: `AppBar`  
**説明**: アプリケーションのトップバーを構築します。ユーザーのプロフィール、通知ボタン、設定アクセス等を含みます。

#### `_buildMonthlySummary(BuildContext context, WidgetRef ref)`
**戻り値型**: `Widget`  
**説明**: 当月の収支サマリーを表示するカードウィジェットを構築します。収入合計、支出合計、残高を表示します。

#### `_buildCategoryChart(BuildContext context, WidgetRef ref)`
**戻り値型**: `Widget`  
**説明**: カテゴリ別の支出を円グラフまたは棒グラフで視覚化するウィジェットを構築します。

#### `_buildMonthSelector(BuildContext context, WidgetRef ref)`
**戻り値型**: `Widget`  
**説明**: 月を選択するためのセレクターウィジェットを構築します。選択した月に応じてデータを更新します。

#### `_buildRecentTransactions(BuildContext context, WidgetRef ref)`
**戻り値型**: `Widget`  
**説明**: 最近の取引履歴を表示するリストを構築します。各項目には日付、カテゴリ、金額が表示されます。

#### `_buildBudgetProgress(BuildContext context, WidgetRef ref)`
**戻り値型**: `Widget`  
**説明**: 予算に対する現在の支出状況をプログレスバーで表示します。カテゴリごとの予算達成度も視覚化します。

#### `_buildQuickActions(BuildContext context)`
**戻り値型**: `Widget`  
**説明**: 新規取引の追加や取引履歴へのアクセスなど、頻繁に使用される機能へのショートカットを構築します。

#### `_navigateToAddTransaction(BuildContext context)`
**戻り値型**: `void`  
**説明**: 新規取引入力画面に遷移するためのナビゲーション処理を実行します。

#### `_navigateToTransactionHistory(BuildContext context)`
**戻り値型**: `void`  
**説明**: 取引履歴一覧画面に遷移するためのナビゲーション処理を実行します。

#### `_navigateToAnalytics(BuildContext context)`
**戻り値型**: `void`  
**説明**: 詳細な分析グラフ画面に遷移するためのナビゲーション処理を実行します。

## インタラクション処理

#### 月の切り替え
```dart
void _onMonthChanged(DateTime newDate) {
  final monthYearProvider = ref.read(selectedMonthYearProvider.notifier);
  monthYearProvider.state = newDate;
  
  // 選択した月のデータをリロード
  ref.refresh(monthlySummaryProvider);
  ref.refresh(categoryExpensesProvider);
  ref.refresh(recentTransactionsProvider);
}
```
**説明**: ユーザーが月を変更した際に、関連するすべてのデータプロバイダーを新しい月のデータでリフレッシュします。

#### 取引追加ボタン処理
```dart
Future<void> _onAddTransactionPressed(BuildContext context) async {
  final result = await Navigator.of(context).pushNamed('/add-transaction');
  
  if (result == true) {
    // 新しい取引が追加された場合、データをリフレッシュ
    ref.refresh(monthlySummaryProvider);
    ref.refresh(categoryExpensesProvider);
    ref.refresh(recentTransactionsProvider);
  }
}
```
**説明**: 新規取引追加ボタンがタップされたときの処理を実装します。取引追加画面に遷移し、取引が追加された場合はデータを更新します。

## リスポンシブ対応

#### 画面サイズに応じたレイアウト変更
```dart
Widget _buildResponsiveLayout(BuildContext context, WidgetRef ref) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  if (screenWidth > 840) {
    // タブレット/デスクトップ向けレイアウト
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildMonthlySummary(context, ref),
              _buildBudgetProgress(context, ref),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _buildCategoryChart(context, ref),
              _buildRecentTransactions(context, ref),
            ],
          ),
        ),
      ],
    );
  } else {
    // スマートフォン向けレイアウト
    return Column(
      children: [
        _buildMonthlySummary(context, ref),
        _buildCategoryChart(context, ref),
        _buildBudgetProgress(context, ref),
        _buildRecentTransactions(context, ref),
      ],
    );
  }
}
```
**説明**: 画面サイズに応じてレイアウトを変更し、様々なデバイスで最適な表示を提供します。
