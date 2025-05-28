# Riverpod状態管理設計書

---

## 1. ドキュメント管理

- 文書名: Riverpod状態管理設計書
- 作成者: 廣澤
- 作成日: 2025-05-16

---

## 2. 概要

本文書は、家計簿アプリにおけるRiverpodを使用した状態管理の詳細設計を定義します。MVVMアーキテクチャにおけるViewModelの役割をRiverpodのプロバイダーで実装し、UIとビジネスロジックを効果的に分離します。

---

## 3. 状態管理の基本方針

### 3.1 プロバイダーの種類と使い分け

| プロバイダータイプ | 役割 | 使用シナリオ |
|-----------------|------|-------------|
| Provider | 単純な値や計算値の提供 | 依存性注入、計算値、定数 |
| StateProvider | シンプルな状態管理 | フィルターの選択状態、フォームの値など |
| StateNotifierProvider | 複雑な状態管理 | リスト操作、複数の状態を持つ画面など |
| FutureProvider | 非同期データ取得 | APIからの単発データ取得 |
| StreamProvider | ストリームデータ監視 | リアルタイムアップデート、Firestoreの変更監視 |

### 3.2 状態管理の階層設計

```
presentation/
  └── state/
      ├── providers/                # 各機能のプロバイダー定義
      │   ├── auth_providers.dart
      │   ├── transaction_providers.dart
      │   ├── category_providers.dart
      │   ├── budget_providers.dart
      │   ├── settings_providers.dart
      │   └── ...
      │
      ├── notifiers/                # StateNotifierの実装
      │   ├── auth_notifier.dart
      │   ├── transaction_notifier.dart
      │   ├── category_notifier.dart
      │   ├── budget_notifier.dart
      │   └── ...
      │
      └── states/                   # 状態クラスの定義
          ├── auth_state.dart
          ├── transaction_state.dart
          ├── category_state.dart
          ├── budget_state.dart
          └── ...
```

---

## 4. 状態クラス設計

各機能の状態を表現する状態クラスを定義します。これらはimmutableであり、状態の変更はcopyWithメソッドを通じて行います。

### 4.1 認証状態 (AuthState)

```dart
enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
  error,
}

class AuthState extends Equatable {
  final User? user;
  final AuthStatus status;
  final String? errorMessage;
  
  const AuthState({
    this.user,
    this.status = AuthStatus.initial,
    this.errorMessage,
  });
  
  bool get isAuthenticated => status == AuthStatus.authenticated;
  
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
  
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }
  
  factory AuthState.authenticated(User user) {
    return AuthState(
      user: user,
      status: AuthStatus.authenticated,
    );
  }
  
  factory AuthState.unauthenticated() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }
  
  factory AuthState.loading() {
    return const AuthState(status: AuthStatus.loading);
  }
  
  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      errorMessage: message,
    );
  }
  
  @override
  List<Object?> get props => [user, status, errorMessage];
}
```

### 4.2 取引状態 (TransactionState)

```dart
enum TransactionStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

class TransactionState extends Equatable {
  final List<Transaction> transactions;
  final TransactionStatus status;
  final String? errorMessage;
  final bool hasMore;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionType? filterType;
  final String? filterCategoryId;
  
  const TransactionState({
    this.transactions = const [],
    this.status = TransactionStatus.initial,
    this.errorMessage,
    this.hasMore = true,
    this.startDate,
    this.endDate,
    this.filterType,
    this.filterCategoryId,
  });
  
  TransactionState copyWith({
    List<Transaction>? transactions,
    TransactionStatus? status,
    String? errorMessage,
    bool? hasMore,
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? filterType,
    String? filterCategoryId,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      filterType: filterType ?? this.filterType,
      filterCategoryId: filterCategoryId ?? this.filterCategoryId,
    );
  }
  
  // 集計用ヘルパーメソッド
  double get totalIncome => transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0, (sum, transaction) => sum + transaction.amount);
      
  double get totalExpense => transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0, (sum, transaction) => sum + transaction.amount);
      
  double get balance => totalIncome - totalExpense;
  
  @override
  List<Object?> get props => [
    transactions,
    status,
    errorMessage,
    hasMore,
    startDate,
    endDate,
    filterType,
    filterCategoryId,
  ];
}
```

### 4.3 カテゴリ状態 (CategoryState)

