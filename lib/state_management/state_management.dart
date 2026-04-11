import 'package:flutter/material.dart';

abstract class StateManagement<T> extends ChangeNotifier {
  late T _state;

  StateManagement() {
    _state = build();
  }

  /// Define o estado inicial da subclasse.
  /// Espelha o contrato do Notifier.build() do Riverpod.
  @protected
  T build();

  /// Getter público — leitura somente.
  T get state => _state;

  /// Única forma de emitir um novo estado.
  /// Compara referências antes de notificar.
  @protected
  void emitState(T newState) {
    if (identical(_state, newState)) return;
    _state = newState;
    notifyListeners();
  }

  @override
  String toString() => 'StateManagement<$T>(state: $_state)';
}

@protected
typedef StateBuilder<S> = Widget Function(BuildContext context, S state);

class StateBuilderWidget<V extends StateManagement<S>, S>
    extends StatelessWidget {
  final V viewModel;
  final StateBuilder<S> builder;
  final Widget? child;

  const StateBuilderWidget({
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

@protected
typedef StateListener<S> = void Function(BuildContext context, S state);

class StateListenerWidget<V extends StateManagement<S>, S>
    extends StatefulWidget {
  final V viewModel;
  final StateListener<S> listener;
  final Widget child;

  const StateListenerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.child,
  });

  @override
  State<StateListenerWidget<V, S>> createState() =>
      _StateListenerWidgetState<V, S>();
}

class _StateListenerWidgetState<V extends StateManagement<S>, S>
    extends State<StateListenerWidget<V, S>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(StateListenerWidget<V, S> oldWidget) {
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

class StateConsumerWidget<V extends StateManagement<S>, S>
    extends StatefulWidget {
  final V viewModel;
  final StateListener<S> listener;
  final StateBuilder<S> builder;
  final Widget? child;

  const StateConsumerWidget({
    super.key,
    required this.viewModel,
    required this.listener,
    required this.builder,
    this.child,
  });

  @override
  State<StateConsumerWidget<V, S>> createState() =>
      _StateConsumerWidgetState<V, S>();
}

class _StateConsumerWidgetState<V extends StateManagement<S>, S>
    extends State<StateConsumerWidget<V, S>> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onStateChanged);
  }

  @override
  void didUpdateWidget(StateConsumerWidget<V, S> oldWidget) {
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
