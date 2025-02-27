import Foundation

struct Todo: Decodable {
    let id: Int?
    let title: String?
    let completed: Bool?
    let userId: Int?
    var userName: String?
}

struct User: Decodable {
    let id: Int?
    let name: String?
}
