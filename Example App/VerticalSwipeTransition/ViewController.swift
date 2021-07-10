//
//  ViewController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import UIKit
import GDIVerticalSwipeTransition

class ViewController: UIViewController {

    var contentScrollView: UIScrollView?

    @IBOutlet var swipeView: UIView!

    // Stores the interaction controller in memory to handle interaction
    // with the presented view controller. This must be kept active during the
    // presentation of the view in order to manage interactivity while displayed.
    let interactionController = VSwipeInteractionController()

    // Stores the object that manages the entire transition process.
    // The generic value defines the animation that is used for the transition,
    // and allows for a custom interaction controller as well.
    lazy var transitionController = TransitionController<VSwipeTransitionAnimator>(
        interactionController: interactionController
    )

    lazy var tapGesture: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(gestureAction))
        return gesture
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // take the interaction controller's guestre and add it to our invoking view
        swipeView.addGestureRecognizer(interactionController.externalGesture)
        swipeView.addGestureRecognizer(tapGesture)

        // listen for the gesture's state to invoke presentation of the modal
        interactionController.externalGesture.addTarget(self, action: #selector(gestureAction))
        interactionController.externalGesture.require(toFail: tapGesture)

        // prevent the view from going beyond the top (into negative y positions)
        interactionController.presentationMetrics.topMaxY = 0
        interactionController.dismissalMetrics.topMaxY = 0

        // use a custom presentation controller to customize the size
        // of the presented view controller, and show a dimmer view.
        // comment this out to use the default full-screen presentation.
        transitionController.presentationControllerProvider = self
    }

    @objc func gestureAction() {
        // do not try to present again if a presentation is in progress.
        // without this, we would attempt to present the same view controller
        // multiple times while the transition is running, causing inconsistencies
        // in the view transition process.
        guard presentedViewController == nil else { return }

        guard let viewController = ModalViewController.instantiateFromStoryboard() as? UINavigationController,
              let modalViewController = viewController.topViewController as? ModalViewController
        else {
            assertionFailure()
            return
        }

        // tell the interaction controller to handle dismissal from the table view
        // when it is scrolled to the top of its content
        interactionController.scrollView = modalViewController.tableView

        // configure the presented view controller to use our custom controller,
        // and set it to use a custom presentation style to make use of it
        viewController.transitioningDelegate = transitionController
        viewController.modalPresentationStyle = .custom

        // finally present
        present(viewController, animated: true, completion: nil)
    }
}

extension ViewController: PresentationControllerProvider {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController {
        // here we provide a custom presentation controller that manages adjustments to
        // the presentation that is not part of the transition animation or the interactivity.
        // implement a custom presentation controller when you want to adjust the frame of
        // the presented view, or adjust other views outside of the transition.
        VSwipePresentationController(presentedViewController: presented, presenting: presenting)
    }
}
