# StateManagement

Biblioteca para gerenciamento de estado para Flutter baseada em `ChangeNotifier`, sem dependências externas. Oferece três widgets principais para cobrir os padrões mais comuns: **builder**, **listener** e **consumer**.

---

## Sumário

- [StateManagement](#statemanagement-1)
- [StateBuilderWidget](#statebuilderwidget)
- [StateListenerWidget](#statelistenerwidget)
- [StateConsumerWidget](#stateconsumerwidget)
- [Exemplo completo](#exemplo-completo)

---

## StateManagement

Classe abstrata base para ViewModels. Estende `ChangeNotifier` e encapsula um único valor de estado do tipo `T`.

```dart
abstract class StateManagement<T> extends ChangeNotifier
```

### Propriedades

| Nome    | Tipo | Descrição                      |
|---------|------|--------------------------------|
| `state` | `T`  | Estado atual (somente leitura) |

### Métodos

| Nome                    | Descrição                                                                                   |
|-------------------------|---------------------------------------------------------------------------------------------|
| `build()`               | Define o estado inicial da subclasse. Obrigatório — chamado automaticamente no construtor.  |
| `emitState(T newState)` | Atualiza o estado e notifica os listeners. Ignorado se o novo estado for idêntico ao atual. |

### Uso

```dart
// 1. Defina o modelo
class CounterModel {
  final int count;
  const CounterModel({this.count = 0});

  CounterModel copyWith({int? count}) {
    return CounterModel(count: count ?? this.count);
  }
}

// 2. Defina a interface
abstract interface class CounterViewModel extends StateManagement<CounterModel> {
  void increment();
  void decrement();
}

// 3. Crie a implementação
class CounterViewModelImpl extends StateManagement<CounterModel>
    implements CounterViewModel {

  @override
  CounterModel build() => const CounterModel();

  @override
  void increment() => emitState(state.copyWith(count: state.count + 1));

  @override
  void decrement() => emitState(state.copyWith(count: state.count - 1));
}
```

> **Nota:** o estado inicial é definido em `build()`, não mais via `super(initialState)` no construtor.
> Isso espelha o contrato do `Notifier.build()` do Riverpod, mantendo a ergonomia familiar.

---

## StateBuilderWidget

Reconstrói a UI automaticamente sempre que o estado do ViewModel muda. Internamente utiliza `ListenableBuilder`.

```dart
class StateBuilderWidget<V extends StateManagement<S>, S> extends StatelessWidget
```

### Parâmetros

| Nome        | Tipo                              | Obrigatório | Descrição                                                     |
|-------------|-----------------------------------|-------------|---------------------------------------------------------------|
| `viewModel` | `V`                               | ✅           | Instância do ViewModel                                        |
| `builder`   | `Widget Function(BuildContext, S)` | ✅           | Função que reconstrói a UI com o estado atual                 |
| `child`     | `Widget?`                         | ❌           | Widget estático que não depende do estado (otimização)        |

### Uso

```dart
StateBuilderWidget<CounterViewModel, CounterModel>(
  viewModel: counterViewModel,
  builder: (context, state) {
    return Text(
      'Count: ${state.count}',
      style: const TextStyle(fontSize: 24),
    );
  },
);
```

### Com `child` otimizado

O parâmetro `child` é repassado ao `builder` sem ser reconstruído a cada mudança de estado:

```dart
StateBuilderWidget<CounterViewModel, CounterModel>(
  viewModel: counterViewModel,
  child: const Icon(Icons.add),
  builder: (context, state) {
    return Column(
      children: [
        Text('Count: ${state.count}'),
        // child é recebido aqui sem reconstrução
      ],
    );
  },
);
```

---

## StateListenerWidget

Executa um callback toda vez que o estado muda, **sem reconstruir a UI**. Ideal para efeitos colaterais como navegação, snackbars e diálogos.

```dart
class StateListenerWidget<V extends StateManagement<S>, S> extends StatefulWidget
```

### Parâmetros

| Nome        | Tipo                                   | Obrigatório | Descrição                                   |
|-------------|----------------------------------------|-------------|---------------------------------------------|
| `viewModel` | `V`                                    | ✅           | Instância do ViewModel                      |
| `listener`  | `void Function(BuildContext, S)`       | ✅           | Callback executado a cada mudança de estado |
| `child`     | `Widget`                               | ✅           | Widget filho renderizado normalmente        |

### Uso

```dart
StateListenerWidget<CounterViewModel, CounterModel>(
  viewModel: counterViewModel,
  listener: (context, state) {
    if (state.count == 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chegou a 10!')),
      );
    }
  },
  child: const CounterScreen(),
);
```

### Navegação no listener

```dart
StateListenerWidget<AuthViewModel, AuthModel>(
  viewModel: authViewModel,
  listener: (context, state) {
    if (state.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  },
  child: const LoginScreen(),
);
```

---

## StateConsumerWidget

Combina `StateBuilderWidget` + `StateListenerWidget` em um único widget: reconstrói a UI **e** executa efeitos colaterais na mesma mudança de estado.

```dart
class StateConsumerWidget<V extends StateManagement<S>, S> extends StatefulWidget
```

### Parâmetros

| Nome        | Tipo                               | Obrigatório | Descrição                          |
|-------------|------------------------------------|-------------|------------------------------------|
| `viewModel` | `V`                                | ✅           | Instância do ViewModel             |
| `listener`  | `void Function(BuildContext, S)`   | ✅           | Callback para efeitos colaterais   |
| `builder`   | `Widget Function(BuildContext, S)` | ✅           | Função que reconstrói a UI         |
| `child`     | `Widget?`                          | ❌           | Widget estático (otimização)       |

### Uso

```dart
StateConsumerWidget<CounterViewModel, CounterModel>(
  viewModel: counterViewModel,
  listener: (context, state) {
    if (state.count == 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chegou a 10!')),
      );
    }
  },
  builder: (context, state) {
    return Text('Count: ${state.count}');
  },
);
```

---

## Exemplo completo

```dart
// model
class CounterModel {
  final int count;
  const CounterModel({this.count = 0});

  CounterModel copyWith({int? count}) {
    return CounterModel(count: count ?? this.count);
  }
}

// interface
abstract interface class CounterViewModel extends StateManagement<CounterModel> {
  void increment();
  void decrement();
}

// implementação
class CounterViewModelImpl extends StateManagement<CounterModel>
    implements CounterViewModel {

  @override
  CounterModel build() => const CounterModel();

  @override
  void increment() => emitState(state.copyWith(count: state.count + 1));

  @override
  void decrement() => emitState(state.copyWith(count: state.count - 1));
}

// view
class CounterView extends StatefulWidget {
  const CounterView({super.key});

  @override
  State<CounterView> createState() => _CounterViewState();
}

class _CounterViewState extends State<CounterView> {
  late final CounterViewModel _counterViewModel;

  @override
  void initState() {
    super.initState();
    _counterViewModel = CounterViewModelImpl();
  }

  @override
  void dispose() {
    _counterViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: StateConsumerWidget<CounterViewModel, CounterModel>(
        viewModel: _counterViewModel,
        listener: (context, state) {
          if (state.count == 10) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chegou a 10!')),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: Text(
              '${state.count}',
              style: const TextStyle(fontSize: 48),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: _counterViewModel.increment,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: _counterViewModel.decrement,
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
```
