import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject private var store: CarboCreditStore

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "leaf") }

            LogView()
                .tabItem { Label("Log", systemImage: "list.bullet.rectangle") }

            RecipesView()
                .tabItem { Label("Recipes", systemImage: "fork.knife") }

            TrendsView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "slider.horizontal.3") }
        }
        .tint(CarboTheme.accent)
    }
}

struct TodayView: View {
    @EnvironmentObject private var store: CarboCreditStore
    @State private var showingSnapMeal = false
    @State private var showingManualEntry = false
    @State private var showingMeasurement = false
    @State private var showingRecipeBuilder = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    buildUpSection
                    stayUnderSection
                    bodyCheckInSection
                    quickActions
                }
                .padding()
            }
            .background(CarboTheme.background.ignoresSafeArea())
            .navigationTitle("CarboCredit")
            .sheet(isPresented: $showingSnapMeal) { SnapMealView() }
            .sheet(isPresented: $showingManualEntry) { ManualEntryView() }
            .sheet(isPresented: $showingMeasurement) { MeasurementEntryView() }
            .sheet(isPresented: $showingRecipeBuilder) { RecipeBuilderView() }
        }
    }

    private var buildUpSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Build Up")
                .font(.headline)
                .foregroundStyle(CarboTheme.text)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Protein", systemImage: "bolt.heart")
                    Spacer()
                    Text("\(store.todayNutrition.protein.clean)g / \(store.goals.proteinTarget.clean)g")
                        .foregroundStyle(CarboTheme.mutedText)
                }

                ProgressView(value: min(store.todayNutrition.protein / store.goals.proteinTarget, 1))
                    .tint(CarboTheme.protein)

                Text("\(max(store.goals.proteinTarget - store.todayNutrition.protein, 0).clean)g to target")
                    .font(.caption)
                    .foregroundStyle(CarboTheme.mutedText)
            }
            .cardStyle()
        }
    }

    private var stayUnderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Stay Under")
                .font(.headline)
                .foregroundStyle(CarboTheme.text)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                BudgetCard(title: "Carb Credits", value: store.todayNutrition.carbs, limit: store.goals.carbLimit, unit: "g", color: CarboTheme.caution)
                BudgetCard(title: "Calories", value: store.todayNutrition.calories, limit: store.goals.calorieLimit, unit: "", color: CarboTheme.caution)
                BudgetCard(title: "LDL Impact", value: store.todayNutrition.ldlImpact, limit: store.goals.ldlImpactLimit, unit: "", color: CarboTheme.ldl)
            }
        }
    }

    private var bodyCheckInSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Body Check-In")
                    .font(.headline)
                Spacer()
                Button("Log") { showingMeasurement = true }
                    .buttonStyle(.borderedProminent)
                    .tint(CarboTheme.accent)
            }

            HStack(spacing: 12) {
                MeasurementTile(title: "Weight", value: store.latestMeasurement?.weight.clean ?? "-", unit: "lb")
                MeasurementTile(title: "Waist", value: store.latestMeasurement?.waist.clean ?? "-", unit: "in")
            }
        }
        .foregroundStyle(CarboTheme.text)
        .cardStyle()
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Add")
                .font(.headline)
                .foregroundStyle(CarboTheme.text)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                QuickActionButton(title: "Snap Meal", icon: "camera") { showingSnapMeal = true }
                QuickActionButton(title: "Manual", icon: "square.and.pencil") { showingManualEntry = true }
                QuickActionButton(title: "Meal Prep", icon: "takeoutbag.and.cup.and.straw") {
                    if let recipe = store.recipes.first(where: \.isMealPrepShortcut) {
                        store.logRecipe(recipe)
                    }
                }
                QuickActionButton(title: "Snack", icon: "birthday.cake") {
                    store.addLogEntry(FoodLogEntry(name: "Snack", date: Date(), source: .snack, nutrition: Nutrition(carbs: 18, protein: 2, calories: 140, ldlImpact: 1)))
                }
                QuickActionButton(title: "Recipe", icon: "plus.rectangle.on.rectangle") {
                    showingRecipeBuilder = true
                }
            }
        }
    }
}

