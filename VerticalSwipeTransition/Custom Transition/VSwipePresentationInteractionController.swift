//
//  VSwipePresentationInteractionController.swift
//  VerticalSwipeTransition
//
//  Created by Grant Davis on 7/7/21.
//

import Foundation
import UIKit

private protocol VSwipeMetric {
    func targetViewController(transitionContext: UIViewControllerContextTransitioning) -> UIViewController?

    func initialPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect?

    func finalPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect?

    func verticalPosition(transitionContext: UIViewControllerContextTransitioning, progress: CGFloat, interactionDistance: CGFloat) -> CGFloat

    func shouldFinishTransition(progress: CGFloat, velocity: CGFloat) -> Bool

    func interruptionTranslation(transitionContext: UIViewControllerContextTransitioning) -> CGFloat

    func progress(verticalTranslation: CGFloat, interactionDistance: CGFloat) -> CGFloat
}

class VSwipePresentationInteractionController: NSObject, InteractionControlling {

    private class PresentationMetrics: VSwipeMetric {
        func targetViewController(transitionContext: UIViewControllerContextTransitioning) -> UIViewController? {
            guard let presentedViewController = transitionContext.viewController(forKey: .to) else { return nil }
            return presentedViewController
        }

        func initialPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect? {
            guard let presentedViewController = transitionContext.viewController(forKey: .to) else { return nil }

            let containerFrame = transitionContext.containerView.frame
            return CGRect(origin: CGPoint(x: containerFrame.minX, y: containerFrame.maxY), size: presentedViewController.view.frame.size)
        }

        func finalPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect? {
            guard let presentedViewController = transitionContext.viewController(forKey: .to) else { return nil }

            return transitionContext.finalFrame(for: presentedViewController)
        }

        func verticalPosition(transitionContext: UIViewControllerContextTransitioning, progress: CGFloat, interactionDistance: CGFloat) -> CGFloat {
            guard let presentedFinalFrame = finalPresentationFrame(transitionContext: transitionContext) else { return 0 }

            return presentedFinalFrame.maxY - interactionDistance * progress
        }

        func shouldFinishTransition(progress: CGFloat, velocity: CGFloat) -> Bool {
            progress > 0.5 || velocity < -300
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

    private class DismissalMetrics: VSwipeMetric {
        func targetViewController(transitionContext: UIViewControllerContextTransitioning) -> UIViewController? {
            guard let dismissedViewController = transitionContext.viewController(forKey: .from) else { return nil }
            return dismissedViewController
        }

        func initialPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect? {
            guard let dismissedViewController = transitionContext.viewController(forKey: .from) else { return nil }

            return transitionContext.initialFrame(for: dismissedViewController)
        }

        func finalPresentationFrame(transitionContext: UIViewControllerContextTransitioning) -> CGRect? {
            guard let targetViewController = transitionContext.viewController(forKey: .from) else { return nil }

            return CGRect(origin: CGPoint(x: targetViewController.view.frame.minX, y: transitionContext.containerView.frame.maxY),
                          size: targetViewController.view.frame.size)
        }

        func verticalPosition(transitionContext: UIViewControllerContextTransitioning, progress: CGFloat, interactionDistance: CGFloat) -> CGFloat {
            guard let targetViewController = transitionContext.viewController(forKey: .from) else { return 0 }

            let initialFrame = transitionContext.initialFrame(for: targetViewController)

            return initialFrame.minY + interactionDistance * progress
        }

        func shouldFinishTransition(progress: CGFloat, velocity: CGFloat) -> Bool {
            progress > 0.5 || velocity > 300
        }

        func interruptionTranslation(transitionContext: UIViewControllerContextTransitioning) -> CGFloat {
            guard let targetViewController = transitionContext.viewController(forKey: .from) else { return 0 }

            return -targetViewController.view.frame.minY
        }

        func progress(verticalTranslation: CGFloat, interactionDistance: CGFloat) -> CGFloat {
            verticalTranslation / interactionDistance
        }
    }

    var interactionPhase: InteractionPhase?

    private var currentMetric: VSwipeMetric {
        switch interactionPhase {
        case .none, .presenting:
            return presentationMetrics
        case .dismissing:
            return dismissalMetrics
        }
    }

    private lazy var presentationMetrics: VSwipeMetric = PresentationMetrics()
    private lazy var dismissalMetrics: VSwipeMetric = DismissalMetrics()

    private let finalAnimationDuration: TimeInterval = 0.6

    private(set) weak var targetViewController: UIViewController?

    private(set) weak var scrollView: UIScrollView?

    private(set) var isInteractionInProgress: Bool = false

    private var interactionDistance: CGFloat = 0

    private var presentedFinalFrame: CGRect = .zero

    /// Gesture that is available to external objects to trigger the start of
    /// an interactive transition. This should be added to the view that, when panned,
    /// will start the presentation of a modal view controller.
    private(set) lazy var externalGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(gestureAction(_:)))
        return gesture
    }()

