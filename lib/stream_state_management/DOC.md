# StreamStateManagement

Biblioteca para gerenciamento de estado para Flutter baseada em `Stream`, sem dependências externas. Oferece três widgets principais para cobrir os padrões mais comuns: **builder**, **listener** e **consumer**.

---

## Sumário

- [StreamStateManagement](#streamstatemanagement-1)
- [Typedefs](#typedefs)
- [StreamBuilderWidget](#streambuilderwidget)
- [StreamListenerWidget](#streamlistenerwidget)
- [StreamConsumerWidget](#streamconsumerwidget)
- [Exemplo completo](#exemplo-completo)

---

## StreamStateManagement

Classe abstrata base para ViewModels baseados em `Stream`. Equivalente ao `StateManagement` porém expõe o estado via `Stream`, permitindo múltiplos listeners independentes sem acoplamento ao `ChangeNotifier`. Internamente usa um `StreamController.broadcast`.

```dart
abstract class StreamStateManagement<T>
```

### Propriedades

| Nome     | Tipo       | Descrição                                          |
|----------|------------|----------------------------------------------------|
| `state`  | `T`        | Estado atual (somente leitura)                     |
| `stream` | `Stream<T>` | Stream de estados com suporte a múltiplos listeners |

### Métodos

| Nome                    | Descrição                                                                                                         |
|-------------------------|-------------------------------------------------------------------------------------------------------------------|
| `build()`               | Define o estado inicial da subclasse. Obrigatório — chamado automaticamente no construtor.                        |
| `emitState(T newState)` | Atualiza o estado e adiciona o novo valor ao stream. Ignorado se idêntico ao atual ou se o controller estiver fechado. |
| `dispose()`             | Fecha o `StreamController`. Deve ser chamado no `dispose` da View.                                               |

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
abstract interface class CounterViewModel
    extends StreamStateManagement<CounterModel> {
  void increment();
  void decrement();
}

// 3. Crie a implementação
class CounterViewModelImpl extends StreamStateManagement<CounterModel>
    implements CounterViewModel {

  @override
  CounterModel build() => const CounterModel();

  @override
  void increment() => emitState(state.copyWith(count: state.count + 1));

  @override
  void decrement() => emitState(state.copyWith(count: state.count - 1));
}
```

> **Nota:** o estado inicial é definido em `build()`, sem necessidade de `super(initialState)`.
> O `StreamController.broadcast` garante que múltiplos widgets possam escutar o mesmo stream
> simultaneamente sem lançar erros.

---

## StreamBuilderWidget

Reconstrói a UI automaticamente a cada novo estado emitido pelo `stream` do ViewModel. Internamente utiliza o `StreamBuilder` nativo do Flutter.

O `initialData` é obtido de `viewModel.state`, garantindo que a UI nunca renderize um frame vazio enquanto o primeiro evento ainda não chegou.

```dart
class StreamBuilderWidget<V extends StreamStateManagement<S>, S>
    extends StatelessWidget
```

### Parâmetros

| Nome        | Tipo                      | Obrigatório | Descrição                                     |
|-------------|---------------------------|-------------|-----------------------------------------------|
| `viewModel` | `V`                       | ✅           | Instância do ViewModel                        |
| `builder`   | `StreamStateBuilder<S>`   | ✅           | Função que reconstrói a UI com o estado atual |

### Uso

```dart
StreamBuilderWidget<CounterViewModel, CounterModel>(
  viewModel: _counterViewModel,
  builder: (context, state) {
    return Text(
      '${state.count}',
      style: const TextStyle(fontSize: 48),
    );
  },
);
```

---

## StreamListenerWidget

Executa um callback a cada novo estado emitido, **sem reconstruir a UI**. Ideal para efeitos colaterais como navegação, snackbars e diálogos. Cancela a `StreamSubscription` automaticamente no `dispose`.

```dart
class StreamListenerWidget<V extends StreamStateManagement<S>, S>
    extends StatefulWidget
```

### Parâmetros

| Nome        | Tipo                      | Obrigatório | Descrição                                   |
|-------------|---------------------------|-------------|---------------------------------------------|
| `viewModel` | `V`                       | ✅           | Instância do ViewModel                      |
| `listener`  | `StreamStateListener<S>`  | ✅           | Callback executado a cada mudança de estado |
| `child`     | `Widget`                  | ✅           | Widget filho renderizado normalmente        |

### Uso

```dart
StreamListenerWidget<CounterViewModel, CounterModel>(
  viewModel: _counterViewModel,
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
StreamListenerWidget<AuthViewModel, AuthModel>(
  viewModel: _authViewModel,
  listener: (context, state) {
    if (state.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  },
  child: const LoginScreen(),
);
```

---

## StreamConsumerWidget

Combina `StreamBuilderWidget` + `StreamListenerWidget` em um único widget: reconstrói a UI **e** executa efeitos colaterais na mesma emissão de estado.

```dart
class StreamConsumerWidget<V extends StreamStateManagement<S>, S>
    extends StatefulWidget
```

### Parâmetros

| Nome        | Tipo                      | Obrigatório | Descrição                        |
|-------------|---------------------------|-------------|----------------------------------|
| `viewModel` | `V`                       | ✅           | Instância do ViewModel           |
| `listener`  | `StreamStateListener<S>`  | ✅           | Callback para efeitos colaterais |
| `builder`   | `StreamStateBuilder<S>`   | ✅           | Função que reconstrói a UI       |

### Uso

```dart
StreamConsumerWidget<CounterViewModel, CounterModel>(
  viewModel: _counterViewModel,
  listener: (context, state) {
    if (state.count == 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chegou a 10!')),
      );
    }
  },
  builder: (context, state) {
    return Text('${state.count}');
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
abstract interface class CounterViewModel
    extends StreamStateManagement<CounterModel> {
  void increment();
  void decrement();
}

// implementação
class CounterViewModelImpl extends StreamStateManagement<CounterModel>
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
      body: StreamConsumerWidget<CounterViewModel, CounterModel>(
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
