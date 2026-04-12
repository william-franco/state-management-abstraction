# AsyncStreamStateManagement

Extensão da biblioteca `StreamStateManagement` para operações assíncronas. Encapsula o estado em `StateValue<T>`, um tipo sealed com três variantes — **loading**, **error** e **data** — exposto via `Stream` com suporte a múltiplos listeners simultâneos.

---

## Sumário

- [StateValue](#statevalue)
- [AsyncStreamStateManagement](#asyncstreamstatemanagement-1)
- [Typedefs](#typedefs)
- [AsyncStreamBuilderWidget](#asyncstreambuilderwidget)
- [AsyncStreamListenerWidget](#asyncstreamlistenerwidget)
- [AsyncStreamConsumerWidget](#asyncstreamconsumerwidget)
- [Exemplo completo](#exemplo-completo)

---

## StateValue

Tipo sealed que representa os três estados possíveis de uma operação assíncrona.

```dart
sealed class StateValue<T>
```

### Variantes

| Classe         | Descrição                        | Propriedade          |
|----------------|----------------------------------|----------------------|
| `StateLoading` | Operação em andamento            | —                    |
| `StateError`   | Operação concluída com falha     | `errorValue: Object` |
| `StateData`    | Operação concluída com sucesso   | `dataValue: T`       |

### Método `when`

Permite tratar cada variante de forma exaustiva, sem `if`/`switch` manual:

```dart
state.when(
  loading: () => const CircularProgressIndicator(),
  error: (error) => Text('Erro: $error'),
  data: (data) => Text('Produto: ${data.name}'),
);
```

---

## AsyncStreamStateManagement

Classe abstrata base para ViewModels com operações assíncronas baseados em `Stream`. Encapsula o estado em `StateValue<T>` e o expõe via `stream`, mantendo os atalhos `setLoading`, `setError` e `setData`. Internamente usa um `StreamController.broadcast`.

```dart
abstract class AsyncStreamStateManagement<T>
```

### Propriedades

| Nome     | Tipo                    | Descrição                                           |
|----------|-------------------------|-----------------------------------------------------|
| `state`  | `StateValue<T>`         | Estado atual (somente leitura)                      |
| `stream` | `Stream<StateValue<T>>` | Stream de estados com suporte a múltiplos listeners |

### Métodos

| Nome                           | Descrição                                                                                                              |
|--------------------------------|------------------------------------------------------------------------------------------------------------------------|
| `build()`                      | Define o estado inicial da subclasse. Obrigatório — chamado automaticamente no construtor.                             |
| `emitState(StateValue<T>)`     | Atualiza o estado e adiciona o novo valor ao stream. Ignorado se idêntico ao atual ou se o controller estiver fechado. |
| `setLoading()`                 | Atalho para `emitState(StateLoading())`.                                                                               |
| `setError(Object error)`       | Atalho para `emitState(StateError(error))`.                                                                            |
| `setData(T data)`              | Atalho para `emitState(StateData(data))`.                                                                              |
| `dispose()`                    | Fecha o `StreamController`. Deve ser chamado no `dispose` da View.                                                    |

### Uso

```dart
// 1. Defina o modelo
class ProductModel {
  final String name;
  const ProductModel({this.name = ''});

  ProductModel copyWith({String? name}) {
    return ProductModel(name: name ?? this.name);
  }
}

// 2. Defina a interface
abstract interface class ProductViewModel
    extends AsyncStreamStateManagement<ProductModel> {
  Future<void> fetchProduct();
}

// 3. Crie a implementação
class ProductViewModelImpl extends AsyncStreamStateManagement<ProductModel>
    implements ProductViewModel {

  final ProductRepository productRepository;

  ProductViewModelImpl({required this.productRepository});

  @override
  StateValue<ProductModel> build() => const StateLoading();

  @override
  Future<void> fetchProduct() async {
    setLoading();
    final result = await productRepository.findOne();
    result.fold(
      onSuccess: (data) => setData(data),
      onError: (error) => setError(error),
    );
  }
}
```

> **Nota:** o estado inicial é definido em `build()`, sem necessidade de `super(initialState)`.
> O tipo de retorno é `StateValue<T>`, permitindo iniciar como `StateLoading()`,
> `StateData(value)` ou `StateError(error)` conforme a necessidade.

---

## Typedefs

Aliases de função para os callbacks dos widgets, reduzindo a verbosidade nas assinaturas.

```dart
typedef AsyncStreamStateBuilder<T>  = Widget Function(BuildContext context, StateValue<T> state);
typedef AsyncStreamStateListener<T> = void   Function(BuildContext context, StateValue<T> state);
```

---

## AsyncStreamBuilderWidget

Reconstrói a UI automaticamente a cada novo estado emitido pelo `stream` do ViewModel. Internamente utiliza o `StreamBuilder` nativo do Flutter.

O `initialData` é obtido de `viewModel.state`, garantindo que a UI nunca renderize um frame vazio enquanto o primeiro evento ainda não chegou.

```dart
class AsyncStreamBuilderWidget<V extends AsyncStreamStateManagement<T>, T>
    extends StatelessWidget
```

### Parâmetros

| Nome        | Tipo                           | Obrigatório | Descrição                                     |
|-------------|--------------------------------|-------------|-----------------------------------------------|
| `viewModel` | `V`                            | ✅           | Instância do ViewModel                        |
| `builder`   | `AsyncStreamStateBuilder<T>`   | ✅           | Função que reconstrói a UI com o estado atual |

### Uso

```dart
AsyncStreamBuilderWidget<ProductViewModel, ProductModel>(
  viewModel: _productViewModel,
  builder: (context, state) {
    return state.when(
      loading: () => const CircularProgressIndicator(),
      error: (error) => Text('Erro: $error'),
      data: (product) => Text('Produto: ${product.name}'),
    );
  },
);
```

---

## AsyncStreamListenerWidget

Executa um callback a cada novo estado emitido, **sem reconstruir a UI**. Ideal para efeitos colaterais como navegação, snackbars e diálogos. Cancela a `StreamSubscription` automaticamente no `dispose`.

```dart
class AsyncStreamListenerWidget<V extends AsyncStreamStateManagement<T>, T>
    extends StatefulWidget
```

### Parâmetros

| Nome        | Tipo                            | Obrigatório | Descrição                                   |
|-------------|---------------------------------|-------------|---------------------------------------------|
| `viewModel` | `V`                             | ✅           | Instância do ViewModel                      |
| `listener`  | `AsyncStreamStateListener<T>`   | ✅           | Callback executado a cada mudança de estado |
| `child`     | `Widget`                        | ✅           | Widget filho renderizado normalmente        |

### Uso

```dart
AsyncStreamListenerWidget<ProductViewModel, ProductModel>(
  viewModel: _productViewModel,
  listener: (context, state) {
    if (state is StateError<ProductModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${state.errorValue}')),
      );
    }
  },
  child: const ProductScreen(),
);
```

---

## AsyncStreamConsumerWidget

Combina `AsyncStreamBuilderWidget` + `AsyncStreamListenerWidget` em um único widget: reconstrói a UI **e** executa efeitos colaterais na mesma emissão de estado.

```dart
class AsyncStreamConsumerWidget<V extends AsyncStreamStateManagement<T>, T>
    extends StatefulWidget
```

### Parâmetros

| Nome        | Tipo                           | Obrigatório | Descrição                        |
|-------------|--------------------------------|-------------|----------------------------------|
| `viewModel` | `V`                            | ✅           | Instância do ViewModel           |
| `listener`  | `AsyncStreamStateListener<T>`  | ✅           | Callback para efeitos colaterais |
| `builder`   | `AsyncStreamStateBuilder<T>`   | ✅           | Função que reconstrói a UI       |

### Uso

```dart
AsyncStreamConsumerWidget<ProductViewModel, ProductModel>(
  viewModel: _productViewModel,
  listener: (context, state) {
    if (state is StateError<ProductModel>) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${state.errorValue}')),
      );
    }
  },
  builder: (context, state) {
    return state.when(
      loading: () => const CircularProgressIndicator(),
      error: (error) => Text('Erro: $error'),
      data: (product) => Text('Produto: ${product.name}'),
    );
  },
);
```

---

## Exemplo completo

```dart
// model
class ProductModel {
  final String name;
  const ProductModel({this.name = ''});

  ProductModel copyWith({String? name}) {
    return ProductModel(name: name ?? this.name);
  }
}

// interface
abstract interface class ProductViewModel
    extends AsyncStreamStateManagement<ProductModel> {
  Future<void> fetchProduct();
}

// implementação
class ProductViewModelImpl extends AsyncStreamStateManagement<ProductModel>
    implements ProductViewModel {

  final ProductRepository productRepository;

  ProductViewModelImpl({required this.productRepository});

  @override
  StateValue<ProductModel> build() => const StateLoading();

  @override
  Future<void> fetchProduct() async {
    setLoading();
    final result = await productRepository.findOne();
    result.fold(
      onSuccess: (data) => setData(data),
      onError: (error) => setError(error),
    );
  }
}

// view
class ProductView extends StatefulWidget {
  const ProductView({super.key});

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  late final ProductRepository _productRepository;
  late final ProductViewModel _productViewModel;

  @override
  void initState() {
    super.initState();
    _productRepository = ProductRepositoryImpl();
    _productViewModel = ProductViewModelImpl(
      productRepository: _productRepository,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _productViewModel.fetchProduct();
    });
  }

  @override
  void dispose() {
    _productViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produto')),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _productViewModel.fetchProduct,
          child: AsyncStreamConsumerWidget<ProductViewModel, ProductModel>(
            viewModel: _productViewModel,
            listener: (context, state) {
              if (state is StateError<ProductModel>) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: ${state.errorValue}')),
                );
              }
            },
            builder: (context, state) {
              return state.when(
                loading: () => const CircularProgressIndicator(),
                error: (error) => Text('Erro: $error'),
                data: (product) => Text('Produto: ${product.name}'),
              );
            },
          ),
        ),
      ),
    );
  }
}
```
