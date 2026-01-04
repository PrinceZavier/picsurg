import Foundation
import CoreML
import Vision
import UIKit
import Combine

/// Service for ML-based surgical photo classification
final class MLService {

    enum MLError: Error {
        case modelLoadFailed
        case classificationFailed
        case invalidImage
    }

    // MARK: - Singleton

    static let shared = MLService()

    // MARK: - Model

    private var model: VNCoreMLModel?
    private var isModelLoaded = false

    // MARK: - Simulator Detection
    #if targetEnvironment(simulator)
    private let isSimulator = true
    #else
    private let isSimulator = false
    #endif

    private init() {
        loadModel()
    }

    private func loadModel() {
        do {
            // Load the compiled model
            let config = MLModelConfiguration()
            config.computeUnits = .cpuOnly // Use CPU only for compatibility

            // Try to load PicSurgeV1 model
            let mlModel = try PicSurgeV1(configuration: config).model
            model = try VNCoreMLModel(for: mlModel)
            isModelLoaded = true
            print("✅ ML Model loaded successfully")
        } catch {
            print("❌ Failed to load ML model: \(error)")
            isModelLoaded = false
        }
    }

    // MARK: - Classification

    /// Classification result
    struct ClassificationResult {
        let isSurgical: Bool
        let confidence: Float
        let label: String
    }

    /// Classify a single image
    func classifyImage(_ image: UIImage) async throws -> ClassificationResult {
        guard let cgImage = image.cgImage else {
            throw MLError.invalidImage
        }

        return try await classifyImageSync(cgImage)
    }

    /// Classify a CGImage synchronously on background thread
    private func classifyImageSync(_ cgImage: CGImage) async throws -> ClassificationResult {
        guard let model = model else {
            print("Model is nil, cannot classify")
            throw MLError.modelLoadFailed
        }

        return try await Task.detached(priority: .userInitiated) {
            let request = VNCoreMLRequest(model: model)
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                print("Vision request failed: \(error)")
                throw MLError.classificationFailed
            }

            guard let results = request.results as? [VNClassificationObservation],
                  let topResult = results.first else {
                throw MLError.classificationFailed
            }

            // Determine if surgical based on label
            // Your model uses "Surgical" and "NonSurgical" labels
            let isSurgical = topResult.identifier == "Surgical"

            return ClassificationResult(
                isSurgical: isSurgical,
                confidence: topResult.confidence,
                label: topResult.identifier
            )
        }.value
    }

    /// Classify image data
    func classifyImageData(_ data: Data) async throws -> ClassificationResult {
        guard let image = UIImage(data: data) else {
            throw MLError.invalidImage
        }
        return try await classifyImage(image)
    }

    // MARK: - Batch Classification

    /// Scan result for a photo
    struct ScanResult: Identifiable {
        let id = UUID()
        let assetIdentifier: String
        let isSurgical: Bool
        let confidence: Float
        let label: String
        var isSelected: Bool = true

        init(assetIdentifier: String, classification: ClassificationResult) {
            self.assetIdentifier = assetIdentifier
            self.isSurgical = classification.isSurgical
            self.confidence = classification.confidence
            self.label = classification.label
        }
    }

    /// Batch classify multiple images with progress callback
    func scanPhotos(
        images: [(identifier: String, image: UIImage)],
        progress: @escaping (Float) -> Void
    ) async -> [ScanResult] {
        // Check if model is loaded
        guard isModelLoaded, model != nil else {
            print("❌ Model not loaded, skipping scan")
            return []
        }

        print("🔍 Starting scan of \(images.count) images (simulator: \(isSimulator))")

        var results: [ScanResult] = []
        let total = Float(images.count)
        var successCount = 0
        var failCount = 0

        for (index, item) in images.enumerated() {
            do {
                let classification = try await classifyImage(item.image)
                successCount += 1

                print("✅ Classified \(item.identifier): \(classification.label) (\(String(format: "%.1f", classification.confidence * 100))%)")

                // Only include photos classified as "Surgical"
                if classification.isSurgical {
                    let result = ScanResult(
                        assetIdentifier: item.identifier,
                        classification: classification
                    )
                    results.append(result)
                    print("   → Added to results (surgical photo)")
                }
            } catch {
                failCount += 1
                // Skip images that fail to classify
                print("❌ Classification failed for \(item.identifier): \(error)")

                // In simulator, if ML keeps failing, treat all images as potential surgical for testing UI
                #if targetEnvironment(simulator)
                if failCount > 3 && successCount == 0 {
                    print("⚠️ Simulator ML not working - adding photo for UI testing")
                    let mockResult = ScanResult(
                        assetIdentifier: item.identifier,
                        classification: ClassificationResult(
                            isSurgical: true,
                            confidence: 0.85,
                            label: "Surgical (Simulator Test)"
                        )
                    )
                    results.append(mockResult)
                }
                #endif
            }

            // Update progress on main thread
            let currentProgress = Float(index + 1) / total
            await MainActor.run {
                progress(currentProgress)
            }
        }

        print("📊 Scan complete: \(successCount) succeeded, \(failCount) failed, \(results.count) surgical photos found")

        return results
    }

    /// Classification threshold - confidence must be above this to count as surgical
    var confidenceThreshold: Float = 0.5

    /// Filter results by confidence threshold
    func filterByConfidence(_ results: [ScanResult]) -> [ScanResult] {
        results.filter { $0.confidence >= confidenceThreshold }
    }
}
