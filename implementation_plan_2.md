# Smart Routing LLM Transaction Parser (Gemma + Gemini)

We will upgrade the current text-parsing logic in `SmsParserService` to leverage **both** the local Gemma model and the cloud Gemini API, routing intelligently based on the scenario.

## User Review Required

Please review the new **A/B Testing Mode** designed specifically for your request to see side-by-side comparisons of single transactions.

## Smart Routing & Testing Logic

1. **The Fast Filter (Regex):**
   - Quick Regex check for financial keywords (`debited`, `credited`, etc.) to filter out OTPs.

2. **Bulk Loading (Historical Sync):**
   - **Condition:** `isBulk = true`.
   - **Key Check:** Verify `gemini_api_key`. Show UI warning if missing. Throw halt error if invalid.
   - **Action:** Route all to **Gemini API** for maximum speed. (No Gemma comparison here to save time).

3. **Daily / Single Transactions (A/B Testing Mode):**
   - **Condition:** `isBulk = false`.
   - **Action:** We will run **BOTH** Gemma and Gemini simultaneously (in parallel to save time).
   - **Comparison Logging:** We don't want to duplicate your transactions and mess up your net worth. Instead, we will save the **Gemini** result as the actual transaction (since it's the gold standard), but we will append Gemma's predicted JSON to a new `aiComparisonNotes` field on that transaction.
   - **Viewing:** When you tap on a transaction in your app's UI, you will be able to see the notes: *"Gemini predicted Category: Dining, Amount: 500. Gemma predicted Category: Food, Amount: 50"*. This lets you evaluate Gemma's accuracy directly without breaking your budget.

## Proposed Code Changes

### 1. Update `Transaction` Model (`lib/features/expenses/models/transaction_model.dart`)
- **[MODIFY]** Add a `String? parserSource;` field.
- **[MODIFY]** Add a `String? aiComparisonNotes;` field to hold the A/B testing comparison.

### 2. Update `SmsParserService` (`lib/features/parser/services/sms_parser_service.dart`)
- **[MODIFY]** Change `parse` to `Future<ParsedSmsTransaction?> parseAsync(String smsBody, {bool isBulk = false})`.
- **[NEW]** Add API key validation for bulk syncs.
- **[NEW]** Add `_parseWithGemma` and `_parseWithGemini` functions.
- **[NEW]** For `isBulk == false`, use `Future.wait([_parseWithGemma(), _parseWithGemini()])` to get both results. Then construct the `aiComparisonNotes` string and attach it to the final `ParsedSmsTransaction` (which is returned).

### 3. Update Sync Services (`sms_sync_service.dart` & `email_sync_service.dart`)
- **[MODIFY]** Add pre-sync Gemini API key validation logic.
- **[MODIFY]** Update the loop to call `await _parser.parseAsync(msg.body!, isBulk: true)`.
