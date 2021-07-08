//
//  TransitionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit


class TransitionController<Animator: TransitionAnimator>: NSObject, UIViewControllerTransitioningDelegate {

    let presentationInteractionController: InteractionControlling
    let dismissalInteractionController: InteractionControlling

    init(presentationInteractionController: InteractionControlling, dismissalInteractionController: InteractionControlling) {
        self.presentationInteractionController = presentationInteractionController
        self.dismissalInteractionController = dismissalInteractionController
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        Animator(presenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        Animator(presenting: false)
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        presentationInteractionController
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard dismissalInteractionController.isInteractionInProgress else { return nil }

        return dismissalInteractionController
    }
}
