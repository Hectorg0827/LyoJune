import Foundation

// MARK: - Bundle Extensions
extension Bundle {
    /// App version from Info.plist
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    /// Build number from Info.plist
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    /// App name from Info.plist
    var appName: String {
        return infoDictionary?["CFBundleDisplayName"] as? String ??
               infoDictionary?["CFBundleName"] as? String ?? "LyoApp"
    }
    
    /// Bundle identifier
    var bundleID: String {
        return bundleIdentifier ?? "com.lyo.app"
    }
    
    /// Full version string (version + build)
    var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - Dictionary Extensions for Any type support
extension Dictionary where Key == String, Value == Any {
    func encode() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    static func decode(from data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data, options: [])
        guard let dictionary = object as? [String: Any] else {
            throw NetworkError.decodingError("Failed to decode dictionary")
        }
        return dictionary
    }
}

// MARK: - Codable Dictionary Support
extension Dictionary: Codable where Key == String, Value == Any {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dictionary = try container.decode([String: CodableValue].self)
        self = dictionary.mapValues { $0.value }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let codableDict = mapValues { CodableValue($0) }
        try container.encode(codableDict)
    }
}

// Helper struct to make Any values codable
private struct CodableValue: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([CodableValue].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: CodableValue].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            let codableArray = array.map { CodableValue($0) }
            try container.encode(codableArray)
        case let dictionary as [String: Any]:
            let codableDict = dictionary.mapValues { CodableValue($0) }
            try container.encode(codableDict)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unable to encode value"))
        }
    }
}
