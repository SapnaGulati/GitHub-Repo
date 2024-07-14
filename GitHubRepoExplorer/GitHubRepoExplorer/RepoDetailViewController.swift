//
//  RepoDetailViewController.swift
//  GitHubRepoExplorer
//
//  Created by Sapna on 13/07/24.
//

import UIKit
import WebKit
import SafariServices

class RepoDetailViewController: UIViewController {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var ownerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var webViewContainer: UIView!
    
    var repository: RepositoryModel?
    var webView: WKWebView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLabels()
        setupWebView()
    }
    
    private func setupLabels() {
        if let repository = repository {
            nameLabel.text = "Repo: \(repository.name)"
            ownerLabel.text = "Owner: \(repository.owner.login)"
            descriptionLabel.text = "Desc: \(repository.description ?? "")"
        }
    }
    
    private func setupWebView() {
        guard let repository = repository, let url = URL(string: repository.htmlUrl ?? "") else {
            return
        }
        
        let webView = WKWebView(frame: webViewContainer.bounds)
        let request = URLRequest(url: url)
        webView.load(request)
        webViewContainer.addSubview(webView)
        self.webView = webView
    }
    
    @IBAction func openWebView(_ sender: UIButton) {
        guard let url = URL(string: repository?.htmlUrl ?? "") else {
            self.showAlert()
            return
        }
        
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: nil)
    }
    
    private func showAlert() {
        guard let htmlUrlString = repository?.htmlUrl, !htmlUrlString.isEmpty, let url = URL(string: htmlUrlString) else {
            // Show alert if htmlUrl is nil or empty
            let alert = UIAlertController(title: "URL Not Available", message: "The URL for this repository is not provided.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true, completion: nil)
    }
}
