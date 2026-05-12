# CarboCredit

CarboCredit is a SwiftUI iOS app for tracking daily "carb credits" alongside protein, calories, LDL impact, meal prep recipes, and simple body check-ins. The product goal is to make food decisions feel budgeted and actionable without turning every meal into a spreadsheet.

## Short PRD

### Problem

People who are managing carbs, protein, calories, and cholesterol-related habits often need one place to answer: "Can I eat this and still stay on track today?" Most trackers are either too calorie-centric or too slow for repeated daily use.

### Target User

- A health-conscious user tracking carbs and protein every day.
- Someone who eats a mix of meal-prepped food, snacks, recipes, and restaurant meals.
- Someone who wants simple progress signals from weight and waist check-ins.

### MVP Goals

- Show today's nutrition totals against daily limits and targets.
- Support fast logging from common flows: snap meal, manual add, snack, recipe, and meal prep shortcut.
- Store reusable recipes with per-serving nutrition.
- Track body measurements over time.
- Keep settings local and adjustable without account setup.

### Current Features

- Today dashboard with protein target, carb credit, calorie, and LDL impact budgets.
- Food log with filters and swipe-to-delete.
- Manual food entry with source, nutrition, and notes.
- Snap meal placeholder flow using `PhotosPicker`.
- Recipe list, recipe builder seed flow, and recipe-to-log action.
- Progress tab for body measurements.
- Settings for daily and weekly goals.
- Local persistence through `UserDefaults`.

### Non-Goals For Now

- Cloud sync, account auth, and sharing.
- Medical recommendations or clinical risk scoring.
- Automatic nutrition lookup from a food database.
- Real image-based nutrition estimation. The current snap meal flow is a user-reviewed estimate placeholder.

## Basic Architecture Spec

CarboCredit is a small single-target SwiftUI app.

```text
CarboCredit/
  CarboCreditApp.swift          App entry point and store injection
  Models/
    NutritionModels.swift       Codable domain models and data container
  Store/
    AppStore.swift              ObservableObject state, mutations, persistence, seed data
  Views/
    ContentView.swift           Tabs and all current feature views
    Theme.swift                 Shared colors, card style, number formatting
```

### State Management

- `CarboCreditStore` is the app-level `ObservableObject`.
- It is created once in `CarboCreditApp` with `@StateObject`.
- Views read and mutate it through `@EnvironmentObject`.
- Mutating methods call `save()` after changing persistent state.

### Persistence

- Storage is local-only.
- The full app state is encoded as `CarboCreditData`.
- `JSONEncoder` and `JSONDecoder` use ISO-8601 date encoding.
- Encoded data is saved under the `UserDefaults` key:

```text
carbo-credit-data-v1
```

If no saved data exists, `CarboCreditStore.seedData()` provides sample recipes, logs, goals, and measurements.

## Data Format Spec

The persisted payload is conceptually:

```json
{
  "goals": {
    "carbLimit": 160,
    "proteinTarget": 120,
    "calorieLimit": 2000,
    "ldlImpactLimit": 12,
    "weeklyCarbLimit": 900,
    "weeklyCalorieLimit": 12500
  },
  "logEntries": [
    {
      "id": "UUID",
      "name": "Takeout Salmon Bowl",
      "date": "2026-05-12T19:00:00Z",
      "source": "Eating Out",
      "nutrition": {
        "carbs": 68,
        "protein": 32,
        "calories": 720,
        "ldlImpact": 6
      },
      "notes": "",
      "hasPhoto": true
    }
  ],
  "recipes": [
    {
      "id": "UUID",
      "name": "Salmon Chazuke",
      "servings": 2,
      "ingredients": [
        {
          "id": "UUID",
          "name": "Rice",
          "amount": "0.75 cup",
          "nutrition": {
            "carbs": 45,
            "protein": 4,
            "calories": 210,
            "ldlImpact": 0
          }
        }
      ],
      "isMealPrepShortcut": true
    }
  ],
  "bodyMeasurements": [
    {
      "id": "UUID",
      "date": "2026-05-12T19:00:00Z",
      "weight": 146.8,
      "waist": 30.5
    }
  ]
}
```

### Model Notes

- `Nutrition` is additive and used for daily totals, recipe totals, and per-serving calculations.
- `LogSource` values are user-facing raw strings: `Eating Out`, `Meal Prep`, `Manual`, `Snack`, and `Recipe`.
- `Recipe.perServingNutrition` divides total ingredient nutrition by `servings`.
- `BodyMeasurement` currently tracks weight in pounds and waist in inches.
- `ldlImpact` is an app-specific numeric heuristic, not a clinical measurement.

## Development

Open `CarboCredit.xcodeproj` in Xcode and run the `CarboCredit` scheme.

Command-line compile check:

```zsh
xcodebuild -scheme CarboCredit -project CarboCredit.xcodeproj -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

## Roadmap

- Add editable recipe ingredients.
- Add food log editing.
- Add weekly trend summaries.
- Replace snap meal placeholder estimates with a reviewable estimation pipeline.
- Add import/export for the local data payload.
