# ホーム画面 Provider クラス

## 概要
ホーム画面で使用される主要な Provider クラスの定義です。Riverpod を用いた状態管理と、データの取得・加工・提供を担当します。

**ファイルパス**: `lib/presentation/state/providers/home_providers.dart`

## Provider 定義

### selectedMonthYearProvider

```dart
/// 選択された年月を管理するStateProvider
final selectedMonthYearProvider = StateProvider<DateTime>((ref) {
  // デフォルトで現在の月を選択
  return DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
});
```

**説明**: 現在選択されている年月を保持するStateProvider。ユーザーが月を切り替えると、このプロバイダーの状態が更新されます。

### monthlySummaryProvider

```dart
/// 月間サマリー情報を提供するFutureProvider
final monthlySummaryProvider = FutureProvider.autoDispose<MonthlySummary>((ref) async {
  // 選択中の年月を取得
  final selectedDate = ref.watch(selectedMonthYearProvider);
  
  // 取引リポジトリからデータ取得
  final repository = ref.read(transactionRepositoryProvider);
  
  // 指定月の開始日と終了日
  final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
  
  // 収入と支出を取得
  final income = await repository.getTotalIncome(startDate, endDate);
  final expense = await repository.getTotalExpense(startDate, endDate);
  
  // サマリー情報を作成して返却
  return MonthlySummary(
    month: selectedDate,
    income: income,
    expense: expense,
    balance: income - expense,
  );
});
```

**説明**: 選択中の月の収入、支出、残高などの月間サマリー情報を提供するFutureProvider。選択月が変更されると自動的に最新データを取得します。

### categoryExpensesProvider

```dart
/// カテゴリ別支出情報を提供するFutureProvider
final categoryExpensesProvider = FutureProvider.autoDispose<List<CategoryExpense>>((ref) async {
  // 選択中の年月を取得
  final selectedDate = ref.watch(selectedMonthYearProvider);
  
  // 取引リポジトリからデータ取得
  final repository = ref.read(transactionRepositoryProvider);
  
  // 指定月の開始日と終了日
  final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
  
  // カテゴリ別支出を取得
  final categoryExpenses = await repository.getCategoryExpenses(startDate, endDate);
  
  // 金額に基づいて降順でソート
  categoryExpenses.sort((a, b) => b.amount.compareTo(a.amount));
  
  return categoryExpenses;
});
```

**説明**: 選択中の月のカテゴリ別支出情報を提供するFutureProvider。グラフ表示やカテゴリリストの表示に使用されます。

### recentTransactionsProvider

```dart
/// 最近の取引情報を提供するFutureProvider
final recentTransactionsProvider = FutureProvider.autoDispose<List<Transaction>>((ref) async {
  // 選択中の年月を取得
  final selectedDate = ref.watch(selectedMonthYearProvider);
  
  // 取引リポジトリからデータ取得
  final repository = ref.read(transactionRepositoryProvider);
  
  // 指定月の開始日と終了日
  final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
  
  // 最近の取引を取得（最新の5件）
  final transactions = await repository.getTransactions(
    startDate: startDate,
    endDate: endDate,
    limit: 5,
  );
  
  // 日付順（新しい順）でソート
  transactions.sort((a, b) => b.date.compareTo(a.date));
  
  return transactions;
});
```

**説明**: 選択中の月の最新の取引データを提供するFutureProvider。ホーム画面に表示する最近の取引リストに使用されます。

### budgetProgressProvider