```dart
enum CategoryStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

class CategoryState extends Equatable {
  final List<Category> categories;
  final CategoryStatus status;
  final String? errorMessage;
  final CategoryType? filterType;
  
  const CategoryState({
    this.categories = const [],
    this.status = CategoryStatus.initial,
    this.errorMessage,
    this.filterType,
  });
  
  List<Category> get incomeCategories => categories
      .where((c) => c.type == CategoryType.income || c.type == CategoryType.both)
      .toList();
      
  List<Category> get expenseCategories => categories
      .where((c) => c.type == CategoryType.expense || c.type == CategoryType.both)
      .toList();
  
  CategoryState copyWith({
    List<Category>? categories,
    CategoryStatus? status,
    String? errorMessage,
    CategoryType? filterType,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      filterType: filterType ?? this.filterType,
    );
  }
  
  @override
  List<Object?> get props => [
    categories,
    status,
    errorMessage,
    filterType,
  ];
}
```

### 4.4 予算状態 (BudgetState)

```dart
enum BudgetStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

class BudgetState extends Equatable {
  final Budget? budget;
  final double budgetUsageRate;
  final BudgetStatus status;
  final String? errorMessage;
  final int year;
  final int month;
  
  const BudgetState({
    this.budget,
    this.budgetUsageRate = 0.0,
    this.status = BudgetStatus.initial,
    this.errorMessage,
    required this.year,
    required this.month,
  });
  
  BudgetState copyWith({
    Budget? budget,
    double? budgetUsageRate,
    BudgetStatus? status,
    String? errorMessage,
    int? year,
    int? month,
  }) {
    return BudgetState(
      budget: budget ?? this.budget,
      budgetUsageRate: budgetUsageRate ?? this.budgetUsageRate,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      year: year ?? this.year,
      month: month ?? this.month,
    );
  }
  
  // ヘルパーメソッド
  bool get hasActiveBudget => budget != null && budget!.amount > 0;
  
  double get remainingBudget => 
      hasActiveBudget ? budget!.amount * (1 - budgetUsageRate) : 0;
  
  bool get isOverBudget => budgetUsageRate > 1.0;
  
  @override
  List<Object?> get props => [
    budget,
    budgetUsageRate,
    status,
    errorMessage,
    year,
    month,
  ];
}
```

### 4.5 ユーザー設定状態 (UserSettingsState)

```dart
enum UserSettingsStatus {
  initial,
  loading,
  loaded,
  updating,
  error,
}

class UserSettingsState extends Equatable {
  final UserSettings? settings;
  final UserSettingsStatus status;
  final String? errorMessage;
  
  const UserSettingsState({
    this.settings,
    this.status = UserSettingsStatus.initial,
    this.errorMessage,
  });
  
  // デフォルト値を返すゲッター
  bool get notificationsEnabled => settings?.notificationsEnabled ?? true;
  bool get inputReminderEnabled => settings?.inputReminderEnabled ?? true;
  bool get budgetAlertEnabled => settings?.budgetAlertEnabled ?? true;
  String get language => settings?.language ?? 'ja';
  String get currencyCode => settings?.currencyCode ?? 'JPY';
  bool get isDarkMode => settings?.isDarkMode ?? false;
  
  UserSettingsState copyWith({
    UserSettings? settings,
    UserSettingsStatus? status,
    String? errorMessage,
  }) {
    return UserSettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
  
  @override
  List<Object?> get props => [settings, status, errorMessage];
}
```

---

## 5. StateNotifier の実装

各状態を管理するStateNotifierを実装します。

### 5.1 認証管理 (AuthNotifier)

```dart
class AuthNotifier extends StateNotifier<AuthState> {
  final UserRepository userRepository;
  StreamSubscription<User?>? _authSubscription;
  
  AuthNotifier({required this.userRepository}) : super(AuthState.initial()) {
    _initialize();
  }
  
  void _initialize() {
    state = AuthState.loading();
    _authSubscription = userRepository.authStateChanges().listen(
      (user) {
        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.unauthenticated();
        }
      },
      onError: (error) {
        state = AuthState.error(error.toString());
      },
    );
  }
  
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      state = AuthState.loading();
      final user = await userRepository.signInWithEmailPassword(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  Future<void> signUpWithEmailPassword(
    String email,
    String password,
    String? displayName,
  ) async {
    try {
      state = AuthState.loading();
      final user = await userRepository.signUpWithEmailPassword(
        email,
        password,
        displayName,
      );
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  Future<void> signInWithGoogle() async {
    try {
      state = AuthState.loading();
      final user = await userRepository.signInWithGoogle();
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  Future<void> signOut() async {
    try {
      await userRepository.signOut();
      state = AuthState.unauthenticated();
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  Future<void> resetPassword(String email) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      await userRepository.resetPassword(email);
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);
      await userRepository.updateUserProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      final user = await userRepository.getCurrentUser();
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }
  
  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
```

