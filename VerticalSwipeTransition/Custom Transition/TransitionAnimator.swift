//
//  TransitionAnimator.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

protocol TransitionAnimator: UIViewControllerAnimatedTransitioning {
    init(presenting: Bool)
}

class VerticalSlideTransitionAnimator: NSObject, TransitionAnimator {

    let presenting: Bool

    required init(presenting: Bool) {
        self.presenting = presenting
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        3
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

            let originViewScale: CGFloat = 0.95
            originViewController.view.transform = CGAffineTransform(scaleX: originViewScale, y: originViewScale)
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        animator.startAnimation()
    }

    func animateOut(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let originViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
              let destinationViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
        else {
            assertionFailure()
            return
        }

        let containerView = transitionContext.containerView
        let fromViewFrame = CGRect(x: 0, y: containerView.frame.maxY, width: containerView.frame.width, height: containerView.frame.height)

        let animationCurve: UIView.AnimationCurve = .easeInOut
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
                                              curve: animationCurve)
        {
            originViewController.view.frame = fromViewFrame
            destinationViewController.view.transform = .identity
        }

        animator.addCompletion { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }

        animator.startAnimation()
    }
}
