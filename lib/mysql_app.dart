import 'dart:async';

import 'package:flutter/material.dart';

import 'backend/api_requests/mysql_api_client.dart';

class MysqlApp extends StatefulWidget {
  const MysqlApp({super.key});

  @override
  State<MysqlApp> createState() => _MysqlAppState();
}

class _MysqlAppState extends State<MysqlApp> {
  final MysqlApiClient _api = MysqlApiClient();
  Map<String, dynamic>? _user;
  bool _restoringSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      await _api.restoreSession();
      if (_api.isAuthenticated) {
        final response = await _api.getMe();
        final user = response['user'];
        if (user is Map<String, dynamic> && mounted) {
          setState(() => _user = user);
        }
      }
    } catch (_) {
      await _api.logout();
    } finally {
      if (mounted) setState(() => _restoringSession = false);
    }
  }

  Future<void> _authenticate(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    final result = await action();
    final user = result['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('The API response did not contain a user');
    }
    if (!mounted) return;
    setState(() => _user = user);
  }

  Future<void> _signOut() async {
    await _api.logout();
    if (mounted) setState(() => _user = null);
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FELIPE6',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF197C63),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: _restoringSession
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _user == null
              ? MysqlAuthScreen(
                  onLogin: (email, password) => _authenticate(
                    () => _api.login(email: email, password: password),
                  ),
                  onRegister: (name, email, username, password) =>
                      _authenticate(
                    () => _api.register(
                      displayName: name,
                      email: email,
                      username: username,
                      password: password,
                    ),
                  ),
                )
              : MysqlHomeScreen(
                  api: _api,
                  user: _user!,
                  onSignOut: _signOut,
                ),
    );
  }
}

class MysqlAuthScreen extends StatefulWidget {
  const MysqlAuthScreen({
    required this.onLogin,
    required this.onRegister,
    super.key,
  });

  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function(
    String displayName,
    String email,
    String username,
    String password,
  ) onRegister;

  @override
  State<MysqlAuthScreen> createState() => _MysqlAuthScreenState();
}

class _MysqlAuthScreenState extends State<MysqlAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _isRegistering = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      if (_isRegistering) {
        await widget.onRegister(
          _displayName.text.trim(),
          _email.text.trim(),
          _username.text.trim(),
          _password.text,
        );
      } else {
        await widget.onLogin(_email.text.trim(), _password.text);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_messageFor(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _messageFor(Object error) => error is MysqlApiException
      ? error.message
      : 'No se pudo conectar con la API. Comprueba que el servidor esté activo.';

  @override
  Widget build(BuildContext context) {
    final title = _isRegistering ? 'Crear cuenta' : 'Iniciar sesión';
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            padding: const EdgeInsets.all(28),
            shrinkWrap: true,
            children: [
              const Icon(Icons.pets, size: 44),
              const SizedBox(height: 18),
              Text(
                'FELIPE6',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 28),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_isRegistering) ...[
                      TextFormField(
                        controller: _displayName,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                        textCapitalization: TextCapitalization.words,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Escribe tu nombre'
                                : null,
                      ),
                      TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(labelText: 'Usuario'),
                        validator: (value) =>
                            value == null || value.trim().length < 3
                                ? 'Usa al menos 3 caracteres'
                                : null,
                      ),
                    ],
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                              ? 'Escribe un correo válido'
                              : null,
                    ),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) => value == null || value.length < 10
                          ? 'La contraseña debe tener al menos 10 caracteres'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(title),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => setState(() => _isRegistering = !_isRegistering),
                child: Text(
                  _isRegistering
                      ? 'Ya tengo una cuenta'
                      : 'Crear una cuenta nueva',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MysqlHomeScreen extends StatefulWidget {
  const MysqlHomeScreen({
    required this.api,
    required this.user,
    required this.onSignOut,
    super.key,
  });

  final MysqlApiClient api;
  final Map<String, dynamic> user;
  final VoidCallback onSignOut;

  @override
  State<MysqlHomeScreen> createState() => _MysqlHomeScreenState();
}

class _MysqlHomeScreenState extends State<MysqlHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.user['role'] == 'admin';
    final pages = <Widget>[
      MysqlFeedTab(api: widget.api),
      MysqlChatsTab(api: widget.api),
      MysqlProfileTab(api: widget.api, user: widget.user),
      if (isAdmin)
        MysqlAdminTab(api: widget.api, currentUserId: '${widget.user['id']}'),
    ];
    final labels = <String>['Feed', 'Chats', 'Perfil', if (isAdmin) 'Admin'];
    final icons = <IconData>[
      Icons.dynamic_feed_outlined,
      Icons.chat_bubble_outline,
      Icons.person_outline,
      if (isAdmin) Icons.admin_panel_settings_outlined,
    ];
    if (_selectedIndex >= pages.length) _selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(labels[_selectedIndex]),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: [
          for (var index = 0; index < labels.length; index++)
            NavigationDestination(
              icon: Icon(icons[index]),
              label: labels[index],
            ),
        ],
      ),
    );
  }
}

