class UserModel {
  final int id;
  final String nome;
  final String email;

  UserModel({required this.id, required this.nome, required this.email});

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int,
      nome: map['nome'] as String,
      email: map['email'] as String,
    );
  }
}
