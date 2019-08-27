//
//  ViewController.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit

final class ViewController: UICollectionViewController {
    @IBOutlet private weak var editBarButton: UIBarButtonItem!
    @IBOutlet private weak var rightBarButton: UIBarButtonItem!
    
    private let viewModel = GalleryViewModel()
    private let cellIdentifier = "GalleryCollectionCellIdentifier"
    
    private lazy var mediaNotFoundLabel: UILabel = {
        let label = UILabel(frame: view.frame)
        label.text = "Gallery is empty"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .lightGray
        label.textAlignment = .center
        
        return label
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        handleViewModelActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.tintColor = nil
        (navigationController as? RootNavigationController)?.updateStatusBarStyle(.default)
        
        viewModel.loadMedia()
        collectionView.reloadData()
    }
    
    private func handleViewModelActions() {
        viewModel.onViewModeChanged = { [weak self] in
            if self?.viewModel.viewMode == .view {
                self?.rightBarButton.title = "Camera"
                self?.editBarButton.title = "Edit"
            } else {
                self?.rightBarButton.title = "Done"
                self?.editBarButton.title = "Remove selected"
            }
            
            self?.viewModel.clearSelectedCells()
            self?.collectionView.reloadData()
        }
        
        viewModel.onShowMediaPreview = { [weak self] item in
            guard let previewControl = self?.storyboard?.instantiateViewController(withIdentifier: "PreviewControl") as? PreviewControl else { return }
            previewControl.photoImage = UIImage(contentsOfFile: item.fileUrl.path)
            previewControl.previewType = .gallery
            
            self?.navigationController?.pushViewController(previewControl, animated: true)
        }
    }
    
    @IBAction func editBarButtonAction(_ sender: Any) {
        viewModel.viewMode = viewModel.viewMode == .edit ? .view : .edit
    }
    
    @IBAction func rightBarButtonAction(_ sender: Any) {
        if viewModel.viewMode == .view {
            performSegue(withIdentifier: "ShowCameraSegueIdentifier", sender: nil)
        } else {
            viewModel.clearSelectedCells()
            viewModel.viewMode = .view
        }
    }
}

// MARK: - CollectionView delegates
extension ViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let count = viewModel.dataSource?.count, count > 0 {
            showMediaNotFound(false)
            return count
        }
        
        showMediaNotFound(true)
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? GalleryCollectionCell else { return GalleryCollectionCell() }
        viewModel.configureCell(cell, indexPath: indexPath)
        
        return cell
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return viewModel.sizeForItem(collectionView: collectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return viewModel.cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return viewModel.cellSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.didSelect(collectionView: collectionView, indexPath: indexPath)
    }
}

extension ViewController {
    private func showMediaNotFound(_ exists: Bool) {
        if exists && view.subviews.filter( { $0 == mediaNotFoundLabel} ).count == 0 {
            view.addSubview(mediaNotFoundLabel)
        } else if exists == false {
            mediaNotFoundLabel.removeFromSuperview()
        }
    }
}
