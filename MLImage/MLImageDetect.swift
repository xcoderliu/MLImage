//
//  MLImageDetect.swift
//  MLImage
//
//  Created by 刘智民 on 29/11/2017.
//  Copyright © 2017 刘智民. All rights reserved.
//

import UIKit
import Vision

typealias analyticsCloser = (_ content : String? ) -> ()
typealias resultCloser = (_ content : String? ) -> ()

class MLImageDetect: NSObject {
    let analyticsQueue = DispatchQueue(label: "image.xcoderliu.ml")
    
    override init() {
        analyticsCallBack = nil
        resultCallBack = nil
    }
    
    private func myrequest(request:VNRequest,error:Error?) {
        analyticsQueue.async {
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("unknown!")
            }
            var best = ""
            var bestConfidence:VNConfidence = 0
            var analytics = ""
            
            for classfication in results {
                if classfication.confidence > bestConfidence {
                    best = classfication.identifier
                    bestConfidence = classfication.confidence
                }
                print("可能会是：\(classfication.identifier),可能性：\(classfication.confidence)\n")
                analytics=analytics.appending("可能会是：\(classfication.identifier),可能性：\(classfication.confidence)\n")
            }
            print("最终预测结果：\(best),可能性：\(bestConfidence)\n")
            guard let callback = self.analyticsCallBack else {return}
            guard let resultcallback = self.resultCallBack else {return}
            DispatchQueue.main.async {
                callback(analytics)
                callback("最终预测结果：\(best),可能性：\(bestConfidence)\n")
                resultcallback("\(best)")
            }
        }
    }
    
    public func detectImage(image:CGImage) {
        analyticsQueue.async {
            let modelFile = Inceptionv3()
            let model = try! VNCoreMLModel(for: modelFile.model)
            //start
            let handle = VNImageRequestHandler(cgImage: image)
            let request = VNCoreMLRequest(model: model, completionHandler: self.myrequest )
            try!handle.perform([request])
        }
    }
    
    public var analyticsCallBack: analyticsCloser?
    public var resultCallBack: resultCloser?
}
