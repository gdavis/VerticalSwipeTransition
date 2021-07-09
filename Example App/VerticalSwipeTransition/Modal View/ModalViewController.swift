//
//  ModalViewController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

class ModalViewController: UITableViewController {

    static func instantiateFromStoryboard() -> UIViewController {
        let storyboard = UIStoryboard(name: "ModalView", bundle: nil)
        let navigationController = storyboard.instantiateInitialViewController()!
        return navigationController
    }

    enum Section {
        case standard
    }

    lazy var dataSource: UITableViewDiffableDataSource<Section, String> = {
        let dataSource = UITableViewDiffableDataSource<Section, String>(tableView: tableView) { tableView, indexPath, string in
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            cell?.textLabel?.text = string
            return cell
        }

        return dataSource
    }()


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemPink

        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 5

        createTableSnapshot()
    }

//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        createTableSnapshot()
//    }

    func createTableSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()

        snapshot.appendSections([Section.standard])

        var itemStrings = [String]()
        for i in 0..<50 {
            let rowTitle = "Row #\(i)"
            itemStrings.append(rowTitle)
        }

        snapshot.appendItems(itemStrings, toSection: .standard)

        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)
    }


    @IBAction func dismissAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
