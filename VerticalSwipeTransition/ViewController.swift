//
//  ViewController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import UIKit

class ViewController: UIViewController {

    var contentScrollView: UIScrollView?

    @IBOutlet var swipeView: UIView!

    let presentationTransitionController = VSwipePresentationInteractionController()
    let dismissalTransitionController = VSwipePresentationInteractionController()

    lazy var transitionController = TransitionController<VerticalSlideTransitionAnimator>(
        presentationInteractionController: presentationTransitionController,
        dismissalInteractionController: dismissalTransitionController
    )

    lazy var panGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(gestureAction))
        return gesture
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // configure the transition controller so it may respond
        // to the gesture events from the gestured embedded in the button area.
        presentationTransitionController.configure(forGesture: panGesture)

        swipeView.addGestureRecognizer(panGesture)
    }

    @objc func gestureAction() {
        guard presentationTransitionController.isInteractionInProgress == false else { return }

        print("presenting view controller")

        let viewController = ModalViewController()
        viewController.transitioningDelegate = transitionController
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true, completion: nil)
    }
}
