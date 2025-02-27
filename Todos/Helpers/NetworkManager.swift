import Foundation

final class NetworkManager {
    static let shared = NetworkManager()
    private let todosURL = "https://jsonplaceholder.typicode.com/todos"
    private let usersURL = "https://jsonplaceholder.typicode.com/users"

    func fetchTodos(completion: @escaping ([Todo]?) -> Void) {
        guard let url = URL(string: todosURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            do {
                let todos = try JSONDecoder().decode([Todo].self, from: data)
                completion(todos)
            } catch {
                completion(nil)
            }
        }.resume()
    }

    func fetchUsers(completion: @escaping ([User]?) -> Void) {
        guard let url = URL(string: usersURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            do {
                let users = try JSONDecoder().decode([User].self, from: data)
                completion(users)
            } catch {
                completion(nil)
            }
        }.resume()
    }
}