class MysqlFeedTab extends StatefulWidget {
  const MysqlFeedTab({required this.api, super.key});

  final MysqlApiClient api;

  @override
  State<MysqlFeedTab> createState() => _MysqlFeedTabState();
}

class _MysqlFeedTabState extends State<MysqlFeedTab> {
  late Future<Map<String, dynamic>> _posts;

  @override
  void initState() {
    super.initState();
    _posts = widget.api.getPosts();
  }

  void _reload() => setState(() => _posts = widget.api.getPosts());

  Future<void> _createPost() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final photoController = TextEditingController();
    final values = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva publicación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                minLines: 2,
                maxLines: 4,
              ),
              TextField(
                controller: photoController,
                decoration: const InputDecoration(labelText: 'URL de foto'),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, {
              'title': titleController.text.trim(),
              'description': descriptionController.text.trim(),
              'photoUrl': photoController.text.trim(),
            }),
            child: const Text('Publicar'),
          ),
        ],
      ),
    );
    titleController.dispose();
    descriptionController.dispose();
    photoController.dispose();
    if (values == null || !mounted) return;
    if (values.values.every((value) => value.isEmpty)) {
      _showError(
          context, const FormatException('Agrega texto o una URL de foto'));
      return;
    }
    try {
      await widget.api.createPost(
        postTitle: values['title']!.isEmpty ? null : values['title'],
        postDescription:
            values['description']!.isEmpty ? null : values['description'],
        postPhotoUrl: values['photoUrl']!.isEmpty ? null : values['photoUrl'],
      );
      _reload();
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _createPost,
          tooltip: 'Nueva publicación',
          child: const Icon(Icons.add),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _posts,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _LoadError(error: snapshot.error!, onRetry: _reload);
            }
            final items =
                (snapshot.data?['items'] as List<dynamic>? ?? const [])
                    .whereType<Map<String, dynamic>>()
                    .toList();
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  children: const [
                    SizedBox(height: 180),
                    Center(child: Text('Todavía no hay publicaciones')),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) => _PostTile(post: items[index]),
              ),
            );
          },
        ),
      );
}

class _PostTile extends StatelessWidget {
  const _PostTile({required this.post});

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) {
    final photoUrl = post['postPhotoUrl'] as String?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${post['authorName'] ?? 'Usuario'}  ·  @${post['authorUsername'] ?? ''}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (post['postTitle'] != null) ...[
            const SizedBox(height: 8),
            Text('${post['postTitle']}',
                style: Theme.of(context).textTheme.titleMedium),
          ],
          if (photoUrl != null && photoUrl.isNotEmpty) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                photoUrl,
                width: double.infinity,
                height: 230,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          if (post['postDescription'] != null) ...[
            const SizedBox(height: 8),
            Text('${post['postDescription']}'),
          ],
        ],
      ),
    );
  }
}

class MysqlChatsTab extends StatefulWidget {
  const MysqlChatsTab({required this.api, super.key});

  final MysqlApiClient api;

  @override
  State<MysqlChatsTab> createState() => _MysqlChatsTabState();
}

class _MysqlChatsTabState extends State<MysqlChatsTab> {
  late Future<Map<String, dynamic>> _chats;

  @override
  void initState() {
    super.initState();
    _chats = widget.api.getChats();
  }

  void _reload() => setState(() => _chats = widget.api.getChats());

