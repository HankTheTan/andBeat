import Foundation

// MARK: - SupabaseUser (accessible across all files)
struct SupabaseUser: Identifiable, Decodable {
    let id:       String
    let userName: String
    let email:    String?
}

// MARK: - Service
@Observable
final class SupabaseService {
    static let shared = SupabaseService()

    private let baseURL = "https://ycdwhokltspzznwcdccg.supabase.co/rest/v1"
    private let apiKey  = "sb_publishable_fEoJOv4pRLU-X7RyxxH8xw_Y4UTNW4d"
    let userID          = "11111111-1111-1111-1111-111111111111"

    private(set) var isAuthenticated: Bool    = true
    private(set) var currentUserID:   String? = "11111111-1111-1111-1111-111111111111"

    private init() {}

    // MARK: - Auth (stubs — seed user is pre-created in Supabase)
    func signUp(email: String, password: String) async throws { }
    func signIn(email: String, password: String) async throws { }
    func signOut() async throws { }

    // MARK: - Users
    func fetchUsers() async throws -> [SupabaseUser] {
        let data = try await get("users?select=id,user_name,email&order=created_at.asc")
        return try Self.decoder.decode([SupabaseUser].self, from: data)
    }

    // MARK: - CycleProfile
    func fetchCycleProfile(for userID: String? = nil) async throws -> CycleProfile? {
        let id   = userID ?? self.userID
        let data = try await get("cycle_profiles?user_id=eq.\(id)&select=*&limit=1")
        let rows = try Self.decoder.decode([CycleProfileRow].self, from: data)
        return rows.first.map(CycleProfile.from)
    }

    func upsertCycleProfile(_ profile: CycleProfile) async throws {
        let check = try await get("cycle_profiles?user_id=eq.\(userID)&select=id&limit=1")
        let ids   = try Self.decoder.decode([[String: String]].self, from: check)
        let body  = try Self.encoder.encode(CycleProfileRow(userID: userID, profile: profile))
        if let id = ids.first?["id"] {
            _ = try await patch("cycle_profiles?id=eq.\(id)", body: body)
        } else {
            _ = try await post("cycle_profiles", body: body)
        }
    }

    // MARK: - DailyMetrics
    func fetchDailyMetrics(for userID: String? = nil, limit: Int = 30) async throws -> [DailyMetrics] {
        let id   = userID ?? self.userID
        let data = try await get(
            "daily_metrics?user_id=eq.\(id)&order=record_date.desc&limit=\(limit)&select=*"
        )
        let rows = try Self.decoder.decode([DailyMetricsRow].self, from: data)
        return rows.map(DailyMetrics.from)
    }

    func insertDailyMetrics(_ metrics: DailyMetrics) async throws {
        let body = try Self.encoder.encode(DailyMetricsRow(userID: userID, metrics: metrics))
        _ = try await post("daily_metrics", body: body)
    }
}

// MARK: - HTTP
private extension SupabaseService {
    enum SupabaseError: Error { case http(Int, String) }

    func get(_ path: String) async throws -> Data {
        try await send(makeRequest(path, method: "GET"))
    }
    func post(_ path: String, body: Data) async throws -> Data {
        try await send(makeRequest(path, method: "POST", body: body))
    }
    func patch(_ path: String, body: Data) async throws -> Data {
        try await send(makeRequest(path, method: "PATCH", body: body))
    }

    func makeRequest(_ path: String, method: String, body: Data? = nil) -> URLRequest {
        var req = URLRequest(url: URL(string: "\(baseURL)/\(path)")!)
        req.httpMethod = method
        req.setValue(apiKey,             forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        return req
    }

    func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(code) else {
            throw SupabaseError.http(code, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }
}

// MARK: - JSON
private extension SupabaseService {
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
    static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()
}

// MARK: - CycleProfile DTO
private struct CycleProfileRow: Codable {
    var userId:          String
    var lastPeriodStart: String
    var cycleLength:     Int
    var periodLength:    Int

    private static let ymd: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    init(userID: String, profile: CycleProfile) {
        userId          = userID
        lastPeriodStart = Self.ymd.string(from: profile.lastPeriodStart)
        cycleLength     = profile.cycleLength
        periodLength    = profile.periodLength
    }
}

extension CycleProfile {
    fileprivate static func from(_ row: CycleProfileRow) -> CycleProfile {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        return CycleProfile(
            lastPeriodStart: df.date(from: row.lastPeriodStart) ?? Date(),
            cycleLength:     row.cycleLength,
            periodLength:    row.periodLength
        )
    }
}

// MARK: - DailyMetrics DTO
private struct DailyMetricsRow: Codable {
    var userId:          String
    var recordDate:      String
    var recordedAt:      String
    var heartRate:       Double?
    var bodyTemperature: Double?
    var hrv:             Double?
    var respiratoryRate: Double?
    var notes:           String?

    init(userID: String, metrics: DailyMetrics) {
        let df          = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        userId          = userID
        recordDate      = df.string(from: metrics.date)
        recordedAt      = ISO8601DateFormatter().string(from: metrics.date)
        heartRate       = metrics.heartRate
        bodyTemperature = metrics.bodyTemperature
        hrv             = metrics.hrv
        respiratoryRate = metrics.respiratoryRate
        notes           = metrics.notes
    }
}

extension DailyMetrics {
    fileprivate static func from(_ row: DailyMetricsRow) -> DailyMetrics {
        let df = DateFormatter(); df.dateFormat = "yyyy-MM-dd"
        return DailyMetrics(
            date:            df.date(from: row.recordDate) ?? Date(),
            heartRate:       row.heartRate,
            bodyTemperature: row.bodyTemperature,
            hrv:             row.hrv,
            respiratoryRate: row.respiratoryRate,
            notes:           row.notes
        )
    }
}
