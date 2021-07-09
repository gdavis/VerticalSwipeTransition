//
//  TransitionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

///
/// Object that controls the transition by vending the animation to use for
/// presentation and dismissal. Animation objects are created when requested
/// and configured for presentation or dismissal.
///
/// Also defines the interaction controller to use to
/// handle interactive transitions during both the presentation and dismissal.
///
class TransitionController<Animator: TransitionAnimator>: NSObject, UIViewControllerTransitioningDelegate {

    // MARK: - Properties

    var interactionController: InteractionControlling?
    var presentationControllerProvider: PresentationControllerProvider?
    

    // MARK: - Initialization

    /// Creates a new `TransitionController` to manage transitions when displaying a view.
    ///
    /// - Parameters:
    ///   - interactionController: An optional interaction controller that is used to handle interactive input
    ///                            from a user and control the transition.
    ///   - presentationControllerProvider: An optional presentation controller provider that vends custom presentation controllers
    ///                                     that manipulates the presentation views outside of the transition.
    init(interactionController: InteractionControlling? = nil, presentationControllerProvider: PresentationControllerProvider? = nil) {
        self.interactionController = interactionController
        self.presentationControllerProvider = presentationControllerProvider
    }


    // MARK: - <UIViewControllerTransitioningDelegate>

    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        presentationControllerProvider?.presentationController(forPresented: presented, presenting: presenting, source: source)
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        Animator(presenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        Animator(presenting: false)
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionController = interactionController else { return nil }

        interactionController.interactionPhase = .presenting

        return interactionController
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard let interactionController = interactionController,
              interactionController.isInteractionInProgress
        else {
            interactionController?.interactionPhase = nil
            return nil
        }

        interactionController.interactionPhase = .dismissing

        return interactionController
    }
}
