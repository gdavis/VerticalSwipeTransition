//
//  VSwipePresentationController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/8/21.
//

import Foundation
import UIKit

///
/// This is a sample use case for a custom presentation controller
/// that adjusts the frame of the presented view to be inset
/// and placed within the top safe area.
///
/// A dimmer view is also placed on the presenting view
/// while the transition is in running, and demonstrates
/// how to keep the correct state when the interactive
/// transition is interrupted or cancelled.
///
class VSwipePresentationController: UIPresentationController {

    lazy var dimmerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()

    override var frameOfPresentedViewInContainerView: CGRect {
        let frame = containerView?.frame ?? super.frameOfPresentedViewInContainerView
        let topSafeArea = containerView?.safeAreaInsets.top ?? 0

        return frame
            .insetBy(dx: 10, dy: topSafeArea)
            .offsetBy(dx: 0, dy: topSafeArea)
    }

    override func presentationTransitionWillBegin() {
        guard let transitionCoordinator = presentedViewController.transitionCoordinator,
              let presentingView = presentingViewController.view
        else { return }

        presentingView.addSubview(dimmerView)
        dimmerView.frame = presentingView.frame
        dimmerView.alpha = 0

        transitionCoordinator.animate { [unowned self] context in
            self.dimmerView.alpha = 1
        } completion: { context in

        }
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        guard completed == false else { return }

        UIView.animate(withDuration: 0.2) {
            self.dimmerView.alpha = 0
        } completion: { finished in
            self.dimmerView.removeFromSuperview()
        }
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        guard completed else { return }

        UIView.animate(withDuration: 0.2) {
            self.dimmerView.alpha = 0
        } completion: { finished in
            self.dimmerView.removeFromSuperview()
        }
    }
}
