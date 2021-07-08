//
//  InteractionControlling.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit


protocol InteractionControlling: UIViewControllerInteractiveTransitioning {
    var isInteractionInProgress: Bool { get }
}
