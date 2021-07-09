//
//  InteractionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit


/// Transition controller for the dismissal of a modally presented view.
class VSwipeDismissalInteractionController: NSObject, InteractionControlling {

    var scrollView: UIScrollView?

    var isInteractionInProgress: Bool = false


    // MARK: - <UIViewControllerInteractiveTransitioning>

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let originViewController = transitionContext.viewController(forKey: .from) else {
            assertionFailure()
            return
        }

    }
}


// MARK: - Gesture Handling

extension VSwipeDismissalInteractionController {

    func configure(forGesture gesture: UIPanGestureRecognizer, scrollView: UIScrollView? = nil) {
        gesture.delegate = self
        gesture.addTarget(self, action: #selector(gestureAction(_:)))

        // set the given scroll view to not scroll unless the pan gesture fails
        if let scrollView = scrollView {
            self.scrollView = scrollView
            scrollView.panGestureRecognizer.require(toFail: gesture)
        }
    }

    struct GestureStatus {
        let verticalTranslation: CGFloat
        let verticalVelocity: CGFloat
    }

    @objc private func gestureAction(_ gesture: UIPanGestureRecognizer) {
        let status = GestureStatus(verticalTranslation: gesture.translation(in: gesture.view).y,
                                   verticalVelocity: gesture.velocity(in: gesture.view).y)

        switch gesture.state {
        case .began:
            gestureBegan(status)

        case .changed:
            gestureChanged(status)

        case .ended:
            gestureEnded(status)

        default:
            break
        }
    }

    private func gestureBegan(_ status: GestureStatus) {

    }

    private func gestureChanged(_ status: GestureStatus) {

    }

    private func gestureEnded(_ status: GestureStatus) {

    }
}

extension VSwipeDismissalInteractionController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = scrollView {
            return scrollView.contentOffset.y <= 0
        }

        return true
    }
}
