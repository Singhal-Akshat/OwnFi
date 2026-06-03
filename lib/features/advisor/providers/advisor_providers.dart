import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/quant_forecast_service.dart';
import '../services/ai_advisor_service.dart';
import '../../../core/providers.dart';

final quantForecastServiceProvider = Provider<QuantForecastService>((ref) {
  return QuantForecastService();
});

final aiAdvisorServiceProvider = Provider<AiAdvisorService>((ref) {
  return AiAdvisorService();
});

final quantForecastResultProvider = Provider<AsyncValue<QuantForecastResult>>((ref) {
  final txsState = ref.watch(transactionsProvider);
  final cardsState = ref.watch(creditCardsProvider);
  final loansState = ref.watch(loansProvider);
  final holdingsState = ref.watch(holdingsProvider);
  final bankAccountsState = ref.watch(bankAccountsProvider);

  if (txsState.isLoading || cardsState.isLoading || loansState.isLoading || holdingsState.isLoading || bankAccountsState.isLoading) {
    return const AsyncValue.loading();
  }

  if (txsState.hasError) return AsyncValue.error(txsState.error!, txsState.stackTrace!);
  if (cardsState.hasError) return AsyncValue.error(cardsState.error!, cardsState.stackTrace!);
  if (loansState.hasError) return AsyncValue.error(loansState.error!, loansState.stackTrace!);
  if (holdingsState.hasError) return AsyncValue.error(holdingsState.error!, holdingsState.stackTrace!);
  if (bankAccountsState.hasError) return AsyncValue.error(bankAccountsState.error!, bankAccountsState.stackTrace!);

  final txs = txsState.value ?? [];
  final cards = cardsState.value ?? [];
  final loans = loansState.value ?? [];
  final holdings = holdingsState.value ?? [];
  final bankAccounts = bankAccountsState.value ?? [];

  final service = ref.watch(quantForecastServiceProvider);
  try {
    final result = service.calculateForecast(
      transactions: txs,
      cards: cards,
      loans: loans,
      holdings: holdings,
      bankAccounts: bankAccounts,
    );
    return AsyncValue.data(result);
  } catch (e, st) {
    return AsyncValue.error(e, st);
  }
});
