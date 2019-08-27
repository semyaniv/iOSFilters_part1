//
//  MediaManager.swift
//  iOSCameraFilters
//
//  Created by Dmytriy Semyaniv on 27.08.2019.
//  Copyright © 2019 semyaniv. All rights reserved.
//

import UIKit

class MediaManager: NSObject {
    static let shared = MediaManager()
    
    // MARK: - Public
    func save(_ image: UIImage?, name: String = filename) -> Bool {
        guard let image = image else { return false }
        createTemplatesFolder(for: .image)
        let fileManager = FileManager.default
        
        fileManager.createFile(atPath: filePath(name: "\(name).png", mediaType: .image), contents: image.pngData(), attributes: nil)
        return true
    }
    
    func loadMedia(_ mediaType: MediaObject.MediaType) -> [MediaObject] {
        var loadedItems: [MediaObject] = []
        let fileManager = FileManager.default
        let dictionary = documentsDictionary(mediaType)
        do {
            let items = try fileManager.contentsOfDirectory(at: dictionary, includingPropertiesForKeys: nil)
            for item in items.filter( { $0.pathExtension == (mediaType == .image ? "png" : "" ) }) {
                loadedItems.append(MediaObject(fileUrl: item, fileName: item.deletingPathExtension().lastPathComponent, type: mediaType))
            }
        } catch { }
        
        return loadedItems
    }
    
    func removeMedia(_ media: [MediaObject]) {
        let fileManager = FileManager.default
        let images = media.filter({ $0.type == .image })
        if images.isEmpty == false {
            images.forEach { image in
                do {
                    try fileManager.removeItem(at: image.fileUrl)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    // MARK: - Private
    private class var filename: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func documentsDictionary(_ type: MediaObject.MediaType) -> URL {
        return (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last ?? URL(fileURLWithPath: "")).appendingPathComponent(type.rawValue)
    }
    
    private func createTemplatesFolder(for mediaType: MediaObject.MediaType) {
        let fileManager = FileManager.default
        let dictionary = documentsDictionary(mediaType)
        var isDirectory: ObjCBool = false
        if !fileManager.fileExists(atPath: dictionary.path, isDirectory: &isDirectory) {
            if isDirectory.boolValue == false {
                do {
                    try fileManager.createDirectory(at: dictionary, withIntermediateDirectories: false, attributes: nil)
                } catch {
                    print(error)
                }
            }
        }
    }
    
    private func filePath(name: String, mediaType: MediaObject.MediaType) -> String {
        return documentsDictionary(mediaType).appendingPathComponent(name).path
    }
}
