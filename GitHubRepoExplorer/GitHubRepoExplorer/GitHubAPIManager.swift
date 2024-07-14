//
//  GitHubAPIManager.swift
//  GitHubRepoExplorer
//
//  Created by Sapna on 13/07/24.
//

import Foundation

class GitHubAPIManager {
    static let shared = GitHubAPIManager()
    private let baseURL = "https://api.github.com"
    
    func searchRepositories(query: String, page: Int, completion: @escaping ([RepositoryModel]) -> Void) {
        guard !query.isEmpty else {
            debugPrint("Error: Query parameter is empty.")
            completion([])
            return
        }
        
        let endpoint = "\(baseURL)/search/repositories?q=\(query)&page=\(page)&per_page=10"
        
        guard let url = URL(string: endpoint) else {
            debugPrint("Error: Invalid URL.")
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                debugPrint("Error: \(error?.localizedDescription ?? "Unknown error").")
                completion([])
                return
            }
            
            // Log the JSON response for debugging
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: [])
                debugPrint("JSON Response: \(jsonResponse)")
            } catch {
                debugPrint("Error serializing JSON: \(error)")
            }
            
            // Check for error response
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = jsonObject["message"] as? String {
                    debugPrint("API Error: \(message)")
                    completion([])
                    return
                }
            } catch {
                debugPrint("Error parsing error response: \(error)")
            }
            
            // Parse the JSON response
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let result = try decoder.decode(SearchResponse.self, from: data)
                completion(result.items ?? [])
            } catch {
                debugPrint("Error decoding JSON: \(error)")
                completion([])
            }
        }.resume()
    }
}

