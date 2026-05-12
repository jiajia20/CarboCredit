import Foundation

struct Nutrition: Codable, Equatable {
    var carbs: Double
    var protein: Double
    var calories: Double
    var ldlImpact: Double

    static let zero = Nutrition(carbs: 0, protein: 0, calories: 0, ldlImpact: 0)

    static func + (lhs: Nutrition, rhs: Nutrition) -> Nutrition {
        Nutrition(
            carbs: lhs.carbs + rhs.carbs,
            protein: lhs.protein + rhs.protein,
            calories: lhs.calories + rhs.calories,
            ldlImpact: lhs.ldlImpact + rhs.ldlImpact
        )
    }
}

struct NutritionGoals: Codable, Equatable {
    var carbLimit: Double = 160
    var proteinTarget: Double = 120
    var calorieLimit: Double = 2000
    var ldlImpactLimit: Double = 12
    var weeklyCarbLimit: Double = 900
    var weeklyCalorieLimit: Double = 12500
}

enum LogSource: String, Codable, CaseIterable, Identifiable {
    case snapMeal = "Eating Out"
    case mealPrep = "Meal Prep"
    case manual = "Manual"
    case snack = "Snack"
    case recipe = "Recipe"

    var id: String { rawValue }
}

struct FoodLogEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var date: Date
    var source: LogSource
    var nutrition: Nutrition
    var notes: String = ""
    var hasPhoto: Bool = false
}

struct RecipeIngredient: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var amount: String
    var nutrition: Nutrition
}

struct Recipe: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var servings: Double
    var ingredients: [RecipeIngredient]
    var isMealPrepShortcut: Bool

    var totalNutrition: Nutrition {
        ingredients.reduce(.zero) { $0 + $1.nutrition }
    }

    var perServingNutrition: Nutrition {
        guard servings > 0 else { return totalNutrition }
        return Nutrition(
            carbs: totalNutrition.carbs / servings,
            protein: totalNutrition.protein / servings,
            calories: totalNutrition.calories / servings,
            ldlImpact: totalNutrition.ldlImpact / servings
        )
    }
}

struct BodyMeasurement: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date
    var weight: Double
    var waist: Double
}

struct CarboCreditData: Codable {
    var goals: NutritionGoals
    var logEntries: [FoodLogEntry]
    var recipes: [Recipe]
    var bodyMeasurements: [BodyMeasurement]
}
