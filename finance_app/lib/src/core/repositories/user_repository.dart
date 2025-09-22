import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import '../models/user.dart';
import '../services/database_service.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  static UserRepository get instance => _instance;
  UserRepository._internal();

  Future<Database> get _db async => await DatabaseService.instance.database;

  Future<User?> getUserById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'users',
      where: 'id = ? AND is_deleted = 0',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _mapToUser(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await _db;
    final maps = await db.query(
      'users',
      where: 'email = ? AND is_deleted = 0',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return _mapToUser(maps.first);
    }
    return null;
  }

  Future<String> createUser(User user) async {
    final db = await _db;
    final userMap = _mapFromUser(user);
    
    await db.insert('users', userMap);
    return user.id;
  }

  Future<void> updateUser(User user) async {
    final db = await _db;
    final userMap = _mapFromUser(user);
    
    await db.update(
      'users',
      userMap,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(String id) async {
    final db = await _db;
    
    await db.update(
      'users',
      {
        'is_deleted': 1,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  User _mapToUser(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      settings: Map<String, dynamic>.from(
        jsonDecode(map['settings'] as String),
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      lastModified: DateTime.parse(map['last_modified'] as String),
      isDeleted: (map['is_deleted'] as int) == 1,
    );
  }

  Map<String, dynamic> _mapFromUser(User user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'phone': user.phone,
      'settings': jsonEncode(user.settings),
      'created_at': user.createdAt.toIso8601String(),
      'last_modified': user.lastModified.toIso8601String(),
      'is_deleted': user.isDeleted ? 1 : 0,
    };
  }
}