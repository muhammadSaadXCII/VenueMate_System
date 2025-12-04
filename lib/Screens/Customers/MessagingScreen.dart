import 'package:flutter/material.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFF47C20);
    const Color searchBarColor = Color(0xFFD9D9D9);

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 🔙 BACK ARROW + HEADER
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 28, color: Color(0xFFF47C20)),
                    onPressed: () {
                      Navigator.pop(context); // Go back to Home Screen
                    },
                  ),

                  Image.asset(
                    'assets/images/messageicon.png',
                    width: 55,
                    height: 55,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.maps_ugc_rounded, color: primaryOrange, size: 32);
                    },
                  ),
                  const SizedBox(width: 12),

                  const Text(
                    "Message",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // SEARCH BAR
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: searchBarColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Search...",
                    hintStyle: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.black87,
                      size: 26,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // CHATS BUTTON
              Center(
                child: SizedBox(
                  width: 200,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF2994A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Chats",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Divider(thickness: 3, color: Color(0xFFCCCCCC)),
              const SizedBox(height: 10),

              // CHAT LIST
              Expanded(
                child: ListView(
                  children: const [
                    ChatItem(
                      name: "Muhammad Saad",
                      message: "Great I will arrive soon.....",
                      time: "05:02",
                      unreadCount: 3,
                      imageUrl: "https://i.pravatar.cc/150?img=11",
                    ),
                    Divider(thickness: 1, color: Color(0xFFCCCCCC)),

                    ChatItem(
                      name: "Muhammad Ali",
                      message: "My order has not arrived yet",
                      time: "05:02",
                      unreadCount: 2,
                      imageUrl: "https://i.pravatar.cc/150?img=3",
                    ),
                    Divider(thickness: 1, color: Color(0xFFCCCCCC)),

                    ChatItem(
                      name: "Irtaza Sahi",
                      message: "How are you?????",
                      time: "12/21/2022",
                      unreadCount: 1,
                      imageUrl: "https://i.pravatar.cc/150?img=59",
                    ),
                    Divider(thickness: 1, color: Color(0xFFCCCCCC)),

                    ChatItem(
                      name: "Muhammad Ali",
                      message: "My order has not arrived yet",
                      time: "05:02",
                      unreadCount: 2,
                      imageUrl: "https://i.pravatar.cc/150?img=3",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatItem extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final int unreadCount;
  final String imageUrl;

  const ChatItem({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    required this.unreadCount,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
              backgroundColor: Colors.grey[200],
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (unreadCount > 0)
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF47C20),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 4),

              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
