import Foundation

/// Internal structure for reading the "type" field during polymorphic decoding.

struct TypeDiscriminator: Decodable {
    let typeRaw: String

    enum CodingKeys: String, CodingKey { case type }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.typeRaw = try c.decode(String.self, forKey: .type)
    }
}
