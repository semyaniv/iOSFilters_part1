//
//  CameraViewModel.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit

typealias CameraFilterAlias = (name: String, filter: CIFilter?)
final class CameraViewModel: NSObject {
    var cameraControl: CameraControl?
    var takePhoto: ((UIImage?, Error?) -> Void)?
    
    lazy var filtersArray: [CameraFilterAlias] = {
        var result: [CameraFilterAlias] = []
        
        // Original
        result.append(("Original", nil))
        
        // Chrome
        if let filter = CIFilter(name: "CIPhotoEffectChrome") {
            result.append(("Chrome", filter))
        }
        
        // Instant Effect
        if let filter = CIFilter(name: "CIPhotoEffectInstant") {
            result.append(("Instant", filter))
        }
        
        // Process
        if let filter = CIFilter(name: "CIPhotoEffectProcess") {
            result.append(("Process", filter))
        }
        
        // Invert
        if let filter = CIFilter(name: "CIColorInvert") {
            result.append(("Invert", filter))
        }
        
        // CMYK halftone
        if let filter = CIFilter(name: "CICMYKHalftone", parameters: ["inputWidth" : 5, "inputSharpness": 1]) {
            result.append(("CMYK", filter))
        }
        
        // Monochrome
        if let filter = CIFilter(name: "CIColorMonochrome") {
            result.append(("Monochrome", filter))
        }
        
        // Sepiatone
        if let filter = CIFilter(name: "CISepiaTone") {
            result.append(("Sepia", filter))
        }
        
        // Noir
        if let filter = CIFilter(name: "CIPhotoEffectNoir") {
            result.append(("Noir", filter))
        }
        
        // Mono
        if let filter = CIFilter(name: "CIPhotoEffectMono") {
            result.append(("Mono", filter))
        }
        
        // Comic
        if let filter = CIFilter(name: "CIComicEffect") {
            result.append(("Comic", filter))
        }
        
        
        return result
    }()
    
    
    static func apply(filter: CIFilter?, for image: UIImage?) -> UIImage? {
        if let filter = filter, let image = image {
            let beginImage = CIImage(image: image)
            filter.setValue(beginImage, forKey: "inputImage")
            
            if let output = filter.outputImage {
                return UIImage(ciImage: output)
            }
        }
        
        return image
    }
}

// MARK: - Actions
extension CameraViewModel {
    func onSelectFilter(_ filter: CIFilter?) {
        cameraControl?.videoFilter = filter
    }
    
    func onSnap() {
        cameraControl?.takePhoto({ [weak self] image, error in
            self?.takePhoto?(image, error)
        })
    }
    
    func onFlash() {
        switch cameraControl?.torchMode {
        case .on?: cameraControl?.torchMode = .auto
        case .auto?: cameraControl?.torchMode = .off
        case .off?: cameraControl?.torchMode = .on
        case .none: break
        }
    }
    
    func onAutoFocus() {
        switch cameraControl?.autoFocus {
        case .on?: cameraControl?.autoFocus = .off
        case .off?: cameraControl?.autoFocus = .on
        case .none: break
        }
    }

    func onCameraSwitch() {
        cameraControl?.position = cameraControl?.position == .back ? .front : .back
    }
    
    func resetCameraSettings() {
        cameraControl?.torchMode = .off
        cameraControl?.autoFocus = .on
    }
}
