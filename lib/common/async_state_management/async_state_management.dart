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
  StateValue<T> _state;

  AsyncStateManagement(StateValue<T> initialState) : _state = initialState;

  StateValue<T> get state => _state;

  @protected
  void emitState(StateValue<T> newState) {
    if (identical(_state, newState)) return;
    _state = newState;
    debugPrint('AsyncStateManagement<$T> -> $newState');
    notifyListeners();
  }

  @override
  String toString() => 'AsyncStateManagement<$T>(state: $_state)';

  @protected
  void setLoading() => emitState(const StateLoading());

  @protected
  void setError(Object error) => emitState(StateError<T>(error));

  @protected
  void setData(T data) => emitState(StateData<T>(data));
}

@protected
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
