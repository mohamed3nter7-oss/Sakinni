import 'package:flutter/material.dart';
import 'package:sakkeny_app/services/chat_service.dart';
import 'package:sakkeny_app/services/api_service.dart';
import 'package:sakkeny_app/services/property_service.dart';

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final ChatService chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String currentUserId = "";

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserId();
  }

  Future<void> _fetchCurrentUserId() async {
    try {
      final response = await ApiService().dio.get('/auth/me');
      if (response.data['success'] == true) {
        if (mounted) {
          setState(() {
            currentUserId = response.data['data']['user']['_id'];
          });
        }
      }
    } catch (e) {
      print('Failed to get current user info for messages');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Messages",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false, // Hide back button on main tab
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF276152), width: 2),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Color(0xFF276152)),
                  border: InputBorder.none,
                  hintText: "Search owners...",
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Content: Search Results OR Active Chats
            Expanded(
              child: _searchQuery.isNotEmpty
                  ? _buildSearchResults()
                  : _buildActiveChats(),
            ),
          ],
        ),
      ),
    );
  }

  // Build Active Chats List (Stream)
  Widget _buildActiveChats() {
    if (currentUserId.isEmpty) {
      return const Center(child: Text("Please log in to view messages"));
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getMyChats(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("No messages yet", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: snapshot.data!.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            var data = snapshot.data![index];
            String otherUserId = data['otherUserId'] ?? "";
            String displayName = data['otherUserName'] ?? "User";
            String lastMessage = data['lastMessage'] ?? "";

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF276152),
                child: Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600]),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      userId: otherUserId,
                      name: displayName,
                      lastMessage: "",
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Build Global Search Results (Owners)
  Widget _buildSearchResults() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _searchOwners(_searchQuery),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        List<Map<String, String>> owners = snapshot.data ?? [];

        if (owners.isEmpty) {
          return const Center(child: Text("No owners found"));
        }

        return ListView.separated(
          itemCount: owners.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final owner = owners[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              title: Text(owner['name'] ?? "Unknown"),
              subtitle: const Text("Property Owner"),
              trailing: const Icon(Icons.message, color: Color(0xFF276152)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      userId: owner['id']!,
                      name: owner['name']!,
                      lastMessage: "Hello!",
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Search Logic: Find owners in properties
  Future<List<Map<String, String>>> _searchOwners(String query) async {
    if (query.isEmpty) return [];

    try {
      final properties = await PropertyService().searchProperties(query);

      // Deduplicate owners
      Set<String> processedIds = {};
      List<Map<String, String>> results = [];

      for (var p in properties) {
        String uid = p.userId;
        String name = p.userName;

        if (uid.isNotEmpty && uid != currentUserId && !processedIds.contains(uid)) {
          processedIds.add(uid);
          results.add({'id': uid, 'name': name});
        }
      }
      return results;
    } catch (e) {
      debugPrint("Search error: $e");
      return [];
    }
  }
}

// ==========================================
// CHAT PAGE (Conversation)
// ==========================================

class ChatPage extends StatefulWidget {
  final String userId; // The OTHER user's ID
  final String name; // The OTHER user's Name
  final String lastMessage; // Optional initial message string (for context)

  const ChatPage({
    super.key,
    required this.userId,
    required this.name,
    required this.lastMessage,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ChatService chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  String currentUserId = "";
  String? chatId;
  bool isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final response = await ApiService().dio.get('/auth/me');
      if (response.data['success'] == true) {
        currentUserId = response.data['data']['user']['_id'];
      }

      String? createdChatId = await chatService.startOrGetChat(widget.userId, widget.name);
      if (mounted) {
        setState(() {
          chatId = createdChatId;
          isInitializing = false;
        });

        if (widget.lastMessage.isNotEmpty && chatId != null) {
          await chatService.sendMessage(chatId!, widget.lastMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isInitializing = false;
        });
      }
    }
  }

  Future<void> sendMessage() async {
    String text = messageController.text.trim();
    if (text.isEmpty || currentUserId.isEmpty || chatId == null) return;

    messageController.clear();

    try {
      await chatService.sendMessage(chatId!, text);
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF276152),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isInitializing
          ? const Center(child: CircularProgressIndicator())
          : chatId == null
              ? const Center(child: Text("Error loading chat"))
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: chatService.getChatMessages(chatId!),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text('Say Hello! 👋'));
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true, // Start from bottom
                            padding: const EdgeInsets.all(16),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              var data = snapshot.data![index];
                              bool isMe = data['senderId'] == currentUserId;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: ChatBubble(
                                  text: data['text'] ?? '',
                                  isMe: isMe,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // Input Area
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: messageController,
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                filled: true,
                                fillColor: Colors.grey[100],
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(25),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: sendMessage,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF276152),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF276152) : Colors.grey[200],
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(0),
          bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}