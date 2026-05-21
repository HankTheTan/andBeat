import Foundation

/// Supabase 云端数据服务 — 由 Core 层统一持有，各模块通过此单例访问
/// 接入方式：等 Supabase Swift SDK 通过 SPM 添加后，补充具体实现
@Observable
final class SupabaseService {
    static let shared = SupabaseService()

    // 从 Supabase 控制台 Project Settings > API 获取
    private let projectURL: String = "YOUR_SUPABASE_URL"
    private let anonKey: String    = "YOUR_SUPABASE_ANON_KEY"

    private(set) var isAuthenticated: Bool = false
    private(set) var currentUserID: String? = nil

    private init() {}

    // MARK: - Auth（待 SDK 接入后实现）
    func signUp(email: String, password: String) async throws { }
    func signIn(email: String, password: String) async throws { }
    func signOut() async throws { }

    // MARK: - CycleProfile 云同步（待实现）
    func fetchCycleProfile() async throws -> CycleProfile? { return nil }
    func upsertCycleProfile(_ profile: CycleProfile) async throws { }

    // MARK: - DailyMetrics 云同步（待实现）
    func fetchDailyMetrics(limit: Int) async throws -> [DailyMetrics] { return [] }
    func insertDailyMetrics(_ metrics: DailyMetrics) async throws { }
}
