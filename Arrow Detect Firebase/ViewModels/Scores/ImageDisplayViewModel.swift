//
//  ImageDisplayViewModel.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 30/01/2025.
//

import Foundation
import Vision
import VisionKit
import CoreImage
import CoreImage.CIFilterBuiltins


@Observable
class ImageDisplayViewModel {
    
    let targetSize: ScoresheetViewModel.TargetSize
    var image: CIImage
    
    
    @ObservationIgnored private var scoreRadii: [String: Float] {
        switch targetSize {
        case .eighty:
            return ["": 1.0]
        case .sixty:
            return ["": 2.0]
        case .forty:
            return ["": 3.0]
        }
    }
    
    @ObservationIgnored private var quadDetectRequest: VNDetectRectanglesRequest {
        let request = VNDetectRectanglesRequest(completionHandler: self.quadPostProcess)
        request.maximumObservations = 1
        request.minimumSize = 0.4
        request.minimumConfidence = 0.5
        request.quadratureTolerance = 20
        return request
    }
    
    @ObservationIgnored private var contourDetectRequest: VNDetectContoursRequest {
        let request = VNDetectContoursRequest(completionHandler: self.contourPostProcess)
        request.detectsDarkOnLight = true
        request.contrastPivot = 0.1
        request.contrastAdjustment = 3.0
        request.maximumImageDimension = 1024
        return request
    }
    init(image: CIImage, targetSize: ScoresheetViewModel.TargetSize) {
        self.targetSize = targetSize
        self.image = image
    }
    
    private func correctPerspective (ciImage: CIImage, rectangle: VNRectangleObservation) -> CIImage? {
        let width = ciImage.extent.width
        let height = ciImage.extent.height
        let perspectiveFilter = CIFilter.perspectiveTransform()
        
        perspectiveFilter.inputImage = ciImage
        perspectiveFilter.topLeft = CGPoint(x: (rectangle.topLeft.x * width), y: (rectangle.topLeft.y * height))
        perspectiveFilter.topRight = CGPoint(x: (rectangle.topRight.x * width), y: (rectangle.topRight.y * height))
        perspectiveFilter.bottomLeft = CGPoint(x: (rectangle.bottomLeft.x * width), y: (rectangle.bottomLeft.y * height))
        perspectiveFilter.bottomRight = CGPoint(x: (rectangle.bottomRight.x * width), y: (rectangle.bottomRight.y * height))
        return perspectiveFilter.outputImage
    }
    private func preProcess(ciImage: CIImage) -> CIImage? {
        let monochromeFilter = CIFilter.colorControls()
        
        monochromeFilter.inputImage = ciImage
        monochromeFilter.saturation = 0
        return monochromeFilter.outputImage
    }
    
    private func quadPostProcess(request: VNRequest?, error: Error?){
        if let error {
            print(error)
            return
        } else if let result = request?.results?.first as? VNRectangleObservation {
            guard let processedImage = correctPerspective(ciImage: image, rectangle: result) else {
                print("could not unskew image perspective")
                return
            }
            image = processedImage
        } else {
            print("no rectangles found")
        }
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        do {
            guard let processed = preProcess(ciImage: image) else {return }
            image = processed
            try handler.perform([contourDetectRequest])
        } catch {
            print("contours error")
        }
    }
    
    private func contourPostProcess (request: VNRequest?, error: Error?) {
        guard let result = request?.results?.first as? VNContoursObservation else {
            print("No contours detected")
            return
        }
        depthFisrtTraverse(contours: result.topLevelContours.compactMap({$0}))
        let filtered = result.topLevelContours.compactMap({try? $0.polygonApproximation(epsilon: 0.05)}).filter({isArrow(contour: $0)})
        //findCoordinates(contours: result.topLevelContours.compactMap({$0}))
        guard let annotated = drawContours(on: image, contours: filtered, imageSize: image.extent.size) else { return}
        image = annotated
        
    }
    
    private func depthFisrtTraverse (contours: [VNContour], depth: Int = 0) {
        for contour in contours {
            if contour.childContourCount == 0 {
                print("contour \(contour.indexPath), arrow: \(isArrow(contour: contour)) depth: \(depth), points: \(contour.pointCount)")
            } else {
                depthFisrtTraverse(contours: contour.childContours, depth: depth+1)
            }
        }
    }
    
    private func isArrow (contour: VNContour) -> Bool {
        let trueBoundingBox = CGSize(width: contour.normalizedPath.boundingBox.width * image.extent.width, height: contour.normalizedPath.boundingBox.height * image.extent.height)
        let aspectRatio = trueBoundingBox.width / trueBoundingBox.height
        
        if contour.childContourCount == 0,  contour.pointCount < 50, contour.pointCount > 2, aspectRatio > 1.1 || aspectRatio < (1/1.1) {
            return true
        } else {
            return false
        }
    }
    
    private func findCoordinates (contours: [VNContour]) {
        for contour in contours {
            print(contour.normalizedPoints.first as Any)
        }
    }
    func drawContours(on ciImage: CIImage, contours: [VNContour], imageSize: CGSize, colour: UIColor = .red) -> CIImage? {
        _ = CIFormat.RGBA8
        let context = CIContext(options: nil)
        
        // Create CGImage from CIImage
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }

        let renderer = UIGraphicsImageRenderer(size: imageSize)
        let annotatedImage = renderer.image { ctx in
            
            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: imageSize.height)
            ctx.cgContext.concatenate(flipVertical)
            
            // Draw original image
            ctx.cgContext.draw(cgImage, in: CGRect(origin: .zero, size: imageSize))
            
            // Set contour drawing properties
            ctx.cgContext.setStrokeColor(colour.cgColor)
            ctx.cgContext.setLineWidth(2)

            for contour in contours {
                let points = contour.normalizedPoints.map { point in
                    CGPoint(x: CGFloat(point.x * Float(imageSize.width)), y: CGFloat((point.y) * Float(imageSize.height)))
                }
                
                if let firstPoint = points.first {
                    ctx.cgContext.move(to: firstPoint)
                    for point in points.dropFirst() {
                        ctx.cgContext.addLine(to: point)
                    }
                    ctx.cgContext.closePath()
                }
            }
            ctx.cgContext.strokePath()
        }

        return CIImage(image: annotatedImage)
    }
    
    func process() async {
        do {
            let handler = VNImageRequestHandler(ciImage: image, options: [:])
            try handler.perform([quadDetectRequest])
        } catch let error {
            print(error)
        }
    }
}
