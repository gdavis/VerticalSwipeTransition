//
//  ModalViewController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

class ModalViewController: UIViewController {

    lazy var dismissButton: UIButton = {
        let button = UIButton(type: .close)
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(dismissView), for: .touchUpInside)

        // TODO:(grant) remove debugging outline
        button.layer.borderColor = UIColor.yellow.cgColor
        button.layer.borderWidth = 2

        return button
    }()

    @objc func dismissView() {
        print(#function)
        dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemPink
        view.addSubview(dismissButton)
        dismissButton.center = view.center
        
        view.layer.borderColor = UIColor.green.cgColor
        view.layer.borderWidth = 5
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        dismissButton.center = view.center
    }
}