### 5.2 取引管理 (TransactionNotifier)

```dart
class TransactionNotifier extends StateNotifier<TransactionState> {
  final TransactionRepository transactionRepository;
  StreamSubscription<List<Transaction>>? _transactionsSubscription;
  
  TransactionNotifier({required this.transactionRepository})
      : super(const TransactionState());
  
  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? filterType,
    String? filterCategoryId,
  }) async {
    try {
      state = state.copyWith(
        status: TransactionStatus.loading,
        startDate: startDate,
        endDate: endDate,
        filterType: filterType,
        filterCategoryId: filterCategoryId,
      );
      
      // 前の購読をキャンセル
      await _transactionsSubscription?.cancel();
      
      // 新しい購読を開始
      _transactionsSubscription = transactionRepository
          .watchTransactions(
            startDate: startDate,
            endDate: endDate,
            type: filterType,
            categoryId: filterCategoryId,
          )
          .listen(
            (transactions) {
              state = state.copyWith(
                transactions: transactions,
                status: TransactionStatus.loaded,
              );
            },
            onError: (error) {
              state = state.copyWith(
                status: TransactionStatus.error,
                errorMessage: error.toString(),
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        status: TransactionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> loadTransactionsByMonth(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0);
    
    await loadTransactions(
      startDate: startDate,
      endDate: endDate,
      filterType: state.filterType,
      filterCategoryId: state.filterCategoryId,
    );
  }
  
  Future<void> addTransaction(Transaction transaction) async {
    try {
      state = state.copyWith(status: TransactionStatus.updating);
      await transactionRepository.addTransaction(transaction);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: TransactionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      state = state.copyWith(status: TransactionStatus.updating);
      await transactionRepository.updateTransaction(transaction);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: TransactionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> deleteTransaction(String id) async {
    try {
      state = state.copyWith(status: TransactionStatus.updating);
      await transactionRepository.deleteTransaction(id);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: TransactionStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  void filterByType(TransactionType? type) {
    loadTransactions(
      startDate: state.startDate,
      endDate: state.endDate,
      filterType: type,
      filterCategoryId: state.filterCategoryId,
    );
  }
  
  void filterByCategory(String? categoryId) {
    loadTransactions(
      startDate: state.startDate,
      endDate: state.endDate,
      filterType: state.filterType,
      filterCategoryId: categoryId,
    );
  }
  
  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    super.dispose();
  }
}
```

### 5.3 カテゴリ管理 (CategoryNotifier)

```dart
class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryRepository categoryRepository;
  StreamSubscription<List<Category>>? _categoriesSubscription;
  
  CategoryNotifier({required this.categoryRepository})
      : super(const CategoryState()) {
    loadCategories();
  }
  
  Future<void> loadCategories({CategoryType? filterType}) async {
    try {
      state = state.copyWith(
        status: CategoryStatus.loading,
        filterType: filterType,
      );
      
      // 前の購読をキャンセル
      await _categoriesSubscription?.cancel();
      
      // 新しい購読を開始
      _categoriesSubscription = categoryRepository
          .watchCategories(type: filterType)
          .listen(
            (categories) {
              state = state.copyWith(
                categories: categories,
                status: CategoryStatus.loaded,
              );
            },
            onError: (error) {
              state = state.copyWith(
                status: CategoryStatus.error,
                errorMessage: error.toString(),
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> addCategory(Category category) async {
    try {
      state = state.copyWith(status: CategoryStatus.updating);
      await categoryRepository.addCategory(category);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> updateCategory(Category category) async {
    try {
      state = state.copyWith(status: CategoryStatus.updating);
      await categoryRepository.updateCategory(category);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> deleteCategory(String id) async {
    try {
      state = state.copyWith(status: CategoryStatus.updating);
      await categoryRepository.deleteCategory(id);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: CategoryStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  void filterByType(CategoryType? type) {
    loadCategories(filterType: type);
  }
  
  @override
  void dispose() {
    _categoriesSubscription?.cancel();
    super.dispose();
  }
}
```

### 5.4 予算管理 (BudgetNotifier)

