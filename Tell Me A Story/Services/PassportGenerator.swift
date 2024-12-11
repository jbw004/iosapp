// Services/PassportGenerator.swift

import UIKit
import Photos

enum PassportGeneratorError: Error {
    case imageGenerationFailed
    case canvasLoadingFailed
    case coverLoadingFailed(String)
    case photosSaveError
    case photosPermissionDenied
    
    var localizedDescription: String {
        switch self {
        case .imageGenerationFailed:
            return "Failed to generate passport image"
        case .canvasLoadingFailed:
            return "Failed to load canvas background"
        case .coverLoadingFailed(let issueId):
            return "Failed to load cover for issue: \(issueId)"
        case .photosSaveError:
            return "Failed to save image to photos"
        case .photosPermissionDenied:
            return "Permission to save photos was denied"
        }
    }
}

final class PassportGenerator {
    
    private struct CoverData {
        let image: UIImage
        let position: CGPoint
        let rotation: CGFloat
    }
    
    static func generatePassport(canvas: CanvasTemplate, readIssues: [ReadIssue]) async throws -> UIImage {
        // First, load all images asynchronously
        let canvasImage = try await loadCanvasImage(from: canvas.imageUrl)
        let coverData = try await loadCoverImages(readIssues: readIssues)
        
        // Calculate passport size (3:4 aspect ratio)
        let width: CGFloat = 1200 // High resolution for sharing
        let height: CGFloat = width * 1.3
        let size = CGSize(width: width, height: height)
        
        // Create graphics context
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Ensure consistent size regardless of device scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        // Perform the actual rendering synchronously now that we have all assets
        return renderer.image { context in
            // Draw canvas background
            canvasImage.draw(in: CGRect(origin: .zero, size: size))
            
            // Draw all covers
            for data in coverData {
                let coverSize = CGSize(width: 180, height: 180)
                let coverRect = CGRect(
                    x: data.position.x - coverSize.width/2,
                    y: data.position.y - coverSize.height/2,
                    width: coverSize.width,
                    height: coverSize.height
                )
                
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: data.position.x, y: data.position.y)
                context.cgContext.rotate(by: data.rotation)
                context.cgContext.translateBy(x: -data.position.x, y: -data.position.y)
                
                // Draw cover with shadow
                context.cgContext.setShadow(
                    offset: CGSize(width: 0, height: 2),
                    blur: 4,
                    color: UIColor.black.withAlphaComponent(0.3).cgColor
                )
                
                // Create rounded corners mask
                let path = UIBezierPath(
                    roundedRect: coverRect,
                    cornerRadius: 12
                )
                context.cgContext.addPath(path.cgPath)
                context.cgContext.clip()
                
                data.image.draw(in: coverRect)
                context.cgContext.restoreGState()
            }
        }
    }
    
    private static func loadCanvasImage(from urlString: String) async throws -> UIImage {
        guard let canvasUrl = URL(string: urlString),
              let (canvasData, _) = try? await URLSession.shared.data(from: canvasUrl),
              let canvasImage = UIImage(data: canvasData) else {
            throw PassportGeneratorError.canvasLoadingFailed
        }
        return canvasImage
    }
    
    private static func loadCoverImages(readIssues: [ReadIssue]) async throws -> [CoverData] {
        let size = CGSize(width: 1200, height: 1200 * 1.3)
        let positions = generateCoverPositions(
            count: readIssues.count,
            containerSize: size,
            coverSize: CGSize(width: 180, height: 180)
        )
        
        return try await withThrowingTaskGroup(of: CoverData.self) { group in
            var coverData: [CoverData] = []
            
            for (index, issue) in readIssues.enumerated() {
                group.addTask {
                    guard let coverUrl = URL(string: issue.coverImageUrl),
                          let (coverData, _) = try? await URLSession.shared.data(from: coverUrl),
                          let coverImage = UIImage(data: coverData) else {
                        throw PassportGeneratorError.coverLoadingFailed(issue.issueId)
                    }
                    
                    return CoverData(
                        image: coverImage,
                        position: positions[index],
                        rotation: CGFloat.random(in: -0.2...0.2)
                    )
                }
            }
            
            for try await data in group {
                coverData.append(data)
            }
            
            return coverData
        }
    }
    
    static func saveToPhotos(image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        
        guard status == .authorized else {
            throw PassportGeneratorError.photosPermissionDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PassportGeneratorError.photosSaveError)
                }
            }
        }
    }
    
    private static func generateCoverPositions(
        count: Int,
        containerSize: CGSize,
        coverSize: CGSize
    ) -> [CGPoint] {
        var positions: [CGPoint] = []
        let padding: CGFloat = 20
        let minX = coverSize.width/2 + padding
        let maxX = containerSize.width - coverSize.width/2 - padding
        let minY = coverSize.height/2 + padding
        let maxY = containerSize.height - coverSize.height/2 - padding
        
        // Grid-based positioning with random offset
        let columns = Int(sqrt(Double(count))) + 1
        let rows = (count + columns - 1) / columns
        
        let cellWidth = (maxX - minX) / CGFloat(columns)
        let cellHeight = (maxY - minY) / CGFloat(rows)
        
        for i in 0..<count {
            let row = i / columns
            let col = i % columns
            
            // Base position
            let baseX = minX + cellWidth * CGFloat(col) + cellWidth/2
            let baseY = minY + cellHeight * CGFloat(row) + cellHeight/2
            
            // Add random offset within cell
            let offsetX = CGFloat.random(in: -cellWidth/4...cellWidth/4)
            let offsetY = CGFloat.random(in: -cellHeight/4...cellHeight/4)
            
            positions.append(CGPoint(
                x: baseX + offsetX,
                y: baseY + offsetY
            ))
        }
        
        return positions.shuffled() // Randomize final arrangement
    }
}
