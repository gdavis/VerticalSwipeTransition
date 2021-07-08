//
//  ViewController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet var swipeView: UIView!

    let interactionController = InteractionController()
    lazy var transitionController = TransitionController<VerticalSlideTransitionAnimator>(
        interactionController: interactionController
    )

    lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer()
        gesture.addTarget(self, action: #selector(gestureAction))
        return gesture
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        swipeView.addGestureRecognizer(panGesture)
    }

    @objc func gestureAction() {
        switch panGesture.state {
        case .began:
            gestureStarted()

        case .changed:
            gestureChanged()

        case .ended:
            gestureEnded()

        default:
            break
        }
    }
}

private extension ViewController {

    func gestureStarted() {
        interactionController.verticalPanGesture = panGesture

        let viewController = ModalViewController()
        viewController.transitioningDelegate = transitionController
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true, completion: nil)
    }

    func gestureChanged() {

    }

    func gestureEnded() {

    }
}
