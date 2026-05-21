import Foundation
import HealthKit

/// HealthKit 数据读取服务 — 由 Core 层统一持有，各模块不直接操作 HKHealthStore
@Observable
final class HealthKitService {
    static let shared = HealthKitService()

    private let store = HKHealthStore()
    private(set) var isAuthorized: Bool = false

    private init() {}

    // MARK: - 权限申请
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .respiratoryRate)!,
            HKObjectType.quantityType(forIdentifier: .bodyTemperature)!,
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: types)
            isAuthorized = true
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - 数据读取（待各模块按需调用）
    func fetchLatestHeartRate() async -> Double? { return nil }
    func fetchLatestHRV() async -> Double? { return nil }
    func fetchLatestRespiratoryRate() async -> Double? { return nil }
    func fetchLatestBodyTemperature() async -> Double? { return nil }
}
