//
//  VSwipeInteractionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

// TODO:(grant) Scroll view support

/// Protocol used to provide crutial metrics that
/// determine how the interactive transition performs.
///
/// This protocol is adopted by different objects to
/// provide metrics for the presentation and
/// dismissal of the view.
///
/// Since much of the logic to handle the logic
/// for managing the transition is similar for both
/// presentation and dismissal, this protocol
/// gives us a specific place to determine how the
/// math should be different when going between
/// the presentation and dismissal of a view.
///
protocol VSwipeMetric {

    var topMaxY: CGFloat? { get set }

    /// Provides the view controller that is the target for the pan slide transition.
    /// This is the "to" view duration presentation, and the "from" view on dismissal.
    /// - Parameter transitionContext: The context information for the transition.
    func targetViewController(transitionContext: UIViewControllerContextTransitioning) -> UIViewController?

    /// Returns the initial frame for the target view controller
    /// - Parameter transitionContext: The context information for the transition.
    func initialPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect?

    /// Returns the final frame for the target view controller
    /// - Parameter transitionContext: The context information for the transition.
    func finalPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect?

    /// Returns the y position for the target view controller from the given progress and interaction distance.
    /// - Parameters:
    ///   - transitionContext: The context information for the transition.
    ///   - progress: The current progress of the transition, from 0-1.
    ///   - interactionDistance: The amount of distance that the target view can travel.
    func verticalPosition(transitionContext: UIViewControllerContextTransitioning, progress: CGFloat, interactionDistance: CGFloat) -> CGFloat

    /// Returns a boolean that indicates if the transition should finish or cancel given the current progress and gesture velocity.
    /// - Parameters:
    ///   - progress: The current progress of the transition, from 0-1.
    ///   - velocity: The current vertical velocity of the pan gesture.
    func shouldFinishTransition(progress: CGFloat, velocity: CGFloat) -> Bool

    /// Returns the amount of translation when a gesture interruption occurs.
    /// - Parameter transitionContext: The context information for the transition.
    func interruptionTranslation(transitionContext: UIViewControllerContextTransitioning) -> CGFloat

    /// The current progress of the transition given the amount of gesture translation and distance.
    /// - Parameters:
    ///   - verticalTranslation: The amount of vertical translation from the pan gesture.
    ///   - interactionDistance: The amount of distance that the target view can travel.
    func progress(verticalTranslation: CGFloat, interactionDistance: CGFloat) -> CGFloat
}


/// Object that controls user input during an interactive transition.
class VSwipeInteractionController: NSObject, InteractionControlling {

    class PresentationMetrics: VSwipeMetric {

        var topMaxY: CGFloat?

        func targetViewController(transitionContext: UIViewControllerContextTransitioning) -> UIViewController? {
            transitionContext.viewController(forKey: .to)
        }

        func initialPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect? {
            guard let presentedViewController = transitionContext.viewController(forKey: .to) else { return nil }

            let initialFrame = transitionContext.finalFrame(for: presentedViewController)
            let containerFrame = transitionContext.containerView.frame

            return initialFrame.offsetBy(dx: 0, dy: containerFrame.maxY)
        }

        func finalPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect? {
            guard let presentedViewController = transitionContext.viewController(forKey: .to) else { return nil }
            
            return transitionContext.finalFrame(for: presentedViewController)
        }

        func verticalPosition(transitionContext: UIViewControllerContextTransitioning, progress: CGFloat, interactionDistance: CGFloat) -> CGFloat {
            guard let presentedFinalFrame = finalPresentationFrame(transitionContext: transitionContext) else { return 0 }

            let position = presentedFinalFrame.maxY - interactionDistance * progress
            if let maxY = topMaxY {
                return max(maxY, position)
            }

            return position
        }

        func shouldFinishTransition(progress: CGFloat, velocity: CGFloat) -> Bool {
            // if the user has panned quickly in the opposite direction, cancel.
            if velocity > 300 { return false }

            return progress > 0.5 || velocity < -300
        }

        func interruptionTranslation(transitionContext: UIViewControllerContextTransitioning) -> CGFloat {
            guard let finalFrame = finalPresentationFrame(transitionContext: transitionContext),
                  let targetViewController = transitionContext.viewController(forKey: .to)
            else { return 0 }

            return finalFrame.height - targetViewController.view.frame.minY
        }

        func progress(verticalTranslation: CGFloat, interactionDistance: CGFloat) -> CGFloat {
            -verticalTranslation / interactionDistance
        }
    }

    class DismissalMetrics: VSwipeMetric {

        var topMaxY: CGFloat?

