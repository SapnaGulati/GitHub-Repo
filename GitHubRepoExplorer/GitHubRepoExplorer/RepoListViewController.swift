//
//  RepoListViewController.swift
//  GitHubRepoExplorer
//
//  Created by Sapna on 13/07/24.
//

import UIKit

import UIKit
import SystemConfiguration
import Network

class RepoListViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var repositories: [RepositoryModel] = []
    var currentPage = 1
    let itemsPerPage = 10
    var query = ""
    var totalResults = 0
    let initialLoadItemCount = 15
    
    private var pathMonitor: NWPathMonitor?
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        tableView.register(RepoCell.self, forCellReuseIdentifier: "RepoCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        // Setup reachability
        pathMonitor = NWPathMonitor()
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    debugPrint("Network is available")
                } else {
                    debugPrint("Network is not available")
                    self?.loadOfflineData()
                }
            }
        }
        pathMonitor?.start(queue: queue)
        tableView.reloadData()
    }
    
    private func loadOfflineData() {
        self.repositories = self.fetchRepositoriesFromCoreData()
        self.displayInitialItems()
        self.tableView.reloadData()
    }
    
    private func displayInitialItems() {
        let initialItemsCount = repositories.count > initialLoadItemCount ? initialLoadItemCount : repositories.count
        repositories = Array(repositories.prefix(initialItemsCount))
    }
    
    func searchRepositories(query: String, page: Int) {
        GitHubAPIManager.shared.searchRepositories(query: query, page: page) { [weak self] repositories in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if repositories.isEmpty {
                    debugPrint("Failed to fetch new repositories, showing previously loaded data.")
                    self.loadOfflineData()
                    return
                }
                let oldCount = self.repositories.count
                self.repositories.append(contentsOf: repositories)
                
                // Calculate the range of index paths to insert
                var indexPathsToInsert: [IndexPath] = []
                for row in oldCount..<self.repositories.count {
                    indexPathsToInsert.append(IndexPath(row: row, section: 0))
                }
                
                // Perform batch update on table view
                self.tableView.beginUpdates()
                self.tableView.insertRows(at: indexPathsToInsert, with: .automatic)
                self.tableView.endUpdates()
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRepoDetail",
           let indexPath = tableView.indexPathForSelectedRow,
           let destinationVC = segue.destination as? RepoDetailViewController {
            let selectedRepository = repositories[indexPath.row]
            destinationVC.repository = selectedRepository
        }
    }
}

// MARK: - UITableViewDataSource
extension RepoListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RepoCell", for: indexPath) as! RepoCell
        let repository = repositories[indexPath.row]
        cell.repository = repository
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}

// MARK: - UITableViewDelegate
extension RepoListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastElement = repositories.count - 1
        if indexPath.row == lastElement {
            currentPage += 1
            searchRepositories(query: query, page: currentPage)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let repository = repositories[indexPath.row]
        navigateToRepoDetail(repository: repository)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension RepoListViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let query = searchBar.text else { return }
        self.query = query
        currentPage = 1
        searchRepositories(query: query, page: currentPage)
        searchBar.resignFirstResponder()
    }
}

// MARK: - Core Data Methods
extension RepoListViewController {
    func saveRepositoriesToCoreData(_ repositories: [RepositoryModel]) {
        let context = CoreDataManager.shared.mainContext
        
        for repo in repositories {
            let repositoryEntity = RepositoryEntity(context: context)
            repositoryEntity.id = Int64(repo.id)
            repositoryEntity.name = repo.name
            repositoryEntity.owner = repo.owner.login
            repositoryEntity.repoDescription = repo.description ?? ""
            repositoryEntity.htmlUrl = repo.htmlUrl
            // repositoryEntity.imageUrl = repo.imageUrl // Add if imageUrl is needed
            // repositoryEntity.contributors = repo.contributors // Handle contributors separately
            
            do {
                try context.save()
            } catch {
                debugPrint("Failed to save repository entity: \(error)")
            }
        }
    }
    
    func fetchRepositoriesFromCoreData() -> [RepositoryModel] {
        let repositoryEntities = CoreDataManager.shared.fetchRepositories()
        
        return repositoryEntities.map { entity in
            RepositoryModel(
                id: Int(entity.id),
                name: entity.name ?? "",
                description: entity.repoDescription,
                htmlUrl: entity.htmlUrl ?? "",
                owner: Owner(login: entity.owner ?? ""),
                imageUrl: entity.imageUrl ?? "",
                contributors: nil // Handle contributors separately if needed
            )
        }
    }
    
    private func navigateToRepoDetail(repository: RepositoryModel) {
        guard let repoDetailVC = storyboard?.instantiateViewController(withIdentifier: "RepoDetailViewController") as? RepoDetailViewController else {
            return
        }
        repoDetailVC.repository = repository
        navigationController?.pushViewController(repoDetailVC, animated: true)
    }
}