struct BudgetCard: View {
    let title: String
    let value: Double
    let limit: Double
    let unit: String
    let color: Color

    var remaining: Double { max(limit - value, 0) }
    var progress: Double { min(value / limit, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text("\(value.clean)\(unit) / \(limit.clean)\(unit)")
                .font(.title3.weight(.bold))
            ProgressView(value: progress)
                .tint(progress > 0.85 ? color : CarboTheme.accent)
            Text("\(remaining.clean)\(unit) left")
                .font(.caption)
                .foregroundStyle(CarboTheme.mutedText)
        }
        .foregroundStyle(CarboTheme.text)
        .cardStyle()
    }
}

struct MeasurementTile: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(CarboTheme.mutedText)
            Text("\(value) \(unit)")
                .font(.title3.weight(.semibold))
            Label("weekly trend", systemImage: "arrow.down.right")
                .font(.caption2)
                .foregroundStyle(CarboTheme.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CarboTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(CarboTheme.accent)
    }
}

struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CarboCreditStore
    @State private var name = ""
    @State private var source = LogSource.manual
    @State private var carbs = 0.0
    @State private var protein = 0.0
    @State private var calories = 0.0
    @State private var ldlImpact = 0.0
    @State private var notes = ""

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Name", text: $name)
                    Picker("Type", selection: $source) {
                        ForEach(LogSource.allCases) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                }

                Section("Nutrition") {
                    Stepper("Carbs \(carbs.clean)g", value: $carbs, in: 0...300, step: 1)
                    Stepper("Protein \(protein.clean)g", value: $protein, in: 0...200, step: 1)
                    Stepper("Calories \(calories.clean)", value: $calories, in: 0...3000, step: 10)
                    Stepper("LDL Impact \(ldlImpact.clean)", value: $ldlImpact, in: 0...30, step: 1)
                }

                Section("Notes") {
                    TextField("Optional", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Button {
                    store.addLogEntry(
                        FoodLogEntry(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            date: Date(),
                            source: source,
                            nutrition: Nutrition(carbs: carbs, protein: protein, calories: calories, ldlImpact: ldlImpact),
                            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    )
                    dismiss()
                } label: {
                    Text("Save Food")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CarboTheme.accent)
                .disabled(!canSave)
            }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Manual Add")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SnapMealView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CarboCreditStore
    @State private var selectedItem: PhotosPickerItem?
    @State private var mealName = "Takeout Salmon Bowl"
    @State private var carbs = 68.0
    @State private var protein = 32.0
    @State private var calories = 720.0
    @State private var ldlImpact = 6.0
    @State private var portion = "Normal"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Label("Choose Meal Photo", systemImage: "photo")
                            .frame(maxWidth: .infinity)
                    }
                    .tint(CarboTheme.accent)

                    TextField("Meal name", text: $mealName)
                }

                Section("Review Estimate") {
                    Stepper("Carbs \(carbs.clean)g", value: $carbs, in: 0...300, step: 1)
                    Stepper("Protein \(protein.clean)g", value: $protein, in: 0...200, step: 1)
                    Stepper("Calories \(calories.clean)", value: $calories, in: 0...3000, step: 10)
                    Stepper("LDL Impact \(ldlImpact.clean)", value: $ldlImpact, in: 0...30, step: 1)
                }

                Section("Portion") {
                    Picker("Portion", selection: $portion) {
                        Text("Small").tag("Small")
                        Text("Normal").tag("Normal")
                        Text("Large").tag("Large")
                    }
                    .pickerStyle(.segmented)
                }

                Button {
                    store.addLogEntry(
                        FoodLogEntry(
                            name: mealName,
                            date: Date(),
                            source: .snapMeal,
                            nutrition: Nutrition(carbs: carbs, protein: protein, calories: calories, ldlImpact: ldlImpact),
                            hasPhoto: selectedItem != nil
                        )
                    )
                    dismiss()
                } label: {
                    Text("Save Log")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CarboTheme.accent)
            }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Snap Meal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct LogView: View {
    @EnvironmentObject private var store: CarboCreditStore
    @State private var filter = "All"
    private let filters = ["All", "Manual", "Snack", "Meal Prep", "Eating Out", "Recipe"]

    var filteredEntries: [FoodLogEntry] {
        store.logEntries.filter { entry in
            filter == "All" || entry.source.rawValue == filter || (filter == "Meal" && entry.source == .recipe)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                TodaySummaryStrip(nutrition: store.todayNutrition, goals: store.goals)
                    .listRowBackground(CarboTheme.background)

                Picker("Filter", selection: $filter) {
                    ForEach(filters, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(CarboTheme.background)

                ForEach(filteredEntries) { entry in
                    LogRow(entry: entry)
                        .listRowBackground(CarboTheme.surface)
                }
                .onDelete { offsets in
                    store.deleteLogEntries(at: offsets, from: filteredEntries)
                }
            }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Log")
        }
    }
}

struct TodaySummaryStrip: View {
    let nutrition: Nutrition
    let goals: NutritionGoals

    var body: some View {
        HStack {
            MiniMetric(label: "C", value: "\(nutrition.carbs.clean)/\(goals.carbLimit.clean)")
            MiniMetric(label: "P", value: "\(nutrition.protein.clean)/\(goals.proteinTarget.clean)")
            MiniMetric(label: "Cal", value: "\(nutrition.calories.clean)/\(goals.calorieLimit.clean)")
            MiniMetric(label: "LDL", value: "\(nutrition.ldlImpact.clean)/\(goals.ldlImpactLimit.clean)")
        }
        .cardStyle()
    }
}

struct LogRow: View {
    let entry: FoodLogEntry

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(entry.hasPhoto ? CarboTheme.surfaceStrong : CarboTheme.background)
                Image(systemName: entry.hasPhoto ? "photo" : "fork.knife")
                    .foregroundStyle(CarboTheme.accent)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(entry.name)
                        .font(.headline)
                    Spacer()
                    Text(entry.source.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CarboTheme.background)
                        .clipShape(Capsule())
                }

                HStack {
                    MiniMetric(label: "C", value: "\(entry.nutrition.carbs.clean)g")
                    MiniMetric(label: "P", value: "\(entry.nutrition.protein.clean)g")
                    MiniMetric(label: "Cal", value: entry.nutrition.calories.clean)
                    MiniMetric(label: "LDL", value: entry.nutrition.ldlImpact.clean)
                }
            }
        }
        .foregroundStyle(CarboTheme.text)
        .padding(.vertical, 6)
    }
}

