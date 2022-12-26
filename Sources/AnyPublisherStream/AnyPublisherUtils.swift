import Combine

extension Publisher where Failure == Never {
    public var stream: AsyncStream<Output> {
        .init { continuation in
            let cancellable = self
                .eraseToAnyPublisher()
                .sink { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let never):
                        continuation.yield(with: .failure(never))
                    }
                } receiveValue: { output in
                    continuation.yield(output)
                }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}

extension Publisher where Failure == Error {
    public var throwingStream: AsyncThrowingStream<Output, Failure> {
        .init { continuation in
            let cancellable = self
                .eraseToAnyPublisher()
                .sink { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                } receiveValue: { output in
                    continuation.yield(output)
                }

            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
