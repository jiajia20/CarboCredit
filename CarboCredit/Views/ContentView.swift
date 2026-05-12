import SwiftUI
import PhotosUI
import Charts

struct ContentView: View {
    @EnvironmentObject private var store: CarboCreditStore

    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor(CarboTheme.tabUnselected)
    }

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
                MeasurementTile(title: "Weight", value: store.latestMeasurement?.weight.clean ?? "-", unit: "kg")
                MeasurementTile(title: "Waist", value: store.latestMeasurement?.waist.clean ?? "-", unit: "cm")
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
    @State private var filter = LogFilter.all

    var filteredEntries: [FoodLogEntry] {
        store.logEntries.filter { entry in
            filter.matches(entry)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                TodaySummaryStrip(nutrition: store.todayNutrition, goals: store.goals)

                Picker("Filter", selection: $filter) {
                    ForEach(LogFilter.allCases) { filter in
                        Image(systemName: filter.icon)
                            .tag(filter)
                            .accessibilityLabel(filter.title)
                    }
                }
                .pickerStyle(.segmented)

                    LazyVStack(spacing: 10) {
                        ForEach(filteredEntries) { entry in
                            LogRow(entry: entry) {
                                store.deleteLogEntry(entry)
                            }
                                .cardStyle()
                        }
                    }
                }
                .padding()
            }
            .background(CarboTheme.background)
            .navigationTitle("Log")
        }
    }
}

enum LogFilter: String, CaseIterable, Identifiable {
    case all
    case manual
    case snack
    case mealPrep
    case eatingOut
    case recipe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .manual: "Manual"
        case .snack: "Snack"
        case .mealPrep: "Meal Prep"
        case .eatingOut: "Eating Out"
        case .recipe: "Recipe"
        }
    }

    var icon: String {
        switch self {
        case .all: "square.grid.2x2"
        case .manual: "square.and.pencil"
        case .snack: "birthday.cake"
        case .mealPrep: "takeoutbag.and.cup.and.straw"
        case .eatingOut: "camera"
        case .recipe: "plus.rectangle.on.rectangle"
        }
    }

    func matches(_ entry: FoodLogEntry) -> Bool {
        switch self {
        case .all:
            true
        case .manual:
            entry.source == .manual
        case .snack:
            entry.source == .snack
        case .mealPrep:
            entry.source == .mealPrep
        case .eatingOut:
            entry.source == .snapMeal
        case .recipe:
            entry.source == .recipe
        }
    }
}

struct TodaySummaryStrip: View {
    let nutrition: Nutrition
    let goals: NutritionGoals

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.headline)
                .foregroundStyle(CarboTheme.text)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                SummaryMetric(title: "Carbs", value: "\(nutrition.carbs.clean)g", goal: "\(goals.carbLimit.clean)g")
                SummaryMetric(title: "Protein", value: "\(nutrition.protein.clean)g", goal: "\(goals.proteinTarget.clean)g")
                SummaryMetric(title: "Calories", value: nutrition.calories.clean, goal: goals.calorieLimit.clean)
                SummaryMetric(title: "LDL", value: nutrition.ldlImpact.clean, goal: goals.ldlImpactLimit.clean)
            }
        }
        .cardStyle()
    }
}