        func targetViewController(transitionContext: UIViewControllerContextTransitioning) -> UIViewController? {
            transitionContext.viewController(forKey: .from)
        }

        func initialPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect? {
            guard let dismissedViewController = transitionContext.viewController(forKey: .from) else { return nil }

            return transitionContext.initialFrame(for: dismissedViewController)
        }

        func finalPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect? {
            guard let targetViewController = transitionContext.viewController(forKey: .from) else { return nil }

            return targetViewController.view.frame
                .offsetBy(dx: 0, dy: transitionContext.containerView.frame.maxY)
//            return CGRect(origin: CGPoint(x: targetViewController.view.frame.minX, y: transitionContext.containerView.frame.maxY),
//                          size: targetViewController.view.frame.size)
        }

        func verticalPosition(transitionContext: UIViewControllerContextTransitioning, progress: CGFloat, interactionDistance: CGFloat) -> CGFloat {
            guard let initialFrame = initialPresentationFrame(transitionContext: transitionContext) else { return 0 }

            let position = initialFrame.minY + interactionDistance * progress
            if let maxY = topMaxY {
                return max(maxY, position)
            }

            return position
        }

        func shouldFinishTransition(progress: CGFloat, velocity: CGFloat) -> Bool {
            // if the user has panned quickly in the opposite direction, cancel.
            if velocity < -300 { return false }

            return progress > 0.5 || velocity > 300
        }

        func interruptionTranslation(transitionContext: UIViewControllerContextTransitioning) -> CGFloat {
            guard let targetViewController = transitionContext.viewController(forKey: .from) else { return 0 }
            
            return -targetViewController.view.frame.minY
        }

        func progress(verticalTranslation: CGFloat, interactionDistance: CGFloat) -> CGFloat {
            verticalTranslation / interactionDistance
        }
    }

    /// The current phase for the interaction. This can be either `presenting` or `dismissing`,
    /// and determines which metrics are used to perform calculations for the transition.
    ///
    /// This value is set by the `TransitionController` when vending this an interactive
    /// transition controller. This must be set properly to perform the transition successfully.
    ///
    var interactionPhase: InteractionPhase?

    // The current set of metrics to use for the current interaction phase.
    private var currentMetric: VSwipeMetric {
        switch interactionPhase {
        case .none, .presenting:
            return presentationMetrics
        case .dismissing:
            return dismissalMetrics
        }
    }

    // Object that provides the presentation metrics for the transition.
    lazy var presentationMetrics: VSwipeMetric = PresentationMetrics()

    // Object that provides the dismissal metrics for the transition.
    lazy var dismissalMetrics: VSwipeMetric = DismissalMetrics()

    // The duration for the finish and cancel animations when a gesture's
    // interaction has finished and we animate to the final position.
    private let finalAnimationDuration: TimeInterval = 0.6

    // The view controller that is being presented by the transition.
    private(set) weak var targetViewController: UIViewController?

    // TODO:(grant) finish scroll view support
    private(set) weak var scrollView: UIScrollView?

    // Boolean that determines if this controller is currently
    // engaged in an interactive transition.
    private(set) var isInteractionInProgress: Bool = false

    // The amount of distance that can be travelled when panning.
    private var interactionDistance: CGFloat = 0

    // The final frame of the target view controller for the current transition phase.
    private var presentedFinalFrame: CGRect = .zero

    /// Gesture that is available to external objects to trigger the start of
    /// an interactive transition. This should be added to the view that, when panned,
    /// will start the presentation of a modal view controller.
    private(set) lazy var externalGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(gestureAction(_:)))
        return gesture
    }()

    // The transition context for the active transition.
    private weak var transitionContext: UIViewControllerContextTransitioning?

    // The animation that animates to the finished or cancelled position.
    private var transitionAnimator: UIViewPropertyAnimator?

    /// Tracks the position of the view when an interruption occurs
    /// which is then used to offset the translation of a new gesture
    /// panning phase.
    private lazy var interruptedTranslation: CGFloat = 0

    /// Gesture that is used to interrupt an animator transitioning to the finish or
    /// cancelled state, that allows the user to restart interactivity.
    private lazy var interactionGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(gestureAction(_:)))
        gesture.delaysTouchesBegan = false
        return gesture
    }()
}


// MARK: - <UIViewControllerInteractiveTransitioning>

extension VSwipeInteractionController {

    func startInteractiveTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let presentedViewController = transitionContext.viewController(forKey: .to)
        else {
            assertionFailure()
            return
        }

        // setup the initial placement within the container and its position
        if interactionPhase == .presenting,
           let initialFrame = currentMetric.initialPresentationFrame(transitionContext: transitionContext)
        {
            presentedViewController.view.frame = initialFrame
            transitionContext.containerView.addSubview(presentedViewController.view)
        }

