//
//  InteractionControlling.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

public enum InteractionPhase {
    case presenting
    case dismissing
}

public protocol InteractionControlling: UIViewControllerInteractiveTransitioning {

    var interactionPhase: InteractionPhase? { get set }

    var isInteractionInProgress: Bool { get }
}
