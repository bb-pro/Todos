import UIKit
import Network

final class TodoListViewController: UIViewController {
    
    private let searchBar = UISearchBar()
    private let tableView = UITableView()
    private let footerActivityIndicator = UIActivityIndicatorView(style: .medium)

    private var allTodos: [Todo] = []
    private var filteredTodos: [Todo] = []
    private var currentPage = 0
    private let pageSize = 20
    private var isConnected = false
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private var isLoadingMoreData = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNetworkMonitor()
        handleNetworkChange()
    }
    
    private func setupUI() {
        title = "Todos"
        view.backgroundColor = .systemBackground

        searchBar.placeholder = "Search todos..."
        searchBar.delegate = self
        searchBar.inputAccessoryView = createToolbar()
        
        tableView.register(TodoCell.self, forCellReuseIdentifier: TodoCell.identifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = footerActivityIndicator
        
        
        view.addSubview(searchBar)
        view.addSubview(tableView)
        
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func setupNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.handleNetworkChange()
            }
        }
        monitor.start(queue: queue)
    }

    private func handleNetworkChange() {
        if isConnected {
            loadData()
        } else {
            loadFromCache()
        }
    }
    
    private func loadFromCache() {
        print("No internet connection. Loading cached todos.")
        if let cachedTodos = CacheManager().getCachedTodos() {
            self.allTodos = cachedTodos
            self.filteredTodos = Array(allTodos.prefix(pageSize))
            tableView.reloadData()
        }
    }
    
    private func loadData() {
        print("Internet available. Fetching new data...")
        
        NetworkManager.shared.fetchUsers { [weak self] users in
            guard let self = self, let users = users else {
                return
            }
            CacheManager().saveUsers(users)
            
            NetworkManager.shared.fetchTodos { [weak self] todos in
                guard let self = self, let todos = todos else {
                    return
                }
                
                var updatedTodos = todos
                for index in 0..<updatedTodos.count {
                    updatedTodos[index].userName = users.first(where: { $0.id == updatedTodos[index].userId })?.name
                }
                
                CacheManager().saveTodos(updatedTodos)
                
                DispatchQueue.main.async {
                    self.allTodos = updatedTodos
                    self.filteredTodos = Array(self.allTodos.prefix(self.pageSize))
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    private func loadMoreData() {
        guard !isLoadingMoreData else { return }
        isLoadingMoreData = true
        footerActivityIndicator.startAnimating()
        
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 1) { [weak self] in
            guard let self = self else { return }
            
            let nextIndex = (self.currentPage + 1) * self.pageSize
            guard nextIndex < self.allTodos.count else {
                self.isLoadingMoreData = false
                DispatchQueue.main.async {
                    self.footerActivityIndicator.stopAnimating()
                }
                return
            }
            
            self.currentPage += 1
            let moreData = self.allTodos[nextIndex..<min(nextIndex + self.pageSize, self.allTodos.count)]
            self.filteredTodos.append(contentsOf: moreData)
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.footerActivityIndicator.stopAnimating()
                self.isLoadingMoreData = false
            }
        }
    }
    
    private func createToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissKeyboard))
        
        toolbar.setItems([flexibleSpace, cancelButton], animated: false)
        return toolbar
    }
    
    @objc private func dismissKeyboard() {
        searchBar.resignFirstResponder()
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension TodoListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTodos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoCell.identifier, for: indexPath) as? TodoCell else {
                   return UITableViewCell()
               }
        let todo = filteredTodos[indexPath.row]
        cell.configure(with: todo)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailsVC = TodoDetailsViewController(todo: filteredTodos[indexPath.row])
        navigationController?.pushViewController(detailsVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
        print(filteredTodos[indexPath.row])
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let thresholdIndex = filteredTodos.count - 5
        if indexPath.row == thresholdIndex {
            loadMoreData()
        }
    }
}

// MARK: - Search Bar Delegate
extension TodoListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredTodos = Array(allTodos.prefix(pageSize))
        } else {
            filteredTodos = allTodos.filter { todo in
                let matchesTitle = todo.title?.lowercased().contains(searchText.lowercased()) ?? false
                let matchesUser = todo.userName?.lowercased().contains(searchText.lowercased()) ?? false
                return matchesTitle || matchesUser
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
