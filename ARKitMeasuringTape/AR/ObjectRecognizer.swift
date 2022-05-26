//
//  ObjectRecognizer.swift
//  ARKitMeasuringTape
//
//  Created by Karina gurachevskaya on 26.05.22.
//  Copyright © 2022 Sai Sandeep. All rights reserved.
//

import UIKit
import Vision

struct RecognizedObject {
    var bounds: CGRect
    var label: String
    var confidence: Float

    var relativeCenter: CGPoint {
        .init(x: bounds.midX, y: 1 - bounds.midY)
    }
}

class ObjectRecognizer {
    private var completion: (([RecognizedObject]) -> Void)?
    private let confidenceThreshold: Float = 0.6
    private var requests: [VNRequest] = []

    init() {
        loadModel()
    }
    
    func recognize(fromPixelBuffer pixelBuffer: CVImageBuffer, completion: @escaping ([RecognizedObject]) -> Void) {
        self.completion = completion
        let exifOrientation = OrientationUtils.exifOrientationFromDeviceOrientation()
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: exifOrientation, options: [:])
        try? imageRequestHandler.perform(self.requests)
    }
    
    // MARK: - Private
    
    private func loadModel() {
        guard let modelURL = Bundle.main.url(forResource: "ObjectDetector", withExtension: "mlmodelc") else {
            assertionFailure()
            return
        }
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL))
            let objectRecognition = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                if let results = request.results {
                    self?.processResults(results.compactMap { $0 as? VNRecognizedObjectObservation })
                } else {
                    print("no results error \(String(describing: error?.localizedDescription))")
                }
            }
            objectRecognition.imageCropAndScaleOption = .scaleFit
            self.requests = [objectRecognition]
        } catch let error as NSError {
            print("Error while loading model: \(error)")
            assertionFailure()
        }
    }
    
    private func processResults(_ results: [VNRecognizedObjectObservation]) {
        var recognizedObjects: [RecognizedObject] = []
        for result in results {
            guard let label = result.labels.first else {
                continue
            }
            print("detected \(label.identifier) confidence \(label.confidence)")
            if label.confidence > confidenceThreshold {
                recognizedObjects.append(RecognizedObject(bounds: result.boundingBox, label: label.identifier, confidence: label.confidence))
            }
        }
        completion?(recognizedObjects)
    }
}