  Future<void> _newChat() async {
    final emailController = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo chat'),
        content: TextField(
          controller: emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Correo del usuario'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, emailController.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    emailController.dispose();
    if (email == null || email.isEmpty || !mounted) return;

    try {
      final result = await widget.api.createChat(email: email);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MysqlChatThreadPage(
            api: widget.api,
            chat: result['chat'] as Map<String, dynamic>,
          ),
        ),
      );
      _reload();
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _newChat,
          tooltip: 'Nuevo chat',
          child: const Icon(Icons.add_comment_outlined),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: _chats,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _LoadError(error: snapshot.error!, onRetry: _reload);
            }
            final items =
                (snapshot.data?['items'] as List<dynamic>? ?? const [])
                    .whereType<Map<String, dynamic>>()
                    .toList();
            if (items.isEmpty) {
              return const Center(child: Text('No tienes chats todavía'));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final chat = items[index];
                return ListTile(
                  leading:
                      const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text('${chat['otherDisplayName'] ?? 'Chat grupal'}'),
                  subtitle: Text('${chat['lastMessage'] ?? 'Sin mensajes'}'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          MysqlChatThreadPage(api: widget.api, chat: chat),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}

class MysqlChatThreadPage extends StatefulWidget {
  const MysqlChatThreadPage({
    required this.api,
    required this.chat,
    super.key,
  });

  final MysqlApiClient api;
  final Map<String, dynamic> chat;

  @override
  State<MysqlChatThreadPage> createState() => _MysqlChatThreadPageState();
}

class _MysqlChatThreadPageState extends State<MysqlChatThreadPage> {
  final _messageController = TextEditingController();
  late Future<Map<String, dynamic>> _messages;
  Timer? _messageRefreshTimer;
  bool _refreshingMessages = false;
  bool _sending = false;

  String get _chatId => '${widget.chat['id'] ?? widget.chat['chat_id']}';

  @override
  void initState() {
    super.initState();
    _messages = widget.api.getChatMessages(_chatId);
    _messageRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _refreshMessages(),
    );
  }

  @override
  void dispose() {
    _messageRefreshTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _refreshMessages() async {
    if (_refreshingMessages || !mounted) return;
    _refreshingMessages = true;
    try {
      final response = await widget.api.getChatMessages(_chatId);
      if (mounted) setState(() => _messages = Future.value(response));
    } catch (error) {
      if (mounted) setState(() => _messages = Future.error(error));
    } finally {
      _refreshingMessages = false;
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.sendChatMessage(_chatId, text: text);
      _messageController.clear();
      await _refreshMessages();
    } catch (error) {
      if (mounted) _showError(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar:
            AppBar(title: Text('${widget.chat['otherDisplayName'] ?? 'Chat'}')),
        body: Column(
          children: [
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _messages,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _LoadError(
                      error: snapshot.error!,
                      onRetry: _refreshMessages,
                    );
                  }
                  final items =
                      (snapshot.data?['items'] as List<dynamic>? ?? const [])
                          .whereType<Map<String, dynamic>>()
                          .toList();
                  if (items.isEmpty)
                    return const Center(child: Text('Envía el primer mensaje'));
                  return ListView.builder(
                    reverse: false,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) => Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child:
                            Text('${items[index]['text'] ?? '[Multimedia]'}'),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Mensaje',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Enviar mensaje',
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}

class MysqlProfileTab extends StatefulWidget {
  const MysqlProfileTab({
    required this.api,
    required this.user,
    super.key,
  });

  final MysqlApiClient api;
  final Map<String, dynamic> user;

  @override
  State<MysqlProfileTab> createState() => _MysqlProfileTabState();
}

class _MysqlProfileTabState extends State<MysqlProfileTab> {
  late Future<Map<String, dynamic>> _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.api.getProfile('${widget.user['id']}');
  }

  void _reload() => setState(
        () => _profile = widget.api.getProfile('${widget.user['id']}'),
      );

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
        future: _profile,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LoadError(
              error: snapshot.error!,
              onRetry: _reload,
            );
          }
          final profile =
              snapshot.data?['user'] as Map<String, dynamic>? ?? widget.user;
          final dogs = (snapshot.data?['dogs'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CircleAvatar(
                radius: 34,
                child: Text(
                  '${profile['display_name'] ?? widget.user['displayName'] ?? '?'}'
                      .characters
                      .first
                      .toUpperCase(),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${profile['display_name'] ?? widget.user['displayName'] ?? ''}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                '@${profile['username'] ?? widget.user['username'] ?? ''}',
                textAlign: TextAlign.center,
              ),
              if (profile['bio'] != null) ...[
                const SizedBox(height: 12),
                Text('${profile['bio']}'),
              ],
              const SizedBox(height: 24),
              Text('Perfiles de perros',
                  style: Theme.of(context).textTheme.titleMedium),
              for (final dog in dogs)
                ListTile(
                  leading: const Icon(Icons.pets),
                  title: Text('${dog['name']}'),
                  subtitle: Text('${dog['type'] ?? ''}  ${dog['age'] ?? ''}'),
                ),
              if (dogs.isEmpty)
                const ListTile(title: Text('Sin perfiles de perros')),
            ],
          );
        },
      );
}

class MysqlAdminTab extends StatefulWidget {
  const MysqlAdminTab({
    required this.api,
    required this.currentUserId,
    super.key,
  });

  final MysqlApiClient api;
  final String currentUserId;

  @override
  State<MysqlAdminTab> createState() => _MysqlAdminTabState();
}

class _MysqlAdminTabState extends State<MysqlAdminTab> {
  String _section = 'users';
  late Future<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    _items = _loadItems();
  }

  Future<Map<String, dynamic>> _loadItems() => switch (_section) {
        'posts' => widget.api.getAdminPosts(),
        'comments' => widget.api.getAdminComments(),
        _ => widget.api.getAdminUsers(),
      };

  void _reload() => setState(() => _items = _loadItems());

  void _selectSection(String section) {
    setState(() {
      _section = section;
      _items = _loadItems();
    });
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await widget.api.setUserStatus(id, status);
      _reload();
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  Future<void> _deleteContent(String id) async {
    try {
      if (_section == 'posts') {
        await widget.api.deleteAdminPost(id);
      } else {
        await widget.api.deleteAdminComment(id);
      }
      _reload();
    } catch (error) {
      if (mounted) _showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'users', label: Text('Usuarios')),
                ButtonSegment(value: 'posts', label: Text('Posts')),
                ButtonSegment(value: 'comments', label: Text('Comentarios')),
              ],
              selected: {_section},
              onSelectionChanged: (selection) =>
                  _selectSection(selection.first),
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _items,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _LoadError(error: snapshot.error!, onRetry: _reload);
                }
                final items =
                    (snapshot.data?['items'] as List<dynamic>? ?? const [])
                        .whereType<Map<String, dynamic>>()
                        .toList();
                if (items.isEmpty) {
                  return Center(
                      child: Text(
                          'Sin ${_section == 'users' ? 'usuarios' : _section == 'posts' ? 'publicaciones' : 'comentarios'}'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = '${item['id']}';
                    if (_section == 'users') {
                      final suspended = item['status'] == 'suspended';
                      return ListTile(
                        title: Text('${item['displayName']}'),
                        subtitle: Text(
                            '${item['email']} · ${item['role']} · ${item['status']}'),
                        trailing: id == widget.currentUserId
                            ? const Icon(Icons.admin_panel_settings_outlined)
                            : IconButton(
                                tooltip: suspended
                                    ? 'Reactivar cuenta'
                                    : 'Suspender cuenta',
                                onPressed: () => _setStatus(
                                    id, suspended ? 'active' : 'suspended'),
                                icon: Icon(suspended
                                    ? Icons.person_add_alt
                                    : Icons.block),
                              ),
                      );
                    }
                    return ListTile(
                      title: Text(
                        '${_section == 'posts' ? item['title'] ?? item['description'] : item['comment']}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                          '@${item['authorUsername'] ?? ''} · ${item['status']}'),
                      trailing: IconButton(
                        tooltip: _section == 'posts'
                            ? 'Eliminar publicación'
                            : 'Eliminar comentario',
                        onPressed: () => _deleteContent(id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 36),
              const SizedBox(height: 12),
              Text(_errorText(error), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

String _errorText(Object error) => error is MysqlApiException
    ? error.message
    : 'No se pudo cargar la información. Comprueba la conexión con la API.';

void _showError(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(_errorText(error))),
  );
}
