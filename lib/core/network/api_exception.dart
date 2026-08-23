/// Base type for every failure that can bubble up from the network
/// layer into a repository/provider and ultimately into a screen's
/// error state.
sealed class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the relevant backend base URL has not been supplied
/// via `--dart-define` yet. Lets the UI show a clear "not connected
/// yet" empty state instead of a generic error while the real API
/// is still being wired up.
class ApiNotConfiguredException extends ApiException {
  const ApiNotConfiguredException()
      : super('This feature is not connected to a live service yet.');
}

/// Thrown for any connectivity failure (timeout, socket error, no
/// internet, etc).
class ApiNetworkException extends ApiException {
  const ApiNetworkException([
    super.message = 'Please check your internet connection and try again.',
  ]);
}

/// Thrown when the server responds with a non-2xx status code.
class ApiServerException extends ApiException {
  final int statusCode;

  const ApiServerException(this.statusCode, [String? message])
      : super(message ?? 'Server error ($statusCode). Please try again.');
}

/// Thrown when the response body could not be parsed into the
/// expected model shape.
class ApiParsingException extends ApiException {
  const ApiParsingException([
    super.message = 'Received an unexpected response. Please try again.',
  ]);
}