```dart
class BudgetNotifier extends StateNotifier<BudgetState> {
  final BudgetRepository budgetRepository;
  final TransactionRepository transactionRepository;
  StreamSubscription<Budget?>? _budgetSubscription;
  
  BudgetNotifier({
    required this.budgetRepository,
    required this.transactionRepository,
  }) : super(BudgetState(
    year: DateTime.now().year,
    month: DateTime.now().month,
  )) {
    loadBudget(state.year, state.month);
  }
  
  Future<void> loadBudget(int year, int month) async {
    try {
      state = state.copyWith(
        status: BudgetStatus.loading,
        year: year,
        month: month,
      );
      
      // 前の購読をキャンセル
      await _budgetSubscription?.cancel();
      
      // 新しい購読を開始
      _budgetSubscription = budgetRepository
          .watchBudget(year, month)
          .listen(
            (budget) async {
              final budgetUsageRate = await budgetRepository.getBudgetUsageRate(year, month);
              
              state = state.copyWith(
                budget: budget,
                budgetUsageRate: budgetUsageRate,
                status: BudgetStatus.loaded,
              );
            },
            onError: (error) {
              state = state.copyWith(
                status: BudgetStatus.error,
                errorMessage: error.toString(),
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        status: BudgetStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> setBudget(double amount) async {
    try {
      state = state.copyWith(status: BudgetStatus.updating);
      
      final now = DateTime.now();
      final budget = Budget(
        id: state.budget?.id ?? '',
        userId: '',  // リポジトリ内で処理
        amount: amount,
        year: state.year,
        month: state.month,
        createdAt: state.budget?.createdAt ?? now,
        updatedAt: now,
      );
      
      await budgetRepository.setBudget(budget);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: BudgetStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  void changeMonth(int year, int month) {
    loadBudget(year, month);
  }
  
  @override
  void dispose() {
    _budgetSubscription?.cancel();
    super.dispose();
  }
}
```

### 5.5 ユーザー設定管理 (UserSettingsNotifier)

```dart
class UserSettingsNotifier extends StateNotifier<UserSettingsState> {
  final UserSettingsRepository userSettingsRepository;
  StreamSubscription<UserSettings>? _settingsSubscription;
  
  UserSettingsNotifier({
    required this.userSettingsRepository,
  }) : super(const UserSettingsState()) {
    loadSettings();
  }
  
  Future<void> loadSettings() async {
    try {
      state = state.copyWith(status: UserSettingsStatus.loading);
      
      // 前の購読をキャンセル
      await _settingsSubscription?.cancel();
      
      // 新しい購読を開始
      _settingsSubscription = userSettingsRepository
          .watchUserSettings()
          .listen(
            (settings) {
              state = state.copyWith(
                settings: settings,
                status: UserSettingsStatus.loaded,
              );
            },
            onError: (error) {
              state = state.copyWith(
                status: UserSettingsStatus.error,
                errorMessage: error.toString(),
              );
            },
          );
    } catch (e) {
      state = state.copyWith(
        status: UserSettingsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> updateNotificationSettings({
    bool? notificationsEnabled,
    bool? inputReminderEnabled,
    bool? budgetAlertEnabled,
  }) async {
    try {
      state = state.copyWith(status: UserSettingsStatus.updating);
      
      await userSettingsRepository.updateNotificationSettings(
        notificationsEnabled: notificationsEnabled,
        inputReminderEnabled: inputReminderEnabled,
        budgetAlertEnabled: budgetAlertEnabled,
      );
      
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: UserSettingsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> updateLanguage(String languageCode) async {
    try {
      state = state.copyWith(status: UserSettingsStatus.updating);
      await userSettingsRepository.updateLanguage(languageCode);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: UserSettingsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> updateCurrency(String currencyCode) async {
    try {
      state = state.copyWith(status: UserSettingsStatus.updating);
      await userSettingsRepository.updateCurrency(currencyCode);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: UserSettingsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  Future<void> updateThemeMode(bool isDarkMode) async {
    try {
      state = state.copyWith(status: UserSettingsStatus.updating);
      await userSettingsRepository.updateThemeMode(isDarkMode);
      // 自動的にリスナーが更新を検知するため、ここで再取得は不要
    } catch (e) {
      state = state.copyWith(
        status: UserSettingsStatus.error,
        errorMessage: e.toString(),
      );
    }
  }
  
  @override
  void dispose() {
    _settingsSubscription?.cancel();
    super.dispose();
  }
}
```

---

## 6. プロバイダー定義

Riverpodのプロバイダーを定義し、アプリ全体から状態にアクセスできるようにします。

### 6.1 認証プロバイダー

