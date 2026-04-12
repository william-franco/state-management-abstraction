import 'package:flutter/material.dart';

sealed class StateValue<T> {
  const StateValue();

  R when<R>({
    required R Function() loading,
    required R Function(Object error) error,
    required R Function(T data) data,
  });
}

class StateLoading<T> extends StateValue<T> {
  const StateLoading();

  @override
  R when<R>({
    required R Function() loading,
    required R Function(Object error) error,
    required R Function(T data) data,
  }) => loading();
}

class StateError<T> extends StateValue<T> {
  final Object errorValue;
  const StateError(this.errorValue);

  @override
  R when<R>({
    required R Function() loading,
    required R Function(Object error) error,
    required R Function(T data) data,
  }) => error(errorValue);
}

class StateData<T> extends StateValue<T> {
  final T dataValue;
  const StateData(this.dataValue);

  @override
  R when<R>({
    required R Function() loading,
    required R Function(Object error) error,
    required R Function(T data) data,
  }) => data(dataValue);
}

abstract class AsyncStateManagement<T> extends ChangeNotifier {
  late StateValue<T> _state;

  AsyncStateManagement() {
    _state = build();
  }

  @protected
  StateValue<T> build();

  StateValue<T> get state => _state;

  @protected
  void emitState(StateValue<T> newState) {
    if (identical(_state, newState)) return;
    _state = newState;
    notifyListeners();
  }

  @protected
  void setLoading() => emitState(StateLoading<T>());

  @protected
  void setError(Object error) => emitState(StateError<T>(error));

  @protected
  void setData(T data) => emitState(StateData<T>(data));

  @override
  String toString() => 'AsyncStateManagement<$T>(state: $_state)';
}

typedef AsyncStateBuilder<S> =
    Widget Function(BuildContext context, StateValue<S> state);

class AsyncStateBuilderWidget<V extends AsyncStateManagement<S>, S>
    extends StatelessWidget {
  final V viewModel;
  final AsyncStateBuilder<S> builder;
  final Widget? child;

  const AsyncStateBuilderWidget({
    super.key,
    required this.viewModel,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      child: child,
      builder: (context, child) {
        return builder(context, viewModel.state);
      },
    );
  }
}

typedef AsyncStateListener<S> =
    void Function(BuildContext context, StateValue<S> state);

class AsyncStateListenerWidget<V extends AsyncStateManagement<S>, S>
    extends StatefulWidget {
  final V viewModel;
  final AsyncStateListener<S> listener;
  final Widget child;

  const AsyncStateListenerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.child,
  });

  @override
  State<AsyncStateListenerWidget<V, S>> createState() =>
      _AsyncStateListenerWidgetState<V, S>();
}

class _AsyncStateListenerWidgetState<V extends AsyncStateManagement<S>, S>
    extends State<AsyncStateListenerWidget<V, S>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(AsyncStateListenerWidget<V, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onStateChanged);
      widget.viewModel.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => widget.listener(context, widget.viewModel.state);

  @override
  Widget build(BuildContext context) => widget.child;
}

class AsyncStateConsumerWidget<V extends AsyncStateManagement<S>, S>
    extends StatefulWidget {
  final V viewModel;
  final AsyncStateListener<S> listener;
  final AsyncStateBuilder<S> builder;
  final Widget? child;

  const AsyncStateConsumerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.builder,
    this.child,
  });

  @override
  State<AsyncStateConsumerWidget<V, S>> createState() =>
      _AsyncStateConsumerWidgetState<V, S>();
}

class _AsyncStateConsumerWidgetState<V extends AsyncStateManagement<S>, S>
    extends State<AsyncStateConsumerWidget<V, S>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(AsyncStateConsumerWidget<V, S> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onStateChanged);
      widget.viewModel.addListener(_onStateChanged);
    }
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => widget.listener(context, widget.viewModel.state);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      child: widget.child,
      builder: (context, child) {
        return widget.builder(context, widget.viewModel.state);
      },
    );
  }
}
