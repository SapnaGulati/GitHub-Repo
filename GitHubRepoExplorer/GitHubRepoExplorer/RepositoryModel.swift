//
//  RepositoryModel.swift
//  GitHubRepoExplorer
//
//  Created by Sapna on 13/07/24.
//

import Foundation

struct RepositoryModel: Codable {
    let id: Int
    let name: String
    let description: String?
    let htmlUrl: String?
    let owner: Owner
    let imageUrl: String?
    var contributors: [Contributor]?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, description, owner
        case htmlUrl = "html_url"
        case imageUrl = "avatar_url"
        case contributors = "contributors_url"
    }
}

struct Owner: Codable {
    let login: String
}

struct Contributor: Codable {
    let login: String
    let contributions: String
}

struct SearchResponse: Codable {
    let items: [RepositoryModel]?
}