```dart
// 認証状態管理プロバイダー
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    userRepository: ref.watch(userRepositoryProvider),
  );
});

// 簡単にアクセスするためのセレクター
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).errorMessage;
});
```

### 6.2 取引プロバイダー

```dart
// 取引状態管理プロバイダー
final transactionProvider = StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

// 月間サマリープロバイダー
final monthlySummaryProvider = FutureProvider.family<MonthlySummary, ({int year, int month})>((ref, params) async {
  final repository = ref.read(transactionRepositoryProvider);
  return repository.getMonthlySummary(params.year, params.month);
});

// カテゴリ別サマリープロバイダー
final categorySummaryProvider = FutureProvider.family<List<CategorySummary>, ({int year, int month, TransactionType type})>((ref, params) async {
  final repository = ref.read(transactionRepositoryProvider);
  return repository.getCategorySummary(params.year, params.month, params.type);
});

// 年間サマリープロバイダー
final yearlySummaryProvider = FutureProvider.family<YearlySummary, int>((ref, year) async {
  final repository = ref.read(transactionRepositoryProvider);
  return repository.getYearlySummary(year);
});

// 総収入プロバイダー
final totalIncomeProvider = Provider<double>((ref) {
  return ref.watch(transactionProvider).totalIncome;
});

// 総支出プロバイダー
final totalExpenseProvider = Provider<double>((ref) {
  return ref.watch(transactionProvider).totalExpense;
});

// 残高プロバイダー
final balanceProvider = Provider<double>((ref) {
  return ref.watch(transactionProvider).balance;
});
```

### 6.3 カテゴリプロバイダー

```dart
// カテゴリ状態管理プロバイダー
final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
});

// 収入カテゴリプロバイダー
final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoryProvider).incomeCategories;
});

// 支出カテゴリプロバイダー
final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(categoryProvider).expenseCategories;
});

// 特定カテゴリプロバイダー
final categoryByIdProvider = Provider.family<Category?, String>((ref, id) {
  final categories = ref.watch(categoryProvider).categories;
  return categories.firstWhereOrNull((category) => category.id == id);
});
```

### 6.4 予算プロバイダー

```dart
// 予算状態管理プロバイダー
final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((ref) {
  return BudgetNotifier(
    budgetRepository: ref.watch(budgetRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

// 現在の予算額プロバイダー
final currentBudgetAmountProvider = Provider<double?>((ref) {
  return ref.watch(budgetProvider).budget?.amount;
});

// 予算使用率プロバイダー
final budgetUsageRateProvider = Provider<double>((ref) {
  return ref.watch(budgetProvider).budgetUsageRate;
});

// 予算残額プロバイダー
final remainingBudgetProvider = Provider<double>((ref) {
  return ref.watch(budgetProvider).remainingBudget;
});

// 予算超過フラグプロバイダー
final isOverBudgetProvider = Provider<bool>((ref) {
  return ref.watch(budgetProvider).isOverBudget;
});
```

### 6.5 ユーザー設定プロバイダー

```dart
// ユーザー設定状態管理プロバイダー
final userSettingsProvider = StateNotifierProvider<UserSettingsNotifier, UserSettingsState>((ref) {
  return UserSettingsNotifier(
    userSettingsRepository: ref.watch(userSettingsRepositoryProvider),
  );
});

// 通知設定プロバイダー
final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider).notificationsEnabled;
});

// 入力リマインダー設定プロバイダー
final inputReminderEnabledProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider).inputReminderEnabled;
});

// 予算アラート設定プロバイダー
final budgetAlertEnabledProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider).budgetAlertEnabled;
});

// 言語設定プロバイダー
final languageProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).language;
});

// 通貨設定プロバイダー
final currencyCodeProvider = Provider<String>((ref) {
  return ref.watch(userSettingsProvider).currencyCode;
});

// テーマモード設定プロバイダー
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(userSettingsProvider).isDarkMode;
});
```

---

## 7. UI連携パターン

Riverpod状態をUIと連携する典型的なパターンを示します。

### 7.1 ConsumerWidgetを使用したサンプル

