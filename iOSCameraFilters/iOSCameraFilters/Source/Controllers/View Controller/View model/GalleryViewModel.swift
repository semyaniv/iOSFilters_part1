//
//  GalleryViewModel.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit

protocol GalleryViewModelProtocol {
    var onViewModeChanged: (() -> Void)? { get set }
    var onShowMediaPreview: ((MediaObject) -> Void)? { get set }
}

final class GalleryViewModel: NSObject, GalleryViewModelProtocol {
    enum ViewMode {
        case view, edit
    }
    
    var onViewModeChanged: (() -> Void)?
    var onShowMediaPreview: ((MediaObject) -> Void)?
    
    var viewMode: ViewMode = .view {
        didSet {
            if viewMode == .view {
                removeSelectedItems()
                onViewModeChanged?()
            } else {
                onViewModeChanged?()
            }
        }
    }
    
    var numberOfRows: Int {
        return dataSource?.count ?? 0
    }
    var numberOfSections = 1
    var dataSource: [MediaObject]?
    let cellSpacing: CGFloat = 2
    private var selectedCells: NSMutableSet = []
}

// MARK: - Public
extension GalleryViewModel {
    func loadMedia() {
        dataSource = MediaManager.shared.loadMedia(.image)
    }
    
    func clearSelectedCells() {
        selectedCells.removeAllObjects()
    }
    
    func configureCell(_ cell: GalleryCollectionCell, indexPath: IndexPath) {
        guard let item = dataSource?[indexPath.item] else { return }
        cell.mediaPreviewImageView.image = UIImage(contentsOfFile: item.fileUrl.path)
        if viewMode == .edit {
            cell.selectImageView.isHidden = false
            cell.selectImageView.image = UIImage(named: selectedCells.contains(indexPath) ? "circle-selected" : "circle-deselected")
            cell.mediaPreviewImageView.alpha = selectedCells.contains(indexPath) ? 0.8 : 1.0
        } else {
            cell.selectImageView.isHidden = true
            cell.mediaPreviewImageView.alpha = 1.0
        }
    }
    
    func sizeForItem(collectionView: UICollectionView) -> CGSize {
        let cellSize = (collectionView.frame.size.width - (cellSpacing * 2.0)) / 3.0
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func didSelect(collectionView: UICollectionView, indexPath: IndexPath) {
        if viewMode == .edit {
            if selectedCells.contains(indexPath) {
                selectedCells.remove(indexPath)
            } else {
                selectedCells.add(indexPath)
            }
            
            UIView.performWithoutAnimation {
                collectionView.reloadItems(at: [indexPath])
            }
            return
        }
        
        guard let item = dataSource?[indexPath.item] else { return }
        onShowMediaPreview?(item)
    }
}

// MARK: - Private
extension GalleryViewModel {
    private func removeSelectedItems() {
        var mediaArray: [MediaObject] = []
        selectedCells.forEach { indexPath in
            if let indexPath = indexPath as? IndexPath, let selectedMedia = dataSource?[indexPath.item] {
                mediaArray.append(selectedMedia)
                dataSource?.remove(at: indexPath.item)
            }
        }
        
        MediaManager.shared.removeMedia(mediaArray)
    }
}
