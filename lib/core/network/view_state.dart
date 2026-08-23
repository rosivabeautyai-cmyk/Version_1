enum ViewStatus { initial, loading, loadingMore, success, empty, error }

/// Lightweight state holder for screens driven by a remote API call
/// (list screens, detail screens, chat, etc). Keeps providers small
/// and gives every screen a single, consistent switch to branch on
/// for its loading / empty / error / success UI.
class ViewState<T> {
  final ViewStatus status;
  final T? data;
  final String? errorMessage;
  final bool hasMore;

  const ViewState({
    this.status = ViewStatus.initial,
    this.data,
    this.errorMessage,
    this.hasMore = false,
  });

  bool get isLoading => status == ViewStatus.loading;
  bool get isLoadingMore => status == ViewStatus.loadingMore;
  bool get isError => status == ViewStatus.error;
  bool get isEmpty => status == ViewStatus.empty;
  bool get isSuccess => status == ViewStatus.success;

  ViewState<T> copyWith({
    ViewStatus? status,
    T? data,
    String? errorMessage,
    bool? hasMore,
  }) {
    return ViewState<T>(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
