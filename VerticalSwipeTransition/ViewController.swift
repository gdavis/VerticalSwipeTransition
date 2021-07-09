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

    let interactionController = VSwipeInteractionController()

    lazy var transitionController = TransitionController<VerticalSlideTransitionAnimator>(
        interactionController: interactionController
    )

    override func viewDidLoad() {
        super.viewDidLoad()

        // take the interaction controller's guestre and add it to our invoking view
        swipeView.addGestureRecognizer(interactionController.externalGesture)

        // listen for the gesture's state to invoke presentation of the modal
        interactionController.externalGesture.addTarget(self, action: #selector(gestureAction))

        // prevent the view from going beyond the top (into negative y positions)
        interactionController.presentationMetrics.topMaxY = 0
        interactionController.dismissalMetrics.topMaxY = 0

        // use a custom presentation controller to customize the size
        // of the presented view controller
        transitionController.presentationControllerProvider = self
    }

    @objc func gestureAction() {
        // do not try to present again if an interaction is in progress.
        // without this, we would attempt to present the same view controller
        // multiple times while the transition is running, causing inconsistencies
        // in the view transition process.
        guard interactionController.isInteractionInProgress == false else { return }

        print("presenting view controller")

        guard let viewController = ModalViewController.instantiateFromStoryboard() as? UINavigationController,
              let modalViewController = viewController.topViewController as? ModalViewController
        else {
            assertionFailure()
            return
        }

        // tell the interaction controller to handle dismissal from the table view
        // when it is scrolled to the top of its content
        interactionController.scrollView = modalViewController.tableView

        viewController.transitioningDelegate = transitionController
        viewController.modalPresentationStyle = .custom
        present(viewController, animated: true, completion: nil)
    }
}

extension ViewController: PresentationControllerProvider {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController {
        VSwipePresentationController(presentedViewController: presented, presenting: presenting)
    }
}
