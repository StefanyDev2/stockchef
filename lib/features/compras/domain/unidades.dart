/// Unidades de medida de HU-006 (CA4). Mismas reglas que
/// functions/src/unidades.ts.
enum UnidadMedida {
  kilogramo('Kilogramo', 'kg'),
  gramo('Gramo', 'g'),
  libra('Libra', 'lb'),
  litro('Litro', 'L'),
  mililitro('Mililitro', 'mL'),
  unidad('Unidad', 'und');

  const UnidadMedida(this.etiqueta, this.abreviatura);

  final String etiqueta;
  final String abreviatura;

  /// Valor guardado en Firestore: el nombre en minúsculas.
  String get valor => name;

  static UnidadMedida? desdeValor(Object? valor) =>
      UnidadMedida.values.asNameMap()[valor];

  /// Tipo de medida: solo se convierten unidades del mismo tipo.
  String get tipo => switch (this) {
    kilogramo || gramo || libra => 'masa',
    litro || mililitro => 'volumen',
    unidad => 'conteo',
  };

  bool esCompatibleCon(UnidadMedida otra) => tipo == otra.tipo;
}