```dart
class TransactionListScreen extends ConsumerWidget {
  const TransactionListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 取引状態の監視
    final transactionState = ref.watch(transactionProvider);
    
    // 日付フィルターの状態管理
    final selectedYear = useState(DateTime.now().year);
    final selectedMonth = useState(DateTime.now().month);
    
    // 画面表示時に取引データをロード
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(transactionProvider.notifier).loadTransactionsByMonth(
          selectedYear.value,
          selectedMonth.value,
        );
      });
      return null;
    }, [selectedYear.value, selectedMonth.value]);
    
    // ローディング表示
    if (transactionState.status == TransactionStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // エラー表示
    if (transactionState.status == TransactionStatus.error) {
      return Center(
        child: Text('エラーが発生しました: ${transactionState.errorMessage}'),
      );
    }
    
    // データが空の場合
    if (transactionState.transactions.isEmpty) {
      return const Center(
        child: Text('取引データがありません。新しい取引を追加してください。'),
      );
    }
    
    // 取引データの表示
    return ListView.builder(
      itemCount: transactionState.transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactionState.transactions[index];
        // カテゴリ情報の取得
        final category = ref.watch(categoryByIdProvider(transaction.categoryId));
        
        return ListTile(
          title: Text(category?.name ?? '不明なカテゴリ'),
          subtitle: Text(transaction.date.toString().substring(0, 10)),
          trailing: Text(
            '${transaction.type == TransactionType.income ? '+' : '-'}¥${transaction.amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: transaction.type == TransactionType.income
                ? Colors.green
                : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            // 詳細画面への遷移
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TransactionDetailScreen(transaction: transaction),
              ),
            );
          },
        );
      },
    );
  }
}
```

### 7.2 ConsumerStatefulWidgetを使用したサンプル

