//  ExamplesMenuViewController.swift
//  iOS Example
//
//  Created to provide a single entry point listing all sample screens,
//  including the new diffable data source demonstrations.
//
//  This controller becomes the initial view controller (embedded in a navigation controller).
//
//  Rows:
//  0 - Original Tab Bar Demo (existing tab bar with classic examples)
//  1 - Diffable Table (iOS 13+)
//  2 - Diffable Collection (iOS 13+)
//  3 - UITextView (code) example
//
//  NOTE: Diffable rows guarded with availability.

import UIKit
import SkeletonView

final class ExamplesMenuViewController: UIViewController {
    private enum Row: Int, CaseIterable { case tabBar, diffableTable, diffableCollection, textViewCode }

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Skeleton Examples"
        view.backgroundColor = .systemBackground
        configureTable()
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.isSkeletonable = true
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension ExamplesMenuViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.isSkeletonable = true
        guard let row = Row(rawValue: indexPath.row) else { return cell }
        switch row {
        case .tabBar: cell.textLabel?.text = "Original Tab Bar Demo"
        case .diffableTable: cell.textLabel?.text = "Diffable Table Demo"; if #unavailable(iOS 13.0) { cell.textLabel?.text = "Diffable Table (Requires iOS 13)" }
        case .diffableCollection: cell.textLabel?.text = "Diffable Collection Demo"; if #unavailable(iOS 13.0) { cell.textLabel?.text = "Diffable Collection (Requires iOS 13)" }
        case .textViewCode: cell.textLabel?.text = "UITextView (Code) Demo"
        }
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let row = Row(rawValue: indexPath.row) else { return }
        switch row {
        case .tabBar:
            if let tab = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController() as? UITabBarController {
                navigationController?.pushViewController(tab, animated: true)
            }
        case .diffableTable:
            if #available(iOS 13.0, *), let vcType = NSClassFromString("iOS_Example.DiffableTableViewController") as? UIViewController.Type {
                navigationController?.pushViewController(vcType.init(), animated: true)
            }
        case .diffableCollection:
            if #available(iOS 13.0, *), let vcType = NSClassFromString("iOS_Example.DiffableCollectionViewController") as? UIViewController.Type {
                navigationController?.pushViewController(vcType.init(), animated: true)
            }
        case .textViewCode:
            navigationController?.pushViewController(UITextViewByCodeViewController(), animated: true)
        }
    }
}