struct MiniMetric: View {
    let label: String
    let value: String

    var body: some View {
        Text("\(label) \(value)")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(CarboTheme.mutedText)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(CarboTheme.background)
            .clipShape(Capsule())
    }
}

struct RecipesView: View {
    @EnvironmentObject private var store: CarboCreditStore
    @State private var showingBuilder = false

    var body: some View {
        NavigationStack {
            List {
                Section("Meal Prep Shortcuts") {
                    ForEach(store.recipes.filter(\.isMealPrepShortcut)) { recipe in
                        RecipeRow(recipe: recipe) {
                            store.logRecipe(recipe)
                        }
                    }
                }

                Section("All Recipes") {
                    ForEach(store.recipes) { recipe in
                        RecipeRow(recipe: recipe) {
                            store.logRecipe(recipe)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Recipes")
            .toolbar {
                Button {
                    showingBuilder = true
                } label: {
                    Label("New Recipe", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingBuilder) {
                RecipeBuilderView()
            }
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    let log: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.headline)
                Text("Per serving: C \(recipe.perServingNutrition.carbs.clean)g  P \(recipe.perServingNutrition.protein.clean)g  Cal \(recipe.perServingNutrition.calories.clean)  LDL \(recipe.perServingNutrition.ldlImpact.clean)")
                    .font(.caption)
                    .foregroundStyle(CarboTheme.mutedText)
            }
            Spacer()
            Button("Log", action: log)
                .buttonStyle(.borderedProminent)
                .tint(CarboTheme.accent)
        }
        .foregroundStyle(CarboTheme.text)
        .listRowBackground(CarboTheme.surface)
    }
}

struct RecipeBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CarboCreditStore
    @State private var recipe = Recipe(
        name: "Salmon Chazuke",
        servings: 2,
        ingredients: [
            RecipeIngredient(name: "Salmon", amount: "5 oz", nutrition: Nutrition(carbs: 0, protein: 34, calories: 280, ldlImpact: 2)),
            RecipeIngredient(name: "Rice", amount: "0.75 cup", nutrition: Nutrition(carbs: 45, protein: 4, calories: 210, ldlImpact: 0))
        ],
        isMealPrepShortcut: true
    )

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipe") {
                    TextField("Name", text: $recipe.name)
                    Stepper("Servings \(recipe.servings.clean)", value: $recipe.servings, in: 1...12, step: 1)
                    Toggle("Add to Meal Prep Shortcuts", isOn: $recipe.isMealPrepShortcut)
                        .tint(CarboTheme.accent)
                }

                Section("Per Serving") {
                    Text("Carbs \(recipe.perServingNutrition.carbs.clean)g")
                    Text("Protein \(recipe.perServingNutrition.protein.clean)g")
                    Text("Calories \(recipe.perServingNutrition.calories.clean)")
                    Text("LDL Impact \(recipe.perServingNutrition.ldlImpact.clean)")
                }

                Section("Ingredients") {
                    ForEach(recipe.ingredients) { ingredient in
                        VStack(alignment: .leading) {
                            Text(ingredient.name)
                            Text(ingredient.amount)
                                .font(.caption)
                                .foregroundStyle(CarboTheme.mutedText)
                        }
                    }
                }

                Button {
                    store.saveRecipe(recipe)
                    dismiss()
                } label: {
                    Text("Save Recipe")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CarboTheme.accent)
            }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Recipe")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct TrendsView: View {
    @EnvironmentObject private var store: CarboCreditStore

    var body: some View {
        NavigationStack {
            List {
                Section("Measurements") {
                    ForEach(store.bodyMeasurements) { measurement in
                        HStack {
                            Text(measurement.date, style: .date)
                            Spacer()
                            Text("\(measurement.weight.clean) lb")
                            Text("\(measurement.waist.clean) in")
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Progress")
        }
    }
}

struct MeasurementEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CarboCreditStore
    @State private var weight = 146.8
    @State private var waist = 30.5

    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly Check-In") {
                    Stepper("Weight \(weight.clean) lb", value: $weight, in: 80...260, step: 0.2)
                    Stepper("Waist \(waist.clean) in", value: $waist, in: 20...60, step: 0.1)
                }

                Button {
                    store.addMeasurement(weight: weight, waist: waist)
                    dismiss()
                } label: {
                    Text("Save Check-In")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(CarboTheme.accent)
            }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Body Check-In")
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: CarboCreditStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Daily Goals") {
                    Stepper("Carb limit \(store.goals.carbLimit.clean)g", value: $store.goals.carbLimit, in: 50...400, step: 5)
                    Stepper("Protein target \(store.goals.proteinTarget.clean)g", value: $store.goals.proteinTarget, in: 40...240, step: 5)
                    Stepper("Calorie limit \(store.goals.calorieLimit.clean)", value: $store.goals.calorieLimit, in: 1000...4000, step: 50)
                    Stepper("LDL impact limit \(store.goals.ldlImpactLimit.clean)", value: $store.goals.ldlImpactLimit, in: 1...40, step: 1)
                }

                Section("Weekly Credits") {
                    Stepper("Weekly carbs \(store.goals.weeklyCarbLimit.clean)g", value: $store.goals.weeklyCarbLimit, in: 200...2500, step: 25)
                    Stepper("Weekly calories \(store.goals.weeklyCalorieLimit.clean)", value: $store.goals.weeklyCalorieLimit, in: 5000...25000, step: 100)
                }
            }
            .onChange(of: store.goals) { _ in store.save() }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CarboCreditStore())
}