struct SummaryMetric: View {
    let title: String
    let value: String
    let goal: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(CarboTheme.mutedText)
            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(CarboTheme.text)
            Text("of \(goal)")
                .font(.caption2)
                .foregroundStyle(CarboTheme.mutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(CarboTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct LogRow: View {
    let entry: FoodLogEntry
    let delete: () -> Void

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

            Button(action: delete) {
                Image(systemName: "trash")
                    .font(.caption.weight(.semibold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.bordered)
            .tint(CarboTheme.tabUnselected)
            .accessibilityLabel("Delete \(entry.name)")
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
    @State private var didLog = false

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
            Button {
                log()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    didLog = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        didLog = false
                    }
                }
            } label: {
                Label(didLog ? "Logged" : "Log", systemImage: didLog ? "checkmark" : "plus")
                    .labelStyle(.titleAndIcon)
            }
                .buttonStyle(.borderedProminent)
                .tint(didLog ? CarboTheme.protein : CarboTheme.accent)
                .scaleEffect(didLog ? 1.04 : 1)
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

    private var measurements: [BodyMeasurement] {
        store.bodyMeasurements.sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    MeasurementChartCard(
                        title: "Weight",
                        unit: "kg",
                        color: CarboTheme.protein,
                        measurements: measurements,
                        value: \.weight
                    )

                    MeasurementChartCard(
                        title: "Waist",
                        unit: "cm",
                        color: CarboTheme.accent,
                        measurements: measurements,
                        value: \.waist
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Measurements")
                            .font(.headline)
                        ForEach(measurements.reversed()) { measurement in
                        HStack {
                            Text(measurement.date, style: .date)
                            Spacer()
                                Text("\(measurement.weight.clean) kg")
                                Text("\(measurement.waist.clean) cm")
                        }
                            .font(.subheadline)
                            .foregroundStyle(CarboTheme.text)
                            .padding(10)
                            .background(CarboTheme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                    .foregroundStyle(CarboTheme.text)
                }
                .padding()
            }
            .background(CarboTheme.background)
            .navigationTitle("Progress")
        }
    }
}

struct MeasurementChartCard: View {
    let title: String
    let unit: String
    let color: Color
    let measurements: [BodyMeasurement]
    let value: KeyPath<BodyMeasurement, Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let latest = measurements.last {
                    Text("\(latest[keyPath: value].clean) \(unit)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CarboTheme.mutedText)
                }
            }

            Chart(measurements) { measurement in
                LineMark(
                    x: .value("Date", measurement.date),
                    y: .value(title, measurement[keyPath: value])
                )
                .foregroundStyle(color)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", measurement.date),
                    y: .value(title, measurement[keyPath: value])
                )
                .foregroundStyle(color)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 170)
        }
        .foregroundStyle(CarboTheme.text)
        .cardStyle()
    }
}

struct MeasurementEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: CarboCreditStore
    @State private var weight = 66.6
    @State private var waist = 77.5

    var body: some View {
        NavigationStack {
            Form {
                Section("Weekly Check-In") {
                    Stepper("Weight \(weight.clean) kg", value: $weight, in: 35...180, step: 0.1)
                    Stepper("Waist \(waist.clean) cm", value: $waist, in: 50...180, step: 0.5)
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
                    NumericGoalRow(title: "Carb limit", unit: "g", value: $store.goals.carbLimit, range: 50...400, step: 5)
                    NumericGoalRow(title: "Protein target", unit: "g", value: $store.goals.proteinTarget, range: 40...240, step: 5)
                    NumericGoalRow(title: "Calorie limit", unit: "", value: $store.goals.calorieLimit, range: 1000...4000, step: 50)
                    NumericGoalRow(title: "LDL impact limit", unit: "", value: $store.goals.ldlImpactLimit, range: 1...40, step: 1)
                }

                Section("Weekly Credits") {
                    NumericGoalRow(title: "Weekly carbs", unit: "g", value: $store.goals.weeklyCarbLimit, range: 200...2500, step: 25)
                    NumericGoalRow(title: "Weekly calories", unit: "", value: $store.goals.weeklyCalorieLimit, range: 5000...25000, step: 100)
                }
            }
            .onChange(of: store.goals) { store.save() }
            .scrollContentBackground(.hidden)
            .background(CarboTheme.background)
            .navigationTitle("Settings")
        }
    }
}

struct NumericGoalRow: View {
    let title: String
    let unit: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            HStack {
                TextField(title, value: $value, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 110)
                    .onChange(of: value) {
                        value = min(max(value, range.lowerBound), range.upperBound)
                    }

                if !unit.isEmpty {
                    Text(unit)
                        .foregroundStyle(CarboTheme.mutedText)
                }

                Spacer()

                Stepper(title, value: $value, in: range, step: step)
                    .labelsHidden()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(CarboCreditStore())
}
