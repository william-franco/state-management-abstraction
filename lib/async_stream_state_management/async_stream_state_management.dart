import 'dart:async';

import 'package:flutter/material.dart';

sealed class StateValue<T> {
  const StateValue();

  R when<R>({
    required R Function() loading,
    required R Function(Object error) error,
    required R Function(T data) data,
  });
}

final class StateLoading<T> extends StateValue<T> {
  const StateLoading();

  @override
  R when<R>({
    required R Function() loading,
    required R Function(Object error) error,
    required R Function(T data) data,
  }) => loading();
}

final class StateError<T> extends StateValue<T> {
  final Object errorValue;
  const StateError(this.errorValue);

  @override
  R when<R>({
    required R Function() loading,
    required R Function(Object error) error,
    required R Function(T data) data,
  }) => error(errorValue);
}

final class StateData<T> extends StateValue<T> {
  final T dataValue;
  const StateData(this.dataValue);

  @override
  R when<R>({
    required R Function() loading,
    required R Function(Object error) error,
    required R Function(T data) data,
  }) => data(dataValue);
}

abstract class AsyncStreamStateManagement<T> {
  late StateValue<T> _state;
  late final StreamController<StateValue<T>> _controller;

  AsyncStreamStateManagement() {
    _controller = StreamController<StateValue<T>>.broadcast();
    _state = build();
  }

  @protected
  StateValue<T> build();

  StateValue<T> get state => _state;

  Stream<StateValue<T>> get stream => _controller.stream;

  @protected
  void emitState(StateValue<T> newState) {
    if (identical(_state, newState)) return;
    if (_controller.isClosed) return;
    _state = newState;
    _controller.add(_state);
  }

  @protected
  void setLoading() => emitState(StateLoading<T>());

  @protected
  void setError(Object error) => emitState(StateError<T>(error));

  @protected
  void setData(T data) => emitState(StateData<T>(data));

  @mustCallSuper
  void dispose() {
    _controller.close();
  }

  @override
  String toString() => 'AsyncStreamStateManagement<$T>(state: $_state)';
}

typedef AsyncStreamStateBuilder<T> =
    Widget Function(BuildContext context, StateValue<T> state);

class AsyncStreamBuilderWidget<V extends AsyncStreamStateManagement<T>, T>
    extends StatelessWidget {
  final V viewModel;
  final AsyncStreamStateBuilder<T> builder;

  const AsyncStreamBuilderWidget({
    super.key,
    required this.viewModel,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StateValue<T>>(
      initialData: viewModel.state,
      stream: viewModel.stream,
      builder: (context, snapshot) => builder(context, snapshot.requireData),
    );
  }
}

typedef AsyncStreamStateListener<T> =
    void Function(BuildContext context, StateValue<T> state);

class AsyncStreamListenerWidget<V extends AsyncStreamStateManagement<T>, T>
    extends StatefulWidget {
  final V viewModel;
  final AsyncStreamStateListener<T> listener;
  final Widget child;

  const AsyncStreamListenerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.child,
  });

  @override
  State<AsyncStreamListenerWidget<V, T>> createState() =>
      _AsyncStreamListenerWidgetState<V, T>();
}

class _AsyncStreamListenerWidgetState<
  V extends AsyncStreamStateManagement<T>,
  T
>
    extends State<AsyncStreamListenerWidget<V, T>> {
  late final StreamSubscription<StateValue<T>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.viewModel.stream.listen((state) {
      if (mounted) widget.listener(context, state);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AsyncStreamConsumerWidget<V extends AsyncStreamStateManagement<T>, T>
    extends StatefulWidget {
  final V viewModel;
  final AsyncStreamStateListener<T> listener;
  final AsyncStreamStateBuilder<T> builder;

  const AsyncStreamConsumerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.builder,
  });

  @override
  State<AsyncStreamConsumerWidget<V, T>> createState() =>
      _AsyncStreamConsumerWidgetState<V, T>();
}

class _AsyncStreamConsumerWidgetState<
  V extends AsyncStreamStateManagement<T>,
  T
>
    extends State<AsyncStreamConsumerWidget<V, T>> {
  late final StreamSubscription<StateValue<T>> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.viewModel.stream.listen((state) {
      if (mounted) widget.listener(context, state);
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AsyncStreamBuilderWidget<V, T>(
      viewModel: widget.viewModel,
      builder: widget.builder,
    );
  }
}