        self.targetViewController = currentMetric.targetViewController(transitionContext: transitionContext)
        self.transitionContext = transitionContext
        self.isInteractionInProgress = true

        // store frame and total travelled distance for later use
        presentedFinalFrame = currentMetric.finalPresentationFrame(transitionContext: transitionContext) ?? .zero
        interactionDistance = transitionContext.containerView.bounds.height// - presentedFinalFrame.minY

        disableOtherTouches()

        print(#function + ", interactionDistance: \(interactionDistance)")
    }
}


// MARK: - Transition Completion

private extension VSwipeInteractionController {

    func finish() {
        print(#function)

        enableOtherTouches()
        transitionContext?.finishInteractiveTransition()
        transitionContext?.completeTransition(true)

        // if we've completed a dismiss transition
        // we can reset the interaction phase and
        // remove the interruption gesture that triggers
        // a transition.
        if case .dismissing = interactionPhase {
            interactionPhase = nil
            removeInterruptionGesture()
        }

        reset()
    }

    func cancel() {
        print(#function)

        enableOtherTouches()
        transitionContext?.cancelInteractiveTransition()
        transitionContext?.completeTransition(false)

        // if we cancelled presenting, we need to reset
        // back to an initial state and remove
        // the interruption gesture if it was used.
        if case .presenting = interactionPhase {
            interactionPhase = nil
            removeInterruptionGesture()
        }
        // if we cancel a dismissal, we need to reset
        // back into a presenting state since the view
        // is still being presented.
        else if case .dismissing = interactionPhase {
            interactionPhase = .presenting
        }

        reset()
    }

    private func reset() {
        interruptedTranslation = 0
        isInteractionInProgress = false
        presentedFinalFrame = .zero

        transitionContext = nil
        transitionAnimator = nil
    }
}


// MARK: - Gesture Handling

extension VSwipeInteractionController {

    struct GestureStatus {
        let verticalTranslation: CGFloat
        let velocity: CGPoint
    }

    @objc private func gestureAction(_ gesture: UIPanGestureRecognizer) {
        // create a new status object to track the translation and velocity values.
        // include the value of an interrupted animation translation to "pick up"
        // where we left off from an interrupted animation position and include
        // that translation within the gesture's current translation.
        let status = GestureStatus(
            verticalTranslation: gesture.translation(in: gesture.view).y - interruptedTranslation,
            velocity: gesture.velocity(in: gesture.view)
        )

        switch gesture.state {
        case .began:
            gestureBegan(status)
        case .changed:
            gestureChanged(status)
        case .ended:
            gestureEnded(status)
        case .cancelled:
            gestureCancelled(status)
        default:
            break
        }
    }

    private func gestureBegan(_ status: GestureStatus) {
        guard let transitionContext = transitionContext
        else {
            // if we are currently in a presenting state but have no transition
            // context, then this gesture is triggering a new dismissal interaction
            if interactionPhase == .presenting {
                print("Starting dismissal from pan gesture")

                // mark that we have started a new interactive transition
                isInteractionInProgress = true

                // if we have a gesture starting, but we are not yet started a interactive transition,
                // then we need to invoke the transition by calling `dismiss` on the target vc.
                targetViewController?.dismiss(animated: true, completion: nil)
            }

            return
        }

        // if the user starts a new pan gesture, we want to cancel
        // the existing transition animation so we can
        // begin the dragging of the view again to keep things
        // fully interactive, even while animating to a
        // finish or cancel position in the view.
        transitionAnimator?.stopAnimation(true)

        // if an interaction is currently in progress,
        // then we will track the current position of the
        // view and use that as a translation offset for
        // the new gesture, keeping the position in line
        // with where it was interrupted.
        if isInteractionInProgress {
            // store the distance of the presented view to the final frame position,
            // and later use it to include in the interrupted gesture's translation
            // so we account for the distance travelled from the interrupted gesture.
            interruptedTranslation = currentMetric.interruptionTranslation(transitionContext: transitionContext)

            print("Interrupting animation, interruptedTranslation: \(interruptedTranslation)")
        }
    }

    private func gestureChanged(_ status: GestureStatus) {
        let progress = currentMetric.progress(verticalTranslation: status.verticalTranslation, interactionDistance: interactionDistance)

        updatePresentedView(progress)
    }

    private func gestureEnded(_ status: GestureStatus) {
        print(#function)

        let progress = currentMetric.progress(verticalTranslation: status.verticalTranslation, interactionDistance: interactionDistance)
        let shouldFinish = currentMetric.shouldFinishTransition(progress: progress, velocity: status.velocity.y)

        // determine where to finish and start an animation to go there.
        if shouldFinish {
            performFinishTransition(status)
        } else {
            performCancelTransition(status)
        }

        // once a gesture ends, install the interruption gesture
        // that will be able to cancel the in-progress animation
        // and resume the interactive translation tracking.
        installInterruptionGesture()
    }

    private func gestureCancelled(_ status: GestureStatus) {
        performCancelTransition(status)
    }
}


// MARK: - Progress Update

private extension VSwipeInteractionController {

    private func updatePresentedView(_ progress: CGFloat) {
        guard let transitionContext = transitionContext,
              let targetViewController = targetViewController
        else { return }

        let frameY = currentMetric.verticalPosition(transitionContext: transitionContext,
                                                    progress: progress,
                                                    interactionDistance: interactionDistance)

//        print(#function + ", progress: \(progress), frameY: \(frameY)")

        targetViewController.view.frame = CGRect(
            x: presentedFinalFrame.minX,
            y: frameY,
            width: presentedFinalFrame.width,
            height: presentedFinalFrame.height
        )

        transitionContext.updateInteractiveTransition(progress)
    }
}


// MARK: - Interruption Gesture

private extension VSwipeInteractionController {

    func installInterruptionGesture() {
        // setup a custom pan gesture within the container to respond
        // to gestures that interrupt the animation transition
        transitionContext?.containerView.addGestureRecognizer(interactionGesture)
    }

    func removeInterruptionGesture() {
        interactionGesture.view?.removeGestureRecognizer(interactionGesture)
    }
}


// MARK: - Ending Transition Animations

private extension VSwipeInteractionController {

    func performFinishTransition(_ status: GestureStatus) {
        guard let transitionContext = transitionContext,
              let targetViewController = targetViewController,
              let finalFrame = currentMetric.finalPresentationFrame(transitionContext: transitionContext)
        else {
            return
        }

        print(#function)

        let initialVelocity = initialVelocity(to: finalFrame.origin, from: targetViewController.view.frame.origin, gestureVelocity: status.velocity)
        let timingParameters = UISpringTimingParameters(dampingRatio: 0.98, initialVelocity: initialVelocity)
        let finishAnimator = UIViewPropertyAnimator(duration: finalAnimationDuration, timingParameters: timingParameters)

        finishAnimator.addAnimations {
            print(#function + ", finalFrame: \(finalFrame)")
            targetViewController.view.frame = finalFrame
        }

        finishAnimator.addCompletion { [unowned self] _ in
            self.finish()
        }

        finishAnimator.startAnimation()

        self.transitionAnimator = finishAnimator
    }

    func performCancelTransition(_ status: GestureStatus) {
        guard let transitionContext = transitionContext,
              let targetViewController = targetViewController,
              let initialFrame = currentMetric.initialPresentationFrame(transitionContext: transitionContext)
        else {
            return
        }

        print(#function)

        let initialVelocity = initialVelocity(to: initialFrame.origin, from: targetViewController.view.frame.origin, gestureVelocity: status.velocity)
        let timingParameters = UISpringTimingParameters(dampingRatio: 0.98, initialVelocity: initialVelocity)
        let cancelAnimator = UIViewPropertyAnimator(duration: finalAnimationDuration, timingParameters: timingParameters)

        cancelAnimator.addAnimations {
            targetViewController.view.frame = initialFrame
        }

        cancelAnimator.addCompletion { [unowned self] _ in
            self.cancel()
        }

        cancelAnimator.startAnimation()

        self.transitionAnimator = cancelAnimator
    }

    func initialVelocity(to finalPosition: CGPoint, from currentPosition: CGPoint, gestureVelocity: CGPoint) -> CGVector {
        var vector: CGVector = .zero

        let deltaY = finalPosition.y - currentPosition.y
        if deltaY != 0 {
            vector.dy = gestureVelocity.y / deltaY
        }

        return vector
    }
}

private extension VSwipeInteractionController {
    func disableOtherTouches() {
        guard let targetViewController = targetViewController
        else {
            assertionFailure("Presented view controller not defined, unable to finish transition")
            return
        }

        targetViewController.view.subviews.forEach {
            $0.isUserInteractionEnabled = false
        }
    }

    func enableOtherTouches() {
        guard let targetViewController = targetViewController
        else {
            assertionFailure("Presented view controller not defined, unable to finish transition")
            return
        }

        targetViewController.view.subviews.forEach {
            $0.isUserInteractionEnabled = true
        }
    }
}


extension VSwipeInteractionController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = scrollView {
            return scrollView.contentOffset.y <= 0
        }

        return true
    }
}
