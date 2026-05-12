import Foundation

final class CarboCreditStore: ObservableObject {
    @Published var goals: NutritionGoals
    @Published var logEntries: [FoodLogEntry]
    @Published var recipes: [Recipe]
    @Published var bodyMeasurements: [BodyMeasurement]

    private let storageKey = "carbo-credit-data-v1"
    private var isBootstrapping = true

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder.carboCredit.decode(CarboCreditData.self, from: data) {
            goals = decoded.goals
            logEntries = decoded.logEntries
            recipes = decoded.recipes
            bodyMeasurements = decoded.bodyMeasurements.map(Self.metricizedMeasurement)
        } else {
            let seed = CarboCreditStore.seedData()
            goals = seed.goals
            logEntries = seed.logEntries
            recipes = seed.recipes
            bodyMeasurements = seed.bodyMeasurements
        }

        isBootstrapping = false
    }

    var todayNutrition: Nutrition {
        logEntries
            .filter { Calendar.current.isDateInToday($0.date) }
            .map(\.nutrition)
            .reduce(.zero, +)
    }

    var latestMeasurement: BodyMeasurement? {
        bodyMeasurements.sorted { $0.date > $1.date }.first
    }

    func addLogEntry(_ entry: FoodLogEntry) {
        logEntries.insert(entry, at: 0)
        save()
    }

    func deleteLogEntries(at offsets: IndexSet, from entries: [FoodLogEntry]) {
        let idsToDelete = Set(offsets.map { entries[$0].id })
        logEntries.removeAll { idsToDelete.contains($0.id) }
        save()
    }

    func deleteLogEntry(_ entry: FoodLogEntry) {
        logEntries.removeAll { $0.id == entry.id }
        save()
    }

    func saveRecipe(_ recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipes[index] = recipe
        } else {
            recipes.insert(recipe, at: 0)
        }
        save()
    }

    func logRecipe(_ recipe: Recipe) {
        addLogEntry(
            FoodLogEntry(
                name: recipe.name,
                date: Date(),
                source: recipe.isMealPrepShortcut ? .mealPrep : .recipe,
                nutrition: recipe.perServingNutrition
            )
        )
    }

    func addMeasurement(weight: Double, waist: Double) {
        bodyMeasurements.insert(BodyMeasurement(date: Date(), weight: weight, waist: waist), at: 0)
        save()
    }

    func save() {
        guard !isBootstrapping else { return }
        let payload = CarboCreditData(
            goals: goals,
            logEntries: logEntries,
            recipes: recipes,
            bodyMeasurements: bodyMeasurements
        )

        if let data = try? JSONEncoder.carboCredit.encode(payload) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private static func seedData() -> CarboCreditData {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today

        let recipes = [
            Recipe(
                name: "Salmon Chazuke",
                servings: 2,
                ingredients: [
                    RecipeIngredient(name: "Salmon", amount: "5 oz", nutrition: Nutrition(carbs: 0, protein: 34, calories: 280, ldlImpact: 2)),
                    RecipeIngredient(name: "Rice", amount: "0.75 cup", nutrition: Nutrition(carbs: 45, protein: 4, calories: 210, ldlImpact: 0)),
                    RecipeIngredient(name: "Tea broth", amount: "1 cup", nutrition: Nutrition(carbs: 1, protein: 0, calories: 5, ldlImpact: 0)),
                    RecipeIngredient(name: "Nori + scallion", amount: "to taste", nutrition: Nutrition(carbs: 2, protein: 1, calories: 15, ldlImpact: 0))
                ],
                isMealPrepShortcut: true
            ),
            Recipe(
                name: "Yogurt Bowl",
                servings: 1,
                ingredients: [
                    RecipeIngredient(name: "Greek yogurt", amount: "1 cup", nutrition: Nutrition(carbs: 9, protein: 22, calories: 150, ldlImpact: 1)),
                    RecipeIngredient(name: "Berries", amount: "0.5 cup", nutrition: Nutrition(carbs: 10, protein: 1, calories: 45, ldlImpact: 0)),
                    RecipeIngredient(name: "Granola", amount: "0.25 cup", nutrition: Nutrition(carbs: 18, protein: 4, calories: 140, ldlImpact: 1))
                ],
                isMealPrepShortcut: true
            )
        ]

        let logs = [
            FoodLogEntry(name: "Yogurt Bowl", date: today, source: .mealPrep, nutrition: Nutrition(carbs: 37, protein: 27, calories: 335, ldlImpact: 2)),
            FoodLogEntry(name: "Takeout Salmon Bowl", date: today, source: .snapMeal, nutrition: Nutrition(carbs: 68, protein: 32, calories: 720, ldlImpact: 6), hasPhoto: true),
            FoodLogEntry(name: "Cookie", date: today, source: .snack, nutrition: Nutrition(carbs: 24, protein: 2, calories: 180, ldlImpact: 1)),
            FoodLogEntry(name: "Shrimp with Veggies", date: yesterday, source: .mealPrep, nutrition: Nutrition(carbs: 18, protein: 38, calories: 410, ldlImpact: 2))
        ]

        let measurements = [
            BodyMeasurement(date: today, weight: 66.6, waist: 77.5),
            BodyMeasurement(date: Calendar.current.date(byAdding: .day, value: -7, to: today) ?? today, weight: 67.0, waist: 78.2)
        ]

        return CarboCreditData(
            goals: NutritionGoals(),
            logEntries: logs,
            recipes: recipes,
            bodyMeasurements: measurements
        )
    }

    private static func metricizedMeasurement(_ measurement: BodyMeasurement) -> BodyMeasurement {
        BodyMeasurement(
            id: measurement.id,
            date: measurement.date,
            weight: measurement.weight > 120 ? measurement.weight / 2.20462 : measurement.weight,
            waist: measurement.waist < 70 ? measurement.waist * 2.54 : measurement.waist
        )
    }
}

private extension JSONEncoder {
    static var carboCredit: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var carboCredit: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
