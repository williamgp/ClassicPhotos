//
//  PhotoOperations.swift
//  ClassicPhotos
//
//  Created by William Peregoy on 8/8/17.
//  Copyright © 2017 raywenderlich. All rights reserved.
//

import UIKit

enum PhotoRecordState {
    case New,
    Downloaded,
    Filtered,
    Failed
}

class PhotoRecord {
    
    var name: String
    var url: URL
    var image = UIImage(named: "Placeholder")
    var state = PhotoRecordState.New
    
    init(name:String, url:URL) {
        self.name = name
        self.url = url
    }
}

class PendingOperations {
    
    lazy var downloadsInProgress = [IndexPath:Operation]()
    var downloadQueue: OperationQueue {
        var queue = OperationQueue()
        queue.name = "Download Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }
    
    lazy var filtrationsInProgress = [IndexPath:Operation]()
    var filtrationQueue: OperationQueue {
        var queue = OperationQueue()
        queue.name = "Filtrations Queue"
        queue.maxConcurrentOperationCount = 1
        return queue
    }
}

class ImageDownloader: Operation {
    let photoRecord: PhotoRecord
    
    init(photoRecord:PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        if self.isCancelled {
            return
        }
    
        guard let imageData = try? Data(contentsOf: self.photoRecord.url) else {
            self.setImageAsFailed()
            return
        }
        
        if self.isCancelled {
            return
        }
        
        if imageData.count > 0 {
            self.photoRecord.image = UIImage(data: imageData)
            self.photoRecord.state = .Downloaded
        } else {
            self.setImageAsFailed()
        }
    }
    
    func setImageAsFailed() {
        self.photoRecord.state = .Failed
        self.photoRecord.image = UIImage(named: "Failed")
    }
}


class ImageFiltration: Operation {
    let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main () {
        if self.isCancelled {
            return
        }
        
        if self.photoRecord.state != .Downloaded {
            return
        }
        
        if let filteredImage = self.applySepiaFilter(image: self.photoRecord.image!) {
            self.photoRecord.image = filteredImage
            self.photoRecord.state = .Filtered
        }
    }
    
    func applySepiaFilter(image:UIImage) -> UIImage? {
        let inputImage = CIImage(data:UIImagePNGRepresentation(image)!)
        
        if self.isCancelled {
            return nil
        }
        let context = CIContext(options:nil)
        let filter = CIFilter(name:"CISepiaTone")
        filter?.setValue(inputImage, forKey: kCIInputImageKey)
        filter?.setValue(0.8, forKey: "inputIntensity")
        let outputImage = filter?.outputImage
        
        if self.isCancelled {
            return nil
        }
        
        let outImage = context.createCGImage(outputImage!, from: outputImage!.extent)
        let returnImage = UIImage(cgImage: outImage!)
        return returnImage
    }
}

