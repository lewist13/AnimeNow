////  SubtitleTextView.swift
//  Anime Now!
//
//  Created by ErrorErrorError on 10/30/22.
//  
//

import SwiftUI
import SwiftWebVTT

struct SubtitleTextView: View {
    @StateObject private var viewModel = ViewModel()

    var url: URL? = nil
    var progress: Double = .zero
    var duration: Double = .zero

    var body: some View {
        Group {
            if let text = viewModel.vtt.value?.bounds(for: duration * progress)?.text {
                VStack(alignment: .center) {
                    Spacer()

                    AttributedText(
                        text: text,
                        options: .defaultStroke
                    )

                    Spacer(minLength: 24)
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
