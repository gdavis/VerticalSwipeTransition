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

    let interactionController = VSwipePresentationInteractionController()

    lazy var transitionController = TransitionController<VerticalSlideTransitionAnimator>(
        interactionController: interactionController
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        // take the interaction controller's guestre and add it to our invoking view
        swipeView.addGestureRecognizer(interactionController.externalGesture)

        // listen for the gesture's state to invoke presentation of the modal
        interactionController.externalGesture.addTarget(self, action: #selector(gestureAction))
    }

    @objc func gestureAction() {
        guard interactionController.isInteractionInProgress == false else { return }

        print("presenting view controller")

        let viewController = ModalViewController()
        viewController.transitioningDelegate = transitionController
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true, completion: nil)
    }
}
