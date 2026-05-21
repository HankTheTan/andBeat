//
//  andBeatApp.swift
//  andBeat
//
//  Created by Hank on 5/21/26.
//

import SwiftUI
import SwiftData

@main
struct andBeatApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CycleProfile.self,
            DailyMetrics.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // 首次启动时写入 Mock 数据
                    let ctx = sharedModelContainer.mainContext
                    MockDataSeeder.seedIfNeeded(in: ctx)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
