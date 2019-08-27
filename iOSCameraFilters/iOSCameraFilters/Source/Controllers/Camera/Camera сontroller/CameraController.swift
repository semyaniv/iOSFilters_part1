//
//  CameraController.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit

final class CameraNavigationItem: UINavigationItem {
    @IBOutlet fileprivate weak var flashItem: UIBarButtonItem!
    @IBOutlet fileprivate weak var autofocusItem: UIBarButtonItem!
    @IBOutlet fileprivate weak var switchCameraItem: UIBarButtonItem!
}

final class CameraController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet private weak var cameraContainer: UIView!
    @IBOutlet private weak var bottomContainer: UIView!
    @IBOutlet private weak var cameraNavigationItem: CameraNavigationItem!
    @IBOutlet private weak var filtersScrollView: UIScrollView!
    
    
    // MARK: - Local variables
    private var viewModel = CameraViewModel()
    private var allEffectViews: [CameraPreviewThumbView]?  {
        return filtersScrollView.subviews.filter { $0 is CameraPreviewThumbView } as? [CameraPreviewThumbView]
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setNeedsStatusBarAppearanceUpdate()
        addEffectsPreview()
        configureCameraOutput()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barTintColor = .clear
        navigationController?.navigationBar.tintColor = .white
        (navigationController as? RootNavigationController)?.updateStatusBarStyle(.lightContent)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.resetCameraSettings()
        updateFlash()
        updateAutoFocus()
    }
    
    private func configureCameraOutput() {
        viewModel.takePhoto = { [weak self] photo, error in
            if let error = error {
                let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            } else if let photo = photo,
                let previewControl = self?.storyboard?.instantiateViewController(withIdentifier: "PreviewControl") as? PreviewControl {
                previewControl.photoImage = photo
                self?.navigationController?.pushViewController(previewControl, animated: true)
            }
        }
    }
    
    // MARK: - Actions
    @IBAction private func cancelAction(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func snapAction(_ sender: Any) {
        viewModel.onSnap()
    }
    
    @IBAction private func flashAction(_ sender: Any) {
        viewModel.onFlash()
        updateFlash()
    }
    
    @IBAction private func autofocusAction(_ sender: Any) {
        viewModel.onAutoFocus()
        updateAutoFocus()
    }
    
    @IBAction private func switchCameraAction(_ sender: Any) {
        viewModel.onCameraSwitch()
    }
}

// Views update
extension CameraController {
    private func updateFlash() {
        switch viewModel.cameraControl?.torchMode {
        case .on?: cameraNavigationItem.flashItem.image = UIImage(named: "button-splash-on")
        case .off?: cameraNavigationItem.flashItem.image = UIImage(named: "button-splash-off")
        case .auto?: cameraNavigationItem.flashItem.image = UIImage(named: "button-splash-auto")
        case .none: break
        }
    }
    
    private func updateAutoFocus() {
        switch viewModel.cameraControl?.autoFocus {
        case .on?: cameraNavigationItem.autofocusItem.image = UIImage(named: "button-auto-focus-on")
        case .off?: cameraNavigationItem.autofocusItem.image = UIImage(named: "button-auto-focus-off")
        case .none: break
        }
    }
}

// MARK: - Navigation
extension CameraController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {
        case let controller as CameraControl:
            viewModel.cameraControl = controller
        default: break
        }
    }
}

extension CameraController {
    private func addEffectsPreview() {
        var offset: CGFloat = 10.0
        
        viewModel.filtersArray.forEach { filterAlias in
            guard let placeholderImage = UIImage(named: "balloon-placeholder") else { return }
            let effectView = CameraPreviewThumbView(frame: CGRect(x: offset, y: 0.0, width: filtersScrollView.frame.size.height, height: filtersScrollView.frame.size.height),
                                                    image: placeholderImage,
                                                    filterAlias: filterAlias)
            filtersScrollView.addSubview(effectView)
            offset += 10.0 + effectView.frame.size.width
            
            effectView.onSelect = { [weak self] effectView in
                guard let effectView = effectView else { return }
                self?.updateSelectedEffect(selectedView: effectView)
                self?.viewModel.onSelectFilter(effectView.filterAlias?.filter)
            }
        }
        updateSelectedEffect(selectedView: allEffectViews?[0])
        filtersScrollView.contentSize = CGSize(width: offset, height: 0.0)
    }
    
    func updateSelectedEffect(selectedView: CameraPreviewThumbView?) {
        guard let selectedView = selectedView else { return }
        allEffectViews?.forEach { thumbView in
            thumbView.selected = thumbView == selectedView
        }
    }
}
