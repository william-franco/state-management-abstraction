# AsyncStateManagement

Extensão da biblioteca `StateManagement` para operações assíncronas. Encapsula o estado em `StateValue<T>`, um tipo sealed com três variantes — **loading**, **error** e **data** — eliminando a necessidade de gerenciar flags booleanas ou estados nulos manualmente.

---

## Sumário

- [StateValue](#statevalue)
- [AsyncStateManagement](#asyncstatemanagement-1)
- [Exemplo completo](#exemplo-completo)

---

## StateValue

Tipo sealed que representa os três estados possíveis de uma operação assíncrona.

```dart
sealed class StateValue<T>
```

### Variantes

| Classe         | Descrição                                          | Propriedade          |
|----------------|----------------------------------------------------|----------------------|
| `StateLoading` | Operação em andamento                              | —                    |
| `StateError`   | Operação concluída com falha                       | `errorValue: Object` |
| `StateData`    | Operação concluída com sucesso                     | `dataValue: T`       |

### Método `when`

Permite tratar cada variante de forma exaustiva, sem `if`/`switch` manual:

```dart
state.when(
  loading: () { /* mostra spinner */ },
  error: (error) { /* mostra mensagem */ },
  data: (data) { /* renderiza conteúdo */ },
);
```

---

## AsyncStateManagement

Classe abstrata base para ViewModels com operações assíncronas. Estende `ChangeNotifier` e encapsula o estado em `StateValue<T>`.

```dart
abstract class AsyncStateManagement<T> extends ChangeNotifier
```

### Propriedades

| Nome    | Tipo            | Descrição                      |
|---------|-----------------|--------------------------------|
| `state` | `StateValue<T>` | Estado atual (somente leitura) |

### Métodos

| Nome                           | Descrição                                                                                         |
|--------------------------------|---------------------------------------------------------------------------------------------------|
| `build()`                      | Define o estado inicial da subclasse. Obrigatório — chamado automaticamente no construtor.        |
| `emitState(StateValue<T>)`     | Atualiza o estado e notifica os listeners. Ignorado se o novo estado for idêntico ao atual.       |
| `setLoading()`                 | Atalho para `emitState(StateLoading())`.                                                          |
| `setError(Object error)`       | Atalho para `emitState(StateError(error))`.                                                       |
| `setData(T data)`              | Atalho para `emitState(StateData(data))`.                                                         |

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
    extends AsyncStateManagement<ProductModel> {
  Future<void> fetchProduct();
}

// 3. Crie a implementação
class ProductViewModelImpl extends AsyncStateManagement<ProductModel>
    implements ProductViewModel {

  final ProductRepository productRepository;

  ProductViewModelImpl({required this.productRepository});

  @override
  StateValue<ProductModel> build() => const StateLoading(); // estado inicial

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

> **Nota:** assim como no `StateManagement`, o estado inicial é definido em `build()`.
> O tipo de retorno é `StateValue<T>`, permitindo iniciar como `StateLoading()`,
> `StateData(value)` ou `StateError(error)` conforme a necessidade.

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
    extends AsyncStateManagement<ProductModel> {
  Future<void> fetchProduct();
}

// implementação
class ProductViewModelImpl extends AsyncStateManagement<ProductModel>
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
          child: StateBuilderWidget<ProductViewModel, StateValue<ProductModel>>(
            viewModel: _productViewModel,
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
