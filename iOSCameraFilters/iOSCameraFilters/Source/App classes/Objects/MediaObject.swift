//
//  MediaObject.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import Foundation

struct MediaObject {
    enum MediaType: String {
        case image
    }
    
    let fileUrl: URL
    let fileName: String
    let type: MediaType
}
