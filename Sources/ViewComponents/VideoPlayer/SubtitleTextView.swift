////  SubtitleTextView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/30/22.
//  
//

import SwiftUI
import Utilities
import SwiftWebVTT

public struct SubtitleTextView: View {
    public enum Size: CGFloat {
        case small = 0.75
        case normal = 1.0
        case large = 1.15
    }

    @StateObject private var viewModel = ViewModel()

    var url: URL? = nil
    var progress: Double = .zero
    var duration: Double = .zero
    var size = Size.normal
    var options: AttributedText.Options = .defaultBoxed

    public init(
        url: URL? = nil,
        progress: Double = .zero,
        duration: Double = .zero,
        size: Size = .normal,
        options: AttributedText.Options = .defaultBoxed
    ) {
        self.url = url
        self.progress = progress
        self.duration = duration
        self.size = size
        self.options = options
    }

    public var body: some View {
        Group {
            if let text = viewModel.vtt.value?.bounds(for: duration * progress)?.text {
                VStack(alignment: .center) {
                    Spacer()

                    AttributedText(
                        text: text,
                        options: options
                    )

                    Spacer(minLength: size.rawValue * 24)
                        .fixedSize()
                }
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity
                )
            }
        }
        .onChange(of: url, perform: {
            viewModel.updateURL($0)
        })
    }
}

extension AttributedText.Options {
    public static let defaultBoxed: Self = .init(
        fontSize: 18,
        backgroundColor: .black.opacity(0.5),
        backgroundRadius: 8,
        backgroundPadding: 8
    )

    public static let defaultStroke: Self = .init(
        fontSize: 18,
        shadowColor: .black,
        shadowOffset: 2,
        strokeColor: .black,
        strokeWidth: 3
    )
}

extension SubtitleTextView {

    class ViewModel: ObservableObject {
        var subtitleURL: URL? = nil
        @Published var vtt = Loadable<WebVTT>.idle

        private var subtitlesTask: URLSessionDataTask?

        func updateURL(_ url: URL?) {
            guard let url = url else {
                subtitlesTask?.cancel()
                subtitleURL = nil
                vtt = .idle
                return
            }

            guard url != subtitleURL else { return }
            subtitlesTask?.cancel()
            subtitleURL = url
            vtt = .loading

            subtitlesTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                do {
                    if error != nil {
                        throw URLError(.badServerResponse)
                    }

                    guard let data = data else {
                        throw URLError(.badServerResponse)
                    }

                    guard let stringVal = String(data: data, encoding: .utf8) else {
                        throw URLError(.badServerResponse)
                    }

                    let parser = WebVTTParser(string: stringVal)

                    self?.updateState(.success(try parser.parse()))
                } catch {
                    self?.updateState(.failed)
                }
            }

            subtitlesTask?.resume()
        }

        private func updateState(_ loadable: Loadable<WebVTT>) {
            DispatchQueue.main.async {
                self.vtt = loadable
            }
        }
    }
}

extension WebVTT: Equatable {
    public static func == (lhs: WebVTT, rhs: WebVTT) -> Bool {
        lhs.cues == rhs.cues
    }
}

extension WebVTT.Cue: Equatable {
    public static func == (lhs: WebVTT.Cue, rhs: WebVTT.Cue) -> Bool {
        lhs.timing == rhs.timing &&
        lhs.text == rhs.text
    }
}

extension WebVTT.Timing: Equatable {
    public static func == (lhs: WebVTT.Timing, rhs: WebVTT.Timing) -> Bool {
        lhs.start == rhs.start &&
        lhs.end == rhs.end
    }
}

struct SubtitleTextView_Previews: PreviewProvider {
    static var previews: some View {
        SubtitleTextView()
            .frame(width: 1280, height: 720)
    }
}

extension WebVTT {
    func bounds(for timeStamp: TimeInterval) -> Cue? {
        // TODO: parse for positions later if available
        cues.first(where: { $0.timeStart <= timeStamp && timeStamp <= $0.timeEnd })
    }
}
