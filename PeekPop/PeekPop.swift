//
//  PeekPop.swift
//  PeekPop
//
//  Created by Roy Marmelstein on 06/03/2016.
//  Copyright © 2016 Roy Marmelstein. All rights reserved.
//

import Foundation

public class PeekPop: NSObject {
    
    var viewController: UIViewController
    var targetViewController: UIViewController?

    private var peekPopGestureRecognizer: PeekPopGestureRecognizer?
    private var peekPopView: PeekPopView?
    private var previewingContexts = [PreviewingContext]()
    
    var originalDelegate: PeekPop3DTouchDelegate?
    
    /**
    Peek pop initializer
     
     - parameter viewController: hosting UIViewController
     
     - returns: PeekPop object
     */
    public init(viewController: UIViewController) {
        self.viewController = viewController
    }
    
    /// Registers a view controller to participate with 3D Touch preview (peek) and commit (pop).
    public func registerForPreviewingWithDelegate(delegate: PeekPopPreviewingDelegate, sourceView: UIView) -> PreviewingContext {
        let previewing = PreviewingContext(delegate: delegate, sourceView: sourceView)
        previewingContexts.append(previewing)
        if #available(iOS 9.0, *) {
            if self.viewController.traitCollection.forceTouchCapability == UIForceTouchCapability.Available {
                let customDelegate = PeekPop3DTouchDelegate(delegate: delegate)
                customDelegate.registerFor3DTouch(sourceView, viewController: viewController)
                originalDelegate = customDelegate
                return previewing
                //&& TARGET_OS_SIMULATOR != 1
            }
        }
        let gestureRecognizer = PeekPopGestureRecognizer(target: self, action: "didPop")
        gestureRecognizer.traitCollection = viewController.traitCollection
        gestureRecognizer.context = previewing
        viewController.view.addGestureRecognizer(gestureRecognizer)
        peekPopGestureRecognizer = gestureRecognizer
        return previewing
    }
    
    /// Unregisters a view controller to participate with 3D Touch preview (peek) and commit (pop).
    public func unregisterForPreviewingWithContext(previewing: PreviewingContext) {
        if let contextIndex = previewingContexts.indexOf(previewing) {
            previewingContexts.removeAtIndex(contextIndex)
        }
    }
    
    func peekPopAnimate(progress: Double, context: PreviewingContext?) {
        // If there aren't any screenshots, take them
        if peekPopView == nil {
            let view = PeekPopView()
            UIApplication.sharedApplication().windows.first?.subviews.first?.addSubview(view)
            peekPopView = view
            peekPopView?.viewControllerScreenshot = viewController.view.screenshotView()
            if let targetViewController = targetViewController {
                targetViewController.view.frame = viewController.view.bounds
                peekPopView?.targetViewControllerScreenshot = targetViewController.view.screenshotView(false)
            }
            if let context = context {
                peekPopView?.sourceViewScreenshot = context.sourceView.screenshotView()
                peekPopView?.sourceViewRect = viewController.view.convertRect(context.sourceView.frame, toView: viewController.view)
            }
            peekPopView?.frame = viewController.view.bounds
            peekPopView?.didAppear()
        }
        else {
            peekPopView?.frame = viewController.view.bounds
        }
        if progress < 0.99 {
            peekPopView?.peekPopAnimate(progress)
        }
        else {
            self.triggerTarget(context!)
        }
    }
    
    func triggerTarget(context: PreviewingContext){
        guard let targetViewController = targetViewController else {
            return
        }
        context.delegate.previewingContext(context, commitViewController: targetViewController)
        peekPopGestureRecognizer?.resetValues()
        self.performSelector("peekPopRelease", withObject: nil, afterDelay: 0.16)
    }
    
    func peekPopRelease() {
        peekPopView?.removeFromSuperview()
        peekPopView = nil
    }
    
}

public struct PreviewingContext {
    public let delegate: PeekPopPreviewingDelegate
    public let sourceView: UIView
}


public protocol PeekPopPreviewingDelegate {
    // If you return nil, a preview presentation will not be performed
    func previewingContext(previewingContext: PreviewingContext, viewControllerForLocation location: CGPoint) -> UIViewController?
    func previewingContext(previewingContext: PreviewingContext, commitViewController viewControllerToCommit: UIViewController)
}
