//
//  OrientationUtils.swift
//  ARKitMeasuringTape
//
//  Created by Karina gurachevskaya on 26.05.22.
//  Copyright © 2022 Sai Sandeep. All rights reserved.
//

import AVFoundation
import UIKit

class OrientationUtils {
    class func exifOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let deviceOrientation = UIDevice.current.orientation
        let returnOrientation: CGImagePropertyOrientation
        
        switch deviceOrientation {
        case .portrait:
            returnOrientation = .right
        case .landscapeLeft:
            returnOrientation = .up
        case .landscapeRight:
            returnOrientation = .down
        case .portraitUpsideDown:
            returnOrientation = .left
        default:
            returnOrientation = .up
        }

        return returnOrientation
    }
    
    class func getCurrentOrientation() -> UIInterfaceOrientation {
        var orientation:UIInterfaceOrientation
        if #available(iOS 13.0, *) {
            orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation ?? .unknown
        } else {
            orientation = UIApplication.shared.statusBarOrientation
        }
        return orientation
    }
    
    class func videoOrientationForCurrentOrientation() -> AVCaptureVideoOrientation {
        let orientation = getCurrentOrientation()
        var videoOrientation:AVCaptureVideoOrientation = .portrait
        switch orientation {
        case .portrait:
            videoOrientation = .portrait
            break
        case .portraitUpsideDown:
            videoOrientation = .portraitUpsideDown
            break
        case .landscapeLeft:
            videoOrientation = .landscapeLeft
            break
        case .landscapeRight:
            videoOrientation = .landscapeRight
            break
        default:
            break
        }
        return videoOrientation
    }
}
