//
//  TransitionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit


class TransitionController<Animator: TransitionAnimator>: NSObject, UIViewControllerTransitioningDelegate {

    let interactionController: InteractionControlling

    init(interactionController: InteractionControlling) {
        self.interactionController = interactionController
    }

    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        Animator(presenting: true)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        Animator(presenting: false)
    }

    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        interactionController.interactionPhase = .presenting

        return interactionController
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        guard interactionController.isInteractionInProgress else {
            interactionController.interactionPhase = nil
            return nil
        }

        interactionController.interactionPhase = .dismissing

        return interactionController
    }
}
