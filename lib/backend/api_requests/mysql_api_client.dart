import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class MysqlApiException implements Exception {
  const MysqlApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'MysqlApiException($statusCode): $message';
}

class MysqlApiClient {
  MysqlApiClient({
    String baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:3000/api',
    ),
    http.Client? client,
    FlutterSecureStorage? secureStorage,
  })  : _baseUrl = baseUrl.replaceFirst(RegExp(r'/+$'), ''),
        _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _tokenKey = 'felipe6_access_token';
  final String _baseUrl;
  final http.Client _client;
  final FlutterSecureStorage _secureStorage;
  String? _accessToken;

  bool get isAuthenticated => _accessToken != null;

  Future<void> restoreSession() async {
    _accessToken = await _secureStorage.read(key: _tokenKey);
  }

  Future<void> _storeToken(Map<String, dynamic> result) async {
    final token = result['accessToken'];
    if (token is! String || token.isEmpty) {
      throw const FormatException(
          'The API response did not contain an access token');
    }
    await _secureStorage.write(key: _tokenKey, value: token);
    _accessToken = token;
  }

  Future<Map<String, dynamic>> register({
    required String displayName,
    required String email,
    required String username,
    required String password,
  }) async {
    final result = await _send('POST', '/auth/register', body: {
      'displayName': displayName,
      'email': email,
      'username': username,
      'password': password,
    });
    await _storeToken(result);
    return result;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final result = await _send('POST', '/auth/login', body: {
      'email': email,
      'password': password,
    });
    await _storeToken(result);
    return result;
  }

  Future<Map<String, dynamic>> getMe() => _send('GET', '/me');

  Future<Map<String, dynamic>> getPosts({int limit = 20, int offset = 0}) =>
      _send('GET', '/posts', query: {'limit': '$limit', 'offset': '$offset'});

  Future<Map<String, dynamic>> createPost({
    String? postPhotoUrl,
    String? postTitle,
    String? postDescription,
    String? dogProfileId,
  }) =>
      _send('POST', '/posts', body: {
        if (postPhotoUrl != null) 'postPhotoUrl': postPhotoUrl,
        if (postTitle != null) 'postTitle': postTitle,
        if (postDescription != null) 'postDescription': postDescription,
        if (dogProfileId != null) 'dogProfileId': dogProfileId,
      });

  Future<Map<String, dynamic>> getProfile(String userId) =>
      _send('GET', '/users/${Uri.encodeComponent(userId)}');

  Future<Map<String, dynamic>> getChats() => _send('GET', '/chats');

  Future<Map<String, dynamic>> createChat({required String email}) =>
      _send('POST', '/chats', body: {'email': email});

  Future<Map<String, dynamic>> getChatMessages(
    String chatId, {
    int limit = 50,
  }) =>
      _send(
        'GET',
        '/chats/${Uri.encodeComponent(chatId)}/messages',
        query: {'limit': '$limit'},
      );

  Future<Map<String, dynamic>> sendChatMessage(
    String chatId, {
    String? text,
    String? imageUrl,
    String? videoUrl,
  }) =>
      _send(
        'POST',
        '/chats/${Uri.encodeComponent(chatId)}/messages',
        body: {
          if (text != null) 'text': text,
          if (imageUrl != null) 'imageUrl': imageUrl,
          if (videoUrl != null) 'videoUrl': videoUrl,
        },
      );

  Future<Map<String, dynamic>> getAdminUsers({
    int limit = 50,
    int offset = 0,
  }) =>
      _send('GET', '/admin/users', query: {
        'limit': '$limit',
        'offset': '$offset',
      });

  Future<Map<String, dynamic>> getAdminPosts(
          {int limit = 50, int offset = 0}) =>
      _send('GET', '/admin/posts', query: {
        'limit': '$limit',
        'offset': '$offset',
      });

  Future<Map<String, dynamic>> getAdminComments({
    int limit = 50,
    int offset = 0,
  }) =>
      _send('GET', '/admin/comments', query: {
        'limit': '$limit',
        'offset': '$offset',
      });

  Future<Map<String, dynamic>> setUserStatus(
    String userId,
    String status,
  ) =>
      _send(
        'PATCH',
        '/admin/users/${Uri.encodeComponent(userId)}/status',
        body: {'status': status},
      );

  Future<void> deleteAdminPost(String postId) async {
    await _send('DELETE', '/admin/posts/${Uri.encodeComponent(postId)}');
  }

  Future<void> deleteAdminComment(String commentId) async {
    await _send(
      'DELETE',
      '/admin/comments/${Uri.encodeComponent(commentId)}',
    );
  }

  Future<void> logout() async {
    _accessToken = null;
    await _secureStorage.delete(key: _tokenKey);
  }

  void close() => _client.close();

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    final decoded =
        response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map<String, dynamic>
          ? decoded['error']?.toString() ?? 'Request failed'
          : 'Request failed';
      throw MysqlApiException(response.statusCode, message);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object from the API');
    }
    return decoded;
  }
}

final mysqlApi = MysqlApiClient();
