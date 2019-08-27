//
//  PreviewControl.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit

class PreviewControl: UIViewController {
    enum PreviewType {
        case camera, gallery
    }
    
    var previewType: PreviewType = .camera {
        didSet {
            if previewType == .gallery {
                saveButton.isEnabled = false
            }
        }
    }
    var photoImage: UIImage?
    
    @IBOutlet private weak var previewImageView: UIImageView!
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    @IBOutlet private weak var exportButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewImageView.image = photoImage
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
    }
    
    @IBAction private func saveAction(_ sender: Any) {
        if MediaManager.shared.save(photoImage?.normalizedImage()) == true {
            navigationController?.popToRootViewController(animated: true)
        } else {
            let alertController = UIAlertController(title: nil, message: "Failed to save the file to app local storage", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction private func exportAction(_ sender: Any) {
        guard let photoImage = photoImage else { return }
        UIImageWriteToSavedPhotosAlbum(photoImage.normalizedImage(), self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default))
            present(alert, animated: true)
        } else {
            exportButton.image = nil
            exportButton.title = "Exported"
            exportButton.isEnabled = false
        }
    }
}

// MARK: - UIImage extension
extension UIImage {
    func normalizedImage() -> UIImage {
        if (imageOrientation == .up) {
            return self;
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale);
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: size.height)
        draw(in: rect)
        
        if let normalizedImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIGraphicsEndImageContext()
            return normalizedImage
        }
        
        UIGraphicsEndImageContext()
        return self
    }
}