```dart
class TransactionFormScreen extends ConsumerStatefulWidget {
  final Transaction? transaction; // 編集時は既存のトランザクション、新規作成時はnull
  
  const TransactionFormScreen({Key? key, this.transaction}) : super(key: key);

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionType _selectedType;
  String? _selectedCategoryId;
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;
  
  @override
  void initState() {
    super.initState();
    
    // 編集時は初期値を設定
    if (widget.transaction != null) {
      _selectedType = widget.transaction!.type;
      _selectedCategoryId = widget.transaction!.categoryId;
      _amountController.text = widget.transaction!.amount.toString();
      _memoController.text = widget.transaction!.memo ?? '';
      _selectedDate = widget.transaction!.date;
      _isRecurring = widget.transaction!.isRecurring;
    } else {
      _selectedType = TransactionType.expense; // デフォルトは支出
    }
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }
  
  void _submitForm() async {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      final amount = double.parse(_amountController.text);
      final now = DateTime.now();
      
      final transactionToSave = Transaction(
        id: widget.transaction?.id ?? '',
        userId: '', // リポジトリ内で設定される
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        date: _selectedDate,
        memo: _memoController.text.isEmpty ? null : _memoController.text,
        isRecurring: _isRecurring,
        createdAt: widget.transaction?.createdAt ?? now,
        updatedAt: now,
      );
      
      try {
        if (widget.transaction == null) {
          // 新規作成
          await ref.read(transactionProvider.notifier).addTransaction(transactionToSave);
        } else {
          // 更新
          await ref.read(transactionProvider.notifier).updateTransaction(transactionToSave);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存しました')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('エラーが発生しました: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('入力内容を確認してください')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // カテゴリリストの取得
    final categories = _selectedType == TransactionType.income
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(expenseCategoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? '新規登録' : '取引編集'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 取引タイプの選択（収入/支出）
            Row(
              children: [
                Expanded(
                  child: RadioListTile<TransactionType>(
                    title: const Text('支出'),
                    value: TransactionType.expense,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _selectedCategoryId = null; // カテゴリをリセット
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<TransactionType>(
                    title: const Text('収入'),
                    value: TransactionType.income,
                    groupValue: _selectedType,
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value!;
                        _selectedCategoryId = null; // カテゴリをリセット
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // カテゴリの選択
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                border: OutlineInputBorder(),
              ),
              value: _selectedCategoryId,
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.id,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              validator: (value) => value == null ? 'カテゴリを選択してください' : null,
            ),
            
            const SizedBox(height: 16),
            
            // 金額入力
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '金額',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '金額を入力してください';
                }
                if (double.tryParse(value) == null) {
                  return '有効な数値を入力してください';
                }
                if (double.parse(value) <= 0) {
                  return '金額は0より大きい値を入力してください';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // 日付選択
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '日付',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat('yyyy/MM/dd').format(_selectedDate),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // メモ入力
            TextFormField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'メモ（任意）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // 定期収支設定
            SwitchListTile(
              title: const Text('定期的な収支'),
              subtitle: const Text('毎月繰り返される収支として記録します'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // 保存ボタン
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.transaction == null ? '登録する' : '更新する',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. 状態のテスト

Riverpodの状態管理をテストするためのパターンを示します。

### 8.1 StateNotifierのテスト

```dart
void main() {
  late MockTransactionRepository mockRepository;
  late TransactionNotifier notifier;

  setUp(() {
    mockRepository = MockTransactionRepository();
    notifier = TransactionNotifier(transactionRepository: mockRepository);
  });

  group('TransactionNotifier Tests', () {
    final testTransactions = [
      Transaction(
        id: '1',
        userId: 'user1',
        amount: 1000,
        type: TransactionType.expense,
        categoryId: 'category1',
        date: DateTime(2025, 5, 1),
        createdAt: DateTime(2025, 5, 1),
        updatedAt: DateTime(2025, 5, 1),
      ),
      Transaction(
        id: '2',
        userId: 'user1',
        amount: 5000,
        type: TransactionType.income,
        categoryId: 'category2',
        date: DateTime(2025, 5, 2),
        createdAt: DateTime(2025, 5, 2),
        updatedAt: DateTime(2025, 5, 2),
      ),
    ];

    test('初期状態のテスト', () {
      expect(notifier.state.transactions, isEmpty);
      expect(notifier.state.status, equals(TransactionStatus.initial));
      expect(notifier.state.errorMessage, isNull);
    });

    test('トランザクションのロードテスト', () async {
      // モックデータの設定
      when(
        mockRepository.watchTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) => Stream.value(testTransactions));

      // テスト対象のメソッド実行
      await notifier.loadTransactions();
      
      // 期待される状態の検証
      expect(notifier.state.transactions, equals(testTransactions));
      expect(notifier.state.status, equals(TransactionStatus.loaded));
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.totalIncome, equals(5000));
      expect(notifier.state.totalExpense, equals(1000));
      expect(notifier.state.balance, equals(4000));
    });

    test('エラーハンドリングのテスト', () async {
      // エラー発生時のモック設定
      when(
        mockRepository.watchTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) => Stream.error('テストエラー'));

      // テスト対象のメソッド実行
      await notifier.loadTransactions();
      
      // 期待される状態の検証
      expect(notifier.state.status, equals(TransactionStatus.error));
      expect(notifier.state.errorMessage, contains('テストエラー'));
    });

    test('トランザクション追加のテスト', () async {
      // モックデータの設定
      final newTransaction = Transaction(
        id: '3',
        userId: 'user1',
        amount: 3000,
        type: TransactionType.expense,
        categoryId: 'category1',
        date: DateTime(2025, 5, 3),
        createdAt: DateTime(2025, 5, 3),
        updatedAt: DateTime(2025, 5, 3),
      );
      
      when(mockRepository.addTransaction(any))
        .thenAnswer((_) => Future.value(newTransaction));
      
      // リスナーはモックできないので、初期状態設定のみ
      when(
        mockRepository.watchTransactions(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          type: any(named: 'type'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) => Stream.value(testTransactions));
      
      // 初期データのロード
      await notifier.loadTransactions();
      
      // 追加処理の実行
      await notifier.addTransaction(newTransaction);
      
      // 期待される状態の検証
      verify(mockRepository.addTransaction(any)).called(1);
    });
  });
}
```

### 8.2 Providerのテスト

```dart
void main() {
  test('budgetUsageRateProviderのテスト', () async {
    // テスト用のProviderScopeを作成
    final container = ProviderContainer(
      overrides: [
        // 依存するプロバイダーをオーバーライド
        budgetProvider.overrideWith((ref) => 
          BudgetNotifier(
            budgetRepository: MockBudgetRepository(),
            transactionRepository: MockTransactionRepository(),
          )..loadBudget(2025, 5) // 初期状態を設定
        ),
      ],
    );
    
    // クリーンアップ
    addTearDown(container.dispose);
    
    // テスト対象のプロバイダー値を取得
    final usageRate = container.read(budgetUsageRateProvider);
    
    // 初期値のアサーション
    expect(usageRate, equals(0.0));
    
    // 状態の更新
    final budgetNotifier = container.read(budgetProvider.notifier);
    final budget = Budget(
      id: 'budget1',
      userId: 'user1',
      amount: 30000,
      year: 2025,
      month: 5,
      createdAt: DateTime(2025, 5, 1),
      updatedAt: DateTime(2025, 5, 1),
    );
    
    // 状態の更新のシミュレーション（内部的にはloadBudgetの結果として発生）
    (budgetNotifier as TestBudgetNotifier).updateStateForTesting(
      budgetNotifier.state.copyWith(
        budget: budget,
        budgetUsageRate: 0.75,
        status: BudgetStatus.loaded,
      ),
    );
    
    // 更新後の値のアサーション
    expect(container.read(budgetUsageRateProvider), equals(0.75));
    expect(container.read(isOverBudgetProvider), equals(false));
    expect(container.read(currentBudgetAmountProvider), equals(30000));
    expect(container.read(remainingBudgetProvider), equals(7500)); // 30000 * (1 - 0.75)
  });
}

