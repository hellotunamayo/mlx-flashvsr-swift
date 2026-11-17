import Foundation
import MLXServeCore
import MLXToolKit
import MLXFlashVSR

@main
struct FlashVSRCLI {
    static func main() async throws {
        let args = CommandLine.arguments
        guard args.count >= 4 else {
            print("Usage: flashvsr-cli <input.mp4> <output.mp4> <model_directory>")
            exit(1)
        }

        let inputURL = URL(fileURLWithPath: args[1])
        let outputURL = URL(fileURLWithPath: args[2])
        let weightsDir = URL(fileURLWithPath: args[3])

        // 1. Initialize MLXServeEngine and set model store
        let engine = MLXServeEngine()
        await engine.useModelStore(ModelStore(root: weightsDir))

        // 2. Register FlashVSR package
        let config = FlashVSRConfiguration()
        let packageID = try await engine.register(
            FlashVSRUpscalePackage.registration,
            configuration: config
        )

        print("Starting video upscale (x2): \(inputURL.lastPathComponent)")
        let startTime = CFAbsoluteTimeGetCurrent()

        // 3. Read video data and upscale
        let input = try Data(contentsOf: inputURL)
        let format: Video.Format = inputURL.pathExtension.lowercased() == "mov" ? .mov : .mp4
        let video = Video(format: format, data: input)
        let request = VideoUpscaleRequest(video: video, scale: 2)
        let response = try await engine.run(request, package: packageID) as! VideoUpscaleResponse

        // 4. Save output file
        try response.video.data.write(to: outputURL)

        let elapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Done! Saved to: \(outputURL.path)")
        print("Inference time: \(String(format: "%.2f", elapsed)) s")
    }
}
