//
//  VerticalSlideTransitionAnimator.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

///
/// Animator that performs a vertical slide transition to bring
/// the presented view on-screen from the bottom of the presenting view
/// to the final view frame defined by the presentation controller.
///
class VerticalSlideTransitionAnimator: NSObject, TransitionAnimator {

    let presenting: Bool
    let animationDuration: TimeInterval = 0.35

    required init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        animationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if presenting {
            animateIn(transitionContext)
        }
        else {
            animateOut(transitionContext)
        }
    }
}

private extension VerticalSlideTransitionAnimator {

    func animateIn(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let originViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let destinationViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        else {
            assertionFailure()
            return
        }

        let containerView = transitionContext.containerView
        containerView.addSubview(destinationViewController.view)

        let finalDestinationFrame = transitionContext.finalFrame(for: destinationViewController)
        let initialDestinationFrame = CGRect(x: 0, y: originViewController.view.frame.maxY, width: finalDestinationFrame.width, height: finalDestinationFrame.height)

        destinationViewController.view.frame = initialDestinationFrame

        let animationCurve: UIView.AnimationCurve = .easeInOut
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                              curve: animationCurve)
        {
            destinationViewController.view.frame = finalDestinationFrame
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        animator.startAnimation()
    }

    func animateOut(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let originViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)
        else {
            assertionFailure()
            return
        }

        let containerView = transitionContext.containerView
        let finalFrame = transitionContext.finalFrame(for: originViewController)
            .offsetBy(dx: 0, dy: containerView.frame.maxY)

        let animationCurve: UIView.AnimationCurve = .easeInOut
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                              curve: animationCurve)
        {
            originViewController.view.frame = finalFrame
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        animator.startAnimation()
    }
}