// テスト用の拡張クラス
class TestBudgetNotifier extends BudgetNotifier {
  TestBudgetNotifier({
    required super.budgetRepository,
    required super.transactionRepository,
  });
  
  void updateStateForTesting(BudgetState newState) {
    state = newState;
  }
}
```

---

## 9. パフォーマンス最適化

Riverpodを使った状態管理のパフォーマンス最適化パターンを示します。

### 9.1 select メソッドによる再描画制御

```dart
class TransactionAmountDisplay extends ConsumerWidget {
  const TransactionAmountDisplay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // selectを使って必要な部分だけ監視
    final totalIncome = ref.watch(transactionProvider.select((state) => state.totalIncome));
    final totalExpense = ref.watch(transactionProvider.select((state) => state.totalExpense));
    final balance = ref.watch(transactionProvider.select((state) => state.balance));
    
    // 通貨設定の取得
    final currencyCode = ref.watch(currencyCodeProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildAmountRow('収入', totalIncome, Colors.green, currencyCode),
            const Divider(),
            _buildAmountRow('支出', totalExpense, Colors.red, currencyCode),
            const Divider(),
            _buildAmountRow('残高', balance, balance >= 0 ? Colors.blue : Colors.orange, currencyCode),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAmountRow(String label, double amount, Color color, String currencyCode) {
    final formatter = NumberFormat.currency(
      locale: 'ja_JP',
      symbol: currencyCode == 'JPY' ? '¥' : '\$',
      decimalDigits: currencyCode == 'JPY' ? 0 : 2,
    );
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          formatter.format(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
```

### 9.2 メモ化による計算の最適化

```dart
// カテゴリごとの合計金額を計算する重い処理の最適化
final categoryTotalsProvider = Provider.family<Map<String, double>, int>((ref, month) {
  // トランザクションデータの取得
  final transactions = ref.watch(transactionProvider).transactions;
  
  // キャッシュ用キー
  final cacheKey = transactions.map((t) => '${t.id}-${t.updatedAt.millisecondsSinceEpoch}').join(':');
  
  // メモ化された計算
  return ref.cache(
    () {
      final Map<String, double> result = {};
      
      for (final transaction in transactions) {
        if (transaction.date.month == month) {
          final categoryId = transaction.categoryId;
          final amount = transaction.amount;
          
          result.update(
            categoryId,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
        }
      }
      
      return result;
    },
    keys: [cacheKey, month],
  );
});
```

### 9.3 リストのレンダリング最適化

```dart
class OptimizedTransactionList extends ConsumerWidget {
  const OptimizedTransactionList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // トランザクションリストだけを監視
    final transactions = ref.watch(
      transactionProvider.select((state) => state.transactions),
    );
    
    return ListView.builder(
      itemCount: transactions.length,
      // 各アイテムを個別のウィジェットに分離し、メモ化
      itemBuilder: (context, index) => TransactionListItem(
        key: ValueKey(transactions[index].id),
        transaction: transactions[index],
      ),
    );
  }
}

// 個別リストアイテムをメモ化
class TransactionListItem extends ConsumerWidget {
  final Transaction transaction;
  
  const TransactionListItem({
    Key? key,
    required this.transaction,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // カテゴリ情報だけを必要なときに取得
    final category = ref.watch(categoryByIdProvider(transaction.categoryId));
    
    return ListTile(
      title: Text(category?.name ?? '不明なカテゴリ'),
      subtitle: Text(DateFormat('yyyy/MM/dd').format(transaction.date)),
      trailing: Text(
        '${transaction.type == TransactionType.income ? '+' : '-'}¥${transaction.amount.toStringAsFixed(0)}',
        style: TextStyle(
          color: transaction.type == TransactionType.income
            ? Colors.green
            : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
```

---

## 10. 変更履歴

| 日付       | 変更内容               | 担当者 |
| ---------- | ---------------------- | ------ |
| 2025-05-16 | 初版リリース           | 廣澤  |
