//
//  TransitionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

protocol PresentationControllerProvider {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController
}

class TransitionController<Animator: TransitionAnimator>: NSObject, UIViewControllerTransitioningDelegate {

    let interactionController: InteractionControlling
    var presentationControllerProvider: PresentationControllerProvider?

    init(interactionController: InteractionControlling, presentationControllerProvider: PresentationControllerProvider? = nil) {
        self.interactionController = interactionController
        self.presentationControllerProvider = presentationControllerProvider
    }

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