```dart
/// 予算進捗状況を提供するFutureProvider
final budgetProgressProvider = FutureProvider.autoDispose<BudgetProgress>((ref) async {
  // 選択中の年月を取得
  final selectedDate = ref.watch(selectedMonthYearProvider);
  
  // 予算リポジトリと取引リポジトリからデータ取得
  final budgetRepository = ref.read(budgetRepositoryProvider);
  final transactionRepository = ref.read(transactionRepositoryProvider);
  
  // 指定月の開始日と終了日
  final startDate = DateTime(selectedDate.year, selectedDate.month, 1);
  final endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
  
  // 月の予算を取得
  final budget = await budgetRepository.getMonthlyBudget(selectedDate.year, selectedDate.month);
  
  // 現在の支出を取得
  final currentExpense = await transactionRepository.getTotalExpense(startDate, endDate);
  
  // カテゴリ別の予算と実際の支出を取得
  final categoryBudgets = await budgetRepository.getCategoryBudgets(selectedDate.year, selectedDate.month);
  final categoryExpenses = await transactionRepository.getCategoryExpenses(startDate, endDate);
  
  // カテゴリ別の予算進捗を計算
  final categoryProgress = categoryBudgets.map((budgetItem) {
    final categoryExpense = categoryExpenses.firstWhere(
      (expense) => expense.categoryId == budgetItem.categoryId,
      orElse: () => CategoryExpense(
        categoryId: budgetItem.categoryId,
        categoryName: budgetItem.categoryName,
        amount: 0,
        color: budgetItem.color,
      ),
    );
    
    return CategoryBudgetProgress(
      categoryId: budgetItem.categoryId,
      categoryName: budgetItem.categoryName,
      budgetAmount: budgetItem.amount,
      expenseAmount: categoryExpense.amount,
      color: budgetItem.color,
    );
  }).toList();
  
  // 総合的な予算進捗情報を返却
  return BudgetProgress(
    totalBudget: budget,
    totalExpense: currentExpense,
    percentage: budget > 0 ? (currentExpense / budget * 100) : 0,
    categoryProgress: categoryProgress,
  );
});
```

**説明**: 予算に対する進捗状況を提供するFutureProvider。総予算に対する消費率や、カテゴリごとの予算使用状況を提供します。

## データモデル

### MonthlySummary

```dart
/// 月間サマリーデータモデル
class MonthlySummary {
  /// 対象月
  final DateTime month;
  
  /// 収入合計
  final double income;
  
  /// 支出合計
  final double expense;
  
  /// 残高（収入 - 支出）
  final double balance;
  
  /// 前月比（%）
  final double? monthOverMonthPercentage;
  
  const MonthlySummary({
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
    this.monthOverMonthPercentage,
  });
}
```

### CategoryExpense

```dart
/// カテゴリ別支出データモデル
class CategoryExpense {
  /// カテゴリID
  final String categoryId;
  
  /// カテゴリ名
  final String categoryName;
  
  /// 支出金額
  final double amount;
  
  /// カテゴリの表示色
  final Color color;
  
  /// 全体に占める割合（%）
  double? percentage;
  
  CategoryExpense({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.color,
    this.percentage,
  });
}
```

### BudgetProgress

```dart
/// 予算進捗データモデル
class BudgetProgress {
  /// 月の合計予算
  final double totalBudget;
  
  /// 現在の合計支出
  final double totalExpense;
  
  /// 予算消費率（%）
  final double percentage;
  
  /// カテゴリ別の予算進捗
  final List<CategoryBudgetProgress> categoryProgress;
  
  /// 残りの予算
  double get remaining => totalBudget - totalExpense;
  
  /// 予算オーバーしているかどうか
  bool get isOverBudget => totalExpense > totalBudget;
  
  const BudgetProgress({
    required this.totalBudget,
    required this.totalExpense,
    required this.percentage,
    required this.categoryProgress,
  });
}
```

### CategoryBudgetProgress

```dart
/// カテゴリ別予算進捗データモデル
class CategoryBudgetProgress {
  /// カテゴリID
  final String categoryId;
  
  /// カテゴリ名
  final String categoryName;
  
  /// 予算額
  final double budgetAmount;
  
  /// 現在の支出額
  final double expenseAmount;
  
  /// カテゴリの表示色
  final Color color;
  
  /// 予算消費率（%）
  double get percentage => budgetAmount > 0 ? (expenseAmount / budgetAmount * 100) : 0;
  
  /// 残りの予算
  double get remaining => budgetAmount - expenseAmount;
  
  /// 予算オーバーしているかどうか
  bool get isOverBudget => expenseAmount > budgetAmount;
  
  const CategoryBudgetProgress({
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmount,
    required this.expenseAmount,
    required this.color,
  });
}
```
