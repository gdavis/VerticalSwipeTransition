//
//  InteractionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit


protocol InteractionControlling: UIViewControllerInteractiveTransitioning {
    var isInteractionInProgress: Bool { get }
}

class InteractionController: NSObject, InteractionControlling {

    var verticalPanGesture: UIPanGestureRecognizer?

    var isInteractionInProgress: Bool = false

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {

    }
}
