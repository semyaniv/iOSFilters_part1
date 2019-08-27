//
//  CameraPreviewThumbView.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit

final class CameraPreviewThumbView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imageView)
        addSubview(titleLabel)
    }
    
    convenience init(frame: CGRect, image: UIImage, filterAlias filter: CameraFilterAlias) {
        defer {
            filterAlias = filter
            previewImage = image
            
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onSelectRecognizerAction(_:)))
            addGestureRecognizer(gestureRecognizer)
        }
        self.init(frame: frame)
    }
    
    convenience init () {
        self.init(frame: CGRect.zero)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("This class does not support NSCoding")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 10.0
        layer.borderWidth = 2.0
        layer.masksToBounds = true
        clipsToBounds = true
    }
    
    @objc private func onSelectRecognizerAction(_ sender: Any) {
        onSelect?(self)
    }
    
    var onSelect: ((_ view: CameraPreviewThumbView?) -> Void)?
    var selected = false {
        didSet {
            layer.borderColor = selected ? UIColor.white.cgColor : UIColor.clear.cgColor
        }
    }
    
    var filterAlias: CameraFilterAlias? {
        didSet {
            titleLabel.text = filterAlias?.name
        }
    }
    
    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: bounds)
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: frame.size.height - 20.0, width: frame.size.width, height: 20.0))
        label.backgroundColor = #colorLiteral(red: 0.07702089101, green: 0.1126967743, blue: 0.1666840613, alpha: 1).withAlphaComponent(0.7)
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10.0)
        
        return label
    }()
    
    private var previewImage: UIImage? {
        didSet {
            if let previewImage = previewImage {
                imageView.image = CameraViewModel.apply(filter: filterAlias?.filter, for: previewImage)
            }
        }
    }
}