    private weak var transitionContext: UIViewControllerContextTransitioning?
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

extension VSwipePresentationInteractionController {

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

        print(#function + ", interactionDistance: \(interactionDistance), targetViewController: \(targetViewController)")
    }
}


// MARK: - Transition Completion

private extension VSwipePresentationInteractionController {

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

extension VSwipePresentationInteractionController {

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
//        print(#function + "translation: \(status.verticalTranslation), velocity: \(status.verticalVelocity)")

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
            if interactionPhase == .presenting {
                print("Starting dismissal from pan gesture")

                isInteractionInProgress = true

                // if we have a gesture starting, but we are not yet started a interactive transition,
                // then we need to invoke the transition by calling `dismiss` on the target vc.
                targetViewController?.dismiss(animated: true, completion: nil)
            }

            return
        }

//        print(#function)

        // if the user restarts a pan gesture, we want to cancel
        // the existing transition animation so we can
        // begin the dragging of the view again to keep things
        // fully interactive, even while animating to a
        // finish or cancel position in the view.
        transitionAnimator?.stopAnimation(true)

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

        installInterruptionGesture()
    }

    private func gestureCancelled(_ status: GestureStatus) {
        performCancelTransition(status)
    }
}


// MARK: - Progress Update

private extension VSwipePresentationInteractionController {

    private func updatePresentedView(_ progress: CGFloat) {
        guard let transitionContext = transitionContext,
              let targetViewController = targetViewController
        else { return }

        let frameY = currentMetric.verticalPosition(transitionContext: transitionContext,
                                                    progress: progress,
                                                    interactionDistance: interactionDistance)

        print(#function + ", progress: \(progress), frameY: \(frameY)")

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

private extension VSwipePresentationInteractionController {

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

private extension VSwipePresentationInteractionController {

    func performFinishTransition(_ status: GestureStatus) {
        guard let transitionContext = transitionContext,
              let targetViewController = targetViewController,
              let finalFrame = currentMetric.finalPresentationFrame(transitionContext: transitionContext)
        else {
//            assertionFailure("Presented view controller not defined, unable to finish transition")
            return
        }

        print(#function)

        let initialVelocity = initialVelocity(to: finalFrame.origin, from: targetViewController.view.frame.origin, gestureVelocity: status.velocity)
        let timingParameters = UISpringTimingParameters(dampingRatio: 0.98, initialVelocity: initialVelocity)
        let finishAnimator = UIViewPropertyAnimator(duration: finalAnimationDuration, timingParameters: timingParameters)

        finishAnimator.addAnimations {
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
//            assertionFailure("Presented view controller not defined, unable to finish transition")
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

private extension VSwipePresentationInteractionController {
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


extension VSwipePresentationInteractionController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let scrollView = scrollView {
            return scrollView.contentOffset.y <= 0
        }

        return true
    }
}
