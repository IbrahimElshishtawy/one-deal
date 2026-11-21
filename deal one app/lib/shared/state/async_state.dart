import 'package:market_space/core/errors/app_failure.dart';

sealed class AsyncState<T> {
  const AsyncState();

  const factory AsyncState.initial() = AsyncInitial<T>;
  const factory AsyncState.loading() = AsyncLoading<T>;
  const factory AsyncState.success(T data) = AsyncSuccess<T>;
  const factory AsyncState.failure(AppFailure failure) = AsyncFailure<T>;

  R when<R>({
    required R Function() onInitial,
    required R Function() onLoading,
    required R Function(T data) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    return switch (this) {
      AsyncInitial<T>() => onInitial(),
      AsyncLoading<T>() => onLoading(),
      AsyncSuccess<T>(:final data) => onSuccess(data),
      AsyncFailure<T>(:final failure) => onFailure(failure),
    };
  }

  bool get isInitial => this is AsyncInitial<T>;
  bool get isLoading => this is AsyncLoading<T>;
  bool get isSuccess => this is AsyncSuccess<T>;
  bool get isFailure => this is AsyncFailure<T>;

  T? get dataOrNull {
    if (this is AsyncSuccess<T>) {
      return (this as AsyncSuccess<T>).data;
    }
    return null;
  }
}

class AsyncInitial<T> extends AsyncState<T> {
  const AsyncInitial();
}

class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

class AsyncSuccess<T> extends AsyncState<T> {
  final T data;
  const AsyncSuccess(this.data);
}

class AsyncFailure<T> extends AsyncState<T> {
  final AppFailure failure;
  const AsyncFailure(this.failure);
}
